"""Sandbox checks for a patched config.lua (needs: pip install lupa).

    python3 dev/check.py path/to/config.lua [essentials|full]

MainStage is simulated: one pending timer at a time (a new settriggertimer
replaces the old one) and controller_timer_trigger is called by hand.
"""
import sys
import lupa
from lupa.lua52 import LuaRuntime

path, tier = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "full")
lua = LuaRuntime(unpack_returned_tuples=True)
g = lua.globals()
lua.execute("MIDI_CtrChange = 0xB0; MIDI_LSB = 0; TIMER = nil; "
            "function settriggertimer(ms) TIMER = ms end; print = function(...) end")
lua.execute(open(path, encoding="utf-8").read())

def ev(*b):
    t = lua.table()
    for i, v in enumerate(b):
        t[i] = v
    return t

def flat(t, out):
    for v in t.values():
        (flat(v, out) if lupa.lua_type(v) == "table" else out.append(v))
    return out

def fire():
    """MainStage firing the pending timer; returns the SysEx bytes sent."""
    g.TIMER = None
    r = g.controller_timer_trigger()
    return flat(r["midi"], []) if r is not None else []

def touch(ctl, on):
    for m in (ev(0xB0, 99, 0), ev(0xB0, 98, ctl), ev(0xB0, 6, 127 if on else 0)):
        g.controller_midi_in(m, "KeyLab 61 mk3 DAW")

items = {i["name"]: i for i in g.controller_info()["items"].values()}
for n, a in [("PreviousPatch", "PreviousPatch"), ("NextPatch", "NextPatch"),
             ("PreviousSet", "PreviousSet"), ("NextSet", "NextSet"), ("Panic Full", "Panic")]:
    assert items[n]["action_mainstage"] == a, n
assert "Knob9" in items and items["Play Stop"]["objectType"] == "Button"
g.controller_initialize("MainStage", False)

# 3 sets x 6 patches
pl = lua.table()
i = 1
for s, name in enumerate(["Classics", "Leads", "Pads"]):
    for p in range(-1, 6):
        t = lua.table()
        t["Label"], t["IsPatch"], t["SetIndex"], t["PatchIndex"] = (name if p < 0 else f"{name} {p}"), p >= 0, s, p
        pl[i] = t
        i += 1
def select(s, p):
    g.controller_select_patch(s * 6 + p, f"{s}-{p}", "S", "C", pl, s, p)
    return g.SCROLL_TYPE

# SET column sync: scroll type follows the actual index change
steps = [((0, 0), 0), ((1, 0), 0), ((2, 0), 0), ((2, 1), 4), ((2, 2), 4), ((1, 0), 0), ((1, 1), 4), ((1, 0), 3)]
for (s, p), want in steps:
    assert select(s, p) == want, (s, p, g.SCROLL_TYPE)
print("essentials checks passed")

if tier == "full":
    fire()  # end of the post-patch-change quiet period
    g.controller_midi_out(ev(0xB0, 105, 64), "Volume", "-6.0 dB −∞", None)
    g.controller_midi_out(ev(0xB0, 91, 10), "Cutoff", None, None)
    assert g.TIMER is None, "untouched change must not pop up (mod wheel case)"

    touch(28, True)                      # touch fader 1 -> popup
    b = fire()
    assert b and b[0] == 0xF0 and b[-1] == 0xF7 and all(0 <= x <= 0x7F for x in b[1:-1])
    assert b[9] == 0x1D, "fader popup layout"

    # Two controls touched, only one release arrives (interleaved NRPN)
    touch(8, True); fire()
    touch(28, False)
    assert len(list(g.TOUCHED.keys())) == 0, "a lost release must not leave a control touched"
    assert g.TIMER == g.RESTORE_DELAY_MS
    b = fire()
    assert b and b[9] == 0x34, "list title restored"
    g.controller_midi_out(ev(0xB0, 91, 20), "Cutoff", None, None)   # mod wheel moves knob 1's param
    assert g.TIMER is None, "no popup after release"

    # Release inside the quiet period right after a patch change
    touch(28, True); fire()
    select(1, 1)
    touch(28, False)
    b = fire()
    assert b and b[9] == 0x34, "restore still happens after a patch change"
    print("full checks passed")

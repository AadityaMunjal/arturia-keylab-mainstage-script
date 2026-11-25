# KeyLab mk3 × MainStage fixes

Fixes for Arturia's MainStage integration script for the **KeyLab 49 / 61 / 88 mk3**. Out of the box, the KeyLab screen shows your patch names but the keyboard can't change patches. This repo fixes that, and optionally adds value popups on the KeyLab screen when you touch or move a fader or knob.

Tested on a KeyLab 61 mk3 with MainStage 4.3.1 (Arturia script v1.4). The 49 and 88 use the identical script apart from the model name, so the same changes apply, but they haven't been tested on hardware yet. Reports are welcome.

## Pick a version

| | `essentials` | `full` |
|---|:---:|:---:|
| Patch ◀ ▶ and Set ◀ ▶ buttons change patches/sets | ✅ | ✅ |
| SET column on the KeyLab screen stays in sync | ✅ | ✅ |
| Metronome, Panic (Stop button), Record, Tap Tempo, Undo, Redo buttons | ✅ | ✅ |
| Knob 9 available as a hardware control | ✅ | ✅ |
| Popup with parameter name + value when you **touch** a fader/knob | | ✅ |
| Popup follows the value while you **move** it | | ✅ |
| Patch list comes back 1 s after you let go | | ✅ |

**essentials** only fixes what's broken. **full** also adds the popups. It's more code that runs while you play, so if you only need working buttons, use essentials.

## Install

Quit MainStage first.

**By hand:** copy the folder for your keyboard, e.g. `full/KeyLab 61 mk3.device`, into

```
~/Music/Audio Music Apps/MIDI Device Profiles/Arturia/
```

replacing the folder that's already there, if any. (In Finder, press ⌘⇧G and paste the path.)

**Or with the installer:** download this repo, then run in Terminal:

```sh
cd keylab-mk3-mainstage
./install.sh essentials      # or: ./install.sh full
```

Add a model number to install just one keyboard: `./install.sh full 61`. If a script is already installed, for example Arturia's own, the installer first saves it to `~/Documents/KeyLab mk3 MainStage backup/`. `./uninstall.sh` puts it back. To switch versions, run `install.sh` again with the other one.

Then start MainStage and create a **new concert** (see below).

## Old concerts vs new concerts

MainStage reads the script every time it starts. Some things, though, are saved inside a concert **when the concert is created**:

- **Button actions** (Next/Previous Patch/Set, Panic, …) and **feedback to the keyboard** for each knob and fader are fixed at creation. In a concert made before installing, the patch/set buttons won't do anything, and knob 9 won't show popups.
- **Everything else** (the screen, the SET sync, popups, touch) comes from the script, so it works in old concerts too.

The easiest route is a new concert: import your old sets via *File → Import → Set*. To keep an old concert instead, map the buttons by hand: in Edit mode, select the concert, then in **Assignments & Mappings** map each KeyLab button to *Actions → Next Patch*, and so on.

## Known issues

- **Play/Stop** doesn't start MainStage's transport. MainStage rejects it from a script. Use the space bar, or map it by hand.
- **Holding two controls and releasing one** brings the patch list back while you're still holding the other. This is deliberate: it stops a lost touch-release message from leaving a popup stuck on screen.
- Popups only appear for controls you're touching. Changes from elsewhere (the mod wheel, patch changes, automation) update the stored value silently, so they don't flash over the list.

## How it works (for tinkerers)

- **Buttons:** the KeyLab sends CC 49–52 on its DAW port. Arturia's script declared these controls but never gave them `action_mainstage`, so MainStage didn't know they were navigation buttons. Transport buttons were missing `objectType`, and `PanicFull` isn't a valid action name (`Panic` is).
- **SET sync:** the original guessed the scroll direction from which button was pressed. That breaks when assignments differ, or when you change patch with the mouse. The patched version works it out from the actual set/patch index change.
- **Popups:** MainStage calls `controller_midi_out(midiEvent, name, valueString)` whenever a mapped parameter changes. The script stores the latest name/value per control. When the control is touched (the KeyLab sends an NRPN: CC99 = 0, CC98 = control, CC6 = 127 / 0), the script draws it with Arturia's screen SysEx (`F0 00 20 6B 7F 42 00 02 04 1D …` for faders, `… 1C …` for knobs). Drawing goes through `settriggertimer`, so fast moves only redraw the latest value. MainStage keeps a single pending timer and ignores timers set from inside `controller_timer_trigger`; the code is built around both.

`dev/check.py` runs a script in a Lua 5.2 sandbox that simulates MainStage's callbacks and timer:

```sh
pip install lupa
python3 dev/check.py "full/KeyLab 61 mk3.device/config.lua" full
```

## License

The `config.lua` files are modified versions of Arturia's KeyLab mk3 MainStage script v1.4, © 2023 Farès Mezdour / Arturia. The original copyright notice is kept in each file. My changes, the installer and the docs are MIT licensed (see `LICENSE`). This project isn't affiliated with Arturia or Apple. If you're from Arturia and want something changed, please open an issue.

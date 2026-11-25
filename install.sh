#!/bin/bash
# Patch Arturia's MainStage script for the KeyLab mk3.
#
#   ./install.sh essentials        patch/set buttons, SET display sync, transport, knob 9
#   ./install.sh full              everything above + value popups on touch/move
#   ./install.sh full 61           only the KeyLab 61 mk3 (default: every model installed)
#
# Your original Arturia file is copied to ~/Documents/KeyLab mk3 MainStage backup
# the first time; ./uninstall.sh puts it back. Re-running with another tier
# starts again from that original, so switching tiers is safe.

set -euo pipefail

TIER="${1:-}"
MODELS="${2:-49 61 88}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROFILES="${KEYLAB_PROFILES_DIR:-$HOME/Music/Audio Music Apps/MIDI Device Profiles/Arturia}"
BACKUP="${KEYLAB_BACKUP_DIR:-$HOME/Documents/KeyLab mk3 MainStage backup}"

# SHA-256 of Arturia's unmodified v1.4 scripts
KNOWN_ORIGINALS="c75258ca14b187fe35614f3155466b56fbbfd9721bb3dc7483edb2f6b49a05c9
5549d4967bdaf9fd72c0909f3f0fd75546e893c616a03d1522a598a6f8b00b26
d33e6187646be71d1036a59f31314e5b0a75630729f08da84cdcc5d8097821de"

case "$TIER" in
  essentials|full) ;;
  *) echo "usage: $0 essentials|full [49|61|88 ...]"; exit 1 ;;
esac

if pgrep -xq MainStage; then
  echo "Please quit MainStage first (it reads the script when it starts)."
  exit 1
fi

found=0
for m in $MODELS; do
  dev="$PROFILES/KeyLab $m mk3.device"
  [ -f "$dev/config.lua" ] || continue
  found=1
  saved="$BACKUP/KeyLab $m mk3/config.lua"

  if [ ! -f "$saved" ]; then
    sum="$(shasum -a 256 "$dev/config.lua" | cut -d' ' -f1)"
    if ! grep -q "$sum" <<<"$KNOWN_ORIGINALS"; then
      if grep -q "action_mainstage = 'NextPatch'" "$dev/config.lua"; then
        echo "KeyLab $m mk3: already modified and no backup found. Reinstall Arturia's"
        echo "  MainStage scripts (Arturia Software Center) and run this again."
        continue
      fi
      echo "KeyLab $m mk3: not the v1.4 script these patches were made for; trying anyway."
    fi
    mkdir -p "$(dirname "$saved")"
    cp "$dev/config.lua" "$saved"
    echo "KeyLab $m mk3: original saved to $saved"
  fi

  tmp="$(mktemp)"
  cp "$saved" "$tmp"
  if patch --batch --forward --silent "$tmp" < "$HERE/patches/$TIER.patch"; then
    cp "$tmp" "$dev/config.lua"
    echo "KeyLab $m mk3: installed '$TIER'"
  else
    echo "KeyLab $m mk3: patch did not apply, file left unchanged"
  fi
  rm -f "$tmp" "$tmp.rej" "$tmp.orig"
done

if [ "$found" = 0 ]; then
  echo "No KeyLab mk3 MainStage script found in:"
  echo "  $PROFILES"
  echo "Install Arturia's MainStage integration first (Arturia Software Center),"
  echo "or set KEYLAB_PROFILES_DIR to the folder that holds 'KeyLab 61 mk3.device'."
  exit 1
fi

echo
echo "Done. Start MainStage. The patch/set buttons only work in concerts created"
echo "after installing; see the README for older concerts."

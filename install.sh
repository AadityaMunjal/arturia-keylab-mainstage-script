#!/bin/bash
# Install the KeyLab mk3 MainStage script.
#
#   ./install.sh essentials        patch/set buttons, SET display sync, transport, knob 9
#   ./install.sh full              everything above + value popups on touch/move
#   ./install.sh full 61           only the KeyLab 61 mk3 (default: 49, 61 and 88)
#
# If a script is already installed (e.g. Arturia's), it is copied to
# ~/Documents/KeyLab mk3 MainStage backup the first time; ./uninstall.sh puts it back.

set -euo pipefail

TIER="${1:-}"
MODELS="${2:-49 61 88}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROFILES="${KEYLAB_PROFILES_DIR:-$HOME/Music/Audio Music Apps/MIDI Device Profiles/Arturia}"
BACKUP="${KEYLAB_BACKUP_DIR:-$HOME/Documents/KeyLab mk3 MainStage backup}"

case "$TIER" in
  essentials|full) ;;
  *) echo "usage: $0 essentials|full [49|61|88 ...]"; exit 1 ;;
esac

if pgrep -xq MainStage; then
  echo "Please quit MainStage first (it reads the script when it starts)."
  exit 1
fi

for m in $MODELS; do
  src="$HERE/$TIER/KeyLab $m mk3.device/config.lua"
  dev="$PROFILES/KeyLab $m mk3.device"
  saved="$BACKUP/KeyLab $m mk3/config.lua"
  if [ ! -f "$src" ]; then
    echo "Unknown model: $m (use 49, 61 or 88)"
    continue
  fi

  # Keep whatever was there before the first install (unless it is one of ours)
  if [ -f "$dev/config.lua" ] && [ ! -f "$saved" ] && ! grep -q "keylab-mk3-mainstage" "$dev/config.lua"; then
    mkdir -p "$(dirname "$saved")"
    cp "$dev/config.lua" "$saved"
    echo "KeyLab $m mk3: previous script saved to $saved"
  fi

  mkdir -p "$dev"
  cp "$src" "$dev/config.lua"
  echo "KeyLab $m mk3: installed '$TIER'"
done

echo
echo "Done. Start MainStage. The patch/set buttons only work in concerts created"
echo "after installing; see the README for older concerts."

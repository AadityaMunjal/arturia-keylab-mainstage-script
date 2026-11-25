#!/bin/bash
# Put Arturia's original MainStage scripts back.
set -euo pipefail

PROFILES="${KEYLAB_PROFILES_DIR:-$HOME/Music/Audio Music Apps/MIDI Device Profiles/Arturia}"
BACKUP="${KEYLAB_BACKUP_DIR:-$HOME/Documents/KeyLab mk3 MainStage backup}"

if pgrep -xq MainStage; then
  echo "Please quit MainStage first."
  exit 1
fi

for m in 49 61 88; do
  saved="$BACKUP/KeyLab $m mk3/config.lua"
  dev="$PROFILES/KeyLab $m mk3.device"
  if [ -f "$saved" ] && [ -d "$dev" ]; then
    cp "$saved" "$dev/config.lua"
    echo "KeyLab $m mk3: original restored"
  fi
done

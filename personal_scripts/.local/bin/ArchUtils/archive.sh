#!/bin/bash
REMOTE="truenas:/mnt/deimos/archive/nautiles_inbox"
for SRC in "$@"; do
    rsync -avhrPO "$SRC" "$REMOTE"
done
notify-send "Rsync complete" "Upload to $REMOTE finished."


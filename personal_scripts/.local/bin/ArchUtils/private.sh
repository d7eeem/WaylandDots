#!/bin/bash
REMOTE="truenas:/mnt/deimos/private/nautiles_inbox"
for SRC in "$@"; do
    rsync -avhrPO "$SRC" "$REMOTE" --remove-source-files
done
notify-send "Rsync complete" "Upload to $REMOTE finished."


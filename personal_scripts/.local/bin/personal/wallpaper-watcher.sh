#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

set -e

  #/home/tinker/.local/bin/personal/wal-on-wallpaper.sh
  # Initial wallpaper
  #
  #

  #
  # Get current GNOME wallpaper
  #
   
  # Initial wallpaper
WALLPAPER="$HOME/.config/background"
LAST_HASH=""

while true; do
while [[ ! -f "$WALLPAPER" ]]; do
    echo "[!] Waiting for wallpaper file to exist: $WALLPAPER"
    sleep 2
done

    CURRENT_HASH=$(sha256sum "$WALLPAPER" | awk '{print $1}')

    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
        echo "[+] Wallpaper content changed: $WALLPAPER"
	wal -c && wal -i "$WALLPAPER"
        LAST_HASH="$CURRENT_HASH"
    fi

    sleep 2
done

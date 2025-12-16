#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

set -e

WALLPAPER="$HOME/.config/background"
LAST_HASH=""
SLEEP_INTERVAL=2

echo "[*] Starting wallpaper monitor for: $WALLPAPER"

# Wait for wallpaper file to exist initially
while [[ ! -f "$WALLPAPER" ]]; do
    echo "[!] Waiting for wallpaper file to exist: $WALLPAPER"
    sleep "$SLEEP_INTERVAL"
done

echo "[+] Wallpaper file found, monitoring for changes..."

# Main monitoring loop
while true; do
    # Check if file still exists (might be deleted/recreated)
    if [[ ! -f "$WALLPAPER" ]]; then
        echo "[!] Wallpaper file disappeared, waiting for it to return..."
        while [[ ! -f "$WALLPAPER" ]]; do
            sleep "$SLEEP_INTERVAL"
        done
        echo "[+] Wallpaper file restored"
        # Reset hash to force update
        LAST_HASH=""
    fi
    
    # Calculate current hash
    CURRENT_HASH=$(sha256sum "$WALLPAPER" | awk '{print $1}')
    
    # Check if wallpaper content changed
    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
        echo "[+] Wallpaper content changed: $WALLPAPER"
        echo "[*] Applying pywal color scheme..."
        
        # Clear cache and generate new colors
        if wal -c && wal -i "$WALLPAPER"; then
            echo "[✓] Pywal applied successfully"
            LAST_HASH="$CURRENT_HASH"
        else
            echo "[✗] Failed to apply pywal, will retry on next change"
        fi
    fi
    
    sleep "$SLEEP_INTERVAL"
done

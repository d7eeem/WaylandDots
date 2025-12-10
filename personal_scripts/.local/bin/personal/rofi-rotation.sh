#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

# Configuration
WALLPAPER_SCRIPT="$HOME/.local/bin/personal/hypr-wall.sh"
WALLPAPER_DIR="$HOME/Nextcloud/wallpaper/"
ROFI_THEME="$HOME/.config/rofi/rofi-aux/rofi-aux.rasi"

# Check if wallpaper rotation is running
is_running() {
    pgrep -f "hypr-wall.sh" > /dev/null
}

# Rofi menu options
if is_running; then
    options="󰿅  Stop Wallpaper Rotation"
else
    options="󰋩  Start Wallpaper Rotation"
fi

# Show menu and get selection
selected=$(echo -e "$options" | rofi -dmenu -theme "$ROFI_THEME" )


# Handle selection
case "$selected" in
    "󰋩  Start Wallpaper Rotation")
        if [ -x "$WALLPAPER_SCRIPT" ] && [ -d "$WALLPAPER_DIR" ]; then
            nohup "$WALLPAPER_SCRIPT" "$WALLPAPER_DIR" > /dev/null 2>&1 &
            notify-send -i "$HOME/.config/swaync/icons/picture.png" "Wallpaper Rotation" "Started"
        else
            notify-send -u critical "Error" "Script or directory not found"
        fi
        ;;
    "󰿅  Stop Wallpaper Rotation")
        pkill -f "hypr-wall.sh"
        notify-send -i "$HOME/.config/swaync/icons/picture.png" "Wallpaper Rotation" "Stopped"
        ;;
esac

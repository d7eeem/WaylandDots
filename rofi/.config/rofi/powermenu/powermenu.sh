#!/usr/bin/env bash

# List of options with emoji or icons
options=(
  "  Shutdown"
  "  Reboot"
  "  Suspend"
  "  Lock"
  "  Logout"
)

# Turn array into newline-separated string
choice=$(printf "%s\n" "${options[@]}" | rofi -dmenu -theme ~/.config/rofi/powermenu/config.rasi -p "Power Menu")

case "$choice" in
"  Shutdown") systemctl poweroff ;;
"  Reboot") systemctl reboot ;;
"  Suspend") systemctl suspend ;;
"  Lock") hyprlock ;;
"  Logout") hyprctl dispatch exit ;;
esac

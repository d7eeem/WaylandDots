#!/bin/bash
SCRIPT_PATH="$HOME/.config/waybar/scripts/idle-inhibitor.sh"

# Show rofi menu for duration selection
choice=$(echo -e "∞ Indefinite\n30 minutes\n1 hour\n2 hours\n4 hours\n Custom...\nTurn Off" | rofi -dmenu -p "Idle Inhibitor Duration" -config "$HOME/.config/rofi/clipboard/clipboard.rasi")

case "$choice" in
"∞ Indefinite")
  $SCRIPT_PATH duration
  ;;
"30 minutes")
  $SCRIPT_PATH duration 30
  ;;
"1 hour")
  $SCRIPT_PATH duration 60
  ;;
"2 hours")
  $SCRIPT_PATH duration 120
  ;;
"4 hours")
  $SCRIPT_PATH duration 240
  ;;
" Custom...")
  # Prompt for custom duration in minutes
  custom=$(echo "" | rofi -dmenu -p "Enter minutes (e.g., 77)" -config "$HOME/.config/rofi/clipboard/clipboard.rasi")
  if [[ "$custom" =~ ^[0-9]+$ ]]; then
    $SCRIPT_PATH duration "$custom"
  fi
  ;;
"Turn Off")
  $SCRIPT_PATH toggle
  ;;
esac
# Show walker menu for duration selection
# choice=$(printf "∞ Indefinite\n30 minutes\n1 hour\n2 hours\n4 hours\nTurn Off" | walker --dmenu)
#
# case "$choice" in
# "∞ Indefinite")
#   $SCRIPT_PATH duration
#   ;;
# "30 minutes")
#   $SCRIPT_PATH duration 30
#   ;;
# "1 hour")
#   $SCRIPT_PATH duration 60
#   ;;
# "2 hours")
#   $SCRIPT_PATH duration 120
#   ;;
# "4 hours")
#   $SCRIPT_PATH duration 240
#   ;;
# "Turn Off")
#   $SCRIPT_PATH toggle
#   ;;
# esac

pkill -RTMIN+8 waybar

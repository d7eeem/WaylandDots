#!/bin/env bash

vram_usage=$(cat /sys/class/drm/card0/device/mem_info_vram_used)

case $BLOCK_BUTTON in
# 1) notify-send "Active Processes" "$(nvidia-smi | awk '/ G / {print $7 "            " $ 8}' | sed 's/\/usr\/lib\///g' | sed 's/firefox\///g')" ;;
1) notify-send "Active Processes" "$( printf "%.3f\n" $(echo "$vram_usage / 1024/1024/1024" | bc -l) )GiB" ;;
2) ;;
3) ;;
6) "$TERMINAL" -e "$EDITOR" "$0" ;;
esac

temp1=$(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input)

# printf "%s\n" " $(nvidia-smi -q | rg 'GPU Current Temp' | awk '{print $5 "°"}')"
# printf "%s\n" " $(/opt/rocm/bin/rocm-smi --showtemp | grep edge | awk '{print $7  "°"}')"
printf "%s°\n" "  $(( $temp1 / 1000 ))"

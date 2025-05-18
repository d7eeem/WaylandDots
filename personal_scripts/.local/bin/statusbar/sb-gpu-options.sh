#!/bin/env bash

vram_usage=$(cat /sys/class/drm/card0/device/mem_info_vram_used)

# printf "%.3f%s\n" "$(echo "$vram_usage / 1024/1024/1024" | bc -l)" " "GiBprintf
vram_in_notification=$(printf "%.3f%s\n" "$(echo "$vram_usage / 1024/1024/1024" | bc -l)" " "GiB)

notify-send "VRAM USED" "$vram_in_notification"

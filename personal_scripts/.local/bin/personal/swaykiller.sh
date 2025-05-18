#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

set -x

if [[ -n $(pgrep swayidle) ]]; then
  notify-send "swayidle is killed"
  killall swayidle
  else
    notify-send "swayidle is working"
    swayidle -w timeout 300 'hyprlock' #timeout 360 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on && kanshi'
fi

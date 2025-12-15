#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

uwsm app -a btop -- kitty -e btop &
sleep 0.3
hyprctl dispatch togglefloating
hyprctl dispatch resizeactive exact 1250 800
hyprctl dispatch centerwindow

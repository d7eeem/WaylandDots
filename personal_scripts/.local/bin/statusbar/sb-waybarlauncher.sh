#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

setsid -f /home/tinker/.local/bin/statusbar/sb-waybarwaller.sh && sleep 1 && killall -9 waybar && sleep 1 && setsid -f waybar

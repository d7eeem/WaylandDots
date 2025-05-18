#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


if [ ! -e "/tmp/${HYPRLAND_INSTANCE_SIGNATURE}.wob" ]; then
  mkfifo "/tmp/${HYPRLAND_INSTANCE_SIGNATURE}.wob" && tail -f "/tmp/${HYPRLAND_INSTANCE_SIGNATURE}.wob" | wob -c /home/tinker/.config/wob/wob.ini
else
  tail -f "/tmp/${HYPRLAND_INSTANCE_SIGNATURE}.wob" | wob -c /home/tinker/.config/wob/wob.ini -vv
fi

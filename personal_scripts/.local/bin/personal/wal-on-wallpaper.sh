#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


WALLPAPER_PATH=$(gsettings get org.gnome.desktop.background picture-uri | sed "s/'//g" | sed 's/file:\/\///')
wal -i "$WALLPAPER_PATH"

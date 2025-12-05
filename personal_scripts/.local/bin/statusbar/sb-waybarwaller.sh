#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem


$HOME/.config/theme_engine/theme_switcher.sh "$(find "$HOME/Nextcloud/Wallpapers" -iregex '.*.\(jpg\|jpeg\|png\|gif\)' -type f | shuf -n 1)"

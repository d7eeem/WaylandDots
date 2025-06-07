#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem


screenshot_file=$(hyprshot -m region | grep -oP 'Screenshot_region_[\d-]+_[\d-]+\.png') && swappy -f "$screenshot_file" && ~/.local/bin/personal/xbackbone_uploader.sh "$screenshot_file"

exec $screenshot_file

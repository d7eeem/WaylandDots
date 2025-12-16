#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

if [[ $# -lt 1 ]] || [[ ! -d "$1" ]]; then
	echo "Usage: $0 <dir containing images>"
	exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_STEP=2

# This controls (in seconds) when to switch to the next image
INTERVAL=30

# Supported image formats
FORMATS="jpg|jpeg|png|gif|bmp|webp"

while true; do
	find "$1" -type f -regextype posix-extended -iregex ".*\.($FORMATS)$" \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			swww img --transition-type random "$img"
			sleep "$INTERVAL"
		done
done

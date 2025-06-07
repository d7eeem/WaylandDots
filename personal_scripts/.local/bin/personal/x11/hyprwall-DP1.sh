#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

# swww kill
#
# imgloc="$HOME/unraid/archive/wallpaper-sort/Me/"
#
#
# ls "$imgloc" | shuf -n 1 | while read file; do 
# swww init && swww img "$imgloc/$file"
# done



if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
	echo "Usage:
	$0 <dir containing images>"
	exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_STEP=2

# This controls (in seconds) when to switch to the next image
INTERVAL=150

while true; do
	find "$1" \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			swww img --outputs DP-1 --transition-type random  "$img"
			sleep $INTERVAL
		done
done



#swww img --transition-type wipe --transition-angle 30 "$img"


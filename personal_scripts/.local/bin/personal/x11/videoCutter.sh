#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

if [[ -z "$1" ]]; then
	echo $0 [vod] [start] [end] [output]
else
	ffmpeg -i "$1" -ss $2 -to $3 -c copy "$4".mp4
fi

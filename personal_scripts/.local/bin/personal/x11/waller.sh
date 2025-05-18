#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

screen0() {
	screen2=$(xrandr -q | grep "HDMI" | awk '/ connected/ {print $1}' | sed -n '1p')
	bgloc1="${XDG_DATA_HOME:-$HOME/.local/share/}/bg1"
	if [ -n "$screen2" ]; then
		trueloc="$(readlink -f "$2")" &&
			case "$(file --mime-type -b "$trueloc")" in
			image/*) ln -sf "$(readlink -f "$2")" "$bgloc1" && notify-send -i "$bgloc1" "Changing wallpaper..." ;;
			inode/directory) ln -sf "$(find "$trueloc" -iregex '.*.\(jpg\|jpeg\|png\|gif\)' -type f | shuf -n 1)" "$bgloc1" && notify-send -i "$bgloc1" "Random Wallpaper chosen." ;;
			*)
				notify-send "Error" "Not a valid image."
				exit 1
				;;
			esac
		xwallpaper --zoom "$bgloc1"
	else
		notify-send "Error" "Not a valid image."
		exit 1
	fi
}

screen1() {
	screen3=$(xrandr -q | grep "DP-1" | awk '/ connected/ {print $1}' | sed -n '1p')
	bgloc2="${XDG_DATA_HOME:-$HOME/.local/share/}/bg2"
	if [ -n "$screen3" ]; then
		trueloc="$(readlink -f "$2")" &&
			case "$(file --mime-type -b "$trueloc")" in
			image/*) ln -sf "$(readlink -f "$2")" "$bgloc2" && notify-send -i "$bgloc2" "Changing wallpaper..." ;;
			inode/directory) ln -sf "$(find "$trueloc" -iregex '.*.\(jpg\|jpeg\|png\|gif\)' -type f | shuf -n 1)" "$bgloc2" && notify-send -i "$bgloc2" "Random Wallpaper chosen." ;;
			*)
				notify-send "Error" "Not a valid image."
				exit 1
				;;
			esac
		xwallpaper --zoom "$bgloc2"
	else
		notify-send "Error" "Not a valid image."
		exit 1
	fi
}

case $1 in
0) screen0 "$2" ;;
1) screen1 "$2" ;;
*)
	screen0 "$1"
	screen1 "$1"
	;;

esac

#!/bin/sh

# Status bar module for disk space
# $1 should be drive mountpoint, otherwise assumed /.

location=${1:-/}

percent=$(
    df -H / | grep -vE '^Filesystem' | awk '{ print $5}' 
    )

[ -d "$location" ] || exit

case $BLOCK_BUTTON in
	1) notify-send "💽 Disk space" "$(df -t ext4 -t btrfs -t ntfs -t fuse.mergerfs -t fuse* -h --output=target,used,size,pcent)" ;;
	3) notify-send "💽 Disk module" "\- Shows used hard drive space.
- Click to show all disk info." ;;
	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
esac

# case "$location" in
# 	"/home"* ) icon="🏠" ;;
# 	"/mnt"* ) icon="💾" ;;
# 	# *) icon="🖥";;
# esac

printf "%s %s %s\n" "$percent"  •  "$(df -h "$location" | awk ' /[0-9]/ {print $3}')"

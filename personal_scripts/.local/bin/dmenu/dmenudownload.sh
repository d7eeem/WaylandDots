#!/bin/bash


# List all files in Downloads folder

# get choice of downloads files
choice=$(find "$HOME/Downloads" -type f | awk -F'/' '{print $NF}' | sort | dmenu -i -c -l 10 -p "Downloads:")
path=$(find "$HOME/Downloads" -iname "$choice")
echo "$path"
# if nothing is chosen then exit
[ "$choice" != "" ] || exit

xdg-open "$path"

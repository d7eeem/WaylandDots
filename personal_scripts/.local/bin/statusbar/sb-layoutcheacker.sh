#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

# Define the path to the configuration file
pathtofile="/home/tinker/.config/hypr/themes/theme.conf"

# Query the current layout setting
current_layout=$(grep 'layout =' "$pathtofile")

# Check the current layout and print the corresponding symbol
if [[ "$current_layout" == *"layout = dwindle"* ]]; then
  printf "@\n"
elif [[ "$current_layout" == *"layout = master"* ]]; then
  printf "%s\n" "|-"
else
  printf "Layout not found or unrecognized.\n"
fi

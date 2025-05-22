#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

# Define the path to the configuration file
# Query the current layout setting
current_layout=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

# Check the current layout and print the corresponding symbol
if [[ "$current_layout" == "dwindle" ]]; then
  printf "@\n"
elif [[ "$current_layout" == "master" ]]; then
  printf "%s\n" "|-"
else
  printf "Layout not found or unrecognized.\n"
fi

#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

# Get all visible windows
TREE=$(hyprctl clients -j | jq -r '.[] | select(.hidden==false and .mapped==true)')

# Get window positions and sizes, let user select one with slurp
SELECTION=$(echo "$TREE" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)

# Parse the selection
X=$(echo "$SELECTION" | awk -F'[, x]' '{print $1}')
Y=$(echo "$SELECTION" | awk -F'[, x]' '{print $2}')
W=$(echo "$SELECTION" | awk -F'[, x]' '{print $3}')
H=$(echo "$SELECTION" | awk -F'[, x]' '{print $4}')

# Find and display the matching window properties
hyprctl clients -j | jq --argjson x "$X" --argjson y "$Y" --argjson w "$W" --argjson h "$H" \
  '.[] | select(.hidden==false and .mapped==true) | select(.at[0]==$x and .at[1]==$y and .size[0]==$w and .size[1]==$h)'

#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem


TREE=$(hyprctl clients -j | jq -r '.[] | select(.hidden==false and .mapped==true)')
SELECTION=$(echo $TREE | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)

X=$(echo $SELECTION | awk -F'[, x]' '{print $1}')
Y=$(echo $SELECTION | awk -F'[, x]' '{print $2}')
W=$(echo $SELECTION | awk -F'[, x]' '{print $3}')
H=$(echo $SELECTION | awk -F'[, x]' '{print $4}')


$(hyprctl clients -j) | $(jq -r '.[] | select(.hidden==false and .mapped==true)') | $(jq -r $X --argjson y $Y --argjson w $W --argjson h $H ' . | select(.at[0]==$x and .at[1]==$y and .size[0]==$w and.size[1]==$h)')

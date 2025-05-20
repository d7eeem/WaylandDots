#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem
# set -e 
# set -x
#

# Define the path to the file
pathtofile="/home/tinker/.config/hypr/themes/theme.conf"

# Check if the file contains "layout = dwindle"
if grep -q "layout = dwindle" "$pathtofile"; then
  # If found, replace "layout = dwindle" with "layout = master"
  sed -i 's/layout = dwindle/layout = master/' "$pathtofile"
else
  # If not found, replace "layout = master" with "layout = dwindle"
  sed -i 's/layout = master/layout = dwindle/' "$pathtofile"
fi

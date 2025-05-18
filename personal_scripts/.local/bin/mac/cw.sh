#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title cw
# @raycast.mode inline
# @raycast.refreshTime 1h

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName cw

# Documentation:
# @raycast.description cw


case $1 in
*.PNG | *.png | *.jpg | *.JPG) ChangeMenuBarColor SolidColor "#000000" $1 ;;
*.GIF | *.gif) echo "can't set gif" ;;
*) ls /users/id7eeem/Documents/luna-central/wally/untitled/ | shuf -n 1 | while read file; do
	ChangeMenuBarColor SolidColor "#000000" /users/id7eeem/Documents/luna-central/wally/untitled/$file
done ;;
esac

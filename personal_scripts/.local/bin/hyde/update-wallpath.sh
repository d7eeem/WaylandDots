#!/bin/env bash

set -x

SYMLINK="/home/tinker/.cache/hyde/wall.set"
ABSOUL_SYMLINK_PATH=$(readlink -f $SYMLINK)
FILE="/home/tinker/.config/hypr/hyprlock.conf"

if [[ "$(file --mime-type "$ABSOUL_SYMLINK_PATH" | awk '{print $2}')" != image/png ]]; then
sed -i "s|path = .*|path = /home/tinker/Nextcloud/Wallpaper/hyprlock/08.png|" "$FILE"
else
  # Update the first occurrence with the .set path
  sed -i "0,/path = .*$/s|path = .*|path = $HOME/.cache/hyde/wall.set|" "$FILE"
  
  # Update the second occurrence with the .sqre path
  sed -i "0,/path = .*$/! {0,/path = .*$/s|path = .*|path = $HOME/.cache/hyde/wall.sqre|}" "$FILE"
fi


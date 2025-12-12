#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

source ~/.local/bin/personal/wallcacher.sh

declare -a media_files=()
declare -a cache_files=()

if generate_rofi_thumbnails \
  "$HOME/Pictures/wallpapaer/" \
  "$HOME/.cache/thumbnails" \
  media_files \
  cache_files; then
  echo "Found ${#media_files[@]} files"
  for i in "${!media_files[@]}"; do
    echo "${media_files[$i]} -> ${cache_files[$i]}"
  done
fi

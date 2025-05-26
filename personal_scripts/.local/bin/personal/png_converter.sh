#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem
# find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) ! -iname "*.gif" ! -iname "*.png" | while read -r file; do
#   newfile="${file%.*}.png"
#   parallel --bar magick "$file" "$newfile" && rm "$file"
# done

find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
  ! -iname "*.gif" ! -iname "*.png" \
  -print0 | parallel --bar -0 '
    newfile="{.}.png"
    magick "{}" "$newfile" && rm "{}"
'

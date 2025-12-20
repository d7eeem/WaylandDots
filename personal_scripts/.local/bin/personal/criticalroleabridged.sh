#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
#                    |___/
DIR="/mnt/deimos/downloads/ytptube/Critical Role Abridged/Critical Role Abridged/"
cd "$DIR" &&
  yt-dlp -f "bv*+ba/best" --merge-output-format mkv \
    --cookies-from-browser firefox \
    --ignore-errors \
    --sponsorblock-remove all \
    --write-info-json \
    --write-thumbnail \
    --embed-thumbnail \
    --write-description \
    --download-archive "$DIR/arcive.txt" \
    --write-comments \
    -o "%(title)s.%(ext)s" \
    "https://www.youtube.com/show/VLPL1tiwbzkOjQzLiaOJBpHvyQ46GtPefp2H?sbp=Kgtzb1J1V2pDZzZHTUAB"

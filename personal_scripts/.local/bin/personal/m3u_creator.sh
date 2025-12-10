#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem


# Define the directory to search in
# SEARCH_DIR="${1:-.}"  # Default to current directory if not provided
#
# # Define the output playlist file
# PLAYLIST_FILE="${2:-playlist.m3u}"  # Default to "playlist.m3u" if not provided
#
# # Define the MIME type for video files
# MIME_TYPE="video"
#
# # Find video files based on their MIME type and create the .m3u playlist
# #fd --type f --exec bash -c 'file --mime-type -b "$1" | grep -q "$2" && echo "$1"' _ {} "$MIME_TYPE" > "$PLAYLIST_FILE"
# fd --type f --exec bash -c 'file --mime-type -b "$1" | grep -q "$2" && echo "$1"' _ {} "video" >> playlist.m3u
#
# echo "Playlist created: $PLAYLIST_FILE"

# Define the directory to search in
SEARCH_DIR="${1:-.}"  # Default to current directory if not provided

# Define the output playlist file
PLAYLIST_FILE="${2:-playlist.m3u}"  # Default to "playlist.m3u" if not provided

# Define the MIME type for video files
MIME_TYPE="video"

# Find video files based on their MIME type and create the .m3u playlist
fd --type f --exec bash -c 'file --mime-type -b "$1" | grep -q "$2" && echo "$1"' _ {} "$MIME_TYPE" > "$PLAYLIST_FILE"

echo "Playlist created: $PLAYLIST_FILE"

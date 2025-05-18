#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

# Check if a directory argument is provided
if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") <target-directory>"
    exit 1
fi

# Define the source directory as the directory passed as an argument
SOURCE_DIR="$1"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "The directory $SOURCE_DIR does not exist."
    exit 1
fi

# Define the target directories for pictures and videos within the source directory
PICTURES_DIR="$SOURCE_DIR/Pictures"
VIDEOS_DIR="$SOURCE_DIR/Videos"

# Create the target directories if they don't exist
mkdir -p "$PICTURES_DIR"
mkdir -p "$VIDEOS_DIR"

# Loop over each file in the source directory
for file in "$SOURCE_DIR"/*; do
    if [ -f "$file" ]; then
        # Get the MIME type of the file
        mime_type=$(file --mime-type -b "$file")
        
        # Check if the file is an image
        if [[ $mime_type == image/* ]]; then
            mv "$file" "$PICTURES_DIR/"
        # Check if the file is a video
        elif [[ $mime_type == video/* ]]; then
            mv "$file" "$VIDEOS_DIR/"
        fi
    fi
done

echo "Files sorted successfully!"


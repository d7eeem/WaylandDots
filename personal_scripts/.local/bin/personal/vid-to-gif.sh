#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

# rev4 - changes suggested by KownBash https://www.reddit.com/r/bash/comments/5cxfqw/i_wrote_a_simple_video_to_gif_bash_script_thought/da19gjz/

# Usage function, displays valid arguments
usage() { echo "Usage: $0 [-f <fps, defaults to 15>] [-w <width, defaults to 480] inputfile" 1>&2; exit 1; }

# Default variables
fps=15
width=480

# getopts to process the command line arguments
while getopts ":f:w:" opt; do
    case "${opt}" in
        f) fps=${OPTARG};;
        w) width=${OPTARG};;
        *) usage;;
    esac
done

# shift out the arguments already processed with getopts
shift "$((OPTIND - 1))"
if (( $# == 0 )); then
    printf >&2 'Missing input file\n'
    usage >&2
fi

# set input variable to the first option after the arguments
input="$1"

# Extract filename from input file without the extension
filename=$(basename "$input")
#extension="${filename##*.}"
filename="${filename%.*}.gif"

# Debug display to show what the script is using as inputs
echo "Input: $#"
echo "Output: $filename"
echo "FPS: $fps"
echo "Width: $width"

# temporary file to store the first pass pallete
palette="/tmp/palette.png"

# options to pass to ffmpeg
filters="fps=$fps,scale=$width:-1:flags=lanczos"

# ffmpeg first pass
ffmpeg -v warning -i "$input" -vf "$filters,palettegen" -y $palette
# ffmpeg second pass
ffmpeg -v warning -i "$input" -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=3" -y "$filename"

# display output file size
filesize=$(du -h "$filename" | cut -f1)
echo "Output File Name: $filename"
echo "Output File Size: $filesize"

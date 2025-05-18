#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

set -e
set -x
set -v
# ffmpeg libva-mesa-driver libva-utils
checks() {
if [[ ! -x "$(command -v vainfo)" ]]; then
  echo "vainfo is not install"
fi
if [[ ! -x "$(command -v ffmpeg)" ]]; then
  echo "ffmpeg is not install"
fi
if [[ ! -e "$(pa -Q | grep libva-mesa-driver)" ]]; then
  echo "libva-mesa-driver is not installed"
fi
if [[ ! -e "$(pa -Q | grep libva-utils)" ]]; then
  echo "libva-utils is not installed"
fi
}

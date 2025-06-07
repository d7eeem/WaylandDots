#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

if [ -n "$1" ];then  
    mpv --no-audio-display --volume=50 "$1" 
  else
    du -a /home/$USER | cut -f2- | grep 'mp3$\|ogg$\|wav$\|m4a$' | fzf | xargs -I '{}' mpv --no-audio-display --volume=50 {}

fi

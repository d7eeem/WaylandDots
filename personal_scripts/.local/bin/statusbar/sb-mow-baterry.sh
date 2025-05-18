#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

battery=$(mow report battery)


if [ -z "$battery" ]; then 
  exit
elif [[ $battery =~ Error || $battery =~ sleep ]]; then
 exit 
 else
  echo " $battery"
fi


# on Arch and it's flavours install mow-git from AUR and on other distros install from source 

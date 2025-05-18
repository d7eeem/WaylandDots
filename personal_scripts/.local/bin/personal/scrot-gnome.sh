#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem



area () {
gnome-screenshot --area -f /home/tinker/Pictures/gnome/screenshot_area_$(date +"%Y%m%d_%H%M%S").png  && $HOME/.local/bin/personal/xbackbone_uploader.sh "$(find /home/tinker/Pictures/gnome -maxdepth 1 -type f -iname "*area*" | tail -n 1)"
}

window (){
gnome-screenshot --window -f /home/tinker/Pictures/gnome/screenshot_window_$(date +"%Y%m%d_%H%M%S").png  && $HOME/.local/bin/personal/xbackbone_uploader.sh "$(find /home/tinker/Pictures/gnome -maxdepth 1 -type f -iname "*window*" | tail -n 1)"
}


case "$1" in
  area) area
  ;;
  window) window
  ;;
esac



#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem



sm() {
  hyprshot -m output -m active -o ~/Nextcloud/Hyprshot/ -- /home/tinker/.local/bin/personal/xbackbone_uploader.sh
}

sw() {
  hyprshot -m window -o ~/Nextcloud/Hyprshot/ -- /home/tinker/.local/bin/personal/xbackbone_uploader.sh
}

sa() {
  hyprshot -m region -o ~/Nextcloud/Hyprshot/ -- /home/tinker/.local/bin/personal/xbackbone_uploader.sh
}


case "$1" in
  sw)
    sw
    ;;
  sa)
    sa
    ;;
  sm|*)
    sm
    ;;
esac

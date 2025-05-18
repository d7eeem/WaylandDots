#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

DATE=$(date +"%Y-%m-%d_%H-%M")

monitor ()
{
  spectacle -bnm -C -o /home/tinker/Nextcloud/KDEScreenshots/Screenshot_full_"$DATE".png && "$HOME"/.local/bin/personal/xbackbone_uploader.sh "$(find /home/tinker/Nextcloud/KDEScreenshots -maxdepth 1 -type f -iname "*full*" | tail -n 1)"
}
#   spectacle -bnm -o /home/tinker/Nextcloud/KDEScreenshots/Screenshot_$(date +"%Y-%m-%d_%H-%M").png && "$HOME"/.local/bin/personal/xbackbone_uploader.sh /home/tinker/Nextcloud/KDEScreenshots/Screenshot_$(date +"%Y-%m-%d_%H-%M").png


window ()
{
  spectacle -bnu -C -o /home/tinker/Nextcloud/KDEScreenshots/Screenshot_window_"$DATE".png && "$HOME"/.local/bin/personal/xbackbone_uploader.sh "$(find /home/tinker/Nextcloud/KDEScreenshots -maxdepth 1 -type f -iname "*window*" | tail -n 1)"
#   spectacle -bnu -o /home/tinker/Nextcloud/KDEScreenshots/Screenshot_$(date +"%Y-%m-%d_%H-%M").png && "$HOME"/.local/bin/personal/xbackbone_uploader.sh /home/tinker/Nextcloud/KDEScreenshots/Screenshot_$(date +"%Y-%m-%d_%H-%M").png
}

region ()
{
  spectacle -bnr -s -C -o /home/tinker/Nextcloud/KDEScreenshots/Screenshot_region_"$DATE".png && "$HOME"/.local/bin/personal/xbackbone_uploader.sh "$(find /home/tinker/Nextcloud/KDEScreenshots -maxdepth 1 -type f -iname "*region*" | tail -n 1)"
}
#   spectacle -bnr -o /home/tinker/Nextcloud/KDEScreenshots/Screenshot_$(date +"%Y-%m-%d_%H-%M").png && "$HOME"/.local/bin/personal/xbackbone_uploader.sh /home/tinker/Nextcloud/KDEScreenshots/Screenshot_$(date +"%Y-%m-%d_%H-%M").png


case "$1" in
  monitor) monitor
  ;;
  region) region
  ;;
  window) window
  ;;
esac

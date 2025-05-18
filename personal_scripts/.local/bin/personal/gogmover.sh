#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem
echo "Script started" >> ./debug.log
/usr/bin/find . -type f ! -name .stfolder -exec /usr/bin/rsync -avrP {} root@10.10.10.8:/mnt/deimos/games/video/computer/torrented/GOG/ --log-file=./log.log \;
echo "Script ended" >> ./debug.log

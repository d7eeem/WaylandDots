#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

#waybar_dir="$HOME/.config/waybar/"
#
#
#killall waybar
#waybar --config "${waybar_dir}"/config.jsonc --style "${waybar_dir}"/style.css > /dev/null 2>&1 &


case "$1" in
  C)
    ~/.local/bin/hyde/wbarconfgen.sh
    ;;
  n)
    ~/.local/bin/hyde/wbarconfgen.sh n
    ;;
esac

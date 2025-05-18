#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

printf "%s\n" "$(sed "s/.*/🔒/" /sys/class/net/{wg*,tun*,nord*}/operstate 2>/dev/null)"

case $BLOCK_BUTTON in
  1) notify-send "You Arew Connected to " "$(ip a | grep  -o "nordlynx\|wg0\|wg-mullvad\|tun[0-9]{1,}" | head -n 1)" ;;
  3) if ip a | grep -q "nordlynx"; then
    nordvpn disconnect
  elif ip a | grep -q "wg-mullvad"; then
    mullvad disconnect
    fi
    ;;
esac


#!/bin/sh
wg0=$(ip a | grep wg0 || grep wg-mullvad)
if [ -z "$wg0"  ]; then
	icon="  "
else
	icon="  "
fi

printf "%s\n" "$icon"

case $BLOCK_BUTTON in
	1) sudo wg-quick up wg0 && notify-send "VPN " "VPN has been Activated" ;;
	9) notify-send "menu" "\- Left Click to Activate
- Right Click to Deactivate" ;;
	3) sudo wg-quick down wg0 && notify-send "VPN " "VPN has been Deactivated";;
esac

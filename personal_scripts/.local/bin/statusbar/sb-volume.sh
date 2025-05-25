#!/bin/env bash


muter ()
{
  mute=$(pamixer --get-mute) 
  if [[ ${mute} == "false" ]]; then
    swayosd-client --output-volume mute-toggle
    else
    swayosd-client --output-volume mute-toggle
  fi
}

muter

# case $BLOCK_BUTTON in
# 	1) pavucontrol ;;
# 	2) pamixer -t ;;
# 	4) pamixer --allow-boost -i 1 ;;
# 	5) pamixer --allow-boost -d 1 ;;
# 	3) notify-send "📢 Volume module" "\- Shows volume 🔊, 🔇 if muted.
# - Middle click to mute.
# - Scroll to change." ;;
# 	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
# esac
#
# vol="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
#
# # If muted, print 🔇 and exit.
# [ "$vol" != "${vol%\[MUTED\]}" ] && echo 󰖁 && exit
# # [ "$vol" != "${vol%\[MUTED\]}" ] && echo 🔇 && exit
#
# vol="${vol#Volume: }"
# split() {
# 	# For ommiting the . without calling and external program.
# 	IFS=$2
# 	set -- $1
# 	printf '%s' "$@"
# }
# vol="$(split "$vol" ".")"
# vol="${vol##0}"
#
# # emoji
# # case 1 in
# # 	$((vol >= 70)) ) icon="🔊" ;;
# # 	$((vol >= 30)) ) icon="🔉" ;;
# # 	$((vol >= 1)) ) icon="🔈" ;;
# # 	* ) echo 🔇 && exit ;;
# # esac
#
# #Ascci
# case 1 in
# 	$((vol >= 70)) ) icon=" " ;;
# 	$((vol >= 30)) ) icon=" " ;;
# 	$((vol >= 1)) ) icon=" " ;;
# 	* ) echo 󰖁 && exit ;;
# esac
#
# echo "$vol $icon"

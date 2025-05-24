#!/bin/bash


# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Airpods Battery
# @raycast.mode inline
# @raycast.refreshTime 5m
# Optional parameters:
# @raycast.icon 🎧

# Headphones IDs
airpod_id=0x200E
solo_id=0x2006

if [[ $(system_profiler SPBluetoothDataType | grep -b2 $airpod_id | awk '/Connected/{print $3}') == Yes ]]; then
	case=$(system_profiler SPBluetoothDataType | awk '/Case Battery Level/{print $4}')
	left=$(system_profiler SPBluetoothDataType | awk '/Left Battery Level/{print $4}')
	right=$(system_profiler SPBluetoothDataType | awk '/Right Battery Level/{print $4}')
	echo "🎧 Case $case, Right $right, Left $left."
elif [[ $(system_profiler SPBluetoothDataType | grep -b2 $solo_id | awk '/Connected/{print $3}') == Yes ]]; then
	bat=$(system_profiler SPBluetoothDataType | awk '/Battery Level/{print $3}')
	echo "🎧 solo³ is at $bat"
else
	echo "No Headphones connected. 🤷"
	exit 0
fi

#!/bin/bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem
xx=$(yabai -m query --windows --window)
curWindowId="$(echo $xx | jq -re ".id")"

focusWindow() {
    $(yabai -m window --focus $1) # $1 is the first argument passed in (window id).
}

$(yabai -m window --display prev || yabai -m window --display last)
focusWindow "$curWindowId"

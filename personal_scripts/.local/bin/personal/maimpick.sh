#!/bin/sh

# This is bound to Shift+PrintScreen by default, requires maim. It lets you
# choose the kind of screenshot to take, including copying the image or even
# highlighting an area to copy. scrotcucks on suicidewatch right now.

case "$(printf "full screenshot\\ncurrent window\\na selected area\\na selected area (copy)\\ncurrent window (copy)\\nfull screen (copy)" | dmenu -c -l 6 -i -p "Screenshot which area?")" in
  "full screenshot") maim /home/id7eeem/Pictures/screenshots/scrot-full-"$(date '+%y%m%d-%H%M-%S').png";;
	"current window") maim -m 1 -i "$(xdotool getactivewindow)" ~/Pictures/screenshots/scrot-window-"$(date '+%y%m%d-%H%M-%S').png" ;;
	"a selected area") maim -m 1 -s /home/id7eeem/Pictures/screenshots/scrot-selected-"$(date '+%y%m%d-%H%M-%S').png" ;;
	"a selected area (copy)") maim -m 1 -s | xclip -selection clipboard -t image/png ;;
	"current window (copy)") maim -m 1 -i "$(xdotool getactivewindow)" | xclip -selection clipboard -t image/png ;;
	"full screen (copy)") maim -m 1 | xclip -selection clipboard -t image/png ;;
esac

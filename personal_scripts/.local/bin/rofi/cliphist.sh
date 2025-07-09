#!/usr/bin/env bash

case "${1}" in
c|-c|--copy)
    cliphist list | rofi -dmenu -p "Copy..." -config "/home/tinker/.config/rofi/clipboard/clipboard.rasi" |cliphist decode | wl-copy
    ;;
d|-d|--delete)
    cliphist list | rofi -dmenu -p "Delete..." -config "/home/tinker/.config/rofi/clipboard/clipboard.rasi" | cliphist delete
    ;;
w|-w|--wipe)
 if [ "$(echo -e "Yes\nNo" | rofi -dmenu -p "Clear Clipboard History?" -config "/home/tinker/.config/rofi/clipboard/clipboard.rasi")" == "Yes" ]; then
    cliphist wipe
fi
    ;;
*)
    echo -e "cliphist.sh [action]"
    echo "c -c --copy    :  cliphist list and copy selected"
    echo "d -d --delete  :  cliphist list and delete selected"
    echo "w -w --wipe    :  cliphist wipe database"
    exit 1
    ;;
esac


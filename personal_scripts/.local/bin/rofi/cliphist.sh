#!/usr/bin/env bash

case "${1}" in
c|-c|--copy)
    cliphist list | rofi -dmenu -theme-str "entry { placeholder: \"Copy...\";}" -config "/home/tinker/.config/rofi/launchers/type-7/style-9.rasi" |cliphist decode | wl-copy
    ;;
d|-d|--delete)
    cliphist list | rofi -dmenu -theme-str "entry { placeholder: \"Delete...\";}" -config "/home/tinker/.config/rofi/launchers/type-7/style-9.rasi" | cliphist delete
    ;;
w|-w|--wipe)
 if [ "$(echo -e "Yes\nNo" | rofi -dmenu -theme-str "entry { placeholder: \"Clear Clipboard History?\";}" -config "/home/tinker/.config/rofi/launchers/type-7/style-9.rasi")" == "Yes" ]; then
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



dir="$HOME/.config/rofi/launchers/type-7"
theme='style-9'

## Run
rofi \
    -show "$1" \
    -theme ${dir}/${theme}.rasi

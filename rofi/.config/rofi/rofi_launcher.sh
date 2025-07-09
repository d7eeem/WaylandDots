
#dir="/home/tinker/WaylandDots/rofi/.config/rofi/launchers/type-1"
dir="/home/tinker/WaylandDots/rofi/.config/rofi/launchers/type-1"
#theme='style-1"
theme='style-2'

## Run
rofi \
    -show "$1" \
    -theme ${dir}/${theme}.rasi

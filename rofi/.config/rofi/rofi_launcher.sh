#!/bin/env bash
dir="$HOME/WaylandDots/rofi/.config/rofi/launchers/type-1"
theme='style-5'

## Run
rofi \
    -show "$1" \
    -theme ${dir}/${theme}.rasi \
    -run-command "uwsm app -- {cmd}"

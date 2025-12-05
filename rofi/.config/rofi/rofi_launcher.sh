#!/bin/env bash
dir="/home/tinker/WaylandDots/rofi/.config/rofi/launchers/type-3"
theme='config'
#theme='style-1'

## Run
rofi \
    -show "$1" \
    -theme ${dir}/${theme}.rasi \
    #-run-command "uwsm app -- {cmd}"

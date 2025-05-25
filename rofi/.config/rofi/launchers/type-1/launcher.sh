#!/usr/bin/env bash

dir="/home/tinker/.config/rofi/launchers/type-1"
theme='style-5'

rofi \
    -show $1 \
    -theme ${dir}/${theme}.rasi

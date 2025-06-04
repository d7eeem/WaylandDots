#!/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem

# Change to suite your flavor / accent combination
export FLAVOR="mocha"
export ACCENT="mauve"

# Set the theme


sudo flatpak override --env=GTK_THEME="Everforest-Dark"
#sudo flatpak override --env=GTK_THEME="catppuccin-${FLAVOR}-${ACCENT}-standard+default"

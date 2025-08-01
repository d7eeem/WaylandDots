#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

cd "$HOME"/.local/bin && 
  fzf --preview 'bat --style=numbers --color=always --line-range :500 {}' | 
  xargs -I '{}' nvim {}

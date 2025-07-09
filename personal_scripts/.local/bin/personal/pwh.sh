#!/bin/bash

# Get the current path, replacing /home/username with $HOME
current_path="${PWD/#$HOME/\$HOME}"

# If an argument is provided, append it to the path
if [ -n "$1" ]; then
  echo -n "$current_path/$1" | wl-copy
else
  echo -n "$current_path" | wl-copy
fi

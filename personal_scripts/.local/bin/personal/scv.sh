#!/bin/sh

cd "$HOME"/.local/bin/ && fzf --preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window='top:50%' | xargs -I '{}' nvim {}
# cd "$HOME/WaylandDots/personal_scripts/.local/bin" &&
#   find . -type d \( -name "mac" -o -name "windows" \) -prune -o -type f -print |
#   sed 's|^\./||' |
#     fzf --multi \
#       --preview 'bat --style=numbers --color=always --line-range :500 {}' \
#       --preview-window='top:50%' |
#     xargs -r nvim

# fd --type f . "$HOME/WaylandDots/personal_scripts/.local/bin" \
#   --exclude mac \
#   --exclude windows |
#   fzf --multi \
#     --preview 'bat --style=numbers --color=always --line-range :500 {}' \
#     --preview-window='right:50%' |
#   xargs -r nvim

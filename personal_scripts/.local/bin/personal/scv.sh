#!/bin/sh

cd "$HOME"/.local/bin/ && \
fzf --walker-skip .git,node_modules,mac,windows \
    --preview 'bat --style=numbers --color=always --line-range :500 {}' \
    --preview-window='top:50%' | \
xargs -I '{}' nvim {}

#!/bin/sh

cd "$HOME"/.local/bin/ && fzf --preview 'bat --style=numbers --color=always --line-range :500 {}' | xargs -I '{}' nvim {}

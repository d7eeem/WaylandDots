#!/bin/bash

source ~/.zshenv

# export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | paste -sd ':' -)"
# export PATH="${PATH}:$HOME/.local/bin/personal/"
# export PATH="${PATH}:$HOME/dots/scripts/.local/bin/personal/"
# export PATH="${PATH}:$HOME/.local/bin/dmenu"
# export PATH="${PATH}:$HOME/dots/scripts/.local/bin/dmenu/"
# export PATH="${PATH}:$HOME/.local/bin/lukes"
# export PATH="${PATH}:$HOME/dots/scripts/.local/bin/lukes/"
# export PATH="${PATH}:$HOME/.local/bin/statusbar/"
# export PATH="${PATH}:$HOME/dots/scripts/.local/bin/statusbar/"
# export PATH="${PATH}:$HOME/dots/shell/.config/shell/"
#
# export DOWNGRADE_FROM_ALA=1
#
# # Default programs:
# # export BROWSER="firefox"
# export FILEMANAGER="thunar"
# export DMENUCMD="rofi -show drun"
# export EDITOR=nvim
# export VISUAL="$EDITOR"
# export TERMINAL="st"
# export AWT_TOOLKIT=MToolkit
# export _JAVA_AWT_WM_NONREPARENTING=1
# export AWT_TOOLKIT=MToolkit
# export WXSUPPRESS_SIZER_FLAGS_CHECK
#
# # ~/ Clean-up:
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DOWNLOADS_HOME="$HOME/Downloads"
# export XINITRC="${XDG_CONFIG_HOME:-$HOME/.config}/x11/xinitrc"
# export LESSHISTFILE="-"
# export WGETRC="$HOME/.config/wget/wgetrc"
# export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/shell/inputrc"
# export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
# export WINEPREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/default"
# export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
# export PATH="$HOME/.local/share/node_modules/bin:$PATH"
# export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
# export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/history"
# export DICS="/usr/share/stardict/dic/"
# export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
# export LF_ICONS="/home/id7eeem/.config/shell/lf-icons"
# export SUDO_ASKPASS="$HOME/.local/bin/dmenu/dmenupass.sh"
#
#
#
#
#
# # export XDG_RUNTIME_DIR="/tmp/runtime-root"
# # FZF
# # export FZF_DEFAULT_OPTS="--layout=reverse-list --inline-info --height 40% --ansi --border=rounded"
# # export FZF_COMPLETION_TRIGGER='~~'
# # export FZF_COMPLETION_OPTS='--border --info=inline'
# #
# #
# # _fzf_compgen_path() {
# #   fd --hidden --follow --exclude ".git" . "$1"
# # }
# #
# # # Use fd to generate the list for directory completion
# # _fzf_compgen_dir() {
# #   fd --type d --hidden --follow --exclude ".git" . "$1"
# # }
# #
# # # (EXPERIMENTAL) Advanced customization of fzf options via _fzf_comprun function
# # # - The first argument to the function is the name of the command.
# # # - You should make sure to pass the rest of the arguments to fzf.
# # _fzf_comprun() {
# #   local command=$1
# #   shift
# #
# #   case "$command" in
# #     cd)           fzf "$@" --preview 'tree -C {} | head -200' ;;
# #     export|unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
# #     ssh)          fzf "$@" --preview 'dig {}' ;;
# #     *)            fzf "$@" ;;
# #   esac
# # }
#
#
# [ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc ] && setsid shortcuts.sh >/dev/null 2>&1
#
# source /home/id7eeem/.config/shell/lf-icons

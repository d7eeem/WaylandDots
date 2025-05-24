#!/bin/bash
export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | paste -sd ':' -)"
export PATH="${PATH}:$HOME/.local/bin/personal/"
export PATH="${PATH}:$HOME/.local/bin/dmenu"
export PATH="${PATH}:$HOME/.local/bin/statusbar/"
export PATH="${PATH}:$HOME/.local/bin/hyper/"
export PATH="${PATH}:$HOME/.local/bin/hyde/"
export PATH="${PATH}:$HOME/.local/bin/sysutils/"

export DOWNGRADE_FROM_ALA=1
export RUST_BACKTRACE=1
export GAMESCOPE_WAYLAND_DISPLAY


# HYPRSHOT default save Location
export HYPRSHOT_DIR="$HOME/Nextcloud/Hyprshot"



# Default programs:
# export BROWSER="firefox"
export FILEMANAGER="thunar"
export DMENUCMD="rofi -show drun"
export EDITOR="nvim"
export VISUAL="$EDITOR"
export TERMINAL="kitty"
export IMGPRE="imv-dir"
# export WXSUPPRESS_SIZER_FLAGS_CHECK

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DOWNLOADS_HOME="$HOME/Downloads"
export WGETRC="$HOME/.config/wget/wgetrc"
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/shell/inputrc"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
#export WINEPREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/default"
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export PATH="$HOME/.local/share/node_modules/bin:$PATH"
export DICS="/usr/share/stardict/dic/"
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo/bin"
export LF_ICONS="/home/tinker/.config/shell/lf-icons"
export SUDO_ASKPASS="$HOME/.local/bin/personal/askpass.sh"
export PATH=~/.npm-global/bin:$PATH

# Set GUI settings
export QT_QPA_PLATFORM=wayland
export QT_STYLE_OVERRIDE=kvantum
export QT_SCALE_FACTOR=1
export ELM_SCALE=1
export GDK_SCALE=1
export XCURSOR_SIZE=30
export SAL_USE_VCLPLUGIN=gtk3



### nnn
export NNN_FIFO=/tmp/nnn.fifo
export NNN_PLUG='p:preview-tui'
export USE_PISTOL=1
alias nnn='nnn -Pp'



[ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc ] && setsid shortcuts.sh >/dev/null 2>&1

source /home/tinker/.config/shell/lf-icons


ZSH_AUTOSUGGEST_STRATEGY=history

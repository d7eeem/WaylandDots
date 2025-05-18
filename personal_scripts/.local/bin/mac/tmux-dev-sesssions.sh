#!/bin/sh
#                               _
#  ___ _ __   ___ _ __ ___   __| |
# / __| '_ \ / __| '_ ` _ \ / _` |
# \__ | |_) | (__| | | | | | (_| |
# |___| .__/ \___|_| |_| |_|\__,_|
#     |_|
# Created by: spcmd
# http://spcmd.github.io
# https://github.com/spcmd

# Start a default tmux session with predefined windows/programs

tmux new-session -d -c "$HOME"
tmux new-window -n files -c "$HOME" mc
tmux -2 attach-session -d

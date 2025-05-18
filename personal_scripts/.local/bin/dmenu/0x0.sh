#!/bin/bash

curl -F"file=@$(du -a $HOME/Downloads | cut -f2- | dmenu -c -i -l 20 -p 'Share Link: ')" 0x0.st | wl-copy

#!/bin/sh
du -a $HOME |
	cut -f2- |
	grep -E 'mkv$|mp4$' |
	fzf |
	xargs -I '{}' mpv '{}'
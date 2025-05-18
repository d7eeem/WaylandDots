#!/bin/sh

# Feed script a url or file location.
# If an image, it will view in sxiv,
# if a video or gif, it will view in mpv
# if a music file or pdf, it will download,
# otherwise it opens link in browser.

# If no url given. Opens browser. For using script as $BROWSER.
[ -z "$1" ] && { "$BROWSER"; exit; }

case "$1" in
	*mkv|*webm|*mp4|*youtube.com/watch*|*youtube.com/playlist*|*youtu.be*|*hooktube.com*|*bitchute.com*|*videos.lukesmith.xyz*)
		open -a IINA "$1" >/dev/null 2>&1 ;;
	*png|*jpg|*jpe|*jpeg|*gif|*png*|*gif*|*jpg*|*jpe*|*jpeg*|*jpg?*)
		curl -sL "$1" > "/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")" && open -a feh.app "/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")"  >/dev/null 2>&1 & ;;
	*pdf|*cbz|*cbr)
		curl -sL "$1" > "/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")" && zathura "/tmp/$(echo "$1" | sed "s/.*\///;s/%20/ /g")"  >/dev/null 2>&1 & ;;
	*mp3|*flac|*opus|*mp3?source*|*.mp3?|*mp3*)
		open -a IINA  "$1"  ;;
	*)
		[ -f "$1" ] && setsid -f "$TERMINAL" -e "$EDITOR" "$1" >/dev/null 2>&1 || setsid -f "$BROWSER" "$1" >/dev/null 2>&1
esac

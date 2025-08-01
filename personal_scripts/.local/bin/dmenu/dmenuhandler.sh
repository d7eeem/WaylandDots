#!/bin/sh

# Feed this script a link and it will give dmenu
# some choice programs to use to open it.
feed="${1:-$(printf "%s" | dmenu -p 'Paste URL or file path')}"

case "$(printf "Copy URL\\nsxiv\\nsetbg\\nPDF\\nbrowser\\nlynx\\nvim\\nmpv\\nmpv loop\\nmpv float\\nqueue download\\nqueue yt-dlp\\nqueue yt-dlp audio" | dmenu -i -p "Open it with?")" in
	"Copy URL") echo "$feed" | xclip -selection clipboard ;;
	mpv) setsid -f mpv -quiet "$feed" >/dev/null 2>&1 ;;
	"mpv loop") setsid -f mpv -quiet --loop "$feed" >/dev/null 2>&1 ;;
	"mpv float") setsid -f "$TERMINAL" -e mpv --geometry=+0-0 --autofit=30%  --title="mpvfloat" "$feed" >/dev/null 2>&1 ;;
	"queue yt-dlp") qndl "$feed" >/dev/null 2>&1 ;;
	"queue yt-dlp audio") qndl "$feed" 'yt-dlp --embed-metadata -icx -f bestaudio/best' >/dev/null 2>&1 ;;
	"queue download") qndl "$feed" 'curl -LO' >/dev/null 2>&1 ;;
	PDF) curl -sL "$feed" > "/tmp/$(echo "$feed" | sed "s|.*/||;s/%20/ /g")" && zathura "/tmp/$(echo "$feed" | sed "s|.*/||;s/%20/ /g")"  >/dev/null 2>&1 ;;
	sxiv) curl -sL "$feed" > "/tmp/$(echo "$feed" | sed "s|.*/||;s/%20/ /g")" && sxiv -a "/tmp/$(echo "$feed" | sed "s|.*/||;s/%20/ /g")"  >/dev/null 2>&1 ;;
	vim) curl -sL "$feed" > "/tmp/$(echo "$feed" | sed "s|.*/||;s/%20/ /g")" && setsid -f "$TERMINAL" -e "$EDITOR" "/tmp/$(echo "$feed" | sed "s|.*/||;s/%20/ /g")"  >/dev/null 2>&1 ;;
	setbg) curl -L "$feed" > $XDG_CACHE_HOME/pic ; xwallpaper --zoom $XDG_CACHE_HOME/pic >/dev/null 2>&1 ;;
	browser) setsid -f "$BROWSER" "$feed" >/dev/null 2>&1 ;;
	lynx) lynx "$feed" >/dev/null 2>&1 ;;
esac


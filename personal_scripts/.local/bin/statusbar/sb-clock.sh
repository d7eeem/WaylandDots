#!/bin/sh

 clock=$(date '+%I')

 # case "$clock" in
 # 	"00") icon="🕛" ;;
 # 	"01") icon="🕐" ;;
 # 	"02") icon="🕑" ;;
 # 	"03") icon="🕒" ;;
 # 	"04") icon="🕓" ;;
 # 	"05") icon="🕔" ;;
 # 	"06") icon="🕕" ;;
 # 	"07") icon="🕖" ;;
 # 	"08") icon="🕗" ;;
 # 	"09") icon="🕘" ;;
 # 	"10") icon="🕙" ;;
 # 	"11") icon="🕚" ;;
 # 	"12") icon="🕛" ;;
 # 	"13") icon="🕐" ;;
 # 	"14") icon="🕑" ;;
 # 	"15") icon="🕒" ;;
 # 	"16") icon="🕓" ;;
 # 	"17") icon="🕔" ;;
 # 	"18") icon="🕕" ;;
 # 	"19") icon="🕖" ;;
 # 	"20") icon="🕗" ;;
 # 	"21") icon="🕘" ;;
 # 	"22") icon="🕙" ;;
 # 	"23") icon="🕚" ;;
 # esac
case "$clock" in
 	"00") icon="󱑊 " ;;
 	"01") icon="󱐿 " ;;
 	"02") icon="󱑀 " ;;
 	"03") icon="󱑁 " ;;
 	"04") icon="󱑂 " ;;
 	"05") icon="󱑃 " ;;
 	"06") icon="󱑄 " ;;
 	"07") icon="󱑅 " ;;
 	"08") icon="󱑆 " ;;
 	"09") icon="󱑇 " ;;
 	"10") icon="󱑈 " ;;
 	"11") icon="󱑉 " ;;
 	"12") icon="󱑊 " ;;
 	"13") icon="󱐿 " ;;
 	"14") icon="󱑀 " ;;
 	"15") icon="󱑁 " ;;
 	"16") icon="󱑂 " ;;
 	"17") icon="󱑃 " ;;
 	"18") icon="󱑄 " ;;
 	"19") icon="󱑅 " ;;
 	"20") icon="󱑆 " ;;
 	"21") icon="󱑇 " ;;
 	"22") icon="󱑈 " ;;
 	"23") icon="󱑉 " ;;
 esac

case $BLOCK_BUTTON in
	1) notify-send "     This Month" "$(cal --color=always | sed "s/..7m/<b><span color=\"red\">/;s/..27m/<\/span><\/b>/")"  ;;
	2) setsid -f "$TERMINAL" -e calcurse ;;
	3) notify-send "📅 Time/date module" "\- Left click to show upcoming appointments for the next three days via \`calcurse -d3\` and show the month via \`cal\`
- Middle click opens calcurse if installed" ;;
	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
esac

printf '%s%s\n'  "$icon" "$(date "+%H:%M|%d/%m/%Y")"

# printf '%s%s\n' "$icon" " $(date "+%H:%M|%d/%m/%Y")"

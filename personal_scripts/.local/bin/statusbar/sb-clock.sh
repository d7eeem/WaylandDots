#!/bin/env bash


# Get the current hour (24-hour format)
clock=$(date '+%H')

# Map hour to Nerd Font clock icon
case "$clock" in
    "00") icon="󱑊" ;;
    "01") icon="󱐿" ;;
    "02") icon="󱑀" ;;
    "03") icon="󱑁" ;;
    "04") icon="󱑂" ;;
    "05") icon="󱑃" ;;
    "06") icon="󱑄" ;;
    "07") icon="󱑅" ;;
    "08") icon="󱑆" ;;
    "09") icon="󱑇" ;;
    "10") icon="󱑈" ;;
    "11") icon="󱑉" ;;
    "12") icon="󱑊" ;;
    "13") icon="󱐿" ;;
    "14") icon="󱑀" ;;
    "15") icon="󱑁" ;;
    "16") icon="󱑂" ;;
    "17") icon="󱑃" ;;
    "18") icon="󱑄" ;;
    "19") icon="󱑅" ;;
    "20") icon="󱑆" ;;
    "21") icon="󱑇" ;;
    "22") icon="󱑈" ;;
    "23") icon="󱑉" ;;
esac


# Final text display
time=$(date '+%H:%M | %d/%m/%Y')

# Get today's day number (no leading zero)
today=$(date '+%-d')

# Build calendar
cal_output=$(cal)

# Color styles
color_month="#ffead3"
color_weekday="#ffcc66"
color_today="#ff6699"

# Format calendar with HTML coloring
calendar_html=""
while IFS= read -r line; do
    # Header (month and year)
    if [[ "$line" =~ [A-Za-z] ]]; then
        calendar_html+="<span style='color:${color_month}'><b>${line}</b></span>\n"
        continue
    fi

    # Weekday line
    if [[ "$line" =~ ^\ *S ]]; then
        calendar_html+="<span style='color:${color_weekday}'><b>${line}</b></span>\n"
        continue
    fi

    # Day numbers
    line_out=""
    for word in $line; do
        if [[ "$word" == "$today" ]]; then
            line_out+="<span style='color:${color_today}'><b>${word}</b></span> "
        else
            line_out+="${word} "
        fi
    done
    calendar_html+="${line_out% }\\n"
done <<< "$cal_output"

# Output JSON for Waybar
echo "{\"text\": \"$icon $time\", \"tooltip\": \"<tt>${calendar_html}</tt>\"}"


#
#  # clock=$(date '+%I')
#
#  # case "$clock" in
#  # 	"00") icon="🕛" ;;
#  # 	"01") icon="🕐" ;;
#  # 	"02") icon="🕑" ;;
#  # 	"03") icon="🕒" ;;
#  # 	"04") icon="🕓" ;;
#  # 	"05") icon="🕔" ;;
#  # 	"06") icon="🕕" ;;
#  # 	"07") icon="🕖" ;;
#  # 	"08") icon="🕗" ;;
#  # 	"09") icon="🕘" ;;
#  # 	"10") icon="🕙" ;;
#  # 	"11") icon="🕚" ;;
#  # 	"12") icon="🕛" ;;
#  # 	"13") icon="🕐" ;;
#  # 	"14") icon="🕑" ;;
#  # 	"15") icon="🕒" ;;
#  # 	"16") icon="🕓" ;;
#  # 	"17") icon="🕔" ;;
#  # 	"18") icon="🕕" ;;
#  # 	"19") icon="🕖" ;;
#  # 	"20") icon="🕗" ;;
#  # 	"21") icon="🕘" ;;
#  # 	"22") icon="🕙" ;;
#  # 	"23") icon="🕚" ;;
#  # esac
# case "$clock" in
#  	"00") icon="󱑊 " ;;
#  	"01") icon="󱐿 " ;;
#  	"02") icon="󱑀 " ;;
#  	"03") icon="󱑁 " ;;
#  	"04") icon="󱑂 " ;;
#  	"05") icon="󱑃 " ;;
#  	"06") icon="󱑄 " ;;
#  	"07") icon="󱑅 " ;;
#  	"08") icon="󱑆 " ;;
#  	"09") icon="󱑇 " ;;
#  	"10") icon="󱑈 " ;;
#  	"11") icon="󱑉 " ;;
#  	"12") icon="󱑊 " ;;
#  	"13") icon="󱐿 " ;;
#  	"14") icon="󱑀 " ;;
#  	"15") icon="󱑁 " ;;
#  	"16") icon="󱑂 " ;;
#  	"17") icon="󱑃 " ;;
#  	"18") icon="󱑄 " ;;
#  	"19") icon="󱑅 " ;;
#  	"20") icon="󱑆 " ;;
#  	"21") icon="󱑇 " ;;
#  	"22") icon="󱑈 " ;;
#  	"23") icon="󱑉 " ;;
#  esac
#
# printf '%s%s\n'  "$icon" "$(date "+%H:%M|%d/%m/%Y")"
#
# # printf '%s%s\n' "$icon" " $(date "+%H:%M|%d/%m/%Y")"
# # case $BLOCK_BUTTON in
# # 	1) notify-send "     This Month" "$(cal --color=always | sed "s/..7m/<b><span color=\"red\">/;s/..27m/<\/span><\/b>/")"  ;;
# # 	2) setsid -f "$TERMINAL" -e calcurse ;;
# # 	3) notify-send "📅 Time/date module" "\- Left click to show upcoming appointments for the next three days via \`calcurse -d3\` and show the month via \`cal\`
# # - Middle click opens calcurse if installed" ;;
# # 	6) "$TERMINAL" -e "$EDITOR" "$0" ;;
# # esac
#

#!/bin/bash

getforecast() { curl -sf "wttr.in/26.072474,43.964667" > "/Users/id7eeem/.local/share/weatherreport" || exit 1 ;}

showweather() { printf "%s" "$(sed '16q;d' "/Users/id7eeem/.local/share/weatherreport" |
	grep -wo "[0-9]*%" | sort -rn | sed "s/^/☔/g;1q" | tr -d '\n')"
sed '13q;d' "/Users/id7eeem/.local/share/weatherreport" | grep -o "m\\([-+]\\)*[0-9]\\+" | sort -n -t 'm' -k 2n | sed -e 1b -e '$!d' | tr '\n|m' ' ' | awk '{print " 🥶" $1 "°","🌞" $2 "°"}' ;}

[ "$(stat -c %y "/Users/id7eeem/.local/share/weatherreport" 2>/dev/null | cut -d' ' -f1)" = "$(date '+%Y-%m-%d')" ] ||
	getforecast



echo "🌦️"
echo "---"
showweather

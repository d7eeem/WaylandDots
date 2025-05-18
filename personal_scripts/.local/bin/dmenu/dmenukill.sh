#!/bin/sh
pid=$(ps -u $USER -o pid,%mem,%cpu,comm |
	sort -b -k2 -r |
	sed -n '1!p' |
	dmenu -c -i -l 20 -p "pid to kill!" |
	awk '{print $1}')
kill $pid
notify-send "The Process with PID of $pid has been Killed"

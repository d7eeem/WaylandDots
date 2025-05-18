#!/bin/bash
# <bitbar.title>Battery</bitbar.title>
# <bitbar.version>v0.1</bitbar.version>
# <bitbar.author>id7xyz</bitbar.author>
# <bitbar.author.github>d7eeem</bitbar.author.github>
# <bitbar.image>https://cdn.id7x.xyz/bbtt.png</bitbar.image>
# <bitbar.dependencies>pmset, grep, tr</bitbar.dependencies>


if pmset -g batt | grep AC &> /dev/null; then
    echo "⚡"
else
    echo "🔋"
fi
echo "---"
battery="$(pmset -g batt | grep -o '[0-9]*%')"

if [[ "${#battery}" -gt 3 ]] ; then
	echo "$battery" | tr -d '%'
else
	echo "$battery"
fi
echo "---"
# echo "Edit | terminal=true bash=nvim param1='$0'"

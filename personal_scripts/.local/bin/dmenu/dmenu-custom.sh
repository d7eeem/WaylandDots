#!/bin/env bash

namelist=(
  " ST"
  " calc"
  " ssh"
	" submenu"
	"漣Settings"
	" Browser"
	" Search"
  " Protondb"
  " HLTB"
	" Man"
	" Edit"
)

commandlist=(
  "st"
  "rofi -show calc"
  "dmenussh.sh"
	"submenu.sh"
	"dmenu-settings.sh"
	"$BROWSER"
	"dmenuduck.sh"
  "protondb.sh"
  "hltb.sh"
	"dmenu-man.sh"
	"$TERMINAL -e $EDITOR $0"
)

sel=$(printf '%s\n' "${namelist[@]}" | dmenu -i -c "$@" -p "dmenu")

if [ "$sel" ]; then
	for i in "${!namelist[@]}"; do
		if [ "${namelist[$i]}" = "$sel" ]; then
			break
		fi
	done

	${commandlist[$i]}
fi

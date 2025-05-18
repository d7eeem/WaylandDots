#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem
#
# Depindensec = dmenu 
# You give it a keyword or any thing and it will go to duckduckgo and serch for it 
# You can use bang '!' with a charcater to search other sites if you used bang with 'g' it will search google and bang with 'w' it will search wikipedia 'yt' for YouTube

duck="https://www.protondb.com/search?q="
BROWSER="firefox"


keyword=$(tac ~/.cache/search_history | dmenu -c -l 5 -p "Search")

[ -z "$keyword" ] || echo "$keyword" >> ~/.cache/search_history


[ -z "$keyword" ] && exit 0 || case $keyword in 
        d|delete|del) sed -i '1,$ d' ~/.cache/search_history;;
        *) $BROWSER "$duck""$keyword";;
    esac


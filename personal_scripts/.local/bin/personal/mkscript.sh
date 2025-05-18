#!/bin/sh
# Simple script to generate a script file in my scripts directory

printf "File Name: "

# Set a name for the script
while [ -z "$ans" ];
do
  read -r ans

  if [ -z "$ans" ]; then
    printf "File Name: "
  fi
done

file=$HOME/.local/bin/personal/$ans

if [ -d "$HOME/.local/bin/personal" ]; then
  if [ -e "$HOME/.local/bin/personal/$ans" ]; then
    $EDITOR "$file"
  else
    echo "#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem
" >> "$file"
    chmod +x "$file"
    $EDITOR "$file"
  fi
fi

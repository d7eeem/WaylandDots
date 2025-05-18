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

file=$HOME/.local/bin/mac/Bar/$ans

if [ -d "$HOME/.local/bin/mac/Bar" ]; then
  if [ -e "$HOME/.local/bin/mac/Bar/$ans" ]; then
    $EDITOR "$file"
  else
    echo "#!/bin/sh
# <bitbar.title>plexStream</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>id7xyz</bitbar.author>
# <bitbar.author.github>d7eeem</bitbar.author.github>
# <bitbar.image>https://cdn.id7x.xyz/fghdfghdfgh.png</bitbar.image>
# <bitbar.dependencies>jq</bitbar.dependencies>
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem
" >> "$file"
    chmod +x "$file"
    $EDITOR "$file"
  fi
fi

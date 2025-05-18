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

file=$HOME/.local/bin/dmenu/$ans

if [ -d "$HOME/.local/bin/dmenu" ]; then
  if [ -e "$HOME/.local/bin/dmenu/$ans" ]; then
file=$HOME/Repos/scripts/dmenu/$ans

if [ -d "$HOME/Repos/scripts/dmenu" ]; then
  if [ -e "$HOME/Repos/scripts/dmenu/$ans" ]; then
    $EDITOR "$file"
  else
    echo "#!/bin/sh" >> "$file"
    chmod +x "$file"
    $EDITOR "$file"
  fi
fi

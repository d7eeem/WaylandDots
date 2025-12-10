#!/bin/sh
# Simple script to generate a script file in my scripts directory

printf "File Name: "
# Set a name for the script
while [ -z "$ans" ]; do
  read -r ans
  if [ -z "$ans" ]; then
    printf "File Name: "
  fi
done

file="$HOME/.local/bin/personal/$ans.sh"

if [ -d "$HOME/.local/bin/personal" ]; then
  if [ -e "$file" ]; then
    echo "File already exists, opening in editor..."
    $EDITOR "$file"
  else
    cat > "$file" << 'EOF'
#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\\__, /___|
# Created by: d7eeem aka id7xyz
# https://github.com/d7eeem

EOF
    chmod +x "$file"
    $EDITOR "$file"
  fi
else
  echo "Error: Directory $HOME/.local/bin/personal does not exist!"
  exit 1
fi

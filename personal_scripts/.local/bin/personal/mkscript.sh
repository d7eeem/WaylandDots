#!/usr/bin/env bash
# Script generator with gum and directory selection

BASE_DIR="$HOME/.local/bin"

# Parse arguments
if [ "$1" = "--not-personal" ]; then
  SCRIPT_DIR="$BASE_DIR"
else
  # Build directory list
  dir_list="$BASE_DIR"$'\n'
  for dir in "$BASE_DIR"/*/; do
    dir_list+="${dir%/}"$'\n'
  done
  
  # Let user choose directory with gum filter (fuzzy find)
  SCRIPT_DIR=$(echo -n "$dir_list" | gum filter --placeholder "Search directory...")
  
  # Exit if cancelled
  if [ -z "$SCRIPT_DIR" ]; then
    echo "Cancelled."
    exit 0
  fi
fi

# Get filename with gum input
ans=$(gum input --placeholder "File Name")

# Exit if empty
if [ -z "$ans" ]; then
  echo "No filename provided."
  exit 1
fi

file="$SCRIPT_DIR/$ans"

# If file exists, confirm before opening
if [ -e "$file" ]; then
  gum confirm "File exists. Open in editor?" && ${EDITOR:-vi} "$file"
else
  # Create new file with template
  cat > "$file" << 'EOF'
#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
#                    |___/

EOF
  chmod +x "$file"
  gum style --foreground 212 "✓ Created: $file"
  
  # Ask if user wants to edit
  if gum confirm "Open in editor?"; then
    ${EDITOR:-vi} "$file"
  fi
fi


# #!/usr/bin/env bash
# # Script generator with gum and directory selection
#
# PERSONAL_DIR="$HOME/.local/bin/personal"
# SHARED_DIR="$HOME/.local/bin"
#
# # Parse arguments
# if [ "$1" = "--not-personal" ]; then
#   SCRIPT_DIR="$SHARED_DIR"
# else
#   # Let user choose directory with gum
#   SCRIPT_DIR=$(gum choose --header "Select directory:" "$PERSONAL_DIR" "$SHARED_DIR")
#   
#   # Exit if cancelled
#   if [ -z "$SCRIPT_DIR" ]; then
#     echo "Cancelled."
#     exit 0
#   fi
# fi
#
# # Get filename with gum input
# ans=$(gum input --placeholder "File Name")
#
# # Exit if empty
# if [ -z "$ans" ]; then
#   echo "No filename provided."
#   exit 1
# fi
#
# file="$SCRIPT_DIR/$ans"
#
# # Create directory if it doesn't exist
# if [ ! -d "$SCRIPT_DIR" ]; then
#   mkdir -p "$SCRIPT_DIR"
#   gum style --foreground 212 "Created directory: $SCRIPT_DIR"
# fi
#
# # If file exists, confirm before opening
# if [ -e "$file" ]; then
#   gum confirm "File exists. Open in editor?" && ${EDITOR:-vi} "$file"
# else
#   # Create new file with template
#   cat > "$file" << 'EOF'
# #!/usr/bin/env bash
# # _     _ _____
# #(_) __| |___  |_  ___   _ ____
# #| |/ _| |  / /\ \/ / | | |_  /
# #| | (_| | / /  >  <| |_| |/ /
# #|_|\__,_|/_/  /_/\_\__, /___|
# #                    |___/
#
# EOF
#   chmod +x "$file"
#   gum style --foreground 212 "✓ Created: $file"
#   ${EDITOR:-vi} "$file"
# fi


# #!/bin/sh
# # Simple script to generate a script file in my scripts directory
#
# SCRIPT_DIR="$HOME/.local/bin/personal"
#
# # Prompt for filename
# printf "File Name: "
# while [ -z "$ans" ]; do
#   read -r ans
#   if [ -z "$ans" ]; then
#     printf "File Name: "
#   fi
# done
#
# file="$SCRIPT_DIR/$ans"
#
# # Check if directory exists, create if not
# if [ ! -d "$SCRIPT_DIR" ]; then
#   mkdir -p "$SCRIPT_DIR"
#   echo "Created directory: $SCRIPT_DIR"
# fi
#
# # If file exists, just edit it
# if [ -e "$file" ]; then
#   echo "File exists, opening in editor..."
#   ${EDITOR:-vi} "$file"
# else
#   # Create new file with template
#   cat > "$file" << 'EOF'
# #!/usr/bin/env bash
# # _     _ _____
# #(_) __| |___  |_  ___   _ ____
# #| |/ _| |  / /\ \/ / | | |_  /
# #| | (_| | / /  >  <| |_| |/ /
# #|_|\__,_|/_/  /_/\_\__, /___|
# #                    |___/
#
# EOF
#   chmod +x "$file"
#   echo "Created new script: $file"
#   ${EDITOR:-vi} "$file"
# fi

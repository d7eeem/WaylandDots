#!/bin/sh
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
# Created by: d7eeem aka id7xyz
# https://gitlab.com/d7eeem



# Usage: git ignore <path>
# Adds path to .gitignore and removes from git cache if tracked

if [ $# -eq 0 ]; then
    echo "Usage: git ignore <path>"
    echo "Example: git ignore path/to/file.txt"
    exit 1
fi

PATH_TO_IGNORE="$1"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Get the root of the git repository
GIT_ROOT=$(git rev-parse --show-toplevel)
GITIGNORE="$GIT_ROOT/.gitignore"

# Create .gitignore if it doesn't exist
touch "$GITIGNORE"

# Check if path is already in .gitignore
if grep -Fxq "$PATH_TO_IGNORE" "$GITIGNORE"; then
    echo "Already in .gitignore: $PATH_TO_IGNORE"
else
    echo "$PATH_TO_IGNORE" >> "$GITIGNORE"
    echo "Added to .gitignore: $PATH_TO_IGNORE"
fi

# Check if the file is tracked by git
if git ls-files --error-unmatch "$PATH_TO_IGNORE" > /dev/null 2>&1; then
    echo "Removing from git cache: $PATH_TO_IGNORE"
    git rm --cached -r "$PATH_TO_IGNORE"
    echo "Successfully removed from tracking"
else
    echo "File was not tracked by git"
fi

echo "Done!"

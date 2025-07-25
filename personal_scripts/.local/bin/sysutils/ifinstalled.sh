#!/bin/sh

# Some optional functions in LARBS require programs not installed by default. I
# use this little script to check to see if a command exists and if it doesn't
# it informs the user that they need that command to continue. This is used in
# various other scripts for clarity's sake.

for x in "$@"; do
    pacman -Qq "$x" >/dev/null 2>&1 ||
    { notify-send "📦 $x" "must be installed for this function." && exit 1; }
done

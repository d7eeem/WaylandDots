#!/usr/bin/env fish

# Get used RAM in GB with icon (using the user's command, but with the correct icon for Waybar)
#set icon ""  # U+F1C0 (Font Awesome database icon)
set icon ""
set mem_text (free --mebi | sed -n '2{p}' | awk -v icn="$icon" '{printf ("%s %2.1fGB", icn, ($3 / 1024))}')

# Get top memory-consuming processes
set processes (ps axch -o cmd:15,%mem --sort -%mem | head)

# Escape newlines for JSON
set processes_json (string join '\\n' $processes)

# Output JSON for Waybar
set json (string join '' '{"text":"' $mem_text '", "tooltip":"' $processes_json '"}')
echo $json 

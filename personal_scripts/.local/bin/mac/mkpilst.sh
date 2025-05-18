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

file=/Users/id7eeem/Library/LaunchAgents/com.id7xyz.$ans.plist

if [ -d "/Users/id7eeem/Library/LaunchAgents" ]; then
  if [ -e "/Users/id7eeem/Library/LaunchAgents/com.id7xyz.$ans.plist" ]; then
    $EDITOR "$file"
  else
    echo "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.id7xyz.$ans.plist</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ans</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Day</key>
        <integer>11</integer>
        <key>Hour</key>
        <integer>0</integer>
        <key>Minute</key>
        <integer>0</integer>
        <key>Month</key>
        <integer>7</integer>
        <key>Weekday</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
" >> "$file"
    chmod +x "$file"
    $EDITOR "$file"
  fi
fi

#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title SysPrefupdate


# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName System Preferences Update pane
# @raycast.mode silent
# @raycast.packageName System
# @raycast.schemaVersion 1

# Documentation:
# @raycast.author id7eeem
# @raycast.authorURL https://github.com/d7eeem

tell application "System Preferences"
	activate
	set the current pane to pane id "com.apple.preferences.softwareupdate"
end tell

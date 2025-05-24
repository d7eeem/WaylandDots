#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title term
# @raycast.mode silent
# @raycast.refreshTime 1h

# Optional parameters:
# @raycast.icon /Applications/iTerm.app/Contents/Resources/AppIcon.icns
# @raycast.argument1 { "type": "text", "placeholder": "your cmd" }
# @raycast.packageName term

# Documentation:
# @raycast.author id7eeem
# @raycast.authorURL https://github.com/d7eeem

on run argv
	tell application "iTerm"
		activate
		set new_term to (create window with default profile)
		tell new_term
			tell the current session
				repeat with arg in argv
					write text arg
				end repeat
			end tell
		end tell
	end tell
end run
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title IINA
# @raycast.mode silent

# Optional parameters:
# @raycast.icon /Applications/IINA.app/Contents/Resources/AppIcon.icns
# @raycast.packageName Open urls in IINA

open -na IINA.app "$(pbpaste)"
# open ${1// /%20} -a IINA

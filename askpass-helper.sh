#!/bin/env bash
set -e

#yad --entry --hide-text --title="Authentication Required" --text="Enter your password:"

zenity --password \
       --title="Authentication Required" \
       --text="Enter your password:"

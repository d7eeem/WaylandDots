#!/bin/sh
/usr/local/bin/brew update
sleep 1
/usr/local/bin/brew upgrade
sleep 1
sh ~/.local/bin/webhooks/pushover "Doing Something With brew 📦"

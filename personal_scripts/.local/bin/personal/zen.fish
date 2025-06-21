#!/bin/env fish

if command -v zen-browser >/dev/null 2>&1
    zen-browser $argv
else
    flatpak app.zen_browser.zen
end
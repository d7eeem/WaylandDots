#!/bin/env fish

if command -v brave >/dev/null 2>&1
    brave $argv
else
    flatpak run com.brave.Browser $argv
end
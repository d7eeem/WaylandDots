#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
#                    |___/

if command -v zen-browser >/dev/null 2>&1; then
    zen-browser "$@"
else
    flatpak run app.zen_browser.zen "$@"
fi

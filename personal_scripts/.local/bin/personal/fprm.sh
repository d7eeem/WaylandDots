#!/usr/bin/env bash
# _     _ _____
#(_) __| |___  |_  ___   _ ____
#| |/ _| |  / /\ \/ / | | |_  /
#| | (_| | / /  >  <| |_| |/ /
#|_|\__,_|/_/  /_/\_\__, /___|
#                    |___/


flatpak --user list --app --columns=application | fzf | xargs -r flatpak uninstall y

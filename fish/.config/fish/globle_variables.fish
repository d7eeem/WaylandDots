# Global Variables Configuration for Fish Shell
# Location: ~/.config/fish/globle_variables.fish

## GPU and AI Settings
set -gx ROCR_VISIBLE_DEVICES 0
set -gx OLLAMA_NUM_PARALLEL 2
set -gx OLLAMA_HOST 0.0.0.0

## Man Page Formatting
set -gx MANROFFOPT "-c"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

## Done Plugin Settings
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

## Editor Configuration
set -gx EDITOR nvim

## Starship Prompt Configuration
set -gx STARSHIP_CONFIG $HOME/.config/fish/starship.toml
set -gx STARSHIP_CACHE ~/.cache/starship/cache

## SSH and Sudo Password Helper
set -Ux SSH_ASKPASS /usr/local/bin/askpass-helper.sh
set -Ux SUDO_ASKPASS /usr/local/bin/askpass-helper.sh

## Locale Settings
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

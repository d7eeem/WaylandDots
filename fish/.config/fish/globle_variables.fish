set -gx EDITOR nvim 
set -gx STARSHIP_CONFIG /home/tinker/.config/fish/starship.toml
set -gx STARSHIP_CACHE ~/.cache/starship/cache


set -Ux SSH_ASKPASS  /usr/local/bin/askpass-helper.sh
set -Ux SUDO_ASKPASS /usr/local/bin/askpass-helper.sh




# Locale
set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8

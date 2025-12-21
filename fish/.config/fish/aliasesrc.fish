## File Operations & Navigation
alias cd='z'
alias rsync='rsync -avhriPO'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.="eza -a | grep -e '^\.'"
alias ks="ls"
alias cat='bat --color auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

## Directory Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias mkd="mkdir -pv"

## Search & Filter
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias find='fd'
alias du='dust'

## System Info & Monitoring
alias hw='hwinfo --short'
alias dft="df -h -t ext4 -t btrfs -t fuse.mergerfs -h"
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias top='btop'
alias ps='ps aux'

## Package Management (CachyOS/Arch)
alias update='sudo pacman -Syu'
alias mirror="sudo cachyos-rate-mirrors"
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'
alias jctl="journalctl -p 3 -xb"
alias lastinstalled="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

## Archive Operations
alias tarnow='tar -acf '
alias untar='tar -zxvf '

## Download & Media
alias wget='wget -c '
alias yt="yt-dlp --add-metadata -i"
alias yta="yt -x -f bestaudio/best"
alias ffmpeg="ffmpeg -hide_banner"
alias convert='magick convert'

## Git Shortcuts
alias g="git" 
alias ga="git add" 
alias gu="git add -u" 
alias gc="git commit" 
alias gd="git diff" 
alias gs="git status" 
alias gp="git push" 
alias gP="git pull" 
alias gf="git fetch" 
alias clone="git clone"
alias gg="git clone"

## Docker & Containers
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dstop='docker stop'
alias drm='docker rm'
alias drmi='docker rmi'
alias dprune='docker system prune -af'
alias dnet='docker network ls'
alias dvol='docker volume ls'
alias dcp='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'
alias dcu='docker compose up'

## Editors & Viewers
alias editor="nvim"
alias vim="nvim"
alias nano="nvim"
alias v="editor"
alias s="imv"
alias sxiv="imv"
alias m="mpv"
alias p="mpv"

## Applications & Tools
alias ff="flatpak"
alias winecreate="WINEPREFIX=$HOME/.local/share/wineprefixes/default winecfg"
alias tmux="tmux -f $HOME/.config/tmux/tmux.conf"
alias t="tmux"

## Utility
alias ca="clear"
alias c="clear"

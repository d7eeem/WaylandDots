## Useful aliases
# Replace ls with eza
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'"                                   # show only dotfiles
alias ks="ls"
alias ca="clear"
alias convert='magick convert'
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias cat='bat --color auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias hw='hwinfo --short'                                   # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl"              # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'          # List amount of -git packages
alias update='sudo pacman -Syu'
alias mirror="sudo cachyos-rate-mirrors"
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
alias jctl="journalctl -p 3 -xb"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias mkd="mkdir -pv"
alias yt="yt-dlp --add-metadata -i"
alias yta="yt -x -f bestaudio/best"
alias ffmpeg="ffmpeg -hide_banner"
alias dft="df -h -t  ext4  -t btrfs -t fuse.mergerfs -h"
alias s="imv"
alias sxiv="s"
alias g="git" 
alias gu="git add -u" 
alias gs="git status" 
alias ga="git add" 
alias gp="git push" 
alias gd="git diff" 
alias gc="git commit" 
alias gP="git pull" 
alias gf="git fetch" 
alias clone="git clone"
alias gg="git clone"
alias editor="nvim"
alias vim="nvim"
alias nano="nvim"
alias v="editor"
alias ff="flatpak"
alias pacman="sudo pacman"
alias winecreate="WINEPREFIX=$HOME/.local/share/wineprefixes/default winecfg"
alias tmux="tmux -f $HOME/.config/tmux/tmux.conf"
alias t="tmux"
alias m="mpv"
alias p="mpv"
alias bat="bat --color auto"

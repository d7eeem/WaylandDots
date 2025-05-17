# Use neovim for vim if present
if type -q nvim
    alias vim="nvim"
    alias vimdiff="nvim -d"
end

# Verbosity and settings that you pretty much always want
alias \
    cp="cp -iv" \
    mv="mv -iv" \
    mkd="mkdir -pv" \
    yt="yt-dlp --add-metadata -i" \
    yta="yt -x -f bestaudio/best" \
    ffmpeg="ffmpeg -hide_banner" \
    ls="eza -l" \
    +x="chmod +x" \
    wal="feh --bg-fill -r -z ~/Pictures/wally/untitled" \
    sl="ls" \
    la="eza -a" \
    ll="eza -la" \
    l="eza" \
    ks="ls" \
    grep="grep --color=auto" \
    diff="diff --color=auto" \
    jwd="java -jar ~/JWUDTool.jar -commonkey D7B00402659BA2ABD2CB0DB27FA2B656" \
    cat="bat" \
    ccat="highlight --out-format=ansi" \
    dft="df -h -t ext4 -t btrfs -t fuse.mergerfs -h" \
    s="imv" \
    sxiv="imv" \
    m="mpv" \
    lc="clear; and ls" \
    lf="lfub.sh" \
    ka="killall" \
    SS="sudo systemctl" \
    ex="exit" \
    g="git" \
    gu="git add -u" \
    gs="git status" \
    ga="git add" \
    gp="git push" \
    gd="git diff" \
    gc="git commit" \
    gP="git pull" \
    gf="git fetch" \
    sdn="sudo shutdown -h now" \
    e="nvim" \
    v="nvim" \
    ff="flatpak" \
    p="sudo pacman" \
    pq="echo 'n' | sudo pacman -Su" \
    pa="paru --skipreview" \
    z="zathura" \
    paup="paru --skipreview -Syu" \
    ca="clear" \
    ...="../.." \
    ....="../../.." \
    te="trash-empty" \
    tl="trash-list" \
    zs="source ~/.config/zsh/.zshrc" \
    cals="clear; and ls" \
    soundctl="switch-sound-output.sh" \
    lg="lazygit" \
    refbar="killall -q waybar; and setsid -f waybar &" \
    tmux="tmux -f $HOME/.config/tmux/tmux.conf" \
    t="tmux" \
    ref="shortcuts.sh > /dev/null; and source $XDG_CONFIG_HOME/shell/shortcutrc; and source $XDG_CONFIG_HOME/shell/zshnameddirrc" \
    winecreate="env WINEPREFIX=$HOME/.local/share/wineprefixes/default winecfg" \
    hp="nvim scp://root@10.10.10.54//opt/homepage/config"


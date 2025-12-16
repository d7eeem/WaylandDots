#!/usr/bin/env sh

# Get current animation state
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

# Waybar CSS file
WAYBAR_CSS="$HOME/.config/waybar/style.css"

if [ "$HYPRGAMEMODE" = "1" ]; then
    # DISABLE performance mode (enable game mode)
    echo "Enabling game mode..."
    
    # Comment out animations/transitions in Waybar CSS
    if [ -f "$WAYBAR_CSS" ]; then
        sed -i 's/^\([^/]*animation:.*\)$/\/\* \1 \*\//g' "$WAYBAR_CSS"
        sed -i 's/^\([^/]*transition:.*\)$/\/\* \1 \*\//g' "$WAYBAR_CSS"
        killall -q waybar
        waybar >/dev/null 2>&1 &
    fi
    
    # Disable Hyprland eye candy
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    
    # Kill idle daemon to prevent screen lock during gaming
    killall -q swayidle
    
else
    # ENABLE performance mode (disable game mode)
    echo "Disabling game mode..."
    
    # Uncomment animations/transitions in Waybar CSS
    if [ -f "$WAYBAR_CSS" ]; then
        sed -i 's/\/\* \(.*animation:.*\) \*\//\1/g' "$WAYBAR_CSS"
        sed -i 's/\/\* \(.*transition:.*\) \*\//\1/g' "$WAYBAR_CSS"
        killall -q waybar
        waybar >/dev/null 2>&1 &
    fi
    
    # Reload Hyprland config to restore defaults
    hyprctl reload
    
    # Restart idle daemon
    pgrep -x swayidle >/dev/null || swayidle -w timeout 300 'hyprlock' >/dev/null 2>&1 &
fi

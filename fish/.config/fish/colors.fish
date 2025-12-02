
# Matugen colors for eza
# This file is sourced by config.fish

# Function to convert hex to RGB for eza
function hex_to_rgb
    set hex (string replace '#' '' $argv[1])
    set r (string sub -s 1 -l 2 $hex)
    set g (string sub -s 3 -l 2 $hex)
    set b (string sub -s 5 -l 2 $hex)
    printf "%d;%d;%d" 0x$r 0x$g 0x$b
end

# Load Matugen colors for eza
function load_matugen_eza_colors
    # Try to read from Matugen's generated colors
    if test -f ~/.config/matugen/colors.toml
        # Read key colors from matugen
        set bg (grep -m1 'background.*hex.*=' ~/.config/matugen/colors.toml | grep -oP '#[0-9a-fA-F]{6}' | head -1)
        set fg (grep -m1 'on_surface.*hex.*=' ~/.config/matugen/colors.toml | grep -oP '#[0-9a-fA-F]{6}' | head -1)
        set primary (grep -m1 'primary.*hex.*=' ~/.config/matugen/colors.toml | grep -oP '#[0-9a-fA-F]{6}' | head -1)
        set secondary (grep -m1 'secondary.*hex.*=' ~/.config/matugen/colors.toml | grep -oP '#[0-9a-fA-F]{6}' | head -1)
        set tertiary (grep -m1 'tertiary.*hex.*=' ~/.config/matugen/colors.toml | grep -oP '#[0-9a-fA-F]{6}' | head -1)
        set error (grep -m1 'error.*hex.*=' ~/.config/matugen/colors.toml | grep -oP '#[0-9a-fA-F]{6}' | head -1)
        
        # Convert to RGB
        set fg_rgb (hex_to_rgb $fg)
        set primary_rgb (hex_to_rgb $primary)
        set secondary_rgb (hex_to_rgb $secondary)
        set tertiary_rgb (hex_to_rgb $tertiary)
        set error_rgb (hex_to_rgb $error)
        
        # Set EXA_COLORS with Matugen theme
        set -gx EXA_COLORS "\
di=38;2;$primary_rgb:\
ln=38;2;$tertiary_rgb:\
ex=38;2;$secondary_rgb:\
uu=38;2;$fg_rgb:\
gu=38;2;$fg_rgb:\
sn=38;2;$fg_rgb:\
sb=38;2;$fg_rgb:\
ur=38;2;$primary_rgb:\
uw=38;2;$error_rgb:\
ux=38;2;$secondary_rgb:\
ue=38;2;$secondary_rgb:\
gr=38;2;$primary_rgb:\
gw=38;2;$error_rgb:\
gx=38;2;$secondary_rgb:\
tr=38;2;$primary_rgb:\
tw=38;2;$error_rgb:\
tx=38;2;$secondary_rgb"
        
        echo "✓ Eza colors loaded from Matugen theme"
    else
        echo "⚠ Matugen colors.toml not found"
    end
end

# Eza alias
alias ls='eza --color=always --group-directories-first --icons'

# Load colors
load_matugen_eza_colors

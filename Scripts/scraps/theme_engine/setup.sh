#!/usr/bin/env bash

# Define paths with proper quoting
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Create directory structure - UPDATED for new requirements
mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/gtk"
mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/themes"
mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/kde"
mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/swaync"
mkdir -p "$XDG_CACHE_HOME/theme_engine/user/generated/"{hypr,gtk,swaync}  # Removed kde
mkdir -p "$XDG_STATE_HOME/theme_engine/scss"
mkdir -p "$HOME/.local/share/color-schemes"
mkdir -p "$XDG_CONFIG_HOME/swaync"
mkdir -p "$XDG_CONFIG_HOME/rofi/images"  # NEW: for rofi background
mkdir -p "$XDG_CONFIG_HOME/hypr/themes"  # NEW: for hyprland colors
mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"      # NEW: for gtk config
mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"      # NEW: for gtk config
mkdir -p "$CACHE_DIR/gtk"                # NEW: for temporary gtk configs

# Copy template files with proper quoting - ADDED ERROR HANDLING
if [ -f "./scripts/templates/hypr/themes/colors.conf" ]; then
    cp "./scripts/templates/hypr/themes/colors.conf" "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/themes/"
    echo "✓ Hyprland colors template copied"
else
    echo "⚠  Hyprland colors template not found, creating basic one..."
    mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/themes"
    cat > "$XDG_CONFIG_HOME/theme_engine/scripts/templates/hypr/themes/colors.conf" << 'EOF'
# Hyprland colors template
# This file will be auto-populated with generated colors

# Wallpaper colors
$wallpaper-primary = {{ color4 }}
$wallpaper-accent = {{ color1 }}
$wallpaper-background = {{ background }}

# Application colors  
$color0 = {{ color0 }}
$color1 = {{ color1 }}
$color2 = {{ color2 }}
$color3 = {{ color3 }}
$color4 = {{ color4 }}
$color5 = {{ color5 }}
$color6 = {{ color6 }}
$color7 = {{ color7 }}

# Hyprland specific
$active_border = $wallpaper-accent
$inactive_border = $color0
EOF
    echo "✓ Basic hyprland template created"
fi

if [ -f "./scripts/templates/gtk/gtk-colors.css" ]; then
    cp "./scripts/templates/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/theme_engine/scripts/templates/gtk/"
    echo "✓ GTK colors template copied"
else
    echo "⚠  GTK colors template not found, creating basic one..."
    mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/gtk"
    cat > "$XDG_CONFIG_HOME/theme_engine/scripts/templates/gtk/gtk-colors.css" << 'EOF'
/* GTK colors template */
/* This file will be auto-populated with generated colors */

@define-color wallpaper_primary #{{ color4 }};
@define-color wallpaper_accent #{{ color1 }};
@define-color wallpaper_background #{{ background }};

@define-color color0 #{{ color0 }};
@define-color color1 #{{ color1 }};
@define-color color2 #{{ color2 }};
@define-color color3 #{{ color3 }};
@define-color color4 #{{ color4 }};
@define-color color5 #{{ color5 }};
@define-color color6 #{{ color6 }};
@define-color color7 #{{ color7 }};
EOF
    echo "✓ Basic GTK template created"
fi

# KDE template (optional)
if [ -f "./scripts/templates/kde/theme.colors" ]; then
    cp "./scripts/templates/kde/theme.colors" "$XDG_CONFIG_HOME/theme_engine/scripts/templates/kde/"
    echo "✓ KDE colors template copied"
else
    echo "ℹ  KDE template not found, skipping..."
fi

if [ -f "./scripts/templates/swaync/style.css" ]; then
    cp "./scripts/templates/swaync/style.css" "$XDG_CONFIG_HOME/theme_engine/scripts/templates/swaync/"
    echo "✓ SwayNC template copied"
else
    echo "⚠  SwayNC template not found, creating basic one..."
    mkdir -p "$XDG_CONFIG_HOME/theme_engine/scripts/templates/swaync"
    cat > "$XDG_CONFIG_HOME/theme_engine/scripts/templates/swaync/style.css" << 'EOF'
/* SwayNC colors template */
/* This file will be auto-populated with generated colors */

.control-center {
    background: #{{ background }};
    color: #{{ foreground }};
}

.notification {
    background: #{{ color0 }};
    color: #{{ foreground }};
    border: 1px solid #{{ color4 }};
}

.notification.critical {
    border-color: #{{ color1 }};
}
EOF
    echo "✓ Basic SwayNC template created"
fi

# Copy scss file with proper quoting - ADDED ERROR HANDLING
if [ -f "./scss/_material.scss" ]; then
    cp "./scss/_material.scss" "$XDG_STATE_HOME/theme_engine/scss/"
    echo "✓ Material SCSS file copied"
else
    echo "⚠  Material SCSS file not found, creating basic one..."
    mkdir -p "$XDG_STATE_HOME/theme_engine/scss"
    cat > "$XDG_STATE_HOME/theme_engine/scss/_material.scss" << 'EOF'
// Material colors will be auto-generated
// This file is populated by the theme engine
EOF
    echo "✓ Basic SCSS file created"
fi

# Copy main script and make it executable - ADDED ERROR HANDLING
if [ -f "./theme_switcher.sh" ]; then
    cp "./theme_switcher.sh" "$XDG_CONFIG_HOME/theme_engine/"
    chmod +x "$XDG_CONFIG_HOME/theme_engine/theme_switcher.sh"
    echo "✓ Theme switcher script copied and made executable"
else
    echo "❌ Error: theme_switcher.sh not found in current directory!"
    echo "Please run this script from the theme engine directory"
    exit 1
fi

# Create symlink for easy access - NEW
if [ ! -f "/usr/local/bin/theme-switcher" ] && [ ! -h "/usr/local/bin/theme-switcher" ]; then
    echo "Creating symlink in /usr/local/bin for easy access..."
    sudo ln -sf "$XDG_CONFIG_HOME/theme_engine/theme_switcher.sh" "/usr/local/bin/theme-switcher" 2>/dev/null || {
        echo "ℹ  Could not create system symlink, creating user symlink instead..."
        mkdir -p "$HOME/.local/bin"
        ln -sf "$XDG_CONFIG_HOME/theme_engine/theme_switcher.sh" "$HOME/.local/bin/theme-switcher"
        echo "✓ User symlink created at ~/.local/bin/theme-switcher"
    }
else
    echo "✓ Symlink already exists"
fi

# Initial KDE color scheme setup if running under KDE
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
    echo "KDE desktop detected, setting up color scheme..."
    if [ -f "./scripts/templates/kde/theme.colors" ]; then
        cp "./scripts/templates/kde/theme.colors" "$HOME/.local/share/color-schemes/MaterialYou.colors"
        if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
            plasma-apply-colorscheme MaterialYou
            echo "✓ KDE color scheme applied"
        else
            echo "⚠  plasma-apply-colorscheme not found"
        fi
    else
        echo "⚠  KDE template not available"
    fi
fi

# Initial swaync setup
if command -v swaync >/dev/null 2>&1; then
    echo "SwayNC detected, setting up initial theme..."
    if [ -f "./scripts/templates/swaync/style.css" ]; then
        cp "./scripts/templates/swaync/style.css" "$XDG_CONFIG_HOME/swaync/"
        echo "✓ SwayNC theme applied"
    else
        echo "⚠  SwayNC template not available"
    fi
fi

# Create initial GTK settings - NEW
echo "Configuring initial GTK settings..."
cat > "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=WhiteSur-Dark-solid-alt-red-nord
gtk-icon-theme-name=WhiteSur-dark
gtk-font-name=Ubuntu, 11
gtk-cursor-theme-name=WhiteSur-cursors
gtk-enable-animations=1
EOF

cp "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" "$XDG_CONFIG_HOME/gtk-4.0/settings.ini"
echo "✓ GTK settings configured"

# Check for dependencies - NEW
echo "Checking dependencies..."
for dep in wal hyprctl swww magick; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "✓ $dep found"
    else
        echo "⚠  $dep not installed (optional)"
    fi
done

echo ""
echo "🎉 Setup complete!"
echo "You can now use the theme switcher in the following ways:"
echo "  $XDG_CONFIG_HOME/theme_engine/theme_switcher.sh [wallpaper]"
echo "  theme-switcher [wallpaper] (if symlink was created)"
echo ""
echo "To use without arguments for file picker:"
echo "  theme-switcher"
echo ""
echo "First run will create necessary cache files and apply your theme."
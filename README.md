# WaylandDots

Personal dotfiles configuration for Wayland-based desktop environments, primarily focused on Hyprland.

## Overview

This repository contains my personal configuration files for a Wayland desktop setup. The configurations are managed using GNU Stow for easy deployment and organization.

## Features

- **Hyprland**: Tiling window manager configuration with UWSM integration
- **Waybar**: Customized status bar with various modules
- **Rofi**: Application launcher and menu system
- **Fish Shell**: Shell configuration with custom functions and shortcuts
- **Matugen**: Color scheme management
- **SwayNC**: Notification daemon configurations
- **MPV**: Media player configuration
- **And more**: Additional tools and utilities

## Structure

The repository is organized by application, with each directory containing its respective configuration files:

```
WaylandDots/
├── hyprland/          # Hyprland compositor config
├── waybar/            # Status bar configuration
├── rofi/              # Application launcher
├── fish/              # Fish shell config
├── uwsm/              # UWSM session manager
├── personal_scripts/  # Custom scripts and utilities
├── Scripts/           # Installation scripts
├── install.sh         # Main installation script
├── stow.sh            # Stow management script
└── ...                # Other application configs
```

## Installation

This repository uses GNU Stow for managing dotfiles. Two installation scripts are provided for convenience:

### Quick Installation

```bash
# Clone the repository
git clone <repository-url> ~/WaylandDots
cd ~/WaylandDots

# Run the main installation script (installs packages + deploys dotfiles)
./install.sh
```

### Installation Options

**Main Install Script** (`install.sh`):
```bash
./install.sh              # Install packages and deploy dotfiles
./install.sh -p           # Only install system packages
./install.sh -s           # Only deploy dotfiles
./install.sh -l           # List available packages
./install.sh --stow-only hyprland waybar
                          # Deploy only specific configs
./install.sh --unstow hyprland
                          # Remove specific dotfiles
```

**Stow Script** (`stow.sh`):
```bash
./stow.sh                 # Stow all packages
./stow.sh hyprland waybar # Stow specific packages
./stow.sh -D hyprland     # Unstow (remove) hyprland
./stow.sh -R waybar       # Restow waybar
./stow.sh -l              # List available packages
./stow.sh -i              # Interactive mode
./stow.sh -b              # Create backup before stowing
./stow.sh -n              # Dry run (preview changes)
```

### Manual Installation

You can also use GNU Stow directly:

```bash
# Install specific package
stow <package-name>

# Example: Install hyprland config
stow hyprland

# Unstow a package
stow -D hyprland
```

## Credits

This configuration draws inspiration and components from various sources:

- [Luke Smith](https://github.com/lukesmithxyz) - Shell scripts and utilities
- [HyDE Project](https://github.com/HyDE-Project/HyDE) - Hyprland configuration inspiration
- [ML4W](https://github.com/mylinuxforwork/) - Workflow configurations
- [Yohaneh dotfiles](https://github.com/Yohaneh/dotfiles-colorful-blur) - Visual styling
- [szymonwilczek dotfiles](https://github.com/szymonwilczek/dotfiles) - Configuration patterns
- [GNOME-macOS-Tahoe theme](https://github.com/kayozxo/GNOME-macOS-Tahoe) - Theme elements
- Various LLM-assisted configurations

## TODO

- [ ] Fix API key integration for xbackbone
- [ ] Fix keys sourcing for env_var

## Disclaimer

**No support will be provided.** These are personal configurations tailored to my specific setup and workflow. Use at your own risk and adapt as needed for your system.

## License

These dotfiles are provided as-is for reference and inspiration. Feel free to use any parts that are helpful, but be aware that configurations may be incomplete or require specific system dependencies.

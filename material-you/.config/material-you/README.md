# Material You Theme Generator

A Python-based Material You theme generator for Linux desktop environments, particularly focused on Wayland and GTK-based systems. This tool extracts colors from an image using Google's Material You color scheme algorithm (via `matugen`) and generates theme files for various system components.

## Prerequisites

- Python 3.6+
- `matugen` (install via cargo: `cargo install matugen`)

## Installation

1. Clone this repository to `~/.config/material-you/`:
```bash
git clone https://your-repo-url ~/.config/material-you
```

2. Make the main script executable:
```bash
chmod +x ~/.config/material-you/src/material_you.py
```

3. Ensure `matugen` is installed and available in your PATH.

## Usage

Generate a theme from an image:

```bash
 /path/to/your/image.jpg
```

This will generate:
- GTK3 colors (`~/.config/gtk-3.0/colors.css`)
- GTK4 colors (`~/.config/gtk-4.0/colors1.css`)
- Waybar colors (`~/.config/material-you/waybar-colors2.css`)
- SCSS variables (`~/.config/material-you/colors.scss`)
- JSON color data (`~/.config/material-you/colors.json`)

## Templates

The `src/templates` directory contains template files that serve as references for the generated output:
- `colors.json` - JSON template for color data
- `colors.scss` - SCSS variables template
- `waybar-colors2.css` - Waybar CSS template
- `colors2.css` - GTK CSS template
- `colors.conf` - Configuration template

These templates are preserved as references but are not required for the tool to function.

## Debugging

Logs are written to `~/.config/material-you/debug.log`. Check this file if you encounter any issues.

## Dependencies

- `matugen`: Used for Material You color extraction
- Python standard library (no additional Python packages required)

## License

[Insert your chosen license here] 
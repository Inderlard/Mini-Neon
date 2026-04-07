# Theme Installation
This repository features an icon theme for GNOME and derivatives, along with tools to add your own AI-generated icons.
To install the theme, you must save the Mini-Neon folder directly into `~/.local/share/icons` and activate the theme in your settings.

IconTools only works with this theme.

> This theme is based on a mix of [Sours icon theme](https://github.com/tully-t/Sours) [Sours gnome look](https://www.gnome-look.org/p/2214536); [Infinity-Dark](https://github.com/L4ki/Infinity-Plasma-Themes) [Infinity-Dark gnome look](https://www.gnome-look.org/p/1436570); [Fancy dark](https://github.com/L4ki/Fancy-Plasma-Themes?tab=readme-ov-file) [Fancy dark gnome look](https://www.gnome-look.org/p/1598639)

# IconTools

A set of tools to process AI-generated logos with black backgrounds and install them as icons in the Linux **Mini-Neon** theme.

It takes any PNG/JPG image with a dark background, intelligently removes the background, generates the necessary scales for system icons (16 → 256 px), and installs them in the correct folder within the icon theme.

---

## Included Tools

| Command | Description |
|---|---|
| `icon-process` | Processes one or more images: removes black background and exports multi-scale PNGs |
| `icon-install` | Installs already processed icons into the Mini-Neon theme |
| `icon-pipe` | Complete pipeline: processes and installs in a single step with a graphical interface |
| `icon-appimage` | Installs an AppImage from scratch: processes the logo, creates the `.desktop` file, and registers the icon in the theme |

---

## Requirements

- **Linux** (tested on Ubuntu/Debian and derivatives)
- `python3` + `python3-venv`
- `zenity` (graphical dialogs)
- `libgtk-3-bin` (includes `gtk-update-icon-cache`)
- **Mini-Neon** icon theme installed in `~/.local/share/icons/Mini-Neon/`

Install system dependencies with:

```bash
sudo apt install python3 python3-venv zenity libgtk-3-bin
```

---

## Installation

```bash
git clone https://github.com/Inderlard/Mini-Neon.git
cd icontools
bash install.sh
```

The installer:
1. Creates a Python virtual environment in `~/.local/share/icontools/venv/`
2. Installs **Pillow** and **NumPy** in the venv
3. Copies scripts to `~/.local/share/icontools/`
4. Installs commands to `~/.local/bin/`
5. Creates `.desktop` entries in `~/.local/share/applications/`
6. Adds `~/.local/bin` to the PATH if it wasn't already there

Open a new terminal (or run `source ~/.bashrc`) for the commands to become available.

---

## Usage

### Full Pipeline (Recommended)

```bash
icon-pipe logo.png
# or without arguments to open the file selector:
icon-pipe
```

Flow:
1. Select (or pass as an argument) the logo image
2. It is automatically processed in a temporary folder
3. You will be asked to choose the target application's `.desktop` file
4. The icon is installed in Mini-Neon and the temporary folder is cleaned up

### Process Only

```bash
# Process an image (output goes to ./output/name/)
icon-process logo.png

# Process with graphical file selector
icon-process --select input

# Custom sizes
icon-process logo.png --png-sizes 32 48 64 128

# Also generate .ico in addition to PNG
icon-process logo.png --formats png ico

# View all options
icon-process --help
```

### Install Only

```bash
# Auto-detects subfolder in ./output
icon-install

# Graphical selector
icon-install --select

# Direct path
icon-install --source /path/to/icon/folder
```

### Install an AppImage from scratch

```bash
# Graphical selector for everything (recommended)
icon-appimage

# With direct arguments
icon-appimage logo.png MyApp.AppImage
```

Flow:
1. Select the logo (image with black background)
2. Select the `.AppImage` file
3. Type the application name — this will be used for the launcher and as the icon ID
4. The logo is processed and the PNGs are installed in Mini-Neon under that ID
5. The maximum resolution PNG is copied next to the AppImage as `[AppImage]-icon.png`
6. The `.desktop` file is automatically created in `~/.local/share/applications/`
7. The AppImage is marked as executable

> **Note:** The icon ID is derived from the entered name (lowercase, spaces → hyphens). This same ID appears in the `Icon=` field of the `.desktop` file, allowing the theme to resolve it correctly.

---

## Repository Structure

```
icontools/
├── IconProcess.py      # Image processor (Python core)
├── InstallIcon.sh      # Icon installer for Mini-Neon
├── icon-process        # CLI wrapper for IconProcess.py
├── icon-pipe           # Full pipeline (process + install)
├── icon-appimage       # Pipeline for AppImages (process + .desktop + theme)
├── install.sh          # System installer
├── uninstall.sh        # Uninstaller
├── .gitignore
└── README.md
```

The `input/` and `output/` folders are created automatically when using the tools and are excluded from the repository.

---

## How IconProcess Works

The processor applies the following in order:

1. **Watermark Removal** — deletes the bottom-right corner (configurable area)
2. **Dark Background → Transparency** — calculates alpha based on the maximum brightness of each pixel with gamma correction
3. **Cropping and Square Canvas** — detects the content's bounding box and centers it on a 1:1 canvas with padding
4. **Quality Scaling** — uses LANCZOS for all sizes; applies a soft `UnsharpMask` on sizes ≤ 32px to recover definition without breaking alpha channel edges

Default exported PNG sizes: `16 22 24 32 48 64 128 256`

---

## Uninstallation

```bash
bash uninstall.sh
```

This removes the venv, installed scripts, and `.desktop` entries. Icons already installed in Mini-Neon **are not deleted** (remove them manually from `~/.local/share/icons/Mini-Neon/apps/` if needed).

---

## License

MIT — use it, modify it, and share it freely.
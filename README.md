# Install theme
This repository includes an icon theme for GNOME and its derivatives, as well as tools for adding your own AI-generated icons.
To install the theme, place the Mini-Neon folder directly in `~/.local/share/icons` and enable the theme in the settings.

IconTools only works with this theme.

> This theme is a mix of [Sours icon theme](https://github.com/tully-t/Sours) [Sours gnome look](https://www.gnome-look.org/p/2214536); [Infinity-Dark](https://github.com/L4ki/Infinity-Plasma-Themes) [Infinity-Dark gnome look](https://www.gnome-look.org/p/1436570); [Fancy dark](https://github.com/L4ki/Fancy-Plasma-Themes?tab=readme-ov-file) [Fancy dark gnome look](https://www.gnome-look.org/p/1598639)


# IconTools

A set of tools to process AI-generated logos with black backgrounds and install them as icons in the **Mini-Neon** Linux theme.

It takes any PNG/JPG image with a dark background, intelligently removes the background, generates the necessary scales for system icons (16 → 256 px), and installs them in the correct icon theme folder.

---

## Included tools

| Command | Description |
|---|---|
| `icon-process` | Processes one or several images: removes black background and exports multi-scale PNG |
| `icon-install` | Installs already processed icons into the Mini-Neon theme |
| `icon-pipe` | Full pipeline: processes and installs in a single step with a graphical interface |

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
1. Creates the Python virtual environment in `~/.local/share/icontools/venv/`
2. Installs **Pillow** and **NumPy** in the venv
3. Copies the scripts to `~/.local/share/icontools/`
4. Installs the commands in `~/.local/bin/`
5. Creates `.desktop` entries in `~/.local/share/applications/`
6. Adds `~/.local/bin` to the PATH if it wasn't already there

Open a new terminal (or run `source ~/.bashrc`) so the commands are available.

---

## Usage

### Full pipeline (recommended)

```bash
icon-pipe logo.png
# or without arguments to open the file selector:
icon-pipe
```

Workflow:
1. Select (or pass as an argument) the logo image
2. It is automatically processed in a temporary folder
3. You are asked to choose the target application's `.desktop` file
4. The icon is installed in Mini-Neon and the temporary folder is cleaned up

### Only process

```bash
# Process an image (output goes to ./output/name/)
icon-process logo.png

# Process with graphical file selector
icon-process --select input

# Custom sizes
icon-process logo.png --png-sizes 32 48 64 128

# Also generate .ico in addition to PNG
icon-process logo.png --formats png ico

# See all options
icon-process --help
```

### Only install

```bash
# Auto-detects subfolder in ./output
icon-install

# Graphical selector
icon-install --select

# Direct path
icon-install --source /path/to/icon/folder
```

---

## Repository structure

```
icontools/
├── IconProcess.py      # Image processor (Python core)
├── InstallIcon.sh      # Icon installer for Mini-Neon
├── icon-process        # CLI wrapper for IconProcess.py
├── icon-pipe           # Full pipeline (process + install)
├── install.sh          # System installer
├── uninstall.sh        # Uninstaller
├── .gitignore
└── README.md
```

The `input/` and `output/` folders are created automatically when using the tools and are excluded from the repository.

---

## How IconProcess works

The processor applies the following in order:

1. **Remove watermark** — clears the bottom-right corner (configurable area)
2. **Dark background → transparency** — calculates alpha from the maximum brightness of each pixel with gamma correction
3. **Cropping and square canvas** — detects the content's bounding box and centers it on a 1:1 canvas with padding
4. **Quality scaling** — uses LANCZOS for all sizes; applies a soft `UnsharpMask` on sizes ≤ 32px to recover definition without breaking alpha channel edges

Default exported PNG sizes: `16 22 24 32 48 64 128 256`

---

## Uninstallation

```bash
bash uninstall.sh
```

Removes the venv, installed scripts, and `.desktop` entries. Icons already installed in Mini-Neon **are not deleted** (manually delete them from `~/.local/share/icons/Mini-Neon/apps/` if needed).

---

## License

MIT — use, modify, and share it freely.
#!/bin/bash
# install.sh — Instalador de IconTools
#
# Instala todas las herramientas de IconTools en el entorno del usuario:
#   • Crea el entorno virtual Python con Pillow y NumPy
#   • Copia los scripts al directorio de datos (~/.local/share/icontools/)
#   • Instala los comandos en ~/.local/bin/
#   • Crea las entradas .desktop en ~/.local/share/applications/
#   • Asegura que ~/.local/bin esté en el PATH

set -euo pipefail

# ─────────────────────────────────────────────
# Rutas
# ─────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/icontools"
VENV_DIR="$INSTALL_DIR/venv"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"

# ─────────────────────────────────────────────
# Colores
# ─────────────────────────────────────────────
C_HEADER='\033[1;36m'
C_STEP='\033[1;34m'
C_OK='\033[0;32m'
C_WARN='\033[1;33m'
C_ERR='\033[0;31m'
C_NC='\033[0m'

header() { echo -e "\n${C_HEADER}$1${C_NC}"; }
step()   { echo -e "\n${C_STEP}▸ $1${C_NC}"; }
ok()     { echo -e "${C_OK}  ✓  $1${C_NC}"; }
warn()   { echo -e "${C_WARN}  ⚠  $1${C_NC}"; }
fail()   { echo -e "${C_ERR}  ✗  $1${C_NC}"; }

# ─────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────
echo -e ""
echo -e "${C_HEADER}  ╔══════════════════════════════════════════╗${C_NC}"
echo -e "${C_HEADER}  ║           IconTools — Instalador         ║${C_NC}"
echo -e "${C_HEADER}  ╚══════════════════════════════════════════╝${C_NC}"
echo -e ""

# ─────────────────────────────────────────────
# 1. Comprobar dependencias del sistema
# ─────────────────────────────────────────────
step "Verificando dependencias del sistema..."

MISSING=()
check_dep() {
    if command -v "$1" &>/dev/null; then
        ok "$1"
    else
        fail "$1  (no encontrado)"
        MISSING+=("$1")
    fi
}

check_dep python3
check_dep zenity
check_dep gtk-update-icon-cache

# python3-venv puede estar separado
if ! python3 -c "import venv" &>/dev/null; then
    fail "python3-venv  (módulo no disponible)"
    MISSING+=("python3-venv")
fi

if [ "${#MISSING[@]}" -gt 0 ]; then
    echo ""
    warn "Dependencias faltantes: ${MISSING[*]}"
    echo -e "  Instálalas con:\n"
    echo -e "    ${C_WARN}sudo apt install python3 python3-venv zenity libgtk-3-bin${C_NC}\n"
    exit 1
fi

# ─────────────────────────────────────────────
# 2. Crear directorios
# ─────────────────────────────────────────────
step "Creando directorios..."

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$APPS_DIR"
ok "$INSTALL_DIR"
ok "$BIN_DIR"
ok "$APPS_DIR"

# ─────────────────────────────────────────────
# 3. Copiar scripts principales
# ─────────────────────────────────────────────
step "Copiando scripts al directorio de datos..."

cp "$REPO_DIR/IconProcess.py"  "$INSTALL_DIR/IconProcess.py"
cp "$REPO_DIR/InstallIcon.sh"  "$INSTALL_DIR/InstallIcon.sh"
chmod +x "$INSTALL_DIR/InstallIcon.sh"

ok "IconProcess.py"
ok "InstallIcon.sh"

# ─────────────────────────────────────────────
# 4. Instalar comandos en ~/.local/bin/
# ─────────────────────────────────────────────
step "Instalando comandos en $BIN_DIR..."

# icon-process: wrapper del procesador Python
cp "$REPO_DIR/icon-process" "$BIN_DIR/icon-process"
chmod +x "$BIN_DIR/icon-process"
ok "icon-process"

# icon-pipe: pipeline completo proceso + instalación
cp "$REPO_DIR/icon-pipe" "$BIN_DIR/icon-pipe"
chmod +x "$BIN_DIR/icon-pipe"
ok "icon-pipe"

# icon-install: apunta al script de instalación en INSTALL_DIR
cat > "$BIN_DIR/icon-install" << 'WRAPPER'
#!/bin/bash
exec bash "$HOME/.local/share/icontools/InstallIcon.sh" "$@"
WRAPPER
chmod +x "$BIN_DIR/icon-install"
ok "icon-install"

# ─────────────────────────────────────────────
# 5. Crear entorno virtual Python
# ─────────────────────────────────────────────
step "Creando entorno virtual Python..."

if [ -d "$VENV_DIR" ]; then
    warn "Entorno virtual existente — recreando..."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
ok "venv en $VENV_DIR"

step "Instalando dependencias Python (Pillow, NumPy)..."

"$VENV_DIR/bin/pip" install --upgrade pip --quiet
"$VENV_DIR/bin/pip" install pillow numpy --quiet

ok "Pillow $(\"$VENV_DIR/bin/python\" -c 'import PIL; print(PIL.__version__)')"
ok "NumPy  $(\"$VENV_DIR/bin/python\" -c 'import numpy; print(numpy.__version__)')"

# ─────────────────────────────────────────────
# 6. Asegurar ~/.local/bin en el PATH
# ─────────────────────────────────────────────
step "Comprobando PATH..."

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
PATH_ADDED=false

for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$rc_file" ] && ! grep -q '\.local/bin' "$rc_file"; then
        printf '\n# Añadido por IconTools\n%s\n' "$PATH_LINE" >> "$rc_file"
        ok "PATH añadido a $(basename "$rc_file")"
        PATH_ADDED=true
    fi
done

if [ "$PATH_ADDED" = false ]; then
    ok "PATH ya contiene ~/.local/bin"
fi

# ─────────────────────────────────────────────
# 7. Crear entradas .desktop
# ─────────────────────────────────────────────
step "Creando entradas de aplicación (.desktop)..."

# icon-process.desktop
cat > "$APPS_DIR/icon-process.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Icon Processor
Name[es]=Procesador de Iconos
Comment=Procesa logos con fondo negro y genera iconos PNG multi-escala
Comment[es]=Procesa logos con fondo negro y genera iconos PNG multi-escala
Exec=$BIN_DIR/icon-process --select input
Icon=image-x-generic
Terminal=true
Categories=Graphics;Utility;
Keywords=icon;logo;png;process;background;remove;
StartupNotify=false
EOF
ok "icon-process.desktop"

# icon-install.desktop
cat > "$APPS_DIR/icon-install.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Icon Installer
Name[es]=Instalador de Iconos
Comment=Instala iconos procesados en el tema Mini-Neon
Comment[es]=Instala iconos procesados en el tema Mini-Neon
Exec=$BIN_DIR/icon-install
Icon=preferences-desktop-icons
Terminal=false
Categories=Settings;DesktopSettings;Utility;
Keywords=icon;install;theme;mini-neon;
StartupNotify=false
EOF
ok "icon-install.desktop"

# icon-pipe.desktop
cat > "$APPS_DIR/icon-pipe.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Icon Pipe
Name[es]=Procesar e Instalar Icono
Comment=Procesa e instala un logo como icono en Mini-Neon en un solo paso
Comment[es]=Procesa e instala un logo como icono en Mini-Neon en un solo paso
Exec=$BIN_DIR/icon-pipe
Icon=system-software-install
Terminal=false
Categories=Graphics;Settings;Utility;
Keywords=icon;logo;process;install;pipeline;mini-neon;
StartupNotify=true
EOF
ok "icon-pipe.desktop"

# Validar si la herramienta está disponible
if command -v desktop-file-validate &>/dev/null; then
    for f in icon-process icon-install icon-pipe; do
        if ! desktop-file-validate "$APPS_DIR/$f.desktop" 2>/dev/null; then
            warn "$f.desktop tiene advertencias (no crítico)"
        fi
    done
fi

# Refrescar base de datos de aplicaciones
update-desktop-database "$APPS_DIR" &>/dev/null || true
ok "Base de datos de aplicaciones actualizada"

# ─────────────────────────────────────────────
# 8. Resumen final
# ─────────────────────────────────────────────
echo ""
echo -e "${C_HEADER}  ╔══════════════════════════════════════════╗${C_NC}"
echo -e "${C_HEADER}  ║        ¡Instalación completada!          ║${C_NC}"
echo -e "${C_HEADER}  ╚══════════════════════════════════════════╝${C_NC}"
echo ""
echo -e "  Comandos disponibles:"
echo -e ""
echo -e "    ${C_OK}icon-process${C_NC}  [imagen...]   Procesa imágenes → iconos PNG"
echo -e "    ${C_OK}icon-install${C_NC}               Instala iconos en Mini-Neon"
echo -e "    ${C_OK}icon-pipe${C_NC}    [imagen]      Pipeline completo en un paso"
echo ""
echo -e "  ${C_WARN}Nota:${C_NC} Si los comandos no responden, abre un terminal nuevo"
echo -e "        o ejecuta:  ${C_WARN}source ~/.bashrc${C_NC}"
echo ""

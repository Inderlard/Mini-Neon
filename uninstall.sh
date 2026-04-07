#!/bin/bash
# uninstall.sh — Desinstalador de IconTools
#
# Elimina todos los componentes instalados por install.sh:
#   • Directorio de datos y entorno virtual Python
#   • Comandos de ~/.local/bin/
#   • Entradas .desktop de ~/.local/share/applications/
#   • Líneas de PATH añadidas al shell (opcional)

# ─────────────────────────────────────────────
# Colores
# ─────────────────────────────────────────────
C_HEADER='\033[1;36m'
C_STEP='\033[1;34m'
C_OK='\033[0;32m'
C_WARN='\033[1;33m'
C_ERR='\033[0;31m'
C_NC='\033[0m'

step() { echo -e "\n${C_STEP}▸ $1${C_NC}"; }
ok()   { echo -e "${C_OK}  ✓  $1${C_NC}"; }
warn() { echo -e "${C_WARN}  ⚠  $1${C_NC}"; }
skip() { echo -e "     $1  ${C_WARN}(no encontrado, omitido)${C_NC}"; }

# ─────────────────────────────────────────────
# Rutas
# ─────────────────────────────────────────────
INSTALL_DIR="$HOME/.local/share/icontools"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"

# ─────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────
echo ""
echo -e "${C_HEADER}  ╔══════════════════════════════════════════╗${C_NC}"
echo -e "${C_HEADER}  ║         IconTools — Desinstalador        ║${C_NC}"
echo -e "${C_HEADER}  ╚══════════════════════════════════════════╝${C_NC}"
echo ""

# ─────────────────────────────────────────────
# Confirmación
# ─────────────────────────────────────────────
echo -e "  Se eliminarán los siguientes componentes:\n"
echo -e "    • ${C_WARN}$INSTALL_DIR${C_NC}  (scripts + venv Python)"
echo -e "    • ${C_WARN}$BIN_DIR/icon-process${C_NC}"
echo -e "    • ${C_WARN}$BIN_DIR/icon-install${C_NC}"
echo -e "    • ${C_WARN}$BIN_DIR/icon-pipe${C_NC}"
echo -e "    • ${C_WARN}$BIN_DIR/icon-appimage${C_NC}"
echo -e "    • Entradas .desktop en ${C_WARN}$APPS_DIR${C_NC}"
echo ""
read -rp "  ¿Continuar? [s/N]: " CONFIRM
CONFIRM="${CONFIRM,,}"   # lowercase

if [[ "$CONFIRM" != "s" && "$CONFIRM" != "si" && "$CONFIRM" != "yes" && "$CONFIRM" != "y" ]]; then
    echo ""
    echo "  Desinstalación cancelada."
    echo ""
    exit 0
fi

# ─────────────────────────────────────────────
# 1. Eliminar directorio de datos (scripts + venv)
# ─────────────────────────────────────────────
step "Eliminando directorio de datos..."

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "$INSTALL_DIR"
else
    skip "$INSTALL_DIR"
fi

# ─────────────────────────────────────────────
# 2. Eliminar comandos de ~/.local/bin/
# ─────────────────────────────────────────────
step "Eliminando comandos..."

for cmd in icon-process icon-install icon-pipe icon-appimage; do
    target="$BIN_DIR/$cmd"
    if [ -f "$target" ]; then
        rm -f "$target"
        ok "$target"
    else
        skip "$target"
    fi
done

# ─────────────────────────────────────────────
# 3. Eliminar entradas .desktop
# ─────────────────────────────────────────────
step "Eliminando entradas de aplicación..."

for desktop in icon-process.desktop icon-install.desktop icon-pipe.desktop icon-appimage.desktop; do
    target="$APPS_DIR/$desktop"
    if [ -f "$target" ]; then
        rm -f "$target"
        ok "$target"
    else
        skip "$target"
    fi
done

# Refrescar base de datos de aplicaciones
update-desktop-database "$APPS_DIR" &>/dev/null || true
ok "Base de datos de aplicaciones actualizada"

# ─────────────────────────────────────────────
# 4. Limpiar líneas de PATH (opcional)
# ─────────────────────────────────────────────
step "Líneas de PATH en archivos de shell..."

PATH_REMOVED=false
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$rc_file" ] && grep -q 'Añadido por IconTools' "$rc_file" 2>/dev/null; then
        # Eliminar el bloque añadido por el instalador (comentario + export)
        sed -i '/# Añadido por IconTools/,/export PATH.*\.local\/bin/d' "$rc_file"
        ok "Limpiado: $(basename "$rc_file")"
        PATH_REMOVED=true
    fi
done

if [ "$PATH_REMOVED" = false ]; then
    warn "No se encontraron líneas de PATH de IconTools en los archivos de shell"
    warn "(si las añadiste manualmente, elimínalas tú mismo)"
fi

# ─────────────────────────────────────────────
# 5. Resumen
# ─────────────────────────────────────────────
echo ""
echo -e "${C_HEADER}  ╔══════════════════════════════════════════╗${C_NC}"
echo -e "${C_HEADER}  ║        Desinstalación completada         ║${C_NC}"
echo -e "${C_HEADER}  ╚══════════════════════════════════════════╝${C_NC}"
echo ""
echo -e "  ${C_WARN}Nota:${C_NC} Los iconos ya instalados en Mini-Neon no se han tocado."
echo -e "        Si quieres eliminarlos, hazlo manualmente desde:"
echo -e "        ${C_WARN}~/.local/share/icons/Mini-Neon/apps/${C_NC}"
echo ""

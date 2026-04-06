#!/bin/bash
# InstallIcon.sh v5
# Instala iconos multi-escala generados por IconProcess.py
# en el tema de iconos Mini-Neon.
#
# Estructura destino: ~/.local/share/icons/Mini-Neon/apps/TAMAÑO/icono.png
#
# Uso:
#   icon-install                        # auto-detecta ./output
#   icon-install --select               # explorador para elegir carpeta fuente
#   icon-install --source /ruta/icono   # ruta directa (usado por icon-pipe)

THEME_APPS="$HOME/.local/share/icons/Mini-Neon/apps"
APPS_DIR="$HOME/.local/share/applications"

# ─────────────────────────────────────────────
# Parseo de argumentos: --select / -s  y  --source PATH
# ─────────────────────────────────────────────
SELECT=false
SOURCE_ARG=""

args=("$@")
i=0
while [ $i -lt ${#args[@]} ]; do
    case "${args[$i]}" in
        --select|-s)
            SELECT=true
            ;;
        --source)
            i=$(( i + 1 ))
            SOURCE_ARG="${args[$i]}"
            ;;
        --source=*)
            SOURCE_ARG="${args[$i]#--source=}"
            ;;
    esac
    i=$(( i + 1 ))
done

# ─────────────────────────────────────────────
# 1. Carpeta fuente de los iconos procesados
# ─────────────────────────────────────────────
OUTPUT_BASE="$(pwd)/output"

if [ -n "$SOURCE_ARG" ]; then
    # Ruta proporcionada directamente (por icon-pipe u otro script)
    SOURCE_DIR="$SOURCE_ARG"

elif [ "$SELECT" = true ]; then
    # Con --select: explorador apuntando a ./output
    SOURCE_DIR=$(zenity --file-selection \
        --directory \
        --title="Selecciona la carpeta del icono a instalar" \
        --filename="$OUTPUT_BASE/")
    [ -z "$SOURCE_DIR" ] && { echo "Cancelado."; exit 0; }

else
    # Sin argumentos: detectar subcarpetas en ./output
    if [ ! -d "$OUTPUT_BASE" ]; then
        zenity --error --title="Carpeta no encontrada" \
            --text="No existe la carpeta de salida:\n\n<b>$OUTPUT_BASE</b>\n\nUsa <tt>--select</tt> para elegir la ruta manualmente."
        exit 1
    fi

    mapfile -t subdirs < <(find "$OUTPUT_BASE" -mindepth 1 -maxdepth 1 -type d | sort)
    n_subdirs="${#subdirs[@]}"

    if [ "$n_subdirs" -eq 0 ]; then
        zenity --error --title="Sin iconos" \
            --text="No se encontraron subcarpetas en:\n\n<b>$OUTPUT_BASE</b>\n\nProcesa primero las imágenes con <tt>icon-process</tt>."
        exit 1

    elif [ "$n_subdirs" -eq 1 ]; then
        SOURCE_DIR="${subdirs[0]}"
        echo "Carpeta detectada automáticamente: $SOURCE_DIR"

    else
        zenity --info --title="Varias carpetas detectadas" --width=420 \
            --text="Se encontraron <b>${n_subdirs}</b> carpetas en <i>output/</i>.\n\nSelecciona cuál quieres instalar."
        SOURCE_DIR=$(zenity --file-selection \
            --directory \
            --title="Selecciona la carpeta del icono a instalar" \
            --filename="$OUTPUT_BASE/")
        [ -z "$SOURCE_DIR" ] && { echo "Cancelado."; exit 0; }
    fi
fi

# Validar que existe
if [ ! -d "$SOURCE_DIR" ]; then
    zenity --error --title="Carpeta no encontrada" \
        --text="No existe la carpeta seleccionada:\n\n<b>$SOURCE_DIR</b>"
    exit 1
fi

# ─────────────────────────────────────────────
# 2. Seleccionar el .desktop → abre directamente en applications/
# ─────────────────────────────────────────────
DESKTOP_FILE=$(zenity --file-selection \
    --title="Selecciona el archivo .desktop de la App" \
    --filename="$APPS_DIR/")

[ -z "$DESKTOP_FILE" ] && { echo "Cancelado."; exit 0; }

# ─────────────────────────────────────────────
# 3. Extraer el nombre del icono del .desktop
# ─────────────────────────────────────────────
ICON_NAME=$(grep -m 1 "^Icon=" "$DESKTOP_FILE" | cut -d'=' -f2-)
if [ -z "$ICON_NAME" ]; then
    zenity --error --text="No se encontró ninguna línea 'Icon=' en:\n<b>$DESKTOP_FILE</b>"
    exit 1
fi

# Limpiar extensión y ruta si el .desktop las incluye
ICON_NAME="${ICON_NAME%.png}"
ICON_NAME="${ICON_NAME%.svg}"
ICON_NAME="${ICON_NAME%.xpm}"
ICON_NAME="$(basename "$ICON_NAME")"

# ─────────────────────────────────────────────
# 4. Instalar cada PNG en su carpeta de tamaño
#    Patrón esperado: nombre_NxN.png
#    Destino: ~/.local/share/icons/Mini-Neon/apps/N/icono.png
# ─────────────────────────────────────────────
installed=0
errors=0
skipped=0
log_lines=""

while IFS= read -r -d '' png_file; do
    filename=$(basename "$png_file")

    if [[ "$filename" =~ _([0-9]+)x[0-9]+\.png$ ]]; then
        size="${BASH_REMATCH[1]}"
        dest_dir="$THEME_APPS/${size}"

        mkdir -p "$dest_dir"
        if cp "$png_file" "$dest_dir/${ICON_NAME}.png" 2>/dev/null; then
            log_lines+="  ✓  ${size}px  →  ${dest_dir}/${ICON_NAME}.png\n"
            (( installed++ ))
        else
            log_lines+="  ✗  ${size}px  →  Error al copiar\n"
            (( errors++ ))
        fi
    else
        (( skipped++ ))
    fi

done < <(find "$SOURCE_DIR" -name "*.png" -print0 | sort -z)

# ─────────────────────────────────────────────
# 5. Verificar que se instaló algo
# ─────────────────────────────────────────────
if [ "$installed" -eq 0 ]; then
    zenity --error --title="Sin iconos instalados" \
        --text="No se encontraron PNGs con formato <i>nombre_NxN.png</i> en:\n\n<b>$SOURCE_DIR</b>"
    exit 1
fi

# ─────────────────────────────────────────────
# 6. Refrescar caché del tema
# ─────────────────────────────────────────────
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Mini-Neon" &>/dev/null

# ─────────────────────────────────────────────
# 7. Limpiar carpeta fuente ya instalada
# ─────────────────────────────────────────────
cleanup_note=""
if rm -rf "$SOURCE_DIR" 2>/dev/null; then
    cleanup_note="\n🗑  Carpeta eliminada: <i>$(basename "$SOURCE_DIR")</i>"
else
    cleanup_note="\n⚠  No se pudo eliminar: <i>$SOURCE_DIR</i>"
fi

# ─────────────────────────────────────────────
# 8. Resumen final
# ─────────────────────────────────────────────
zenity --info \
    --title="¡Iconos instalados!" \
    --width=500 \
    --text="Icono: <b>${ICON_NAME}</b>   |   Tema: <b>Mini-Neon</b>\n\n${log_lines}\nInstalados: <b>${installed}</b>   Errores: <b>${errors}</b>   Omitidos: <b>${skipped}</b>${cleanup_note}"

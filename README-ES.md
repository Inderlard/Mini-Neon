# Instalacion del tema
Este repositodio cuenta con un tema de iconos para GNOME y derivados y unas herramiens para añadir tus propios iconos generados por IA
Para instalar el tema de debe guuadrar la carpeta Mini-Neon directamente en `~/.local/share/icons` y activar el tema en la configuración.

IconTools solo funciona con este tema.

> Este tema esta basado en una mezcla de [Sours icon theme](https://github.com/tully-t/Sours) [Sours gnome look](https://www.gnome-look.org/p/2214536); [Infinity-Dark](https://github.com/L4ki/Infinity-Plasma-Themes) [Infinity-Dark gnome look](https://www.gnome-look.org/p/1436570); [Fancy dark](https://github.com/L4ki/Fancy-Plasma-Themes?tab=readme-ov-file) [Fancy dark gnome look](https://www.gnome-look.org/p/1598639)

# IconTools

Conjunto de herramientas para procesar logos con fondo negro generados por IA e instalarlos como iconos en el tema **Mini-Neon** de Linux.

Toma cualquier imagen PNG/JPG con fondo oscuro, elimina el fondo de forma inteligente, genera las escalas necesarias para iconos del sistema (16 → 256 px) y las instala en la carpeta correcta del tema de iconos.

---

## Herramientas incluidas

| Comando | Descripción |
|---|---|
| `icon-process` | Procesa una o varias imágenes: elimina el fondo negro y exporta PNG multi-escala |
| `icon-install` | Instala iconos ya procesados en el tema Mini-Neon |
| `icon-pipe` | Pipeline completo: procesa e instala en un solo paso con interfaz gráfica |
| `icon-appimage` | Instala una AppImage desde cero: procesa el logo, crea el `.desktop` y registra el icono en el tema |

---

## Requisitos

- **Linux** (probado en Ubuntu/Debian y derivados)
- `python3` + `python3-venv`
- `zenity` (diálogos gráficos)
- `libgtk-3-bin` (incluye `gtk-update-icon-cache`)
- Tema de iconos **Mini-Neon** instalado en `~/.local/share/icons/Mini-Neon/`

Instala las dependencias del sistema con:

```bash
sudo apt install python3 python3-venv zenity libgtk-3-bin
```

---

## Instalación

```bash
git clone https://github.com/Inderlard/Mini-Neon.git
cd icontools
bash install.sh
```

El instalador:
1. Crea el entorno virtual Python en `~/.local/share/icontools/venv/`
2. Instala **Pillow** y **NumPy** en el venv
3. Copia los scripts a `~/.local/share/icontools/`
4. Instala los comandos en `~/.local/bin/`
5. Crea entradas `.desktop` en `~/.local/share/applications/`
6. Añade `~/.local/bin` al PATH si no estaba ya

Abre un terminal nuevo (o ejecuta `source ~/.bashrc`) para que los comandos estén disponibles.

---

## Uso

### Pipeline completo (recomendado)

```bash
icon-pipe logo.png
# o sin argumentos para abrir el selector de archivos:
icon-pipe
```

Flujo:
1. Selecciona (o pasa como argumento) la imagen del logo
2. Se procesa automáticamente en una carpeta temporal
3. Se te pide que elijas el `.desktop` de la aplicación destino
4. El icono se instala en Mini-Neon y la carpeta temporal se limpia

### Solo procesar

```bash
# Procesar una imagen (sale en ./output/nombre/)
icon-process logo.png

# Procesar con selector gráfico de archivos
icon-process --select input

# Tamaños personalizados
icon-process logo.png --png-sizes 32 48 64 128

# También generar .ico además de PNG
icon-process logo.png --formats png ico

# Ver todas las opciones
icon-process --help
```

### Solo instalar

```bash
# Auto-detecta subcarpeta en ./output
icon-install

# Selector gráfico
icon-install --select

# Ruta directa
icon-install --source /ruta/a/carpeta/de/iconos
```

### Instalar una AppImage desde cero

```bash
# Selector gráfico para todo (recomendado)
icon-appimage

# Con argumentos directos
icon-appimage logo.png MiApp.AppImage
```

Flujo:
1. Selecciona el logo (imagen con fondo negro)
2. Selecciona el archivo `.AppImage`
3. Escribe el nombre de la aplicación — se usará en el lanzador y como ID de icono
4. El logo se procesa y los PNG se instalan en Mini-Neon bajo ese ID
5. Se copia el PNG de máxima resolución junto al AppImage como `[AppImage]-icon.png`
6. Se crea automáticamente el `.desktop` en `~/.local/share/applications/`
7. El AppImage queda marcado como ejecutable

> **Nota:** El ID de icono se deriva del nombre introducido (minúsculas, espacios → guiones). Ese mismo ID aparece en el campo `Icon=` del `.desktop`, por lo que el tema lo resuelve correctamente.

---

## Estructura del repositorio

```
icontools/
├── IconProcess.py      # Procesador de imágenes (núcleo Python)
├── InstallIcon.sh      # Instalador de iconos en Mini-Neon
├── icon-process        # Wrapper CLI para IconProcess.py
├── icon-pipe           # Pipeline completo (procesar + instalar)
├── icon-appimage       # Pipeline para AppImages (proceso + .desktop + tema)
├── install.sh          # Instalador del sistema
├── uninstall.sh        # Desinstalador
├── .gitignore
└── README.md
```

Las carpetas `input/` y `output/` se crean automáticamente al usar las herramientas y están excluidas del repositorio.

---

## Cómo funciona IconProcess

El procesador aplica en orden:

1. **Eliminar marca de agua** — borra la esquina inferior-derecha (zona configurable)
2. **Fondo oscuro → transparencia** — calcula el alfa a partir del brillo máximo de cada píxel con corrección gamma
3. **Recorte y canvas cuadrado** — detecta el bounding box del contenido y lo centra en un canvas 1:1 con padding
4. **Escalado de calidad** — usa LANCZOS para todos los tamaños; aplica un suave `UnsharpMask` en tamaños ≤ 32px para recuperar definición sin romper los bordes del canal alfa

Tamaños PNG exportados por defecto: `16 22 24 32 48 64 128 256`

---

## Desinstalación

```bash
bash uninstall.sh
```

Elimina el venv, los scripts instalados y las entradas `.desktop`. Los iconos ya instalados en Mini-Neon **no se borran** (elimínalos manualmente desde `~/.local/share/icons/Mini-Neon/apps/` si lo necesitas).

---

## Licencia

MIT — úsalo, modifícalo y compártelo libremente.

#!/usr/bin/env python3
"""
logo_processor.py v5 — Procesador automatico de logos con fondo negro
"""

import sys
import struct
import io
import argparse
import numpy as np
from pathlib import Path
from PIL import Image

# ─────────────────────────────────────────────
# Tamaños PNG por defecto para iconos
# ─────────────────────────────────────────────
PNG_ICON_SIZES = [16, 22, 24, 32, 48, 64, 128, 256]

# ─────────────────────────────────────────────
# 1. Eliminar marca de agua (esquina inf-derecha)
# ─────────────────────────────────────────────
def remove_watermark(img_np: np.ndarray, zone: float = 0.10) -> np.ndarray:
    h, w = img_np.shape[:2]
    result = img_np.copy()
    result[h - int(h * zone):, w - int(w * zone):] = 0
    return result

# ─────────────────────────────────────────────
# 2. Fondo oscuro → transparencia
# ─────────────────────────────────────────────
def remove_dark_background(img_np: np.ndarray, gamma: float = 1.8, noise_floor: int = 8) -> np.ndarray:
    rgb = img_np[:, :, :3].astype(np.float32)
    alpha_raw = np.max(rgb, axis=2)
    nf = float(noise_floor)
    alpha_clean = np.clip((alpha_raw - nf) / (255.0 - nf), 0.0, 1.0)
    alpha_final = np.power(alpha_clean, gamma)

    rgba = np.zeros((*img_np.shape[:2], 4), dtype=np.uint8)
    rgba[:, :, :3] = img_np[:, :, :3]
    rgba[:, :, 3]  = (alpha_final * 255).clip(0, 255).astype(np.uint8)
    return rgba

# ─────────────────────────────────────────────
# 3. Recorte ajustado al logo + canvas 1:1
# ─────────────────────────────────────────────
def crop_and_square(rgba_np: np.ndarray, crop_threshold: int = 10, padding: int = 40) -> Image.Image:
    alpha = rgba_np[:, :, 3]
    rows  = np.any(alpha > crop_threshold, axis=1)
    cols  = np.any(alpha > crop_threshold, axis=0)

    if not rows.any():
        return Image.fromarray(rgba_np, "RGBA")

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]
    cropped = rgba_np[rmin:rmax + 1, cmin:cmax + 1]
    h, w    = cropped.shape[:2]

    side   = max(h, w) + padding * 2
    canvas = np.zeros((side, side, 4), dtype=np.uint8)
    y_off  = (side - h) // 2
    x_off  = (side - w) // 2
    canvas[y_off:y_off + h, x_off:x_off + w] = cropped
    return Image.fromarray(canvas, "RGBA")

# ─────────────────────────────────────────────
# 4. Escalado de alta calidad para iconos PNG
# ─────────────────────────────────────────────
def resize_for_icon(img: Image.Image, size: int) -> Image.Image:
    """
    Escala la imagen al tamaño indicado con cuidado:
    - Usa LANCZOS para máxima calidad
    - Aplica ligero sharpening en tamaños muy pequeños para
      compensar la pérdida de detalle inherente al downscale
    """
    resized = img.resize((size, size), Image.LANCZOS)

    # En tamaños pequeños, un toque de sharpening recupera definición
    if size <= 32:
        from PIL import ImageFilter
        # Filtro de enfoque suave, sin exagerar
        sharpened = resized.filter(ImageFilter.UnsharpMask(radius=0.6, percent=120, threshold=2))
        # Preservar canal alpha original (el sharpening puede alterar bordes)
        r, g, b, a = resized.split()
        sr, sg, sb, _ = sharpened.split()
        resized = Image.merge("RGBA", (sr, sg, sb, a))

    return resized

def save_png_scales(img_rgba: Image.Image, output_dir: Path, stem: str,
                    sizes: list = None) -> None:
    """
    Guarda una PNG por cada tamaño en una subcarpeta con el nombre del logo.
    Si solo hay un tamaño se guarda directamente en output_dir.
    """
    if sizes is None:
        sizes = PNG_ICON_SIZES

    if len(sizes) == 1:
        # Un solo tamaño: guardar directamente
        out_path = output_dir / f"{stem}.png"
        resize_for_icon(img_rgba, sizes[0]).save(out_path, "PNG")
        print(f"   [OK] {out_path}")
    else:
        # Múltiples tamaños: subcarpeta por logo
        sub = output_dir / stem
        sub.mkdir(parents=True, exist_ok=True)
        for s in sizes:
            out_path = sub / f"{stem}_{s}x{s}.png"
            resize_for_icon(img_rgba, s).save(out_path, "PNG")
            print(f"   [OK] {out_path}")

# ─────────────────────────────────────────────
# 5. ICO multi-tamaño
# ─────────────────────────────────────────────
ICO_SIZES     = [16, 24, 32, 48, 64, 128, 256]
ICO_BMP_SIZES = {16, 24, 32, 48}

def _rgba_to_bmp(img: Image.Image) -> bytes:
    w, h = img.size
    header = struct.pack("<IiiHHIIiiII", 40, w, -h, 1, 32, 0, w * h * 4, 0, 0, 0, 0)
    arr  = np.array(img.convert("RGBA"))
    bgra = arr[:, :, [2, 1, 0, 3]].tobytes()
    return header + bgra

def write_ico(img_rgba: Image.Image, output_path: str, sizes: tuple = tuple(ICO_SIZES)) -> None:
    frames = []
    for s in sizes:
        resized = resize_for_icon(img_rgba, s)
        if s in ICO_BMP_SIZES:
            data = _rgba_to_bmp(resized)
        else:
            buf = io.BytesIO()
            resized.save(buf, format="PNG")
            data = buf.getvalue()
        frames.append((s, data))

    n = len(frames)
    data_offset = 6 + n * 16
    entries_bin = b""
    data_bin    = b""

    for (s, data) in frames:
        w = 0 if s >= 256 else s
        entries_bin += struct.pack("<BBBBHHII", w, w, 0, 0, 1, 32, len(data), data_offset + len(data_bin))
        data_bin += data

    with open(output_path, "wb") as f:
        f.write(struct.pack("<HHH", 0, 1, n) + entries_bin + data_bin)

# ─────────────────────────────────────────────
# Pipeline principal
# ─────────────────────────────────────────────
def process_logo(input_path: Path, output_dir: Path, formats: list,
                 png_sizes: list = None,
                 gamma: float = 1.8, noise_floor: int = 8,
                 crop_threshold: int = 10, padding: int = 15,
                 watermark_zone: float = 0.10):

    print(f"\n Procesando: {input_path.name}")

    try:
        img = Image.open(input_path).convert("RGB")
    except Exception as e:
        print(f"   [ERROR] No se pudo leer la imagen: {e}")
        return

    img_np  = np.array(img)
    img_np  = remove_watermark(img_np, zone=watermark_zone)
    rgba_np = remove_dark_background(img_np, gamma=gamma, noise_floor=noise_floor)
    final_img = crop_and_square(rgba_np, crop_threshold=crop_threshold, padding=padding)

    stem = input_path.stem

    if "png" in formats:
        save_png_scales(final_img, output_dir, stem, sizes=png_sizes)

    if "ico" in formats:
        ico_path = output_dir / f"{stem}.ico"
        write_ico(final_img, str(ico_path))
        print(f"   [OK] Guardado: {ico_path}")

# ─────────────────────────────────────────────
# Selector de carpeta / archivo con diálogo GUI
# ─────────────────────────────────────────────
def pick_folder(title: str = "Selecciona una carpeta") -> Path | None:
    """Abre el explorador del SO y devuelve la carpeta elegida, o None."""
    try:
        import tkinter as tk
        from tkinter import filedialog
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        folder = filedialog.askdirectory(title=title)
        root.destroy()
        return Path(folder) if folder else None
    except Exception as e:
        print(f"[ERROR] No se pudo abrir el explorador de archivos: {e}")
        return None

def pick_files(title: str = "Selecciona archivos de imagen") -> list[Path]:
    """Abre el explorador del SO y devuelve los archivos elegidos."""
    try:
        import tkinter as tk
        from tkinter import filedialog
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        files = filedialog.askopenfilenames(
            title=title,
            filetypes=[("Imágenes", "*.png *.jpg *.jpeg *.webp"), ("Todos", "*.*")]
        )
        root.destroy()
        return [Path(f) for f in files] if files else []
    except Exception as e:
        print(f"[ERROR] No se pudo abrir el explorador de archivos: {e}")
        return []

# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Procesa logos IA: elimina fondo negro y marca de agua.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "inputs", nargs="*",
        help="Archivos o carpetas a procesar.\n(Por defecto: carpeta ./input del directorio actual)"
    )
    parser.add_argument(
        "--output", "-o", default=None,
        help="Carpeta de salida.\n(Por defecto: carpeta ./output del directorio actual)"
    )
    parser.add_argument(
        "--formats", "-f", nargs="+", choices=["png", "ico"], default=["png"],
        help="Formatos de salida: png, ico.\n(Por defecto: png con todas las escalas)"
    )
    parser.add_argument(
        "--png-sizes", nargs="+", type=int, default=None, metavar="PX",
        help=(
            "Tamaños PNG a exportar (en píxeles).\n"
            f"Por defecto: {PNG_ICON_SIZES}\n"
            "Ejemplo: --png-sizes 32 64 128"
        )
    )
    parser.add_argument(
        "--select", "-s",
        choices=["input", "output", "all"], default=None,
        const="all", nargs="?",
        help=(
            "Abre el explorador de archivos para seleccionar rutas:\n"
            "  input  → seleccionar carpeta/archivos de entrada\n"
            "  output → seleccionar carpeta de salida\n"
            "  all    → seleccionar ambas (por defecto si se usa -s sin argumento)"
        )
    )
    parser.add_argument("--gamma",           type=float, default=1.8)
    parser.add_argument("--noise-floor",     type=int,   default=8)
    parser.add_argument("--crop-threshold",  type=int,   default=10)
    parser.add_argument("--padding",         type=int,   default=15)
    parser.add_argument("--watermark-zone",  type=float, default=0.10)
    args = parser.parse_args()

    # ── Resolución de rutas de entrada ──────────────────────────────────────
    select = args.select
    raw_inputs = list(args.inputs)

    # Selector GUI para entrada
    if select in ("input", "all"):
        print("Abriendo explorador para seleccionar la carpeta/archivos de entrada...")
        chosen = pick_files("Selecciona las imágenes a procesar")
        if not chosen:
            # Si cancela la selección de archivos, intentar con carpeta
            chosen_folder = pick_folder("Selecciona la carpeta de entrada")
            if chosen_folder:
                raw_inputs = [str(chosen_folder)]
            else:
                print("[WARN] No se seleccionó ninguna entrada. Se usará la carpeta ./input")
        else:
            raw_inputs = [str(p) for p in chosen]

    # Sin entradas explícitas → usar ./input
    if not raw_inputs:
        raw_inputs = [str(Path.cwd() / "input")]

    # ── Resolución de ruta de salida ─────────────────────────────────────────
    output_path_str = args.output

    if select in ("output", "all"):
        print("Abriendo explorador para seleccionar la carpeta de salida...")
        chosen_out = pick_folder("Selecciona la carpeta de salida")
        if chosen_out:
            output_path_str = str(chosen_out)
        else:
            print("[WARN] No se seleccionó carpeta de salida. Se usará ./output")

    out = Path(output_path_str) if output_path_str else Path.cwd() / "output"
    out.mkdir(parents=True, exist_ok=True)

    # ── Tamaños PNG ──────────────────────────────────────────────────────────
    png_sizes = args.png_sizes if args.png_sizes else PNG_ICON_SIZES

    # ── Recopilar archivos ────────────────────────────────────────────────────
    valid_extensions = {'.png', '.jpg', '.jpeg', '.webp'}
    files_to_process = []

    for item in raw_inputs:
        path = Path(item)
        if path.is_dir():
            for ext in valid_extensions:
                files_to_process.extend(path.rglob(f"*{ext}"))
                files_to_process.extend(path.rglob(f"*{ext.upper()}"))
        elif "*" in item:
            files_to_process.extend(Path(".").glob(item))
        elif path.exists():
            files_to_process.append(path)
        else:
            print(f"[WARN] No encontrado: {path}")

    # Eliminar duplicados manteniendo orden
    files_to_process = list(dict.fromkeys(files_to_process))

    if not files_to_process:
        print("No se encontraron imágenes válidas para procesar.")
        return

    print(f"\nEntrada : {[str(p) for p in files_to_process[:3]]}{'...' if len(files_to_process) > 3 else ''}")
    print(f"Salida  : {out}")
    print(f"Formatos: {args.formats}  |  Tamaños PNG: {png_sizes}")

    ok = err = 0
    for p in files_to_process:
        try:
            process_logo(
                p, out, args.formats,
                png_sizes=png_sizes,
                gamma=args.gamma,
                noise_floor=args.noise_floor,
                crop_threshold=args.crop_threshold,
                padding=args.padding,
                watermark_zone=args.watermark_zone
            )
            ok += 1
        except Exception as e:
            print(f"[ERROR] {p.name}: {e}")
            err += 1

    print(f"\n{'─'*45}\nCompletado: {ok} logo(s)  |  Errores: {err}")

if __name__ == "__main__":
    main()
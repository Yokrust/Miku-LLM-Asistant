#!/usr/bin/env python3
"""Turn the Miku logo (SVG) into the PNGs the app bundle needs.

macOS menu bar icons are *template* images: only the alpha channel survives —
the system paints them black on a light menu bar, white on a dark one, and
inverts them while the menu is open. So the job here is to turn the logo's ink
into alpha and throw the colour away.

The logo is a single flat silhouette, so the conversion is exact: ink is
#231f20, the page is white, and everything in between is antialiasing.

Rasterising is done by QuickLook (`qlmanage`), which ships with macOS — no
Homebrew, no Python SVG stack. It only renders onto an opaque white page, hence
the luminance → alpha step.

Usage:  python3 Scripts/make-icons.py
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
APP = HERE.parent
REPO = APP.parent
SOURCE = REPO / "Logos" / "SVGS" / "MikuBLogo-1.svg"  # black on white; the white
# sibling would rasterise blank
OUT = APP / "Resources" / "Assets"

# Luminance of the logo's ink (#231f20). Anything at or below this is fully opaque.
INK = 0x23 * 0.299 + 0x1F * 0.587 + 0x20 * 0.114

# Menu bar mark, in points. Status items are 22pt tall (24 on notched Macs); 16pt
# of art sits at the same weight as the system's own icons and as the other apps
# already in the bar.
MENUBAR_PT = 16

# Where the state lives *inside* the mark. The menu bar shows one thing — Miku —
# so the state has to be a change to her, not a second glyph beside her
# (DISENO.md §9.7). Coordinates are fractions of the mark's box.
#
# The core sits in the open lower half of the face: the largest empty circle
# inside the silhouette is centred at (0.50, 0.71) with a radius of 0.26, so a
# 0.115 dot there never touches the hair or the eyes.
CORE = {"x": 0.50, "y": 0.70, "r": 0.115}
# The slash runs bottom-left to top-right, the direction SF Symbols uses for its
# own `.slash` variants. It is drawn twice: once as a wide cut through the alpha,
# so the line stays legible where it crosses the hair, then as the line itself.
SLASH = {"width": 0.075, "gap": 0.05}

# `fondo/lienzo` of the dark theme (DISENO.md §4) — the plate the app icon sits on.
CANVAS = (0x0A, 0x0C, 0x0F)

# The bitmaps `iconutil` expects, and which slot each one fills. One bitmap can
# serve two slots: 32 px is both "32pt @1x" and "16pt @2x".
ICONSET = {
    16: ["icon_16x16.png"],
    32: ["icon_16x16@2x.png", "icon_32x32.png"],
    64: ["icon_32x32@2x.png"],
    128: ["icon_128x128.png"],
    256: ["icon_128x128@2x.png", "icon_256x256.png"],
    512: ["icon_256x256@2x.png", "icon_512x512.png"],
    1024: ["icon_512x512@2x.png"],
}

RENDER_PX = 1024


def rasterise(svg: Path, px: int) -> Image.Image:
    """SVG → RGB bitmap on a white page, via QuickLook."""
    with tempfile.TemporaryDirectory() as tmp:
        # qlmanage names its output after the input file, so give it a copy.
        work = Path(tmp) / svg.name
        work.write_bytes(svg.read_bytes())
        subprocess.run(
            ["qlmanage", "-t", "-s", str(px), "-o", tmp, str(work)],
            check=True,
            capture_output=True,
        )
        png = Path(tmp) / f"{svg.name}.png"
        if not png.exists():
            raise SystemExit(f"QuickLook no pudo rasterizar {svg}")
        return Image.open(png).convert("L")


def to_alpha(page: Image.Image) -> Image.Image:
    """White page with dark ink → black image whose alpha is the ink."""
    # 255 at the ink's luminance, 0 at white, linear across the antialiased edge.
    alpha = page.point(
        lambda v: 255 if v <= INK else round((255 - v) * 255 / (255 - INK))
    )
    alpha = alpha.crop(alpha.getbbox())  # drop the page margin
    black = Image.new("RGBA", alpha.size, (0, 0, 0, 255))
    black.putalpha(alpha)
    return black


def with_core(mark: Image.Image) -> Image.Image:
    """Reposo + core: Miku is listening, thinking, speaking or taking notes."""
    alpha = mark.getchannel("A").copy()
    w, h = alpha.size
    r = CORE["r"] * w
    cx, cy = CORE["x"] * w, CORE["y"] * h
    ImageDraw.Draw(alpha).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    return replace_alpha(mark, alpha)


def with_slash(mark: Image.Image) -> Image.Image:
    """Reposo + slash: the wake word is off, so Miku is not listening at all."""
    alpha = mark.getchannel("A").copy()
    w, h = alpha.size
    line = [(0.10 * w, 0.90 * h), (0.90 * w, 0.10 * h)]
    draw = ImageDraw.Draw(alpha)
    draw.line(line, fill=0, width=round((SLASH["width"] + 2 * SLASH["gap"]) * w))
    draw.line(line, fill=255, width=round(SLASH["width"] * w))
    return replace_alpha(mark, alpha)


def replace_alpha(mark: Image.Image, alpha: Image.Image) -> Image.Image:
    out = mark.copy()
    out.putalpha(alpha)
    return out


def fit(img: Image.Image, box: int) -> Image.Image:
    """Scale to fit a square box, keeping the aspect ratio, centred."""
    w, h = img.size
    scale = box / max(w, h)
    art = img.resize(
        (max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS
    )
    canvas = Image.new("RGBA", (box, box), (0, 0, 0, 0))
    canvas.paste(art, ((box - art.width) // 2, (box - art.height) // 2))
    return canvas


def main() -> int:
    if not SOURCE.exists():
        raise SystemExit(f"no encuentro el logo: {SOURCE}")

    OUT.mkdir(parents=True, exist_ok=True)
    art = to_alpha(rasterise(SOURCE, RENDER_PX))

    # Menu bar: the three marks, 1x/2x/3x of a 16pt box, as template images.
    # `Sin conexión` is not here — it is the resting mark drawn at reduced ink,
    # which the app does at runtime.
    marks = {
        "MenuBarIcon": art,  # reposo
        "MenuBarIconActive": with_core(
            art
        ),  # escuchando · pensando · hablando · anotando
        "MenuBarIconMuted": with_slash(art),  # silenciada
    }
    for stem, mark in marks.items():
        for scale in (1, 2, 3):
            name = f"{stem}.png" if scale == 1 else f"{stem}@{scale}x.png"
            fit(mark, MENUBAR_PT * scale).save(OUT / name)
        print(f"✓ {stem} (1x/2x/3x)")

    # App icon: the same silhouette, but this one is *not* a template, so it has
    # to carry its own contrast — white ink on the canvas colour of the dark theme.
    # Miku is LSUIElement, so this only ever shows in Finder and Get Info.
    with tempfile.TemporaryDirectory() as tmp:
        iconset = Path(tmp) / "Miku.iconset"
        iconset.mkdir()
        for px, names in ICONSET.items():
            plate = app_icon(art, px)
            for name in names:
                plate.save(iconset / name)
        subprocess.run(
            ["iconutil", "-c", "icns", str(iconset), "-o", str(OUT / "Miku.icns")],
            check=True,
        )
    print("✓ Miku.icns")
    return 0


def app_icon(art: Image.Image, px: int) -> Image.Image:
    """One tile of the app icon: white mark on the dark canvas, rounded."""
    plate = Image.new("RGBA", (px, px), CANVAS + (255,))
    # 82% of the tile — roughly the proportion Apple's own icons leave around the art.
    ink = fit(art, round(px * 0.82))
    white = Image.new("RGBA", ink.size, (255, 255, 255, 255))
    white.putalpha(ink.getchannel("A"))
    plate.paste(white, ((px - ink.width) // 2, (px - ink.height) // 2), white)
    return round_corners(plate)


def round_corners(img: Image.Image) -> Image.Image:
    """macOS app icons are squircles; a rounded rect is close enough at this size."""
    from PIL import ImageDraw

    px = img.width
    mask = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, px * 4 - 1, px * 4 - 1], radius=round(px * 4 * 0.225), fill=255
    )
    mask = mask.resize((px, px), Image.LANCZOS)
    out = img.copy()
    out.putalpha(mask)
    return out


if __name__ == "__main__":
    sys.exit(main())

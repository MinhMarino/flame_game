#!/usr/bin/env python3
"""Extract a bee death frame from a sprite sheet and build bee_smashed.png.

Steps:
1. Crop the requested frame from a grid-based sprite sheet
2. Remove the light background (transparent alpha)
3. Auto-trim empty transparent borders
4. Resize to the game's bee sprite size (313px, same base as ant_smashed)

Usage:
  python3 scripts/extract_bee_smashed.py
  python3 scripts/extract_bee_smashed.py --frame 7 --input assets/source/bee_death_sheet.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

# Keep in sync with lib/enemies/enemy_assets.dart
FRAME_SIZE = 313
BEE_DISPLAY_SCALE = 0.315
DEFAULT_FRAME = 7
DEFAULT_COLS = 4
DEFAULT_ROWS = 4


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=root / "assets/source/bee_death_sheet.png",
        help="Source sprite sheet path",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "assets/images/bee_smashed.png",
        help="Output PNG path",
    )
    parser.add_argument(
        "--frame",
        type=int,
        default=DEFAULT_FRAME,
        help="1-based frame index in the sheet grid",
    )
    parser.add_argument("--cols", type=int, default=DEFAULT_COLS)
    parser.add_argument("--rows", type=int, default=DEFAULT_ROWS)
    parser.add_argument(
        "--output-size",
        type=int,
        default=FRAME_SIZE,
        help="Final square output size in pixels",
    )
    parser.add_argument(
        "--bg-threshold",
        type=int,
        default=28,
        help="Background color distance threshold (higher = more aggressive)",
    )
    return parser.parse_args()


def crop_frame(
    image: Image.Image,
    frame: int,
    cols: int,
    rows: int,
) -> Image.Image:
    width, height = image.size
    cell_w = width // cols
    cell_h = height // rows

    index = frame - 1
    row = index // cols
    col = index % cols

    if row >= rows or col >= cols:
        raise ValueError(f"Frame {frame} is outside a {cols}x{rows} grid")

    # Trim in-cell padding used for frame labels.
    pad_x = int(cell_w * 0.06)
    pad_top = int(cell_h * 0.12)
    pad_bottom = int(cell_h * 0.04)

    left = col * cell_w + pad_x
    top = row * cell_h + pad_top
    right = (col + 1) * cell_w - pad_x
    bottom = (row + 1) * cell_h - pad_bottom

    return image.crop((left, top, right, bottom))


def sample_background_color(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    points = [
        (2, 2),
        (width - 3, 2),
        (2, height - 3),
        (width - 3, height - 3),
        (width // 2, 2),
    ]
    rs: list[int] = []
    gs: list[int] = []
    bs: list[int] = []
    for x, y in points:
        r, g, b, _ = rgba.getpixel((x, y))
        rs.append(r)
        gs.append(g)
        bs.append(b)
    return (sum(rs) // len(rs), sum(gs) // len(gs), sum(bs) // len(bs))


def color_distance(
    pixel: tuple[int, int, int, int],
    background: tuple[int, int, int],
) -> int:
    r, g, b, _ = pixel
    br, bg, bb = background
    return abs(r - br) + abs(g - bg) + abs(b - bb)


def remove_background(
    image: Image.Image,
    threshold: int,
) -> Image.Image:
    rgba = image.convert("RGBA")
    background = sample_background_color(rgba)
    pixels = rgba.load()
    width, height = rgba.size

    for y in range(height):
        for x in range(width):
            if color_distance(pixels[x, y], background) <= threshold:
                pixels[x, y] = (pixels[x, y][0], pixels[x, y][1], pixels[x, y][2], 0)

    return rgba


def trim_transparent(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def resize_to_square(image: Image.Image, size: int) -> Image.Image:
    rgba = image.convert("RGBA")
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rgba.thumbnail((size, size), Image.Resampling.LANCZOS)
    offset = ((size - rgba.width) // 2, (size - rgba.height) // 2)
    canvas.paste(rgba, offset, rgba)
    return canvas


def main() -> None:
    args = parse_args()

    if not args.input.exists():
        raise SystemExit(f"Input not found: {args.input}")

    args.output.parent.mkdir(parents=True, exist_ok=True)

    sheet = Image.open(args.input)
    cropped = crop_frame(sheet, args.frame, args.cols, args.rows)
    cutout = remove_background(cropped, args.bg_threshold)
    trimmed = trim_transparent(cutout)
    final = resize_to_square(trimmed, args.output_size)
    final.save(args.output)

    display_size = FRAME_SIZE * BEE_DISPLAY_SCALE
    print(f"Input:        {args.input}")
    print(f"Frame:        {args.frame} ({args.cols}x{args.rows} grid)")
    print(f"Cropped:      {cropped.size}")
    print(f"Trimmed:      {trimmed.size}")
    print(f"Output:       {args.output} ({final.size[0]}x{final.size[1]})")
    print(f"Runtime size: ~{display_size:.1f}px (bee display scale {BEE_DISPLAY_SCALE})")


if __name__ == "__main__":
    main()

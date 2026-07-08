#!/usr/bin/env python3
"""Extract a bee death frame from a sprite sheet and build bee_smashed.png.

Steps:
1. Crop the requested frame from a grid-based sprite sheet
2. Remove the light background (transparent alpha)
3. Auto-trim empty transparent borders
4. Resize to the game's bee sprite size (313px, same base as ant_smashed)

Usage:
  python3 scripts/extract_bee_smashed.py
  python3 scripts/extract_bee_smashed.py --frame 8 --input assets/source/bee_death_sheet.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

# Keep in sync with lib/enemies/enemy_assets.dart
FRAME_SIZE = 313
BEE_DISPLAY_SCALE = 0.315
DEFAULT_FRAME = 8
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
    parser.add_argument(
        "--fly-sheet",
        type=Path,
        default=root / "assets/images/bee_fly_sheet.png",
        help="Live bee fly sheet used to align body center",
    )
    parser.add_argument(
        "--fly-start-frame",
        type=int,
        default=0,
        help="First fly frame index used for center alignment",
    )
    parser.add_argument(
        "--fly-frame-count",
        type=int,
        default=8,
        help="Number of fly frames averaged for center alignment",
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


def content_center(image: Image.Image) -> tuple[float, float] | None:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return None
    return ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2)


def average_content_center(frames: list[Image.Image]) -> tuple[float, float]:
    centers = [c for frame in frames if (c := content_center(frame)) is not None]
    if not centers:
        raise ValueError("No opaque pixels found in reference frames")
    avg_x = sum(x for x, _ in centers) / len(centers)
    avg_y = sum(y for _, y in centers) / len(centers)
    return avg_x, avg_y


def load_fly_reference_center(
    fly_sheet_path: Path,
    frame_size: int,
    start_frame: int,
    frame_count: int,
) -> tuple[float, float]:
    sheet = Image.open(fly_sheet_path).convert("RGBA")
    frames: list[Image.Image] = []
    for index in range(start_frame, start_frame + frame_count):
        left = index * frame_size
        frames.append(sheet.crop((left, 0, left + frame_size, frame_size)))
    return average_content_center(frames)


def resize_to_square(
    image: Image.Image,
    size: int,
    *,
    content_center_target: tuple[float, float] | None = None,
) -> Image.Image:
    rgba = image.convert("RGBA")
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rgba.thumbnail((size, size), Image.Resampling.LANCZOS)

    if content_center_target is None:
        offset = ((size - rgba.width) // 2, (size - rgba.height) // 2)
    else:
        source_center = content_center(rgba)
        if source_center is None:
            offset = ((size - rgba.width) // 2, (size - rgba.height) // 2)
        else:
            target_x, target_y = content_center_target
            offset = (
                int(round(target_x - source_center[0])),
                int(round(target_y - source_center[1])),
            )

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
    reference_center = load_fly_reference_center(
        args.fly_sheet,
        args.output_size,
        args.fly_start_frame,
        args.fly_frame_count,
    )
    final = resize_to_square(
        trimmed,
        args.output_size,
        content_center_target=reference_center,
    )
    final.save(args.output)

    display_size = FRAME_SIZE * BEE_DISPLAY_SCALE
    print(f"Input:        {args.input}")
    print(f"Frame:        {args.frame} ({args.cols}x{args.rows} grid)")
    print(f"Cropped:      {cropped.size}")
    print(f"Trimmed:      {trimmed.size}")
    print(f"Fly center:   ({reference_center[0]:.1f}, {reference_center[1]:.1f})")
    smashed_center = content_center(final)
    if smashed_center is not None:
        print(
            f"Smashed ctr:  ({smashed_center[0]:.1f}, {smashed_center[1]:.1f})"
        )
    print(f"Output:       {args.output} ({final.size[0]}x{final.size[1]})")
    print(f"Runtime size: ~{display_size:.1f}px (bee display scale {BEE_DISPLAY_SCALE})")


if __name__ == "__main__":
    main()

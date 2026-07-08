#!/usr/bin/env python3
"""Build bee_smashed.png from a source death image or sprite sheet.

Steps:
1. Load a single death image or crop one frame from a sprite sheet
2. Remove the light background (transparent alpha)
3. Auto-trim empty transparent borders
4. Scale and center to match ant_smashed proportions in a 313px canvas

Usage:
  python3 scripts/extract_bee_smashed.py
  python3 scripts/extract_bee_smashed.py --input assets/source/bee_death.png
  python3 scripts/extract_bee_smashed.py --frame 8 --input assets/source/bee_death_sheet.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

# Keep in sync with lib/enemies/enemy_assets.dart
FRAME_SIZE = 313
BEE_DISPLAY_SCALE = 0.24
BEE_FLY_FRAME_COUNT = 8
# Death art should read slightly smaller than the live bee body on screen.
DEATH_TO_LIVE_RATIO = 0.92
DEFAULT_FRAME = 8
DEFAULT_COLS = 4
DEFAULT_ROWS = 4


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=root / "assets/source/bee_death.png",
        help="Source image path (single frame or sprite sheet)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "assets/images/bee_smashed.png",
        help="Output PNG path",
    )
    parser.add_argument(
        "--reference-fly",
        type=Path,
        default=root / "assets/images/bee_fly_sheet.png",
        help="Live bee fly sheet used for scale and center alignment",
    )
    parser.add_argument(
        "--reference-ant",
        type=Path,
        default=root / "assets/images/ant_smashed.png",
        help="Optional smashed ant used only for center fallback",
    )
    parser.add_argument(
        "--frame",
        type=int,
        default=DEFAULT_FRAME,
        help="1-based frame index when input is a sprite sheet grid",
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
        "--death-scale",
        type=float,
        default=DEATH_TO_LIVE_RATIO,
        help="Scale death art relative to live bee body size (lower = smaller)",
    )
    parser.add_argument(
        "--rotate",
        type=int,
        default=0,
        help="Rotate extracted art clockwise by this many degrees (0 to skip)",
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


def is_sprite_sheet(image: Image.Image, cols: int, rows: int) -> bool:
    width, height = image.size
    cell_w = width // cols
    cell_h = height // rows
    return cell_w > 0 and cell_h > 0 and cols * cell_w == width and rows * cell_h == height


def sample_background_color(image: Image.Image) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    points = [
        (2, 2),
        (width - 3, 2),
        (2, height - 3),
        (width - 3, height - 3),
        (width // 2, 2),
        (width // 2, height - 3),
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


def is_checkerboard_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, _ = pixel
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    # Neutral light gray / white cells used in exported checkerboards.
    return max_c - min_c <= 18 and max_c >= 180


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
            pixel = pixels[x, y]
            if is_checkerboard_background(pixel) or color_distance(
                pixel,
                background,
            ) <= threshold:
                pixels[x, y] = (pixel[0], pixel[1], pixel[2], 0)

    return rgba


def trim_transparent(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def content_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.getbbox()


def content_center(image: Image.Image) -> tuple[float, float] | None:
    bbox = content_bbox(image)
    if bbox is None:
        return None
    return ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2)


def content_max_dimension(image: Image.Image) -> int:
    bbox = content_bbox(image)
    if bbox is None:
        return 0
    return max(bbox[2] - bbox[0], bbox[3] - bbox[1])


def rotate_art(image: Image.Image, degrees: int) -> Image.Image:
    if degrees % 360 == 0:
        return image
    # PIL rotates counter-clockwise; negate for clockwise degrees.
    return image.rotate(-degrees, expand=True, resample=Image.Resampling.BICUBIC)


def scale_to_max_dimension(image: Image.Image, max_dim: int) -> Image.Image:
    if max_dim <= 0:
        return image
    width, height = image.size
    current_max = max(width, height)
    if current_max == max_dim:
        return image
    scale = max_dim / current_max
    new_size = (
        max(1, int(round(width * scale))),
        max(1, int(round(height * scale))),
    )
    return image.resize(new_size, Image.Resampling.LANCZOS)


def average_content_center(frames: list[Image.Image]) -> tuple[float, float]:
    centers = [c for frame in frames if (c := content_center(frame)) is not None]
    if not centers:
        raise ValueError("No opaque pixels found in reference frames")
    avg_x = sum(x for x, _ in centers) / len(centers)
    avg_y = sum(y for _, y in centers) / len(centers)
    return avg_x, avg_y


def average_content_max_dimension(frames: list[Image.Image]) -> float:
    dims = [content_max_dimension(frame) for frame in frames]
    dims = [dim for dim in dims if dim > 0]
    if not dims:
        raise ValueError("No opaque pixels found in reference frames")
    return sum(dims) / len(dims)


def load_fly_reference(
    fly_sheet_path: Path,
    frame_size: int,
    frame_count: int,
) -> tuple[float, float, float]:
    sheet = Image.open(fly_sheet_path).convert("RGBA")
    frames: list[Image.Image] = []
    for index in range(frame_count):
        left = index * frame_size
        frames.append(sheet.crop((left, 0, left + frame_size, frame_size)))
    center = average_content_center(frames)
    live_max = average_content_max_dimension(frames)
    return center[0], center[1], live_max


def reference_target_from_fly(
    fly_reference_path: Path,
    output_size: int,
    frame_count: int,
    death_scale: float,
) -> tuple[float, float, int]:
    target_x, target_y, live_max = load_fly_reference(
        fly_reference_path,
        output_size,
        frame_count,
    )
    target_max = int(round(live_max * death_scale))
    return target_x, target_y, target_max


def place_on_canvas(
    image: Image.Image,
    size: int,
    *,
    content_center_target: tuple[float, float],
) -> Image.Image:
    rgba = image.convert("RGBA")
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
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


def load_source_frame(args: argparse.Namespace) -> Image.Image:
    sheet = Image.open(args.input)
    if is_sprite_sheet(sheet, args.cols, args.rows):
        return crop_frame(sheet, args.frame, args.cols, args.rows)
    return sheet


def main() -> None:
    args = parse_args()

    if not args.input.exists():
        raise SystemExit(f"Input not found: {args.input}")
    if not args.reference_fly.exists():
        raise SystemExit(f"Fly reference not found: {args.reference_fly}")

    args.output.parent.mkdir(parents=True, exist_ok=True)

    source = load_source_frame(args)
    cutout = remove_background(source, args.bg_threshold)
    trimmed = trim_transparent(cutout)
    rotated = rotate_art(trimmed, args.rotate)

    target_x, target_y, target_max = reference_target_from_fly(
        args.reference_fly,
        args.output_size,
        BEE_FLY_FRAME_COUNT,
        args.death_scale,
    )
    scaled = scale_to_max_dimension(rotated, target_max)
    final = place_on_canvas(
        scaled,
        args.output_size,
        content_center_target=(target_x, target_y),
    )
    final.save(args.output)

    display_size = FRAME_SIZE * BEE_DISPLAY_SCALE
    print(f"Input:        {args.input}")
    if is_sprite_sheet(source, args.cols, args.rows):
        print(f"Frame:        {args.frame} ({args.cols}x{args.rows} grid)")
    else:
        print("Mode:         single image")
    print(f"Rotate:       {args.rotate}°")
    print(f"Trimmed:      {trimmed.size}")
    print(f"Live bee max: {reference_target_from_fly(args.reference_fly, args.output_size, BEE_FLY_FRAME_COUNT, 1.0)[2]:.0f}px avg")
    print(
        f"Target max:   {target_max}px "
        f"({args.death_scale:.0%} of live bee body)"
    )
    print(f"Scaled:       {scaled.size}")
    print(f"Center:       ({target_x:.1f}, {target_y:.1f})")
    smashed_center = content_center(final)
    smashed_max = content_max_dimension(final)
    if smashed_center is not None:
        print(
            f"Smashed ctr:  ({smashed_center[0]:.1f}, {smashed_center[1]:.1f})"
        )
    print(f"Smashed max:  {smashed_max}px")
    print(f"Output:       {args.output} ({final.size[0]}x{final.size[1]})")
    print(f"Runtime size: ~{display_size:.1f}px (bee display scale {BEE_DISPLAY_SCALE})")


if __name__ == "__main__":
    main()

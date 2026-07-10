#!/usr/bin/env python3
"""Generate the 5 Lollipop health-stage sprites via the OpenAI Images API.

Produces `lollipop_100.png`, `lollipop_75.png`, `lollipop_50.png`,
`lollipop_25.png`, and `lollipop_0.png` in `assets/images/`, matching the
existing casual mobile game art style (bold black outline, glossy cel
shading, transparent background, top-down orthographic view).

Each damage stage is generated as an edit of the previous stage so the
lollipop is progressively "eaten" rather than redesigned from scratch.

Requires: OPENAI_API_KEY environment variable (never written to disk).

Usage:
  python3 scripts/generate_lollipop_assets.py
"""

from __future__ import annotations

import base64
import os
from pathlib import Path

import requests
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/source/lollipop"
OUTPUT_DIR = ROOT / "assets/images"
REFERENCE_IMAGE = SOURCE_DIR / "lollipop_reference.png"

MODEL = "gpt-image-1"
GEN_SIZE = "1024x1024"
FINAL_SIZE = 313  # Matches EnemyAssets.frameSize canvas convention.

STYLE_DESCRIPTION = (
    "Casual mobile game icon art style: bold clean black outline "
    "(roughly 4-6% of the object's width), glossy cel-shaded coloring with "
    "one bright soft highlight and simple gradient shading, flat vivid "
    "saturated colors, no background, no drop shadow, no text, no "
    "watermark, crisp vector-like rendering quality, centered composition "
    "with even padding on all sides, top-down orthographic view."
)

OUTLINE_REMINDER = (
    " Every single shape in the image, including the stick, bow, candy "
    "body, crumbs, and shard pieces, must keep the same bold thick black "
    "cartoon outline seen in the original pristine lollipop reference "
    "image (the first input image) - do not thin, fade, or remove the "
    "black outline on any element."
)

STAGES = [
    {
        "name": "lollipop_100",
        "label": "100% HP - brand new",
        "prompt": (
            "A colorful spiral swirl lollipop candy on a short wooden "
            "stick with a red ribbon bow tied below the candy head, "
            "rainbow swirl pattern (red, orange, yellow, green, blue), "
            "perfectly round and pristine with no damage or bites. "
            f"{STYLE_DESCRIPTION} Transparent background."
        ),
    },
    {
        "name": "lollipop_75",
        "label": "75% HP - slightly damaged",
        "prompt": (
            "The first input image is the ORIGINAL pristine lollipop "
            "(style + outline reference). The second input image is the "
            "CURRENT state to edit. Take the current lollipop and add "
            "only a small, subtle bite mark chipped out of the outer edge "
            "of the candy, as if a tiny insect took one nibble. Keep the "
            "stick, red bow, rainbow swirl colors, shading style, camera "
            "angle, size, and position completely identical otherwise. Do "
            "not redesign the lollipop. "
            f"{STYLE_DESCRIPTION}{OUTLINE_REMINDER} Transparent background."
        ),
    },
    {
        "name": "lollipop_50",
        "label": "50% HP - noticeably bitten",
        "prompt": (
            "The first input image is the ORIGINAL pristine lollipop "
            "(style + outline reference). The second input image is the "
            "CURRENT state to edit. Take the current lollipop and make "
            "the bite damage more severe: roughly half of the candy disc "
            "is now missing, with ragged, uneven bitten edges and a few "
            "tiny candy crumb pieces scattered near the base, as if "
            "insects have been steadily nibbling it away. Keep the stick, "
            "red bow, remaining rainbow swirl colors, shading style, "
            "camera angle, and position identical otherwise. Do not "
            "redesign the lollipop. "
            f"{STYLE_DESCRIPTION}{OUTLINE_REMINDER} Transparent background."
        ),
    },
    {
        "name": "lollipop_25",
        "label": "25% HP - heavily damaged",
        "prompt": (
            "The first input image is the ORIGINAL pristine lollipop "
            "(style + outline reference). The second input image is the "
            "CURRENT state to edit. Take the current lollipop and make "
            "the damage severe: only a small, jagged, heavily-nibbled nub "
            "of the candy remains attached to the stick, most of the "
            "original disc is gone, with several candy crumbs and small "
            "broken shards scattered around the base. Keep the stick, red "
            "bow, remaining candy colors, shading style, camera angle, and "
            "position identical otherwise. Do not redesign the lollipop. "
            f"{STYLE_DESCRIPTION}{OUTLINE_REMINDER} Transparent background."
        ),
    },
    {
        "name": "lollipop_0",
        "label": "0% HP - destroyed",
        "prompt": (
            "The first input image is the ORIGINAL pristine lollipop "
            "(style + outline reference). The second input image is the "
            "CURRENT state to edit. Show the lollipop's final destroyed "
            "state: the candy head is completely eaten away, leaving only "
            "the bare wooden stick with the red ribbon bow still tied to "
            "it, lying at a slight angle, surrounded by a small scatter "
            "of candy crumbs and a couple of tiny cracked candy shard "
            "pieces on the ground around it. Keep the stick, bow, color "
            "palette, shading style, and camera angle consistent with the "
            "original image. "
            f"{STYLE_DESCRIPTION}{OUTLINE_REMINDER} Transparent background."
        ),
    },
]


def api_key() -> str:
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        raise SystemExit("OPENAI_API_KEY environment variable is not set.")
    return key


def save_b64_png(b64_data: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(base64.b64decode(b64_data))


def generate_first_stage(headers: dict, *, force: bool = False) -> Path:
    """Text-to-image generation for the pristine (100% HP) lollipop."""
    out_path = SOURCE_DIR / "lollipop_100_raw.png"
    if out_path.exists() and not force:
        print(f"Reusing cached {STAGES[0]['label']} -> {out_path}")
        return out_path
    response = requests.post(
        "https://api.openai.com/v1/images/generations",
        headers=headers,
        json={
            "model": MODEL,
            "prompt": STAGES[0]["prompt"],
            "size": GEN_SIZE,
            "quality": "high",
            "background": "transparent",
            "output_format": "png",
            "n": 1,
        },
        timeout=180,
    )
    response.raise_for_status()
    data = response.json()["data"][0]
    save_b64_png(data["b64_json"], out_path)
    print(f"Generated {STAGES[0]['label']} -> {out_path}")
    return out_path


def edit_next_stage(
    headers: dict,
    stage: dict,
    original_image: Path,
    previous_image: Path,
) -> Path:
    """Image-edit chaining: derive each damage stage from the prior stage.

    Always includes the original pristine (100% HP) render as the first
    input image so the black outline / shading style has a strong anchor
    and doesn't drift away over successive edits.
    """
    out_path = SOURCE_DIR / f"{stage['name']}_raw.png"
    files = [
        (
            "image[]",
            (original_image.name, original_image.open("rb"), "image/png"),
        ),
        (
            "image[]",
            (previous_image.name, previous_image.open("rb"), "image/png"),
        ),
    ]
    data = {
        "model": MODEL,
        "prompt": stage["prompt"],
        "size": GEN_SIZE,
        "quality": "high",
        "background": "transparent",
        "output_format": "png",
        "input_fidelity": "high",
        "n": "1",
    }
    response = requests.post(
        "https://api.openai.com/v1/images/edits",
        headers=headers,
        data=data,
        files=files,
        timeout=180,
    )
    response.raise_for_status()
    result = response.json()["data"][0]
    save_b64_png(result["b64_json"], out_path)
    print(f"Generated {stage['label']} -> {out_path}")
    return out_path


def trim_transparent(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def postprocess(raw_path: Path, final_path: Path, canvas_size: int) -> None:
    """Trim transparent padding, then center on a fixed square canvas."""
    image = Image.open(raw_path).convert("RGBA")
    trimmed = trim_transparent(image)

    max_dim = max(trimmed.size)
    target_max = int(canvas_size * 0.86)
    if max_dim > 0:
        scale = target_max / max_dim
        new_size = (
            max(1, int(round(trimmed.width * scale))),
            max(1, int(round(trimmed.height * scale))),
        )
        trimmed = trimmed.resize(new_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = (
        (canvas_size - trimmed.width) // 2,
        (canvas_size - trimmed.height) // 2,
    )
    canvas.paste(trimmed, offset, trimmed)
    final_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(final_path)


def main() -> None:
    if not REFERENCE_IMAGE.exists():
        raise SystemExit(f"Reference image not found: {REFERENCE_IMAGE}")

    headers = {"Authorization": f"Bearer {api_key()}"}

    raw_paths: list[Path] = [generate_first_stage(headers)]
    for stage in STAGES[1:]:
        raw_paths.append(
            edit_next_stage(headers, stage, raw_paths[0], raw_paths[-1])
        )

    for stage, raw_path in zip(STAGES, raw_paths):
        final_path = OUTPUT_DIR / f"{stage['name']}.png"
        postprocess(raw_path, final_path, FINAL_SIZE)
        print(f"Saved final -> {final_path}")


if __name__ == "__main__":
    main()

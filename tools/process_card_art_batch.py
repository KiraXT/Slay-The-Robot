#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path

from PIL import Image


if __package__:
    from tools.card_art_chroma import remove_chroma_key
    from tools.card_art_manifest import key_color_for_card
else:
    from card_art_chroma import remove_chroma_key
    from card_art_manifest import key_color_for_card


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools" / "card_art_individualization_manifest.json"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"


def _parse_key_color(key_color: str) -> tuple[int, int, int]:
    value = key_color.removeprefix("#")
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


def _remove_key_fringe(
    image: Image.Image,
    key_color: str,
) -> Image.Image:
    rgba = image.convert("RGBA")
    key_red, key_green, key_blue = _parse_key_color(key_color)
    cleaned_pixels = []
    for red, green, blue, alpha in rgba.getdata():
        distance = max(
            abs(red - key_red),
            abs(green - key_green),
            abs(blue - key_blue),
        )
        if 0 < alpha < 255 and distance <= 32:
            cleaned_pixels.append((0, 0, 0, 0))
        else:
            cleaned_pixels.append((red, green, blue, alpha))
    rgba.putdata(cleaned_pixels)
    return rgba


def _normalize_subject(image: Image.Image) -> Image.Image:
    visible_alpha = image.getchannel("A").point(
        lambda alpha: 255 if alpha > 16 else 0
    )
    bbox = visible_alpha.getbbox()
    if bbox is None:
        return image

    subject = image.crop(bbox)
    max_subject_size = 420
    scale = min(
        1.0,
        max_subject_size / subject.width,
        max_subject_size / subject.height,
    )
    if scale < 1.0:
        subject = subject.resize(
            (
                max(1, round(subject.width * scale)),
                max(1, round(subject.height * scale)),
            ),
            Image.Resampling.LANCZOS,
        )

    canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    left = (canvas.width - subject.width) // 2
    top = (canvas.height - subject.height) // 2
    canvas.alpha_composite(subject, (left, top))
    return canvas


def process_one(raw_path: Path, output_path: Path, key_color: str) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(raw_path) as source:
        keyed = remove_chroma_key(
            source,
            key_color,
            transparent_threshold=24,
            opaque_threshold=90,
            edge_contract=1,
            edge_feather=0.7,
            despill=True,
        )
    final = keyed.resize(
        (512, 512),
        Image.Resampling.LANCZOS,
    )
    final = _remove_key_fringe(final, key_color)
    final = _normalize_subject(final)
    final = _remove_key_fringe(final, key_color)
    final.save(output_path, format="PNG", optimize=True)


def process_phase(phase: str) -> list[Path]:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        rows = {
            row["object_id"]: row
            for row in csv.DictReader(handle)
            if row.get("object_id")
        }

    outputs = []
    for card_id in manifest["phases"][phase]:
        color_id = rows[card_id]["card_color_id"]
        color_folder = color_id.removeprefix("color_")
        raw_path = (
            ROOT
            / "tmp"
            / "card-art-individualization"
            / "raw"
            / f"{card_id}.png"
        )
        output_path = (
            ROOT
            / "external"
            / "sprites"
            / "cards"
            / color_folder
            / f"{card_id}.png"
        )
        key_color = key_color_for_card(manifest, card_id, color_id)
        process_one(raw_path, output_path, key_color)
        outputs.append(output_path)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--phase",
        required=True,
        choices=("pilot", "red", "colored", "team"),
    )
    args = parser.parse_args()
    outputs = process_phase(args.phase)
    print(f"CARD_ART_PROCESSED: {len(outputs)}")


if __name__ == "__main__":
    main()

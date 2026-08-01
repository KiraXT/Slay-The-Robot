#!/usr/bin/env python3
"""Render card-art phases into a neutral-background contact sheet."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont

if __package__:
    from tools.card_art_manifest import (
        manifest_card_ids,
        validate_card_color_contract,
    )
else:
    from card_art_manifest import (
        manifest_card_ids,
        validate_card_color_contract,
    )


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "tools" / "card_art_individualization_manifest.json"
CARDS_CSV_PATH = ROOT / "external" / "config" / "cards.csv"
CELL_WIDTH = 560
CELL_HEIGHT = 620
ART_SIZE = 512
ART_LEFT = 24
ART_TOP = 16
BACKGROUND = (38, 42, 48)
ART_BORDER = (76, 83, 92)
LABEL_COLOR = (242, 244, 247)
ID_COLOR = (172, 181, 191)


def _load_manifest() -> dict[str, object]:
    with MANIFEST_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _load_cards() -> dict[str, dict[str, str]]:
    with CARDS_CSV_PATH.open("r", encoding="utf-8", newline="") as handle:
        lines = handle.readlines()
    header_index = next(
        index
        for index, line in enumerate(lines)
        if line.split(",", 1)[0].strip() == "object_id"
    )
    reader = csv.DictReader(lines[header_index:])
    cards: dict[str, dict[str, str]] = {}
    for row in reader:
        object_id = (row.get("object_id") or "").strip()
        if not object_id or object_id.startswith("#"):
            continue
        cards[object_id] = row
    return cards


def _phase_ids(manifest: dict[str, object], phase: str) -> list[str]:
    phases = manifest.get("phases")
    if not isinstance(phases, dict):
        raise ValueError("manifest phases must be an object")
    if phase == "all":
        values: Iterable[object] = (
            card_id
            for phase_name in ("pilot", "red", "colored", "team")
            for card_id in phases.get(phase_name, [])
        )
    else:
        if phase not in phases:
            raise ValueError(f"unknown card-art phase: {phase}")
        values = phases[phase]
    card_ids = [card_id for card_id in values if isinstance(card_id, str)]
    if not card_ids:
        raise ValueError(f"card-art phase is empty: {phase}")
    return card_ids


def _texture_path(manifest: dict[str, object], card_id: str) -> str:
    color_ids = validate_card_color_contract(
        manifest,
        manifest_card_ids(manifest),
    )
    color_folder = color_ids[card_id].removeprefix("color_")
    return f"external/sprites/cards/{color_folder}/{card_id}.png"


def _font(paths: list[str], size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in paths:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def _fit_font(
    text: str,
    paths: list[str],
    maximum_size: int,
    maximum_width: int,
) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for size in range(maximum_size, 9, -1):
        font = _font(paths, size)
        if ImageDraw.Draw(Image.new("RGB", (1, 1))).textbbox((0, 0), text, font=font)[2] <= maximum_width:
            return font
    return _font(paths, 10)


def render_contact_sheet(phase: str, output_path: Path) -> Path:
    """Render one manifest phase and return the written RGB PNG path."""
    manifest = _load_manifest()
    cards = _load_cards()
    card_ids = _phase_ids(manifest, phase)
    columns = 4 if phase == "pilot" else 5
    rows = (len(card_ids) + columns - 1) // columns
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)

    sheet = Image.new("RGB", (columns * CELL_WIDTH, rows * CELL_HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    font_paths = [
        "/System/Library/Fonts/STHeiti Medium.ttc",
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    ]

    for index, card_id in enumerate(card_ids):
        card = cards.get(card_id, {})
        texture_path = _texture_path(manifest, card_id)
        source_path = ROOT / texture_path
        if not source_path.exists():
            raise FileNotFoundError(source_path)

        column = index % columns
        row = index // columns
        cell_left = column * CELL_WIDTH
        cell_top = row * CELL_HEIGHT
        art_box = (
            cell_left + ART_LEFT,
            cell_top + ART_TOP,
            cell_left + ART_LEFT + ART_SIZE,
            cell_top + ART_TOP + ART_SIZE,
        )
        draw.rectangle(art_box, outline=ART_BORDER, width=2)
        with Image.open(source_path) as source:
            art = source.convert("RGBA")
            if art.size != (ART_SIZE, ART_SIZE):
                art = art.resize((ART_SIZE, ART_SIZE), Image.Resampling.LANCZOS)
            composite = Image.new("RGB", art.size, BACKGROUND)
            composite.paste(art, mask=art.getchannel("A"))
            sheet.paste(composite, (cell_left + ART_LEFT, cell_top + ART_TOP))

        name = (card.get("card_name") or card_id).strip()
        name_font = _fit_font(name, font_paths, 25, CELL_WIDTH - 48)
        id_font = _font(font_paths, 17)
        name_box = draw.textbbox((0, 0), name, font=name_font)
        id_box = draw.textbbox((0, 0), card_id, font=id_font)
        name_x = cell_left + (CELL_WIDTH - (name_box[2] - name_box[0])) // 2
        id_x = cell_left + (CELL_WIDTH - (id_box[2] - id_box[0])) // 2
        draw.text((name_x, cell_top + 538), name, fill=LABEL_COLOR, font=name_font)
        draw.text((id_x, cell_top + 574), card_id, fill=ID_COLOR, font=id_font)

    sheet.save(output, format="PNG")
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", choices=("pilot", "red", "colored", "team", "all"), required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    render_contact_sheet(args.phase, args.output)


if __name__ == "__main__":
    main()

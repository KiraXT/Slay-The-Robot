#!/usr/bin/env python3
"""Regression checks for the card-art contact sheet renderer."""

from pathlib import Path
import sys
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.render_card_art_contact_sheet import (
    _load_manifest,
    _phase_ids,
    _texture_path,
    render_contact_sheet,
)


def _assert_non_background_content(image: Image.Image, columns: int, rows: int) -> None:
    background = image.getpixel((0, 0))
    cell_width = image.width // columns
    cell_height = image.height // rows
    for row in range(rows):
        for column in range(columns):
            left = column * cell_width
            top = row * cell_height
            sample = image.crop((left + 26, top + 18, left + 534, top + 526))
            colors = sample.getcolors(maxcolors=sample.width * sample.height)
            assert colors is not None
            assert any(color != background for _, color in colors), (
                f"cell {column},{row} contains no card-art pixels"
            )


def _assert_card_order(
    image: Image.Image,
    card_ids: list[str],
    manifest: dict,
) -> None:
    background = image.getpixel((0, 0))
    for index, card_id in enumerate(card_ids):
        column = index % 5
        row = index // 5
        with Image.open(ROOT / _texture_path(manifest, card_id)) as source:
            art = source.convert("RGBA")
        expected = Image.new("RGB", (512, 512), background)
        expected.paste(art, mask=art.getchannel("A"))
        actual = image.crop(
            (
                column * 560 + 24,
                row * 620 + 16,
                column * 560 + 536,
                row * 620 + 528,
            )
        )
        assert actual.tobytes() == expected.tobytes(), (
            f"cell {index} does not contain canonical card {card_id}"
        )


def main() -> None:
    manifest = _load_manifest()
    expected_all_ids = [
        card_id
        for phase_name in ("pilot", "red", "colored", "team")
        for card_id in manifest["phases"][phase_name]
    ]
    all_ids = _phase_ids(manifest, "all")
    assert all_ids == expected_all_ids
    assert len(all_ids) == 50
    assert len(set(all_ids)) == 50

    test_temp_root = ROOT / "tmp" / "card-art-contact-sheet-test"
    test_temp_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix="run-", dir=test_temp_root
    ) as directory:
        output = render_contact_sheet("pilot", Path(directory) / "pilot.png")
        assert output.exists()
        with Image.open(output) as image:
            assert image.mode == "RGB"
            assert image.width == 4 * 560
            assert image.height == 2 * 620
            assert image.getpixel((0, 0)) == (38, 42, 48)
            _assert_non_background_content(image, 4, 2)

        output = render_contact_sheet("all", Path(directory) / "all.png")
        assert output.exists()
        with Image.open(output) as image:
            assert image.mode == "RGB"
            assert image.size == (2800, 6200)
            assert image.getpixel((0, 0)) == (38, 42, 48)
            _assert_non_background_content(image, 5, 10)
            _assert_card_order(image, all_ids, manifest)

    print("ALL_TESTS_PASSED")


if __name__ == "__main__":
    main()

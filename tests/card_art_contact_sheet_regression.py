#!/usr/bin/env python3
"""Regression checks for the card-art contact sheet renderer."""

from pathlib import Path
import sys
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.render_card_art_contact_sheet import render_contact_sheet


def _assert_non_background_content(image: Image.Image, columns: int, rows: int) -> None:
    background = image.getpixel((0, 0))
    cell_width = image.width // columns
    cell_height = image.height // rows
    for row in range(rows):
        for column in range(columns):
            left = column * cell_width
            top = row * cell_height
            sample = image.crop((left + 24, top + 16, left + 536, top + 528))
            colors = sample.getcolors(maxcolors=sample.width * sample.height)
            assert colors is not None
            assert any(color != background for _, color in colors), (
                f"cell {column},{row} contains no card-art pixels"
            )


def main() -> None:
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

    print("ALL_TESTS_PASSED")


if __name__ == "__main__":
    main()

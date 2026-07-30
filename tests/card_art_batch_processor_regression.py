#!/usr/bin/env python3
import tempfile
import sys
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


def main() -> None:
    from tools.process_card_art_batch import process_one

    with tempfile.TemporaryDirectory() as temporary_directory:
        temporary = Path(temporary_directory)
        raw_path = temporary / "raw.png"
        output_path = temporary / "output.png"

        source = Image.new("RGBA", (64, 64), (0, 255, 0, 255))
        draw = ImageDraw.Draw(source, "RGBA")
        draw.rectangle((15, 15, 48, 48), fill=(255, 0, 0, 128))
        draw.rectangle((16, 16, 47, 47), fill=(255, 0, 0, 255))
        source.save(raw_path)

        process_one(
            raw_path=raw_path,
            output_path=output_path,
            key_color="#00ff00",
        )

        with Image.open(output_path) as image:
            assert image.size == (512, 512)
            assert image.mode == "RGBA"
            assert image.getpixel((0, 0))[3] == 0
            assert image.getpixel((256, 256))[3] == 255
            green_fringe = sum(
                1
                for red, green, blue, alpha in image.getdata()
                if 0 < alpha < 255
                and max(abs(red), abs(green - 255), abs(blue)) <= 32
            )
            assert green_fringe == 0

        color_raw_path = temporary / "color-raw.png"
        color_output_path = temporary / "color-output.png"
        color_source = Image.new("RGBA", (64, 64), (255, 0, 255, 255))
        color_draw = ImageDraw.Draw(color_source, "RGBA")
        warm_subject = (244, 190, 160, 255)
        color_draw.rectangle((14, 14, 49, 49), fill=(40, 30, 20, 255))
        color_draw.rectangle((16, 16, 47, 47), fill=warm_subject)
        yellow_foreground = (255, 235, 47, 255)
        color_draw.rectangle((24, 24, 39, 39), fill=yellow_foreground)
        color_source.save(color_raw_path)

        process_one(
            raw_path=color_raw_path,
            output_path=color_output_path,
            key_color="#ff00ff",
        )

        with Image.open(color_output_path) as image:
            assert image.getpixel((0, 0))[3] == 0
            assert image.getpixel((160, 160)) == warm_subject
            assert image.getpixel((256, 256)) == yellow_foreground
            magenta_fringe = sum(
                1
                for red, green, blue, alpha in image.getdata()
                if 0 < alpha < 255
                and max(abs(red - 255), abs(green), abs(blue - 255)) <= 32
            )
            assert magenta_fringe == 0

        edge_raw_path = temporary / "edge-raw.png"
        edge_output_path = temporary / "edge-output.png"
        edge_source = Image.new("RGBA", (64, 64), (0, 255, 0, 255))
        edge_draw = ImageDraw.Draw(edge_source, "RGBA")
        edge_draw.rectangle((0, 16, 47, 47), fill=(255, 0, 0, 255))
        edge_source.save(edge_raw_path)

        process_one(
            raw_path=edge_raw_path,
            output_path=edge_output_path,
            key_color="#00ff00",
        )

        with Image.open(edge_output_path) as image:
            visible_bbox = image.getchannel("A").point(
                lambda alpha: 255 if alpha > 16 else 0
            ).getbbox()
            assert visible_bbox is not None
            assert visible_bbox[0] >= 32
            assert visible_bbox[2] - visible_bbox[0] <= 420
            assert visible_bbox[3] - visible_bbox[1] <= 420

    print("CARD_ART_BATCH_PROCESSOR_VALIDATED")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Focused regression checks for approved card-art asset guards."""

import copy
import hashlib
import sys
import unittest
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tests import card_individual_art_regression as validator


VALID_DEFAULTS = {
    "color_red": "#00ff00",
    "color_blue": "#ff00ff",
    "color_green": "#ff00ff",
    "color_orange": "#0055ff",
    "color_white": "#ff00ff",
    "color_purple": "#ff00ff",
}


def _rgba_digest(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()


def _contract_ready_manifest() -> dict:
    manifest = copy.deepcopy(validator.load_manifest())
    card_ids = validator.manifest_card_ids(manifest)
    manifest["key_colors"] = {
        "defaults": dict(VALID_DEFAULTS),
        "overrides": {
            "attack_increase_cost_on_damage_taken_card": "#00ff00",
            "card_banish_attack": "#ff00ff",
        },
    }
    manifest["approved_rgba_sha256"] = {
        card_id: hashlib.sha256(card_id.encode("utf-8")).hexdigest()
        for card_id in card_ids
    }
    return manifest


class CardArtApprovedAssetGuardsRegression(unittest.TestCase):
    def test_one_pixel_subject_is_rejected(self) -> None:
        self.assertTrue(
            hasattr(validator, "validate_approved_asset"),
            "missing approved asset guard",
        )
        image = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        image.putpixel((256, 256), (255, 0, 0, 255))

        with self.assertRaisesRegex(AssertionError, "visible pixel count"):
            validator.validate_approved_asset(
                "synthetic_one_pixel",
                image,
                _rgba_digest(image),
            )

    def test_digest_mismatch_is_rejected(self) -> None:
        self.assertTrue(
            hasattr(validator, "validate_approved_asset"),
            "missing approved asset guard",
        )
        image = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        ImageDraw.Draw(image).rectangle(
            (156, 156, 355, 355),
            fill=(255, 0, 0, 255),
        )

        with self.assertRaisesRegex(
            AssertionError,
            "approved RGBA digest mismatch",
        ):
            validator.validate_approved_asset(
                "synthetic_digest_mismatch",
                image,
                "0" * 64,
            )

    def test_duplicate_approved_digests_are_rejected(self) -> None:
        manifest = _contract_ready_manifest()
        card_ids = validator.manifest_card_ids(manifest)
        manifest["approved_rgba_sha256"][card_ids[1]] = (
            manifest["approved_rgba_sha256"][card_ids[0]]
        )

        with self.assertRaisesRegex(
            AssertionError,
            "approved RGBA digests must be unique",
        ):
            validator.validate_manifest_invariants(manifest)

    def test_missing_or_invalid_approved_digest_is_rejected(self) -> None:
        missing = _contract_ready_manifest()
        missing["approved_rgba_sha256"].pop(
            validator.manifest_card_ids(missing)[0]
        )
        with self.assertRaisesRegex(
            AssertionError,
            "exactly one digest per canonical card ID",
        ):
            validator.validate_manifest_invariants(missing)

        invalid = _contract_ready_manifest()
        invalid["approved_rgba_sha256"][
            validator.manifest_card_ids(invalid)[0]
        ] = "not-a-sha256"
        with self.assertRaisesRegex(AssertionError, "valid SHA-256"):
            validator.validate_manifest_invariants(invalid)


def main() -> None:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(
        CardArtApprovedAssetGuardsRegression
    )
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemExit(1)
    print("CARD_ART_APPROVED_ASSET_GUARDS_VALIDATED")


if __name__ == "__main__":
    main()

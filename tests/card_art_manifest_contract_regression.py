#!/usr/bin/env python3
"""Focused regression checks for the shared card-art manifest contract."""

import copy
import hashlib
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tests import card_individual_art_regression as validator
from tools import process_card_art_batch as processor


VALID_DEFAULTS = {
    "color_red": "#00ff00",
    "color_blue": "#ff00ff",
    "color_green": "#ff00ff",
    "color_orange": "#0055ff",
    "color_white": "#ff00ff",
    "color_purple": "#ff00ff",
}
VALID_OVERRIDES = {
    "attack_increase_cost_on_damage_taken_card": "#00ff00",
    "card_banish_attack": "#ff00ff",
}


def _contract_ready_manifest() -> dict:
    manifest = copy.deepcopy(validator.load_manifest())
    card_ids = validator.manifest_card_ids(manifest)
    manifest["key_colors"] = {
        "defaults": dict(VALID_DEFAULTS),
        "overrides": dict(VALID_OVERRIDES),
    }
    manifest["approved_rgba_sha256"] = {
        card_id: hashlib.sha256(card_id.encode("utf-8")).hexdigest()
        for card_id in card_ids
    }
    return manifest


class CardArtManifestContractRegression(unittest.TestCase):
    def test_processor_reads_defaults_and_overrides_from_manifest(self) -> None:
        manifest = _contract_ready_manifest()
        self.assertTrue(
            hasattr(processor, "key_color_for_card"),
            "batch processor has no injectable manifest key-color resolver",
        )

        manifest["key_colors"]["defaults"]["color_blue"] = "#123456"
        manifest["key_colors"]["overrides"]["card_banish_attack"] = "#654321"
        self.assertEqual(
            processor.key_color_for_card(
                manifest,
                "card_backup_drink",
                "color_blue",
            ),
            "#123456",
        )
        self.assertEqual(
            processor.key_color_for_card(
                manifest,
                "card_banish_attack",
                "color_red",
            ),
            "#654321",
        )

    def test_manifest_rejects_wrong_default_ids_and_invalid_colors(self) -> None:
        mutations = []

        missing_default = _contract_ready_manifest()
        del missing_default["key_colors"]["defaults"]["color_purple"]
        mutations.append(("exactly the six expected color IDs", missing_default))

        extra_default = _contract_ready_manifest()
        extra_default["key_colors"]["defaults"]["color_debug"] = "#ffffff"
        mutations.append(("exactly the six expected color IDs", extra_default))

        invalid_color = _contract_ready_manifest()
        invalid_color["key_colors"]["defaults"]["color_red"] = "00ff00"
        mutations.append(("valid #rrggbb", invalid_color))

        for expected_message, manifest in mutations:
            with self.subTest(expected_message=expected_message):
                with self.assertRaisesRegex(AssertionError, expected_message):
                    validator.validate_manifest_invariants(manifest)

    def test_manifest_rejects_override_outside_canonical_cards(self) -> None:
        manifest = _contract_ready_manifest()
        manifest["key_colors"]["overrides"]["card_debug_log"] = "#00ff00"

        with self.assertRaisesRegex(
            AssertionError,
            "override IDs must be canonical card IDs",
        ):
            validator.validate_manifest_invariants(manifest)


def main() -> None:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(
        CardArtManifestContractRegression
    )
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        raise SystemExit(1)
    print("CARD_ART_MANIFEST_CONTRACT_VALIDATED")


if __name__ == "__main__":
    main()

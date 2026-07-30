#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path

from openpyxl import load_workbook
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "external" / "config" / "cards.csv"
XLSX_PATH = ROOT / "external" / "config" / "cards.xlsx"
MANIFEST = ROOT / "tools" / "card_art_individualization_manifest.json"

EXPECTED_PHASES = {
    "pilot": {
        "card_finisher",
        "card_backup_drink",
        "card_metronome",
        "card_bag_swing",
        "card_block_initial",
        "variable_cost_attack_card",
        "card_attack_block",
        "card_damage_increase",
    },
    "red": {
        "attack_lower_cost_on_discard_card",
        "attack_with_conditional_block_card",
        "attack_with_conditional_draw_card",
        "card_banish_attack",
        "card_discard_block",
        "card_draft_red_card",
        "card_duplicate_attacks",
        "card_law",
        "card_opening_strike",
        "card_play_random_from_hand",
        "card_pursuit",
        "card_requires_adjacency",
        "card_right_click_transform_mode_a",
        "card_right_click_transform_mode_b",
        "card_vulnerable_enemies",
        "cards_played_attack_card",
        "ignore_damage_increase_attack_card",
        "set_hand_energy_card",
        "transform_hand_card",
    },
    "colored": {
        "card_by_accident",
        "card_hasty_sorting",
        "card_quick_search",
        "card_something_fell_out",
        "card_distorted_note",
        "card_echo_shield",
        "card_finale_burst",
        "card_first_beat",
        "card_tuning",
        "card_last_item",
        "card_old_item_reuse",
        "card_sports_drink",
        "card_sprint_start",
        "card_travel_light",
        "card_warmup",
    },
    "team": {
        "add_health_card",
        "card_shove",
        "custom_block_card",
        "end_turn_card",
        "attack_increase_cost_on_damage_taken_card",
        "card_energy_on_discard",
        "improving_retain_block_card",
        "upgrade_entire_deck_card",
    },
}

EXCLUDED_DEVELOPMENT_CARDS = {"card_debug_log", "card_restart_combat"}

KEY_COLOR_BY_COLOR = {
    "color_red": "#00ff00",
    "color_blue": "#ff00ff",
    "color_green": "#ff00ff",
    "color_orange": "#0055ff",
    "color_white": "#ff00ff",
    "color_purple": "#ff00ff",
}
KEY_COLOR_OVERRIDES = {
    "variable_cost_attack_card": "#ffff00",
    "custom_block_card": "#ffff00",
    "attack_increase_cost_on_damage_taken_card": "#00ff00",
}


def load_manifest() -> dict:
    assert MANIFEST.exists(), "missing card art individualization manifest"
    with MANIFEST.open(encoding="utf-8") as handle:
        return json.load(handle)


def csv_cards() -> dict[str, dict[str, str]]:
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        return {
            row["object_id"]: row
            for row in csv.DictReader(handle)
            if row.get("object_id") and not row["object_id"].startswith("#")
        }


def xlsx_cards() -> dict[str, dict[str, str]]:
    workbook = load_workbook(XLSX_PATH, read_only=True, data_only=True)
    worksheet = workbook["Cards"]
    headers = [cell.value for cell in worksheet[1]]
    rows = {}
    for values in worksheet.iter_rows(min_row=2, values_only=True):
        row = dict(zip(headers, values))
        card_id = row.get("object_id")
        if card_id:
            rows[str(card_id)] = row
    workbook.close()
    return rows


def expected_art_path(card_id: str, cards: dict[str, dict[str, str]]) -> str:
    color_folder = cards[card_id]["card_color_id"].removeprefix("color_")
    return f"external/sprites/cards/{color_folder}/{card_id}.png"


def validate_card_configs(card_ids: list[str]) -> None:
    cards = csv_cards()
    workbook_cards = xlsx_cards()
    for card_id in card_ids:
        assert card_id in cards, f"missing card in cards.csv: {card_id}"
        assert card_id in workbook_cards, f"missing card in cards.xlsx: {card_id}"
        assert (workbook_cards[card_id].get("card_texture_path") or "") == cards[card_id]["card_texture_path"], (
            f"card_texture_path mismatch: {card_id}"
        )
        assert expected_art_path(card_id, cards).startswith("external/sprites/cards/")


def rgb_from_hex(value: str) -> tuple[int, int, int]:
    stripped = value.removeprefix("#")
    assert len(stripped) == 6, f"invalid RGB color: {value}"
    return tuple(int(stripped[index:index + 2], 16) for index in (0, 2, 4))


def validate_card_art(card_id: str, cards: dict[str, dict[str, str]]) -> None:
    expected_path = expected_art_path(card_id, cards)
    assert cards[card_id]["card_texture_path"] == expected_path, (
        f"unexpected cards.csv art path for {card_id}: "
        f"{cards[card_id]['card_texture_path']}"
    )

    workbook_cards = xlsx_cards()
    assert (workbook_cards[card_id].get("card_texture_path") or "") == expected_path, (
        f"unexpected cards.xlsx art path for {card_id}: "
        f"{workbook_cards[card_id].get('card_texture_path')}"
    )

    image_path = ROOT / expected_path
    assert image_path.exists(), f"missing individual card art: {expected_path}"
    with Image.open(image_path) as image:
        assert image.size == (512, 512), f"unexpected image size for {card_id}: {image.size}"
        assert image.mode == "RGBA", f"unexpected image mode for {card_id}: {image.mode}"
        alpha_extrema = image.getextrema()[3]
        assert alpha_extrema[0] == 0, f"image is not transparent for {card_id}"
        assert alpha_extrema[1] == 255, f"image has no opaque pixels for {card_id}"
        for corner in ((0, 0), (511, 0), (0, 511), (511, 511)):
            assert image.getpixel(corner)[3] <= 16, (
                f"opaque corner {corner} for {card_id}"
            )

        key_hex = KEY_COLOR_OVERRIDES.get(
            card_id,
            KEY_COLOR_BY_COLOR[cards[card_id]["card_color_id"]],
        )
        key_rgb = rgb_from_hex(key_hex)
        fringe_pixels = 0
        for red, green, blue, alpha in image.getdata():
            if 0 < alpha < 255 and max(
                abs(red - key_rgb[0]),
                abs(green - key_rgb[1]),
                abs(blue - key_rgb[2]),
            ) <= 32:
                fringe_pixels += 1
        assert fringe_pixels < 64, (
            f"chroma fringe detected for {card_id}: "
            f"{fringe_pixels} pixels near {key_hex}"
        )


def validate_manifest() -> None:
    assert sum(map(len, EXPECTED_PHASES.values())) == 50
    assert not set.union(*EXPECTED_PHASES.values()) & EXCLUDED_DEVELOPMENT_CARDS

    manifest = load_manifest()
    assert set(manifest["phases"]) == set(EXPECTED_PHASES)
    assert set(manifest["excluded_development_cards"]) == EXCLUDED_DEVELOPMENT_CARDS

    phase_ids = [card_id for phase in manifest["phases"].values() for card_id in phase]
    assert len(phase_ids) == 50
    assert len(set(phase_ids)) == 50
    for phase_name, expected_ids in EXPECTED_PHASES.items():
        assert set(manifest["phases"][phase_name]) == expected_ids

    validate_card_configs(phase_ids)


def validate_phase(phase_name: str) -> None:
    assert phase_name in EXPECTED_PHASES, f"unknown phase: {phase_name}"
    manifest = load_manifest()
    phase_ids = manifest["phases"][phase_name]
    assert set(phase_ids) == EXPECTED_PHASES[phase_name]
    validate_card_configs(phase_ids)
    cards = csv_cards()
    for card_id in phase_ids:
        validate_card_art(card_id, cards)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("manifest", *EXPECTED_PHASES))
    args = parser.parse_args()
    if args.phase == "manifest":
        validate_manifest()
        print("MANIFEST_VALIDATED: 50 cards")
    elif args.phase:
        validate_phase(args.phase)
        print(f"PHASE_VALIDATED: {args.phase}")
    else:
        validate_manifest()
        print("MANIFEST_VALIDATED: 50 cards")


if __name__ == "__main__":
    main()

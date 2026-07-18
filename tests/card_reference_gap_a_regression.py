#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"
EXCEL_TO_JSON = ROOT / "external" / "tools" / "excel_to_json.py"
JSON_TO_EXCEL = ROOT / "external" / "tools" / "json_to_excel.py"
SCRIPTS = ROOT / "autoload" / "Scripts.gd"

ACTION_PATH = "res://scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd"
VALIDATOR_PATH = "res://scripts/validators/card_plays/ValidatorPreviousCard.gd"


def load_card(card_id: str) -> dict:
    with (CARDS / f"{card_id}.json").open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


def walk(value):
    if isinstance(value, dict):
        for key, child in value.items():
            yield key, child
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def assert_path_exists(res_path: str) -> None:
    assert (ROOT / res_path.replace("res://", "")).exists(), res_path


def csv_ids() -> list[str]:
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        return [row["object_id"] for row in csv.DictReader(handle) if row.get("object_id")]


def main() -> None:
    assert_path_exists(ACTION_PATH)
    assert_path_exists(VALIDATOR_PATH)

    scripts_text = SCRIPTS.read_text(encoding="utf-8")
    assert "ACTION_TARGET_STATUS_VALUE_MODIFIER" in scripts_text
    assert "VALIDATOR_PREVIOUS_CARD" in scripts_text

    pursuit = load_card("card_pursuit")
    assert any(key == VALIDATOR_PATH for key, _ in walk(pursuit["card_play_actions"]))
    assert "draw_count" in pursuit["card_values"]

    echo_shield = load_card("card_echo_shield")
    assert any(key == VALIDATOR_PATH for key, _ in walk(echo_shield["card_play_actions"]))
    assert "bonus_block" in echo_shield["card_values"]

    finale_burst = load_card("card_finale_burst")
    action_payloads = [child for key, child in walk(finale_burst["card_play_actions"]) if key == ACTION_PATH]
    assert len(action_payloads) == 1
    payload = action_payloads[0]
    assert payload["status_effect_object_id"] == "status_effect_corrosion"
    assert payload["charge_key"] == "status_charges"
    assert payload["value_key"] == "damage"
    assert payload["operation"] == "add"

    excel_to_json_text = EXCEL_TO_JSON.read_text(encoding="utf-8")
    json_to_excel_text = JSON_TO_EXCEL.read_text(encoding="utf-8")
    for column in (
        "card_values_json",
        "card_play_actions_json",
        "card_draw_actions_json",
        "card_discard_actions_json",
        "card_retain_actions_json",
        "card_listeners_json",
    ):
        assert column in excel_to_json_text
        assert column in json_to_excel_text

    ids = csv_ids()
    for card_id in ("card_pursuit", "card_echo_shield", "card_finale_burst"):
        assert ids.count(card_id) == 1, f"{card_id} should appear once in cards.csv"

    print("validated card reference gap A")


if __name__ == "__main__":
    main()

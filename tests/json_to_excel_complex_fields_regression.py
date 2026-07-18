#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_TO_EXCEL = ROOT / "external" / "tools" / "json_to_excel.py"


def load_converter_module():
    spec = importlib.util.spec_from_file_location("json_to_excel", JSON_TO_EXCEL)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_card_complex_json_columns_are_populated():
    module = load_converter_module()
    row = {}
    card = {
        "card_values": {"draw_count": 1, "nested": {"value": 3}},
        "card_play_actions": [
            {
                "res://scripts/actions/pick_card_actions/ActionPickCards.gd": {
                    "action_data": [
                        {"res://scripts/actions/cardset_actions/ActionAddCardsToHand.gd": {}}
                    ],
                    "actions_on_lethal": [],
                }
            }
        ],
        "card_draw_actions": [
            {"res://scripts/actions/ActionAddEnergy.gd": {"energy_amount": 1}}
        ],
        "card_discard_actions": [
            {"res://scripts/actions/ActionAddEnergy.gd": {"energy_amount": 2}}
        ],
        "card_retain_actions": [
            {"res://scripts/actions/cardset_actions/ActionImproveCardValues.gd": {"block": 2}}
        ],
        "card_listeners": [
            {"res://scripts/card_listeners/ListenerCardCostModifier.gd": {"event_name": "card_damaged"}}
        ],
    }

    module.populate_card_complex_json_fields(card, row)

    assert json.loads(row["card_values_json"]) == card["card_values"]
    assert json.loads(row["card_play_actions_json"]) == card["card_play_actions"]
    assert json.loads(row["card_draw_actions_json"]) == card["card_draw_actions"]
    assert json.loads(row["card_discard_actions_json"]) == card["card_discard_actions"]
    assert json.loads(row["card_retain_actions_json"]) == card["card_retain_actions"]
    assert json.loads(row["card_listeners_json"]) == card["card_listeners"]


def test_blank_card_complex_fields_export_as_empty_strings():
    module = load_converter_module()
    row = {}
    module.populate_card_complex_json_fields({}, row)

    for column_name in [
        "card_values_json",
        "card_play_actions_json",
        "card_draw_actions_json",
        "card_discard_actions_json",
        "card_retain_actions_json",
        "card_listeners_json",
    ]:
        assert row[column_name] == ""


def main() -> None:
    test_card_complex_json_columns_are_populated()
    test_blank_card_complex_fields_export_as_empty_strings()
    print("validated json_to_excel complex field support")


if __name__ == "__main__":
    main()

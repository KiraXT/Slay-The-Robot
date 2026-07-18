#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
EXCEL_TO_JSON = ROOT / "external" / "tools" / "excel_to_json.py"
CARDS_XLSX = ROOT / "external" / "config" / "cards.xlsx"
REAL_CARD_COMPLEX_FIELDS = {
    "card_something_fell_out": ["card_values", "card_discard_actions"],
    "card_sports_drink": ["card_values", "card_play_actions", "card_draw_actions"],
    "card_warmup": ["card_values", "card_play_actions", "card_retain_actions"],
    "card_quick_search": ["card_values", "card_play_actions"],
}
FIELD_TO_COMPLEX_COLUMN = {
    "card_values": "card_values_json",
    "card_play_actions": "card_play_actions_json",
    "card_draw_actions": "card_draw_actions_json",
    "card_discard_actions": "card_discard_actions_json",
    "card_retain_actions": "card_retain_actions_json",
    "card_listeners": "card_listeners_json",
}


def load_converter_module():
    spec = importlib.util.spec_from_file_location("excel_to_json", EXCEL_TO_JSON)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def make_base_row(**overrides) -> pd.Series:
    data = {
        "object_id": "test_complex_card",
        "card_name": "Complex Card",
        "card_description": "Draw [draw_count] and keep nested actions",
        "card_type": 1,
        "card_rarity": 1,
        "card_color_id": "color_blue",
        "card_energy_cost": 1,
        "card_energy_cost_is_variable": False,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": False,
        "card_exhausts": False,
        "card_is_ethereal": False,
        "card_is_retained": False,
        "card_appears_in_card_packs": True,
        "card_texture_path": "external/sprites/cards/blue/card_blue.png",
        "card_keyword_object_ids": "",
        "draw_count": 99,
        "action_type": "ActionBlock",
        "action_time_delay": 0.5,
        "card_upgrade_amount_max": 1,
        "card_values_json": json.dumps({"draw_count": 2, "custom_nested": {"value": 7}}),
        "card_play_actions_json": json.dumps([
            {
                "res://scripts/actions/pick_card_actions/ActionPickCards.gd": {
                    "min_card_amount": 1,
                    "max_card_amount": 1,
                    "action_data": [
                        {"res://scripts/actions/cardset_actions/ActionAddCardsToHand.gd": {}},
                        {
                            "res://scripts/actions/cardset_actions/ActionChangeCardEnergies.gd": {
                                "card_energy_cost_until_turn": 0,
                            }
                        },
                    ],
                    "actions_on_lethal": [],
                }
            }
        ]),
        "card_draw_actions_json": json.dumps([
            {"res://scripts/actions/ActionAddEnergy.gd": {"energy_amount": 1, "actions_on_lethal": []}}
        ]),
        "card_discard_actions_json": json.dumps([
            {"res://scripts/actions/ActionAddEnergy.gd": {"energy_amount": 2, "actions_on_lethal": []}}
        ]),
        "card_retain_actions_json": json.dumps([
            {
                "res://scripts/actions/cardset_actions/ActionImproveCardValues.gd": {
                    "pick_played_card": True,
                    "card_value_improvements": {"block": 2},
                }
            }
        ]),
        "card_listeners_json": json.dumps([
            {
                "res://scripts/card_listeners/ListenerCardCostModifier.gd": {
                    "event_name": "card_damaged",
                    "card_energy_cost_change": 1,
                }
            }
        ]),
    }
    data.update(overrides)
    return pd.Series(data)


def test_complex_json_columns_override_simple_columns():
    module = load_converter_module()
    converter = module.CardConverter()
    card_json = converter._build_card_json(make_base_row())
    properties = card_json["properties"]

    assert properties["card_values"] == {"draw_count": 2, "custom_nested": {"value": 7}}
    assert list(properties["card_play_actions"][0].keys()) == [
        "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
    ]
    assert properties["card_play_actions"][0]["res://scripts/actions/pick_card_actions/ActionPickCards.gd"]["action_data"][1][
        "res://scripts/actions/cardset_actions/ActionChangeCardEnergies.gd"
    ]["card_energy_cost_until_turn"] == 0
    assert list(properties["card_draw_actions"][0].keys()) == ["res://scripts/actions/ActionAddEnergy.gd"]
    assert list(properties["card_discard_actions"][0].keys()) == ["res://scripts/actions/ActionAddEnergy.gd"]
    assert list(properties["card_retain_actions"][0].keys()) == [
        "res://scripts/actions/cardset_actions/ActionImproveCardValues.gd"
    ]
    assert list(properties["card_listeners"][0].keys()) == [
        "res://scripts/card_listeners/ListenerCardCostModifier.gd"
    ]


def test_blank_complex_columns_keep_legacy_action_generation():
    module = load_converter_module()
    converter = module.CardConverter()
    row = make_base_row(
        card_values_json="",
        card_play_actions_json="",
        card_draw_actions_json="",
        card_discard_actions_json="",
        card_retain_actions_json="",
        card_listeners_json="",
    )
    properties = converter._build_card_json(row)["properties"]

    assert properties["card_values"]["draw_count"] == 99
    assert list(properties["card_play_actions"][0].keys()) == ["res://scripts/actions/ActionBlock.gd"]
    assert "card_draw_actions" not in properties
    assert "card_discard_actions" not in properties
    assert "card_retain_actions" not in properties
    assert "card_listeners" not in properties


def test_action_validator_previous_card_type_uses_card_play_validator_path():
    module = load_converter_module()
    converter = module.CardConverter()
    row = make_base_row(
        card_play_actions_json="",
        action_type="ActionValidator",
        validator_type="ValidatorPreviousCardType",
    )
    properties = converter._build_card_json(row)["properties"]
    validator_data = properties["card_play_actions"][0]["res://scripts/actions/meta_actions/ActionValidator.gd"]["validator_data"]

    assert list(validator_data[0].keys()) == [
        "res://scripts/validators/card_plays/ValidatorPreviousCardType.gd"
    ]


def test_invalid_complex_json_is_validation_error():
    module = load_converter_module()
    row = make_base_row(card_play_actions_json="{not valid json")
    errors = module.CardValidator().validate_card(row)

    matching_errors = [
        error
        for error in errors
        if error.field == "card_play_actions_json" and error.severity == "ERROR"
    ]
    assert matching_errors, "invalid complex JSON text must be rejected before conversion"


def test_real_workbook_complex_rows_match_current_json():
    module = load_converter_module()
    converter = module.CardConverter()
    workbook = pd.read_excel(CARDS_XLSX, sheet_name="Cards")

    for card_id, field_names in REAL_CARD_COMPLEX_FIELDS.items():
        rows = workbook[workbook["object_id"] == card_id]
        assert len(rows) == 1, f"{card_id} must exist once in cards.xlsx"
        row = rows.iloc[0]
        converted = converter._build_card_json(row)["properties"]
        for field_name in field_names:
            column_name = FIELD_TO_COMPLEX_COLUMN[field_name]
            expected = json.loads(str(row[column_name]))
            assert converted.get(field_name) == expected, (
                f"{card_id} {field_name} must round-trip from cards.xlsx complex JSON columns"
            )


def main() -> None:
    test_complex_json_columns_override_simple_columns()
    test_blank_complex_columns_keep_legacy_action_generation()
    test_action_validator_previous_card_type_uses_card_play_validator_path()
    test_invalid_complex_json_is_validation_error()
    test_real_workbook_complex_rows_match_current_json()
    print("validated excel_to_json complex field support")


if __name__ == "__main__":
    main()

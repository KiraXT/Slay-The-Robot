#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
STATUSES = ROOT / "external" / "data" / "status_effects"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"

STATUS_SCRIPT = "res://scripts/status_effects/StatusEffectNextMatchingCardModifier.gd"
APPLY_STATUS_ACTION = "res://scripts/actions/status_actions/ActionApplyStatus.gd"
BASE_COMBATANT = ROOT / "scripts" / "combatants" / "BaseCombatant.gd"
BASE_STATUS_EFFECT = ROOT / "scripts" / "status_effects" / "BaseStatusEffect.gd"


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


def load_card(card_id: str) -> dict:
    return load_json(CARDS / f"{card_id}.json")


def load_status(status_id: str) -> dict:
    return load_json(STATUSES / f"{status_id}.json")


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


def find_action_payload(card: dict, action_path: str) -> list[dict]:
    return [child for key, child in walk(card.get("card_play_actions", [])) if key == action_path]


def csv_ids() -> list[str]:
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        return [row["object_id"] for row in csv.DictReader(handle) if row.get("object_id")]


def main() -> None:
    assert_path_exists(STATUS_SCRIPT)

    status_script_text = (ROOT / STATUS_SCRIPT.replace("res://", "")).read_text(encoding="utf-8")
    for expected in (
        "Signals.card_play_started.connect(_on_card_play_started)",
        "Signals.player_turn_ended.connect(_on_player_turn_ended)",
        "card_type_filter",
        "value_modifiers",
        "consume_charge_on_trigger",
        "clear_on_player_turn_end",
        "ignore_duplicate_plays",
        "_disconnect_signals",
        "value_modifier_queue",
        "on_status_reapplied",
    ):
        assert expected in status_script_text

    apply_status_text = (ROOT / APPLY_STATUS_ACTION.replace("res://", "")).read_text(encoding="utf-8")
    assert "add_status_effect_charges(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)" in apply_status_text

    base_combatant_text = BASE_COMBATANT.read_text(encoding="utf-8")
    assert "func add_status_effect_charges(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0, custom_values: Dictionary = {})" in base_combatant_text
    assert "_create_status_effect(status_effect_object_id, custom_values)" in base_combatant_text
    assert "status_effect_script.on_status_reapplied(charge_amount, secondary_charge_amount, custom_values)" in base_combatant_text
    assert "status_effect.status_effect_script.on_status_removed()" in base_combatant_text

    base_status_effect_text = BASE_STATUS_EFFECT.read_text(encoding="utf-8")
    assert "func on_status_removed() -> void:" in base_status_effect_text
    assert "func on_status_reapplied(_charge_amount: int, _secondary_charge_amount: int, _custom_values: Dictionary) -> void:" in base_status_effect_text

    combo_status = load_status("status_effect_combo_starter")
    assert combo_status["status_effect_script_path"] == STATUS_SCRIPT
    assert combo_status["status_effect_stacks"] is True
    assert combo_status["status_effect_allows_multiples"] is False
    assert combo_status["status_effect_decay_rate"] == 0
    assert combo_status["status_effect_texture_path"] == ""

    combo = load_card("card_combo_starter")
    assert combo["card_name"] == "连段起手"
    assert combo["card_type"] == 1
    assert combo["card_color_id"] == "color_red"
    assert combo["card_energy_cost"] == 1
    assert combo["card_requires_target"] is False
    assert combo["card_values"]["damage"] == 3
    assert combo["card_upgrade_value_improvements"]["damage"] == 2

    payloads = find_action_payload(combo, APPLY_STATUS_ACTION)
    assert len(payloads) == 1
    values = payloads[0]
    assert values["target_override"] == 2
    assert values["status_effect_object_id"] == "status_effect_combo_starter"
    assert values["status_charge_amount"] == 1
    assert values.get("status_force_apply_new_effect", False) is False

    custom = values["status_custom_values"]
    assert custom["card_type_filter"] == [0]
    assert custom["value_modifiers"] == {"damage": 3}
    assert custom["consume_charge_on_trigger"] is True
    assert custom["clear_on_player_turn_end"] is True
    assert custom["ignore_duplicate_plays"] is True

    upgrade_changes = combo["card_first_upgrade_property_changes"]
    assert "card_play_actions" in upgrade_changes
    upgraded_payloads = [
        child
        for key, child in walk(upgrade_changes["card_play_actions"])
        if key == APPLY_STATUS_ACTION
    ]
    assert len(upgraded_payloads) == 1
    upgraded_custom = upgraded_payloads[0]["status_custom_values"]
    assert upgraded_custom["value_modifiers"] == {"damage": 5}

    assert csv_ids().count("card_combo_starter") == 1

    print("validated card reference gap C")


if __name__ == "__main__":
    main()

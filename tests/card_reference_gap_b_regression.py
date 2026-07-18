#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
STATUSES = ROOT / "external" / "data" / "status_effects"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"
SCRIPTS = ROOT / "autoload" / "Scripts.gd"
BASE_COMBATANT = ROOT / "scripts" / "combatants" / "BaseCombatant.gd"

STATUS_SCRIPT = "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd"
MODIFY_VALUES_ACTION = "res://scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd"
APPLY_STATUS_ACTION = "res://scripts/actions/status_actions/ActionApplyStatus.gd"
ADD_ENERGY_ACTION = "res://scripts/actions/ActionAddEnergy.gd"
VARIABLE_STATS_ACTION = "res://scripts/actions/meta_actions/ActionVariableCombatStatsModifier.gd"


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
    assert_path_exists(MODIFY_VALUES_ACTION)

    scripts_text = SCRIPTS.read_text(encoding="utf-8")
    assert "ACTION_MODIFY_CURRENT_CARD_PLAY_VALUES" in scripts_text

    apply_status_text = (ROOT / APPLY_STATUS_ACTION.replace("res://", "")).read_text(encoding="utf-8")
    assert "status_custom_values" in apply_status_text
    assert "add_new_status_effect(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)" in apply_status_text

    base_combatant_text = BASE_COMBATANT.read_text(encoding="utf-8")
    assert "_create_status_effect(status_effect_object_id, custom_values)" in base_combatant_text
    assert "status_effect_script.status_custom_values = custom_values" in base_combatant_text

    metronome_status = load_status("status_effect_metronome")
    assert metronome_status["status_effect_script_path"] == STATUS_SCRIPT
    assert metronome_status["status_effect_allows_multiples"] is True

    travel_light_status = load_status("status_effect_travel_light")
    assert travel_light_status["status_effect_script_path"] == STATUS_SCRIPT
    assert travel_light_status["status_effect_allows_multiples"] is True

    metronome = load_card("card_metronome")
    metronome_payloads = find_action_payload(metronome, APPLY_STATUS_ACTION)
    assert len(metronome_payloads) == 1
    metronome_values = metronome_payloads[0]
    assert metronome_values["status_effect_object_id"] == "status_effect_metronome"
    assert metronome_values["status_force_apply_new_effect"] is True
    metronome_custom = metronome_values["status_custom_values"]
    assert metronome_custom["trigger_signal"] == "card_play_started"
    assert metronome_custom["max_triggers_per_turn"] == 1
    assert metronome_custom["card_type_filter"] == [0, 1]
    assert any(key == MODIFY_VALUES_ACTION for key, _ in walk(metronome_custom["action_data"]))

    travel_light = load_card("card_travel_light")
    travel_payloads = find_action_payload(travel_light, APPLY_STATUS_ACTION)
    assert len(travel_payloads) == 1
    travel_values = travel_payloads[0]
    assert travel_values["status_effect_object_id"] == "status_effect_travel_light"
    assert travel_values["status_force_apply_new_effect"] is True
    travel_custom = travel_values["status_custom_values"]
    assert travel_custom["trigger_signal"] == "card_exhausted"
    assert travel_custom["max_triggers_per_turn"] == 1
    assert any(key == ADD_ENERGY_ACTION for key, _ in walk(travel_custom["action_data"]))

    last_item = load_card("card_last_item")
    last_item_payloads = find_action_payload(last_item, VARIABLE_STATS_ACTION)
    assert len(last_item_payloads) == 1
    assert last_item_payloads[0]["stat_enum"] == 14
    assert last_item_payloads[0]["is_total_stat"] is True

    ids = csv_ids()
    for card_id in ("card_metronome", "card_travel_light", "card_last_item"):
        assert ids.count(card_id) == 1, f"{card_id} should appear once in cards.csv"

    print("validated card reference gap B")


if __name__ == "__main__":
    main()

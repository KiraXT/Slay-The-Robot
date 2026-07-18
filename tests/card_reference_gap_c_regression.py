#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
STATUSES = ROOT / "external" / "data" / "status_effects"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"
SCRIPTS = ROOT / "autoload" / "Scripts.gd"
EXCEL_TO_JSON = ROOT / "external" / "tools" / "excel_to_json.py"

ACTION_APPLY_STATUS = "res://scripts/actions/status_actions/ActionApplyStatus.gd"
ACTION_TAG_CARDS = "res://scripts/actions/cardset_actions/ActionTagCards.gd"
ACTION_RETAIN_CARDS = "res://scripts/actions/cardset_actions/ActionRetainCards.gd"
ACTION_ADD_CARDS_TO_DRAW = "res://scripts/actions/cardset_actions/ActionAddCardsToDraw.gd"
ACTION_CHANGE_CARD_ENERGIES = "res://scripts/actions/cardset_actions/ActionChangeCardEnergies.gd"
ACTION_MODIFY_CURRENT_VALUES = "res://scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd"
ACTION_DUPLICATE_CURRENT_PLAY = "res://scripts/actions/meta_actions/ActionDuplicateCurrentCardPlay.gd"
ACTION_ADD_ENERGY = "res://scripts/actions/ActionAddEnergy.gd"
TAGGED_TRIGGER_SCRIPT = "res://scripts/status_effects/StatusEffectTaggedCardTrigger.gd"
ONCE_PER_TURN_SCRIPT = "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd"
VALIDATOR_CARD_TYPE = "res://scripts/validators/card/ValidatorCardType.gd"

EXPECTED_CARDS = {
    "card_combo_starter": "color_red",
    "card_chorus": "color_green",
    "card_bookmark_clip": "color_orange",
    "card_pack_sorting": "color_orange",
    "card_ready_stance": "color_orange",
}

EXPECTED_STATUSES = {
    "status_effect_combo_starter": ONCE_PER_TURN_SCRIPT,
    "status_effect_chorus": ONCE_PER_TURN_SCRIPT,
    "status_effect_bookmark_clip": TAGGED_TRIGGER_SCRIPT,
    "status_effect_pack_sorting": TAGGED_TRIGGER_SCRIPT,
    "status_effect_ready_stance": TAGGED_TRIGGER_SCRIPT,
}


def load_properties(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


def load_card(card_id: str) -> dict:
    return load_properties(CARDS / f"{card_id}.json")


def load_status(status_id: str) -> dict:
    return load_properties(STATUSES / f"{status_id}.json")


def walk(value):
    if isinstance(value, dict):
        for key, child in value.items():
            yield key, child
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def find_action_payload(source: dict, action_path: str) -> list[dict]:
    return [child for key, child in walk(source.get("card_play_actions", [])) if key == action_path]


def assert_res_path_exists(res_path: str) -> None:
    assert (ROOT / res_path.replace("res://", "")).exists(), res_path


def csv_ids() -> list[str]:
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        return [row["object_id"] for row in csv.DictReader(handle) if row.get("object_id")]


def assert_status_payload(card: dict, status_id: str) -> dict:
    payloads = find_action_payload(card, ACTION_APPLY_STATUS)
    matching = [
        payload
        for payload in payloads
        if payload.get("status_effect_object_id") == status_id
    ]
    assert len(matching) == 1, f"{card['object_id']} should apply {status_id} once"
    custom_values = matching[0].get("status_custom_values", {})
    assert isinstance(custom_values, dict), f"{status_id} should be configured through status_custom_values"
    return custom_values


def main() -> None:
    assert_res_path_exists(ACTION_TAG_CARDS)
    assert_res_path_exists(ACTION_DUPLICATE_CURRENT_PLAY)
    assert_res_path_exists(TAGGED_TRIGGER_SCRIPT)

    scripts_text = SCRIPTS.read_text(encoding="utf-8")
    assert "ACTION_TAG_CARDS" in scripts_text
    assert "ACTION_DUPLICATE_CURRENT_CARD_PLAY" in scripts_text

    converter_text = EXCEL_TO_JSON.read_text(encoding="utf-8")
    for action_name in ("ActionTagCards", "ActionDuplicateCurrentCardPlay"):
        assert action_name in converter_text, f"Excel converter must know {action_name}"

    for status_id, script_path in EXPECTED_STATUSES.items():
        assert_res_path_exists(script_path)
        status = load_status(status_id)
        assert status["status_effect_script_path"] == script_path
        assert status["status_effect_stacks"] is True

    for card_id, color_id in EXPECTED_CARDS.items():
        card = load_card(card_id)
        assert card["object_id"] == card_id
        assert card["card_color_id"] == color_id
        assert card["card_appears_in_card_packs"] is True
        assert card["card_texture_path"], f"{card_id} should have art"

    combo = load_card("card_combo_starter")
    combo_custom = assert_status_payload(combo, "status_effect_combo_starter")
    assert combo_custom["trigger_signal"] == "card_play_started"
    assert combo_custom["card_type_filter"] == [0]
    assert combo_custom["consume_charge_on_trigger"] is True
    assert combo_custom["expire_on_player_turn_ended"] is True
    assert any(key == ACTION_MODIFY_CURRENT_VALUES for key, _ in walk(combo_custom["action_data"]))

    chorus = load_card("card_chorus")
    chorus_custom = assert_status_payload(chorus, "status_effect_chorus")
    assert chorus["card_type"] == 2
    assert chorus_custom["trigger_signal"] == "card_play_started"
    assert chorus_custom["card_type_filter"] == [0, 1]
    assert any(key == ACTION_DUPLICATE_CURRENT_PLAY for key, _ in walk(chorus_custom["action_data"]))

    bookmark = load_card("card_bookmark_clip")
    bookmark_custom = assert_status_payload(bookmark, "status_effect_bookmark_clip")
    assert any(key == ACTION_TAG_CARDS for key, _ in walk(bookmark["card_play_actions"]))
    assert any(key == ACTION_RETAIN_CARDS for key, _ in walk(bookmark["card_play_actions"]))
    assert bookmark_custom["trigger_signal"] == "player_turn_started"
    assert bookmark_custom["card_tags"] == ["tag_bookmark_clip"]
    assert bookmark_custom["arm_on_next_player_turn"] is True
    assert any(key == ACTION_CHANGE_CARD_ENERGIES for key, _ in walk(bookmark_custom["action_data"]))

    pack_sorting = load_card("card_pack_sorting")
    pack_custom = assert_status_payload(pack_sorting, "status_effect_pack_sorting")
    assert any(key == ACTION_TAG_CARDS for key, _ in walk(pack_sorting["card_play_actions"]))
    assert any(key == ACTION_ADD_CARDS_TO_DRAW for key, _ in walk(pack_sorting["card_play_actions"]))
    assert pack_custom["trigger_signal"] == "card_drawn"
    assert pack_custom["card_tags"] == ["tag_pack_sorting"]
    assert pack_custom["consume_charge_on_trigger"] is True
    assert any(key == ACTION_ADD_ENERGY for key, _ in walk(pack_custom["action_data"]))

    ready = load_card("card_ready_stance")
    ready_custom = assert_status_payload(ready, "status_effect_ready_stance")
    assert any(key == ACTION_TAG_CARDS for key, _ in walk(ready["card_play_actions"]))
    assert any(key == ACTION_RETAIN_CARDS for key, _ in walk(ready["card_play_actions"]))
    assert any(key == VALIDATOR_CARD_TYPE for key, _ in walk(ready["card_play_actions"]))
    assert ready_custom["trigger_signal"] == "card_play_started"
    assert ready_custom["card_tags"] == ["tag_ready_stance"]
    assert ready_custom["card_type_filter"] == [0]
    assert ready_custom["arm_on_next_player_turn"] is True
    assert ready_custom["expire_on_player_turn_ended"] is True
    assert any(key == ACTION_MODIFY_CURRENT_VALUES for key, _ in walk(ready_custom["action_data"]))

    ids = csv_ids()
    for card_id in EXPECTED_CARDS:
        assert ids.count(card_id) == 1, f"{card_id} should appear once in cards.csv"

    print("validated card reference gap C")


if __name__ == "__main__":
    main()

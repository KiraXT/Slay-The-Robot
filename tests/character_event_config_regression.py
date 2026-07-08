#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENTS = ROOT / "external" / "data" / "events"
EVENT_POOLS = ROOT / "external" / "data" / "event_pools"
VALIDATOR_CHARACTER = "res://scripts/validators/ValidatorCharacter.gd"

EXPECTED_EVENTS = {
    "event_red_broken_boxing_ring": "character_red",
    "event_red_warning_line_gate": "character_red",
    "event_blue_scattered_toolbox": "character_blue",
    "event_blue_runaway_shuffler": "character_blue",
    "event_green_echo_tuning_room": "character_green",
    "event_green_corrosion_tank": "character_green",
    "event_orange_prep_supply_stop": "character_orange",
    "event_orange_hidden_backpack_pocket": "character_orange",
}

EXPECTED_OPTION_COUNTS = {event_id: 3 for event_id in EXPECTED_EVENTS}

EXPECTED_OPTION_TEXT = {
    "event_red_broken_boxing_ring": ["重打基础", "压上步伐", "拆下护板"],
    "event_red_warning_line_gate": ["正面突破", "找准破绽", "暂时撤退"],
    "event_blue_scattered_toolbox": ["慌忙翻找", "留下备用品", "卖掉零件"],
    "event_blue_runaway_shuffler": ["接受重排", "抓住弹出的牌", "关掉机器"],
    "event_green_echo_tuning_room": ["跟上第一拍", "调整频率", "过载共鸣"],
    "event_green_corrosion_tank": ["提取试剂", "强化样本", "封存危险品"],
    "event_orange_prep_supply_stop": ["打包饮料", "轻装上阵", "多拿一点"],
    "event_orange_hidden_backpack_pocket": ["夹好书签", "翻出旧物", "卖掉纪念品"],
}


def load_properties(directory: Path, object_id: str) -> dict:
    path = directory / f"{object_id}.json"
    assert path.exists(), f"missing JSON for {object_id}: {path}"
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    properties = payload["properties"]
    assert properties["object_id"] == object_id
    return properties


def walk_script_paths(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.startswith("res://"):
                yield key
            yield from walk_script_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_script_paths(child)


def assert_script_paths_exist(event_id: str, event: dict) -> None:
    for script_path in walk_script_paths(event):
        local_path = ROOT / script_path.replace("res://", "")
        assert local_path.exists(), f"{event_id} references missing script {script_path}"


def assert_character_validator(event_id: str, event: dict, character_id: str) -> None:
    validators = event["event_pool_validator_data"]
    assert validators == [
        {
            VALIDATOR_CHARACTER: {
                "character_object_ids": [character_id],
            }
        }
    ], f"{event_id} should be filtered to {character_id}"


def assert_dialogue(event_id: str, event: dict) -> None:
    dialogue = event["event_dialogue_data"]
    assert dialogue is not None, f"{event_id} should embed dialogue data"
    initial_state_id = dialogue["dialogue_initial_dialogue_state_object_id"]
    states = dialogue["dialogue_state_id_to_dialogue_states"]
    options = dialogue["dialogue_option_id_to_dialogue_options"]
    assert initial_state_id in states, f"{event_id} initial state missing"
    state = states[initial_state_id]
    option_ids = state["dialogue_state_dialogue_option_object_ids"]
    assert len(option_ids) == EXPECTED_OPTION_COUNTS[event_id]
    assert state["dialogue_state_dialogue_texture_path"] == ""
    expected_texts = EXPECTED_OPTION_TEXT[event_id]
    for option_id, expected_text in zip(option_ids, expected_texts):
        assert option_id in options, f"{event_id} missing option {option_id}"
        option = options[option_id]
        assert option["dialogue_option_bbcode"].startswith(expected_text), (
            f"{event_id} option {option_id} should start with {expected_text}"
        )
        assert option["dialogue_option_visible_on_failed_validation"] is True


def main() -> None:
    for event_id, character_id in EXPECTED_EVENTS.items():
        event = load_properties(EVENTS, event_id)
        assert event["event_dialogue_object_id"] == ""
        assert event["event_weighted_enemy_object_ids"] == []
        assert event["event_initial_combat_actions"] == []
        assert event["location_event_pool_validator_failed_strategy"] == 1
        assert_character_validator(event_id, event, character_id)
        assert_dialogue(event_id, event)
        assert_script_paths_exist(event_id, event)

    pool = load_properties(EVENT_POOLS, "event_pool_act_1_dialogue")
    pool_events = pool["event_pool_event_object_ids"]
    assert pool["event_pool_fallback_event_object_id"] == "event_pick_something"
    assert "event_pick_something" in pool_events
    for event_id in EXPECTED_EVENTS:
        assert event_id in pool_events, f"dialogue pool should include {event_id}"

    print("validated character event configuration")


if __name__ == "__main__":
    main()

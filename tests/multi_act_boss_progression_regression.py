#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ACTS = ROOT / "external" / "data" / "acts"
EVENT_POOLS = ROOT / "external" / "data" / "event_pools"
EVENTS = ROOT / "external" / "data" / "events"
ENEMIES = ROOT / "external" / "data" / "enemies"

KNOWN_STATUS_IDS = {
    "status_effect_corrosion",
    "status_effect_damage_increase",
    "status_effect_negate_damage",
    "status_effect_negate_debuff",
    "status_effect_preserve_block",
    "status_effect_vulnerable",
    "status_effect_weaken",
}

EXPECTED_ACT_POOLS = {
    "act_2": {
        "act_easy_combat_event_pool_object_id": "event_pool_act_2_easy",
        "act_hard_combat_event_pool_object_id": "event_pool_act_2_hard",
        "act_miniboss_event_pool_object_id": "event_pool_act_2_miniboss",
        "act_boss_event_pool_object_id": "event_pool_act_2_boss",
        "act_next_act_ids": ["act_3"],
    },
    "act_3": {
        "act_easy_combat_event_pool_object_id": "event_pool_act_3_easy",
        "act_hard_combat_event_pool_object_id": "event_pool_act_3_hard",
        "act_miniboss_event_pool_object_id": "event_pool_act_3_miniboss",
        "act_boss_event_pool_object_id": "event_pool_act_3_boss",
        "act_next_act_ids": ["act_1"],
    },
}

EXPECTED_POOLS = {
    "event_pool_act_2_easy": [
        "event_act_2_easy_combat_scrap_pair",
        "event_act_2_easy_combat_barrier_lancer",
        "event_act_2_easy_combat_jammer_drone",
    ],
    "event_pool_act_2_hard": [
        "event_act_2_hard_combat_forge_line",
        "event_act_2_hard_combat_signal_wall",
        "event_act_2_hard_combat_lancer_pack",
    ],
    "event_pool_act_2_miniboss": [
        "event_act_2_miniboss_forge_guardian",
        "event_act_2_miniboss_relay_tower",
    ],
    "event_pool_act_2_boss": ["event_act_2_boss_foundry_heart"],
    "event_pool_act_3_easy": [
        "event_act_3_easy_combat_core_blade_pair",
        "event_act_3_easy_combat_null_priest_guard",
        "event_act_3_easy_combat_drone_screen",
    ],
    "event_pool_act_3_hard": [
        "event_act_3_hard_combat_null_wall",
        "event_act_3_hard_combat_core_phalanx",
        "event_act_3_hard_combat_orbital_crossfire",
    ],
    "event_pool_act_3_miniboss": [
        "event_act_3_miniboss_null_bastion",
        "event_act_3_miniboss_orbital_array",
    ],
    "event_pool_act_3_boss": ["event_act_3_boss_overmind_core"],
}

EXPECTED_BOSSES = {
    "enemy_act_1_boss_1": {"health": 200, "type": 2},
    "enemy_act_2_boss_foundry_heart": {"health": 260, "type": 2},
    "enemy_act_3_boss_overmind_core": {"health": 340, "type": 2},
}


def load_properties(directory: Path, object_id: str) -> dict:
    path = directory / f"{object_id}.json"
    assert path.exists(), f"missing JSON for {object_id}: {path}"
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    properties = payload["properties"]
    assert properties["object_id"] == object_id
    return properties


def referenced_enemy_ids(event: dict) -> set[str]:
    enemy_ids = set()
    for slot_weights in event["event_weighted_enemy_object_ids"]:
        enemy_ids.update(slot_weights.keys())
    return enemy_ids


def walk_action_values(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.startswith("res://"):
                yield key, child
            yield from walk_action_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_action_values(child)


def assert_attack_graph_is_closed(enemy_id: str, enemy: dict) -> None:
    states = enemy["enemy_attack_states"]
    assert "initial" in states, f"{enemy_id} must include initial attack state"
    for state_id, state in states.items():
        weights = state.get("next_attack_weights", {})
        assert weights, f"{enemy_id}:{state_id} must define next attack weights"
        for next_state_id in weights:
            assert next_state_id in states, f"{enemy_id}:{state_id} points to missing state {next_state_id}"

    reachable = set()
    stack = ["initial"]
    while stack:
        state_id = stack.pop()
        if state_id in reachable:
            continue
        reachable.add(state_id)
        stack.extend(states[state_id].get("next_attack_weights", {}).keys())

    unreachable = set(states) - reachable
    assert not unreachable, f"{enemy_id} has unreachable attack states: {sorted(unreachable)}"


def assert_enemy_actions_are_valid(enemy_id: str, enemy: dict) -> None:
    for script_path, values in walk_action_values(enemy):
        assert script_path.startswith("res://scripts/actions/"), script_path
        assert (ROOT / script_path.replace("res://", "")).exists(), f"missing action script: {script_path}"
        status_id = values.get("status_effect_object_id")
        if status_id is not None:
            assert status_id in KNOWN_STATUS_IDS, f"{enemy_id} references unknown status {status_id}"


def main() -> None:
    for act_id, expected in EXPECTED_ACT_POOLS.items():
        act = load_properties(ACTS, act_id)
        for key, expected_value in expected.items():
            assert act[key] == expected_value, f"{act_id}.{key} should be {expected_value!r}, got {act[key]!r}"

    for pool_id, expected_events in EXPECTED_POOLS.items():
        pool = load_properties(EVENT_POOLS, pool_id)
        assert pool["event_pool_event_object_ids"] == expected_events
        assert pool["event_pool_fallback_event_object_id"] == expected_events[0]
        assert not any(event_id.startswith("event_act_1_boss") for event_id in expected_events)

    event_enemy_ids = set()
    for pool_events in EXPECTED_POOLS.values():
        for event_id in pool_events:
            event = load_properties(EVENTS, event_id)
            enemy_ids = referenced_enemy_ids(event)
            assert enemy_ids, f"{event_id} must spawn at least one enemy"
            event_enemy_ids.update(enemy_ids)
            if "boss" in event_id or "miniboss_relay" in event_id or "orbital_array" in event_id:
                assert event["event_enemy_placement_is_automatic"] is False, f"{event_id} must use manual slots"
                assert len(event["event_enemy_placement_positions"]) >= 3, f"{event_id} must reserve summon slots"

    for enemy_id in sorted(event_enemy_ids | set(EXPECTED_BOSSES)):
        enemy = load_properties(ENEMIES, enemy_id)
        assert enemy["enemy_health"] > 0
        assert enemy["enemy_health_max"] >= enemy["enemy_health"]
        assert enemy["enemy_texture_path"], f"{enemy_id} must define a texture"
        assert (ROOT / enemy["enemy_texture_path"]).exists(), f"{enemy_id} texture missing: {enemy['enemy_texture_path']}"
        assert_attack_graph_is_closed(enemy_id, enemy)
        assert_enemy_actions_are_valid(enemy_id, enemy)

    act_1_boss = load_properties(ENEMIES, "enemy_act_1_boss_1")
    act_2_boss = load_properties(ENEMIES, "enemy_act_2_boss_foundry_heart")
    act_3_boss = load_properties(ENEMIES, "enemy_act_3_boss_overmind_core")
    assert act_1_boss["enemy_health"] < act_2_boss["enemy_health"] < act_3_boss["enemy_health"]
    assert act_2_boss["enemy_type"] == EXPECTED_BOSSES["enemy_act_2_boss_foundry_heart"]["type"]
    assert act_3_boss["enemy_type"] == EXPECTED_BOSSES["enemy_act_3_boss_overmind_core"]["type"]
    assert act_2_boss["enemy_texture_path"] == "external/sprites/enemies/enemy_act_1_boss_1.png"
    assert act_3_boss["enemy_texture_path"] == "external/sprites/enemies/enemy_act_1_boss_1.png"

    print("validated multi-act boss progression data")


if __name__ == "__main__":
    main()

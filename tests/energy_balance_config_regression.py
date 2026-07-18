#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
PLAYERS = ROOT / "external" / "data" / "player"

EXPECTED_PLAYER_ENERGY_MAX = 3

EXPECTED_CARD_VALUES = {
    "card_attack_basic": {
        "card_energy_cost": 1,
        "card_values": {"damage": 6, "number_of_attacks": 1},
        "card_upgrade_value_improvements": {"damage": 3},
    },
    "card_block_basic": {
        "card_energy_cost": 1,
        "card_values": {"block": 5},
        "card_upgrade_value_improvements": {"block": 3},
    },
    "attack_lower_cost_on_discard_card": {
        "card_energy_cost": 3,
        "card_values": {"damage": 18, "number_of_attacks": 1},
        "card_upgrade_value_improvements": {"damage": 6},
    },
    "attack_increase_cost_on_damage_taken_card": {
        "card_energy_cost": 0,
        "card_values": {"damage": 7, "number_of_attacks": 1},
        "card_upgrade_value_improvements": {"damage": 3},
    },
    "card_attack_rng": {
        "card_energy_cost": 1,
        "card_values": {"damage": 6, "number_of_attacks": 1, "damage_random": 3},
        "card_upgrade_value_improvements": {"damage_random": 3},
    },
    "self_attaching_attack_card": {
        "card_energy_cost": 0,
        "card_values": {"damage": 6, "number_of_attacks": 1},
        "card_upgrade_value_improvements": {},
    },
    "variable_cost_attack_card": {
        "card_energy_cost": 0,
        "card_energy_cost_is_variable": True,
        "card_energy_cost_variable_upper_bound": 3,
        "card_values": {"damage": 7, "number_of_attacks": 1},
        "card_upgrade_value_improvements": {"damage": 2},
    },
    "randomize_hand_card": {
        "card_energy_cost": 0,
        "card_values": {"draw_count": 2, "min_card_amount": 3, "max_card_amount": 3},
    },
    "set_hand_energy_card": {
        "card_energy_cost": 1,
        "card_values": {"min_card_amount": 3, "max_card_amount": 3},
    },
    "transform_hand_card": {
        "card_energy_cost": 1,
        "card_values": {"min_card_amount": 3, "max_card_amount": 3},
    },
    "card_grant_energy": {
        "card_energy_cost": 0,
        "card_values": {"energy_amount": 1},
        "card_upgrade_value_improvements": {"energy_amount": 1},
    },
    "card_energy_on_draw": {
        "card_values": {"energy_amount": 1},
        "card_upgrade_value_improvements": {"energy_amount": 1},
    },
    "card_something_fell_out": {
        "card_values": {"energy_amount": 1},
        "card_upgrade_value_improvements": {"energy_amount": 1},
    },
}


def load_properties(directory: Path, object_id: str) -> dict:
    path = directory / f"{object_id}.json"
    assert path.exists(), f"missing JSON: {path}"
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    properties = payload["properties"]
    assert properties["object_id"] == object_id
    return properties


def assert_nested_subset(actual: dict, expected: dict, label: str) -> None:
    for key, expected_value in expected.items():
        assert key in actual, f"{label} missing {key}"
        if isinstance(expected_value, dict):
            assert isinstance(actual[key], dict), f"{label}.{key} should be a dict"
            assert_nested_subset(actual[key], expected_value, f"{label}.{key}")
        else:
            assert actual[key] == expected_value, (
                f"{label}.{key} expected {expected_value}, got {actual[key]}"
            )


def walk_action_values(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.startswith("res://"):
                yield key, child
            yield from walk_action_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_action_values(child)


def action_values_for(card: dict, script_suffix: str) -> list[dict]:
    values = []
    for script_path, action_values in walk_action_values(card):
        if script_path.endswith(script_suffix):
            values.append(action_values)
    return values


def main() -> None:
    for player_file in sorted(PLAYERS.glob("player_*.json")):
        with player_file.open(encoding="utf-8") as handle:
            player = json.load(handle)["properties"]
        assert player["player_energy_max"] == EXPECTED_PLAYER_ENERGY_MAX, (
            f"{player_file.name} should start with {EXPECTED_PLAYER_ENERGY_MAX} energy"
        )

    for card_file in sorted(CARDS.glob("*.json")):
        with card_file.open(encoding="utf-8") as handle:
            card = json.load(handle)["properties"]
        if card.get("card_energy_cost_is_variable", False):
            assert card["card_energy_cost_variable_upper_bound"] <= EXPECTED_PLAYER_ENERGY_MAX, (
                f"{card['object_id']} X-cost upper bound should fit 3-energy turns"
            )
        elif card.get("card_is_playable", True):
            assert 0 <= card["card_energy_cost"] <= EXPECTED_PLAYER_ENERGY_MAX, (
                f"{card['object_id']} has cost outside 0-{EXPECTED_PLAYER_ENERGY_MAX}"
            )

    for card_id, expected in EXPECTED_CARD_VALUES.items():
        card = load_properties(CARDS, card_id)
        assert_nested_subset(card, expected, card_id)
        for exact_field in ("card_values", "card_upgrade_value_improvements"):
            if exact_field in expected:
                assert card[exact_field] == expected[exact_field], (
                    f"{card_id}.{exact_field} expected {expected[exact_field]}, "
                    f"got {card[exact_field]}"
                )

    grant_energy = load_properties(CARDS, "card_grant_energy")
    grant_energy_actions = action_values_for(grant_energy, "ActionAddEnergy.gd")
    assert grant_energy_actions, "card_grant_energy should grant energy when played"
    assert grant_energy_actions[0]["energy_amount"] == 1
    assert "[energy_amount]" in grant_energy["card_description"]

    draw_energy = load_properties(CARDS, "card_energy_on_draw")
    draw_energy_actions = action_values_for(draw_energy, "ActionAddEnergy.gd")
    assert draw_energy_actions[0]["energy_amount"] == 1

    fell_out = load_properties(CARDS, "card_something_fell_out")
    fell_out_actions = action_values_for(fell_out, "ActionAddEnergy.gd")
    assert fell_out_actions[0]["energy_amount"] == 1

    x_attack = load_properties(CARDS, "variable_cost_attack_card")
    x_attack_actions = action_values_for(x_attack, "ActionAttackGenerator.gd")
    assert x_attack_actions[0]["damage"] == 7

    lowering_attack = load_properties(CARDS, "attack_lower_cost_on_discard_card")
    lowering_listeners = action_values_for(lowering_attack, "ListenerCardCostModifier.gd")
    assert lowering_listeners, "discard-cost attack should lower cost from a listener"
    assert lowering_listeners[0]["stat_enum"] == 13
    assert lowering_listeners[0]["energy_per_stat"] == -1

    increasing_attack = load_properties(CARDS, "attack_increase_cost_on_damage_taken_card")
    increasing_listeners = action_values_for(increasing_attack, "ListenerCardCostModifier.gd")
    assert increasing_listeners, "damage-taken attack should increase cost from a listener"
    assert increasing_listeners[0]["stat_enum"] == 9
    assert increasing_listeners[0]["energy_per_stat"] == 1

    print("validated 3-energy card balance")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "external" / "data" / "artifacts" / "artifact_top_deck_attack_card.json"

PICK_CARDS = "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
CHANGE_CARD_PROPERTIES = "res://scripts/actions/cardset_actions/ActionChangeCardProperties.gd"
VALIDATOR_CARD_TYPE = "res://scripts/validators/card/ValidatorCardType.gd"

DECK = 1
ATTACK = 0


def main() -> None:
    with ARTIFACT.open(encoding="utf-8") as handle:
        properties = json.load(handle)["properties"]

    add_actions = properties["artifact_add_actions"]
    assert len(add_actions) == 1, "top-deck artifact must define one selection action"
    pick_values = add_actions[0][PICK_CARDS]

    assert pick_values["card_pick_type"] == DECK, "top-deck artifact must select from the permanent deck"
    assert pick_values["force_manual_selection"] is True, "top-deck artifact must show a deck selection prompt"
    assert pick_values["min_card_amount"] == 1, "top-deck artifact must require one selected card"
    assert pick_values["max_card_amount"] == 1, "top-deck artifact must select exactly one card"
    assert pick_values["min_cards_are_required_for_action"] is True, "top-deck artifact must not accept an empty selection"
    assert pick_values["validator_data"] == [{VALIDATOR_CARD_TYPE: {"card_types": [ATTACK]}}], (
        "top-deck artifact must only offer attack cards"
    )

    action_data = pick_values["action_data"]
    assert len(action_data) == 1, "top-deck artifact must apply one selected-card action"
    change_values = action_data[0][CHANGE_CARD_PROPERTIES]
    assert change_values["change_parent_card"] is False, "permanent deck cards must not require a combat parent"
    assert change_values["card_properties"] == {"card_first_shuffle_priority": 1}, (
        "selected attack must be prioritized in the first combat shuffle"
    )

    print("validated top-deck attack artifact configuration")


if __name__ == "__main__":
    main()

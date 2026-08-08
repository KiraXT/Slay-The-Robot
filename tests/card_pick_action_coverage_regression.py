#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"

PICK_UPGRADE_CARDS = "res://scripts/actions/pick_card_actions/ActionPickUpgradeCards.gd"
UPGRADE_CARDS = "res://scripts/actions/cardset_actions/ActionUpgradeCards.gd"
PICK_CARDS = "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
VALIDATOR_CARD_UPGRADEABLE = "res://scripts/validators/card/ValidatorCardUpgradeable.gd"
VALIDATOR_DECK_HAS_UPGRADEABLE_CARD = "res://scripts/validators/deck/ValidatorDeckHasUpgradeableCard.gd"

DECK = 1
COMBAT_DECK = 2
VALID_CARD_PICK_TYPES = set(range(9))


def load_card(card_id: str) -> dict:
    with (CARDS / f"{card_id}.json").open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


def find_pick_actions(value, source: str):
    if isinstance(value, dict):
        for key, child in value.items():
            if key in {PICK_CARDS, PICK_UPGRADE_CARDS}:
                yield source, key, child
            yield from find_pick_actions(child, source)
    elif isinstance(value, list):
        for child in value:
            yield from find_pick_actions(child, source)


def validate_explicit_picker_configuration() -> None:
    for path in sorted((ROOT / "external" / "data").rglob("*.json")):
        with path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
        for source, action_path, values in find_pick_actions(payload, str(path.relative_to(ROOT))):
            assert "card_pick_type" in values, f"{source} must explicitly define {action_path} card_pick_type"
            card_pick_type = values["card_pick_type"]
            assert (
                isinstance(card_pick_type, (int, float))
                and not isinstance(card_pick_type, bool)
                and int(card_pick_type) == card_pick_type
                and int(card_pick_type) in VALID_CARD_PICK_TYPES
            ), f"{source} must use a valid card_pick_type enum value"
            if action_path == PICK_CARDS:
                assert values.get("action_data"), f"{source} must define a result action for ActionPickCards"
            else:
                for key in ("force_manual_selection", "min_card_amount", "max_card_amount"):
                    assert key in values, f"{source} must explicitly define {key} for ActionPickUpgradeCards"


def main() -> None:
    validate_explicit_picker_configuration()

    upgrade_card = load_card("card_upgrade_card")
    upgrade_pick = upgrade_card["card_play_actions"][0][PICK_UPGRADE_CARDS]
    assert upgrade_pick["card_pick_type"] == DECK, "card_upgrade_card must select from the permanent deck"
    assert upgrade_pick["force_manual_selection"] is True, "card_upgrade_card must show the deck selection"
    assert upgrade_pick["min_card_amount"] == 1 and upgrade_pick["max_card_amount"] == 1, (
        "card_upgrade_card must select exactly one card"
    )
    assert upgrade_pick["min_cards_are_required_for_action"] is True, (
        "card_upgrade_card must reject empty selections"
    )
    assert upgrade_pick["upgrade_parent_card"] is False, "permanent deck cards must not require a combat parent"
    assert upgrade_pick["validator_data"] == [{VALIDATOR_CARD_UPGRADEABLE: {}}], (
        "card_upgrade_card must only offer upgradeable cards"
    )
    assert upgrade_card["card_play_validators"] == [{VALIDATOR_DECK_HAS_UPGRADEABLE_CARD: {}}], (
        "card_upgrade_card must be unavailable when the permanent deck has no upgradeable cards"
    )

    upgrade_entire_deck = load_card("upgrade_entire_deck_card")
    entire_deck_actions = upgrade_entire_deck["card_play_actions"]
    assert len(entire_deck_actions) == 1 and UPGRADE_CARDS in entire_deck_actions[0], (
        "upgrade_entire_deck_card must upgrade the combat deck without opening a card picker"
    )
    entire_deck_values = entire_deck_actions[0][UPGRADE_CARDS]
    assert entire_deck_values["card_pick_type"] == COMBAT_DECK, (
        "upgrade_entire_deck_card must target every card in the current combat deck"
    )
    assert entire_deck_values["upgrade_parent_card"] is False, (
        "upgrade_entire_deck_card must not permanently upgrade the source deck"
    )
    assert entire_deck_values["validator_data"] == [{VALIDATOR_CARD_UPGRADEABLE: {}}], (
        "upgrade_entire_deck_card must ignore cards that are already fully upgraded"
    )

    print("validated card-pick action coverage")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARD_PACKS = ROOT / "external" / "data" / "card_packs"
EVENT_POOLS = ROOT / "external" / "data" / "event_pools"

CARD_PACK_DATA = ROOT / "data" / "readonly" / "CardPackData.gd"
RANDOM = ROOT / "autoload" / "Random.gd"
PICK_CARDS = ROOT / "scripts" / "actions" / "pick_card_actions" / "ActionBasePickCards.gd"
OPEN_CHEST = ROOT / "scripts" / "actions" / "world_interaction_actions" / "ActionOpenChest.gd"
GRANT_REWARDS = ROOT / "scripts" / "actions" / "rewards" / "ActionGrantRewards.gd"
REWARD_OVERLAY = ROOT / "scripts" / "ui" / "RewardOverlay.gd"

REQUIRED_RARITY_KEYS = {"common", "uncommon", "rare"}


def load_properties(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    return payload["properties"]


def assert_contains(path: Path, needle: str) -> None:
    source = path.read_text(encoding="utf-8")
    assert needle in source, f"{path} must contain {needle!r}"


def main() -> None:
    assert_contains(CARD_PACK_DATA, "card_pack_rarity_weights")
    assert_contains(RANDOM, "generate_rarity_weighted_card_draft_from_card_pack_id")
    assert_contains(PICK_CARDS, "draft_is_weighted")
    assert_contains(OPEN_CHEST, "chest_consumable_count")
    assert_contains(OPEN_CHEST, "get_location_consumable_rewards")
    assert_contains(GRANT_REWARDS, "consumable_ids")
    assert_contains(REWARD_OVERLAY, "reward_consumable_ids")
    assert_contains(REWARD_OVERLAY, "reward_button_actions")

    for path in sorted(CARD_PACKS.glob("*.json")):
        card_pack = load_properties(path)
        weights = card_pack.get("card_pack_rarity_weights")
        assert isinstance(weights, dict), f"{path.name} must define card_pack_rarity_weights"
        assert REQUIRED_RARITY_KEYS <= set(weights), f"{path.name} must include common/uncommon/rare weights"
        assert all(isinstance(weights[key], int) and weights[key] >= 0 for key in REQUIRED_RARITY_KEYS), (
            f"{path.name} rarity weights must be non-negative integers"
        )
        assert sum(weights[key] for key in REQUIRED_RARITY_KEYS) > 0, f"{path.name} weights must not all be zero"

    for path in sorted(EVENT_POOLS.glob("*.json")):
        pool = load_properties(path)
        assert isinstance(pool.get("event_pool_event_object_ids"), list), f"{path.name} must list event ids"
        assert "event_pool_fallback_event_object_id" in pool, f"{path.name} must define fallback event id"

    print("validated reward and draft configuration")


if __name__ == "__main__":
    main()

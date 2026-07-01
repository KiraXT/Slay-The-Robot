#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
STATUSES = ROOT / "external" / "data" / "status_effects"

EXPECTED_CARDS = {
    "card_chorus": ("副歌", "color_green", 2, 2),
    "card_bookmark_clip": ("夹好书签", "color_orange", 1, 2),
    "card_pack_sorting": ("背包整理", "color_orange", 1, 2),
    "card_ready_stance": ("准备姿态", "color_orange", 1, 3),
}

EXPECTED_STATUSES = {
    "status_effect_chorus": "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd",
    "status_effect_bookmark_clip": "res://scripts/status_effects/StatusEffectTaggedCardTrigger.gd",
    "status_effect_pack_sorting": "res://scripts/status_effects/StatusEffectTaggedCardTrigger.gd",
    "status_effect_ready_stance": "res://scripts/status_effects/StatusEffectTaggedCardTrigger.gd",
}

REQUIRED_SCRIPTS = [
    ROOT / "scripts" / "actions" / "cardset_actions" / "ActionModifyCardTags.gd",
    ROOT / "scripts" / "actions" / "meta_actions" / "ActionDuplicateCurrentCardPlay.gd",
    ROOT / "scripts" / "status_effects" / "StatusEffectTaggedCardTrigger.gd",
]


def load_properties(path: Path) -> dict:
    assert path.exists(), f"missing file: {path}"
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


def walk(value):
    if isinstance(value, dict):
        for key, child in value.items():
            yield key, child
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def find_action_values(card: dict, script_suffix: str) -> list[dict]:
    matches = []
    for key, child in walk(card):
        if isinstance(key, str) and key.endswith(script_suffix):
            matches.append(child)
    return matches


def assert_card_basic(card_id: str, expected: tuple) -> dict:
    name, color_id, card_type, rarity = expected
    card = load_properties(CARDS / f"{card_id}.json")
    assert card["object_id"] == card_id
    assert card["card_name"] == name
    assert card["card_color_id"] == color_id
    assert card["card_type"] == card_type
    assert card["card_rarity"] == rarity
    assert card["card_appears_in_card_packs"] is True
    assert card["card_texture_path"], f"{card_id} should have a texture path"
    return card


def assert_status_basic(status_id: str, script_path: str) -> dict:
    status = load_properties(STATUSES / f"{status_id}.json")
    assert status["object_id"] == status_id
    assert status["status_effect_script_path"] == script_path
    assert status["status_effect_stacks"] is True
    return status


def assert_ledger_contains(card_ids: set[str]) -> None:
    with (ROOT / "external" / "config" / "cards.csv").open(encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    present = {row["object_id"] for row in rows}
    missing = sorted(card_ids - present)
    assert not missing, f"missing cards.csv rows: {missing}"


def main() -> None:
    for script_path in REQUIRED_SCRIPTS:
        assert script_path.exists(), f"missing script: {script_path}"

    once_per_turn_script = (ROOT / "scripts" / "status_effects" / "StatusEffectOncePerTurnTrigger.gd").read_text(encoding="utf-8")
    assert "func _disconnect_signals()" in once_per_turn_script
    assert "ActionDuplicateCurrentCardPlay.gd" in once_per_turn_script or "action_data" in once_per_turn_script

    next_modifier_script = (ROOT / "scripts" / "status_effects" / "StatusEffectNextMatchingCardModifier.gd").read_text(encoding="utf-8")
    assert "card_tag_filter" in next_modifier_script

    tagged_script = (ROOT / "scripts" / "status_effects" / "StatusEffectTaggedCardTrigger.gd").read_text(encoding="utf-8")
    for expected_text in [
        "card_drawn",
        "card_play_started",
        "player_turn_started",
        "player_turn_ended",
        "remove_tag_on_trigger",
        "expire_on_player_turn_end",
    ]:
        assert expected_text in tagged_script, expected_text

    for status_id, script_path in EXPECTED_STATUSES.items():
        assert_status_basic(status_id, script_path)

    chorus = assert_card_basic("card_chorus", EXPECTED_CARDS["card_chorus"])
    chorus_status_actions = find_action_values(chorus, "ActionApplyStatus.gd")
    assert chorus_status_actions
    chorus_custom_values = chorus_status_actions[0]["status_custom_values"]
    assert chorus_custom_values["trigger_signal"] == "card_play_started"
    assert chorus_custom_values["card_type_filter"] == [0, 1]
    assert chorus_custom_values["ignore_duplicate_plays"] is True
    assert find_action_values(chorus, "ActionDuplicateCurrentCardPlay.gd")

    bookmark = assert_card_basic("card_bookmark_clip", EXPECTED_CARDS["card_bookmark_clip"])
    assert find_action_values(bookmark, "ActionRetainCards.gd")
    assert any(values.get("add_tags") == ["temporary_bookmark_clip_discount"] for values in find_action_values(bookmark, "ActionModifyCardTags.gd"))
    assert any(values.get("status_effect_object_id") == "status_effect_bookmark_clip" for values in find_action_values(bookmark, "ActionApplyStatus.gd"))

    pack_sorting = assert_card_basic("card_pack_sorting", EXPECTED_CARDS["card_pack_sorting"])
    assert any(values.get("add_tags") == ["temporary_pack_sorting_energy"] for values in find_action_values(pack_sorting, "ActionModifyCardTags.gd"))
    assert find_action_values(pack_sorting, "ActionAddCardsToDraw.gd")
    assert any(values.get("status_effect_object_id") == "status_effect_pack_sorting" for values in find_action_values(pack_sorting, "ActionApplyStatus.gd"))

    ready_stance = assert_card_basic("card_ready_stance", EXPECTED_CARDS["card_ready_stance"])
    ready_pick_actions = find_action_values(ready_stance, "ActionPickCards.gd")
    assert ready_pick_actions
    assert ready_pick_actions[0]["random_selection"] is True
    assert any(values.get("add_tags") == ["temporary_ready_stance_damage"] for values in find_action_values(ready_stance, "ActionModifyCardTags.gd"))
    assert any(values.get("status_effect_object_id") == "status_effect_ready_stance" for values in find_action_values(ready_stance, "ActionApplyStatus.gd"))

    assert_ledger_contains(set(EXPECTED_CARDS))
    print("validated card reference final gap")


if __name__ == "__main__":
    main()

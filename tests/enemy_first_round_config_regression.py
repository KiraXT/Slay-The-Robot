#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENEMIES = ROOT / "external" / "data" / "enemies"
EVENTS = ROOT / "external" / "data" / "events"
EVENT_POOLS = ROOT / "external" / "data" / "event_pools"

EXPECTED_ENEMIES = {
    "enemy_act_1_scout_striker": {
        "name": "侦测打手",
        "enemy_type": 0,
        "enemy_health": 28,
        "state_count": 3,
        "texture_path": "external/sprites/enemies/enemy_act_1_scout_striker.png",
        "min_visible_height": 170,
    },
    "enemy_act_1_scrap_shield_guard": {
        "name": "废料盾卫",
        "enemy_type": 0,
        "enemy_health": 35,
        "state_count": 3,
        "texture_path": "external/sprites/enemies/enemy_act_1_scrap_shield_guard.png",
        "min_visible_height": 170,
    },
    "enemy_act_1_disruptor_unit": {
        "name": "消解单元",
        "enemy_type": 0,
        "enemy_health": 32,
        "state_count": 3,
        "texture_path": "external/sprites/enemies/enemy_act_1_disruptor_unit.png",
        "min_visible_height": 165,
    },
    "enemy_act_1_micro_drone": {
        "name": "小型无人机",
        "enemy_type": 0,
        "enemy_health": 10,
        "state_count": 3,
        "texture_path": "external/sprites/enemies/enemy_act_1_micro_drone.png",
        "min_visible_height": 125,
    },
    "enemy_act_1_miniboss_bastion_guard": {
        "name": "壁垒守卫",
        "enemy_type": 1,
        "enemy_health": 130,
        "state_count": 4,
        "texture_path": "external/sprites/enemies/enemy_act_1_miniboss_bastion_guard.png",
        "min_visible_height": 190,
    },
    "enemy_act_1_miniboss_command_core": {
        "name": "指挥中枢",
        "enemy_type": 1,
        "enemy_health": 95,
        "state_count": 4,
        "texture_path": "external/sprites/enemies/enemy_act_1_miniboss_command_core.png",
        "min_visible_height": 190,
    },
}

EXPECTED_EVENTS = {
    "event_act_1_easy_combat_scout_striker": ["enemy_act_1_scout_striker"],
    "event_act_1_easy_combat_drone_swarm": ["enemy_act_1_micro_drone"],
    "event_act_1_hard_combat_scrap_wall": [
        "enemy_act_1_scrap_shield_guard",
        "enemy_act_1_micro_drone",
    ],
    "event_act_1_hard_combat_disruptor_support": [
        "enemy_act_1_disruptor_unit",
        "enemy_act_1_scout_striker",
        "enemy_act_1_micro_drone",
    ],
    "event_act_1_miniboss_bastion_guard": ["enemy_act_1_miniboss_bastion_guard"],
    "event_act_1_miniboss_command_core": ["enemy_act_1_miniboss_command_core"],
}

EXPECTED_POOL_MEMBERS = {
    "event_pool_act_1_easy": [
        "event_act_1_easy_combat_scout_striker",
        "event_act_1_easy_combat_drone_swarm",
    ],
    "event_pool_act_1_hard": [
        "event_act_1_hard_combat_scrap_wall",
        "event_act_1_hard_combat_disruptor_support",
    ],
    "event_pool_act_1_miniboss": [
        "event_act_1_miniboss_bastion_guard",
        "event_act_1_miniboss_command_core",
    ],
}

KNOWN_STATUS_IDS = {
    "status_effect_damage_increase",
    "status_effect_negate_damage",
    "status_effect_negate_debuff",
    "status_effect_preserve_block",
    "status_effect_vulnerable",
    "status_effect_weaken",
}

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def load_properties(directory: Path, object_id: str) -> dict:
    path = directory / f"{object_id}.json"
    assert path.exists(), f"missing JSON for {object_id}: {path}"
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    properties = payload["properties"]
    assert properties["object_id"] == object_id
    return properties


def walk_action_values(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.startswith("res://"):
                yield key, child
            yield from walk_action_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_action_values(child)


def referenced_enemy_ids(event: dict) -> set[str]:
    enemy_ids = set()
    for slot_weights in event["event_weighted_enemy_object_ids"]:
        enemy_ids.update(slot_weights.keys())
    return enemy_ids


def validate_enemy_actions(enemy: dict) -> None:
    for script_path, values in walk_action_values(enemy):
        assert script_path.startswith("res://scripts/actions/"), script_path
        local_script_path = ROOT / script_path.replace("res://", "")
        assert local_script_path.exists(), f"missing action script: {script_path}"
        assert "status_effect_charges" not in values, (
            f"{enemy['object_id']} uses unsupported status_effect_charges in {script_path}"
        )
        status_id = values.get("status_effect_object_id")
        if status_id is not None:
            assert status_id in KNOWN_STATUS_IDS, f"unexpected status id: {status_id}"


def read_png_size_and_alpha(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as handle:
        header = handle.read(33)
    assert header.startswith(PNG_SIGNATURE), f"{path} is not a PNG"
    width = int.from_bytes(header[16:20], "big")
    height = int.from_bytes(header[20:24], "big")
    color_type = header[25]
    assert color_type in (4, 6), f"{path} should include alpha channel"

    try:
        from PIL import Image
    except ModuleNotFoundError:
        return width, height, min(width, height)

    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    visible_bbox = alpha.getbbox()
    assert visible_bbox is not None, f"{path} should have visible pixels"
    visible_height = visible_bbox[3] - visible_bbox[1]
    corner_pixels = [
        alpha.getpixel((0, 0)),
        alpha.getpixel((width - 1, 0)),
        alpha.getpixel((0, height - 1)),
        alpha.getpixel((width - 1, height - 1)),
    ]
    assert max(corner_pixels) == 0, f"{path} should have transparent corners"
    return width, height, visible_height


def main() -> None:
    for enemy_id, expected in EXPECTED_ENEMIES.items():
        enemy = load_properties(ENEMIES, enemy_id)
        assert enemy["enemy_name"] == expected["name"]
        assert enemy["enemy_type"] == expected["enemy_type"]
        assert enemy["enemy_health"] == expected["enemy_health"]
        assert enemy["enemy_health_max"] == expected["enemy_health"]
        assert enemy["enemy_is_minion"] is False
        assert len(enemy["enemy_attack_states"]) == expected["state_count"]
        assert "initial" in enemy["enemy_attack_states"]
        assert enemy["enemy_attack_states"]["initial"]["next_attack_weights"]
        assert enemy["enemy_texture_path"] == expected["texture_path"]
        texture_path = ROOT / expected["texture_path"]
        assert texture_path.exists(), f"missing texture: {texture_path}"
        _, _, visible_height = read_png_size_and_alpha(texture_path)
        assert visible_height >= expected["min_visible_height"], (
            f"{texture_path} visible height {visible_height} below "
            f"{expected['min_visible_height']}"
        )
        validate_enemy_actions(enemy)

    for event_id, expected_enemy_ids in EXPECTED_EVENTS.items():
        event = load_properties(EVENTS, event_id)
        ids = referenced_enemy_ids(event)
        for enemy_id in expected_enemy_ids:
            assert enemy_id in ids, f"{event_id} should reference {enemy_id}"

    command_event = load_properties(EVENTS, "event_act_1_miniboss_command_core")
    assert command_event["event_enemy_placement_is_automatic"] is False
    assert len(command_event["event_enemy_placement_positions"]) >= 3

    for pool_id, event_ids in EXPECTED_POOL_MEMBERS.items():
        pool = load_properties(EVENT_POOLS, pool_id)
        for event_id in event_ids:
            assert event_id in pool["event_pool_event_object_ids"], (
                f"{pool_id} should include {event_id}"
            )

    print("validated first-round enemy configuration")


if __name__ == "__main__":
    main()

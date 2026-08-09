#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENEMY_DIR = ROOT / "external" / "data" / "enemies"

EXPECTED_ENEMIES = {
    "enemy_1": {
        "name": "赤刃巡逻兵",
        "texture_path": "external/sprites/enemies/enemy_1.png",
        "min_visible_height": 260,
    },
    "enemy_2": {
        "name": "蓝壳斥候",
        "texture_path": "external/sprites/enemies/enemy_2.png",
        "min_visible_height": 230,
    },
    "enemy_3": {
        "name": "绿蚀净化者",
        "texture_path": "external/sprites/enemies/enemy_3.png",
        "min_visible_height": 260,
    },
    "enemy_4": {
        "name": "强袭破阵机",
        "texture_path": "external/sprites/enemies/enemy_4.png",
        "min_visible_height": 250,
    },
    "enemy_act_1_miniboss_1": {
        "name": "重装守门者",
        "texture_path": "external/sprites/enemies/enemy_act_1_miniboss_1.png",
        "min_visible_height": 270,
    },
    "enemy_act_1_miniboss_2": {
        "name": "双生突击者",
        "texture_path": "external/sprites/enemies/enemy_act_1_miniboss_2.png",
        "min_visible_height": 240,
    },
    "enemy_act_1_boss_1": {
        "name": "蜂巢主机",
        "texture_path": "external/sprites/enemies/enemy_act_1_boss_1.png",
        "min_visible_height": 330,
    },
    "enemy_act_2_boss_foundry_heart": {
        "name": "熔炉心脏",
        "texture_path": "external/sprites/enemies/enemy_act_2_boss_foundry_heart.png",
        "min_visible_height": 330,
    },
    "enemy_act_3_boss_overmind_core": {
        "name": "至高主脑核心",
        "texture_path": "external/sprites/enemies/enemy_act_3_boss_overmind_core.png",
        "min_visible_height": 330,
    },
    "enemy_act_2_scrap_lancer": {
        "name": "废料长枪机",
        "texture_path": "external/sprites/enemies/enemy_act_2_scrap_lancer.png",
        "min_visible_height": 230,
    },
    "enemy_act_2_barrier_smith": {
        "name": "护栏锻造机",
        "texture_path": "external/sprites/enemies/enemy_act_2_barrier_smith.png",
        "min_visible_height": 230,
    },
    "enemy_act_2_signal_jammer": {
        "name": "信号干扰器",
        "texture_path": "external/sprites/enemies/enemy_act_2_signal_jammer.png",
        "min_visible_height": 230,
    },
    "enemy_act_2_repair_drone": {
        "name": "修补无人机",
        "texture_path": "external/sprites/enemies/enemy_act_2_repair_drone.png",
        "min_visible_height": 180,
    },
    "enemy_act_2_miniboss_forge_guardian": {
        "name": "熔炉守卫",
        "texture_path": "external/sprites/enemies/enemy_act_2_miniboss_forge_guardian.png",
        "min_visible_height": 280,
    },
    "enemy_act_2_miniboss_relay_tower": {
        "name": "中继高塔",
        "texture_path": "external/sprites/enemies/enemy_act_2_miniboss_relay_tower.png",
        "min_visible_height": 280,
    },
    "enemy_act_3_core_blade": {
        "name": "核心刃卫",
        "texture_path": "external/sprites/enemies/enemy_act_3_core_blade.png",
        "min_visible_height": 230,
    },
    "enemy_act_3_null_priest": {
        "name": "归零祭仪机",
        "texture_path": "external/sprites/enemies/enemy_act_3_null_priest.png",
        "min_visible_height": 230,
    },
    "enemy_act_3_shield_obelisk": {
        "name": "护盾方尖碑",
        "texture_path": "external/sprites/enemies/enemy_act_3_shield_obelisk.png",
        "min_visible_height": 260,
    },
    "enemy_act_3_orbital_drone": {
        "name": "轨道无人机",
        "texture_path": "external/sprites/enemies/enemy_act_3_orbital_drone.png",
        "min_visible_height": 180,
    },
    "enemy_act_3_miniboss_null_bastion": {
        "name": "归零壁垒",
        "texture_path": "external/sprites/enemies/enemy_act_3_miniboss_null_bastion.png",
        "min_visible_height": 280,
    },
    "enemy_act_3_miniboss_orbital_array": {
        "name": "轨道阵列",
        "texture_path": "external/sprites/enemies/enemy_act_3_miniboss_orbital_array.png",
        "min_visible_height": 280,
    },
    "enemy_minion_1": {
        "name": "裂爪子机",
        "texture_path": "external/sprites/enemies/enemy_minion_1.png",
        "min_visible_height": 190,
    },
    "enemy_minion_2": {
        "name": "绿壳子机",
        "texture_path": "external/sprites/enemies/enemy_minion_2.png",
        "min_visible_height": 190,
    },
}

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def load_enemy(enemy_id):
    with (ENEMY_DIR / f"{enemy_id}.json").open(encoding="utf-8") as fp:
        return json.load(fp)["properties"]


def read_png_size_and_alpha(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as fp:
        header = fp.read(33)
    assert header.startswith(PNG_SIGNATURE), f"{path} is not a PNG"
    width = int.from_bytes(header[16:20], "big")
    height = int.from_bytes(header[20:24], "big")
    color_type = header[25]
    assert color_type in (4, 6), f"{path} should include alpha channel"

    from PIL import Image

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


def main():
    failures = []
    texture_paths = []
    for enemy_id, expected in EXPECTED_ENEMIES.items():
        enemy = load_enemy(enemy_id)
        actual_name = enemy.get("enemy_name")
        if actual_name != expected["name"]:
            failures.append(f"{enemy_id}: expected {expected['name']!r}, got {actual_name!r}")

        actual_path = enemy.get("enemy_texture_path")
        if actual_path != expected["texture_path"]:
            failures.append(
                f"{enemy_id}: expected texture {expected['texture_path']!r}, got {actual_path!r}"
            )
            continue

        texture_paths.append(actual_path)
        texture_path = ROOT / actual_path
        if not texture_path.exists():
            failures.append(f"{enemy_id}: missing texture {actual_path!r}")
            continue

        _, _, visible_height = read_png_size_and_alpha(texture_path)
        if visible_height < expected["min_visible_height"]:
            failures.append(
                f"{enemy_id}: visible height {visible_height} below "
                f"{expected['min_visible_height']}"
            )

    if len(set(texture_paths)) != len(texture_paths):
        failures.append("existing enemies should not share replacement texture paths")

    if failures:
        raise AssertionError("\n".join(failures))


if __name__ == "__main__":
    main()

# Multi-Act Boss Progression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete three-act combat progression with act-specific normal combat, miniboss, and Boss pools while keeping final Boss art as documented placeholders.

**Architecture:** Keep `ActionGenerateAct.gd` unchanged and make the progression data-driven through `ActData`, `EventPoolData`, `EventData`, and `EnemyData` JSON files. Tests first verify the data contract and runtime map generation, then data files fill the failing contract.

**Tech Stack:** Godot 4 GDScript, JSON data under `external/data/`, Python regression tests for static data contracts, headless Godot regression tests for runtime map generation.

## Global Constraints

- First act behavior and existing enemy IDs remain unchanged.
- `act_2` and `act_3` must use act-specific easy, hard, miniboss, and Boss event pools.
- Boss behavior must use existing actions only: attack generation, block, summon, and status application.
- Boss placeholder art must use `external/sprites/enemies/enemy_act_1_boss_1.png`.
- New normal enemy and miniboss art may reuse existing same-style enemy PNGs.
- Do not change rewards, shop, rest, cards, or map generation algorithm.
- Superpower project documents are written in Chinese unless the user requests another language; this implementation plan uses the required skill template header in English and project-specific notes in English for worker clarity.

---

## File Structure

- Create: `tests/multi_act_boss_progression_regression.py`
  - Static data contract: validates act pool wiring, pool membership, event enemy references, enemy texture paths, status/action references, Boss HP ordering, and attack-state graph reachability.
- Create: `tests/multi_act_map_generation_regression.gd`
  - Runtime contract: generates `act_2` and `act_3`, then confirms each generated Boss location uses the act-specific Boss pool and resolves to the act-specific Boss event.
- Modify: `external/data/acts/act_2.json`
  - Point to `event_pool_act_2_easy`, `event_pool_act_2_hard`, `event_pool_act_2_miniboss`, and `event_pool_act_2_boss`.
- Modify: `external/data/acts/act_3.json`
  - Point to `event_pool_act_3_easy`, `event_pool_act_3_hard`, `event_pool_act_3_miniboss`, and `event_pool_act_3_boss`; keep `act_next_act_ids` as `["act_1"]` so Endless Mode can continue looping.
- Create: `external/data/event_pools/event_pool_act_2_easy.json`
- Create: `external/data/event_pools/event_pool_act_2_hard.json`
- Create: `external/data/event_pools/event_pool_act_2_miniboss.json`
- Create: `external/data/event_pools/event_pool_act_2_boss.json`
- Create: `external/data/event_pools/event_pool_act_3_easy.json`
- Create: `external/data/event_pools/event_pool_act_3_hard.json`
- Create: `external/data/event_pools/event_pool_act_3_miniboss.json`
- Create: `external/data/event_pools/event_pool_act_3_boss.json`
- Create act 2 event files:
  - `external/data/events/event_act_2_easy_combat_scrap_pair.json`
  - `external/data/events/event_act_2_easy_combat_barrier_lancer.json`
  - `external/data/events/event_act_2_easy_combat_jammer_drone.json`
  - `external/data/events/event_act_2_hard_combat_forge_line.json`
  - `external/data/events/event_act_2_hard_combat_signal_wall.json`
  - `external/data/events/event_act_2_hard_combat_lancer_pack.json`
  - `external/data/events/event_act_2_miniboss_forge_guardian.json`
  - `external/data/events/event_act_2_miniboss_relay_tower.json`
  - `external/data/events/event_act_2_boss_foundry_heart.json`
- Create act 3 event files:
  - `external/data/events/event_act_3_easy_combat_core_blade_pair.json`
  - `external/data/events/event_act_3_easy_combat_null_priest_guard.json`
  - `external/data/events/event_act_3_easy_combat_drone_screen.json`
  - `external/data/events/event_act_3_hard_combat_null_wall.json`
  - `external/data/events/event_act_3_hard_combat_core_phalanx.json`
  - `external/data/events/event_act_3_hard_combat_orbital_crossfire.json`
  - `external/data/events/event_act_3_miniboss_null_bastion.json`
  - `external/data/events/event_act_3_miniboss_orbital_array.json`
  - `external/data/events/event_act_3_boss_overmind_core.json`
- Create act 2 enemy files:
  - `external/data/enemies/enemy_act_2_scrap_lancer.json`
  - `external/data/enemies/enemy_act_2_barrier_smith.json`
  - `external/data/enemies/enemy_act_2_signal_jammer.json`
  - `external/data/enemies/enemy_act_2_repair_drone.json`
  - `external/data/enemies/enemy_act_2_miniboss_forge_guardian.json`
  - `external/data/enemies/enemy_act_2_miniboss_relay_tower.json`
  - `external/data/enemies/enemy_act_2_boss_foundry_heart.json`
- Create act 3 enemy files:
  - `external/data/enemies/enemy_act_3_core_blade.json`
  - `external/data/enemies/enemy_act_3_null_priest.json`
  - `external/data/enemies/enemy_act_3_shield_obelisk.json`
  - `external/data/enemies/enemy_act_3_orbital_drone.json`
  - `external/data/enemies/enemy_act_3_miniboss_null_bastion.json`
  - `external/data/enemies/enemy_act_3_miniboss_orbital_array.json`
  - `external/data/enemies/enemy_act_3_boss_overmind_core.json`

## Task 1: Static Multi-Act Data Contract

**Files:**
- Create: `tests/multi_act_boss_progression_regression.py`

**Interfaces:**
- Consumes: JSON shape used by `ActData`, `EventPoolData`, `EventData`, and `EnemyData`.
- Produces: a regression command `python3 tests/multi_act_boss_progression_regression.py`.

- [ ] **Step 1: Write the failing test**

Create `tests/multi_act_boss_progression_regression.py` with this structure:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 tests/multi_act_boss_progression_regression.py`

Expected: FAIL because `act_2` and `act_3` still point at first-act pools and new pools/events/enemies do not exist.

- [ ] **Step 3: Commit**

Commit is deferred until Task 2 turns the red test green.

## Task 2: Act 2 And Act 3 Combat Data

**Files:**
- Modify: `external/data/acts/act_2.json`
- Modify: `external/data/acts/act_3.json`
- Create: all event pool, event, and enemy JSON files listed in File Structure.

**Interfaces:**
- Consumes: `ActionApplyStatus.gd` with `status_charge_amount`, `status_effect_object_id`, `target_override`.
- Consumes: `ActionSummonEnemies.gd` with `number_of_spawns`, `random_enemy_object_ids`, `spawn_slots`, `target_override`.
- Produces: act-specific pool IDs consumed by `ActionGenerateAct.gd`.

- [ ] **Step 1: Write minimal production data**

Use these exact pool memberships:

```json
{
  "event_pool_act_2_easy": [
    "event_act_2_easy_combat_scrap_pair",
    "event_act_2_easy_combat_barrier_lancer",
    "event_act_2_easy_combat_jammer_drone"
  ],
  "event_pool_act_2_hard": [
    "event_act_2_hard_combat_forge_line",
    "event_act_2_hard_combat_signal_wall",
    "event_act_2_hard_combat_lancer_pack"
  ],
  "event_pool_act_2_miniboss": [
    "event_act_2_miniboss_forge_guardian",
    "event_act_2_miniboss_relay_tower"
  ],
  "event_pool_act_2_boss": ["event_act_2_boss_foundry_heart"],
  "event_pool_act_3_easy": [
    "event_act_3_easy_combat_core_blade_pair",
    "event_act_3_easy_combat_null_priest_guard",
    "event_act_3_easy_combat_drone_screen"
  ],
  "event_pool_act_3_hard": [
    "event_act_3_hard_combat_null_wall",
    "event_act_3_hard_combat_core_phalanx",
    "event_act_3_hard_combat_orbital_crossfire"
  ],
  "event_pool_act_3_miniboss": [
    "event_act_3_miniboss_null_bastion",
    "event_act_3_miniboss_orbital_array"
  ],
  "event_pool_act_3_boss": ["event_act_3_boss_overmind_core"]
}
```

Use these exact enemy IDs and base values:

```json
{
  "enemy_act_2_scrap_lancer": {"name": "废料长枪机", "health": 42, "type": 0, "texture": "external/sprites/enemies/enemy_4.png"},
  "enemy_act_2_barrier_smith": {"name": "护栏锻造机", "health": 48, "type": 0, "texture": "external/sprites/enemies/enemy_act_1_scrap_shield_guard.png"},
  "enemy_act_2_signal_jammer": {"name": "信号干扰器", "health": 36, "type": 0, "texture": "external/sprites/enemies/enemy_act_1_disruptor_unit.png"},
  "enemy_act_2_repair_drone": {"name": "修补无人机", "health": 18, "type": 0, "texture": "external/sprites/enemies/enemy_act_1_micro_drone.png"},
  "enemy_act_2_miniboss_forge_guardian": {"name": "熔炉守卫", "health": 160, "type": 1, "texture": "external/sprites/enemies/enemy_act_1_miniboss_bastion_guard.png"},
  "enemy_act_2_miniboss_relay_tower": {"name": "中继高塔", "health": 135, "type": 1, "texture": "external/sprites/enemies/enemy_act_1_miniboss_command_core.png"},
  "enemy_act_2_boss_foundry_heart": {"name": "熔炉心脏", "health": 260, "type": 2, "texture": "external/sprites/enemies/enemy_act_1_boss_1.png"},
  "enemy_act_3_core_blade": {"name": "核心刃卫", "health": 58, "type": 0, "texture": "external/sprites/enemies/enemy_4.png"},
  "enemy_act_3_null_priest": {"name": "归零祭仪机", "health": 52, "type": 0, "texture": "external/sprites/enemies/enemy_3.png"},
  "enemy_act_3_shield_obelisk": {"name": "护盾方尖碑", "health": 72, "type": 0, "texture": "external/sprites/enemies/enemy_act_1_scrap_shield_guard.png"},
  "enemy_act_3_orbital_drone": {"name": "轨道无人机", "health": 24, "type": 0, "texture": "external/sprites/enemies/enemy_act_1_micro_drone.png"},
  "enemy_act_3_miniboss_null_bastion": {"name": "归零壁垒", "health": 210, "type": 1, "texture": "external/sprites/enemies/enemy_act_1_miniboss_bastion_guard.png"},
  "enemy_act_3_miniboss_orbital_array": {"name": "轨道阵列", "health": 180, "type": 1, "texture": "external/sprites/enemies/enemy_act_1_miniboss_command_core.png"},
  "enemy_act_3_boss_overmind_core": {"name": "至高主脑核心", "health": 340, "type": 2, "texture": "external/sprites/enemies/enemy_act_1_boss_1.png"}
}
```

Use `target_override = 1` for self-targeted block/status actions and `target_override = 2` for player debuffs. Use manual event positions `[[180, 0], [0, 0], [360, 0]]` for summon-capable Boss and miniboss events so the main enemy is centered in slot 0 and summons occupy slots 1 and 2.

- [ ] **Step 2: Run static test to verify it passes**

Run: `python3 tests/multi_act_boss_progression_regression.py`

Expected: PASS and prints `validated multi-act boss progression data`.

- [ ] **Step 3: Commit**

```bash
git add tests/multi_act_boss_progression_regression.py external/data/acts/act_2.json external/data/acts/act_3.json external/data/event_pools external/data/events external/data/enemies
git commit -m "feat: add multi-act combat progression data"
```

## Task 3: Runtime Map Generation Regression

**Files:**
- Create: `tests/multi_act_map_generation_regression.gd`

**Interfaces:**
- Consumes: `ActionGenerator.generate_act(act_id: String, act_number: int)`.
- Consumes: `Global.get_all_act_locations()`.
- Produces: runtime proof that generated Boss nodes use the act-specific Boss event pools.

- [ ] **Step 1: Write the failing runtime test**

Create `tests/multi_act_map_generation_regression.gd`:

```gdscript
extends SceneTree

const PLAYER_ID := "player_red"
const TEST_SEED := 20260807
const LOCATION_TYPES := {
	"STARTING": 0,
	"COMBAT": 1,
	"MINIBOSS": 2,
	"BOSS": 3,
	"EVENT": 4,
	"TREASURE": 5,
	"SHOP": 6,
	"REST_SITE": 7,
}

var failures: Array[String] = []
var game_global: Node
var action_generator: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	action_generator = root.get_node("ActionGenerator")
	var previous_player_data = game_global.player_data
	_assert_generated_act_boss_pool("act_2", 2, "event_pool_act_2_boss", "event_act_2_boss_foundry_heart")
	_assert_generated_act_boss_pool("act_3", 3, "event_pool_act_3_boss", "event_act_3_boss_overmind_core")
	game_global.player_data = previous_player_data
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _assert_generated_act_boss_pool(act_id: String, act_number: int, expected_pool_id: String, expected_event_id: String) -> void:
	game_global.player_data = game_global.get_player_data_from_prototype(PLAYER_ID)
	game_global.player_data.player_run_seed = TEST_SEED
	game_global.player_data.player_act = act_number - 1
	game_global.player_data.player_act_id = "act_%s" % str(max(1, act_number - 1))
	game_global.player_data.player_location_id = "location_previous_boss"
	game_global.player_data.player_rng.clear()
	var previous_location := LocationData.new()
	previous_location.location_id = "location_previous_boss"
	previous_location.location_act = act_number - 1
	previous_location.location_type = LOCATION_TYPES.BOSS
	previous_location.location_position = Vector2(400, 100)
	game_global.player_data.location_id_to_location_data[previous_location.location_id] = previous_location
	action_generator.generate_act(act_id, act_number)
	var boss_location = _get_single_location_of_type(game_global.get_all_act_locations(), LOCATION_TYPES.BOSS)
	if boss_location == null:
		return
	if boss_location.location_event_pool_object_id != expected_pool_id:
		failures.append("%s boss location should use %s, got %s" % [
			act_id,
			expected_pool_id,
			boss_location.location_event_pool_object_id,
		])
	var actual_event_id: String = boss_location.get_location_event_object_id()
	if actual_event_id != expected_event_id:
		failures.append("%s boss location should resolve %s, got %s" % [
			act_id,
			expected_event_id,
			actual_event_id,
		])


func _get_single_location_of_type(locations: Array, location_type: int):
	var matching_locations: Array = []
	for location in locations:
		if location.location_type == location_type:
			matching_locations.append(location)
	if matching_locations.size() != 1:
		failures.append("Expected one location of type %s, got %s." % [location_type, matching_locations.size()])
		return null
	return matching_locations[0]
```

- [ ] **Step 2: Run runtime test**

Run: `godot --headless --path . --script tests/multi_act_map_generation_regression.gd`

Expected: PASS after Task 2 data exists.

- [ ] **Step 3: Commit**

```bash
git add tests/multi_act_map_generation_regression.gd
git commit -m "test: cover multi-act map boss pools"
```

## Task 4: Full Verification

**Files:**
- No new files.

**Interfaces:**
- Consumes: all new data and tests from Tasks 1-3.
- Produces: final acceptance result.

- [ ] **Step 1: Run focused Python regressions**

Run:

```bash
python3 tests/multi_act_boss_progression_regression.py
python3 tests/enemy_first_round_config_regression.py
python3 tests/existing_enemy_packaging_regression.py
```

Expected: all commands exit 0.

- [ ] **Step 2: Run focused Godot regressions**

Run:

```bash
godot --headless --path . --script tests/multi_act_map_generation_regression.gd
godot --headless --path . --script tests/map_generation_flow_regression.gd
godot --headless --path . --script tests/map_location_layout_regression.gd
```

Expected: all commands print `ALL_TESTS_PASSED` and exit 0.

- [ ] **Step 3: Inspect working tree**

Run: `git status --short`

Expected: only unrelated pre-existing files plus files intentionally changed by this feature if a final commit has not yet been made.

- [ ] **Step 4: Final commit if needed**

If Task 2 or Task 3 commits were deferred, stage only this feature's files and commit:

```bash
git add docs/superpowers/plans/2026-08-07-multi-act-boss-progression.md tests/multi_act_boss_progression_regression.py tests/multi_act_map_generation_regression.gd external/data/acts/act_2.json external/data/acts/act_3.json external/data/event_pools external/data/events external/data/enemies
git commit -m "feat: add multi-act boss progression"
```

# 卡牌参考缺口 B 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现每回合首次触发型能力，配置 `节拍器`、`轻装上阵`、`最后一件`，并把卡牌写入 JSON 与 Excel/CSV 台账。

**Architecture:** 使用玩家身上的状态效果承载“每回合一次触发”能力。状态脚本监听战斗信号，根据 `status_custom_values` 判断触发时机并生成 actions；`节拍器` 在 `card_play_started` 阶段修改当前 `CardPlayRequest.card_values`，保证发生在该牌 actions 生成前。

**Tech Stack:** Godot 4 / GDScript、JSON card/status resources、Python 3、openpyxl、现有回归脚本。

---

## 文件结构

- Modify: `tests/card_configurable_cards_regression.py`
  - 加入 `card_metronome`、`card_travel_light`、`card_last_item`。
  - 预期总数从 18 增至 21。
- Create: `tests/card_reference_gap_b_regression.py`
  - 检查 B 批脚本、状态、卡牌和台账配置。
- Modify: `autoload/Scripts.gd`
  - 增加 `ACTION_MODIFY_CURRENT_CARD_PLAY_VALUES`。
- Modify: `scripts/actions/status_actions/ActionApplyStatus.gd`
  - 支持 `status_custom_values` 传给 `BaseCombatant.add_new_status_effect()`。
- Create: `scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd`
  - 修改当前 `CardPlayRequest.card_values`，不写回 `CardData`。
- Create: `scripts/status_effects/StatusEffectOncePerTurnTrigger.gd`
  - 通用每回合一次触发状态脚本。
- Create: `external/data/status_effects/status_effect_metronome.json`
  - `节拍器` 可见状态，脚本指向通用状态脚本。
- Create: `external/data/status_effects/status_effect_travel_light.json`
  - `轻装上阵` 可见状态，脚本指向通用状态脚本。
- Create: `external/data/cards/card_metronome.json`
- Create: `external/data/cards/card_travel_light.json`
- Create: `external/data/cards/card_last_item.json`
- Modify: `external/tools/excel_to_json.py`
  - 将 `ActionModifyCurrentCardPlayValues` 加入 action path map。
- Modify: `external/tools/json_to_excel.py`
  - 将新 action 保留在复杂字段 JSON 输出中。
- Modify: `external/config/cards.xlsx`
  - 从 JSON 重新生成，包含三张新卡。
- Modify: `external/config/cards.csv`
  - 从 workbook 导出，包含三张新卡。

## Task 0: 建立隔离工作区和基线

**Files:**
- No source files.

- [ ] **Step 1: 创建实现 worktree**

从当前分支创建实现分支，然后合入 `main`，确保同时包含 B 批设计文档和 A 批实现：

```bash
git worktree add .worktrees/card-reference-gap-b -b codex/card-reference-gap-b
```

切换到新 worktree 后运行：

```bash
git merge main
```

Expected: merge succeeds without conflicts.

- [ ] **Step 2: 运行基线回归**

在 `.worktrees/card-reference-gap-b` 中运行：

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected:

```text
validated 18 configurable cards
validated card reference gap A
```

## Task 1: 增加失败回归测试

**Files:**
- Modify: `tests/card_configurable_cards_regression.py`
- Create: `tests/card_reference_gap_b_regression.py`

- [ ] **Step 1: 扩展卡牌配置回归**

在 `EXPECTED` 中加入：

```python
    "card_metronome": "color_green",
    "card_travel_light": "color_orange",
    "card_last_item": "color_orange",
```

在 `REQUIRED_ACTIONS` 中加入：

```python
    "card_metronome": ["card_play_actions"],
    "card_travel_light": ["card_play_actions"],
    "card_last_item": ["card_play_actions"],
```

- [ ] **Step 2: 新增 B 批专项回归**

创建 `tests/card_reference_gap_b_regression.py`：

```python
#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
STATUSES = ROOT / "external" / "data" / "status_effects"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"

STATUS_SCRIPT = "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd"
MODIFY_VALUES_ACTION = "res://scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd"
APPLY_STATUS_ACTION = "res://scripts/actions/status_actions/ActionApplyStatus.gd"
ADD_ENERGY_ACTION = "res://scripts/actions/ActionAddEnergy.gd"
VARIABLE_STATS_ACTION = "res://scripts/actions/meta_actions/ActionVariableCombatStatsModifier.gd"


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


def load_card(card_id: str) -> dict:
    return load_json(CARDS / f"{card_id}.json")


def load_status(status_id: str) -> dict:
    return load_json(STATUSES / f"{status_id}.json")


def walk(value):
    if isinstance(value, dict):
        for key, child in value.items():
            yield key, child
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def assert_path_exists(res_path: str) -> None:
    assert (ROOT / res_path.replace("res://", "")).exists(), res_path


def find_action_payload(card: dict, action_path: str) -> list[dict]:
    return [child for key, child in walk(card.get("card_play_actions", [])) if key == action_path]


def csv_ids() -> list[str]:
    with CSV_PATH.open(encoding="utf-8", newline="") as handle:
        return [row["object_id"] for row in csv.DictReader(handle) if row.get("object_id")]


def main() -> None:
    assert_path_exists(STATUS_SCRIPT)
    assert_path_exists(MODIFY_VALUES_ACTION)

    apply_status_text = (ROOT / APPLY_STATUS_ACTION.replace("res://", "")).read_text(encoding="utf-8")
    assert "status_custom_values" in apply_status_text
    assert "add_new_status_effect(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)" in apply_status_text

    metronome_status = load_status("status_effect_metronome")
    assert metronome_status["status_effect_script_path"] == STATUS_SCRIPT
    assert metronome_status["status_effect_allows_multiples"] is True

    travel_light_status = load_status("status_effect_travel_light")
    assert travel_light_status["status_effect_script_path"] == STATUS_SCRIPT
    assert travel_light_status["status_effect_allows_multiples"] is True

    metronome = load_card("card_metronome")
    metronome_payloads = find_action_payload(metronome, APPLY_STATUS_ACTION)
    assert len(metronome_payloads) == 1
    metronome_values = metronome_payloads[0]
    assert metronome_values["status_effect_object_id"] == "status_effect_metronome"
    assert metronome_values["status_force_apply_new_effect"] is True
    metronome_custom = metronome_values["status_custom_values"]
    assert metronome_custom["trigger_signal"] == "card_play_started"
    assert metronome_custom["max_triggers_per_turn"] == 1
    assert any(key == MODIFY_VALUES_ACTION for key, _ in walk(metronome_custom["action_data"]))

    travel_light = load_card("card_travel_light")
    travel_payloads = find_action_payload(travel_light, APPLY_STATUS_ACTION)
    assert len(travel_payloads) == 1
    travel_values = travel_payloads[0]
    assert travel_values["status_effect_object_id"] == "status_effect_travel_light"
    assert travel_values["status_force_apply_new_effect"] is True
    travel_custom = travel_values["status_custom_values"]
    assert travel_custom["trigger_signal"] == "card_exhausted"
    assert travel_custom["max_triggers_per_turn"] == 1
    assert any(key == ADD_ENERGY_ACTION for key, _ in walk(travel_custom["action_data"]))

    last_item = load_card("card_last_item")
    last_item_payloads = find_action_payload(last_item, VARIABLE_STATS_ACTION)
    assert len(last_item_payloads) == 1
    assert last_item_payloads[0]["stat_enum"] == 14
    assert last_item_payloads[0]["is_total_stat"] is True

    ids = csv_ids()
    for card_id in ("card_metronome", "card_travel_light", "card_last_item"):
        assert ids.count(card_id) == 1, f"{card_id} should appear once in cards.csv"

    print("validated card reference gap B")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: 运行失败回归**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_b_regression.py
```

Expected: 第一条因缺少 `card_metronome.json` 等卡牌失败；第二条因缺少新脚本或状态失败。

## Task 2: 实现每回合一次触发框架

**Files:**
- Modify: `autoload/Scripts.gd`
- Modify: `scripts/actions/status_actions/ActionApplyStatus.gd`
- Create: `scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd`
- Create: `scripts/status_effects/StatusEffectOncePerTurnTrigger.gd`

- [ ] **Step 1: 在 `Scripts.gd` 增加 action 常量**

在 meta actions 区域加入：

```gdscript
const ACTION_MODIFY_CURRENT_CARD_PLAY_VALUES: String = "res://scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd"
```

- [ ] **Step 2: 扩展 `ActionApplyStatus.gd`**

在读取状态参数处加入：

```gdscript
var status_custom_values: Dictionary = action_interceptor_processor.get_shadowed_action_values("status_custom_values", {})
```

并把强制新实例路径改为：

```gdscript
target.add_new_status_effect(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)
```

- [ ] **Step 3: 创建当前出牌数值修改 action**

创建 `scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd`：

```gdscript
# Modifies values on the current CardPlayRequest only. Does not mutate CardData.
extends BaseAction

func is_instant_action() -> bool:
	return true

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		if card_play_request == null:
			continue
		var value_modifiers: Dictionary = action_interceptor_processor.get_shadowed_action_values("value_modifiers", {})
		var operation: String = action_interceptor_processor.get_shadowed_action_values("operation", "add")
		for value_key in value_modifiers.keys():
			var existing_value: int = int(card_play_request.card_values.get(value_key, 0))
			var modifier: int = int(value_modifiers[value_key])
			match operation:
				"set":
					card_play_request.card_values[value_key] = modifier
				_:
					card_play_request.card_values[value_key] = max(0, existing_value + modifier)
```

- [ ] **Step 4: 创建通用状态脚本**

创建 `scripts/status_effects/StatusEffectOncePerTurnTrigger.gd`：

```gdscript
# Generic status effect that executes configured actions the first N times a matching event happens each player turn.
extends BaseStatusEffect

var triggers_this_turn: int = 0

func _connect_signals() -> void:
	Signals.player_turn_started.connect(_on_player_turn_started)
	var trigger_signal: String = str(status_custom_values.get("trigger_signal", ""))
	match trigger_signal:
		"card_play_started":
			Signals.card_play_started.connect(_on_card_play_event)
		"card_played":
			Signals.card_played.connect(_on_card_play_event)
		"card_drawn":
			Signals.card_drawn.connect(_on_card_data_event)
		"card_discarded":
			Signals.card_discarded.connect(_on_card_discarded)
		"card_exhausted":
			Signals.card_exhausted.connect(_on_card_data_event)
		_:
			push_error("Unsupported once-per-turn trigger_signal: %s" % trigger_signal)

func _on_player_turn_started() -> void:
	triggers_this_turn = 0

func _on_card_play_event(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	_attempt_trigger(card_play_request.card_data, card_play_request)

func _on_card_data_event(card_data: CardData) -> void:
	var card_play_request: CardPlayRequest = CardPlayRequest.new()
	card_play_request.card_data = card_data
	if card_data != null:
		card_play_request.card_values = card_data.card_values.duplicate(true)
	_attempt_trigger(card_data, card_play_request)

func _on_card_discarded(card_data: CardData, _is_manual_discard: bool) -> void:
	_on_card_data_event(card_data)

func _attempt_trigger(card_data: CardData, card_play_request: CardPlayRequest) -> void:
	if not Global.is_player_turn():
		return
	if not _can_trigger(card_data):
		return
	var max_triggers_per_turn: int = int(status_custom_values.get("max_triggers_per_turn", 1))
	if triggers_this_turn >= max_triggers_per_turn:
		return
	var action_data: Array = status_custom_values.get("action_data", [])
	if action_data.is_empty():
		return
	triggers_this_turn += 1
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [parent_combatant], action_data, null)
	ActionHandler.add_actions(generated_actions)

func _can_trigger(card_data: CardData) -> bool:
	if card_data == null:
		return false
	if status_custom_values.has("card_object_id_filter"):
		if card_data.object_id != str(status_custom_values["card_object_id_filter"]):
			return false
	if status_custom_values.has("card_type_filter"):
		var filter_value: Variant = status_custom_values["card_type_filter"]
		if filter_value is Array:
			var accepted_types: Array[int] = []
			accepted_types.assign(filter_value)
			return accepted_types.has(card_data.card_type)
		return card_data.card_type == int(filter_value)
	return true
```

- [ ] **Step 5: 运行专项回归确认仍失败在资源配置**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_b_regression.py
```

Expected: 新脚本检查通过，仍因缺少状态 JSON 或卡牌 JSON 失败。

## Task 3: 新增状态和卡牌 JSON

**Files:**
- Create: `external/data/status_effects/status_effect_metronome.json`
- Create: `external/data/status_effects/status_effect_travel_light.json`
- Create: `external/data/cards/card_metronome.json`
- Create: `external/data/cards/card_travel_light.json`
- Create: `external/data/cards/card_last_item.json`

- [ ] **Step 1: 新增 `status_effect_metronome`**

创建 `external/data/status_effects/status_effect_metronome.json`：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "status_effect_metronome",
        "status_effect_action_process_times": [],
        "status_effect_allows_multiples": true,
        "status_effect_can_be_negative": false,
        "status_effect_decay_rate": 0,
        "status_effect_decay_type": 0,
        "status_effect_enemy_actions": [],
        "status_effect_healthbar_layer_color": "",
        "status_effect_healthbar_reserve_type": 0,
        "status_effect_interceptor_ids": [],
        "status_effect_is_visible": true,
        "status_effect_name": "节拍器",
        "status_effect_negative_charges_texture_path": "",
        "status_effect_player_actions": [],
        "status_effect_priority": 0,
        "status_effect_script_path": "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd",
        "status_effect_stacks": true,
        "status_effect_texture_path": "external/sprites/status_effects/status_effect_duplicate_card_plays.png",
        "status_effect_type": 0
    }
}
```

- [ ] **Step 2: 新增 `status_effect_travel_light`**

创建 `external/data/status_effects/status_effect_travel_light.json`：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "status_effect_travel_light",
        "status_effect_action_process_times": [],
        "status_effect_allows_multiples": true,
        "status_effect_can_be_negative": false,
        "status_effect_decay_rate": 0,
        "status_effect_decay_type": 0,
        "status_effect_enemy_actions": [],
        "status_effect_healthbar_layer_color": "",
        "status_effect_healthbar_reserve_type": 0,
        "status_effect_interceptor_ids": [],
        "status_effect_is_visible": true,
        "status_effect_name": "轻装上阵",
        "status_effect_negative_charges_texture_path": "",
        "status_effect_player_actions": [],
        "status_effect_priority": 0,
        "status_effect_script_path": "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd",
        "status_effect_stacks": true,
        "status_effect_texture_path": "external/sprites/status_effects/status_effect_preserve_block.png",
        "status_effect_type": 0
    }
}
```

- [ ] **Step 3: 新增 `card_metronome`**

创建 `external/data/cards/card_metronome.json`，核心配置：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_metronome",
        "object_uid": "",
        "card_name": "节拍器",
        "card_description": "能力。每回合第一次打出攻击或技能时，其伤害和格挡提高 [value_bonus]。",
        "card_type": 2,
        "card_rarity": 2,
        "card_color_id": "color_green",
        "card_energy_cost": 1,
        "card_energy_cost_is_variable": false,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": false,
        "card_exhausts": false,
        "card_is_ethereal": false,
        "card_is_retained": false,
        "card_appears_in_card_packs": true,
        "card_texture_path": "external/sprites/cards/green/card_green.png",
        "card_keyword_object_ids": [],
        "card_values": {
            "value_bonus": 2,
            "status_charge_amount": 1
        },
        "card_play_actions": [
            {
                "res://scripts/actions/status_actions/ActionApplyStatus.gd": {
                    "target_override": 2,
                    "status_effect_object_id": "status_effect_metronome",
                    "status_charge_amount": 1,
                    "status_force_apply_new_effect": true,
                    "status_custom_values": {
                        "trigger_signal": "card_play_started",
                        "max_triggers_per_turn": 1,
                        "card_type_filter": [0, 1],
                        "ignore_duplicate_plays": true,
                        "action_data": [
                            {
                                "res://scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd": {
                                    "value_modifiers": {
                                        "damage": 2,
                                        "block": 2
                                    },
                                    "operation": "add"
                                }
                            }
                        ]
                    }
                }
            }
        ],
        "card_upgrade_value_improvements": {
            "value_bonus": 1
        },
        "card_first_upgrade_property_changes": {
            "card_energy_cost": 0
        },
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 4: 新增 `card_travel_light`**

创建 `external/data/cards/card_travel_light.json`，核心配置：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_travel_light",
        "object_uid": "",
        "card_name": "轻装上阵",
        "card_description": "能力。每回合第一次消耗牌时，获得 [energy_amount] 点能量。",
        "card_type": 2,
        "card_rarity": 2,
        "card_color_id": "color_orange",
        "card_energy_cost": 1,
        "card_energy_cost_is_variable": false,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": false,
        "card_exhausts": false,
        "card_is_ethereal": false,
        "card_is_retained": false,
        "card_appears_in_card_packs": true,
        "card_texture_path": "external/sprites/cards/orange/card_orange.png",
        "card_keyword_object_ids": [],
        "card_values": {
            "energy_amount": 1,
            "status_charge_amount": 1
        },
        "card_play_actions": [
            {
                "res://scripts/actions/status_actions/ActionApplyStatus.gd": {
                    "target_override": 2,
                    "status_effect_object_id": "status_effect_travel_light",
                    "status_charge_amount": 1,
                    "status_force_apply_new_effect": true,
                    "status_custom_values": {
                        "trigger_signal": "card_exhausted",
                        "max_triggers_per_turn": 1,
                        "action_data": [
                            {
                                "res://scripts/actions/ActionAddEnergy.gd": {
                                    "energy_amount": 1
                                }
                            }
                        ]
                    }
                }
            }
        ],
        "card_upgrade_value_improvements": {},
        "card_first_upgrade_property_changes": {
            "card_energy_cost": 0
        },
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 5: 新增 `card_last_item`**

创建 `external/data/cards/card_last_item.json`，核心配置：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_last_item",
        "object_uid": "",
        "card_name": "最后一件",
        "card_description": "造成 [damage] 点伤害。本场战斗每消耗过1张牌，额外造成 [damage_per_exhaust] 点伤害。",
        "card_type": 0,
        "card_rarity": 3,
        "card_color_id": "color_orange",
        "card_energy_cost": 2,
        "card_energy_cost_is_variable": false,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": true,
        "card_exhausts": false,
        "card_is_ethereal": false,
        "card_is_retained": false,
        "card_appears_in_card_packs": true,
        "card_texture_path": "external/sprites/cards/orange/card_orange.png",
        "card_keyword_object_ids": [],
        "card_values": {
            "damage": 10,
            "damage_per_exhaust": 2,
            "number_of_attacks": 1
        },
        "card_play_actions": [
            {
                "res://scripts/actions/meta_actions/ActionVariableCombatStatsModifier.gd": {
                    "stat_enum": 14,
                    "is_total_stat": true,
                    "multiplied_values": ["damage"],
                    "multiplied_values_bases": {
                        "damage": 10
                    },
                    "action_data": [
                        {
                            "res://scripts/actions/meta_actions/ActionAttackGenerator.gd": {
                                "damage": 2,
                                "number_of_attacks": 1,
                                "time_delay": 0.0,
                                "actions_on_lethal": []
                            }
                        }
                    ]
                }
            }
        ],
        "card_upgrade_value_improvements": {},
        "card_first_upgrade_property_changes": {
            "card_energy_cost": 1
        },
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 6: 运行专项回归**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_b_regression.py
```

Expected: 仍可能因 `cards.csv` 尚未更新失败，其余脚本、状态、卡牌检查通过。

## Task 4: 更新转换器和卡牌台账

**Files:**
- Modify: `external/tools/excel_to_json.py`
- Modify: `external/tools/json_to_excel.py`
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`

- [ ] **Step 1: 更新 action path map**

在 `external/tools/excel_to_json.py` 的 `ACTION_PATHS` 中加入：

```python
        'ActionModifyCurrentCardPlayValues': 'meta_actions',
```

在 `external/tools/json_to_excel.py` 如存在同名 action map，也加入同一项；如果 `json_to_excel.py` 仅输出原始复杂 JSON 字段，无需额外改动。

- [ ] **Step 2: 从 JSON 重新生成 Excel**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 external/tools/json_to_excel.py
```

Expected: `external/config/cards.xlsx` 包含 `card_metronome`、`card_travel_light`、`card_last_item`。

- [ ] **Step 3: 从 Excel 导出 CSV**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -c "import csv; from pathlib import Path; from openpyxl import load_workbook; root=Path('.'); wb=load_workbook(root/'external/config/cards.xlsx', read_only=True, data_only=True); ws=wb['Cards']; out=root/'external/config/cards.csv'; f=out.open('w', encoding='utf-8', newline=''); writer=csv.writer(f); [writer.writerow([cell if cell is not None else '' for cell in row]) for row in ws.iter_rows(values_only=True)]; f.close(); wb.close(); print(out)"
```

Expected: `external/config/cards.csv` 更新。

- [ ] **Step 4: 运行卡牌回归**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_b_regression.py
```

Expected:

```text
validated 21 configurable cards
validated card reference gap B
```

## Task 5: 完整验证和提交

**Files:**
- Modify: `autoload/Scripts.gd`
- Modify: `scripts/actions/status_actions/ActionApplyStatus.gd`
- Create: `scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd`
- Create: `scripts/status_effects/StatusEffectOncePerTurnTrigger.gd`
- Create: `external/data/status_effects/status_effect_metronome.json`
- Create: `external/data/status_effects/status_effect_travel_light.json`
- Create: `external/data/cards/card_metronome.json`
- Create: `external/data/cards/card_travel_light.json`
- Create: `external/data/cards/card_last_item.json`
- Modify: `external/tools/excel_to_json.py`
- Modify: `external/tools/json_to_excel.py`
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`
- Modify: `tests/card_configurable_cards_regression.py`
- Create: `tests/card_reference_gap_b_regression.py`

- [ ] **Step 1: 检查新 JSON 合法性**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/status_effects/status_effect_metronome.json
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/status_effects/status_effect_travel_light.json
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/cards/card_metronome.json
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/cards/card_travel_light.json
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/cards/card_last_item.json
```

Expected: 五条命令均成功输出格式化 JSON。

- [ ] **Step 2: 运行 Python 回归**

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_b_regression.py
```

Expected:

```text
validated 21 configurable cards
validated card reference gap A
validated card reference gap B
```

- [ ] **Step 3: 运行 Godot headless**

```bash
godot --headless --path . --quit
```

Expected: 进程退出码为 0。若输出包含既有资源导入噪声，确认没有出现 B 批新增脚本或卡牌 ID 相关错误。

- [ ] **Step 4: 查看改动范围**

```bash
git status --short
```

Expected: 只包含本计划列出的文件。新卡 JSON 位于忽略目录，提交时需要 `git add -f external/data/cards/card_metronome.json external/data/cards/card_travel_light.json external/data/cards/card_last_item.json`。

- [ ] **Step 5: 提交实现**

```bash
git add autoload/Scripts.gd scripts/actions/status_actions/ActionApplyStatus.gd scripts/actions/meta_actions/ActionModifyCurrentCardPlayValues.gd scripts/status_effects/StatusEffectOncePerTurnTrigger.gd external/data/status_effects/status_effect_metronome.json external/data/status_effects/status_effect_travel_light.json external/tools/excel_to_json.py external/tools/json_to_excel.py external/config/cards.xlsx external/config/cards.csv tests/card_configurable_cards_regression.py tests/card_reference_gap_b_regression.py
git add -f external/data/cards/card_metronome.json external/data/cards/card_travel_light.json external/data/cards/card_last_item.json
git commit -m "Add card reference gap B mechanics"
```

Expected: commit succeeds with only B 批功能和配置文件。

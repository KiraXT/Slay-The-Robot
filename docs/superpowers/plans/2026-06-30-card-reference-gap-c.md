# Card Reference Gap C Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现“下一张符合条件攻击临时增伤”机制，并配置红色 `card_combo_starter` / `连段起手`。

**Architecture:** 复用现有状态效果系统和 `ActionModifyCurrentCardPlayValues`。新增一个监听 `Signals.card_play_started` 的通用状态脚本，只修改当前 `CardPlayRequest.card_values`，并让 `ActionApplyStatus` 在普通叠层状态首次创建时也能传入 `status_custom_values`。

**Tech Stack:** Godot 4 GDScript、JSON 数据配置、Python 回归测试、`external/tools/json_to_excel.py` 台账生成。

---

## 文件结构

- Create: `scripts/status_effects/StatusEffectNextMatchingCardModifier.gd`  
  负责监听下一张符合条件的牌，修改当前出牌请求中的数值，并按配置消耗或回合结束清除状态。
- Modify: `scripts/actions/status_actions/ActionApplyStatus.gd`  
  在非 `status_force_apply_new_effect` 路径下，把 `status_custom_values` 继续传给目标。
- Modify: `scripts/combatants/BaseCombatant.gd`  
  让 `add_status_effect_charges()` 在首次创建普通叠层状态时可以把 custom values 写入状态实例。
- Create: `external/data/status_effects/status_effect_combo_starter.json`  
  可见 buff 状态，引用新状态脚本。
- Create: `external/data/cards/card_combo_starter.json`  
  红色 1 费技能牌，施加 `status_effect_combo_starter`。
- Modify: `tests/card_reference_gap_c_regression.py`  
  新增 C 批结构回归测试。
- Modify: `tests/card_configurable_cards_regression.py`  
  把 `card_combo_starter` 加入可配置卡牌总回归。
- Modify: `external/config/cards.csv` and `external/config/cards.xlsx`  
  由 `external/tools/json_to_excel.py` 从 JSON 生成台账。

---

### Task 1: 写 C 批失败回归测试

**Files:**
- Create: `tests/card_reference_gap_c_regression.py`
- Modify: `tests/card_configurable_cards_regression.py`

- [ ] **Step 1: Create `tests/card_reference_gap_c_regression.py`**

```python
#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
STATUSES = ROOT / "external" / "data" / "status_effects"
CSV_PATH = ROOT / "external" / "config" / "cards.csv"

STATUS_SCRIPT = "res://scripts/status_effects/StatusEffectNextMatchingCardModifier.gd"
APPLY_STATUS_ACTION = "res://scripts/actions/status_actions/ActionApplyStatus.gd"
BASE_COMBATANT = ROOT / "scripts" / "combatants" / "BaseCombatant.gd"


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

    status_script_text = (ROOT / STATUS_SCRIPT.replace("res://", "")).read_text(encoding="utf-8")
    for expected in (
        "Signals.card_play_started.connect(_on_card_play_started)",
        "Signals.player_turn_ended.connect(_on_player_turn_ended)",
        "card_type_filter",
        "value_modifiers",
        "consume_charge_on_trigger",
        "clear_on_player_turn_end",
        "ignore_duplicate_plays",
    ):
        assert expected in status_script_text

    apply_status_text = (ROOT / APPLY_STATUS_ACTION.replace("res://", "")).read_text(encoding="utf-8")
    assert "add_status_effect_charges(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)" in apply_status_text

    base_combatant_text = BASE_COMBATANT.read_text(encoding="utf-8")
    assert "func add_status_effect_charges(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0, custom_values: Dictionary = {})" in base_combatant_text
    assert "_create_status_effect(status_effect_object_id, custom_values)" in base_combatant_text

    combo_status = load_status("status_effect_combo_starter")
    assert combo_status["status_effect_script_path"] == STATUS_SCRIPT
    assert combo_status["status_effect_stacks"] is True
    assert combo_status["status_effect_allows_multiples"] is False
    assert combo_status["status_effect_decay_rate"] == 0

    combo = load_card("card_combo_starter")
    assert combo["card_name"] == "连段起手"
    assert combo["card_type"] == 1
    assert combo["card_color_id"] == "color_red"
    assert combo["card_energy_cost"] == 1
    assert combo["card_requires_target"] is False
    assert combo["card_values"]["damage"] == 3
    assert combo["card_upgrade_value_improvements"]["damage"] == 2

    payloads = find_action_payload(combo, APPLY_STATUS_ACTION)
    assert len(payloads) == 1
    values = payloads[0]
    assert values["target_override"] == 2
    assert values["status_effect_object_id"] == "status_effect_combo_starter"
    assert values["status_charge_amount"] == 1
    assert values.get("status_force_apply_new_effect", False) is False

    custom = values["status_custom_values"]
    assert custom["card_type_filter"] == [0]
    assert custom["value_modifiers"] == {"damage": 3}
    assert custom["consume_charge_on_trigger"] is True
    assert custom["clear_on_player_turn_end"] is True
    assert custom["ignore_duplicate_plays"] is True

    assert csv_ids().count("card_combo_starter") == 1

    print("validated card reference gap C")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Update `tests/card_configurable_cards_regression.py`**

Add `card_combo_starter` to `EXPECTED`:

```python
    "card_combo_starter": "color_red",
```

Add `card_combo_starter` to `REQUIRED_ACTIONS`:

```python
    "card_combo_starter": ["card_play_actions"],
```

- [ ] **Step 3: Run the new test and confirm it fails for the missing implementation**

Run:

```bash
python3 tests/card_reference_gap_c_regression.py
```

Expected: fails with an assertion mentioning `res://scripts/status_effects/StatusEffectNextMatchingCardModifier.gd`.

- [ ] **Step 4: Commit failing tests**

```bash
git add tests/card_reference_gap_c_regression.py tests/card_configurable_cards_regression.py
git commit -m "Add card reference gap C regression tests"
```

---

### Task 2: 让普通叠层状态支持首次 custom values

**Files:**
- Modify: `scripts/actions/status_actions/ActionApplyStatus.gd`
- Modify: `scripts/combatants/BaseCombatant.gd`
- Test: `tests/card_reference_gap_c_regression.py`

- [ ] **Step 1: Modify `ActionApplyStatus.gd`**

Change the non-force branch to pass `status_custom_values`:

```gdscript
		else:
			target.add_status_effect_charges(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)
```

- [ ] **Step 2: Modify `BaseCombatant.gd` signature**

Replace the function signature with:

```gdscript
func add_status_effect_charges(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0, custom_values: Dictionary = {}) -> void:
```

- [ ] **Step 3: Modify first-create path in `BaseCombatant.gd`**

Inside `add_status_effect_charges()`, replace:

```gdscript
		var _status_effect: StatusEffect = _create_status_effect(status_effect_object_id)
```

with:

```gdscript
		var _status_effect: StatusEffect = _create_status_effect(status_effect_object_id, custom_values)
```

- [ ] **Step 4: Run the C test and confirm it still fails only on missing status/card assets**

Run:

```bash
python3 tests/card_reference_gap_c_regression.py
```

Expected: still fails because `StatusEffectNextMatchingCardModifier.gd` or C data JSON does not exist yet; it should no longer fail on the `ActionApplyStatus` or `BaseCombatant` assertions after later assets exist.

- [ ] **Step 5: Commit custom values support**

```bash
git add scripts/actions/status_actions/ActionApplyStatus.gd scripts/combatants/BaseCombatant.gd
git commit -m "Support custom values for stackable status creation"
```

---

### Task 3: 实现下一张匹配牌修正状态脚本

**Files:**
- Create: `scripts/status_effects/StatusEffectNextMatchingCardModifier.gd`
- Test: `tests/card_reference_gap_c_regression.py`

- [ ] **Step 1: Create `StatusEffectNextMatchingCardModifier.gd`**

```gdscript
# Modifies the next matching card play request, then optionally consumes itself.
extends BaseStatusEffect

func _connect_signals() -> void:
	Signals.card_play_started.connect(_on_card_play_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)

func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if parent_combatant == null:
		return
	if not parent_combatant.is_alive():
		return
	if not Global.is_player_turn():
		return
	if card_play_request == null or card_play_request.card_data == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	if not _matches_card(card_play_request.card_data):
		return

	_apply_value_modifiers(card_play_request)

	if bool(status_custom_values.get("consume_charge_on_trigger", true)):
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -1)

func _on_player_turn_ended() -> void:
	if parent_combatant == null:
		return
	if bool(status_custom_values.get("clear_on_player_turn_end", true)) and status_charges != 0:
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -status_charges)

func _matches_card(card_data: CardData) -> bool:
	if card_data == null:
		return false
	if status_custom_values.has("card_object_id_filter"):
		var filter_value: Variant = status_custom_values["card_object_id_filter"]
		if filter_value is Array:
			var accepted_ids: Array[String] = []
			accepted_ids.assign(filter_value)
			if not accepted_ids.has(card_data.object_id):
				return false
		elif card_data.object_id != str(filter_value):
			return false
	if status_custom_values.has("card_type_filter"):
		var type_filter: Variant = status_custom_values["card_type_filter"]
		if type_filter is Array:
			var accepted_types: Array[int] = []
			accepted_types.assign(type_filter)
			if not accepted_types.has(card_data.card_type):
				return false
		elif card_data.card_type != int(type_filter):
			return false
	return true

func _apply_value_modifiers(card_play_request: CardPlayRequest) -> void:
	var value_modifiers: Dictionary = status_custom_values.get("value_modifiers", {})
	for value_key in value_modifiers.keys():
		if not card_play_request.card_values.has(value_key):
			continue
		var existing_value: int = int(card_play_request.card_values[value_key])
		var modifier: int = int(value_modifiers[value_key])
		card_play_request.card_values[value_key] = max(0, existing_value + modifier)
```

- [ ] **Step 2: Run the C test and confirm it now fails on missing JSON data**

Run:

```bash
python3 tests/card_reference_gap_c_regression.py
```

Expected: fails with a missing `status_effect_combo_starter.json` or `card_combo_starter.json` error.

- [ ] **Step 3: Commit status script**

```bash
git add scripts/status_effects/StatusEffectNextMatchingCardModifier.gd
git commit -m "Add next matching card modifier status"
```

---

### Task 4: 添加状态和卡牌 JSON

**Files:**
- Create: `external/data/status_effects/status_effect_combo_starter.json`
- Create: `external/data/cards/card_combo_starter.json`
- Test: `tests/card_reference_gap_c_regression.py`

- [ ] **Step 1: Create `status_effect_combo_starter.json`**

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "status_effect_combo_starter",
        "status_effect_action_process_times": [],
        "status_effect_allows_multiples": false,
        "status_effect_can_be_negative": false,
        "status_effect_decay_rate": 0,
        "status_effect_decay_type": 0,
        "status_effect_enemy_actions": [],
        "status_effect_healthbar_layer_color": "",
        "status_effect_healthbar_reserve_type": 0,
        "status_effect_interceptor_ids": [],
        "status_effect_is_visible": true,
        "status_effect_name": "连段起手",
        "status_effect_negative_charges_texture_path": "",
        "status_effect_player_actions": [],
        "status_effect_priority": 0,
        "status_effect_script_path": "res://scripts/status_effects/StatusEffectNextMatchingCardModifier.gd",
        "status_effect_stacks": true,
        "status_effect_texture_path": "external/sprites/status_effects/status_effect_damage_increase.png",
        "status_effect_type": 0
    }
}
```

- [ ] **Step 2: Create `card_combo_starter.json`**

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_combo_starter",
        "object_uid": "",
        "card_name": "连段起手",
        "card_description": "你的下一张攻击造成额外 [damage] 点伤害。",
        "card_type": 1,
        "card_rarity": 1,
        "card_color_id": "color_red",
        "card_energy_cost": 1,
        "card_energy_cost_is_variable": false,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": false,
        "card_exhausts": false,
        "card_is_ethereal": false,
        "card_is_retained": false,
        "card_appears_in_card_packs": true,
        "card_texture_path": "external/sprites/cards/red/card_red.png",
        "card_keyword_object_ids": [],
        "card_values": {
            "damage": 3
        },
        "card_play_actions": [
            {
                "res://scripts/actions/status_actions/ActionApplyStatus.gd": {
                    "target_override": 2,
                    "status_effect_object_id": "status_effect_combo_starter",
                    "status_charge_amount": 1,
                    "status_custom_values": {
                        "card_type_filter": [
                            0
                        ],
                        "value_modifiers": {
                            "damage": 3
                        },
                        "consume_charge_on_trigger": true,
                        "clear_on_player_turn_end": true,
                        "ignore_duplicate_plays": true
                    }
                }
            }
        ],
        "card_upgrade_value_improvements": {
            "damage": 2
        },
        "card_first_upgrade_property_changes": {},
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 3: Run the C test and confirm only the CSV assertion fails**

Run:

```bash
python3 tests/card_reference_gap_c_regression.py
```

Expected: fails with `card_combo_starter` missing from `cards.csv`.

- [ ] **Step 4: Commit JSON data**

`external/data/cards/*.json` may be ignored, so force-add the card JSON.

```bash
git add external/data/status_effects/status_effect_combo_starter.json
git add -f external/data/cards/card_combo_starter.json
git commit -m "Configure combo starter card data"
```

---

### Task 5: 更新卡牌台账

**Files:**
- Modify: `external/config/cards.csv`
- Modify: `external/config/cards.xlsx`
- Test: `tests/card_reference_gap_c_regression.py`

- [ ] **Step 1: Regenerate card ledger from JSON**

Run:

```bash
python3 external/tools/json_to_excel.py
```

Expected: command completes and updates `external/config/cards.csv` plus `external/config/cards.xlsx`.

- [ ] **Step 2: Run focused C regression**

Run:

```bash
python3 tests/card_reference_gap_c_regression.py
```

Expected:

```text
validated card reference gap C
```

- [ ] **Step 3: Run configurable card regression**

Run:

```bash
python3 tests/card_configurable_cards_regression.py
```

Expected:

```text
validated 22 configurable cards
```

- [ ] **Step 4: Commit ledger updates**

```bash
git add external/config/cards.csv external/config/cards.xlsx
git commit -m "Update card ledger for combo starter"
```

---

### Task 6: 全量验证和收尾

**Files:**
- Validate working tree and all C batch changes.

- [ ] **Step 1: Run all card reference regressions**

Run:

```bash
python3 tests/card_configurable_cards_regression.py
python3 tests/card_reference_gap_a_regression.py
python3 tests/card_reference_gap_b_regression.py
python3 tests/card_reference_gap_c_regression.py
```

Expected:

```text
validated 22 configurable cards
validated card reference gap A
validated card reference gap B
validated card reference gap C
```

- [ ] **Step 2: Run Godot headless load check**

Run:

```bash
godot --headless --path . --quit
```

Expected: process exits with code 0. Existing baseline resource warnings are acceptable only if they do not mention `card_combo_starter`, `status_effect_combo_starter`, or `StatusEffectNextMatchingCardModifier`.

- [ ] **Step 3: Check whitespace and status**

Run:

```bash
git diff --check
git status --short
```

Expected: `git diff --check` has no output. `git status --short` is clean.

- [ ] **Step 4: If verification requires a final fix, commit the C batch files explicitly**

Use this only if Step 1-3 find a small issue:

```bash
git add scripts/actions/status_actions/ActionApplyStatus.gd scripts/combatants/BaseCombatant.gd scripts/status_effects/StatusEffectNextMatchingCardModifier.gd tests/card_reference_gap_c_regression.py tests/card_configurable_cards_regression.py external/data/status_effects/status_effect_combo_starter.json external/config/cards.csv external/config/cards.xlsx
git add -f external/data/cards/card_combo_starter.json
git commit -m "Fix combo starter verification issue"
```

Expected: one focused fix commit, then rerun Step 1-3.

---

## Plan Self-Review

- Spec coverage: status script, status JSON, card JSON, custom value data path, tests, CSV/XLSX台账和 Godot 验证均已覆盖。
- Scope check: 不做费用降低、`准备姿态`、`背包整理`、`夹好书签`，符合 C 批设计边界。
- Completeness scan: 本计划没有未决空项；所有新增文件都有完整内容。
- Type consistency: `card_type_filter` 使用 `CardData.CARD_TYPES.ATTACK = 0`，`target_override = 2` 沿用现有玩家目标配置，`value_modifiers.damage` 对应 `card_values.damage`。

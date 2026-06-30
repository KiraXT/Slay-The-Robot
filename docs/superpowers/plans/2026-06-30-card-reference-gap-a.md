# 卡牌参考缺口 A 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补齐 Card Development Reference 第一批低风险缺口：上一张牌校验、按目标腐蚀层数缩放伤害、复杂卡牌字段从 Excel 回写 JSON，并配置三张新卡。

**Architecture:** 本轮沿用现有数据驱动架构。新增脚本保持小边界：一个 card-play validator、一个 meta action、一个 Python 转换器增强；卡牌仍通过 `external/data/cards/*.json` 配置，脚本路径同步加入 `autoload/Scripts.gd`。

**Tech Stack:** Godot 4 / GDScript、JSON card resources、Python 3、pandas/openpyxl、现有 Python/Godot 回归脚本。

---

## 文件结构

- Modify: `tests/card_configurable_cards_regression.py`
  - 将 `card_pursuit`、`card_echo_shield`、`card_finale_burst` 加入卡牌配置回归。
  - 校验新增脚本路径存在。
  - 校验 `card_finale_burst` 使用腐蚀层数缩放 action。
- Create: `tests/card_reference_gap_a_regression.py`
  - 用轻量文本/JSON 检查覆盖新 validator、新 action 和 Excel JSON 字段透传。
- Modify: `autoload/Scripts.gd`
  - 增加 `ACTION_TARGET_STATUS_VALUE_MODIFIER`。
  - 增加 `VALIDATOR_PREVIOUS_CARD`。
- Create: `scripts/validators/card_plays/ValidatorPreviousCard.gd`
  - 读取 `Global.get_combat_stats().cards_played_this_turn`，判断当前牌之前的上一张牌。
- Create: `scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd`
  - 对每个目标读取目标状态层数，修改子 action 参数后生成子 action。
- Modify: `external/tools/excel_to_json.py`
  - 支持 `*_json` 复杂字段列。
  - 将新 action 加入 action path map。
- Modify: `external/tools/json_to_excel.py`
  - 输出 `*_json` 复杂字段列，保证 ledger 能记录复杂配置。
  - 将新 action 加入 action path map。
- Create: `external/data/cards/card_pursuit.json`
- Create: `external/data/cards/card_echo_shield.json`
- Create: `external/data/cards/card_finale_burst.json`
- Modify: `external/config/cards.xlsx`
  - 通过 `json_to_excel.py` 从 JSON 重新生成，包含三张新卡 ledger。
- Modify: `external/config/cards.csv`
  - 从 workbook 导出 UTF-8 CSV。

## Task 1: 增加失败回归检查

**Files:**
- Modify: `tests/card_configurable_cards_regression.py`
- Create: `tests/card_reference_gap_a_regression.py`

- [ ] **Step 1: 扩展卡牌配置回归**

在 `tests/card_configurable_cards_regression.py` 的 `EXPECTED` 中加入：

```python
    "card_pursuit": "color_red",
    "card_echo_shield": "color_green",
    "card_finale_burst": "color_green",
```

在 `REQUIRED_ACTIONS` 中加入：

```python
    "card_pursuit": ["card_play_actions"],
    "card_echo_shield": ["card_play_actions"],
    "card_finale_burst": ["card_play_actions"],
```

- [ ] **Step 2: 新增缺口 A 专项回归**

创建 `tests/card_reference_gap_a_regression.py`：

```python
#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"
EXCEL_TO_JSON = ROOT / "external" / "tools" / "excel_to_json.py"
JSON_TO_EXCEL = ROOT / "external" / "tools" / "json_to_excel.py"

ACTION_PATH = "res://scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd"
VALIDATOR_PATH = "res://scripts/validators/card_plays/ValidatorPreviousCard.gd"


def load_card(card_id: str) -> dict:
    with (CARDS / f"{card_id}.json").open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]


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


def main() -> None:
    assert_path_exists(ACTION_PATH)
    assert_path_exists(VALIDATOR_PATH)

    pursuit = load_card("card_pursuit")
    assert any(key == VALIDATOR_PATH for key, _ in walk(pursuit["card_play_actions"]))
    assert "draw_count" in pursuit["card_values"]

    echo_shield = load_card("card_echo_shield")
    assert any(key == VALIDATOR_PATH for key, _ in walk(echo_shield["card_play_actions"]))
    assert "bonus_block" in echo_shield["card_values"]

    finale_burst = load_card("card_finale_burst")
    action_payloads = [child for key, child in walk(finale_burst["card_play_actions"]) if key == ACTION_PATH]
    assert len(action_payloads) == 1
    payload = action_payloads[0]
    assert payload["status_effect_object_id"] == "status_effect_corrosion"
    assert payload["charge_key"] == "status_charges"
    assert payload["value_key"] == "damage"
    assert payload["operation"] == "add"

    excel_to_json_text = EXCEL_TO_JSON.read_text(encoding="utf-8")
    json_to_excel_text = JSON_TO_EXCEL.read_text(encoding="utf-8")
    for column in (
        "card_values_json",
        "card_play_actions_json",
        "card_draw_actions_json",
        "card_discard_actions_json",
        "card_retain_actions_json",
        "card_listeners_json",
    ):
        assert column in excel_to_json_text
        assert column in json_to_excel_text

    print("validated card reference gap A")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: 运行回归并确认失败**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected: 第一条命令因缺少 `card_pursuit.json` 失败；第二条命令因缺少新脚本失败。

## Task 2: 实现上一张牌校验

**Files:**
- Modify: `autoload/Scripts.gd`
- Create: `scripts/validators/card_plays/ValidatorPreviousCard.gd`

- [ ] **Step 1: 添加脚本常量**

在 `autoload/Scripts.gd` 的 card play validators 区域加入：

```gdscript
const VALIDATOR_PREVIOUS_CARD: String = "res://scripts/validators/card_plays/ValidatorPreviousCard.gd"
```

- [ ] **Step 2: 添加 validator 实现**

创建 `scripts/validators/card_plays/ValidatorPreviousCard.gd`：

```gdscript
# Validator for checking the card played immediately before the current card this turn.
extends BaseValidator

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
    var card_play_request: CardPlayRequest = null
    if action != null:
        card_play_request = action.card_play_request

    var combat_stats_data: CombatStatsData = Global.get_combat_stats()
    if combat_stats_data == null:
        return false != _get_bool(values, "invert", false)

    var previous_card: CardData = _get_previous_card(combat_stats_data, card_play_request)
    var must_exist: bool = _get_bool(values, "must_exist", true)
    if previous_card == null:
        return (not must_exist) != _get_bool(values, "invert", false)

    var matches: bool = true
    if values.has("card_type"):
        matches = matches and previous_card.card_type == int(values["card_type"])
    if values.has("card_object_id"):
        matches = matches and previous_card.object_id == str(values["card_object_id"])
    if values.has("card_tag"):
        matches = matches and previous_card.card_tags.has(str(values["card_tag"]))

    return matches != _get_bool(values, "invert", false)

func _get_previous_card(combat_stats_data: CombatStatsData, current_request: CardPlayRequest) -> CardData:
    for index in range(combat_stats_data.cards_played_this_turn.size() - 1, -1, -1):
        var request: CardPlayRequest = combat_stats_data.cards_played_this_turn[index]
        if request == current_request:
            continue
        if request.card_data != null:
            return request.card_data
    return null

func _get_bool(values: Dictionary[String, Variant], key: String, default_value: bool) -> bool:
    if not values.has(key):
        return default_value
    var value: Variant = values[key]
    if value is bool:
        return value
    if value is String:
        return value.to_lower() in ["true", "yes", "1"]
    return bool(value)
```

- [ ] **Step 3: 运行专项回归**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected: 仍失败，因为 `ActionTargetStatusValueModifier.gd` 和卡牌尚未存在。

## Task 3: 实现目标状态层数缩放 action

**Files:**
- Modify: `autoload/Scripts.gd`
- Create: `scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd`
- Modify: `external/tools/excel_to_json.py`
- Modify: `external/tools/json_to_excel.py`

- [ ] **Step 1: 添加 action 常量**

在 `autoload/Scripts.gd` 的 meta actions 区域加入：

```gdscript
const ACTION_TARGET_STATUS_VALUE_MODIFIER: String = "res://scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd"
```

- [ ] **Step 2: 添加 action 实现**

创建 `scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd`：

```gdscript
# Wraps child actions and adjusts one child value from each target's status charges.
extends BaseAction

func is_instant_action() -> bool:
    return true

func perform_action() -> void:
    var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()

    for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
        var target: BaseCombatant = action_interceptor_processor.target
        if target == null:
            continue

        var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values("status_effect_object_id", "")
        var charge_key: String = action_interceptor_processor.get_shadowed_action_values("charge_key", "status_charges")
        var multiplier: int = action_interceptor_processor.get_shadowed_action_values("multiplier", 1)
        var value_key: String = action_interceptor_processor.get_shadowed_action_values("value_key", "damage")
        var operation: String = action_interceptor_processor.get_shadowed_action_values("operation", "add")
        var default_value: int = action_interceptor_processor.get_shadowed_action_values("default_value", 0)
        var action_data: Array = action_interceptor_processor.get_shadowed_action_values("action_data", [])

        if status_effect_object_id == "" or action_data.is_empty():
            push_error("ActionTargetStatusValueModifier requires status_effect_object_id and action_data")
            continue

        var status_value: int = _get_status_value(target, status_effect_object_id, charge_key, default_value)
        var scaled_value: int = status_value * multiplier
        var modified_action_data: Array[Dictionary] = _build_modified_action_data(action_data, value_key, scaled_value, operation)
        var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [target], modified_action_data, self)
        ActionHandler.add_actions(generated_actions)

func _get_status_value(target: BaseCombatant, status_effect_object_id: String, charge_key: String, default_value: int) -> int:
    var status_effects: Array = target.status_id_to_status_effects.get(status_effect_object_id, [])
    if status_effects.is_empty():
        return default_value

    var selected_value: int = default_value
    for item in status_effects:
        var status_effect: StatusEffect = item
        var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
        var current_value: int = default_value
        match charge_key:
            "status_secondary_charges":
                current_value = status_effect_script.status_secondary_charges
            _:
                current_value = status_effect_script.status_charges
        if abs(current_value) > abs(selected_value):
            selected_value = current_value
    return selected_value

func _build_modified_action_data(action_data: Array, value_key: String, scaled_value: int, operation: String) -> Array[Dictionary]:
    var modified_action_data: Array[Dictionary] = []
    for action_definition in action_data.duplicate(true):
        for action_script_path in action_definition:
            var action_values: Dictionary = action_definition[action_script_path]
            var existing_value: int = int(action_values.get(value_key, 0))
            if operation == "set":
                action_values[value_key] = scaled_value
            else:
                action_values[value_key] = existing_value + scaled_value
        modified_action_data.append(action_definition)
    return modified_action_data
```

- [ ] **Step 3: 将新 action 加入转换器路径表**

在 `external/tools/excel_to_json.py` 与 `external/tools/json_to_excel.py` 的 `ACTION_PATHS` 中加入：

```python
        'ActionTargetStatusValueModifier': 'meta_actions',
```

- [ ] **Step 4: 运行专项回归**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected: 仍失败，因为 Excel JSON 字段和卡牌尚未完成。

## Task 4: 扩展 Excel/JSON 复杂字段透传

**Files:**
- Modify: `external/tools/excel_to_json.py`
- Modify: `external/tools/json_to_excel.py`

- [ ] **Step 1: 在 `excel_to_json.py` 添加复杂字段映射**

在 `CardConverter` 类中加入：

```python
    COMPLEX_JSON_COLUMNS = {
        "card_values_json": "card_values",
        "card_play_actions_json": "card_play_actions",
        "card_draw_actions_json": "card_draw_actions",
        "card_discard_actions_json": "card_discard_actions",
        "card_retain_actions_json": "card_retain_actions",
        "card_listeners_json": "card_listeners",
    }
```

并添加方法：

```python
    def _parse_complex_json_column(self, row: pd.Series, column: str, card_id: str) -> Optional[Any]:
        if column not in row or pd.isna(row[column]):
            return None
        text = str(row[column]).strip()
        if text == "" or text.lower() == "nan":
            return None
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{card_id} {column} contains invalid JSON: {exc}") from exc
```

在 `_build_card_json()` 创建 `json_data` 后加入：

```python
        properties = json_data["properties"]
        for column, property_name in self.COMPLEX_JSON_COLUMNS.items():
            parsed_value = self._parse_complex_json_column(row, column, card_id)
            if parsed_value is not None:
                properties[property_name] = parsed_value
```

- [ ] **Step 2: 在 `json_to_excel.py` 输出复杂字段列**

在 `convert_cards()` 的 `columns` 列表末尾加入：

```python
        'card_values_json', 'card_play_actions_json', 'card_draw_actions_json',
        'card_discard_actions_json', 'card_retain_actions_json', 'card_listeners_json',
```

在每张卡 `row` 填充时加入：

```python
        row['card_values_json'] = format_dialogue_action_payload(card.get('card_values', {}))
        row['card_play_actions_json'] = format_dialogue_action_payload(card.get('card_play_actions', []))
        row['card_draw_actions_json'] = format_dialogue_action_payload(card.get('card_draw_actions', []))
        row['card_discard_actions_json'] = format_dialogue_action_payload(card.get('card_discard_actions', []))
        row['card_retain_actions_json'] = format_dialogue_action_payload(card.get('card_retain_actions', []))
        row['card_listeners_json'] = format_dialogue_action_payload(card.get('card_listeners', []))
```

- [ ] **Step 3: 运行专项回归**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected: 仍失败，因为三张卡牌 JSON 尚未创建。

## Task 5: 配置三张新卡

**Files:**
- Create: `external/data/cards/card_pursuit.json`
- Create: `external/data/cards/card_echo_shield.json`
- Create: `external/data/cards/card_finale_burst.json`

- [ ] **Step 1: 创建红色 `card_pursuit`**

创建 `external/data/cards/card_pursuit.json`，核心配置：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_pursuit",
        "object_uid": "",
        "card_name": "追击",
        "card_description": "造成 [damage] 点伤害。若上一张牌是攻击，抽 [draw_count] 张牌。",
        "card_type": 0,
        "card_rarity": 1,
        "card_color_id": "color_red",
        "card_energy_cost": 1,
        "card_energy_cost_is_variable": false,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": true,
        "card_exhausts": false,
        "card_is_ethereal": false,
        "card_is_retained": false,
        "card_appears_in_card_packs": true,
        "card_texture_path": "external/sprites/cards/red/card_red.png",
        "card_keyword_object_ids": [],
        "card_values": {
            "damage": 6,
            "number_of_attacks": 1,
            "draw_count": 1
        },
        "card_play_actions": [
            {
                "res://scripts/actions/meta_actions/ActionAttackGenerator.gd": {
                    "time_delay": 0.0,
                    "actions_on_lethal": []
                }
            },
            {
                "res://scripts/actions/meta_actions/ActionValidator.gd": {
                    "validator_data": [
                        {
                            "res://scripts/validators/card_plays/ValidatorPreviousCard.gd": {
                                "card_type": 0
                            }
                        }
                    ],
                    "passed_action_data": [
                        {
                            "res://scripts/actions/meta_actions/ActionDrawGenerator.gd": {
                                "draw_count": 1
                            }
                        }
                    ],
                    "failed_action_data": []
                }
            }
        ],
        "card_upgrade_value_improvements": {
            "damage": 3
        },
        "card_first_upgrade_property_changes": {},
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 2: 创建绿色 `card_echo_shield`**

创建 `external/data/cards/card_echo_shield.json`，核心配置：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_echo_shield",
        "object_uid": "",
        "card_name": "回声护盾",
        "card_description": "获得 [block] 点格挡。若上一张牌也是技能，额外获得 [bonus_block] 点格挡。",
        "card_type": 1,
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
        "card_keyword_object_ids": ["keyword_block"],
        "card_values": {
            "block": 7,
            "bonus_block": 6
        },
        "card_play_actions": [
            {
                "res://scripts/actions/ActionBlock.gd": {
                    "block": 7,
                    "time_delay": 0.5,
                    "target_override": 1
                }
            },
            {
                "res://scripts/actions/meta_actions/ActionValidator.gd": {
                    "validator_data": [
                        {
                            "res://scripts/validators/card_plays/ValidatorPreviousCard.gd": {
                                "card_type": 1
                            }
                        }
                    ],
                    "passed_action_data": [
                        {
                            "res://scripts/actions/ActionBlock.gd": {
                                "block": 6,
                                "time_delay": 0.5,
                                "target_override": 1
                            }
                        }
                    ],
                    "failed_action_data": []
                }
            }
        ],
        "card_upgrade_value_improvements": {
            "block": 3,
            "bonus_block": 2
        },
        "card_first_upgrade_property_changes": {},
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 3: 创建绿色 `card_finale_burst`**

创建 `external/data/cards/card_finale_burst.json`，核心配置：

```json
{
    "patch_data": {},
    "properties": {
        "object_id": "card_finale_burst",
        "object_uid": "",
        "card_name": "终场爆音",
        "card_description": "造成 [damage] 点伤害。目标每有1层腐蚀，额外造成 [corrosion_damage_multiplier] 点伤害。",
        "card_type": 0,
        "card_rarity": 3,
        "card_color_id": "color_green",
        "card_energy_cost": 2,
        "card_energy_cost_is_variable": false,
        "card_energy_cost_variable_upper_bound": -1,
        "card_requires_target": true,
        "card_exhausts": false,
        "card_is_ethereal": false,
        "card_is_retained": false,
        "card_appears_in_card_packs": true,
        "card_texture_path": "external/sprites/cards/green/card_green.png",
        "card_keyword_object_ids": ["keyword_corrosion"],
        "card_values": {
            "damage": 8,
            "corrosion_damage_multiplier": 2,
            "number_of_attacks": 1
        },
        "card_play_actions": [
            {
                "res://scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd": {
                    "status_effect_object_id": "status_effect_corrosion",
                    "charge_key": "status_charges",
                    "multiplier": 2,
                    "value_key": "damage",
                    "operation": "add",
                    "default_value": 0,
                    "action_data": [
                        {
                            "res://scripts/actions/meta_actions/ActionAttackGenerator.gd": {
                                "damage": 8,
                                "number_of_attacks": 1,
                                "time_delay": 0.0,
                                "actions_on_lethal": []
                            }
                        }
                    ]
                }
            }
        ],
        "card_upgrade_value_improvements": {
            "damage": 3
        },
        "card_first_upgrade_property_changes": {},
        "card_upgrade_amount": 0,
        "card_upgrade_amount_max": 1,
        "card_first_shuffle_priority": 0
    }
}
```

- [ ] **Step 4: 运行卡牌回归**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected: 两条命令通过。

## Task 6: 更新 Excel/CSV 台账

**Files:**
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`

- [ ] **Step 1: 从 JSON 重新生成 Excel**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 external/tools/json_to_excel.py
```

Expected: `external/config/cards.xlsx` 包含 `card_pursuit`、`card_echo_shield`、`card_finale_burst`。

- [ ] **Step 2: 从 Excel 导出 CSV**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -c "import csv; from pathlib import Path; from openpyxl import load_workbook; root=Path('.'); wb=load_workbook(root/'external/config/cards.xlsx', read_only=True, data_only=True); ws=wb['Cards']; out=root/'external/config/cards.csv'; f=out.open('w', encoding='utf-8', newline=''); writer=csv.writer(f); [writer.writerow([cell if cell is not None else '' for cell in row]) for row in ws.iter_rows(values_only=True)]; f.close(); wb.close(); print(out)"
```

Expected: `external/config/cards.csv` 更新，且三张新卡各出现一次。

- [ ] **Step 3: 再跑卡牌回归**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
```

Expected: 通过，输出包含 `validated 18 configurable cards`。

## Task 7: 完整验证与整理

**Files:**
- No additional files.

- [ ] **Step 1: JSON 合法性检查**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/cards/card_pursuit.json
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/cards/card_echo_shield.json
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m json.tool external/data/cards/card_finale_burst.json
```

Expected: 三条命令均成功输出格式化 JSON。

- [ ] **Step 2: Python 回归检查**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_reference_gap_a_regression.py
```

Expected: 两条命令通过。

- [ ] **Step 3: Godot headless 加载**

Run:

```bash
godot --headless --path . --quit
```

Expected: 项目能无错误加载退出。

- [ ] **Step 4: 查看本轮改动**

Run:

```bash
git status --short
git diff -- tests/card_configurable_cards_regression.py tests/card_reference_gap_a_regression.py autoload/Scripts.gd scripts/validators/card_plays/ValidatorPreviousCard.gd scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd external/tools/excel_to_json.py external/tools/json_to_excel.py external/data/cards/card_pursuit.json external/data/cards/card_echo_shield.json external/data/cards/card_finale_burst.json external/config/cards.xlsx external/config/cards.csv docs/superpowers/plans/2026-06-30-card-reference-gap-a.md
```

Expected: 只评估本轮相关文件；工作区中既有的其他未提交改动不回滚、不整理。

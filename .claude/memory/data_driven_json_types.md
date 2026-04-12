---
name: Godot JSON 数据类型问题
description: 关于 Excel/CSV 转 JSON 过程中的类型转换注意事项
type: project
---

## 关键问题

Godot 的 GDScript 对 JSON 中的数值类型有严格要求，特别是枚举相关的字段。

### 字段类型映射

| 字段名 | 期望类型 | 常见问题 |
|--------|----------|----------|
| `target_override` | `int` | 字符串枚举值或浮点数会导致类型错误 |
| `stat_enum` | `int` | 浮点数会导致类型错误 |
| `card_type` | `int` | - |
| `card_rarity` | `int` | - |
| `card_energy_cost*` | `int` | - |

### target_override 枚举映射

```python
TARGET_OVERRIDES_MAP = {
    'BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS': 0,
    'BaseAction.TARGET_OVERRIDES.PARENT': 1,           # 对自己使用
    'BaseAction.TARGET_OVERRIDES.PLAYER': 2,           # 对玩家使用
    'BaseAction.TARGET_OVERRIDES.ALL_COMBATANTS': 3,
    'BaseAction.TARGET_OVERRIDES.ALL_ENEMIES': 4,
    'BaseAction.TARGET_OVERRIDES.LEFTMOST_ENEMY': 5,
    'BaseAction.TARGET_OVERRIDES.ENEMY_ID': 6,
    'BaseAction.TARGET_OVERRIDES.RANDOM_ENEMY': 7,
}
```

### 受影响的数据目录

- `external/data/cards/` - 卡牌配置
- `external/data/artifacts/` - 遗物配置
- `external/data/events/` - 事件配置
- `external/data/enemies/` - 敌人配置
- `external/data/consumables/` - 消耗品配置
- `external/data/status_effects/` - 状态效果配置

### 转换器要求

所有转换器（csv_to_json.py, excel_to_json.py 等）必须：

1. **处理字符串枚举值**：将 `BaseAction.TARGET_OVERRIDES.*` 转换为对应整数
2. **处理浮点数**：将所有整数字段从浮点数（如 `2.0`）转换为整数（如 `2`）
3. **统一处理**：在 `_parse_actions()` 等方法中统一应用这些转换

### 错误示例

```json
// 错误 - 字符串枚举
"target_override": "BaseAction.TARGET_OVERRIDES.PARENT"

// 错误 - 浮点数
"target_override": 2.0

// 正确
"target_override": 1
```

### 修复工具

- `external/tools/fix_target_override.py` - 修复字符串枚举值
- `external/tools/fix_number_types.py` - 修复数值类型
- `external/tools/fix_float_numbers.py` - 批量修复所有浮点数问题

**Why:** 2026-04-12 开发过程中发现类型错误导致卡牌无法使用
**How to apply:** 在添加新的转换功能或修复数据时，确保整数字段正确处理，必要时运行修复脚本

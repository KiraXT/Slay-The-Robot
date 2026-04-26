# Slay the Robot - 配置与逻辑系统参考文档

本文档汇总了游戏的核心配置方式、Action 逻辑系统以及各数据类型（敌人、卡牌、遗物、事件）的配置方法，同时包含 Excel 转 JSON 的配置管道说明。

---

## 1. 敌人配置与行为逻辑

### 1.1 配置文件位置

敌人配置位于 `external/data/enemies/*.json`，通过 `Global.SCHEMA` 映射为 `EnemyData` 原型数据，由 `FileLoader` 在游戏启动时自动加载到 `Global._id_to_enemy_data` 中。

### 1.2 核心数据结构 (`EnemyData`)

| 字段 | 作用 |
|------|------|
| `enemy_attack_states` | **行为状态机**。定义敌人的攻击/防御模式。 |
| `enemy_initial_status_effects` | 战斗开始时给敌人附加的状态效果。 |
| `enemy_actions_on_death` | 敌人死亡时执行的 action 数组。 |
| `enemy_difficulty_to_enemy_modfiers` | 按难度层覆盖属性（如血量、甚至整个 attack_states）。 |
| `enemy_type` | `STANDARD` (0) / `MINIBOSS` (1) / `BOSS` (2) |
| `enemy_is_minion` | 是否为杂兵（不影响战斗结束判定）。 |

### 1.3 敌人行为状态机 (`enemy_attack_states`)

每个状态是一个字典，包含：

- `attack_damage`：单次攻击伤害
- `number_of_attacks`：攻击次数
- `block`：获得格挡值
- `custom_actions`：额外自定义 action 数组（可调用任意 action 脚本）
- `next_attack_weights`：加权随机选择下一个状态的映射

**特殊状态 `initial`**：战斗开始/敌人回合开始时的"过渡态"，只用于通过 `next_attack_weights` 随机决定第一次实际攻击状态。

### 1.4 运行时流程

1. **玩家回合开始时**，调用 `cycle_enemy_intent()`
2. 敌人执行 `cycle_next_attack_state()`，根据当前状态的 `next_attack_weights` 随机选下一个状态
3. `update_enemy_intent()` 读取当前状态的伤害/攻击次数/格挡，并显示意图图标
4. **敌人回合时**，系统根据当前状态执行攻击和 `custom_actions`

### 1.5 示例：Act 1 Boss (`enemy_act_1_boss_1.json`)

```json
{
    "enemy_attack_states": {
        "initial": {
            "next_attack_weights": {"1": 1.0}
        },
        "1": {
            "attack_damage": 0,
            "block": 0,
            "custom_actions": [{
                "res://scripts/actions/ActionSummonEnemies.gd": {
                    "number_of_spawns": 2,
                    "random_enemy_object_ids": ["enemy_minion_1", "enemy_minion_2"]
                }
            }],
            "next_attack_weights": {"2": 1.0}
        },
        "2": {
            "attack_damage": 3,
            "block": 7,
            "number_of_attacks": 2,
            "next_attack_weights": {"2": 1.0}
        }
    }
}
```

- `initial` → 状态 `1`（100%）
- 状态 `1`：召唤 2 个小怪，然后进入状态 `2`
- 状态 `2`：伤害 3，攻击 2 次，获得 7 格挡，循环自身

---

## 2. Action 逻辑系统

### 2.1 核心概念

整个游戏的逻辑统一基于 **Action 管道系统**：

| 组件 | 作用 | 关键文件 |
|------|------|----------|
| **BaseAction** | 所有可执行逻辑的最小单元 | `scripts/actions/BaseAction.gd` |
| **ActionGenerator** | 从 JSON 配置创建 action 实例 | `autoload/ActionGenerator.gd` |
| **ActionHandler** | 将 action 按顺序压入栈并执行 | `autoload/ActionHandler.gd` |
| **Interceptor** | 在 action 执行前拦截修改（如易伤、虚弱、重复攻击） | `scripts/action_interceptors/` |
| **Validator** | 判定条件是否满足（如卡牌可打出、遗物可右键） | `scripts/validators/` |

### 2.2 JSON 中的 Action 格式

所有配置中的 action 都使用统一格式：

```json
[
    {
        "res://scripts/actions/xxx/ActionName.gd": {
            "param1": value1,
            "param2": value2
        }
    }
]
```

### 2.3 目标选择机制 (`target_override`)

所有 action 都支持 `target_override` 参数，目前有 8 种：

| 值 | 枚举名 | 效果 |
|----|--------|------|
| 0 | `SELECTED_TARGETS` | 默认，使用玩家选中的目标 |
| 1 | `PARENT` | 执行者自己 |
| 2 | `PLAYER` | 玩家角色 |
| 3 | `ALL_COMBATANTS` | 所有存活角色 |
| 4 | `ALL_ENEMIES` | 所有存活敌人 |
| 5 | `LEFTMOST_ENEMY` | 最左侧敌人 |
| 6 | `ENEMY_ID` | 指定 `enemy_ids` 的敌人 |
| 7 | `RANDOM_ENEMY` | 随机敌人 |

### 2.4 目前支持的 Action 分类

#### 基础战斗
- `ActionBlock` - 获得格挡
- `ActionDirectDamage` - 直接伤害
- `ActionAddEnergy` - 增加能量
- `ActionApplyStatus` / `ActionDecayStatus` - 施加/衰减状态
- `ActionSummonEnemies` - 召唤敌人
- `ActionEndTurn` - 结束回合
- `ActionReshuffle` - 重新洗牌
- `ActionResetBlock` - 重置格挡

#### 攻击/抽牌生成器（Meta）
- `ActionAttackGenerator` → 生成 `ActionAttack`
  - 支持 `damage_random`, `merge_attacks`, `actions_on_lethal`
- `ActionDrawGenerator` → 生成 `ActionDraw`
  - 支持 `is_start_of_turn_draw` 标记

#### 卡牌集操作 (Cardset)
- `ActionAddCardsToHand` / `ActionAddCardsToDraw` / `ActionAddCardsToDeck`
- `ActionDiscardCards` / `ActionExhaustCards` / `ActionBanishCards`
- `ActionUpgradeCards` / `ActionTransformCards` / `ActionRemoveCardsFromDeck`
- `ActionChangeCardEnergies` / `ActionChangeCardProperties`
- `ActionRetainCards` / `ActionPlayCards` / `ActionAttachCardsOntoEnemy`

#### 玩家资源
- `ActionAddHealth` / `ActionHealPercent`
- `ActionAddMoney` / `ActionAddArtifact` / `ActionAddConsumable`
- `ActionUseConsumable` / `ActionSwapBossArtifact`

#### 世界/地图/战斗
- `ActionVisitLocation` / `ActionStartCombat` / `ActionOpenChest`
- `ActionGenerateAct`

#### 商店/奖励
- `ActionShopPopulateItems` / `ActionShopPurchaseItems`
- `ActionGrantRewards` / `ActionClearRewards`

#### 遗物相关
- `ActionIncreaseArtifactCharge` - 增加遗物充能

#### 敌人相关
- `ActionCycleEnemyIntent` - 切换敌人意图

#### 选择/创建卡牌（异步）
- `ActionPickCards` / `ActionPickUpgradeCards` / `ActionCreateCards`

#### Meta / 修饰
- `ActionVariableCostModifier` / `ActionVariableCardsetModifier` / `ActionVariableCombatStatsModifier`
- `ActionValidator` - 条件验证分支
- `ActionEmitCustomSignal` - 发射自定义信号

完整路径常量定义在 `autoload/Scripts.gd` 中。

---

## 3. 各配置中的操作方式

### 3.1 卡牌配置 (`external/data/cards/*.json`)

| 字段 | 触发时机 |
|------|---------|
| `card_play_actions` | 打出时（核心逻辑） |
| `card_discard_actions` | 手动丢弃时 |
| `card_exhaust_actions` | 被消耗时 |
| `card_draw_actions` | 抽到手牌时 |
| `card_end_of_turn_actions` | 回合结束时在手牌中 |
| `card_retain_actions` | 保留在手牌中时 |
| `card_right_click_actions` | 右键点击时 |
| `card_initial_combat_actions` | 战斗开始时（牌在卡组中） |
| `card_add_to_deck_actions` | 加入永久卡组时 |
| `card_remove_from_deck_actions` | 从永久卡组移除时 |
| `card_transform_in_deck_actions` | 在卡组中被转化时 |
| `card_play_validators` | 可打出条件验证 |
| `card_glow_validators` | 高亮条件验证 |
| `card_listeners` | 附加监听器（费用/数值修饰） |

**示例** (`card_attack_basic.json`):
```json
"card_play_actions": [
    {
        "res://scripts/actions/meta_actions/ActionAttackGenerator.gd": {
            "time_delay": 0.0,
            "actions_on_lethal": []
        }
    }
]
```

### 3.2 遗物配置 (`external/data/artifacts/*.json`)

遗物支持**纯数据配置**和**自定义脚本**两种模式。

| 字段 | 触发时机 |
|------|---------|
| `artifact_add_actions` | 获得遗物时 |
| `artifact_remove_actions` | 移除遗物时 |
| `artifact_turn_start_actions` | 玩家回合开始时 |
| `artifact_turn_end_actions` | 玩家回合结束时 |
| `artifact_first_turn_actions` | 第一场战斗的第一回合 |
| `artifact_end_of_combat_actions` | 战斗结束时 |
| `artifact_max_counter_actions` | 充能计数器满时 |
| `artifact_right_click_actions` | 右键点击时 |
| `artifact_right_click_validators` | 右键可用条件 |
| `artifact_script_path` | 自定义逻辑脚本路径（可选） |

**纯数据示例** (`artifact_block_on_attacks.json`):
```json
"artifact_counter_max": 3,
"artifact_counter_wraparound": true,
"artifact_max_counter_actions": [
    {"res://scripts/actions/ActionBlock.gd": {"block": 5}}
]
```

**自定义脚本示例** (`artifact_draw_on_kill.json`):
```json
"artifact_script_path": "res://scripts/artifacts/ArtifactDrawOnKill.gd"
```

### 3.3 事件配置 (`external/data/events/*.json`)

事件主要用于定义**战斗遭遇**和世界节点。

| 字段 | 作用 |
|------|------|
| `event_weighted_enemy_object_ids` | 按槽位配置敌人出现的加权随机池 |
| `event_enemy_placement_is_automatic` | 是否自动摆放敌人 |
| `event_enemy_placement_positions` | 敌人相对坐标数组 |
| `event_initial_combat_actions` | 战斗开始时执行的 action 数组 |
| `event_dialogue_object_id` | 关联的对话配置 ID |
| `event_background_texture_path` | 事件背景图 |

**示例** (`event_act_1_easy_combat_1.json`):
```json
"event_weighted_enemy_object_ids": [
    {"enemy_1": 1.0, "enemy_2": 1.0, "enemy_3": 1.0},
    {"enemy_1": 1.0, "enemy_2": 1.0, "enemy_3": 1.0},
    {"enemy_1": 1.0, "enemy_2": 1.0, "enemy_3": 1.0}
]
```
表示最多 3 个敌人槽位，每个槽位等概率刷 enemy_1/2/3。

### 3.4 敌人配置 (`external/data/enemies/*.json`)

敌人的行为逻辑通过 `enemy_attack_states` 中的 `custom_actions` 和 `enemy_actions_on_death` 调用 action 系统。

```json
"enemy_attack_states": {
    "1": {
        "attack_damage": 5,
        "number_of_attacks": 1,
        "block": 5,
        "custom_actions": [
            {
                "res://scripts/actions/ActionApplyStatus.gd": {
                    "status_effect_object_id": "status_vulnerable",
                    "status_charge_amount": 1
                }
            }
        ],
        "next_attack_weights": {"1": 1, "2": 1}
    }
}
```

---

## 4. Excel 转 JSON 配置管道

### 4.1 支持的配置类型

目前已实现 **Excel/CSV 转 JSON** 的自动化管道，支持以下三种数据类型：

| 类型 | Excel 文件 | 输出目录 | 转换脚本 |
|------|-----------|----------|----------|
| 卡牌 (Cards) | `external/config/cards.xlsx` | `external/data/cards/` | `external/tools/excel_to_json.py` |
| 遗物 (Artifacts) | `external/config/artifacts.xlsx` | `external/data/artifacts/` | `external/tools/excel_to_json_artifacts.py` |
| 事件 (Events) | `external/config/events.xlsx` | `external/data/events/` | `external/tools/excel_to_json_events.py` |

### 4.2 统一转换入口

使用 `convert.py` 作为统一入口，自动检测 Excel 输入并按类型转换：

```bash
# 转换所有配置（卡牌 + 遗物 + 事件）
python external/tools/convert.py

# 仅转换特定类型
python external/tools/convert.py --cards
python external/tools/convert.py --artifacts
python external/tools/convert.py --events

# 创建示例 Excel 文件
python external/tools/convert.py --create-sample

# 仅验证不生成
python external/tools/convert.py --validate-only
```

### 4.3 卡牌 Excel 结构

卡牌 Excel 使用 `Cards` 工作表，关键列包括：

#### 基础信息
- `object_id`, `card_name`, `card_description`, `card_type`, `card_rarity`
- `card_color_id`, `card_energy_cost`, `card_requires_target`
- `card_exhausts`, `card_is_ethereal`, `card_is_retained`

#### 卡牌数值 (自动写入 `card_values`)
- `damage`, `number_of_attacks`, `block`, `draw_count`
- `status_charge_amount`, `status_effect_object_id`
- `money_amount`, `heal_amount`, `damage_random` 等

#### Action 配置
- `action_type` - Action 类名（如 `ActionAttackGenerator`）
- `action_time_delay` - 延迟时间
- `action_target_override` - 目标覆盖（支持 `BaseAction.TARGET_OVERRIDES.XXX` 枚举字符串）
- `action_on_lethal` - 击杀时触发的 action
- `validator_type` - 配合 `ActionValidator` 使用

#### 升级配置
- `card_upgrade_amount_max`
- `upgrade_damage`, `upgrade_block`, `upgrade_number_of_attacks`, `upgrade_draw_count`
- `first_upgrade_energy_cost` - 首次升级改变能量消耗

### 4.4 验证规则（卡牌转换器）

转换器会自动执行以下验证：

**错误 (阻止生成)**
- `object_id` 为空
- `card_name` 为空
- `card_type` 不是有效值 (0-4)
- `card_requires_target` 为 False 但有伤害值

**警告 (允许生成)**
- 攻击卡牌伤害为 0
- 未知颜色 ID
- 描述中的占位符 `[xxx]` 没有对应数值
- Power 卡牌设置了 `card_exhausts`（冗余）
- 可变费用卡牌能量消耗不为 0

### 4.5 输入文件优先级

`convert.py` 的检测优先级：**Excel > CSV**

- 如果存在 `cards.xlsx`，优先使用 Excel 转换器
- 如果不存在 Excel 但存在 `cards.csv`，回退到 CSV 转换器 (`csv_to_json.py`)
- 需要安装依赖：`pip install pandas openpyxl`

### 4.6 文件结构总览

```
external/
├── config/
│   ├── cards.xlsx              # 卡牌 Excel 源文件
│   ├── artifacts.xlsx          # 遗物 Excel 源文件
│   ├── events.xlsx             # 事件 Excel 源文件
│   ├── cards.csv               # 卡牌 CSV 源文件（备用）
│   └── cards_template.csv      # CSV 模板示例
├── data/
│   ├── cards/                  # 自动生成的卡牌 JSON
│   ├── artifacts/              # 自动生成的遗物 JSON
│   ├── events/                 # 自动生成的事件 JSON
│   └── enemies/                # 手动编辑的敌人 JSON
└── tools/
    ├── convert.py              # 统一转换入口
    ├── excel_to_json.py        # 卡牌 Excel 转换器
    ├── excel_to_json_artifacts.py  # 遗物 Excel 转换器
    ├── excel_to_json_events.py     # 事件 Excel 转换器
    └── csv_to_json.py          # 卡牌 CSV 转换器（ legacy ）
```

---

## 5. 总结

- **敌人**：通过 `enemy_attack_states` 状态机配置行为，支持伤害、格挡、自定义 action 和加权状态转移。
- **所有系统（卡牌、遗物、事件、敌人）**：共享同一套 Action 管道系统，配置方式都是在 JSON 中写 `{"脚本路径": {参数}}` 的数组。
- **Excel 转 JSON**：卡牌、遗物、事件均已支持通过 Excel 配置并自动转换为 JSON，统一使用 `python external/tools/convert.py` 执行转换。

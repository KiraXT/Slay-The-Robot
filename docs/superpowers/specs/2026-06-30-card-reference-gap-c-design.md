# 卡牌参考缺口 C 设计

**目标：** 补齐 `Card Development Reference` 中“下一张攻击/下一张牌临时修正”的最小可用缺口，并配置红 `card_combo_starter` / `连段起手`。本批只处理“下一张符合条件的攻击伤害提高”，暂不处理费用降低、下回合保留牌强化、选中牌实例附加触发。

**采用方案：** 新增一个通用玩家状态效果脚本，由卡牌施加到玩家身上。状态效果监听出牌请求，只在下一张符合配置条件的牌开始打出时触发，并通过现有 action/interceptor 流程修改本次出牌的攻击伤害。非目标牌不会消耗状态，触发后消耗层数，回合结束时可按配置清除。

## 范围

### 本批包含

- 新增通用“下一张符合条件牌修正”状态效果脚本。
- 新增状态效果 JSON，用于承载 `连段起手` 的可见状态。
- 配置红 `card_combo_starter` / `连段起手`。
- 增加回归测试，覆盖状态配置、过滤规则、消耗规则和卡牌配置。
- 更新 `external/config/cards.xlsx` 和 `external/config/cards.csv` 卡牌台账。

### 本批不包含

- 下一张攻击费用降低。
- 直接修改手牌 UI 中的能量费用展示。
- 橙 `准备姿态` 的保留攻击和下回合限定增伤。
- 橙 `背包整理` 的抽到指定牌触发。
- 橙 `夹好书签` 的单张牌实例追踪和下回合限定降费。
- 新卡美术、最终数值平衡、卡池权重重排。

## 架构

### 通用状态效果脚本

新增 `scripts/status_effects/StatusEffectNextMatchingCardModifier.gd`。

该脚本继承 `BaseStatusEffect`，由状态效果挂在玩家身上后工作。脚本初始化时读取 `status_custom_values`，并监听 `Signals.card_play_started`。收到出牌事件后，脚本先判断本次牌是否属于当前状态拥有者，再检查牌类型、牌 ID 等过滤条件。

支持配置：

- `card_type_filter`：可选，限制触发牌类型。本批 `连段起手` 使用攻击牌过滤。
- `card_object_id_filter`：可选，限制触发牌 ID。
- `value_modifiers`：可选，按键修改当前 `CardPlayRequest.card_values`，例如 `{ "damage": 3 }`。
- `consume_charge_on_trigger`：触发后是否消耗状态层数，默认 `true`。
- `clear_on_player_turn_end`：回合结束是否清除状态，默认 `true`。
- `ignore_duplicate_plays`：是否忽略复制出牌，默认 `true`。

触发时，脚本只修改当前出牌请求中的 `card_values`，不写回 `CardData`。这样本次攻击可以得到增伤，手牌、弃牌堆、牌库中的卡牌实例不会被永久污染。

### 状态层数和叠加

状态层数代表仍可触发的次数。每次成功命中一张符合条件的牌后消耗一层。多个同类状态叠加时，按现有状态叠层行为合并层数，并在一次符合条件的出牌中只消耗一层。

本批 `连段起手` 默认只给 1 层，所以常规行为是只强化下一张攻击。若以后需要“接下来 N 张攻击”，可以直接通过层数表达，不需要新增脚本。

### 回合结束清除

`连段起手` 是红色连段启动牌，效果应服务当前回合的进攻节奏。状态脚本监听 `Signals.player_turn_ended`，当 `clear_on_player_turn_end = true` 时移除剩余层数，避免跨回合残留。

## 本批卡牌配置

### 红 `card_combo_starter` / `连段起手`

类型：红色 1 费技能牌。它不直接造成伤害，而是给玩家添加一次性的连段状态。

效果：获得“连段起手”状态。你的下一张攻击造成额外伤害。

实现：

- `card_play_actions` 使用 `ActionApplyStatus` 给玩家施加 `status_effect_combo_starter`。
- `status_effect_combo_starter` 的脚本为 `StatusEffectNextMatchingCardModifier.gd`。
- `status_force_apply_new_effect` 使用现有状态叠加规则；若实现中需要隔离运行时配置，可以使用 `status_custom_values`。
- custom values 写入：
  - `card_type_filter = ["attack"]`
  - `value_modifiers = { "damage": 3 }`
  - `consume_charge_on_trigger = true`
  - `clear_on_player_turn_end = true`
  - `ignore_duplicate_plays = true`

验收：

- 打出 `连段起手` 后，下一张攻击的本次伤害提高。
- 中间打出非攻击牌不会消耗状态。
- 第一张攻击触发后状态消耗，不继续影响后续攻击。
- 回合结束时未使用的状态清除。

## 数据流程

1. 玩家打出 `连段起手`。
2. `ActionApplyStatus` 给玩家添加 `status_effect_combo_starter`。
3. 状态脚本监听后续 `card_play_started`。
4. 玩家打出非攻击牌时，状态跳过且不消耗。
5. 玩家打出攻击牌时，状态修改当前 `CardPlayRequest.card_values.damage`。
6. 状态消耗一层；层数归零时由现有状态移除流程处理。
7. 若玩家回合结束前未触发，状态按配置清除。

## 错误处理

- `value_modifiers` 为空时，状态不修改数值，但仍可按配置消耗或等待下一张牌。
- 事件中缺少 `CardPlayRequest` 或 `card_data` 时直接跳过，不消耗层数。
- `card_type_filter`、`card_object_id_filter` 不匹配时直接跳过。
- 配置了不存在的 `card_values` 键时，脚本只对当前请求中存在的键生效，避免给无关牌创建新数值。
- 状态没有拥有者或拥有者已死亡时，不触发修改。

## 测试

新增 `tests/card_reference_gap_c_regression.py`，检查：

- 新状态脚本存在，并监听 `card_play_started` 和 `player_turn_ended`。
- 新状态 JSON 路径有效，并引用通用状态脚本。
- `card_combo_starter` 存在且通过 `ActionApplyStatus` 施加新状态。
- `card_combo_starter` 的 custom values 限定攻击牌、配置 `damage` 修正、触发后消耗、回合结束清除。
- 非攻击牌不会被配置为消耗状态的触发目标。
- `card_combo_starter` 出现在 `cards.csv` 台账中。

同时运行：

- `tests/card_configurable_cards_regression.py`
- `tests/card_reference_gap_a_regression.py`
- `tests/card_reference_gap_b_regression.py`
- `tests/card_reference_gap_c_regression.py`
- `godot --headless --path . --quit`

## 实现顺序

1. 增加失败回归测试。
2. 实现 `StatusEffectNextMatchingCardModifier.gd`。
3. 新增 `status_effect_combo_starter` 状态 JSON。
4. 配置 `card_combo_starter` 卡牌 JSON。
5. 更新 Excel/CSV 台账。
6. 运行 Python 回归、JSON 检查和 Godot headless 验证。

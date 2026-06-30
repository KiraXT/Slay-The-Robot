# 卡牌参考缺口 B 设计

**目标：** 补齐 `Card Development Reference` 中“每回合首次触发型能力”的下一批缺口，并配置本批可解锁的卡牌。本批只处理每回合一次触发能力和可直接配置的整场消耗数缩放，不处理下一张牌修正、选中牌实例追踪、精确下回合限定过期。

**采用方案：** 新增一个通用玩家状态效果脚本，由能力牌施加到玩家身上。状态效果监听战斗事件，在每个玩家回合内最多触发指定次数，并执行 JSON 配置的 actions。这样 `节拍器`、`轻装上阵` 后续都可以共用同一套机制。

## 范围

### 本批包含

- 新增通用“每回合一次触发”状态效果脚本。
- 新增状态效果 JSON，用于承载该通用脚本的可见状态。首批创建 `status_effect_metronome` 和 `status_effect_travel_light`，二者共用同一脚本但展示为不同状态。
- 扩展 `ActionApplyStatus`，支持把 `status_custom_values` 传入新状态实例。
- 配置绿 `card_metronome` / `节拍器`。
- 配置橙 `card_travel_light` / `轻装上阵`。
- 配置橙 `card_last_item` / `最后一件`，优先使用现有 `ActionVariableCombatStatsModifier` 按整场消耗牌数量缩放伤害。
- 更新 `external/config/cards.xlsx` 和 `external/config/cards.csv` 卡牌台账。
- 增加回归测试，覆盖脚本路径、状态配置、卡牌配置、台账记录和现有卡牌回归数量。

### 本批不包含

- 红 `连段起手` 的下一张攻击临时修正。
- 橙 `准备姿态` 的下回合攻击增强。
- 橙 `背包整理` 的抽到指定牌触发。
- 橙 `夹好书签` 的单张牌实例追踪和下回合限定降费。
- 新卡美术、最终数值平衡、卡池权重重排。

## 架构

### 通用状态效果脚本

新增 `scripts/status_effects/StatusEffectOncePerTurnTrigger.gd`。

该脚本继承 `BaseStatusEffect`，由状态效果挂在玩家身上后工作。脚本在初始化时读取 `status_custom_values`，并根据配置连接对应信号。

支持配置：

- `trigger_signal`：触发来源。首批支持 `card_play_started`、`card_played`、`card_drawn`、`card_discarded`、`card_exhausted`。
- `max_triggers_per_turn`：每个玩家回合最多触发次数，默认 1。
- `card_type_filter`：可选，限制触发牌类型。
- `card_object_id_filter`：可选，限制触发牌 ID。
- `ignore_duplicate_plays`：可选，默认 `true`，避免复制出牌重复消耗首次触发。
- `action_data`：触发后执行的 actions。
- `consume_charge_on_trigger`：可选，触发后消耗状态层数，默认 `false`。

状态脚本维护一个运行时字段 `triggers_this_turn`。监听 `player_turn_started` 时重置为 0；收到目标事件时先检查玩家回合、触发次数和过滤条件，通过后生成 actions 并递增计数。

### 施加状态时传入配置

现有 `ActionApplyStatus` 已能通过 `status_force_apply_new_effect` 调用 `BaseCombatant.add_new_status_effect()`，但尚未把自定义配置传给状态实例。本批扩展 `ActionApplyStatus.gd`：

- 新增读取 `status_custom_values`，默认 `{}`。
- 当 `status_force_apply_new_effect` 为 `true` 时，把 `status_custom_values` 作为第四个参数传给 `add_new_status_effect()`。
- 非强制新实例路径继续走 `add_status_effect_charges()`，不改变既有状态叠加行为。

两个新状态 JSON 都设置 `status_effect_allows_multiples = true`。这样同一脚本可支持多张能力牌各自持有独立配置和本回合触发计数。

### 触发动作执行

触发时创建一个 `CardPlayRequest`：

- 对 `card_play_started`、`card_played`，沿用事件中的 `CardPlayRequest`，让 actions 能读取本次出牌的 card values 和目标。
- 对 `card_drawn`、`card_discarded`、`card_exhausted`，创建一个带有对应 `card_data` 的临时请求。

执行目标默认是玩家自身。需要影响本次出牌时，action 可读取当前 `CardPlayRequest`。首批 `节拍器` 需要对本次出牌的 `card_values` 做临时加值，因此会新增一个小型 meta action：`ActionModifyCurrentCardPlayValues.gd`。它只修改当前请求的 `card_values`，不写回 `CardData`，避免永久污染卡牌实例。

### 本批卡牌配置

#### 绿 `card_metronome` / `节拍器`

类型：能力牌。

效果：获得“节拍器”状态。每个玩家回合第一张被打出的标准牌触发一次，使该次出牌的数值提高。

实现：

- `card_play_actions` 使用 `ActionApplyStatus` 给玩家施加 `status_effect_metronome`。
- `status_effect_metronome` 的脚本为 `StatusEffectOncePerTurnTrigger.gd`。
- `status_force_apply_new_effect` 为 `true`，并通过 custom values 写入：
  - `trigger_signal = "card_play_started"`
  - `max_triggers_per_turn = 1`
  - `action_data` 包含 `ActionModifyCurrentCardPlayValues.gd`
- `ActionModifyCurrentCardPlayValues.gd` 对 `damage`、`block` 等配置键增加数值。

验收：

- 每个玩家回合只增强第一张符合条件的牌。
- 同一回合第二张牌不增强。
- 新玩家回合再次可触发。
- 修改只存在于本次出牌请求，不永久改变手牌、弃牌堆或牌库中的同名牌。

#### 橙 `card_travel_light` / `轻装上阵`

类型：能力牌。

效果：获得“轻装上阵”状态。每个玩家回合第一次有牌被消耗时，获得能量。

实现：

- `card_play_actions` 使用 `ActionApplyStatus` 给玩家施加 `status_effect_travel_light`。
- `status_effect_travel_light` 的脚本为 `StatusEffectOncePerTurnTrigger.gd`。
- `status_force_apply_new_effect` 为 `true`，custom values 写入：
  - `trigger_signal = "card_exhausted"`
  - `max_triggers_per_turn = 1`
  - `action_data` 包含 `ActionAddEnergy.gd`

验收：

- 本回合第一次消耗牌获得能量。
- 本回合后续消耗牌不再获得能量。
- 下个玩家回合重新可触发。
- 由打出消耗牌或 action 消耗牌都能触发，因为二者都会发 `card_exhausted`。

#### 橙 `card_last_item` / `最后一件`

类型：攻击牌。

效果：造成伤害，按本场战斗已消耗牌数量获得额外伤害。

实现：

- 使用现有 `ActionVariableCombatStatsModifier`。
- `stat_enum = CombatStatsData.STATS.CARDS_EXHAUSTED`。
- `is_total_stat = true`。
- 子 action 使用 `ActionAttackGenerator`。

验收：

- 本场未消耗牌时只造成基础伤害。
- 本场已消耗牌越多，伤害越高。
- 不新增脚本，除非现有 action 在测试中暴露无法表达整场统计缩放。

## 数据流程

1. 能力牌打出。
2. `ActionApplyStatus` 给玩家添加对应触发状态，并写入 `status_custom_values`。
3. 状态脚本读取自定义配置并监听对应信号。
4. 战斗事件发生时，状态判断本回合触发次数和过滤条件。
5. 状态生成配置化 actions 并执行。
6. 下个玩家回合开始时，状态重置本回合触发次数。

## 错误处理

- `trigger_signal` 未配置或不支持时，状态脚本记录错误并不连接事件。
- `action_data` 为空时不触发 actions，但仍不会崩溃。
- 事件中缺少 `CardPlayRequest` 时，脚本会基于 `CardData` 创建临时请求。
- `card_type_filter`、`card_object_id_filter` 不匹配时直接跳过，不消耗本回合触发次数。
- `consume_charge_on_trigger` 导致层数归零时，沿用现有状态移除流程。

## 测试

新增 `tests/card_reference_gap_b_regression.py`，检查：

- 新状态脚本存在。
- `ActionModifyCurrentCardPlayValues.gd` 存在。
- `ActionApplyStatus.gd` 支持 `status_custom_values` 并传入 `add_new_status_effect()`。
- `status_effect_metronome` 和 `status_effect_travel_light` 路径有效，并引用通用状态脚本。
- `card_metronome` 使用 `status_effect_metronome`，监听 `card_play_started`。
- `card_travel_light` 使用 `status_effect_travel_light`，监听 `card_exhausted`。
- `card_last_item` 使用 `ActionVariableCombatStatsModifier` 且 `is_total_stat = true`。
- 三张卡出现在 `cards.csv` 台账中。

同时更新并运行：

- `tests/card_configurable_cards_regression.py`
- `tests/card_reference_gap_b_regression.py`
- 三张新卡 JSON 合法性检查
- `godot --headless --path . --quit`

## 实现顺序

1. 增加失败回归测试。
2. 实现 `StatusEffectOncePerTurnTrigger.gd`。
3. 实现 `ActionModifyCurrentCardPlayValues.gd`。
4. 扩展 `ActionApplyStatus.gd` 支持 `status_custom_values`。
5. 新增状态效果 JSON。
6. 配置三张卡牌 JSON。
7. 更新 Excel/CSV 台账。
8. 运行 Python 回归、JSON 检查和 Godot headless 验证。

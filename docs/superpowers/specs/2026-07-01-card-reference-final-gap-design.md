# 最终卡牌参考缺口设计

**目标：** 补齐角色机制总设计中剩余的 4 张计划卡牌：绿 `副歌`，橙 `夹好书签`、`背包整理`、`准备姿态`。本批只处理卡牌功能和数据配置，不处理最终数值平衡与独立卡图。

## 范围

### 本批包含

- 绿 `card_chorus` / `副歌`：能力牌。每回合第一次打出攻击或技能时，复制该牌一次。
- 橙 `card_bookmark_clip` / `夹好书签`：选择 1 张手牌并保留；那张牌下个玩家回合费用降低。
- 橙 `card_pack_sorting` / `背包整理`：选择 1 张手牌放到抽牌堆顶；下次抽到那张牌时获得能量。
- 橙 `card_ready_stance` / `准备姿态`：保留所有攻击；这些攻击在下个玩家回合打出时伤害提高。
- 更新 `external/config/cards.xlsx` 与 `external/config/cards.csv` 台账。
- 增加回归测试覆盖脚本、状态、卡牌和台账。

### 本批不包含

- 新卡逐张美术。
- 卡池权重重排。
- 起始牌组调整。
- 更复杂的跨战斗牌实例持久追踪。

## 架构

本批使用“状态监听 + 牌实例标记”的方式实现。

1. `副歌` 使用玩家状态监听 `card_play_started`。状态每回合触发一次，匹配攻击或技能后请求复制本次出牌。复制请求标记为 `is_duplicate_play`，避免递归复制。
2. `夹好书签`、`背包整理`、`准备姿态` 使用一个新的卡组 action 给运行中的 `CardData` 实例添加临时 tag。现有 `CardData.card_tags` 会跟随同一张运行时牌在手牌、抽牌堆、弃牌堆之间移动，足够覆盖本批需求。
3. 新增一个通用状态效果监听被标记的牌。它可以监听 `card_drawn` 或 `card_play_started`，匹配指定 tag 后执行配置化 actions，并按配置移除 tag 或在玩家回合结束时过期。
4. `夹好书签` 的费用降低通过现有 `ActionChangeCardEnergies` 写入 `card_energy_cost_until_turn`，只在下个玩家回合有效。
5. `准备姿态` 的下回合攻击增强通过现有 `StatusEffectNextMatchingCardModifier.gd` 的相同思想实现，但过滤条件改为“牌实例带有指定 tag”。触发后只修改当前 `CardPlayRequest.card_values`，不永久污染牌数据。

## 数据流

### 副歌

1. 玩家打出 `副歌`，获得 `status_effect_chorus`。
2. 玩家每回合第一次打出攻击或技能时，状态收到 `card_play_started`。
3. 状态创建一个新的 `CardPlayRequest`，复制当前牌、目标和 `card_values`。
4. 状态发送 `Signals.card_play_requested`，请求免费复制出牌。
5. 状态本回合计数加 1；复制出的牌因为 `is_duplicate_play = true` 不会再次触发。

### 夹好书签

1. 玩家打出 `夹好书签`，选择 1 张手牌。
2. 该牌被保留，并获得 tag `temporary_bookmark_clip_discount`。
3. 下个玩家回合开始后，状态等待这张牌被打出或回合结束。
4. 若牌在下个回合仍在手牌中，状态让它本回合费用降低。
5. 下个玩家回合结束时移除 tag，费用自然随 `card_energy_cost_until_turn` 清理。

### 背包整理

1. 玩家打出 `背包整理`，选择 1 张手牌。
2. 该牌获得 tag `temporary_pack_sorting_energy`，并移动到抽牌堆顶。
3. 抽到这张牌时，监听状态匹配 tag，给予能量。
4. 状态移除 tag，避免同一张牌重复回能。

### 准备姿态

1. 玩家打出 `准备姿态`。
2. 当前手牌中所有攻击被保留，并获得 tag `temporary_ready_stance_damage`。
3. 下个玩家回合打出这些攻击时，状态匹配 tag 并提高该次出牌的伤害。
4. 触发后移除该牌 tag；下个玩家回合结束时清理仍未使用的 tag。

## 错误处理

- 找不到可选牌时，选牌 action 按现有规则安全结束，不生成后续动作。
- 监听状态收到空 `CardData` 或空 `CardPlayRequest` 时直接跳过。
- tag 不匹配时不消耗触发次数。
- 配置里未提供 `action_data` 时不执行动作，并保留状态本身。
- 复制出牌时若没有目标，沿用当前请求目标；无目标技能也能正常复制。

## 测试

新增 `tests/card_reference_final_gap_regression.py`：

- 检查新脚本存在：标记牌 action、临时 tag 监听状态、复制当前牌 action。
- 检查 `StatusEffectOncePerTurnTrigger.gd` 对长期连接信号有断开逻辑，避免状态移除后继续触发。
- 检查 4 张卡 JSON 存在、颜色/类型/稀有度正确、可进入卡包。
- 检查 `副歌` 使用 `status_effect_chorus` 并过滤攻击/技能。
- 检查 `夹好书签` 使用保留、打 tag、下回合费用降低的配置。
- 检查 `背包整理` 使用抽牌堆顶移动和抽到回能 tag。
- 检查 `准备姿态` 只标记攻击，并配置下回合伤害提高。
- 检查 4 张卡出现在 `cards.csv` 台账。

同时运行既有回归：

- `tests/card_configurable_cards_regression.py`
- `tests/card_reference_gap_a_regression.py`
- `tests/card_reference_gap_b_regression.py`
- `tests/card_reference_gap_c_regression.py`
- Godot headless 加载验证

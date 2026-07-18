# Card Development Reference

**用途：** 汇总目前已确认的四角色卡牌设计方向、已通过现有配置落地的卡牌、以及后续需要新增开发逻辑的卡牌能力。后续开发时以本文作为功能对照，设计总纲见 `docs/superpowers/specs/2026-06-29-character-card-mechanics-design.md`。

**当前结论：** 已定方案为“方案 2：机制归位”。先按角色机制边界把卡池方向定清楚，再补每个角色缺口。第一批可配置卡牌和后续 Gap A/B/C 复杂机制卡牌已完成落地，当前重点转为验收、数值平衡和更大范围的美术定稿。

## 1. 角色设计边界

| 角色 | 核心体验 | 应拥有的机制 | 应避免变成主轴的机制 |
|---|---|---|---|
| 红 | 近身连段、压迫、爆发回合 | 多段攻击、攻击连锁、敌人攻击时奖励、易伤/虚弱、攻击复制 | 大量抽弃循环、长期升级成长、保留准备 |
| 蓝 | 抽弃循环、混乱补救、随机收益 | 抽牌、弃牌、弃牌堆回收、随机费用、临时消耗品、弃牌触发收益 | 稳定攻击爆发、永久成长、消耗主轴 |
| 绿 | 节奏控制、延迟收益、成长 | 腐蚀、炸弹、意图控制、首张牌/同类型节奏条件、复制演出、升级、保留格挡 | 重随机、纯爆发攻击、背包式保留准备 |
| 橙 | 提前准备、保留、抽到触发、消耗兑现 | 保留、牌库顶设置、抽到触发、消耗/放逐、延迟释放 | 抽弃循环主轴、敌人控制、红色连段压迫 |

## 2. 已可配置落地的卡牌

这些卡牌已按“JSON 先实现，Excel/CSV 留档”的流程加入，未新增游戏逻辑脚本。

| 角色 | 卡牌 ID | 中文设计名 | 设计作用 | 实现方式 |
|---|---|---|---|---|
| 蓝 | `card_hasty_sorting` | 匆忙整理 | 弃牌后按弃牌数量抽牌，补蓝色抽弃循环 | `ActionPickCards` 选手牌，`ActionDiscardCards` 弃牌，按选中数量触发抽牌 |
| 蓝 | `card_something_fell_out` | 掉出来了 | 被手动弃掉时回能，形成弃牌收益 | `card_discard_actions` 触发加能量 |
| 蓝 | `card_quick_search` | 快速翻找 | 从弃牌堆找回关键牌，并临时降费 | 从弃牌堆选牌，加入手牌，`ActionChangeCardEnergies` 本回合降费 |
| 蓝 | `card_by_accident` | 误打误撞 | 随机从弃牌堆打出牌，强化混乱补救感 | 从弃牌堆随机选牌并 `ActionPlayCards` |
| 蓝 | `card_backup_drink` | 备用饮料 | 生成临时道具，若本回合弃过牌则额外抽牌 | 生成消耗品，`ValidatorCombatStats` 判断弃牌数 |
| 绿 | `card_first_beat` | 第一拍 | 如果是本回合第一张牌，获得额外收益 | `ValidatorCombatStats` 判断 `CARDS_PLAYED == 0` |
| 绿 | `card_distorted_note` | 失真音 | 伤害、腐蚀，并在敌人攻击时干扰意图 | 攻击 + 施加腐蚀 + 目标攻击校验后切换意图 |
| 绿 | `card_tuning` | 调音 | 选择手牌并提升其本场战斗数值 | 选手牌，`ActionImproveCardValues` |
| 橙 | `card_warmup` | 热身 | 保留后自身格挡成长 | 自带保留，`card_retain_actions` 提升自身格挡 |
| 橙 | `card_sports_drink` | 运动饮料 | 抽到时回能，打出后抽牌并消耗 | `card_draw_actions` 加能量，打出后抽牌和消耗 |
| 橙 | `card_bag_swing` | 背包挥击 | 本回合消耗过牌时追加伤害 | `ValidatorCombatStats` 判断 `CARDS_EXHAUSTED > 0` |
| 橙 | `card_old_item_reuse` | 旧物再用 | 消耗一张手牌，获得格挡和抽牌 | 选手牌，消耗，格挡，抽牌 |
| 橙 | `card_sprint_start` | 冲刺起步 | 抽到当回合免费，体现准备后的爆发 | `card_draw_actions` 将自身费用改为 0 直到回合结束 |
| 红 | `card_opening_strike` | 起手打击 | 攻击正在进攻的敌人时施加易伤 | 攻击后用敌人攻击校验追加易伤 |
| 红 | `card_finisher` | 终结击 | 本回合已出牌越多，伤害越高 | `ActionVariableCombatStatsModifier` 按出牌数放大伤害 |

### 当前配置能力可覆盖的内容

- 选牌、随机选牌、从手牌/弃牌堆/消耗堆/本回合打出牌中取牌。
- 弃牌、消耗、保留、抽牌、加能量、加格挡、造成伤害、施加状态。
- 把牌加入手牌或牌库，调整选中牌费用，提升选中牌数值，升级牌，打出选中牌。
- 用 `ValidatorCombatStats` 按本回合/本场战斗统计做条件分支。
- 用敌人攻击状态校验做“敌人正在攻击时”的追加效果。
- 使用卡牌自身触发字段：`card_draw_actions`、`card_discard_actions`、`card_retain_actions`、`card_exhaust_actions`、`card_initial_combat_actions`。

### 当前配置注意点

- `card_discard_actions` 目前只在手动弃牌时触发，不等同于回合结束自动弃牌。
- Excel/CSV 已作为卡牌台账更新，转换器已支持复杂 JSON 文本列，复杂牌仍以 JSON 为准并同步留档。
- 新增卡牌 JSON 位于 `external/data/cards/`；该目录下 JSON 受忽略规则影响，提交时需要显式加入。

## 3. 已补齐的复杂机制卡牌

以下卡牌已按 Gap A/B/C 分批落地，均通过 JSON 配置接入通用脚本，不再是待开发项。

| 批次 | 角色 | 卡牌 ID | 中文设计名 | 已落地能力 |
|---|---|---|---|---|
| Gap A | 红 | `card_pursuit` | 追击 | 造成伤害；上一张牌是攻击时抽 1 张 |
| Gap A | 绿 | `card_echo_shield` | 回声护盾 | 获得格挡；上一张牌是技能时额外获得格挡 |
| Gap B | 绿 | `card_finale_burst` | 终场爆音 | 按目标状态层数修正伤害 |
| Gap B | 绿 | `card_metronome` | 节拍器 | 每回合首次出牌时临时提高当前牌数值 |
| Gap B | 橙 | `card_travel_light` | 轻装上阵 | 每回合首次消耗牌时获得能量 |
| Gap B | 橙 | `card_last_item` | 最后一件 | 按本场战斗已消耗牌数修正伤害 |
| Gap C | 红 | `card_combo_starter` | 连段起手 | 下一张攻击在本回合获得伤害提高；当前落地为增伤版，不是降费版 |
| Gap C | 绿 | `card_chorus` | 副歌 | 能力牌；每回合首张攻击和首张技能各复制一次当前出牌 |
| Gap C | 橙 | `card_bookmark_clip` | 夹好书签 | 标记一张手牌并保留，下个玩家回合临时降费，触发后清理 |
| Gap C | 橙 | `card_pack_sorting` | 背包整理 | 标记一张手牌并放到抽牌堆顶，抽到时获得能量，触发后清理 |
| Gap C | 橙 | `card_ready_stance` | 准备姿态 | 标记并保留手牌中所有攻击，下个玩家回合这些攻击获得伤害提高 |

### 当前复杂机制底座

- `ValidatorPreviousCard.gd` / `ValidatorPreviousCardType.gd`：上一张牌、上一张牌类型校验。
- `ActionTargetStatusValueModifier.gd`：按目标状态层数修正子 action 数值。
- `StatusEffectOncePerTurnTrigger.gd`：每回合一次触发状态，支持出牌、消耗等事件。
- `ActionModifyCurrentCardPlayValues.gd`：修正当前正在结算的卡牌数值。
- `ActionTagCards.gd`：给运行时卡牌实例附加标记、持续时间和触发动作。
- `ActionDuplicateCurrentCardPlay.gd`：复制当前卡牌结算。
- `StatusEffectTaggedCardTrigger.gd`：监听被标记卡牌的抽到、打出、回合开始/结束等触发点。

## 4. 数据流程同步

- `external/tools/excel_to_json.py` 已支持复杂 JSON 文本列写回卡牌字段。
- `external/tools/json_to_excel.py` 已支持复杂字段导出到卡牌台账。
- 当前已同步字段包括 `card_values_json`、`card_play_actions_json`、`card_draw_actions_json`、`card_discard_actions_json`、`card_retain_actions_json`、`card_exhaust_actions_json`、`card_initial_combat_actions_json`、`card_listeners_json`。
- `external/config/cards.xlsx` 和 `external/config/cards.csv` 已刷新到当前 92 张卡牌数据。

## 5. 本轮美术同步

### 卡图资源

| 卡牌 ID | 资源路径 |
|---|---|
| `card_combo_starter` | `external/sprites/cards/red/card_combo_starter.png` |
| `card_chorus` | `external/sprites/cards/green/card_chorus.png` |
| `card_bookmark_clip` | `external/sprites/cards/orange/card_bookmark_clip.png` |
| `card_pack_sorting` | `external/sprites/cards/orange/card_pack_sorting.png` |
| `card_ready_stance` | `external/sprites/cards/orange/card_ready_stance.png` |

### 状态图标资源

| 状态 ID | 资源路径 |
|---|---|
| `status_effect_combo_starter` | `external/sprites/status_effects/status_effect_combo_starter.png` |
| `status_effect_chorus` | `external/sprites/status_effects/status_effect_chorus.png` |
| `status_effect_bookmark_clip` | `external/sprites/status_effects/status_effect_bookmark_clip.png` |
| `status_effect_pack_sorting` | `external/sprites/status_effects/status_effect_pack_sorting.png` |
| `status_effect_ready_stance` | `external/sprites/status_effects/status_effect_ready_stance.png` |

## 6. 后续实现验收清单

每次新增卡牌或逻辑后至少检查：

- 新卡 JSON 能被加载，且引用脚本路径存在。
- `external/config/cards.xlsx` 和 `external/config/cards.csv` 中有对应留档。
- `tests/card_configurable_cards_regression.py` 继续通过，或新增同级测试覆盖新机制。
- `external/data/cards/*.json` 均为合法 JSON。
- Godot headless 启动能正常加载项目。
- 涉及手牌、抽牌、弃牌、消耗、保留的逻辑，需要在实战或自动测试中确认触发时机。

## 7. 本轮后仍不处理的内容

- 最终数值平衡。
- 除本轮 5 张 Gap C 卡图外，历史卡牌美术逐张定稿仍未纳入。
- 新角色资源条或新 UI。
- 卡池整体重排和起始牌组调整。
- 把所有紫色/白色牌一次性归位。

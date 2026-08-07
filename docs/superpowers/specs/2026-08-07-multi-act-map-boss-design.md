# 多幕地图与 Boss 分层设计

## 背景

项目已经具备三幕运行结构：玩家数据默认 `player_act_max = 3`，`act_1` 指向 `act_2`，`act_2` 指向 `act_3`，通关当前幕 Boss 后会生成下一幕地图。当前缺口是第二幕和第三幕仍复用第一幕事件池与 Boss，导致流程看起来像单层地图和单一 Boss 重复。

本次目标是让完整 run 形成类似《杀戮尖塔》的三幕体验：每一幕使用独立地图事件池、普通战斗池、小 Boss 池和 Boss 池，并按层级提升强度。Boss 图片前期使用现有 Boss 图替代，但在数据命名和设计文档中明确后续美术包装方向，便于测试通过后统一换图。

## 目标

1. 第一幕保持现状，作为低压机器人试验场。
2. 第二幕新增独立普通战斗、困难战斗、小 Boss、Boss 事件池与敌人数据。
3. 第三幕新增独立普通战斗、困难战斗、小 Boss、Boss 事件池与敌人数据。
4. 地图生成器继续沿用现有结构：每幕生成新的节点图，Boss 节点结束后进入下一幕或胜利。
5. Boss 行为全部用现有数据驱动动作表达，不新增 Boss 专用脚本。
6. Boss 图片暂时指向 `external/sprites/enemies/enemy_act_1_boss_1.png`；新增普通敌人和小 Boss 可暂用现有同风格敌人图。
7. 新增回归测试，验证二、三幕不再引用第一幕 Boss 池，且每幕 Boss/小 Boss/战斗池能加载到有效敌人。

## 非目标

1. 不重写地图生成算法。
2. 不新增半血阶段、Boss 专用 AI 脚本或新的战斗动作类型。
3. 不在本阶段生成最终 Boss 图片。
4. 不改变奖励、商店、休息点、卡牌草稿或角色初始构筑规则。

## 总体结构

`external/data/acts/act_2.json` 和 `external/data/acts/act_3.json` 改为引用各自专属池：

| 幕 | 普通前段 | 普通后段 | 小 Boss | Boss | 非战斗 |
| --- | --- | --- | --- | --- | --- |
| 第一幕 | `event_pool_act_1_easy` | `event_pool_act_1_hard` | `event_pool_act_1_miniboss` | `event_pool_act_1_boss` | `event_pool_act_1_dialogue` |
| 第二幕 | `event_pool_act_2_easy` | `event_pool_act_2_hard` | `event_pool_act_2_miniboss` | `event_pool_act_2_boss` | `event_pool_act_1_dialogue` |
| 第三幕 | `event_pool_act_3_easy` | `event_pool_act_3_hard` | `event_pool_act_3_miniboss` | `event_pool_act_3_boss` | `event_pool_act_1_dialogue` |

第二幕和第三幕先复用第一幕非战斗事件池，避免把本次范围扩大到事件文本设计。地图上的事件节点仍能运行，战斗分层体验先独立完成。

## 强度曲线

### 第一幕

第一幕保留现有数据，作为玩家学习基础攻击、格挡、虚弱、易伤、腐蚀、召唤小怪等机制的入口。

### 第二幕：回收工厂

第二幕主题是“压力与资源交换”。敌人血量和格挡提高，更多组合使用虚弱、易伤、免伤和召唤，要求玩家能处理多目标和中等强度防御。

新增标准敌人：

| 敌人 ID | 名称 | 定位 | 血量 | 行为摘要 | 临时贴图 |
| --- | --- | --- | --- | --- | --- |
| `enemy_act_2_scrap_lancer` | 废料长枪机 | 单体压血 | 42 | 交替单次高伤与双段攻击，可偶尔加格挡 | `enemy_4.png` |
| `enemy_act_2_barrier_smith` | 护栏锻造机 | 防御支援 | 48 | 格挡自身，给玩家虚弱，小伤害补压 | `enemy_act_1_scrap_shield_guard.png` |
| `enemy_act_2_signal_jammer` | 信号干扰器 | 状态干扰 | 36 | 施加易伤和虚弱，低伤连击 | `enemy_act_1_disruptor_unit.png` |
| `enemy_act_2_repair_drone` | 修补无人机 | 召唤/陪衬 | 18 | 小额攻击与自我格挡，作为 Boss 召唤物 | `enemy_act_1_micro_drone.png` |

新增小 Boss：

| 敌人 ID | 名称 | 定位 | 血量 | 行为摘要 | 临时贴图 |
| --- | --- | --- | --- | --- | --- |
| `enemy_act_2_miniboss_forge_guardian` | 熔炉守卫 | 防御爆发 | 160 | 先筑盾，再免伤蓄力，随后重击 | `enemy_act_1_miniboss_bastion_guard.png` |
| `enemy_act_2_miniboss_relay_tower` | 中继高塔 | 召唤支援 | 135 | 召唤修补无人机，给自己伤害提升，再多段攻击 | `enemy_act_1_miniboss_command_core.png` |

新增 Boss：

| 敌人 ID | 名称 | 血量 | 定位 | 临时贴图 |
| --- | --- | --- | --- | --- |
| `enemy_act_2_boss_foundry_heart` | 熔炉心脏 | 260 | 防御蓄力 Boss | `enemy_act_1_boss_1.png` |

`熔炉心脏` 行为循环：

1. `加压`：获得 20 格挡，并给自身 2 层伤害提升。
2. `喷渣`：攻击 6 点 3 次，并给玩家 2 层虚弱。
3. `封炉`：获得 28 格挡，并获得 1 层免伤。
4. `倾倒熔液`：攻击 24 点 1 次，并给玩家 4 层腐蚀。
5. 回到 `加压`。

这个 Boss 的压力来自“先防后打”的节奏：玩家如果只堆防，会被伤害提升拖高；如果只抢伤害，会撞上格挡和免伤窗口。

### 第三幕：中央核心塔

第三幕主题是“终局调度与多线压力”。敌人基础血量更高，更多使用多段伤害、负面状态和召唤。第三幕 Boss 需要像最终考试，要求玩家同时处理攻击节奏、状态层数和召唤场面。

新增标准敌人：

| 敌人 ID | 名称 | 定位 | 血量 | 行为摘要 | 临时贴图 |
| --- | --- | --- | --- | --- | --- |
| `enemy_act_3_core_blade` | 核心刃卫 | 高伤输出 | 58 | 单次重击与三段连击交替 | `enemy_4.png` |
| `enemy_act_3_null_priest` | 归零祭仪机 | 负面状态 | 52 | 易伤、虚弱、腐蚀轮换，伤害较低 | `enemy_3.png` |
| `enemy_act_3_shield_obelisk` | 护盾方尖碑 | 防御墙 | 72 | 高格挡、免伤、间隔重击 | `enemy_act_1_scrap_shield_guard.png` |
| `enemy_act_3_orbital_drone` | 轨道无人机 | 终局小怪 | 24 | 快速双段攻击，作为最终 Boss 召唤物 | `enemy_act_1_micro_drone.png` |

新增小 Boss：

| 敌人 ID | 名称 | 定位 | 血量 | 行为摘要 | 临时贴图 |
| --- | --- | --- | --- | --- | --- |
| `enemy_act_3_miniboss_null_bastion` | 归零壁垒 | 高防状态战 | 210 | 高格挡、免伤、易伤玩家、重击 | `enemy_act_1_miniboss_bastion_guard.png` |
| `enemy_act_3_miniboss_orbital_array` | 轨道阵列 | 多目标战 | 180 | 召唤轨道无人机，给自己伤害提升，多段攻击 | `enemy_act_1_miniboss_command_core.png` |

新增 Boss：

| 敌人 ID | 名称 | 血量 | 定位 | 临时贴图 |
| --- | --- | --- | --- | --- |
| `enemy_act_3_boss_overmind_core` | 至高主脑核心 | 340 | 终局复合 Boss | `enemy_act_1_boss_1.png` |

`至高主脑核心` 行为循环：

1. `开局同步`：召唤 2 个轨道无人机，占用左右槽位。
2. `计算弱点`：给玩家 2 层易伤和 2 层虚弱，同时自身获得 16 格挡。
3. `多线程齐射`：攻击 8 点 4 次。
4. `核心护幕`：获得 32 格挡和 1 层免伤。
5. `终端裁决`：攻击 32 点 1 次，并给自身 2 层伤害提升。
6. 回到 `计算弱点`。

这个 Boss 的压力来自“三线同时处理”：如果不处理无人机，持续伤害会过高；如果忽视 Boss 本体，后续伤害提升会滚雪球；如果缺少爆发，护幕回合会拖长战斗。

## 事件池设计

第二幕事件池：

- `event_pool_act_2_easy`：混合 2 敌人事件，敌人总血量约 70-90。
- `event_pool_act_2_hard`：2-3 敌人事件，敌人总血量约 100-140，并带更多状态压力。
- `event_pool_act_2_miniboss`：2 个小 Boss 事件。
- `event_pool_act_2_boss`：1 个 Boss 事件。

第三幕事件池：

- `event_pool_act_3_easy`：2 敌人事件，敌人总血量约 100-130。
- `event_pool_act_3_hard`：2-3 敌人事件，敌人总血量约 140-180，并带强状态压力。
- `event_pool_act_3_miniboss`：2 个小 Boss 事件。
- `event_pool_act_3_boss`：1 个 Boss 事件。

所有 Boss 与带召唤的事件使用手动站位，保证 `ActionSummonEnemies.gd` 能把召唤物放进指定 slot。常规战斗继续使用自动站位。

## Boss 美术包装方向

本阶段不生成最终图片，但每个 Boss 的视觉包装先固定为后续资产验收标准。

### 熔炉心脏

主题：回收工厂深处的炉心机械，红橙主色，胸口是熔融核心，外圈有铆钉、散热孔、厚重炉门和熔渣管线。轮廓偏圆胖、重心低，保留现有敌人风格的 Q 版比例、粗黑描边、亮面金属块和透明 PNG。

后续图片要求：

- 透明背景。
- 可读尺寸接近现有 Boss。
- 主体占画布中部，留出左右召唤物空间。
- 发光核心与热管作为第一视觉锚点。
- 不使用写实密集机械细节。

### 至高主脑核心

主题：中央核心塔顶的指挥主脑，红黑银主色，中心为大型发光眼/核心，两侧有悬浮轨道炮或数据环，周围可有小无人机轮廓。整体比熔炉心脏更尖锐、更高阶，但仍保持 Q 版机械 Boss、粗描边、简洁色块和透明 PNG。

后续图片要求：

- 透明背景。
- 可读尺寸接近现有 Boss。
- 轮廓更高、更像最终主脑。
- 中央核心眼明显，左右悬浮组件不遮挡血条或意图。
- 不使用复杂背景，不把 Boss 融入场景图。

## 测试策略

新增一个数据回归测试，覆盖以下行为：

1. `act_2` 和 `act_3` 的普通、困难、小 Boss、Boss 池不再引用第一幕战斗池或第一幕 Boss 池。
2. 新增事件池中的每个事件都能解析到存在的 `EventData`。
3. 每个新增战斗事件至少有一个有效敌人。
4. 每个新增敌人都能解析到存在的 `EnemyData`，敌人贴图路径非空且文件存在。
5. 第二幕 Boss 是 `enemy_act_2_boss_foundry_heart`，类型为 `BOSS`，血量高于第一幕 Boss。
6. 第三幕 Boss 是 `enemy_act_3_boss_overmind_core`，类型为 `BOSS`，血量高于第二幕 Boss。
7. 第二幕和第三幕地图生成后，Boss 节点分别从本幕 Boss 池抽取对应事件。

同时运行现有地图生成回归和敌人打包回归，确保没有破坏第一幕地图布局和旧敌人资产。

## 验收标准

1. 开始 run 后第一幕仍能生成现有地图。
2. 击败第一幕 Boss 后进入第二幕，第二幕地图 Boss 节点使用 `event_pool_act_2_boss`。
3. 击败第二幕 Boss 后进入第三幕，第三幕地图 Boss 节点使用 `event_pool_act_3_boss`。
4. 第三幕 Boss 后触发 run victory。
5. 二、三幕普通战斗、小 Boss、Boss 事件都能加载敌人且不会引用缺失资源。
6. Boss 行为数据包含完整 `initial` 状态和可循环的攻击状态。
7. 所有新增测试通过，现有地图和敌人相关回归测试通过。

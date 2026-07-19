# GM 指令控制台设计

## 背景

项目需要一个 debug/GM 功能，支持通过特殊按键呼出指令入口，方便在运行中快速测试卡牌、遗物、消耗品、角色资源和战斗状态。第一版先实现文本命令行，后续保留扩展为图形 GM 面板的空间。

本设计遵循现有数据驱动架构：卡牌、遗物、消耗品和敌人都从 `external/data/` 加载到 `Global` 的数据表中；运行时状态集中在 `Global.player_data`，动作系统由 `ActionHandler` / `ActionGenerator` 驱动。

## 目标

- 使用数字键 `1` 左边的物理键呼出或隐藏 GM 控制台。
- 第一版提供文本命令输入和结果输出。
- 支持测试所有卡牌、遗物、消耗品、资源和基础战斗状态。
- GM 代码集中放在 `scripts/dev/`，避免污染卡牌、遗物、战斗和普通 UI 脚本。
- 非法命令、非法 ID、状态不满足时返回明确错误，不导致游戏崩溃。
- 默认仅在 editor/debug 环境启用，不进入正式导出体验。

## 非目标

- 第一版不做完整图形 GM 面板。
- 第一版不做事件、地图、商店、宝箱跳转测试。
- 第一版不做命令历史持久化或自动补全。
- 第一版不修改 JSON 数据结构，不新增卡牌、遗物或敌人配置格式。

## 方案选择

采用“根级文本 GM 控制台 + 独立命令执行器”的方案。

`Root.gd` 只负责捕获呼出键并切换控制台显示。控制台 UI 和命令解析放在 `scripts/dev/GMConsole.gd`，实际运行态修改放在 `scripts/dev/GMCommandExecutor.gd`。这样可以让入口全场景可用，同时让调试逻辑与正式游戏逻辑保持边界。

不优先采用“所有 GM 指令都转成 BaseAction”的方案。部分 GM 能力本质是调试运行时，例如清空行动队列、直接改资源、直接发卡到手牌，强行转成 action 会增加复杂度。需要保留游戏语义的操作仍复用现有接口：添加遗物走 `PlayerData.add_artifact()`，添加永久卡牌走 `PlayerData.add_card_to_deck()`，战斗内加手牌或抽牌堆分别走 `Signals.card_add_to_hand_requested` 和 `Signals.card_add_to_draw_requested`。

## 组件设计

### Root 入口

`Root.gd` 新增 GM 控制台子节点引用和键盘输入处理。

- 捕获数字键 `1` 左边物理键位。
- 只在 `GMCommandExecutor.is_enabled()` 判断通过时响应。
- 当控制台可见时，将键盘焦点交给输入框。
- 当控制台隐藏时，释放焦点并继续普通游戏输入。

为了避免中文输入法导致字符不同，呼出逻辑使用物理键位，例如 `physical_keycode == KEY_QUOTELEFT`，不依赖输入出来的字符是 `·`、`` ` `` 还是 `~`。

### GMConsole

新增 `scripts/dev/GMConsole.gd`，挂在 `Root` 下的一个轻量 `Control` 节点。

职责：

- 显示半透明输入区域和输出日志。
- 接收 `LineEdit` 提交的文本。
- 调用 `GMCommandExecutor.execute(command_text)`。
- 将返回结果追加到日志。
- 支持 `Esc` 隐藏控制台。
- 支持 `help` 展示可用命令。

第一版 UI 只需要能可靠输入和看到反馈，不追求视觉复杂度。布局应使用固定顶部或底部条，避免遮挡主要调试信息过多。

### GMCommandExecutor

新增 `scripts/dev/GMCommandExecutor.gd`，负责命令解析、校验和执行。

职责：

- 提供 `is_enabled()`，默认在非 exported 环境启用，在正式导出中禁用。
- 将命令文本按空白拆分为 token。
- 标准化命令别名。
- 校验是否已开始 run、是否处于战斗中、ID 是否存在、参数是否为整数。
- 调用现有 `Global`、`PlayerData`、`Signals`、`ActionHandler` 完成操作。
- 返回结构化结果，例如 `{ "ok": true, "message": "..." }`，由控制台显示。

解析保持简单、确定，不引入复杂表达式语言。

## 第一版命令

### 通用

- `help`：列出命令。
- `clear`：清空控制台输出。

### 卡牌

- `cards all [deck|hand|draw]`
  - 将所有已加载卡牌各复制一张加入指定位置。
  - 默认位置为 `deck`。
- `card add <card_id> [deck|hand|draw]`
  - 将指定卡牌复制一张加入指定位置。
  - 默认位置为 `deck`。

卡牌 ID 来自 `Global.get_card_data(card_id)`。加入 `deck` 时调用 `Global.player_data.add_card_to_deck()`，保留 `card_add_to_deck_actions` 和 `Signals.card_added_to_deck`。加入 `hand` 时要求处于战斗中，通过 `Signals.card_add_to_hand_requested` 让 `Hand.gd` 维护 UI 和 pile 状态；加入 `draw` 时通过 `Signals.card_add_to_draw_requested` 添加到抽牌堆顶部。

### 遗物

- `artifacts all`
  - 将所有已加载遗物加入玩家。
- `artifact add <artifact_id>`
  - 加入指定遗物。

遗物 ID 来自 `Global.get_artifact_data(artifact_id)`。添加遗物统一调用 `Global.player_data.add_artifact()`，保留 `artifact_add_actions`、脚本副作用、遗物栏刷新和从遗物池移除的现有行为。

### 消耗品

- `consumable add <consumable_id>`
  - 添加指定消耗品到空槽。

消耗品 ID 来自 `Global.get_consumable_data(consumable_id)`。执行时复用现有 `Signals.add_consumable_requested` 或 `ActionAddConsumable` 路径，以保留槽位和 UI 刷新逻辑。若槽位已满，返回错误。

### 玩家资源

- `money set <amount>`
- `money add <amount>`
- `hp set <amount>`
- `hp heal <amount>`
- `hp max <amount>`
- `energy set <amount>`
- `energy add <amount>`

这些命令要求已开始 run。金币和生命调用 `PlayerData` 现有方法，触发对应信号。能量只在战斗中有实际意义，但允许在 run 中设置；若当前 UI 依赖信号刷新，执行器需要发出对应资源变化信号。

### 战斗

- `enemy spawn <enemy_id> [slot]`
  - 在指定槽位生成敌人，默认槽位为 `0`。
- `combat win`
  - 快速结束当前战斗，触发战斗结束流程。
- `actions clear`
  - 调用 `ActionHandler.clear_all_actions()`，清空当前 action 栈。

这些命令要求已开始 run，并且除 `actions clear` 外要求当前处于战斗中。敌人 ID 来自 `Global.get_enemy_data(enemy_id)`。

## 状态和错误处理

命令执行前按顺序校验：

1. 命令是否为空。
2. 命令名是否存在。
3. 当前是否启用 GM。
4. 是否需要 run，且 `Global.is_run == true`。
5. 是否需要战斗，且 `Global.is_player_in_combat() == true`。
6. ID 是否存在。
7. 数值参数是否有效。

失败时返回一行明确错误，例如：

- `ERR: unknown command 'foo'. Use help.`
- `ERR: card not found: card_missing`
- `ERR: command requires an active run`
- `ERR: command requires combat`

## 测试设计

新增 Godot 回归测试，覆盖以下行为：

- 根场景实例化后存在 GM 控制台入口。
- 物理呼出键能切换控制台显示。
- `help` 返回可用命令文本。
- 空命令和未知命令返回错误，不崩溃。
- `cards all deck` 会按已加载卡牌数量向牌库添加卡牌。
- `artifacts all` 会向玩家添加遗物，并触发玩家遗物集合变化。
- `consumable add <id>` 能添加已存在消耗品。
- `money`、`hp`、`energy` 命令能修改运行态资源。
- `actions clear` 能清空 action 队列。
- 战斗限定命令在非战斗状态返回错误。

测试直接构造 `Global.player_data` 的运行态，不依赖手动点击标题页流程。涉及 UI 的按键测试只验证根节点切换逻辑，不做复杂视觉快照。

## 后续扩展

后续可以在同一执行器之上增加图形面板：

- 卡牌、遗物、消耗品、敌人搜索列表。
- 常用命令按钮。
- 当前 run 状态查看。
- 命令历史和自动补全。
- 地图、事件、商店、宝箱测试能力。

图形面板只作为命令执行器的另一层调用入口，不重新实现 GM 逻辑。

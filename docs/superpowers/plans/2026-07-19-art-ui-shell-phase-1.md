# 美术 UI 外壳 Phase 1 实施计划

> **给 agentic workers：** 必须使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 按任务执行本计划。步骤使用 checkbox（`- [ ]`）追踪。

**目标：** 在不依赖新一批插画资产的前提下，让玩家第一眼看到的主菜单、选角、战斗 HUD 和卡牌模板进入统一的明快二次元 UI 系统。

**架构：** 新增一个小型 `ArtUIShell` 运行时样式 helper，由现有 UI 脚本调用并生成可见外壳节点。场景文件只做必要的硬资源引用清理，主要改动集中在稳定节点和回归测试。

**技术栈：** Godot 4、GDScript、现有 `.tscn` 场景、现有主题资源、Godot headless 回归测试。

## 全局约束

- Superpower 项目开发文档使用中文。
- 不改变卡牌逻辑、敌人逻辑、地图生成、奖励规则或 JSON 数据 schema。
- 保留类《杀戮尖塔》的交互契约：顶部资源、中部战斗、底部手牌、拖拽选目标、右下角结束回合。
- 视觉方向为二次元角色核心，加《弹射世界》式白/青模块化面板与橙色主操作。
- Phase 1 不引入新的必需 bitmap 插画资产。
- 优先使用可复用的运行时 UI 外壳样式，避免手工重皮肤大量无关 scene 节点。

---

### Task 1：可见外壳合同测试

**文件：**
- 新建：`tests/art_ui_shell_phase_1_regression.gd`

**接口：**
- 消费：`scenes/Root.tscn`、`scenes/ui/Card.tscn`
- 产出：后续任务依赖的命名节点、样式 metadata、绘制层级和可见性回归约束。

- [ ] **Step 1：编写失败测试**

创建 `tests/art_ui_shell_phase_1_regression.gd`，检查：
- `TitleScreen/MainMenu` 有 `ShellPanel` 和 `HeroBadge`。
- `TitleScreen/NewRunMenu` 有 `CharacterInfoPanel`、`RunSetupPanel`、`ModifierPanel`。
- `RunScreen/Combat` 有 `TopResourceBar`、`LeftPileDock`、`RightPileDock`、`HandTray`。
- `scenes/ui/Card.tscn` 有 `FactionBadge`、`ArtFrame`、`DescriptionPanel`。
- 战斗外壳绘制在 `BackgroundButton` 之上，避免被背景盖住。
- `HandTray` 跟随战斗 HUD 显隐，非战斗状态不残留。
- 卡牌 `FactionBadge`、`ArtFrame`、`DescriptionPanel` 绘制在卡牌白底之上，且角标颜色来自 `ColorData`。

- [ ] **Step 2：运行测试确认 RED**

运行：`godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
预期：exit 1，并报告缺少外壳节点或层级不正确。

- [ ] **Step 3：提交**

提交信息：`test: add art ui shell phase 1 contract`

### Task 2：共享运行时 UI 外壳

**文件：**
- 新建：`scripts/ui/ArtUIShell.gd`
- 修改：`scenes/Root.tscn`
- 修改：`scripts/ui/menus/TitleScreen.gd`
- 修改：`scripts/ui/menus/NewRunMenu.gd`
- 修改：`scripts/ui/Combat.gd`

**接口：**
- 消费：Task 1 断言的节点名。
- 产出：`ArtUIShell.ensure_color_panel(parent, node_name, rect, role, color, insert_after_node_name)`、`ArtUIShell.apply_button(button, role)`、`ArtUIShell.apply_label_capsule(label, role)`、`ArtUIShell.apply_texture_button_shell(button, role)`。

- [ ] **Step 1：实现最小样式 helper 和外壳节点**

新增 `ArtUIShell.gd`，提供白/青/橙色按钮、标签和外壳面板样式。为标题、选角、战斗资源条、左右牌堆 dock 和手牌托盘创建运行时外壳节点。所有外壳节点必须 `MOUSE_FILTER_IGNORE`，不能阻挡已有交互。

- [ ] **Step 2：清理 Root 的外部图片硬引用**

从 `Root.tscn` 移除 `external/sprites/ui/flipper/*` 的 `Texture2D` 硬资源引用。由 `TitleScreen.gd` 和 `Combat.gd` 在 `_ready()` 中通过 `FileLoader.load_texture_or_fallback` 加载背景和图标。

- [ ] **Step 3：运行测试确认 GREEN**

运行：`godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
预期：`ALL_TESTS_PASSED`。

- [ ] **Step 4：提交**

提交信息：`feat: add visible art ui shell`

### Task 3：卡牌模板首版 chrome

**文件：**
- 修改：`scripts/ui/Card.gd`
- 修改：`tests/art_ui_shell_phase_1_regression.gd`

**接口：**
- 消费：`ArtUIShell`。
- 产出：运行时创建的 `FactionBadge`、`ArtFrame`、`DescriptionPanel`，让阵营、插画窗口和描述区在手牌尺寸下更明确。

- [ ] **Step 1：扩展测试**

断言 `FactionBadge` 颜色来自卡牌 `ColorData`，并绘制在 `Background` 之上；`ArtFrame` 位于插画后方但在白底上方；`DescriptionPanel` 位于描述文本后方但在白底上方。

- [ ] **Step 2：运行测试确认 RED**

运行：`godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
预期：exit 1，并报告卡牌 chrome 层级或颜色行为缺失。

- [ ] **Step 3：实现最小卡牌 chrome**

在 `Card.gd` 运行时创建三个 shell 节点，保持现有 144x184 卡牌尺寸、文字布局和交互信号不变。

- [ ] **Step 4：运行测试确认 GREEN**

运行：`godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
预期：`ALL_TESTS_PASSED`。

- [ ] **Step 5：提交**

提交信息：`feat: skin card chrome phase 1`

### Task 4：验证

**文件：**
- 只运行测试。

**接口：**
- 消费：全部 Phase 1 改动。
- 产出：交付前验证证据。

- [ ] **Step 1：运行聚焦 UI 外壳测试**

运行：`godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
预期：`ALL_TESTS_PASSED`。

- [ ] **Step 2：运行现有安全回归**

运行：
- `godot --headless --path . --script tests/art_asset_contract_regression.gd`
- `godot --headless --path . --script tests/custom_ui_artifact_regression.gd`
- `godot --headless --path . --script tests/rest_pick_config_regression.gd`
- `godot --headless --path . --script tests/map_location_layout_regression.gd`
- `godot --headless --path . --script tests/gm_console_toggle_regression.gd`
- `godot --headless --path . --script tests/map_location_icon_regression.gd`

预期：每条都打印 `ALL_TESTS_PASSED`。

- [ ] **Step 3：检查 diff 范围**

运行：`git diff --stat main..HEAD`
预期：改动限制在 Phase 1 文档、一个 shell helper、可见 UI 场景/脚本和测试。

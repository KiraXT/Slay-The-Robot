# 标题与角色选择完整演出改造实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有标题/主菜单和角色选择改造成明快浮岛奇幻风格的连续演出，同时完整保留存档、图鉴、设置、难度、种子和自定义规则行为。

**Architecture:** 从 `Root.tscn` 抽离独立 `TitleScreen.tscn`，由 `TitleScreen.gd` 管理明确状态，`TitlePerformanceController.gd` 管理可跳过 Tween 和稳定最终状态，`MenuBackdrop.gd` 管理分层背景、视差与角色背景淡变。角色选择通过局部信号把 `CharacterData` 和完整开局参数交给标题协调器，最后仍调用现有 `Global.start_run()`。

**Tech Stack:** Godot 4.6、GDScript、JSON 数据、PNG 位图资产、现有 `SceneTree` headless 回归测试。

## Global Constraints

- 逻辑画布保持 1200x700；`window/stretch/mode="canvas_items"` 与 `window/stretch/aspect="expand"` 不变。
- 不实现账号登录、联网身份、云存档或用户系统。
- 视觉保持现有明快浮岛奇幻和 Q 版角色立绘方向；机器人只作为遗迹、符文装置和机械纹样细节。
- 不复制《杀戮尖塔》的角色、背景、字体、图标或界面资产，只参考演出层次和交互反馈。
- 保留继续游戏、放弃当前流程、新的冒险、图鉴、设置、退出、难度、种子和自定义规则的现有逻辑。
- 不修改角色战斗数值、初始卡组、遗物效果、开局地图规则、图鉴内部布局或设置内部布局。
- 标题首次进入目标 1.05 秒；主菜单到选人目标 0.80 秒；角色切换目标 0.22 秒；确认开局目标 0.65 秒；局部调整不超过 0.10 秒。
- 所有瞬态演出必须提供统一最终状态函数；重复确认最多调用一次开局；快速切换以最后一次输入为准。
- 新增背景图不得包含角色、文字或 UI；游戏名称继续由 Godot 文本节点渲染。
- 新增位图统一使用 PNG；标题与角色背景为 1200x700，粒子贴图为 64x64。
- 不新增配乐；只沿用现有 BGM 和 UI 音效接口。

## File Map

### 新建

- `scenes/ui/menus/TitleScreen.tscn`：独立标题场景，承载背景、主菜单、选人、图鉴和设置。
- `scripts/ui/menus/TitlePerformanceController.gd`：标题入场、菜单/选人转场、开局确认和最终状态复位。
- `scripts/ui/menus/MenuBackdrop.gd`：静态分层资源、空闲视差、角色背景交叉淡变和粒子启停。
- `tests/title_screen_asset_regression.gd`：验证标题资产、角色背景和角色 JSON 路径。
- `tests/title_screen_performance_regression.gd`：验证场景结构、状态、跳过、角色数据和单次开局请求。
- `external/sprites/ui/title_screen/title_sky.png`
- `external/sprites/ui/title_screen/title_far_islands.png`
- `external/sprites/ui/title_screen/title_mid_ruins.png`
- `external/sprites/ui/title_screen/title_platform.png`
- `external/sprites/ui/title_screen/title_foreground.png`
- `external/sprites/ui/title_screen/title_ornament.png`
- `external/sprites/ui/title_screen/particle_soft.png`
- `external/sprites/ui/title_screen/particle_spark.png`
- 四个角色目录下各自的 `<character_id>_background.png`。

### 修改

- `scenes/Root.tscn`：用 `TitleScreen.tscn` 实例替换内嵌标题分支。
- `scripts/ui/menus/TitleScreen.gd`：改为状态协调器。
- `scripts/ui/menus/MainMenu.gd`：保留命令行为，增加稳定焦点和按钮反馈。
- `scripts/ui/menus/NewRunMenu.gd`：局部角色信号、空状态、完整开局请求和展示回退。
- `scripts/ui/CharacterButtonContainer.gd`：局部选择信号、确定焦点顺序和空列表结果。
- `scripts/ui/CharacterSelectionButton.gd`：选中/焦点反馈并发出局部信号。
- `scenes/ui/CharacterSelectionButton.tscn`：头像尺寸、轮廓和选中装饰。
- `themes/title_screen_theme.tres`：紧凑明亮的标题控件样式。
- `external/data/characters/character_red.json`
- `external/data/characters/character_blue.json`
- `external/data/characters/character_green.json`
- `external/data/characters/character_orange.json`
- `tests/ui_layout_bounds_regression.gd`：新场景路径、三栏布局和宽屏边界。
- `tests/codex_menu_display_regression.gd`：确认场景抽离后图鉴路径不回归。
- `docs/superpowers/specs/2026-07-12-title-character-selection-performance-design.md`：补充难度、种子和自定义规则保留要求。

---

### Task 1: 制作并登记标题与角色舞台资产

**Files:**
- Create: `tests/title_screen_asset_regression.gd`
- Create: `external/sprites/ui/title_screen/*.png`
- Create: `external/sprites/characters/character_red/character_red_background.png`
- Create: `external/sprites/characters/character_blue/character_blue_background.png`
- Create: `external/sprites/characters/character_green/character_green_background.png`
- Create: `external/sprites/characters/character_orange/character_orange_background.png`
- Modify: `external/data/characters/character_red.json`
- Modify: `external/data/characters/character_blue.json`
- Modify: `external/data/characters/character_green.json`
- Modify: `external/data/characters/character_orange.json`

**Interfaces:**
- Consumes: 现有角色立绘、头像、`external/sprites/acts/act_1_background.png` 和 `external/sprites/ui/flipper/background_soft_cyan.png` 作为画风参考。
- Produces: `MenuBackdrop.TITLE_LAYER_PATHS` 使用的八个标题资产，以及四个可由 `CharacterData.character_background_texture_path` 加载的背景路径。

- [ ] **Step 1: 写资产失败测试**

创建 `tests/title_screen_asset_regression.gd`，核心检查如下：

```gdscript
extends SceneTree

const TITLE_ASSETS := {
	"external/sprites/ui/title_screen/title_sky.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_far_islands.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_mid_ruins.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_platform.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_foreground.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_ornament.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/particle_soft.png": Vector2i(64, 64),
	"external/sprites/ui/title_screen/particle_spark.png": Vector2i(64, 64),
}
const CHARACTER_IDS := ["character_red", "character_blue", "character_green", "character_orange"]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for path: String in TITLE_ASSETS:
		_check_image(path, TITLE_ASSETS[path])
	for character_id: String in CHARACTER_IDS:
		var data: CharacterData = Global.get_character_data(character_id)
		if data == null or data.character_background_texture_path.is_empty():
			failures.append("%s has no character background path" % character_id)
		else:
			_check_image(data.character_background_texture_path, Vector2i(1200, 700))
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

func _check_image(path: String, expected_size: Vector2i) -> void:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % path)
	if not FileAccess.file_exists(absolute_path):
		failures.append("Missing image: %s" % path)
		return
	var image := Image.load_from_file(absolute_path)
	if image == null or image.get_size() != expected_size:
		failures.append("%s must be %s" % [path, expected_size])
```

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless --path . --script tests/title_screen_asset_regression.gd`

Expected: FAIL，列出尚未创建的标题资产和空的角色背景路径。

- [ ] **Step 3: 使用 imagegen 制作标题分层资产**

执行前调用 `imagegen` skill。以现有 `act_1_background.png`、`background_soft_cyan.png` 和四个角色头像作为风格参考，禁止生成角色、文字和 UI。使用以下固定方向：

```text
明快日间浮岛奇幻世界，清澈青蓝天空、白色云海、浅色遗迹石材、少量青绿色植物和金色装饰，Q版二次元游戏背景画风，轮廓清晰、色彩通透、适配现有角色立绘。机械与机器人元素只作为遗迹关节和小型发光符文细节。画面为1200x700游戏标题舞台，不含角色、文字、Logo、按钮或界面。
```

先生成完整母版，再分别编辑为天空、远景浮岛、中景遗迹、平台和前景透明层；`title_ornament.png` 只保留浅色石材与金色/青色装饰形体，不生成任何字形。粒子贴图分别为柔光圆点和四角星光，透明背景。

- [ ] **Step 4: 制作四个同透视角色背景**

四张背景使用同一地平线、平台位置和远景构图，只替换局部配色与小型装饰：红色偏暖阳和训练场纹样，蓝色偏清凉水晶和流动能量，绿色偏青绿植物和音乐/能量符文，橙色偏金色旅行物件和轻机械结构。每张图不含角色、文字和 UI。

- [ ] **Step 5: 规范尺寸和文件名**

使用图像工具将标题/角色背景定为 1200x700，将粒子定为 64x64。运行：

Run: `sips -g pixelWidth -g pixelHeight external/sprites/ui/title_screen/*.png external/sprites/characters/character_*/character_*_background.png`

Expected: 六个标题大图和四个角色背景均为 1200x700，两个粒子贴图均为 64x64。

- [ ] **Step 6: 更新角色 JSON 路径**

四个 JSON 分别设置：

```json
"character_background_texture_path": "external/sprites/characters/character_red/character_red_background.png"
```

蓝、绿、橙角色使用对应目录和文件名，不修改其他字段。

- [ ] **Step 7: 运行资产回归**

Run: `godot --headless --path . --script tests/title_screen_asset_regression.gd`

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 8: 提交资产与数据**

```bash
git add tests/title_screen_asset_regression.gd external/sprites/ui/title_screen external/sprites/characters/character_red/character_red_background.png external/sprites/characters/character_blue/character_blue_background.png external/sprites/characters/character_green/character_green_background.png external/sprites/characters/character_orange/character_orange_background.png external/data/characters/character_red.json external/data/characters/character_blue.json external/data/characters/character_green.json external/data/characters/character_orange.json
git commit -m "feat: add title and character stage artwork"
```

### Task 2: 抽离标题场景并锁定既有功能

**Files:**
- Create: `scenes/ui/menus/TitleScreen.tscn`
- Create: `tests/title_screen_performance_regression.gd`
- Modify: `scenes/Root.tscn`
- Modify: `tests/codex_menu_display_regression.gd`
- Modify: `tests/ui_layout_bounds_regression.gd`

**Interfaces:**
- Consumes: `Root.tscn` 当前 `TitleScreen` 分支和现有四个菜单脚本。
- Produces: `res://scenes/ui/menus/TitleScreen.tscn`，根节点名和 Root 实例名均为 `TitleScreen`，现有路径 `TitleScreen/MainMenu`、`TitleScreen/NewRunMenu`、`TitleScreen/CodexMenu`、`TitleScreen/SettingsMenu` 保持有效。

- [ ] **Step 1: 写场景结构失败测试**

在 `tests/title_screen_performance_regression.gd` 中加载独立场景并检查以下节点：

```gdscript
extends SceneTree

const TITLE_SCENE_PATH := "res://scenes/ui/menus/TitleScreen.tscn"
const REQUIRED_PATHS := [
	"MainMenu/VBoxContainer/ContinueButton",
	"MainMenu/VBoxContainer/ForfeitRunButton",
	"MainMenu/VBoxContainer/NewRunButton",
	"MainMenu/VBoxContainer/CodexButton",
	"MainMenu/VBoxContainer/SettingsButton",
	"MainMenu/VBoxContainer/ExitButton",
	"NewRunMenu/DifficultySelect",
	"NewRunMenu/CharacterButtonContainer",
	"NewRunMenu/CustomRunModifierButtonContainer",
	"NewRunMenu/SeedInput",
	"NewRunMenu/StartRunButton",
	"NewRunMenu/BackButton",
	"CodexMenu",
	"SettingsMenu",
]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load(TITLE_SCENE_PATH)
	if packed == null:
		push_error("Missing TitleScreen.tscn")
		quit(1)
		return
	var title_screen := packed.instantiate()
	root.add_child(title_screen)
	await process_frame
	for path: String in REQUIRED_PATHS:
		if not title_screen.has_node(path):
			failures.append("Missing title node: %s" % path)
	title_screen.queue_free()
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
```

- [ ] **Step 2: 运行结构测试确认失败**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: FAIL with `Missing TitleScreen.tscn`。

- [ ] **Step 3: 抽离现有 TitleScreen 分支**

把 `Root.tscn` 的 `TitleScreen` 及其 `MainMenu`、`NewRunMenu`、`CodexMenu`、`SettingsMenu` 全部分支移动到新场景。新场景根节点必须保留：

```text
TitleScreen (Control, unique_name_in_owner=true, 1200x700)
├── Background
├── BackgroundArt
├── MainMenu
├── NewRunMenu
├── CodexMenu
└── SettingsMenu
```

在 `Root.tscn` 中新增 `PackedScene` 外部资源并实例化，实例节点仍命名为 `TitleScreen`。不要修改四个菜单内部节点名。

- [ ] **Step 4: 更新现有测试为稳定子场景路径**

`tests/codex_menu_display_regression.gd` 和 `tests/ui_layout_bounds_regression.gd` 继续从 `Root.tscn` 访问 `TitleScreen/...`；另增加断言：

```gdscript
var title_screen: Control = root_scene.get_node("TitleScreen")
if title_screen.scene_file_path != "res://scenes/ui/menus/TitleScreen.tscn":
	failures.append("Root must instance the extracted TitleScreen scene")
```

- [ ] **Step 5: 运行场景与既有回归**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: `ALL_TESTS_PASSED`

Run: `godot --headless --path . --script tests/codex_menu_display_regression.gd`

Expected: `ALL_TESTS_PASSED`

Run: `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 6: 提交场景抽离**

```bash
git add scenes/Root.tscn scenes/ui/menus/TitleScreen.tscn tests/title_screen_performance_regression.gd tests/codex_menu_display_regression.gd tests/ui_layout_bounds_regression.gd
git commit -m "refactor: extract title screen scene"
```

### Task 3: 建立可跳过的标题状态机与动画控制器

**Files:**
- Create: `scripts/ui/menus/TitlePerformanceController.gd`
- Modify: `scripts/ui/menus/TitleScreen.gd`
- Modify: `scenes/ui/menus/TitleScreen.tscn`
- Modify: `tests/title_screen_performance_regression.gd`

**Interfaces:**
- Consumes: `MainMenu`、`NewRunMenu`、`CodexMenu`、`SettingsMenu` 节点。
- Produces: `TitleScreen.get_screen_state_name() -> String`、`TitleScreen.skip_active_transition() -> void`、`TitlePerformanceController.play_*()` 和四个 `apply_*_state()` 最终状态函数。

- [ ] **Step 1: 扩展失败测试覆盖状态和跳过**

在测试中实例化标题场景，并加入：

```gdscript
title_screen.skip_active_transition()
_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "intro skip")

title_screen.show_new_run_menu()
title_screen.skip_active_transition()
_assert_equal(title_screen.get_screen_state_name(), "CHARACTER_SELECT", "new run skip")

title_screen.show_main_menu()
title_screen.skip_active_transition()
_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "back skip")
```

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: FAIL，因为 `get_screen_state_name()` 和 `skip_active_transition()` 尚不存在。

- [ ] **Step 3: 新建动画控制器接口**

先在 `TitleScreen.tscn` 中把现有背景包进 `Backdrop`，把标题文字移到根节点 `GameTitle`，并新增透明的 `TitleOrnament` 与 `TransitionOverlay`。这些节点均设为 `unique_name_in_owner=true`。`TitlePerformanceController.gd` 使用以下完整基础实现；Task 6 只增强时间线，不改公开接口：

```gdscript
extends Node
class_name TitlePerformanceController

signal transition_finished(target_state: String)

const INTRO_DURATION := 1.05
const TO_CHARACTER_DURATION := 0.80
const TO_MAIN_DURATION := 0.60
const RUN_CONFIRM_DURATION := 0.65

var active_tween: Tween
var active_target_state: String = ""
var title_rest_position: Vector2
var main_menu_rest_position: Vector2
var new_run_rest_position: Vector2

@onready var backdrop: Control = $%Backdrop
@onready var title_ornament: TextureRect = $%TitleOrnament
@onready var game_title: Label = $%GameTitle
@onready var main_menu: Control = $%MainMenu
@onready var new_run_menu: Control = $%NewRunMenu
@onready var transition_overlay: ColorRect = $%TransitionOverlay

func _ready() -> void:
	title_rest_position = game_title.position
	main_menu_rest_position = main_menu.position
	new_run_rest_position = new_run_menu.position

func play_title_intro() -> void:
	apply_entering_state()
	_start_sequence("MAIN_MENU")
	active_tween.tween_property(backdrop, "modulate:a", 1.0, 0.55)
	active_tween.tween_property(game_title, "position", title_rest_position, 0.57).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(game_title, "modulate:a", 1.0, 0.30).set_delay(0.18)
	active_tween.tween_property(main_menu, "position", main_menu_rest_position, 0.35).set_delay(0.45)
	active_tween.tween_property(main_menu, "modulate:a", 1.0, 0.35).set_delay(0.45)
	active_tween.tween_callback(_finish_sequence.bind("MAIN_MENU")).set_delay(INTRO_DURATION)

func play_to_character_select() -> void:
	_start_sequence("CHARACTER_SELECT")
	new_run_menu.visible = true
	new_run_menu.position = new_run_rest_position + Vector2(24.0, 0.0)
	new_run_menu.modulate.a = 0.0
	active_tween.tween_property(main_menu, "position:x", -main_menu.size.x, 0.18)
	active_tween.tween_property(main_menu, "modulate:a", 0.0, 0.18)
	active_tween.tween_property(new_run_menu, "position", new_run_rest_position, 0.35).set_delay(0.35)
	active_tween.tween_property(new_run_menu, "modulate:a", 1.0, 0.35).set_delay(0.35)
	active_tween.tween_callback(_finish_sequence.bind("CHARACTER_SELECT")).set_delay(TO_CHARACTER_DURATION)

func play_to_main_menu() -> void:
	_start_sequence("MAIN_MENU")
	main_menu.visible = true
	main_menu.position = main_menu_rest_position - Vector2(24.0, 0.0)
	main_menu.modulate.a = 0.0
	active_tween.tween_property(new_run_menu, "position:x", new_run_rest_position.x + new_run_menu.size.x, 0.28)
	active_tween.tween_property(new_run_menu, "modulate:a", 0.0, 0.28)
	active_tween.tween_property(main_menu, "position", main_menu_rest_position, 0.30).set_delay(0.20)
	active_tween.tween_property(main_menu, "modulate:a", 1.0, 0.30).set_delay(0.20)
	active_tween.tween_callback(_finish_sequence.bind("MAIN_MENU")).set_delay(TO_MAIN_DURATION)

func play_run_confirm() -> void:
	_start_sequence("LEAVING")
	transition_overlay.visible = true
	transition_overlay.modulate.a = 0.0
	active_tween.tween_property(new_run_menu, "modulate:a", 0.0, 0.35).set_delay(0.20)
	active_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.25).set_delay(0.40)
	active_tween.tween_callback(_finish_sequence.bind("LEAVING")).set_delay(RUN_CONFIRM_DURATION)

func complete_active_transition() -> void:
	if active_target_state.is_empty():
		return
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	_finish_sequence(active_target_state)

func apply_entering_state() -> void:
	backdrop.visible = true
	backdrop.modulate.a = 0.0
	title_ornament.visible = true
	game_title.visible = true
	game_title.position = title_rest_position - Vector2(0.0, 24.0)
	game_title.modulate.a = 0.0
	main_menu.visible = true
	main_menu.position = main_menu_rest_position - Vector2(20.0, 0.0)
	main_menu.modulate.a = 0.0
	main_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_run_menu.visible = false
	transition_overlay.visible = false

func apply_main_menu_state() -> void:
	backdrop.visible = true
	backdrop.modulate.a = 1.0
	game_title.visible = true
	game_title.position = title_rest_position
	game_title.modulate.a = 1.0
	main_menu.visible = true
	main_menu.position = main_menu_rest_position
	main_menu.modulate.a = 1.0
	main_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	new_run_menu.visible = false
	new_run_menu.position = new_run_rest_position
	new_run_menu.modulate.a = 1.0
	transition_overlay.visible = false

func apply_character_select_state() -> void:
	backdrop.visible = true
	backdrop.modulate.a = 1.0
	game_title.visible = false
	main_menu.visible = false
	new_run_menu.visible = true
	new_run_menu.position = new_run_rest_position
	new_run_menu.modulate.a = 1.0
	new_run_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_overlay.visible = false

func apply_leaving_state() -> void:
	main_menu.visible = false
	new_run_menu.visible = false
	transition_overlay.visible = true
	transition_overlay.modulate.a = 1.0

func _start_sequence(target_state: String) -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	active_target_state = target_state
	active_tween = create_tween().set_parallel(true)

func _finish_sequence(target_state: String) -> void:
	match target_state:
		"MAIN_MENU": apply_main_menu_state()
		"CHARACTER_SELECT": apply_character_select_state()
		"LEAVING": apply_leaving_state()
	active_tween = null
	active_target_state = ""
	transition_finished.emit(target_state)
```

- [ ] **Step 4: 将 TitleScreen.gd 改为状态协调器**

使用以下状态和公开行为：

```gdscript
enum ScreenState {
	ENTERING,
	MAIN_MENU,
	TO_CHARACTER_SELECT,
	CHARACTER_SELECT,
	TO_MAIN_MENU,
	CODEX,
	SETTINGS,
	LEAVING,
}

var screen_state := ScreenState.ENTERING

func get_screen_state_name() -> String:
	return ScreenState.keys()[screen_state]

func skip_active_transition() -> void:
	if screen_state in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU, ScreenState.LEAVING]:
		performance_controller.complete_active_transition()

func show_new_run_menu() -> void:
	if screen_state != ScreenState.MAIN_MENU:
		return
	screen_state = ScreenState.TO_CHARACTER_SELECT
	new_run_menu.populate_new_run_menu()
	performance_controller.play_to_character_select()

func show_main_menu() -> void:
	if screen_state == ScreenState.CHARACTER_SELECT:
		screen_state = ScreenState.TO_MAIN_MENU
		performance_controller.play_to_main_menu()
		return
	performance_controller.apply_main_menu_state()
	screen_state = ScreenState.MAIN_MENU
```

图鉴、设置和窗口恢复使用以下实现：

```gdscript
var previous_main_focus: Control

func show_codex_menu() -> void:
	if screen_state != ScreenState.MAIN_MENU:
		return
	previous_main_focus = get_viewport().gui_get_focus_owner()
	performance_controller.apply_main_menu_state()
	main_menu.visible = false
	codex_menu.visible = true
	codex_menu.populate_codex_menu()
	screen_state = ScreenState.CODEX

func show_settings_menu() -> void:
	if screen_state != ScreenState.MAIN_MENU:
		return
	previous_main_focus = get_viewport().gui_get_focus_owner()
	performance_controller.apply_main_menu_state()
	main_menu.visible = false
	settings_menu.visible = true
	screen_state = ScreenState.SETTINGS

func _restore_main_focus() -> void:
	if is_instance_valid(previous_main_focus) and previous_main_focus.visible:
		previous_main_focus.grab_focus()
	else:
		main_menu.grab_default_focus()

func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_IN or not is_node_ready():
		return
	if screen_state in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU, ScreenState.LEAVING]:
		performance_controller.complete_active_transition()
	elif screen_state == ScreenState.MAIN_MENU:
		performance_controller.apply_main_menu_state()
	elif screen_state == ScreenState.CHARACTER_SELECT:
		performance_controller.apply_character_select_state()
```

从 `CODEX` 或 `SETTINGS` 调用 `show_main_menu()` 时隐藏两个工具菜单、应用 `MAIN_MENU` 稳定状态并 `call_deferred("_restore_main_focus")`。`_unhandled_input()` 只在瞬态状态处理确认、取消和鼠标按下，用于调用 `skip_active_transition()`。

- [ ] **Step 5: 运行状态测试**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: `ALL_TESTS_PASSED`

测试中额外调用 `title_screen.notification(NOTIFICATION_APPLICATION_FOCUS_IN)`，验证瞬态会完成到目标状态，稳定态的可见性和焦点不会丢失。

- [ ] **Step 6: 提交状态控制**

```bash
git add scripts/ui/menus/TitlePerformanceController.gd scripts/ui/menus/TitleScreen.gd scenes/ui/menus/TitleScreen.tscn tests/title_screen_performance_regression.gd
git commit -m "feat: add skippable title screen transitions"
```

### Task 4: 重构角色选择数据流与单次开局请求

**Files:**
- Modify: `scripts/ui/CharacterSelectionButton.gd`
- Modify: `scripts/ui/CharacterButtonContainer.gd`
- Modify: `scripts/ui/menus/NewRunMenu.gd`
- Modify: `scripts/ui/menus/TitleScreen.gd`
- Modify: `scenes/ui/menus/TitleScreen.tscn`
- Modify: `tests/title_screen_performance_regression.gd`

**Interfaces:**
- Consumes: `Global.get_character_data()`、`Global.start_run(character_object_id, run_seed, difficulty_level, custom_modifier_ids)`。
- Produces: `CharacterSelectionButton.selected(character_object_id)`、`CharacterButtonContainer.character_selected(character_object_id)`、`NewRunMenu.character_changed(character_data)`、`NewRunMenu.run_requested(...)`、`NewRunMenu.back_requested`。

- [ ] **Step 1: 写角色和开局请求失败测试**

测试必须验证：默认角色不为空、角色变化信号包含 `CharacterData`、两次确认只发出一次请求、请求包含种子/难度/自定义规则、无效角色禁用开始按钮。

```gdscript
var new_run_menu: Control = title_screen.get_node("NewRunMenu")
new_run_menu.populate_new_run_menu()
await process_frame
if new_run_menu.selected_character_object_id.is_empty():
	failures.append("New run menu must select the first character")

var requests: Array = []
new_run_menu.run_requested.connect(func(character_id, seed, difficulty, modifiers):
	requests.append([character_id, seed, difficulty, modifiers])
)
new_run_menu.get_node("StartRunButton").button_up.emit()
new_run_menu.get_node("StartRunButton").button_up.emit()
if requests.size() != 1:
	failures.append("Start run must emit exactly one request")
```

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: FAIL，因为当前按钮使用全局角色信号，并且 `NewRunMenu` 直接调用 `Global.start_run()`。

- [ ] **Step 3: 改为局部角色选择信号**

`CharacterSelectionButton.gd`：

```gdscript
class_name CharacterSelectionButton

signal selected(character_object_id: String)

func _on_button_up() -> void:
	selected.emit(character_object_id)
```

`CharacterButtonContainer.gd`：

```gdscript
signal character_selected(character_object_id: String)

func populate_character_buttons() -> bool:
	clear_character_buttons()
	var character_ids: Array = Global._id_to_character_data.keys()
	character_ids.sort()
	var first_button: CharacterSelectionButton = null
	for character_id: String in character_ids:
		var button: CharacterSelectionButton = Scenes.CHARACTER_SELECTION_BUTTON.instantiate()
		grid_container.add_child(button)
		button.init(character_id)
		button.selected.connect(_on_button_selected)
		if first_button == null:
			first_button = button
	if first_button == null:
		return false
	first_button.button_pressed = true
	first_button.grab_focus()
	first_button.selected.emit(first_button.character_object_id)
	return true

func _on_button_selected(character_object_id: String) -> void:
	character_selected.emit(character_object_id)
```

- [ ] **Step 4: 让 NewRunMenu 发出完整请求并处理空状态**

新增接口：

```gdscript
signal character_changed(character_data: CharacterData)
signal run_requested(character_object_id: String, run_seed: int, difficulty_level: int, custom_modifier_ids: Array[String])
signal back_requested

var run_request_locked := false

func populate_new_run_menu() -> void:
	run_request_locked = false
	var has_characters := character_button_container.populate_character_buttons()
	custom_run_modifier_button_container.populate_custom_run_modifiers()
	empty_state_label.visible = not has_characters
	start_run_button.disabled = not has_characters

func _on_character_selected(character_object_id: String) -> void:
	selected_character_object_id = character_object_id
	var character_data := Global.get_character_data(character_object_id)
	if character_data == null:
		start_run_button.disabled = true
		empty_state_label.visible = true
		return
	populate_character_info(character_object_id)
	character_changed.emit(character_data)

func _on_start_run_button_up() -> void:
	if run_request_locked or selected_character_object_id.is_empty():
		return
	run_request_locked = true
	run_requested.emit(
		selected_character_object_id,
		seed_input.text.to_int(),
		selected_difficulty_level,
		custom_run_modifier_button_container.selected_custom_run_modififers.duplicate(),
	)

func _on_back_button_up() -> void:
	back_requested.emit()
```

刷新角色前先清空遗物纹理和文字。没有初始遗物或遗物数据缺失时，将纹理设为 `FileLoader.load_texture("external/sprites/ui/flipper/icon_menu.png")`，名称设为“无初始遗物”，描述置空，不保留上一个角色内容。

- [ ] **Step 5: 在 TitleScreen 中接管开局**

连接 `run_requested` 后保存一次请求，设置 `LEAVING` 并播放确认动画。`transition_finished("LEAVING")` 时执行：

```gdscript
Global.start_run(
	pending_run_request.character_object_id,
	pending_run_request.run_seed,
	pending_run_request.difficulty_level,
	pending_run_request.custom_modifier_ids,
)
pending_run_request = {}
```

`character_changed` 只更新舞台；`back_requested` 调用 `show_main_menu()`。

- [ ] **Step 6: 运行角色流程测试**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 7: 提交角色数据流**

```bash
git add scripts/ui/CharacterSelectionButton.gd scripts/ui/CharacterButtonContainer.gd scripts/ui/menus/NewRunMenu.gd scripts/ui/menus/TitleScreen.gd scenes/ui/menus/TitleScreen.tscn tests/title_screen_performance_regression.gd
git commit -m "refactor: isolate character selection flow"
```

### Task 5: 构建分层舞台、三栏选人布局和资源回退

**Files:**
- Create: `scripts/ui/menus/MenuBackdrop.gd`
- Modify: `scenes/ui/menus/TitleScreen.tscn`
- Modify: `themes/title_screen_theme.tres`
- Modify: `scenes/ui/CharacterSelectionButton.tscn`
- Modify: `scripts/ui/CharacterSelectionButton.gd`
- Modify: `scripts/ui/menus/TitleScreen.gd`
- Modify: `tests/ui_layout_bounds_regression.gd`
- Modify: `tests/title_screen_performance_regression.gd`

**Interfaces:**
- Consumes: Task 1 资产路径、`CharacterData.character_texture_path`、`character_background_texture_path` 和 `character_color_id`。
- Produces: `MenuBackdrop.set_character_background(path, immediate)`、`MenuBackdrop.preload_character_backgrounds()`、`MenuBackdrop.start_idle_motion()`、`MenuBackdrop.stop_idle_motion()` 和稳定节点路径 `%CharacterPortrait`、`%InfoPanel`、`%RunConfigPanel`。

- [ ] **Step 1: 扩展布局失败测试**

`tests/ui_layout_bounds_regression.gd` 检查以下节点位于 1200x700 内，并且 `InfoPanel`、`CharacterStage`、`RunConfigPanel` 三者不互相重叠：

```gdscript
const TITLE_CONTROLS := [
	"TitleScreen/MainMenu/VBoxContainer",
	"TitleScreen/NewRunMenu/InfoPanel",
	"TitleScreen/NewRunMenu/CharacterStage",
	"TitleScreen/NewRunMenu/RunConfigPanel",
	"TitleScreen/NewRunMenu/CharacterButtonContainer",
	"TitleScreen/NewRunMenu/RunConfigPanel/StartRunButton",
	"TitleScreen/NewRunMenu/RunConfigPanel/BackButton",
]
```

同时把根窗口调整到 `Vector2i(1920, 1080)` 后再次等待布局，确认这些控件仍处于 `TitleScreen.get_global_rect()` 内。

- [ ] **Step 2: 运行布局测试确认失败**

Run: `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`

Expected: FAIL，缺少新舞台节点和三栏面板。

- [ ] **Step 3: 建立稳定节点结构**

`TitleScreen.tscn` 使用以下结构，保留四个菜单为根节点直接子节点：

```text
TitleScreen
├── Backdrop
│   ├── FallbackSky
│   ├── Sky
│   ├── FarIslands
│   ├── MidRuins
│   ├── Platform
│   ├── CharacterBackgroundA
│   ├── CharacterBackgroundB
│   ├── Foreground
│   ├── AmbientParticles
│   └── ConfirmParticles
├── TitleOrnament
├── GameTitle
├── MainMenu
├── NewRunMenu
│   ├── ScreenTitle
│   ├── InfoPanel
│   ├── CharacterStage
│   │   ├── StageRing
│   │   ├── CharacterGlow
│   │   └── CharacterPortrait
│   ├── CharacterButtonContainer
│   ├── RunConfigPanel
│   │   ├── DifficultySelect
│   │   ├── SeedLabel
│   │   ├── SeedInput
│   │   ├── CustomRunModifierButtonContainer
│   │   ├── StartRunButton
│   │   └── BackButton
│   └── EmptyStateLabel
├── CodexMenu
├── SettingsMenu
├── TransitionOverlay
└── PerformanceController
```

基准矩形：`InfoPanel` 为 x=40..350，`CharacterStage` 为 x=370..825，`RunConfigPanel` 为 x=840..1170；所有控件使用稳定尺寸和锚点，不依赖文本撑开父容器。

- [ ] **Step 4: 实现 MenuBackdrop 资源和淡变接口**

```gdscript
extends Control
class_name MenuBackdrop

const TITLE_LAYER_PATHS := {
	"Sky": "external/sprites/ui/title_screen/title_sky.png",
	"FarIslands": "external/sprites/ui/title_screen/title_far_islands.png",
	"MidRuins": "external/sprites/ui/title_screen/title_mid_ruins.png",
	"Platform": "external/sprites/ui/title_screen/title_platform.png",
	"Foreground": "external/sprites/ui/title_screen/title_foreground.png",
}

var active_background_index := 0
var background_tween: Tween
var idle_tween: Tween

@onready var background_layers: Array[TextureRect] = [$CharacterBackgroundA, $CharacterBackgroundB]

func load_title_layers() -> void:
	for node_name: String in TITLE_LAYER_PATHS:
		var layer: TextureRect = get_node(node_name)
		layer.texture = FileLoader.load_texture(TITLE_LAYER_PATHS[node_name])
		layer.visible = layer.texture.get_size() != Vector2i.ZERO
	$FallbackSky.visible = not $Sky.visible

func preload_character_backgrounds() -> void:
	for character_id: String in Global._id_to_character_data:
		var character_data: CharacterData = Global.get_character_data(character_id)
		if character_data != null and not character_data.character_background_texture_path.is_empty():
			FileLoader.load_texture(character_data.character_background_texture_path)

func set_character_background(path: String, immediate: bool = false) -> void:
	var current: TextureRect = background_layers[active_background_index]
	var target_index := 1 - active_background_index
	var target: TextureRect = background_layers[target_index]
	var texture := FileLoader.load_texture(path) if not path.is_empty() else $Platform.texture
	if texture.get_size() == Vector2i.ZERO:
		texture = $Platform.texture
	target.texture = texture
	if immediate:
		current.modulate.a = 0.0
		target.modulate.a = 1.0
		active_background_index = target_index
		return
	if background_tween != null and background_tween.is_valid():
		background_tween.kill()
	target.modulate.a = 0.0
	background_tween = create_tween().set_parallel(true)
	background_tween.tween_property(current, "modulate:a", 0.0, 0.22)
	background_tween.tween_property(target, "modulate:a", 1.0, 0.22)
	background_tween.tween_callback(_finish_background_swap.bind(target_index)).set_delay(0.22)

func _finish_background_swap(target_index: int) -> void:
	active_background_index = target_index
	background_tween = null
```

`FallbackSky` 使用项目现有浅青色，不加载外部资源。`MenuBackdrop._ready()` 同时调用 `load_title_layers()` 和 `preload_character_backgrounds()`，确保首次切换角色不触发同步磁盘读取。

背景加载失败时使用 `Platform`；立绘加载得到空纹理时改用角色头像，再失败时显示 `icon_menu.png` 中性占位。

- [ ] **Step 5: 更新标题主题和头像按钮**

主题将大圆角缩小到不超过 8px，按钮固定高度，保留白、青、金橙、角色阵营色四组对比。`CharacterSelectionButton.tscn` 使用 72x72 稳定尺寸、圆形头像裁切、焦点轮廓和不改变布局尺寸的选中装饰。

- [ ] **Step 6: 在 TitleScreen 更新角色舞台**

```gdscript
func _on_character_changed(character_data: CharacterData) -> void:
	var portrait := FileLoader.load_texture(character_data.character_texture_path)
	if portrait.get_size() == Vector2i.ZERO:
		portrait = FileLoader.load_texture(character_data.character_icon_texture_path)
	character_portrait.texture = portrait
	backdrop.set_character_background(character_data.character_background_texture_path)
	var color_data := Global.get_color_data(character_data.character_color_id)
	var accent := color_data.color if color_data != null else Color.WHITE
	stage_ring.modulate = accent
	character_glow.modulate = Color(accent, 0.35)
```

- [ ] **Step 7: 运行布局、场景和资产回归**

Run: `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`

Expected: `ALL_TESTS_PASSED`

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: `ALL_TESTS_PASSED`

Run: `godot --headless --path . --script tests/title_screen_asset_regression.gd`

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 8: 提交舞台和布局**

```bash
git add scripts/ui/menus/MenuBackdrop.gd scenes/ui/menus/TitleScreen.tscn themes/title_screen_theme.tres scenes/ui/CharacterSelectionButton.tscn scripts/ui/CharacterSelectionButton.gd scripts/ui/menus/TitleScreen.gd tests/ui_layout_bounds_regression.gd tests/title_screen_performance_regression.gd
git commit -m "feat: build title and character selection stage"
```

### Task 6: 完成入场、切换、焦点和确认演出

**Files:**
- Modify: `scripts/ui/menus/TitlePerformanceController.gd`
- Modify: `scripts/ui/menus/MenuBackdrop.gd`
- Modify: `scripts/ui/menus/MainMenu.gd`
- Modify: `scripts/ui/CharacterSelectionButton.gd`
- Modify: `scripts/ui/menus/TitleScreen.gd`
- Modify: `tests/title_screen_performance_regression.gd`

**Interfaces:**
- Consumes: Task 3 状态接口和 Task 5 稳定节点。
- Produces: 规格规定的 1.05/0.80/0.22/0.65 秒演出、焦点反馈、空闲视差和任意阶段跳过后的稳定状态。

- [ ] **Step 1: 扩展失败测试覆盖最终状态和重复输入**

加入断言：每次跳过后只有目标菜单可见；`modulate.a` 为 1；位置和缩放等于控制器稳定值；快速调用 `show_new_run_menu()` 不会创建第二次转场；两次开始按钮输入只调用一次离场请求。

动画测试只检查最终值和信号次数，不等待或比较 Tween 中间帧。

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: FAIL，报告最终属性或重复输入保护尚未满足。

- [ ] **Step 3: 填充四组 Tween 时间线**

在控制器中新增 `character_stage`、`main_menu_buttons` 和 `backdrop_rest_position`，并在 `_ready()` 缓存。四组时间线使用以下实现：

```gdscript
@onready var character_stage: Control = $%CharacterStage

var main_menu_buttons: Array = []
var backdrop_rest_position: Vector2

func _cache_performance_nodes() -> void:
	backdrop_rest_position = backdrop.position
	main_menu_buttons = main_menu.get_node("VBoxContainer").get_children().filter(
		func(child: Node) -> bool: return child is Button
	)

func play_title_intro() -> void:
	apply_entering_state()
	_start_sequence("MAIN_MENU")
	active_tween.tween_property(backdrop, "modulate:a", 1.0, 0.55)
	active_tween.tween_property(game_title, "position:y", title_rest_position.y, 0.57).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(game_title, "modulate:a", 1.0, 0.30).set_delay(0.18)
	active_tween.tween_property(main_menu, "modulate:a", 1.0, 0.30).set_delay(0.45)
	for index: int in main_menu_buttons.size():
		main_menu_buttons[index].modulate.a = 0.0
		active_tween.tween_property(main_menu_buttons[index], "modulate:a", 1.0, 0.24).set_delay(0.45 + index * 0.06)
	active_tween.tween_callback(_finish_sequence.bind("MAIN_MENU")).set_delay(INTRO_DURATION)

func play_to_character_select() -> void:
	_start_sequence("CHARACTER_SELECT")
	new_run_menu.visible = true
	new_run_menu.modulate.a = 0.0
	character_stage.scale = Vector2(0.92, 0.92)
	active_tween.tween_property(main_menu, "position:x", -main_menu.size.x, 0.18)
	active_tween.tween_property(main_menu, "modulate:a", 0.0, 0.18)
	active_tween.tween_property(backdrop, "position", backdrop_rest_position + Vector2(-42.0, 16.0), 0.50).set_delay(0.08)
	active_tween.tween_property(new_run_menu, "modulate:a", 1.0, 0.35).set_delay(0.35)
	active_tween.tween_property(character_stage, "scale", Vector2.ONE, 0.28).set_delay(0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_callback(_finish_sequence.bind("CHARACTER_SELECT")).set_delay(TO_CHARACTER_DURATION)

func play_to_main_menu() -> void:
	_start_sequence("MAIN_MENU")
	main_menu.visible = true
	main_menu.position = main_menu_rest_position - Vector2(24.0, 0.0)
	main_menu.modulate.a = 0.0
	active_tween.tween_property(new_run_menu, "position:x", new_run_rest_position.x + new_run_menu.size.x, 0.28)
	active_tween.tween_property(new_run_menu, "modulate:a", 0.0, 0.28)
	active_tween.tween_property(backdrop, "position", backdrop_rest_position, 0.42)
	active_tween.tween_property(main_menu, "position", main_menu_rest_position, 0.30).set_delay(0.20)
	active_tween.tween_property(main_menu, "modulate:a", 1.0, 0.30).set_delay(0.20)
	active_tween.tween_callback(_finish_sequence.bind("MAIN_MENU")).set_delay(TO_MAIN_DURATION)

func play_run_confirm() -> void:
	_start_sequence("LEAVING")
	transition_overlay.visible = true
	transition_overlay.modulate.a = 0.0
	active_tween.tween_property(character_stage, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(new_run_menu, "modulate:a", 0.0, 0.35).set_delay(0.20)
	active_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.25).set_delay(0.40)
	active_tween.tween_callback(_finish_sequence.bind("LEAVING")).set_delay(RUN_CONFIRM_DURATION)
```

将 `_cache_performance_nodes()` 作为 Task 3 中 `TitlePerformanceController._ready()` 的最后一行。

同步扩展稳定状态：`apply_main_menu_state()` 将 `backdrop.position` 恢复为 `backdrop_rest_position`，`apply_character_select_state()` 将其设为 `backdrop_rest_position + Vector2(-42.0, 16.0)`，两个状态都把 `character_stage.scale` 恢复为 `Vector2.ONE`。最终回调继续先调用 `apply_*_state()` 再发出 `transition_finished`。

- [ ] **Step 4: 实现空闲视差**

`MenuBackdrop.gd` 使用单一时间计数，不持续创建 Tween 或节点：

```gdscript
var idle_motion_enabled := false
var idle_time := 0.0
var far_origin: Vector2
var mid_origin: Vector2
var foreground_origin: Vector2

func _ready() -> void:
	far_origin = $FarIslands.position
	mid_origin = $MidRuins.position
	foreground_origin = $Foreground.position
	load_title_layers()
	preload_character_backgrounds()

func _process(delta: float) -> void:
	if not idle_motion_enabled:
		return
	idle_time += delta
	$FarIslands.position = far_origin + Vector2(sin(idle_time * 0.22) * 12.0, cos(idle_time * 0.16) * 2.0)
	$MidRuins.position = mid_origin + Vector2(sin(idle_time * 0.31) * 8.0, cos(idle_time * 0.21) * 2.0)
	$Foreground.position = foreground_origin + Vector2(sin(idle_time * 0.45) * 5.0, 0.0)

func start_idle_motion() -> void:
	idle_motion_enabled = true
	$AmbientParticles.emitting = true

func stop_idle_motion() -> void:
	idle_motion_enabled = false
	$AmbientParticles.emitting = false
	$FarIslands.position = far_origin
	$MidRuins.position = mid_origin
	$Foreground.position = foreground_origin
```

`AmbientParticles.amount` 使用固定值 24，`ConfirmParticles.amount` 使用固定值 16。

- [ ] **Step 5: 实现菜单与头像反馈**

`MainMenu.gd` 为每个按钮缓存基准 x，并复用每按钮 Tween：

```gdscript
var button_base_x: Dictionary = {}
var button_tweens: Dictionary = {}

func _connect_button_motion(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	button_base_x[button] = button.position.x
	button.focus_entered.connect(_animate_button_focus.bind(button, true))
	button.focus_exited.connect(_animate_button_focus.bind(button, false))
	button.mouse_entered.connect(_animate_button_focus.bind(button, true))
	button.mouse_exited.connect(_animate_button_focus.bind(button, false))
	button.button_down.connect(_animate_button_press.bind(button, true))
	button.button_up.connect(_animate_button_press.bind(button, false))

func _animate_button_focus(button: Button, focused: bool) -> void:
	_kill_button_tween(button)
	var tween := create_tween().set_parallel(true)
	button_tweens[button] = tween
	tween.tween_property(button, "position:x", button_base_x[button] + (12.0 if focused else 0.0), 0.12)
	tween.tween_property(button, "self_modulate", Color.WHITE if focused else Color(0.94, 0.98, 1.0), 0.12)

func _animate_button_press(button: Button, pressed: bool) -> void:
	_kill_button_tween(button)
	var tween := create_tween()
	button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2(0.96, 0.96) if pressed else Vector2.ONE, 0.10)

func _kill_button_tween(button: Button) -> void:
	var tween: Tween = button_tweens.get(button)
	if tween != null and tween.is_valid():
		tween.kill()

func grab_default_focus() -> void:
	var target: Button = continue_button if continue_button.visible and not continue_button.disabled else new_run_button
	if target.visible and not target.disabled:
		target.grab_focus()
```

`CharacterSelectionButton.tscn` 在 TextureButton 根节点下新增 `Portrait` 和 `FocusOutline`。脚本把角色头像写入 `Portrait.texture`，并用同一 `motion_tween` 将 `Portrait.position.y` 在基准值与基准值减 8 之间切换；`FocusOutline.visible` 与 `button_pressed or has_focus()` 保持一致。根按钮尺寸和位置不参与 Tween。

`TitleScreen._on_performance_transition_finished("MAIN_MENU")` 设置 `screen_state=MAIN_MENU` 后调用 `main_menu.call_deferred("grab_default_focus")`；进入 `CHARACTER_SELECT` 后调用当前角色头像的 `grab_focus()`；进入 `LEAVING` 时只消费一次 `pending_run_request`。

- [ ] **Step 6: 实现角色切换 0.22 秒演出**

`TitleScreen.gd` 使用以下切换逻辑；新角色数据到达时先取消旧 Tween，最后一次信号会替换待显示数据：

```gdscript
var character_tween: Tween
var pending_character_visual: CharacterData

func _on_character_changed(character_data: CharacterData) -> void:
	pending_character_visual = character_data
	if character_tween != null and character_tween.is_valid():
		character_tween.kill()
	character_tween = create_tween()
	character_tween.tween_property(character_portrait, "modulate:a", 0.0, 0.08)
	character_tween.parallel().tween_property(character_portrait, "scale", Vector2(0.90, 0.90), 0.08)
	character_tween.tween_callback(_apply_pending_character_visual)
	character_tween.tween_property(character_portrait, "modulate:a", 1.0, 0.14)
	character_tween.parallel().tween_property(character_portrait, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _apply_pending_character_visual() -> void:
	var character_data := pending_character_visual
	var portrait := FileLoader.load_texture(character_data.character_texture_path)
	if portrait.get_size() == Vector2i.ZERO:
		portrait = FileLoader.load_texture(character_data.character_icon_texture_path)
	if portrait.get_size() == Vector2i.ZERO:
		portrait = FileLoader.load_texture("external/sprites/ui/flipper/icon_menu.png")
	character_portrait.texture = portrait
	backdrop.set_character_background(character_data.character_background_texture_path)
	var color_data := Global.get_color_data(character_data.character_color_id)
	var accent := color_data.color if color_data != null else Color.WHITE
	stage_ring.modulate = accent
	character_glow.modulate = Color(accent, 0.35)
```

- [ ] **Step 7: 运行演出回归**

Run: `godot --headless --path . --script tests/title_screen_performance_regression.gd`

Expected: `ALL_TESTS_PASSED`

Run: `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 8: 提交完整演出**

```bash
git add scripts/ui/menus/TitlePerformanceController.gd scripts/ui/menus/MenuBackdrop.gd scripts/ui/menus/MainMenu.gd scripts/ui/CharacterSelectionButton.gd scripts/ui/menus/TitleScreen.gd tests/title_screen_performance_regression.gd
git commit -m "feat: complete title screen performance"
```

### Task 7: 全量验证、视觉验收和文档一致性

**Files:**
- Modify if verification finds defects: title/selection files from Tasks 1-6 only.
- Modify: `docs/superpowers/specs/2026-07-12-title-character-selection-performance-design.md`
- Track: `docs/superpowers/plans/2026-07-12-title-character-selection-performance.md`

**Interfaces:**
- Consumes: 所有前置任务提交。
- Produces: 通过自动化和人工视觉验收的标题/选人流程，以及与实现一致的规格和计划。

- [ ] **Step 1: 运行 Godot 解析烟雾检查**

Run: `godot --headless --path . --quit`

Expected: exit code 0，无 parser error、场景资源错误或无效节点路径。

- [ ] **Step 2: 运行完整相关回归**

```bash
godot --headless --path . --script tests/title_screen_asset_regression.gd
godot --headless --path . --script tests/title_screen_performance_regression.gd
godot --headless --path . --script tests/ui_layout_bounds_regression.gd
godot --headless --path . --script tests/codex_menu_display_regression.gd
```

Expected: 每个测试均输出 `ALL_TESTS_PASSED` 并以 0 退出。

- [ ] **Step 3: 启动游戏进行标题视觉验收**

Run: `godot --path .`

在 1200x700 逻辑画布和 1920x1080 窗口下检查：标题文字清晰；菜单不遮挡角色群像；前景不遮挡焦点；无存档和有存档两种菜单高度均在画布内；空闲动画不改变点击区。

- [ ] **Step 4: 逐角色进行选人视觉验收**

依次选择红、蓝、绿、橙角色并截图。检查每张立绘完整可见、背景地平线不跳动、阵营色清晰但不染满画面、详情和初始遗物不越界、右侧难度/种子/自定义规则完整可用。

- [ ] **Step 5: 验证输入和异常路径**

用鼠标、键盘和手柄分别执行：跳过标题、进入选人、连续切换、返回主菜单、进入图鉴、进入设置、确认开局。演出期间快速重复确认和取消，确认没有半透明节点、错位、无焦点或重复开局。

- [ ] **Step 6: 检查差异范围**

Run: `git status --short`

Expected: 本任务文件与项目已有无关脏文件清晰分离；不得暂存 `external/user_settings.json`、`.superpowers/`、`.DS_Store`、`tmp/` 或本任务之外的生成文件。

- [ ] **Step 7: 提交验证修正和文档**

只暂存本计划、规格补正和验证中产生的标题/选人修正：

```bash
git add docs/superpowers/specs/2026-07-12-title-character-selection-performance-design.md docs/superpowers/plans/2026-07-12-title-character-selection-performance.md
git commit -m "docs: finalize title screen implementation plan"
```

如果 Step 3-5 修改了实现文件，将这些实现修正与对应测试加入同一次最终提交；无实现修正时仅提交两份文档。

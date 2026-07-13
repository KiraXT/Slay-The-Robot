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


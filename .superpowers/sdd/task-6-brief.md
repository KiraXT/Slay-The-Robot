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


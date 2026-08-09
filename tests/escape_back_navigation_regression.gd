extends SceneTree

const ROOT_SCENE_PATH := "res://scenes/Root.tscn"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load(ROOT_SCENE_PATH).instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var escape_event := InputEventKey.new()
	escape_event.pressed = true
	escape_event.keycode = KEY_ESCAPE

	await _test_title_transition_input_priority(root_scene, escape_event)
	await _test_title_back_navigation(root_scene, escape_event)
	await _test_run_back_navigation(root_scene, escape_event)

	root_scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_title_back_navigation(root_scene: Node, escape_event: InputEventKey) -> void:
	var title_screen: Node = root_scene.get_node("TitleScreen")
	title_screen.call("skip_active_transition")
	await process_frame

	for menu_method in ["show_codex_menu", "show_settings_menu"]:
		title_screen.call(menu_method)
		_assert_true(title_screen.call("get_screen_state_name") != "MAIN_MENU", "%s must open before ESC is tested" % menu_method)
		await _press_escape(root_scene, escape_event)
		_assert_equal(title_screen.call("get_screen_state_name"), "MAIN_MENU", "ESC must return from %s" % menu_method)

	title_screen.call("show_new_run_menu")
	title_screen.call("skip_active_transition")
	_assert_equal(title_screen.call("get_screen_state_name"), "CHARACTER_SELECT", "new run menu must open before ESC is tested")
	await _press_escape(root_scene, escape_event)
	title_screen.call("skip_active_transition")
	_assert_equal(title_screen.call("get_screen_state_name"), "MAIN_MENU", "ESC must return from new run menu")


func _test_run_back_navigation(root_scene: Node, escape_event: InputEventKey) -> void:
	root_scene.get_node("TitleScreen").visible = false
	root_scene.get_node("RunScreen").visible = true

	var map: Node = root_scene.get_node("RunScreen/Map")
	map.visible = true
	await _press_escape(root_scene, escape_event)
	_assert_false(map.visible, "ESC must close the map through its Back action")
	map.visible = true
	if not map.has_method("_handle_back_navigation_event"):
		failures.append("Map must handle ESC back navigation directly")
	else:
		map.call("_handle_back_navigation_event", escape_event)
		_assert_false(map.visible, "the map ESC handler must close the map through its Back action")
	map.visible = true
	var console: Node = root_scene.get_node("GMConsole")
	_assert_true(root_scene.call("_toggle_gm_console"), "GM console must open for map ESC priority testing")
	await _press_escape(root_scene, escape_event)
	_assert_false(console.visible, "ESC must close the GM console before closing the map")
	_assert_true(map.visible, "closing the GM console must not close the map")
	if console.visible:
		console.call("hide_console")
	map.visible = false

	var card_selection: Node = root_scene.get_node("RunScreen/CardSelectionOverlay")
	card_selection.call("set_card_mode", 0)
	await _press_escape(root_scene, escape_event)
	_assert_false(card_selection.visible, "ESC must close the card browsing overlay through its Back action")


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append(label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append(label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _test_title_transition_input_priority(root_scene: Node, escape_event: InputEventKey) -> void:
	var title_screen: Node = root_scene.get_node("TitleScreen")
	var console: Node = root_scene.get_node("GMConsole")
	var initial_state = title_screen.call("get_screen_state_name")
	_assert_true(root_scene.call("_toggle_gm_console"), "GM console must open for ESC priority testing")
	await _press_escape(root_scene, escape_event)
	_assert_false(console.visible, "ESC must close the GM console before title transitions consume the input")
	_assert_equal(title_screen.call("get_screen_state_name"), initial_state, "closing the GM console must not skip the title transition")
	if console.visible:
		console.call("hide_console")

	await _press_escape(root_scene, escape_event)
	_assert_equal(title_screen.call("get_screen_state_name"), "MAIN_MENU", "ESC without the GM console must skip the title transition")

	title_screen.call("show_new_run_menu")
	await _press_escape(root_scene, escape_event)
	_assert_equal(title_screen.call("get_screen_state_name"), "CHARACTER_SELECT", "ESC during new run transition must not trigger its Back action")
	title_screen.call("show_main_menu")
	title_screen.call("skip_active_transition")


func _press_escape(_root_scene: Node, escape_event: InputEventKey) -> void:
	Input.parse_input_event(escape_event)
	await process_frame

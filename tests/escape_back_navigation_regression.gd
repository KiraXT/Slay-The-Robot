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
	for view_method in ["view_deck", "view_draw_pile", "view_discard", "view_exhaust"]:
		card_selection.call(view_method)
		_assert_true(card_selection.visible, "%s must open the card browsing overlay before ESC is tested" % view_method)
		await _press_escape(root_scene, escape_event)
		_assert_false(card_selection.visible, "ESC must close the %s browsing overlay through its Back action" % view_method)
	card_selection.call("set_card_mode", 0)
	if not card_selection.has_method("_handle_back_navigation_event"):
		failures.append("CardSelectionOverlay must handle ESC card browsing directly")
	else:
		card_selection.call("_handle_back_navigation_event", escape_event)
		_assert_false(card_selection.visible, "the card browsing ESC handler must close the overlay through its Back action")
	card_selection.call("set_card_mode", 0)
	_assert_true(root_scene.call("_toggle_gm_console"), "GM console must open for card browsing ESC priority testing")
	await _press_escape(root_scene, escape_event)
	_assert_false(console.visible, "ESC must close the GM console before closing card browsing")
	_assert_true(card_selection.visible, "the GM console must remain higher priority than card browsing")
	console.call("hide_console")
	card_selection.visible = false
	card_selection.call("set_card_mode", 1)
	await _press_escape(root_scene, escape_event)
	_assert_true(card_selection.visible, "ESC must not cancel an active card selection")
	card_selection.visible = false

	var pause_overlay: Node = root_scene.get_node("RunScreen/PauseOverlay")
	var global: Node = root.get_node("Global")
	global.call("pause_game")
	_assert_true(pause_overlay.visible, "pause overlay must open before ESC is tested")
	await _press_escape(root_scene, escape_event)
	_assert_false(paused, "ESC must resume a paused game")
	_assert_false(pause_overlay.visible, "ESC must close the pause overlay through Resume")
	global.call("pause_game")
	if not pause_overlay.has_method("_handle_back_navigation_event"):
		failures.append("PauseOverlay must handle ESC directly")
	else:
		pause_overlay.call("_handle_back_navigation_event", escape_event)
		_assert_false(pause_overlay.visible, "the pause ESC handler must resume the game and close the pause overlay")
	global.call("pause_game")
	_assert_true(root_scene.call("_toggle_gm_console"), "GM console must open for paused ESC priority testing")
	await _press_escape(root_scene, escape_event)
	_assert_false(console.visible, "ESC must close the GM console before resuming a paused game")
	_assert_true(paused, "closing the GM console must not resume a paused game")
	_assert_true(pause_overlay.visible, "closing the GM console must keep the pause overlay open")
	if paused:
		global.call("unpause_game")


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

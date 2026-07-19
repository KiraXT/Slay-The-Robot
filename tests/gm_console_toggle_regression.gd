extends SceneTree

var failures: Array[String] = []


class DisabledExecutor extends RefCounted:
	func is_enabled() -> bool:
		return false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame

	if not root_scene.has_method("_toggle_gm_console"):
		failures.append("Root must expose _toggle_gm_console for the GM hotkey.")
	if not root_scene.has_method("_is_gm_console_toggle_event"):
		failures.append("Root must expose _is_gm_console_toggle_event for physical key testing.")
	if not root_scene.has_node("GMConsole"):
		failures.append("Root scene must have a GMConsole child.")
	else:
		var console: Node = root_scene.get_node("GMConsole")
		_assert_false(console.visible, "GMConsole should start hidden")

		var key_event := InputEventKey.new()
		key_event.pressed = true
		key_event.physical_keycode = KEY_QUOTELEFT
		root_scene._input(key_event)
		_assert_true(console.visible, "GMConsole should show after first toggle")

		var result: Dictionary = console.call("submit_command", "definitely_unknown")
		_assert_false(result.ok, "GMConsole should return errors from the executor without crashing")
		var output: RichTextLabel = console.get("output_label")
		_assert_true(output.get_parsed_text().contains("ERR: unknown command 'definitely_unknown'. Use help."), "GMConsole should append executor errors to output")

		root_scene._input(key_event)
		_assert_false(console.visible, "GMConsole should hide after second toggle")

		_assert_true(root_scene.call("_is_gm_console_toggle_event", key_event), "Root should recognize KEY_QUOTELEFT as the GM toggle key")
		var echo_event := InputEventKey.new()
		echo_event.pressed = true
		echo_event.echo = true
		echo_event.physical_keycode = KEY_QUOTELEFT
		root_scene._input(echo_event)
		_assert_false(console.visible, "Root should ignore echo GM toggle events")
		_assert_false(root_scene.call("_is_gm_console_toggle_event", echo_event), "Root should reject echo GM toggle events")

		var release_event := InputEventKey.new()
		release_event.pressed = false
		release_event.physical_keycode = KEY_QUOTELEFT
		_assert_false(root_scene.call("_is_gm_console_toggle_event", release_event), "Root should ignore key release for the GM toggle")

		console.set("executor", DisabledExecutor.new())
		var disabled_toggle_result = root_scene.call("_toggle_gm_console")
		_assert_true(disabled_toggle_result is bool and not disabled_toggle_result, "Root should not toggle a disabled GM console")
		_assert_false(console.visible, "Disabled GM console should remain hidden")
		root_scene._input(key_event)
		_assert_false(console.visible, "Root input should not toggle a disabled GM console")

	root_scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		failures.append(message)

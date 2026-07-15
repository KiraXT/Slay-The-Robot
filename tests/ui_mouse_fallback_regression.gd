extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame

	if (
		not root_scene.has_method("_is_left_mouse_pressed")
		or not root_scene.has_method("_track_fallback_button")
		or not root_scene.has_method("_complete_fallback_click")
	):
		failures.append("Root must provide a mouse polling fallback for missing native button release events")
	else:
		var mouse_pressed_state: Variant = root_scene.call("_is_left_mouse_pressed")
		if not mouse_pressed_state is bool:
			failures.append("Mouse polling fallback must return a boolean state")
		_test_missing_native_release(root_scene)
		_test_native_release_is_not_duplicated(root_scene)
		_test_native_pressed_is_not_duplicated(root_scene)
		_test_release_outside_button_is_ignored(root_scene)
		_test_toggle_button_state_is_updated(root_scene)
		_test_disabled_button_is_released_without_activation(root_scene)
		_test_queued_button_is_ignored(root_scene)
		_test_stale_deferred_release_is_ignored(root_scene)

	root_scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _test_missing_native_release(root_scene: Node) -> void:
	var button := Button.new()
	root_scene.add_child(button)
	var counts := {"button_up": 0, "pressed": 0}
	button.button_up.connect(func() -> void: counts.button_up += 1)
	button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", button)
	root_scene.call("_complete_fallback_click", button)
	if counts.button_up != 1 or counts.pressed != 1:
		failures.append("Fallback must emit button_up and pressed exactly once when native release is missing (counts=%s)" % counts)
	button.queue_free()


func _test_native_release_is_not_duplicated(root_scene: Node) -> void:
	var button := Button.new()
	root_scene.add_child(button)
	var counts := {"button_up": 0, "pressed": 0}
	button.button_up.connect(func() -> void: counts.button_up += 1)
	button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", button)
	button.button_up.emit()
	button.pressed.emit()
	root_scene.call("_complete_fallback_click", button)
	if counts.button_up != 1 or counts.pressed != 1:
		failures.append("Fallback must not duplicate a native button release (counts=%s)" % counts)
	button.queue_free()


func _test_release_outside_button_is_ignored(root_scene: Node) -> void:
	var button := Button.new()
	root_scene.add_child(button)
	var counts := {"button_up": 0, "pressed": 0}
	button.button_up.connect(func() -> void: counts.button_up += 1)
	button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", button)
	root_scene.call("_complete_fallback_click", null)
	if counts.button_up != 1 or counts.pressed != 0:
		failures.append(
			"Fallback must release without clicking when the pointer is released elsewhere (counts=%s)" % counts
		)
	button.queue_free()


func _test_toggle_button_state_is_updated(root_scene: Node) -> void:
	var button := Button.new()
	button.toggle_mode = true
	root_scene.add_child(button)
	var counts := {"toggled": 0}
	button.toggled.connect(func(_pressed: bool) -> void: counts.toggled += 1)

	root_scene.call("_track_fallback_button", button)
	root_scene.call("_complete_fallback_click", button)
	if not button.button_pressed or counts.toggled != 1:
		failures.append(
			"Fallback must update toggle button state and emit toggled once (pressed=%s, count=%d)"
			% [button.button_pressed, counts.toggled]
		)
	button.queue_free()


func _test_native_pressed_is_not_duplicated(root_scene: Node) -> void:
	var button := Button.new()
	root_scene.add_child(button)
	var counts := {"button_up": 0, "pressed": 0}
	button.button_up.connect(func() -> void: counts.button_up += 1)
	button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", button)
	button.pressed.emit()
	root_scene.call("_complete_fallback_click", button)
	if counts.button_up != 1 or counts.pressed != 1:
		failures.append("Fallback must release without duplicating a native pressed signal (counts=%s)" % counts)
	button.queue_free()


func _test_queued_button_is_ignored(root_scene: Node) -> void:
	var button := Button.new()
	root_scene.add_child(button)
	var counts := {"button_up": 0, "pressed": 0}
	button.button_up.connect(func() -> void: counts.button_up += 1)
	button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", button)
	button.queue_free()
	root_scene.call("_complete_fallback_click", button)
	if counts.button_up != 0 or counts.pressed != 0:
		failures.append("Fallback must ignore buttons already queued for deletion (counts=%s)" % counts)


func _test_disabled_button_is_released_without_activation(root_scene: Node) -> void:
	var button := Button.new()
	root_scene.add_child(button)
	var counts := {"button_up": 0, "pressed": 0}
	button.button_up.connect(func() -> void: counts.button_up += 1)
	button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", button)
	button.disabled = true
	root_scene.call("_complete_fallback_click", button)
	if counts.button_up != 1 or counts.pressed != 0:
		failures.append("Fallback must release disabled buttons without activating them (counts=%s)" % counts)
	button.queue_free()


func _test_stale_deferred_release_is_ignored(root_scene: Node) -> void:
	var old_button := Button.new()
	var current_button := Button.new()
	root_scene.add_child(old_button)
	root_scene.add_child(current_button)
	var counts := {"button_up": 0, "pressed": 0}
	current_button.button_up.connect(func() -> void: counts.button_up += 1)
	current_button.pressed.connect(func() -> void: counts.pressed += 1)

	root_scene.call("_track_fallback_button", old_button)
	var old_press_id: int = root_scene.get("_fallback_press_id")
	root_scene.call("_track_fallback_button", current_button)
	var current_press_id: int = root_scene.get("_fallback_press_id")
	root_scene.call("_complete_fallback_click", current_button, old_press_id)
	if counts.button_up != 0 or counts.pressed != 0:
		failures.append("A stale deferred release must not affect the current press (counts=%s)" % counts)
	root_scene.call("_complete_fallback_click", current_button, current_press_id)
	if counts.button_up != 1 or counts.pressed != 1:
		failures.append("The current deferred release must still activate once (counts=%s)" % counts)
	old_button.queue_free()
	current_button.queue_free()

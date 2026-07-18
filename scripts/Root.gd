extends Node2D

# macOS debug windows can retain hover events while dropping GUI button events.
# Raw input is the primary path; display-state polling only repairs missing edges.
var _left_mouse_was_pressed := false
var _fallback_button: BaseButton
var _native_button_down_seen := false
var _native_button_up_seen := false
var _native_pressed_seen := false
var _fallback_press_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_button_event: InputEventMouseButton = event
	if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_button_event.pressed:
		if not _left_mouse_was_pressed:
			_left_mouse_was_pressed = true
			var pressed_button := _get_hovered_button()
			_track_fallback_button(pressed_button)
			call_deferred("_complete_fallback_press", pressed_button, _fallback_press_id)
	elif _left_mouse_was_pressed:
		_left_mouse_was_pressed = false
		var released_over_button := _get_hovered_button()
		var press_id := _fallback_press_id
		call_deferred("_complete_fallback_click", released_over_button, press_id)


func _process(_delta: float) -> void:
	var left_mouse_is_pressed := _is_left_mouse_pressed()
	if not _window_is_focused():
		if not left_mouse_is_pressed and _left_mouse_was_pressed:
			_complete_fallback_click(null)
		_left_mouse_was_pressed = left_mouse_is_pressed
		return
	if left_mouse_is_pressed and not _left_mouse_was_pressed:
		_left_mouse_was_pressed = true
		var pressed_button := _get_hovered_button()
		_track_fallback_button(pressed_button)
		call_deferred("_complete_fallback_press", pressed_button, _fallback_press_id)
	elif not left_mouse_is_pressed and _left_mouse_was_pressed:
		_left_mouse_was_pressed = false
		_complete_fallback_click(_get_hovered_button())


func _is_left_mouse_pressed() -> bool:
	var display_button_mask := 0
	if DisplayServer.get_name() != "headless":
		display_button_mask = DisplayServer.mouse_get_button_state()
	return (display_button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _window_is_focused() -> bool:
	return DisplayServer.get_name() == "headless" or DisplayServer.window_is_focused()


func _track_fallback_button(button: BaseButton) -> void:
	_disconnect_fallback_button()
	_fallback_press_id += 1
	_fallback_button = button
	_native_button_down_seen = false
	_native_button_up_seen = false
	_native_pressed_seen = false
	if is_instance_valid(_fallback_button):
		_native_button_down_seen = _fallback_button.is_pressed()
		_native_pressed_seen = (
			_fallback_button.action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS
			and _fallback_button.is_pressed()
		)
		_fallback_button.button_down.connect(_on_native_button_down)
		_fallback_button.button_up.connect(_on_native_button_up)
		_fallback_button.pressed.connect(_on_native_pressed)


func _complete_fallback_press(pressed_button: BaseButton, expected_press_id: int = -1) -> void:
	if expected_press_id >= 0 and expected_press_id != _fallback_press_id:
		return
	var button := _fallback_button
	if button != pressed_button:
		return
	if _native_button_down_seen or not is_instance_valid(button):
		return
	if button.is_queued_for_deletion():
		return
	if button.disabled or not button.is_visible_in_tree():
		return
	button.button_down.emit()


func _complete_fallback_click(released_over_button: BaseButton, expected_press_id: int = -1) -> void:
	if expected_press_id >= 0 and expected_press_id != _fallback_press_id:
		return
	var button := _fallback_button
	var native_button_up_seen := _native_button_up_seen
	var native_pressed_seen := _native_pressed_seen
	_disconnect_fallback_button()
	if native_button_up_seen or not is_instance_valid(button):
		return
	if button.is_queued_for_deletion():
		return
	var released_over_original_button := button == released_over_button
	var can_activate := (
		released_over_original_button
		and not native_pressed_seen
		and not button.disabled
		and button.is_visible_in_tree()
	)
	if can_activate and button.toggle_mode:
		button.button_pressed = not button.button_pressed
	button.button_up.emit()
	if (
		can_activate
		and is_instance_valid(button)
		and not button.is_queued_for_deletion()
	):
		button.pressed.emit()


func _on_native_button_down() -> void:
	_native_button_down_seen = true


func _on_native_button_up() -> void:
	_native_button_up_seen = true


func _on_native_pressed() -> void:
	_native_pressed_seen = true


func _disconnect_fallback_button() -> void:
	if is_instance_valid(_fallback_button) and _fallback_button.button_down.is_connected(_on_native_button_down):
		_fallback_button.button_down.disconnect(_on_native_button_down)
	if is_instance_valid(_fallback_button) and _fallback_button.button_up.is_connected(_on_native_button_up):
		_fallback_button.button_up.disconnect(_on_native_button_up)
	if is_instance_valid(_fallback_button) and _fallback_button.pressed.is_connected(_on_native_pressed):
		_fallback_button.pressed.disconnect(_on_native_pressed)
	_fallback_button = null


func _get_hovered_button() -> BaseButton:
	var control := get_viewport().gui_get_hovered_control()
	while control != null:
		if control is BaseButton:
			var button: BaseButton = control
			if not button.disabled and (button.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
				return button
		control = control.get_parent() as Control
	return null

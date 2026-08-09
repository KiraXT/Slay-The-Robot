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
	root_scene.get_node("TitleScreen").visible = false
	root_scene.get_node("RunScreen").visible = true

	var consumables: Control = root_scene.get_node("RunScreen/Combat/Consumables")
	var dropdown: Control = consumables.get_node("ConsumableActionDropdown")
	var use_button: Button = dropdown.get_node("UseConsumableButton")
	var select_target_label: Label = consumables.get_node("../SelectTargetLabel")
	var deck_button: TextureButton = root_scene.get_node("RunScreen/Combat/DeckButton")

	_assert_true(dropdown.get_node_or_null("ColorRect") == null, "consumable action dropdown must not render a white background panel")
	if not consumables.has_method("_handle_dropdown_dismissal_event"):
		failures.append("Consumables must handle clicks outside the action buttons")
	else:
		dropdown.visible = true
		consumables.set("selected_consumable_slot_index", 0)
		Input.parse_input_event(_mouse_event(deck_button.get_global_rect().get_center(), true))
		Input.parse_input_event(_mouse_event(deck_button.get_global_rect().get_center(), false))
		await process_frame
		_assert_false(dropdown.visible, "clicking outside consumable action buttons must close the dropdown")
		_assert_equal(consumables.get("selected_consumable_slot_index"), -1, "closing the dropdown must clear the selected consumable")

		dropdown.visible = true
		consumables.set("selected_consumable_slot_index", 0)
		_assert_false(
			consumables.call("_handle_dropdown_dismissal_event", _mouse_event(use_button.get_global_rect().get_center(), true)),
			"clicking Use must not dismiss the dropdown before the button handles it"
		)
		_assert_true(dropdown.visible, "clicking Use must keep the dropdown available to the action button")

		dropdown.visible = false
		consumables.set("selected_consumable_slot_index", 0)
		consumables.set("consumable_target_requested", true)
		select_target_label.show()
		consumables.call("_on_background_button_up")
		_assert_false(consumables.get("consumable_target_requested"), "clicking off a target consumable must cancel targeting")
		_assert_false(select_target_label.visible, "cancelling a target consumable must hide its target prompt")
		_assert_equal(consumables.get("selected_consumable_slot_index"), -1, "cancelling a target consumable must clear its selection")

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


func _mouse_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append(label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append(label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])

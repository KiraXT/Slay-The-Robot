extends SceneTree

var failures: Array[String] = []
var game_global: Node
var signals: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	signals = root.get_node("Signals")
	var packed: PackedScene = load("res://scenes/Root.tscn")
	var root_scene := packed.instantiate()
	root.add_child(root_scene)
	await _wait_frames(2)
	
	game_global.start_run("character_blue", 1234567890123456, 0, [] as Array[String])
	await _wait_frames(10)
	
	var run_start_options: Control = root_scene.get_node("RunScreen/RunStartOptions")
	var container: VBoxContainer = run_start_options.get_node("StartingOptionContainer")
	if not run_start_options.visible or container.get_child_count() == 0:
		var starting_location = game_global.get_player_location_data()
		signals.map_location_selected.emit(starting_location)
		await _wait_frames(6)
	
	if not run_start_options.visible:
		failures.append("RunStartOptions must become visible at the starting location")
	if container.get_child_count() == 0:
		failures.append("RunStartOptions must populate selectable options")
	
	for child in container.get_children():
		if not child is Button:
			failures.append("Run start option %s must be a native Button" % child.name)
	
	if failures.is_empty():
		var first_option: DialogueOption = container.get_child(0)
		var signal_counts := {"button_down": 0, "button_up": 0, "pressed": 0, "option_clicked": 0}
		first_option.button_down.connect(func() -> void: signal_counts.button_down += 1)
		first_option.button_up.connect(func() -> void: signal_counts.button_up += 1)
		first_option.pressed.connect(func() -> void: signal_counts.pressed += 1)
		first_option.dialogue_option_clicked.connect(func(_option) -> void: signal_counts.option_clicked += 1)
		var click_position: Vector2 = first_option.get_global_rect().get_center()
		var input_position: Vector2 = root.get_viewport().get_final_transform() * click_position
		Input.parse_input_event(_create_mouse_motion(input_position))
		await process_frame
		Input.parse_input_event(_create_mouse_button(input_position, true))
		await process_frame
		Input.parse_input_event(_create_mouse_button(input_position, false))
		await _wait_frames(2)
		if signal_counts.option_clicked != 1:
			failures.append("A routed mouse click must activate the selected option exactly once (signals=%s)" % signal_counts)
		if run_start_options.visible:
			failures.append("A routed mouse click must close RunStartOptions (signals=%s)" % signal_counts)
	
	root_scene.queue_free()
	await _wait_frames(2)
	
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _wait_frames(count: int) -> void:
	for index in count:
		await process_frame


func _create_mouse_motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	return event


func _create_mouse_button(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	return event

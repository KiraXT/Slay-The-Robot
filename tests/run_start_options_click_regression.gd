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
		var first_option = container.get_child(0)
		first_option.button_down.emit()
		first_option.button_up.emit()
		await _wait_frames(2)
		if run_start_options.visible:
			failures.append("Clicking a run start option must close RunStartOptions")
	
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

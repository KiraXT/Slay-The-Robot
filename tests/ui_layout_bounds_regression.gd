extends SceneTree

const CANVAS_SIZE := Vector2(1200.0, 700.0)
const BOTTOM_MARGIN := 12.0
const HAND_CARD_VISUAL_BOTTOM := 94.0
const SAVED_RUN_MENU_REQUIRED_HEIGHT := 268.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var title_screen: Control = root_scene.get_node("TitleScreen")
	if title_screen.scene_file_path != "res://scenes/ui/menus/TitleScreen.tscn":
		failures.append("Root must instance the extracted TitleScreen scene")

	await _check_saved_run_main_menu(root_scene)
	_check_combat_hand(root_scene)

	root_scene.queue_free()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_saved_run_main_menu(root_scene: Node) -> void:
	var menu_container: VBoxContainer = root_scene.get_node("TitleScreen/MainMenu/VBoxContainer")
	root_scene.get_node("TitleScreen/MainMenu/VBoxContainer/ContinueButton").visible = true
	root_scene.get_node("TitleScreen/MainMenu/VBoxContainer/ForfeitRunButton").visible = true
	root_scene.get_node("TitleScreen/MainMenu/VBoxContainer/NewRunButton").visible = false
	root_scene.get_node("TitleScreen/MainMenu/VBoxContainer/CodexButton").visible = true
	root_scene.get_node("TitleScreen/MainMenu/VBoxContainer/SettingsButton").visible = true
	root_scene.get_node("TitleScreen/MainMenu/VBoxContainer/ExitButton").visible = true

	menu_container.queue_sort()
	await process_frame

	var required_bottom := menu_container.global_position.y + SAVED_RUN_MENU_REQUIRED_HEIGHT
	if required_bottom > CANVAS_SIZE.y - BOTTOM_MARGIN:
		failures.append(
			"Saved-run main menu requires more vertical space than the title canvas: bottom %.1f, limit %.1f"
			% [required_bottom, CANVAS_SIZE.y - BOTTOM_MARGIN]
		)

	for child in menu_container.get_children():
		if child is Control and child.visible:
			_assert_bottom_inside(child, "%s main menu button" % child.name)


func _check_combat_hand(root_scene: Node) -> void:
	var hand: Control = root_scene.get_node("RunScreen/Combat/Hand")
	var hand_visual_bottom := hand.global_position.y + HAND_CARD_VISUAL_BOTTOM
	if hand_visual_bottom > CANVAS_SIZE.y - BOTTOM_MARGIN:
		failures.append(
			"Hand cards extend below the combat canvas: bottom %.1f, limit %.1f"
			% [hand_visual_bottom, CANVAS_SIZE.y - BOTTOM_MARGIN]
		)


func _assert_bottom_inside(control: Control, label: String) -> void:
	var rect := control.get_global_rect()
	var bottom := rect.position.y + rect.size.y
	if bottom > CANVAS_SIZE.y - BOTTOM_MARGIN:
		failures.append(
			"%s extends below the title canvas: bottom %.1f, limit %.1f"
			% [label, bottom, CANVAS_SIZE.y - BOTTOM_MARGIN]
		)

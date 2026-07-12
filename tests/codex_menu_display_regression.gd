extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var global = root.get_node("Global")
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var title_screen: Control = root_scene.get_node("TitleScreen")
	if title_screen.scene_file_path != "res://scenes/ui/menus/TitleScreen.tscn":
		failures.append("Root must instance the extracted TitleScreen scene")

	var codex_menu: Control = root_scene.get_node("TitleScreen/CodexMenu")
	codex_menu.populate_codex_menu()
	await process_frame

	_assert_grid_count(codex_menu, global._id_to_card_data.size(), "Cards page")

	var enemies_button := _find_codex_button(codex_menu, "Enemies")
	if enemies_button == null:
		failures.append("Codex Enemies button is missing")
	else:
		_assert_button_enabled(enemies_button, "Enemies")
		enemies_button.button_up.emit()
		await process_frame
		_assert_grid_count(codex_menu, global._id_to_enemy_data.size(), "Enemies page")

	var artifacts_button := _find_codex_button(codex_menu, "Artifacts")
	if artifacts_button == null:
		failures.append("Codex Artifacts button is missing")
	else:
		_assert_button_enabled(artifacts_button, "Artifacts")
		artifacts_button.button_up.emit()
		await process_frame
		_assert_grid_count(codex_menu, global._id_to_artifact_data.size(), "Artifacts page")

	var consumables_button := _find_codex_button(codex_menu, "Consumables")
	if consumables_button == null:
		failures.append("Codex Consumables button is missing")
	elif not consumables_button.disabled:
		failures.append("Codex Consumables button should remain disabled until consumables are implemented")

	root_scene.queue_free()
	await process_frame
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _find_codex_button(codex_menu: Control, button_text: String) -> Button:
	for child in codex_menu.get_node("VBoxContainer").get_children():
		if child is Button and child.text == button_text:
			return child
	return null


func _assert_button_enabled(button: Button, label: String) -> void:
	if button.disabled:
		failures.append("Codex %s button should be enabled" % label)


func _assert_grid_count(codex_menu: Control, expected_count: int, label: String) -> void:
	var grid: GridContainer = codex_menu.get_node("ScrollContainer/MarginContainer/CodexCardContainer")
	if grid.get_child_count() != expected_count:
		failures.append(
			"%s should show %s entries, got %s"
			% [label, expected_count, grid.get_child_count()]
		)

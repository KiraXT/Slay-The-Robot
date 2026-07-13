extends SceneTree

const TITLE_SCENE_PATH := "res://scenes/ui/menus/TitleScreen.tscn"
const REQUIRED_PATHS := [
	"MainMenu/VBoxContainer/ContinueButton",
	"MainMenu/VBoxContainer/ForfeitRunButton",
	"MainMenu/VBoxContainer/NewRunButton",
	"MainMenu/VBoxContainer/CodexButton",
	"MainMenu/VBoxContainer/SettingsButton",
	"MainMenu/VBoxContainer/ExitButton",
	"NewRunMenu/DifficultySelect",
	"NewRunMenu/CharacterButtonContainer",
	"NewRunMenu/CustomRunModifierButtonContainer",
	"NewRunMenu/SeedInput",
	"NewRunMenu/StartRunButton",
	"NewRunMenu/BackButton",
	"CodexMenu",
	"SettingsMenu",
]
const MENU_PATHS := ["MainMenu", "NewRunMenu", "CodexMenu", "SettingsMenu"]

var failures: Array[String] = []


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _assert_stable_control(control: Control, expected_visible: bool, expected_position: Vector2, expected_mouse_filter: Control.MouseFilter, label: String) -> void:
	if control.visible != expected_visible:
		failures.append("%s visibility did not settle" % label)
	if control.position != expected_position:
		failures.append("%s position did not settle" % label)
	if control.scale != Vector2.ONE:
		failures.append("%s scale did not settle" % label)
	if not is_equal_approx(control.modulate.a, 1.0):
		failures.append("%s opacity did not settle" % label)
	if control.mouse_filter != expected_mouse_filter:
		failures.append("%s mouse filter did not settle" % label)


func _assert_visual_state(control: Control, expected_visible: bool, expected_alpha: float, expected_mouse_filter: Control.MouseFilter, label: String) -> void:
	if control.visible != expected_visible:
		failures.append("%s visibility did not settle" % label)
	if not is_equal_approx(control.modulate.a, expected_alpha):
		failures.append("%s opacity did not settle" % label)
	if control.mouse_filter != expected_mouse_filter:
		failures.append("%s mouse filter did not settle" % label)


func _assert_main_menu_final_state(title_screen: Control, main_menu_rest_position: Vector2) -> void:
	_assert_stable_control(title_screen.get_node("MainMenu"), true, main_menu_rest_position, Control.MOUSE_FILTER_STOP, "main menu")
	_assert_visual_state(title_screen.get_node("NewRunMenu"), false, 1.0, Control.MOUSE_FILTER_IGNORE, "main menu new run")
	_assert_visual_state(title_screen.get_node("Backdrop"), true, 1.0, Control.MOUSE_FILTER_IGNORE, "main menu backdrop")
	_assert_visual_state(title_screen.get_node("TitleOrnament"), true, 1.0, Control.MOUSE_FILTER_IGNORE, "main menu ornament")
	_assert_visual_state(title_screen.get_node("GameTitle"), true, 1.0, Control.MOUSE_FILTER_IGNORE, "main menu title")
	_assert_visual_state(title_screen.get_node("TransitionOverlay"), false, 0.0, Control.MOUSE_FILTER_IGNORE, "main menu overlay")


func _assert_character_select_final_state(title_screen: Control, new_run_menu_rest_position: Vector2) -> void:
	_assert_visual_state(title_screen.get_node("MainMenu"), false, 1.0, Control.MOUSE_FILTER_IGNORE, "character select main menu")
	_assert_stable_control(title_screen.get_node("NewRunMenu"), true, new_run_menu_rest_position, Control.MOUSE_FILTER_STOP, "character select new run")
	_assert_visual_state(title_screen.get_node("Backdrop"), true, 1.0, Control.MOUSE_FILTER_IGNORE, "character select backdrop")
	_assert_visual_state(title_screen.get_node("TitleOrnament"), false, 1.0, Control.MOUSE_FILTER_IGNORE, "character select ornament")
	_assert_visual_state(title_screen.get_node("GameTitle"), false, 1.0, Control.MOUSE_FILTER_IGNORE, "character select title")
	_assert_visual_state(title_screen.get_node("TransitionOverlay"), false, 0.0, Control.MOUSE_FILTER_IGNORE, "character select overlay")


func _send_action(action: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released := InputEventAction.new()
	released.action = action
	Input.parse_input_event(released)


func _send_mouse_click(position: Vector2) -> void:
	var pressed := InputEventMouseButton.new()
	pressed.button_index = MOUSE_BUTTON_LEFT
	pressed.position = position
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released := InputEventMouseButton.new()
	released.button_index = MOUSE_BUTTON_LEFT
	released.position = position
	Input.parse_input_event(released)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var file_loader: Node = root.get_node("FileLoader")
	file_loader.delete_save()
	var packed: PackedScene = load(TITLE_SCENE_PATH)
	if packed == null:
		push_error("Missing TitleScreen.tscn")
		quit(1)
		return
	var title_screen := packed.instantiate()
	root.add_child(title_screen)
	await process_frame
	var main_menu: Control = title_screen.get_node("MainMenu")
	var new_run_menu: Control = title_screen.get_node("NewRunMenu")
	var performance_controller: Node = title_screen.get_node("TitlePerformanceController")
	var game_title: Label = title_screen.get_node("GameTitle")
	var new_run_button: Button = title_screen.get_node("MainMenu/VBoxContainer/NewRunButton")
	var main_menu_rest_position := Vector2.ZERO
	var new_run_menu_rest_position := Vector2.ZERO
	var run_started_counts: Array = [0]
	var run_started_callback := func() -> void:
		run_started_counts[0] += 1
	var signals: Node = root.get_node("Signals")
	var game_global: Node = root.get_node("Global")
	signals.run_started.connect(run_started_callback)
	if not is_equal_approx(game_title.get_global_rect().get_center().x, 600.0):
		failures.append("Game title must remain centered in the 1200px title screen")
	for path: String in REQUIRED_PATHS:
		if not title_screen.has_node(path):
			failures.append("Missing title node: %s" % path)
	for path: String in MENU_PATHS:
		var menu: Control = title_screen.get_node(path)
		if menu.title_screen != title_screen:
			failures.append("%s must resolve its TitleScreen parent" % path)
	new_run_button.grab_focus()
	_send_action("ui_accept")
	await process_frame
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "confirm skips intro")
	_assert_equal(run_started_counts[0], 0, "confirm during intro must not start a run")
	main_menu_rest_position = main_menu.position
	_assert_main_menu_final_state(title_screen, main_menu_rest_position)

	title_screen.show_new_run_menu()
	_send_action("ui_cancel")
	await process_frame
	_assert_equal(title_screen.get_screen_state_name(), "CHARACTER_SELECT", "cancel skips new run transition")
	_assert_equal(run_started_counts[0], 0, "cancel during transition must not start a run")
	new_run_menu_rest_position = new_run_menu.position
	_assert_character_select_final_state(title_screen, new_run_menu_rest_position)
	var start_run_button: Button = title_screen.get_node("NewRunMenu/StartRunButton")
	title_screen.show_main_menu()
	_send_mouse_click(start_run_button.get_global_rect().get_center())
	await process_frame
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "mouse click skips main menu transition")
	_assert_equal(run_started_counts[0], 0, "mouse click during transition must not start a run")
	_assert_main_menu_final_state(title_screen, main_menu_rest_position)

	title_screen.show_new_run_menu()
	title_screen.skip_active_transition()
	var back_button: Button = title_screen.get_node("NewRunMenu/BackButton")
	back_button.grab_focus()
	title_screen.show_main_menu()
	await create_timer(0.70).timeout
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "natural back transition")
	_assert_equal(title_screen.get_viewport().gui_get_focus_owner(), new_run_button, "natural back transition restores default focus")
	_assert_main_menu_final_state(title_screen, main_menu_rest_position)

	title_screen.show_new_run_menu()
	title_screen.skip_active_transition()
	back_button.grab_focus()
	title_screen.show_main_menu()
	title_screen.skip_active_transition()
	await process_frame
	_assert_equal(title_screen.get_viewport().gui_get_focus_owner(), new_run_button, "skipped back transition restores default focus")
	_assert_main_menu_final_state(title_screen, main_menu_rest_position)

	new_run_button.grab_focus()
	title_screen.show_settings_menu()
	title_screen.show_main_menu()
	await process_frame
	_assert_equal(title_screen.get_viewport().gui_get_focus_owner(), new_run_button, "settings return restores main menu focus")

	title_screen.show_new_run_menu()
	title_screen.skip_active_transition()
	await process_frame
	new_run_menu.populate_new_run_menu()
	await process_frame
	if new_run_menu.selected_character_object_id.is_empty():
		failures.append("New run menu must select the first character")

	var character_button_container: Control = new_run_menu.get_node("CharacterButtonContainer")
	var character_button: TextureButton = character_button_container.get_node("GridContainer").get_child(0)
	var container_character_ids: Array = []
	var changed_character_data: Array = []
	character_button_container.connect("character_selected", func(character_id: String) -> void:
		container_character_ids.append(character_id)
	)
	new_run_menu.character_changed.connect(func(character_data: CharacterData) -> void:
		changed_character_data.append(character_data)
	)
	character_button.button_up.emit()
	var selected_character_id: String = new_run_menu.selected_character_object_id
	_assert_equal(container_character_ids, [selected_character_id], "button selected reaches character container")
	if changed_character_data.size() != 1 or changed_character_data[0] is not CharacterData:
		failures.append("button selected must emit CharacterData through new run menu")
	if not title_screen.has_method("get_current_character_data"):
		failures.append("Title screen must retain selected CharacterData for the stage")
	else:
		_assert_equal(title_screen.call("get_current_character_data"), changed_character_data[0], "title screen retains selected CharacterData")

	var character_data: CharacterData = game_global.get_character_data(selected_character_id)
	var original_artifact_ids: Array[String] = character_data.character_starting_artifact_ids.duplicate()
	var original_artifact_texture = new_run_menu.character_artifact_texture_rect.texture
	character_data.character_starting_artifact_ids.clear()
	new_run_menu._on_character_selected(selected_character_id)
	_assert_equal(new_run_menu.character_artifact_name_label.text, "无初始遗物", "character without artifact clears artifact name")
	_assert_equal(new_run_menu.character_artifact_description_label.text, "", "character without artifact clears artifact description")
	if new_run_menu.character_artifact_texture_rect.texture == original_artifact_texture:
		failures.append("character without artifact must clear the previous artifact texture")
	character_data.character_starting_artifact_ids.assign(original_artifact_ids)
	var artifact_id: String = original_artifact_ids[0]
	var artifact_data = game_global.get_artifact_data(artifact_id)
	game_global._id_to_artifact_data.erase(artifact_id)
	new_run_menu._on_character_selected(selected_character_id)
	_assert_equal(new_run_menu.character_artifact_name_label.text, "无初始遗物", "missing artifact data clears artifact name")
	_assert_equal(new_run_menu.character_artifact_description_label.text, "", "missing artifact data clears artifact description")
	game_global._id_to_artifact_data[artifact_id] = artifact_data

	var original_character_data: Dictionary = game_global._id_to_character_data.duplicate()
	game_global._id_to_character_data.clear()
	new_run_menu.populate_new_run_menu()
	_assert_equal(new_run_menu.selected_character_object_id, "", "empty character list clears selection")
	if not new_run_menu.start_run_button.disabled:
		failures.append("empty character list must disable start run")
	if not new_run_menu.empty_state_label.visible:
		failures.append("empty character list must show empty state")
	game_global._id_to_character_data.merge(original_character_data)
	new_run_menu.populate_new_run_menu()
	await process_frame

	var requests: Array = []
	new_run_menu.run_requested.connect(func(character_id: String, seed: int, difficulty: int, modifiers: Array[String]) -> void:
		requests.append([character_id, seed, difficulty, modifiers])
	)
	new_run_menu.seed_input.text = "31415"
	new_run_menu.selected_difficulty_level = 2
	new_run_menu.custom_run_modifier_button_container.selected_custom_run_modififers.clear()
	new_run_menu.custom_run_modifier_button_container.selected_custom_run_modififers.append("cancelled_modifier")
	var run_started_before_cancel: int = run_started_counts[0]
	start_run_button.button_up.emit()
	_assert_equal(title_screen.get_screen_state_name(), "LEAVING", "run request enters leaving state")
	new_run_menu.back_requested.emit()
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "back cancels leaving request")
	if not title_screen.pending_run_request.is_empty():
		failures.append("back must clear a pending leaving request")
	else:
		performance_controller.emit_signal("transition_finished", "LEAVING")
		_assert_equal(run_started_counts[0], run_started_before_cancel, "cancelled leaving request must not start a run")

		title_screen.show_new_run_menu()
		title_screen.skip_active_transition()
		await process_frame
		new_run_menu.seed_input.text = "27182"
		new_run_menu.selected_difficulty_level = 1
		new_run_menu.custom_run_modifier_button_container.selected_custom_run_modififers.clear()
		new_run_menu.custom_run_modifier_button_container.selected_custom_run_modififers.append("pending_modifier")
		var run_started_before_confirm: int = run_started_counts[0]
		start_run_button.button_up.emit()
		new_run_menu.custom_run_modifier_button_container.selected_custom_run_modififers.clear()
		new_run_menu.custom_run_modifier_button_container.selected_custom_run_modififers.append("mutated_modifier")
		_assert_equal(title_screen.pending_run_request["custom_modifier_ids"], ["pending_modifier"], "pending request keeps modifier snapshot")
		var no_custom_modifiers: Array[String] = []
		title_screen.pending_run_request["custom_modifier_ids"] = no_custom_modifiers
		performance_controller.emit_signal("transition_finished", "LEAVING")
		performance_controller.emit_signal("transition_finished", "LEAVING")
		_assert_equal(run_started_counts[0], run_started_before_confirm + 1, "duplicate leaving completion starts exactly one run")
		_assert_equal(requests.size(), 2, "each new run confirmation emits one request")
		if game_global.is_run:
			game_global.end_run()
			file_loader.delete_save()
	signals.run_started.disconnect(run_started_callback)
	title_screen.queue_free()
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

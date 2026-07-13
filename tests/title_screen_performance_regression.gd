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


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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
	var main_menu_rest_position := Vector2.ZERO
	var new_run_menu_rest_position := Vector2.ZERO
	for path: String in REQUIRED_PATHS:
		if not title_screen.has_node(path):
			failures.append("Missing title node: %s" % path)
	for path: String in MENU_PATHS:
		var menu: Control = title_screen.get_node(path)
		if menu.title_screen != title_screen:
			failures.append("%s must resolve its TitleScreen parent" % path)
	title_screen.skip_active_transition()
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "intro skip")
	main_menu_rest_position = main_menu.position
	_assert_stable_control(main_menu, true, main_menu_rest_position, Control.MOUSE_FILTER_STOP, "intro main menu")

	title_screen.show_new_run_menu()
	title_screen.skip_active_transition()
	_assert_equal(title_screen.get_screen_state_name(), "CHARACTER_SELECT", "new run skip")
	new_run_menu_rest_position = new_run_menu.position
	_assert_stable_control(new_run_menu, true, new_run_menu_rest_position, Control.MOUSE_FILTER_STOP, "new run menu")

	title_screen.show_main_menu()
	title_screen.skip_active_transition()
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "back skip")
	_assert_stable_control(main_menu, true, main_menu_rest_position, Control.MOUSE_FILTER_STOP, "back main menu")

	title_screen.show_new_run_menu()
	title_screen.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_assert_equal(title_screen.get_screen_state_name(), "CHARACTER_SELECT", "window focus completes new run transition")
	_assert_stable_control(new_run_menu, true, new_run_menu_rest_position, Control.MOUSE_FILTER_STOP, "window focus new run menu")

	title_screen.show_main_menu()
	title_screen.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_assert_equal(title_screen.get_screen_state_name(), "MAIN_MENU", "window focus completes main menu transition")
	_assert_stable_control(main_menu, true, main_menu_rest_position, Control.MOUSE_FILTER_STOP, "window focus main menu")

	var new_run_button: Button = title_screen.get_node("MainMenu/VBoxContainer/NewRunButton")
	new_run_button.grab_focus()
	title_screen.show_settings_menu()
	title_screen.show_main_menu()
	await process_frame
	_assert_equal(title_screen.get_viewport().gui_get_focus_owner(), new_run_button, "settings return restores main menu focus")
	title_screen.queue_free()
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

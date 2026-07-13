extends Control

enum ScreenState {
	ENTERING,
	MAIN_MENU,
	TO_CHARACTER_SELECT,
	CHARACTER_SELECT,
	TO_MAIN_MENU,
	CODEX,
	SETTINGS,
	LEAVING,
}

var screen_state := ScreenState.ENTERING
var previous_main_focus: Control

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var settings_menu = $SettingsMenu
@onready var performance_controller = $TitlePerformanceController


func _ready() -> void:
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	performance_controller.transition_finished.connect(_on_transition_finished)
	performance_controller.play_title_intro()


func get_screen_state_name() -> String:
	return ScreenState.keys()[screen_state]


func skip_active_transition() -> void:
	if screen_state in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU, ScreenState.LEAVING]:
		performance_controller.complete_active_transition()


func show_main_menu() -> void:
	if screen_state == ScreenState.CHARACTER_SELECT:
		screen_state = ScreenState.TO_MAIN_MENU
		performance_controller.play_to_main_menu()
		return
	var restore_focus := screen_state in [ScreenState.CODEX, ScreenState.SETTINGS]
	codex_menu.visible = false
	settings_menu.visible = false
	performance_controller.apply_main_menu_state()
	screen_state = ScreenState.MAIN_MENU
	if restore_focus:
		call_deferred("_restore_main_focus")


func show_new_run_menu() -> void:
	if screen_state != ScreenState.MAIN_MENU:
		return
	screen_state = ScreenState.TO_CHARACTER_SELECT
	new_run_menu.populate_new_run_menu()
	performance_controller.play_to_character_select()


func show_codex_menu() -> void:
	if screen_state != ScreenState.MAIN_MENU:
		return
	previous_main_focus = get_viewport().gui_get_focus_owner()
	performance_controller.apply_main_menu_state()
	main_menu.visible = false
	settings_menu.visible = false
	codex_menu.visible = true
	codex_menu.populate_codex_menu()
	screen_state = ScreenState.CODEX


func show_settings_menu() -> void:
	if screen_state != ScreenState.MAIN_MENU:
		return
	previous_main_focus = get_viewport().gui_get_focus_owner()
	performance_controller.apply_main_menu_state()
	main_menu.visible = false
	codex_menu.visible = false
	settings_menu.visible = true
	screen_state = ScreenState.SETTINGS


func _restore_main_focus() -> void:
	if is_instance_valid(previous_main_focus) and previous_main_focus.visible:
		previous_main_focus.grab_focus()
	else:
		_restore_default_main_focus()


func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_IN or not is_node_ready():
		return
	if screen_state in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU, ScreenState.LEAVING]:
		performance_controller.complete_active_transition()
	elif screen_state == ScreenState.MAIN_MENU:
		performance_controller.apply_main_menu_state()
	elif screen_state == ScreenState.CHARACTER_SELECT:
		performance_controller.apply_character_select_state()


func _input(event: InputEvent) -> void:
	if screen_state not in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU, ScreenState.LEAVING]:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
		skip_active_transition()
		get_viewport().set_input_as_handled()


func _on_transition_finished(target_state: String) -> void:
	match target_state:
		"MAIN_MENU":
			var restore_default_focus := screen_state == ScreenState.TO_MAIN_MENU
			screen_state = ScreenState.MAIN_MENU
			if restore_default_focus:
				call_deferred("_restore_default_main_focus")
		"CHARACTER_SELECT": screen_state = ScreenState.CHARACTER_SELECT
		"LEAVING": screen_state = ScreenState.LEAVING


func _restore_default_main_focus() -> void:
	for control in main_menu.get_node("VBoxContainer").get_children():
		if control is Control and control.visible and control.focus_mode != Control.FOCUS_NONE:
			control.grab_focus()
			return


func _on_run_started() -> void:
	visible = false



func _on_run_ended() -> void:
	visible = true

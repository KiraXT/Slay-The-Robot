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
var pending_run_request: Dictionary = {}
var pending_run_request_generation := 0
var next_run_request_generation := 0
var current_character_data: CharacterData
var run_start_handler: Callable

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var settings_menu = $SettingsMenu
@onready var performance_controller = $TitlePerformanceController


func _ready() -> void:
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	new_run_menu.connect("character_changed", _on_character_changed)
	new_run_menu.connect("run_requested", _on_run_requested)
	new_run_menu.connect("back_requested", show_main_menu)
	performance_controller.transition_finished.connect(_on_transition_finished)
	performance_controller.play_title_intro()


func get_screen_state_name() -> String:
	return ScreenState.keys()[screen_state]


func skip_active_transition() -> void:
	if screen_state == ScreenState.LEAVING:
		_complete_active_leaving_transition()
	elif screen_state in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU]:
		performance_controller.complete_active_transition()


func show_main_menu() -> void:
	if screen_state == ScreenState.LEAVING:
		_cancel_pending_run_request()
		performance_controller.apply_main_menu_state()
		screen_state = ScreenState.MAIN_MENU
		return
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
	if screen_state == ScreenState.LEAVING:
		_complete_active_leaving_transition()
	elif screen_state in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU]:
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
		"LEAVING": pass


func get_current_character_data() -> CharacterData:
	return current_character_data


func set_run_start_handler(handler: Callable) -> void:
	run_start_handler = handler


func get_pending_run_request_generation() -> int:
	return pending_run_request_generation


func complete_leaving_request(request_generation: int) -> void:
	if screen_state != ScreenState.LEAVING or pending_run_request.is_empty() or request_generation != pending_run_request_generation:
		return
	var run_request := pending_run_request
	pending_run_request = {}
	pending_run_request_generation = 0
	if run_start_handler.is_valid():
		run_start_handler.call(
			run_request["character_object_id"],
			run_request["run_seed"],
			run_request["difficulty_level"],
			run_request["custom_modifier_ids"],
		)
		return
	Global.start_run(
		run_request["character_object_id"],
		run_request["run_seed"],
		run_request["difficulty_level"],
		run_request["custom_modifier_ids"],
	)


func _on_character_changed(character_data: CharacterData) -> void:
	current_character_data = character_data


func _on_run_requested(character_object_id: String, run_seed: int, difficulty_level: int, custom_modifier_ids: Array[String]) -> void:
	if screen_state != ScreenState.CHARACTER_SELECT or not pending_run_request.is_empty():
		return
	next_run_request_generation += 1
	pending_run_request_generation = next_run_request_generation
	pending_run_request = {
		"character_object_id": character_object_id,
		"run_seed": run_seed,
		"difficulty_level": difficulty_level,
		"custom_modifier_ids": custom_modifier_ids.duplicate(),
	}
	screen_state = ScreenState.LEAVING
	performance_controller.play_run_confirm()
	if performance_controller.active_tween != null and performance_controller.active_tween.is_valid():
		performance_controller.active_tween.finished.connect(complete_leaving_request.bind(pending_run_request_generation), CONNECT_ONE_SHOT)


func _cancel_pending_run_request() -> void:
	pending_run_request = {}
	pending_run_request_generation = 0
	if performance_controller.active_target_state != "LEAVING":
		return
	if performance_controller.active_tween != null and performance_controller.active_tween.is_valid():
		performance_controller.active_tween.kill()
	performance_controller.active_tween = null
	performance_controller.active_target_state = ""


func _complete_active_leaving_transition() -> void:
	var request_generation := pending_run_request_generation
	performance_controller.complete_active_transition()
	complete_leaving_request(request_generation)


func _restore_default_main_focus() -> void:
	for control in main_menu.get_node("VBoxContainer").get_children():
		if control is Control and control.visible and control.focus_mode != Control.FOCUS_NONE:
			control.grab_focus()
			return


func _on_run_started() -> void:
	visible = false



func _on_run_ended() -> void:
	visible = true

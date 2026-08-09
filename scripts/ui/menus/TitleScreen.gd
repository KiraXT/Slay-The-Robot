extends Control

const ICON_MENU_PATH := "external/sprites/ui/flipper/icon_menu.png"

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
var character_tween: Tween
var pending_character_visual: CharacterData

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var settings_menu = $SettingsMenu
@onready var performance_controller = $TitlePerformanceController
@onready var backdrop: Control = $Backdrop
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var stage_ring: Control = %StageRing
@onready var character_glow: Control = %CharacterGlow


func _ready() -> void:
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	new_run_menu.connect("character_changed", _on_character_changed)
	new_run_menu.connect("run_requested", _on_run_requested)
	new_run_menu.connect("back_requested", show_main_menu)
	performance_controller.transition_finished.connect(_on_transition_finished)
	backdrop.start_idle_motion()
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
	if _is_gm_console_open():
		return
	if screen_state not in [ScreenState.ENTERING, ScreenState.TO_CHARACTER_SELECT, ScreenState.TO_MAIN_MENU, ScreenState.LEAVING]:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
		skip_active_transition()
		get_viewport().set_input_as_handled()


func _is_gm_console_open() -> bool:
	for console in get_tree().get_nodes_in_group("gm_console"):
		if console.visible:
			return true
	return false


func _on_transition_finished(target_state: String) -> void:
	match target_state:
		"MAIN_MENU":
			screen_state = ScreenState.MAIN_MENU
			main_menu.call_deferred("grab_default_focus")
		"CHARACTER_SELECT":
			screen_state = ScreenState.CHARACTER_SELECT
			call_deferred("_focus_selected_character")
		"LEAVING": complete_leaving_request(pending_run_request_generation)


func get_current_character_data() -> CharacterData:
	return current_character_data


func get_pending_run_request_generation() -> int:
	return pending_run_request_generation


func complete_leaving_request(request_generation: int) -> void:
	if screen_state != ScreenState.LEAVING or pending_run_request.is_empty() or request_generation != pending_run_request_generation:
		return
	var run_request := pending_run_request
	pending_run_request = {}
	pending_run_request_generation = 0
	Global.start_run(
		run_request["character_object_id"],
		run_request["run_seed"],
		run_request["difficulty_level"],
		run_request["custom_modifier_ids"],
	)


func _on_character_changed(character_data: CharacterData) -> void:
	current_character_data = character_data
	pending_character_visual = character_data
	if character_tween != null and character_tween.is_valid():
		character_tween.kill()
	character_tween = create_tween()
	character_tween.tween_property(character_portrait, "modulate:a", 0.0, 0.08)
	character_tween.parallel().tween_property(character_portrait, "scale", Vector2(0.90, 0.90), 0.08)
	character_tween.tween_callback(_apply_pending_character_visual)
	character_tween.tween_property(character_portrait, "modulate:a", 1.0, 0.14)
	character_tween.parallel().tween_property(character_portrait, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_pending_character_visual() -> void:
	if pending_character_visual == null:
		return
	var character_data := pending_character_visual
	character_portrait.texture = _load_character_portrait(character_data)
	backdrop.set_character_background(character_data.character_background_texture_path)
	var color_data := Global.get_color_data(character_data.character_color_id)
	var accent := color_data.color if color_data != null else Color.WHITE
	stage_ring.modulate = accent
	character_glow.modulate = Color(accent, 0.35)


func _load_character_portrait(character_data: CharacterData) -> Texture2D:
	var candidate_paths: Array[String] = [character_data.character_texture_path, character_data.character_icon_texture_path, ICON_MENU_PATH]
	return _load_first_available_character_portrait(candidate_paths)


func _load_first_available_character_portrait(candidate_paths: Array[String]) -> Texture2D:
	for path: String in candidate_paths:
		var texture := _load_optional_texture(path)
		if texture.get_size() != Vector2.ZERO:
			return texture
	return FileLoader.load_texture_or_fallback("", "character")


func _load_optional_texture(path: String) -> Texture2D:
	if not _texture_file_exists(path):
		return ImageTexture.new()
	return FileLoader.load_texture(path)


func _texture_file_exists(path: String) -> bool:
	return not path.is_empty() and FileAccess.file_exists(FileLoader._get_modified_filepath(path))


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
	backdrop.play_confirm_particles()


func _cancel_pending_run_request() -> void:
	pending_run_request = {}
	pending_run_request_generation = 0
	backdrop.stop_confirm_particles()
	if performance_controller.active_target_state != "LEAVING":
		return
	if performance_controller.active_tween != null and performance_controller.active_tween.is_valid():
		performance_controller.active_tween.kill()
	performance_controller.active_tween = null
	performance_controller.active_target_state = ""


func _complete_active_leaving_transition() -> void:
	performance_controller.complete_active_transition()


func _restore_default_main_focus() -> void:
	main_menu.grab_default_focus()


func _focus_selected_character() -> void:
	for control in new_run_menu.get_node("CharacterButtonContainer/GridContainer").get_children():
		if control is BaseButton and control.button_pressed:
			control.grab_focus()
			return


func _on_run_started() -> void:
	backdrop.stop_idle_motion()
	visible = false



func _on_run_ended() -> void:
	visible = true
	backdrop.start_idle_motion()

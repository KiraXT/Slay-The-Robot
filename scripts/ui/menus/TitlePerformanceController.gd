extends Node
class_name TitlePerformanceController

signal transition_finished(target_state: String)

const INTRO_DURATION := 1.05
const TO_CHARACTER_DURATION := 0.80
const TO_MAIN_DURATION := 0.60
const RUN_CONFIRM_DURATION := 0.65

var active_tween: Tween
var active_target_state: String = ""
var backdrop_rest_position: Vector2
var title_ornament_rest_position: Vector2
var title_rest_position: Vector2
var main_menu_rest_position: Vector2
var new_run_rest_position: Vector2
var transition_overlay_rest_position: Vector2
var main_menu_buttons: Array = []

@onready var backdrop: Control = $%Backdrop
@onready var title_ornament: TextureRect = $%TitleOrnament
@onready var game_title: Label = $%GameTitle
@onready var main_menu: Control = $%MainMenu
@onready var new_run_menu: Control = $%NewRunMenu
@onready var transition_overlay: ColorRect = $%TransitionOverlay
@onready var character_stage: Control = $%CharacterStage


func _ready() -> void:
	backdrop_rest_position = backdrop.position
	title_ornament_rest_position = title_ornament.position
	title_rest_position = game_title.position
	main_menu_rest_position = main_menu.position
	new_run_rest_position = new_run_menu.position
	transition_overlay_rest_position = transition_overlay.position
	_cache_performance_nodes()


func _cache_performance_nodes() -> void:
	backdrop_rest_position = backdrop.position
	main_menu_buttons = main_menu.get_node("VBoxContainer").get_children().filter(
		func(child: Node) -> bool: return child is Button
	)


func play_title_intro() -> void:
	apply_entering_state()
	_start_sequence("MAIN_MENU")
	active_tween.tween_property(backdrop, "modulate:a", 1.0, 0.55)
	active_tween.tween_property(game_title, "position:y", title_rest_position.y, 0.57).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(game_title, "modulate:a", 1.0, 0.30).set_delay(0.18)
	active_tween.tween_property(main_menu, "modulate:a", 1.0, 0.30).set_delay(0.45)
	for index: int in main_menu_buttons.size():
		main_menu_buttons[index].modulate.a = 0.0
		active_tween.tween_property(main_menu_buttons[index], "modulate:a", 1.0, 0.24).set_delay(0.45 + index * 0.06)
	active_tween.tween_callback(_finish_sequence.bind("MAIN_MENU")).set_delay(INTRO_DURATION)


func play_to_character_select() -> void:
	_start_sequence("CHARACTER_SELECT")
	main_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_run_menu.visible = true
	new_run_menu.modulate.a = 0.0
	new_run_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_stage.scale = Vector2(0.92, 0.92)
	active_tween.tween_property(main_menu, "position:x", -main_menu.size.x, 0.18)
	active_tween.tween_property(main_menu, "modulate:a", 0.0, 0.18)
	active_tween.tween_property(backdrop, "position", backdrop_rest_position + Vector2(-42.0, 16.0), 0.50).set_delay(0.08)
	active_tween.tween_property(new_run_menu, "modulate:a", 1.0, 0.35).set_delay(0.35)
	active_tween.tween_property(character_stage, "scale", Vector2.ONE, 0.28).set_delay(0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_callback(_finish_sequence.bind("CHARACTER_SELECT")).set_delay(TO_CHARACTER_DURATION)


func play_to_main_menu() -> void:
	_start_sequence("MAIN_MENU")
	new_run_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_menu.visible = true
	main_menu.position = main_menu_rest_position - Vector2(24.0, 0.0)
	main_menu.scale = Vector2.ONE
	main_menu.modulate.a = 0.0
	main_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_tween.tween_property(new_run_menu, "position:x", new_run_rest_position.x + new_run_menu.size.x, 0.28)
	active_tween.tween_property(new_run_menu, "modulate:a", 0.0, 0.28)
	active_tween.tween_property(backdrop, "position", backdrop_rest_position, 0.42)
	active_tween.tween_property(main_menu, "position", main_menu_rest_position, 0.30).set_delay(0.20)
	active_tween.tween_property(main_menu, "modulate:a", 1.0, 0.30).set_delay(0.20)
	active_tween.tween_callback(_finish_sequence.bind("MAIN_MENU")).set_delay(TO_MAIN_DURATION)


func play_run_confirm() -> void:
	_start_sequence("LEAVING")
	main_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_run_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = true
	transition_overlay.position = transition_overlay_rest_position
	transition_overlay.scale = Vector2.ONE
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	active_tween.tween_property(character_stage, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(new_run_menu, "modulate:a", 0.0, 0.35).set_delay(0.20)
	active_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.25).set_delay(0.40)
	active_tween.tween_callback(_finish_sequence.bind("LEAVING")).set_delay(RUN_CONFIRM_DURATION)


func complete_active_transition() -> void:
	if active_target_state.is_empty():
		return
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	_finish_sequence(active_target_state)


func apply_entering_state() -> void:
	_apply_control_state(backdrop, true, backdrop_rest_position, 0.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(title_ornament, true, title_ornament_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(game_title, true, title_rest_position - Vector2(0.0, 24.0), 0.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(main_menu, true, main_menu_rest_position - Vector2(20.0, 0.0), 0.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(new_run_menu, false, new_run_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(transition_overlay, false, transition_overlay_rest_position, 0.0, Control.MOUSE_FILTER_IGNORE)


func apply_main_menu_state() -> void:
	_apply_control_state(backdrop, true, backdrop_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(title_ornament, true, title_ornament_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(game_title, true, title_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(main_menu, true, main_menu_rest_position, 1.0, Control.MOUSE_FILTER_STOP)
	_apply_control_state(new_run_menu, false, new_run_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(transition_overlay, false, transition_overlay_rest_position, 0.0, Control.MOUSE_FILTER_IGNORE)
	character_stage.scale = Vector2.ONE
	for button: Button in main_menu_buttons:
		button.modulate.a = 1.0


func apply_character_select_state() -> void:
	_apply_control_state(backdrop, true, backdrop_rest_position + Vector2(-42.0, 16.0), 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(title_ornament, false, title_ornament_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(game_title, false, title_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(main_menu, false, main_menu_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(new_run_menu, true, new_run_rest_position, 1.0, Control.MOUSE_FILTER_STOP)
	_apply_control_state(transition_overlay, false, transition_overlay_rest_position, 0.0, Control.MOUSE_FILTER_IGNORE)
	character_stage.scale = Vector2.ONE


func apply_leaving_state() -> void:
	_apply_control_state(backdrop, true, backdrop_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(title_ornament, false, title_ornament_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(game_title, false, title_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(main_menu, false, main_menu_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(new_run_menu, false, new_run_rest_position, 1.0, Control.MOUSE_FILTER_IGNORE)
	_apply_control_state(transition_overlay, true, transition_overlay_rest_position, 1.0, Control.MOUSE_FILTER_STOP)


func _apply_control_state(control: Control, is_visible: bool, rest_position: Vector2, alpha: float, input_filter: Control.MouseFilter) -> void:
	control.visible = is_visible
	control.position = rest_position
	control.scale = Vector2.ONE
	control.modulate.a = alpha
	control.mouse_filter = input_filter


func _start_sequence(target_state: String) -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	active_target_state = target_state
	active_tween = create_tween().set_parallel(true)


func _finish_sequence(target_state: String) -> void:
	match target_state:
		"MAIN_MENU": apply_main_menu_state()
		"CHARACTER_SELECT": apply_character_select_state()
		"LEAVING": apply_leaving_state()
	active_tween = null
	active_target_state = ""
	transition_finished.emit(target_state)

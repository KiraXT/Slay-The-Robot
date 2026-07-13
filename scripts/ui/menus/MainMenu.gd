# Main menu on title screen
extends Control

@onready var title_screen: Control = get_parent()

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var forfeit_run_button: Button = $VBoxContainer/ForfeitRunButton
@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var codex_button: Button = $VBoxContainer/CodexButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

var button_base_x: Dictionary = {}
var button_tweens: Dictionary = {}


func _ready() -> void:
	continue_button.button_up.connect(_on_continue_button_up)
	forfeit_run_button.button_up.connect(_on_forfeit_run_button_up)
	new_run_button.button_up.connect(_on_new_run_button_up)
	codex_button.button_up.connect(_on_codex_button_up)
	settings_button.button_up.connect(_on_settings_button_up)
	exit_button.button_up.connect(_on_exit_button_up)
	for button: Button in [continue_button, forfeit_run_button, new_run_button, codex_button, settings_button, exit_button]:
		_connect_button_motion(button)

	Signals.run_ended.connect(_on_run_ended)
	
	update_continue_button_visibility()


func _connect_button_motion(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	button_base_x[button] = button.position.x
	button.focus_entered.connect(_animate_button_focus.bind(button, true))
	button.focus_exited.connect(_animate_button_focus.bind(button, false))
	button.mouse_entered.connect(_animate_button_focus.bind(button, true))
	button.mouse_exited.connect(_animate_button_focus.bind(button, false))
	button.button_down.connect(_animate_button_press.bind(button, true))
	button.button_up.connect(_animate_button_press.bind(button, false))


func _animate_button_focus(button: Button, focused: bool) -> void:
	_kill_button_tween(button)
	var tween := create_tween().set_parallel(true)
	button_tweens[button] = tween
	tween.tween_property(button, "position:x", button_base_x[button] + (12.0 if focused else 0.0), 0.12)
	tween.tween_property(button, "self_modulate", Color.WHITE if focused else Color(0.94, 0.98, 1.0), 0.12)


func _animate_button_press(button: Button, pressed: bool) -> void:
	_kill_button_tween(button)
	var tween := create_tween()
	button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2(0.96, 0.96) if pressed else Vector2.ONE, 0.10)


func _kill_button_tween(button: Button) -> void:
	var tween: Tween = button_tweens.get(button)
	if tween != null and tween.is_valid():
		tween.kill()


func grab_default_focus() -> void:
	var target: Button = continue_button if continue_button.visible and not continue_button.disabled else new_run_button
	if target.visible and not target.disabled:
		target.grab_focus()

func _on_continue_button_up():
	FileLoader.autoload()

func _on_forfeit_run_button_up():
	FileLoader.delete_save()
	update_continue_button_visibility()

func _on_new_run_button_up():
	title_screen.show_new_run_menu()

func _on_codex_button_up():
	title_screen.show_codex_menu()

func _on_settings_button_up():
	title_screen.show_settings_menu()

func _on_exit_button_up():
	get_tree().quit()

func update_continue_button_visibility() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	continue_button.visible = has_save_file
	forfeit_run_button.visible = has_save_file
	new_run_button.visible = not has_save_file

func _on_run_ended():
	# go back to tile screen on abandoned run, but not failed run
	var has_save_file: bool = FileLoader.has_save_file()
	visible = has_save_file
	update_continue_button_visibility()

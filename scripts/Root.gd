extends Node2D

const GM_CONSOLE_SCRIPT := preload("res://scripts/dev/GMConsole.gd")

var gm_console: GM_CONSOLE_SCRIPT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_gm_console()


func _create_gm_console() -> void:
	if gm_console != null:
		return
	gm_console = GM_CONSOLE_SCRIPT.new()
	gm_console.name = "GMConsole"
	add_child(gm_console)


func _toggle_gm_console() -> bool:
	if gm_console == null or not gm_console.is_enabled():
		return false
	gm_console.toggle()
	return true


func _is_gm_console_toggle_event(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_QUOTELEFT


func _is_gm_console_cancel_event(event: InputEvent) -> bool:
	if gm_console == null or not gm_console.visible or not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.is_action_pressed("ui_cancel")


func _input(event: InputEvent) -> void:
	if _is_gm_console_cancel_event(event):
		gm_console.hide_console()
		get_viewport().set_input_as_handled()
		return
	if _is_gm_console_toggle_event(event) and _toggle_gm_console():
		get_viewport().set_input_as_handled()
		return

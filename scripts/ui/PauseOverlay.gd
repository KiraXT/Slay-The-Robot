extends Control

@onready var resume_button: Button = %ResumeButton
@onready var return_to_title_button: Button = %ReturnToTitleButton
@onready var forfeit_run_button: Button = %ForfeitRunButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_button_pressed)
	return_to_title_button.pressed.connect(_on_return_to_title_button_pressed)
	forfeit_run_button.pressed.connect(_on_forfeit_run_button_pressed)
	
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	
	Signals.game_paused.connect(_on_game_paused)
	Signals.game_unpaused.connect(_on_game_unpaused)


func _input(event: InputEvent) -> void:
	if _handle_back_navigation_event(event):
		get_viewport().set_input_as_handled()


func _handle_back_navigation_event(event: InputEvent) -> bool:
	if not visible or _is_gm_console_open():
		return false
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo or not key_event.is_action_pressed("ui_cancel"):
		return false
	_on_resume_button_pressed()
	return true


func _is_gm_console_open() -> bool:
	for console in get_tree().get_nodes_in_group("gm_console"):
		if console is CanvasItem and console.visible:
			return true
	return false

func _on_run_started():
	visible = false
	
func _on_run_ended():
	visible = false
	

func _on_resume_button_pressed() -> void:
	Global.unpause_game()

func _on_return_to_title_button_pressed() -> void:
	Global.unpause_game()
	Global.end_run(Global.RUN_ENDS.QUIT)

func _on_forfeit_run_button_pressed() -> void:
	Global.unpause_game()
	Global.end_run(Global.RUN_ENDS.LOSS)

func _on_game_paused() -> void:
	visible = true

func _on_game_unpaused() -> void:
	visible = false

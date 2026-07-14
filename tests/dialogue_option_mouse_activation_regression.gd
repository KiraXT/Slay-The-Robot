extends SceneTree

const DIALOGUE_OPTION_SCENE := "res://scenes/ui/general/DialogueOption.tscn"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var option: DialogueOption = load(DIALOGUE_OPTION_SCENE).instantiate()
	root.add_child(option)
	await process_frame
	if option.has_method("_on_gui_input"):
		failures.append("DialogueOption must not override Button's native _gui_input callback")
	if not option.has_method("_on_option_gui_input"):
		failures.append("DialogueOption must subscribe to gui_input without overriding Button's native callback")
	option.init("", "Enabled", "Disabled", [] as Array[Dictionary], [] as Array[Dictionary])
	var clicked_count := [0]
	option.dialogue_option_clicked.connect(func(_option) -> void: clicked_count[0] += 1)
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	option._on_option_gui_input(press_event)
	if clicked_count[0] != 1:
		failures.append("A left mouse press delivered through gui_input must activate an enabled DialogueOption")

	option.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

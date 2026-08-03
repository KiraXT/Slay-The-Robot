extends SceneTree

const DIALOGUE_OPTION_SCENE := "res://scenes/ui/general/DialogueOption.tscn"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load(DIALOGUE_OPTION_SCENE)
	var option = packed.instantiate()
	root.add_child(option)
	await process_frame
	if not option is Button:
		failures.append("DialogueOption must use a native Button root so real mouse clicks are handled reliably")
	option.init("", "[color=green]Test option[/color]", "[color=red]Disabled[/color]", [] as Array[Dictionary], [] as Array[Dictionary])

	var clicked_count := [0]
	option.dialogue_option_clicked.connect(func(_dialogue_option) -> void:
		clicked_count[0] += 1
	)

	option._on_mouse_entered()
	await create_timer(0.03).timeout
	if option.self_modulate == DialogueOption.NORMAL_MODULATE:
		failures.append("DialogueOption hover must provide visual feedback")

	option.button_down.emit()

	if option.scale == DialogueOption.NORMAL_SCALE and option.self_modulate == DialogueOption.HOVER_MODULATE:
		failures.append("DialogueOption click must provide pressed visual feedback")
	option.button_up.emit()

	if clicked_count[0] != 1:
		failures.append("DialogueOption button_up must emit dialogue_option_clicked once")
	await create_timer(0.03).timeout

	option.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

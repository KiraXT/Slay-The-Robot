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

	option.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

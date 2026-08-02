extends SceneTree

const ROOT_SCENE_PATH := "res://scenes/Root.tscn"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load(ROOT_SCENE_PATH).instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var new_run_menu: Node = root_scene.get_node("TitleScreen/NewRunMenu")
	if new_run_menu.get_node_or_null("InfoPanel") == null:
		failures.append("new run must use the blue-branch InfoPanel layout")
	if new_run_menu.get_node_or_null("RunConfigPanel") == null:
		failures.append("new run must use the blue-branch RunConfigPanel layout")
	if new_run_menu.get_node_or_null("CharacterNameLabel") != null:
		failures.append("new run must not use the flattened ArtUIShell layout")

	var combat: Node = root_scene.get_node("RunScreen/Combat")
	for panel_name in ["TopResourceBar", "LeftPileDock", "RightPileDock", "HandTray"]:
		if combat.get_node_or_null(panel_name) != null:
			failures.append("combat must not inject the ArtUIShell %s panel" % panel_name)

	root_scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)

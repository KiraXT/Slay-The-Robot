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
	var info_panel := new_run_menu.get_node_or_null("InfoPanel") as Control
	var stage := new_run_menu.get_node_or_null("CharacterStage") as Control
	var character_buttons := new_run_menu.get_node_or_null("CharacterButtonContainer") as Control
	var run_config := new_run_menu.get_node_or_null("RunConfigPanel") as Control
	if info_panel == null or stage == null or character_buttons == null or run_config == null:
		failures.append("new run must retain its layout anchors for the title transition")
	else:
		if stage.visible:
			failures.append("new run must hide the title-stage character display")
		if character_buttons.position != Vector2(56.0, 552.0):
			failures.append("new run must place character buttons at the legacy blue position")
		if run_config.position != Vector2.ZERO:
			failures.append("new run must use the legacy blue run configuration origin")
		var difficulty_select := run_config.get_node_or_null("DifficultySelect") as Control
		var modifier_list := run_config.get_node_or_null("CustomRunModifierButtonContainer") as Control
		var seed_input := run_config.get_node_or_null("SeedInput") as Control
		var start_run := run_config.get_node_or_null("StartRunButton") as Control
		if difficulty_select == null or modifier_list == null or seed_input == null or start_run == null:
			failures.append("new run must keep the legacy blue configuration controls")
		else:
			if difficulty_select.position != Vector2(64.0, 504.0):
				failures.append("new run must place difficulty controls at the legacy blue position")
			if modifier_list.position != Vector2(824.0, 168.0):
				failures.append("new run must place modifiers at the legacy blue position")
			if seed_input.position != Vector2(472.0, 552.0):
				failures.append("new run must place the seed input at the legacy blue position")
			if start_run.position != Vector2(392.0, 600.0):
				failures.append("new run must place the start control at the legacy blue position")
	if root_scene.get_node_or_null("TitleScreen/Backdrop") == null:
		failures.append("the title-screen backdrop must remain available")

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

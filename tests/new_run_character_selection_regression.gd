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
	new_run_menu.populate_new_run_menu()
	await create_timer(0.35).timeout

	var selected_character_id: String = new_run_menu.get("selected_character_object_id")
	if selected_character_id.is_empty():
		failures.append("new run must select a default character when it populates")
	var name_label := new_run_menu.get_node("InfoPanel/CharacterNameLabel") as Label
	if name_label.text.is_empty() or name_label.text == "Character Name":
		failures.append("new run must populate character information after default selection")
	var start_button := new_run_menu.get_node("RunConfigPanel/StartRunButton") as Button
	if start_button.disabled:
		failures.append("new run must enable start after a character is selected")
	var requested_character_ids: Array[String] = []
	new_run_menu.run_requested.connect(func(character_id, _seed, _difficulty, _modifiers): requested_character_ids.append(str(character_id)))
	new_run_menu._on_start_run_button_up()
	await process_frame
	if requested_character_ids != [selected_character_id]:
		failures.append("new run must emit a run request for the selected character")
	var portrait := new_run_menu.get_node("CharacterStage/CharacterPortrait") as TextureRect
	if portrait.texture == null or not portrait.texture.resource_path.contains("external/sprites/characters/"):
		failures.append("new run must show the selected character portrait on the stage")
	var backdrop_a := root_scene.get_node("TitleScreen/Backdrop/CharacterBackgroundA") as TextureRect
	var backdrop_b := root_scene.get_node("TitleScreen/Backdrop/CharacterBackgroundB") as TextureRect
	var background_path := ""
	if backdrop_a.texture != null:
		background_path = backdrop_a.texture.resource_path
	if background_path.is_empty() and backdrop_b.texture != null:
		background_path = backdrop_b.texture.resource_path
	if not background_path.contains("_background.png"):
		failures.append("new run must show the selected character background")
	var character_buttons: Node = new_run_menu.get_node("CharacterButtonContainer/GridContainer")
	if character_buttons.get_child_count() == 0:
		failures.append("new run must create character selection buttons")
	else:
		var first_button: Node = character_buttons.get_child(0)
		if first_button.get_node_or_null("AvatarFrame/Avatar") == null:
			failures.append("character buttons must use the blue circular avatar presentation")

	root_scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)

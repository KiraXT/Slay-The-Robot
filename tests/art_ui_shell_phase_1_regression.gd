extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame

	_check_root_shell(root_scene)
	_check_card_shell()

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


func _check_root_shell(root_scene: Node) -> void:
	_assert_has_node(root_scene, "TitleScreen/MainMenu/ShellPanel")
	_assert_has_node(root_scene, "TitleScreen/MainMenu/HeroBadge")
	_assert_has_node(root_scene, "TitleScreen/NewRunMenu/CharacterInfoPanel")
	_assert_has_node(root_scene, "TitleScreen/NewRunMenu/RunSetupPanel")
	_assert_has_node(root_scene, "TitleScreen/NewRunMenu/ModifierPanel")
	_assert_has_node(root_scene, "RunScreen/Combat/TopResourceBar")
	_assert_has_node(root_scene, "RunScreen/Combat/LeftPileDock")
	_assert_has_node(root_scene, "RunScreen/Combat/RightPileDock")
	_assert_has_node(root_scene, "RunScreen/Combat/HandTray")
	_assert_shell_panel(root_scene, "TitleScreen/MainMenu/ShellPanel")
	_assert_shell_panel(root_scene, "TitleScreen/NewRunMenu/CharacterInfoPanel")
	_assert_shell_panel(root_scene, "RunScreen/Combat/TopResourceBar")
	_assert_shell_panel(root_scene, "RunScreen/Combat/HandTray")


func _check_card_shell() -> void:
	var card_scene: Node = load("res://scenes/ui/Card.tscn").instantiate()
	root.add_child(card_scene)
	await process_frame

	_assert_has_node(card_scene, "Pivot/CardVisual/FactionBadge")
	_assert_has_node(card_scene, "Pivot/CardVisual/ArtFrame")
	_assert_has_node(card_scene, "Pivot/CardVisual/DescriptionPanel")

	var faction_badge := card_scene.get_node_or_null("Pivot/CardVisual/FactionBadge") as ColorRect
	if faction_badge != null and faction_badge.color.a < 0.95:
		failures.append("Card FactionBadge must be opaque enough to read at hand size")

	var art_frame := card_scene.get_node_or_null("Pivot/CardVisual/ArtFrame") as Control
	var card_texture := card_scene.get_node_or_null("Pivot/CardVisual/CardTexture") as Control
	if art_frame != null and card_texture != null:
		if art_frame.get_index() > card_texture.get_index():
			failures.append("Card ArtFrame must sit behind CardTexture")

	var description_panel := card_scene.get_node_or_null("Pivot/CardVisual/DescriptionPanel") as Control
	var description := card_scene.get_node_or_null("Pivot/CardVisual/CardDescription") as Control
	if description_panel != null and description != null:
		if description_panel.get_index() > description.get_index():
			failures.append("Card DescriptionPanel must sit behind CardDescription")

	card_scene.queue_free()


func _assert_has_node(parent: Node, node_path: String) -> void:
	if parent.get_node_or_null(node_path) == null:
		failures.append("Missing UI shell node: %s" % node_path)


func _assert_shell_panel(parent: Node, node_path: String) -> void:
	var panel := parent.get_node_or_null(node_path) as Control
	if panel == null:
		return
	if not panel.visible:
		failures.append("%s must be visible" % node_path)
	if panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("%s must ignore mouse input so it does not block existing interaction" % node_path)
	if panel.get_meta("art_ui_shell_role", "") == "":
		failures.append("%s must declare art_ui_shell_role metadata" % node_path)

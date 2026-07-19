extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var global = root.get_node("Global")
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame

	_check_root_shell(root_scene)
	await _check_card_shell(global)

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
	_assert_drawn_after(root_scene, "RunScreen/Combat/TopResourceBar", "RunScreen/Combat/BackgroundButton")
	_assert_drawn_after(root_scene, "RunScreen/Combat/LeftPileDock", "RunScreen/Combat/BackgroundButton")
	_assert_drawn_after(root_scene, "RunScreen/Combat/RightPileDock", "RunScreen/Combat/BackgroundButton")
	_assert_drawn_after(root_scene, "RunScreen/Combat/HandTray", "RunScreen/Combat/BackgroundButton")

	var combat := root_scene.get_node("RunScreen/Combat")
	combat.call("set_combat_display_visibility", false)
	_assert_hidden(root_scene, "RunScreen/Combat/HandTray")


func _check_card_shell(global: Node) -> void:
	var card_scene: Node = load("res://scenes/ui/Card.tscn").instantiate()
	root.add_child(card_scene)
	await process_frame

	_assert_has_node(card_scene, "Pivot/CardVisual/FactionBadge")
	_assert_has_node(card_scene, "Pivot/CardVisual/ArtFrame")
	_assert_has_node(card_scene, "Pivot/CardVisual/DescriptionPanel")

	var faction_badge := card_scene.get_node_or_null("Pivot/CardVisual/FactionBadge") as ColorRect
	if faction_badge != null and faction_badge.color.a < 0.95:
		failures.append("Card FactionBadge must be opaque enough to read at hand size")
	_assert_drawn_after(card_scene, "Pivot/CardVisual/FactionBadge", "Pivot/CardVisual/Background")

	var art_frame := card_scene.get_node_or_null("Pivot/CardVisual/ArtFrame") as Control
	var card_texture := card_scene.get_node_or_null("Pivot/CardVisual/CardTexture") as Control
	if art_frame != null and card_texture != null:
		if art_frame.get_index() > card_texture.get_index():
			failures.append("Card ArtFrame must sit behind CardTexture")
	_assert_drawn_after(card_scene, "Pivot/CardVisual/ArtFrame", "Pivot/CardVisual/Background")

	var description_panel := card_scene.get_node_or_null("Pivot/CardVisual/DescriptionPanel") as Control
	var description := card_scene.get_node_or_null("Pivot/CardVisual/CardDescription") as Control
	if description_panel != null and description != null:
		if description_panel.get_index() > description.get_index():
			failures.append("Card DescriptionPanel must sit behind CardDescription")
	_assert_drawn_after(card_scene, "Pivot/CardVisual/DescriptionPanel", "Pivot/CardVisual/Background")

	card_scene.queue_free()
	await process_frame

	var red_card = global.get_card_data("card_opening_strike")
	if red_card == null:
		failures.append("card_opening_strike must be available for card chrome color checks")
		return
	var runtime_card: Node = load("res://scenes/ui/Card.tscn").instantiate()
	root.add_child(runtime_card)
	runtime_card.call("init", red_card, 0, false, false)
	await process_frame
	var runtime_badge := runtime_card.get_node_or_null("Pivot/CardVisual/FactionBadge") as ColorRect
	var color_data = global.get_color_data(red_card.card_color_id)
	if runtime_badge == null:
		failures.append("Runtime card must keep FactionBadge after init")
	elif color_data == null:
		failures.append("%s must resolve to ColorData" % red_card.card_color_id)
	elif not _colors_match(runtime_badge.color, color_data.color):
		failures.append("Runtime card FactionBadge must match card color %s, got %s" % [color_data.color, runtime_badge.color])
	runtime_card.queue_free()
	await process_frame


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


func _assert_drawn_after(parent: Node, front_path: String, back_path: String) -> void:
	var front := parent.get_node_or_null(front_path)
	var back := parent.get_node_or_null(back_path)
	if front == null or back == null:
		return
	if front.get_parent() != back.get_parent():
		failures.append("%s and %s must share a parent for draw order checks" % [front_path, back_path])
		return
	if front.get_index() <= back.get_index():
		failures.append("%s must be drawn after %s" % [front_path, back_path])


func _assert_hidden(parent: Node, node_path: String) -> void:
	var node := parent.get_node_or_null(node_path) as CanvasItem
	if node == null:
		return
	if node.visible:
		failures.append("%s must hide when combat display is hidden" % node_path)


func _colors_match(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) < 0.01 and absf(actual.g - expected.g) < 0.01 and absf(actual.b - expected.b) < 0.01 and absf(actual.a - expected.a) < 0.01

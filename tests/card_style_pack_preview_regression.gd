extends SceneTree

const STYLE_DIR := "external/data/card_styles/"
const STYLE_FILE := "card_style_preview.json"
const CARD_SCENE_PATH := "res://scenes/ui/Card.tscn"
const CARD_DATA_SCRIPT_PATH := "res://data/prototype/CardData.gd"

const CARD_TYPE_ATTACK := 0
const CARD_TYPE_SKILL := 1
const CARD_TYPE_POWER := 2
const CARD_TYPE_STATUS := 3
const CARD_TYPE_CURSE := 4

const MASTER_SLOT_BY_ID := {
	"color_red": "external/sprites/ui/card_styles/full_master/card_master_red.png",
	"color_blue": "external/sprites/ui/card_styles/full_master/card_master_blue.png",
	"color_green": "external/sprites/ui/card_styles/full_master/card_master_green.png",
	"color_orange": "external/sprites/ui/card_styles/full_master/card_master_gold.png",
	"color_white": "external/sprites/ui/card_styles/full_master/card_master_silver.png",
}

const TYPE_SLOT_BY_ID := {
	CARD_TYPE_ATTACK: "external/sprites/ui/card_styles/full_master/ribbons/ribbon_attack.png",
	CARD_TYPE_SKILL: "external/sprites/ui/card_styles/full_master/ribbons/ribbon_skill.png",
	CARD_TYPE_POWER: "external/sprites/ui/card_styles/full_master/ribbons/ribbon_power.png",
	CARD_TYPE_STATUS: "external/sprites/ui/card_styles/full_master/ribbons/ribbon_status.png",
	CARD_TYPE_CURSE: "external/sprites/ui/card_styles/full_master/ribbons/ribbon_curse.png",
}

const LEGACY_STITCHED_LAYERS := [
	"ColorBackground",
	"CardBackground",
	"CardHeaderBackground",
	"CardArtFrame",
	"CardDescriptionBackground",
	"CardTypeConnector",
	"CardFactionBadge",
	"CardFactionStamp",
	"EnergySprite",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var file_loader := root.get_node("FileLoader")
	var style_data := _check_style_pack(file_loader)
	if not style_data.is_empty():
		await _check_runtime_style_variants(style_data, file_loader)
		await _check_atomic_style_fallback(file_loader)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_style_pack(file_loader: Node) -> Dictionary:
	var style_path := STYLE_DIR + STYLE_FILE
	if not FileAccess.file_exists(file_loader.call("_get_modified_filepath", style_path)):
		failures.append("card style preview JSON must exist at %s" % style_path)
		return {}

	var style_data := file_loader.call("load_json", STYLE_DIR, STYLE_FILE) as Dictionary
	if style_data.get("object_id", "") != "card_style_preview":
		failures.append("card style preview object_id must be card_style_preview")

	_check_slot_group(style_data, "master_slots", MASTER_SLOT_BY_ID.keys(), file_loader)
	_check_slot_group(style_data, "type_slots", TYPE_SLOT_BY_ID.keys(), file_loader)
	_check_transparent_edge_contamination(style_data)
	return style_data


func _check_slot_group(style_data: Dictionary, group_name: String, slot_names: Array, file_loader: Node) -> void:
	var slots: Variant = style_data.get(group_name)
	if not slots is Dictionary:
		failures.append("card style preview must define %s" % group_name)
		return

	for slot_name: Variant in slot_names:
		var texture_path := str((slots as Dictionary).get(str(slot_name), ""))
		if texture_path.is_empty():
			failures.append("%s must define texture slot %s" % [group_name, slot_name])
			continue
		if not FileAccess.file_exists(file_loader.call("_get_modified_filepath", texture_path)):
			failures.append("%s texture for %s must exist at %s" % [group_name, slot_name, texture_path])


func _check_runtime_style_variants(style_data: Dictionary, file_loader: Node) -> void:
	var cases := [
		{"color_id": "color_red", "type_id": CARD_TYPE_ATTACK},
		{"color_id": "color_blue", "type_id": CARD_TYPE_SKILL},
		{"color_id": "color_green", "type_id": CARD_TYPE_POWER},
		{"color_id": "color_orange", "type_id": CARD_TYPE_STATUS},
		{"color_id": "color_white", "type_id": CARD_TYPE_CURSE},
	]

	for case_data: Dictionary in cases:
		var card_scene := await _render_style_card(case_data)
		if card_scene == null:
			continue
		var visual := card_scene.get_node("Pivot/CardVisual") as Control
		var color_id := str(case_data["color_id"])
		var type_id := int(case_data["type_id"])
		_assert_texture_rect(
			visual,
			"CardChrome",
			str(file_loader.call("_get_modified_filepath", MASTER_SLOT_BY_ID[color_id])),
			"%s full-card master" % color_id
		)
		_assert_panel_texture(
			visual,
			"CardTypeBackground",
			str(file_loader.call("_get_modified_filepath", TYPE_SLOT_BY_ID[type_id])),
			"%s type ribbon" % type_id
		)
		_assert_master_layer_order(visual, color_id)
		for layer_name: String in LEGACY_STITCHED_LAYERS:
			_assert_hidden(visual, layer_name, "%s legacy layer" % layer_name)
		_assert_white_title(visual, color_id)
		card_scene.queue_free()
		await process_frame


func _check_atomic_style_fallback(file_loader: Node) -> void:
	var card_scene := await _render_style_card({
		"color_id": "color_red",
		"type_id": CARD_TYPE_ATTACK,
	})
	if card_scene == null:
		return
	if not card_scene.has_method("_try_apply_full_card_master"):
		failures.append("Card must validate the master and type textures before enabling the full-card style")
		card_scene.queue_free()
		await process_frame
		return

	card_scene.call("_apply_card_palette", null, "color_red")
	var applied := bool(card_scene.call(
		"_try_apply_full_card_master",
		MASTER_SLOT_BY_ID["color_red"],
		"external/sprites/ui/card_styles/full_master/ribbons/missing.png"
	))
	if applied:
		failures.append("full-card style must not activate when the type ribbon is missing")

	var visual := card_scene.get_node("Pivot/CardVisual") as Control
	_assert_hidden(visual, "CardChrome", "failed full-card master")
	_assert_visible(visual, "ColorBackground", "fallback outer frame")
	var art := _find_descendant(visual, "CardTexture") as Control
	var art_frame := _find_descendant(visual, "CardArtFrame") as Control
	if art == null or art_frame == null:
		failures.append("fallback art nodes must exist")
	elif art.get_index() >= art_frame.get_index():
		failures.append("fallback artwork must render below the legacy art frame")
	elif not art_frame.get_global_rect().encloses(art.get_global_rect()):
		failures.append("fallback artwork must remain inside the legacy art frame")

	card_scene.queue_free()
	await process_frame


func _check_transparent_edge_contamination(style_data: Dictionary) -> void:
	var paths: Array[String] = []
	var master_slots := style_data.get("master_slots", {}) as Dictionary
	for color_id: String in ["color_red", "color_blue", "color_orange", "color_white"]:
		paths.append(str(master_slots.get(color_id, "")))
	var type_slots := style_data.get("type_slots", {}) as Dictionary
	for type_id: String in ["0", "2", "3", "4"]:
		paths.append(str(type_slots.get(type_id, "")))

	for path: String in paths:
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://" + path))
		if image == null or image.is_empty():
			continue
		image.convert(Image.FORMAT_RGBA8)
		var contaminated_pixels := 0
		for y in image.get_height():
			for x in image.get_width():
				var color := image.get_pixel(x, y)
				if (color.a > 0.01 and color.a < 0.99
						and color.g > 0.40
						and color.g - maxf(color.r, color.b) > 0.24):
					contaminated_pixels += 1
		if contaminated_pixels > 0:
			failures.append("%s contains %d semi-transparent chroma-green edge pixels" % [path, contaminated_pixels])


func _render_style_card(case_data: Dictionary) -> Node:
	var card_data_script := load(CARD_DATA_SCRIPT_PATH) as Script
	var packed_scene := load(CARD_SCENE_PATH) as PackedScene
	if card_data_script == null or not card_data_script.can_instantiate() or packed_scene == null:
		failures.append("card style preview must load CardData and Card scene")
		return null

	var data = card_data_script.new()
	data.card_name = "参考样式卡牌"
	data.card_description = "验证参考资源卡框与类型条。"
	data.card_color_id = case_data["color_id"]
	data.card_type = case_data["type_id"]
	data.card_energy_cost = 1
	data.card_requires_target = false
	data.card_texture_path = ""

	var card_scene := packed_scene.instantiate()
	root.add_child(card_scene)
	card_scene.call("init", data, 0.0, false, false)
	await process_frame
	await process_frame
	return card_scene


func _assert_panel_texture(visual: Control, panel_name: String, expected_path: String, label: String) -> void:
	var panel := _find_descendant(visual, panel_name) as Panel
	if panel == null:
		failures.append("%s panel must exist" % label)
		return
	var stylebox := panel.get_theme_stylebox("panel")
	if not stylebox is StyleBoxTexture:
		failures.append("%s must use a reference StyleBoxTexture" % label)
		return
	var texture := (stylebox as StyleBoxTexture).texture
	if texture == null or texture.resource_path != expected_path:
		failures.append("%s must use %s" % [label, expected_path])


func _assert_texture_rect(visual: Control, node_name: String, expected_path: String, label: String) -> void:
	var texture_rect := _find_descendant(visual, node_name) as TextureRect
	if texture_rect == null:
		failures.append("%s TextureRect must exist" % label)
		return
	if texture_rect.texture == null or texture_rect.texture.resource_path != expected_path:
		failures.append("%s must use %s" % [label, expected_path])


func _assert_master_layer_order(visual: Control, color_id: String) -> void:
	var art := _find_descendant(visual, "CardTexture") as Control
	var chrome := _find_descendant(visual, "CardChrome") as Control
	var type_ribbon := _find_descendant(visual, "CardTypeBackground") as Control
	var title := _find_descendant(visual, "CardName") as Control
	var description := _find_descendant(visual, "CardDescription") as Control
	var energy := _find_descendant(visual, "EnergyCost") as Control
	for node: Control in [art, chrome, type_ribbon, title, description, energy]:
		if node == null:
			failures.append("%s full-card stack is missing a dynamic layer" % color_id)
			return
		if node.get_parent() != visual:
			failures.append("%s full-card stack layers must be direct CardVisual children" % color_id)
			return
	if not (art.get_index() < chrome.get_index()
			and chrome.get_index() < title.get_index()
			and chrome.get_index() < description.get_index()
			and chrome.get_index() < energy.get_index()):
		failures.append("%s layer order must be art, full-card master, then dynamic content" % color_id)
	if type_ribbon.z_index <= chrome.z_index and type_ribbon.get_index() <= chrome.get_index():
		failures.append("%s type ribbon must render above the full-card master" % color_id)


func _assert_hidden(visual: Control, node_name: String, label: String) -> void:
	var node := _find_descendant(visual, node_name) as CanvasItem
	if node == null:
		failures.append("%s must remain as a fallback node" % label)
		return
	if node.visible:
		failures.append("%s must be hidden while the full-card master is active" % label)


func _assert_visible(visual: Control, node_name: String, label: String) -> void:
	var node := _find_descendant(visual, node_name) as CanvasItem
	if node == null:
		failures.append("%s must exist" % label)
		return
	if not node.visible:
		failures.append("%s must remain visible" % label)


func _assert_white_title(visual: Control, color_id: String) -> void:
	var title := _find_descendant(visual, "CardName") as RichTextLabel
	if title == null:
		failures.append("%s title must exist" % color_id)
		return
	if title.get_theme_color("default_color") != Color.WHITE:
		failures.append("%s title must use white text over the dark header" % color_id)


func _find_descendant(node: Node, descendant_name: String) -> Node:
	if node.name == descendant_name:
		return node
	for child in node.get_children():
		var result := _find_descendant(child, descendant_name)
		if result != null:
			return result
	return null

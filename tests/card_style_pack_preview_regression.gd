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

const REQUIRED_SHARED_SLOTS := [
	"header_bar",
	"art_frame",
	"description_panel",
	"energy_badge",
	"glow",
]

const COLOR_SLOT_BY_ID := {
	"color_red": "external/sprites/ui/card_styles/preview/frames/frame_red.png",
	"color_blue": "external/sprites/ui/card_styles/preview/frames/frame_blue.png",
	"color_green": "external/sprites/ui/card_styles/preview/frames/frame_green.png",
	"color_orange": "external/sprites/ui/card_styles/preview/frames/frame_gold.png",
	"color_white": "external/sprites/ui/card_styles/preview/frames/frame_silver.png",
}

const TYPE_SLOT_BY_ID := {
	CARD_TYPE_ATTACK: "external/sprites/ui/card_styles/preview/ribbons/ribbon_attack.png",
	CARD_TYPE_SKILL: "external/sprites/ui/card_styles/preview/ribbons/ribbon_skill.png",
	CARD_TYPE_POWER: "external/sprites/ui/card_styles/preview/ribbons/ribbon_power.png",
	CARD_TYPE_STATUS: "external/sprites/ui/card_styles/preview/ribbons/ribbon_status.png",
	CARD_TYPE_CURSE: "external/sprites/ui/card_styles/preview/ribbons/ribbon_curse.png",
}

const SHARED_PANEL_TO_SLOT := {
	"CardHeaderBackground": "header_bar",
	"CardArtFrame": "art_frame",
	"CardDescriptionBackground": "description_panel",
	"EnergySprite": "energy_badge",
	"CardGlow": "glow",
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var file_loader := root.get_node("FileLoader")
	var style_data := _check_style_pack(file_loader)
	if not style_data.is_empty():
		await _check_runtime_style_variants(style_data, file_loader)

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

	_check_slot_group(style_data, "shared_slots", REQUIRED_SHARED_SLOTS, file_loader)
	_check_slot_group(style_data, "color_slots", COLOR_SLOT_BY_ID.keys(), file_loader)
	_check_slot_group(style_data, "type_slots", TYPE_SLOT_BY_ID.keys(), file_loader)
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
		_assert_panel_texture(
			visual,
			"ColorBackground",
			str(file_loader.call("_get_modified_filepath", COLOR_SLOT_BY_ID[color_id])),
			"%s color frame" % color_id
		)
		_assert_panel_texture(
			visual,
			"CardTypeBackground",
			str(file_loader.call("_get_modified_filepath", TYPE_SLOT_BY_ID[type_id])),
			"%s type ribbon" % type_id
		)
		for panel_name: String in SHARED_PANEL_TO_SLOT:
			_assert_panel_texture(
				visual,
				panel_name,
				_resolve_texture_path(file_loader, style_data.get("shared_slots", {}), SHARED_PANEL_TO_SLOT[panel_name]),
				"%s shared layer" % panel_name
			)
		_assert_white_title(visual, color_id)
		card_scene.queue_free()
		await process_frame


func _resolve_texture_path(file_loader: Node, slots: Variant, slot_name: String) -> String:
	if not slots is Dictionary:
		return ""
	return str(file_loader.call("_get_modified_filepath", str((slots as Dictionary).get(slot_name, ""))))


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

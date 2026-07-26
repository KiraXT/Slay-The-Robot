extends SceneTree

const CARD_SCENE_PATH := "res://scenes/ui/Card.tscn"
const CARD_DATA_SCRIPT_PATH := "res://data/prototype/CardData.gd"
const CARD_SHOP_SCENE_PATH := "res://scenes/ui/shop/CardShopButton.tscn"

# Mirrors CardData.CARD_TYPES order from data/prototype/CardData.gd.
# Direct static references make this script fail before the direct runner initializes global classes.
const CARD_TYPE_ATTACK := 0
const CARD_TYPE_SKILL := 1
const CARD_TYPE_POWER := 2
const CARD_TYPE_STATUS := 3
const CARD_TYPE_CURSE := 4

# Mirrors CardData.CARD_RARITIES order from data/prototype/CardData.gd.
const CARD_RARITY_BASIC := 0
const CARD_RARITY_COMMON := 1
const CARD_RARITY_UNCOMMON := 2
const CARD_RARITY_RARE := 3
const CARD_RARITY_GENERATED := 4

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_visual_mappings()
	await _check_layout_bounds()
	await _check_card_detail_treatment()
	await _check_energy_text_sizing()
	await _check_white_card_neutral_frame()
	await _check_b_mech_template_layout()
	await _check_card_shop_layout()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_visual_mappings() -> void:
	var cases := [
		{
			"name": "red basic attack",
			"color_id": "color_red",
			"type": CARD_TYPE_ATTACK,
			"rarity": CARD_RARITY_BASIC,
			"faction": "拳",
			"stars": "★",
			"type_label": "攻击",
			"energy": "1",
		},
		{
			"name": "green common skill",
			"color_id": "color_green",
			"type": CARD_TYPE_SKILL,
			"rarity": CARD_RARITY_COMMON,
			"faction": "藤",
			"stars": "★★",
			"type_label": "技能",
			"energy": "2",
		},
		{
			"name": "blue uncommon power",
			"color_id": "color_blue",
			"type": CARD_TYPE_POWER,
			"rarity": CARD_RARITY_UNCOMMON,
			"faction": "流",
			"stars": "★★★",
			"type_label": "能力",
			"energy": "X",
		},
		{
			"name": "orange rare status",
			"color_id": "color_orange",
			"type": CARD_TYPE_STATUS,
			"rarity": CARD_RARITY_RARE,
			"faction": "械",
			"stars": "★★★★",
			"type_label": "状态",
			"energy": "3",
		},
		{
			"name": "purple generated curse",
			"color_id": "color_purple",
			"type": CARD_TYPE_CURSE,
			"rarity": CARD_RARITY_GENERATED,
			"faction": "蚀",
			"stars": "",
			"type_label": "诅咒",
			"energy": "0",
		},
	]

	for case_data in cases:
		var card := await _render_card(case_data)
		if card == null:
			failures.append("%s failed to render card" % case_data["name"])
			continue

		var visual := card.get_node("Pivot/CardVisual") as Control
		_assert_label(_find_descendant(visual, "CardStars"), case_data["stars"], "%s stars" % case_data["name"])
		_assert_label(_find_descendant(visual, "CardType"), case_data["type_label"], "%s type" % case_data["name"])
		_assert_label(_find_descendant(visual, "EnergyCost"), case_data["energy"], "%s energy" % case_data["name"])
		card.queue_free()
		await process_frame


func _check_layout_bounds() -> void:
	var card := await _render_card({
		"name": "long text",
		"color_id": "color_white",
		"type": CARD_TYPE_SKILL,
		"rarity": CARD_RARITY_RARE,
		"energy": "1",
	})
	if card == null:
		failures.append("long text failed to render card")
		return

	var visual := card.get_node("Pivot/CardVisual") as Control
	for node_name in [
		"CardChrome",
		"CardName",
		"CardTexture",
		"CardTypeBackground",
		"CardDescription",
		"CardStars",
	]:
		_assert_rect_inside(visual, _find_descendant(visual, node_name) as Control, node_name)

	_assert_vertical_non_overlap(visual, "CardDescription", "CardTypeBackground")
	_assert_vertical_non_overlap(visual, "CardDescription", "CardStars")
	_assert_vertical_non_overlap(visual, "CardName", "CardTexture")

	card.queue_free()
	await process_frame


func _check_card_detail_treatment() -> void:
	var card := await _render_card({
		"name": "detail treatment",
		"color_id": "color_red",
		"type": CARD_TYPE_ATTACK,
		"rarity": CARD_RARITY_UNCOMMON,
		"energy": "2",
	})
	if card == null:
		failures.append("detail treatment failed to render card")
		return

	var visual := card.get_node("Pivot/CardVisual") as Control
	_assert_texture_rect_visible(visual, "CardChrome", "full-card master")
	_assert_texture_rect_visible(visual, "CardTypeBackground", "type ribbon")
	_assert_hidden_descendant(visual, "ColorBackground", "legacy outer frame")
	_assert_hidden_descendant(visual, "CardHeaderBackground", "legacy title header")
	_assert_hidden_descendant(visual, "CardArtFrame", "legacy art frame")
	_assert_hidden_descendant(visual, "CardDescriptionBackground", "legacy description panel")
	_assert_dynamic_layer_above_master(visual, "CardName")
	_assert_dynamic_layer_above_master(visual, "CardDescription")
	_assert_dynamic_layer_above_master(visual, "EnergyCost")
	_assert_exact_rect(visual, "CardName", Rect2(34.0, 8.0, 90.0, 24.0), "card name")
	_assert_exact_rect(visual, "EnergyCost", Rect2(4.0, 1.0, 38.0, 38.0), "energy cost")
	_assert_centered_label(visual, "EnergyCost", "energy cost")
	_assert_emboldened_font(visual, "EnergyCost", "font", 0.8, "energy cost")
	_assert_emboldened_font(visual, "CardName", "normal_font", 0.65, "card name")
	_assert_rich_text_vertical_center(visual, "CardName", "card name")

	card.queue_free()
	await process_frame


func _check_energy_text_sizing() -> void:
	var short_card := await _render_card({
		"name": "short energy",
		"color_id": "color_blue",
		"type": CARD_TYPE_SKILL,
		"rarity": CARD_RARITY_COMMON,
		"energy": "2",
	})
	if short_card == null:
		failures.append("short energy failed to render card")
		return
	_assert_label_font_size(short_card, "EnergyCost", 19, "short energy")
	short_card.queue_free()
	await process_frame

	var long_card := await _render_card({
		"name": "long energy",
		"color_id": "color_blue",
		"type": CARD_TYPE_SKILL,
		"rarity": CARD_RARITY_COMMON,
		"energy": "X-12",
		"variable_upper_bound": 12,
	})
	if long_card == null:
		failures.append("long energy failed to render card")
		return
	_assert_label(_find_descendant(long_card, "EnergyCost"), "X-12", "long energy")
	_assert_label_font_size(long_card, "EnergyCost", 14, "long energy")
	long_card.queue_free()
	await process_frame


func _check_white_card_neutral_frame() -> void:
	var card := await _render_card({
		"name": "white neutral frame",
		"color_id": "color_white",
		"type": CARD_TYPE_SKILL,
		"rarity": CARD_RARITY_RARE,
		"energy": "1",
	})
	if card == null:
		failures.append("white neutral frame failed to render card")
		return

	var visual := card.get_node("Pivot/CardVisual") as Control
	var chrome := _find_descendant(visual, "CardChrome") as TextureRect
	if chrome == null or chrome.texture == null:
		failures.append("white card must use a full-card master")
	elif not chrome.texture.resource_path.ends_with("card_master_silver.png"):
		failures.append("white card must use the silver full-card master")

	card.queue_free()
	await process_frame


func _check_b_mech_template_layout() -> void:
	var card := await _render_card({
		"name": "b mech layout",
		"color_id": "color_red",
		"type": CARD_TYPE_ATTACK,
		"rarity": CARD_RARITY_RARE,
		"energy": "2",
	})
	if card == null:
		failures.append("b mech layout failed to render card")
		return

	var visual := card.get_node("Pivot/CardVisual") as Control
	_assert_rect_height_at_least(visual, "CardVisual", 202.0, "tall card visual")
	_assert_rect_top_at_most(visual, "CardName", 12.0, "card name")
	_assert_rect_top_at_most(visual, "CardTexture", 38.0, "card artwork")
	_assert_rect_height_at_least(visual, "CardTexture", 88.0, "large card artwork")
	_assert_rect_top_at_most(visual, "CardTypeBackground", 122.0, "card type ribbon")
	_assert_rect_width_at_most(visual, "CardTypeBackground", 65.0, "short card type ribbon")
	_assert_rect_top_at_most(visual, "CardDescription", 142.0, "effect text")
	_assert_label_font_size_at_most(visual, "CardStars", 10, "card stars")
	_assert_pivot_animation_center(card, Vector2(72.0, 101.0))

	card.queue_free()
	await process_frame


func _check_card_shop_layout() -> void:
	var packed_scene := load(CARD_SHOP_SCENE_PATH) as PackedScene
	if packed_scene == null:
		failures.append("failed to load card shop scene %s" % CARD_SHOP_SCENE_PATH)
		return
	var shop_button := packed_scene.instantiate() as Control
	root.add_child(shop_button)
	await process_frame

	var card := shop_button.get_node_or_null("Card") as Control
	var price := shop_button.get_node_or_null("PriceLabel") as Control
	if card == null or price == null:
		failures.append("card shop must contain Card and PriceLabel controls")
	else:
		if card.get_global_rect().intersects(price.get_global_rect()):
			failures.append("card shop price must not overlap the 202px card")
		if not shop_button.get_global_rect().encloses(price.get_global_rect()):
			failures.append("card shop price must remain inside the shop button")

	shop_button.queue_free()
	await process_frame


func _render_card(case_data: Dictionary) -> Node:
	var card_data_script := load(CARD_DATA_SCRIPT_PATH) as Script
	if card_data_script == null or not card_data_script.can_instantiate():
		failures.append("failed to load CardData script %s" % CARD_DATA_SCRIPT_PATH)
		return null

	var packed_scene := load(CARD_SCENE_PATH) as PackedScene
	if packed_scene == null:
		failures.append("failed to load card scene %s" % CARD_SCENE_PATH)
		return null

	var data = card_data_script.new()
	data.card_name = "超长卡名测试用例"
	data.card_description = "这是一段很长的中文描述，用于确认效果文本区域不会覆盖类型条、星级条或卡牌边框。"
	data.card_color_id = case_data["color_id"]
	data.card_type = case_data["type"]
	data.card_rarity = case_data["rarity"]
	data.card_energy_cost = int(case_data.get("energy", "1")) if str(case_data.get("energy", "1")).is_valid_int() else 1
	data.card_energy_cost_is_variable = str(case_data.get("energy", "")).begins_with("X")
	data.card_energy_cost_variable_upper_bound = int(case_data.get("variable_upper_bound", 0))
	data.card_requires_target = false
	data.card_texture_path = ""

	var card := packed_scene.instantiate()
	if card == null:
		failures.append("failed to instantiate card scene %s" % CARD_SCENE_PATH)
		return null

	root.add_child(card)
	card.init(data, 0.0, false, false)
	await process_frame
	await process_frame
	return card


func _assert_label(node: Node, expected: String, label: String) -> void:
	if node == null:
		failures.append("%s missing node" % label)
		return

	var label_node := node as Label
	if label_node == null:
		failures.append("%s node %s is not a Label" % [label, node.get_path()])
		return

	if label_node.text != expected:
		failures.append("%s expected `%s`, got `%s`" % [label, expected, label_node.text])


func _assert_rect_inside(parent: Control, child: Control, label: String) -> void:
	if parent == null:
		failures.append("%s parent is missing" % label)
		return

	if child == null:
		failures.append("%s is missing" % label)
		return

	var parent_rect := parent.get_global_rect()
	var child_rect := child.get_global_rect()
	if child_rect.position.x < parent_rect.position.x or child_rect.position.y < parent_rect.position.y:
		failures.append("%s starts outside card: %s" % [label, child_rect])
		return

	if child_rect.end.x > parent_rect.end.x:
		failures.append("%s exceeds card width: %s" % [label, child_rect])

	if child_rect.end.y > parent_rect.end.y:
		failures.append("%s exceeds card height: %s" % [label, child_rect])


func _assert_control_inside(parent: Control, child: Control, label: String) -> void:
	if parent == null:
		failures.append("%s parent is missing" % label)
		return
	if child == null:
		failures.append("%s is missing" % label)
		return
	var parent_rect := parent.get_global_rect()
	var child_rect := child.get_global_rect()
	if child_rect.position.x < parent_rect.position.x or child_rect.position.y < parent_rect.position.y:
		failures.append("%s starts outside parent: %s" % [label, child_rect])
	if child_rect.end.x > parent_rect.end.x or child_rect.end.y > parent_rect.end.y:
		failures.append("%s exceeds parent: %s" % [label, child_rect])


func _assert_no_visible_descendant(parent: Node, node_name: String, label: String) -> void:
	var node := _find_descendant(parent, node_name)
	if node == null:
		return
	var canvas_item := node as CanvasItem
	if canvas_item != null and canvas_item.visible:
		failures.append("%s should not be visible" % label)


func _assert_rect_top_at_most(parent: Control, node_name: String, max_top: float, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Control
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return
	var local_top := node.get_global_rect().position.y - parent.get_global_rect().position.y
	if local_top > max_top:
		failures.append("%s top expected <= %.1f, got %.1f" % [label, max_top, local_top])


func _assert_rect_height_at_least(parent: Control, node_name: String, min_height: float, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Control
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return
	var height := node.get_global_rect().size.y
	if height < min_height:
		failures.append("%s height expected >= %.1f, got %.1f" % [label, min_height, height])


func _assert_texture_rect_visible(parent: Control, node_name: String, label: String) -> void:
	var node := _find_descendant(parent, node_name) as TextureRect
	if node == null:
		failures.append("%s missing TextureRect %s" % [label, node_name])
		return
	if not node.visible or node.texture == null:
		failures.append("%s must be visible with a texture" % label)


func _assert_hidden_descendant(parent: Control, node_name: String, label: String) -> void:
	var node := _find_descendant(parent, node_name) as CanvasItem
	if node == null:
		failures.append("%s missing fallback node %s" % [label, node_name])
		return
	if node.visible:
		failures.append("%s must be hidden by the full-card master" % label)


func _assert_dynamic_layer_above_master(parent: Control, node_name: String) -> void:
	var chrome := _find_descendant(parent, "CardChrome") as Control
	var dynamic_node := _find_descendant(parent, node_name) as Control
	if chrome == null or dynamic_node == null:
		failures.append("%s layer-order nodes are missing" % node_name)
		return
	if chrome.get_parent() != parent or dynamic_node.get_parent() != parent:
		failures.append("%s and CardChrome must be direct CardVisual children" % node_name)
		return
	if dynamic_node.get_index() <= chrome.get_index():
		failures.append("%s must render above CardChrome" % node_name)


func _assert_pivot_animation_center(card: Node, expected_center: Vector2) -> void:
	var animation_player := card.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		failures.append("card animation player is missing")
		return
	for animation_name: StringName in [&"RESET", &"card_hover"]:
		var animation := animation_player.get_animation(animation_name)
		if animation == null:
			failures.append("%s animation is missing" % animation_name)
			continue
		var track := animation.find_track(NodePath("Pivot:position"), Animation.TYPE_VALUE)
		if track < 0 or animation.track_get_key_count(track) == 0:
			failures.append("%s must animate Pivot:position" % animation_name)
			continue
		var start_position := animation.track_get_key_value(track, 0) as Vector2
		if not start_position.is_equal_approx(expected_center):
			failures.append("%s must start from card center %s, got %s" % [animation_name, expected_center, start_position])


func _assert_rect_width_at_most(parent: Control, node_name: String, max_width: float, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Control
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return
	var width := node.get_global_rect().size.x
	if width > max_width:
		failures.append("%s width expected <= %.1f, got %.1f" % [label, max_width, width])


func _assert_label_font_size_at_most(parent: Node, node_name: String, max_size: int, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Label
	if node == null:
		failures.append("%s missing label %s" % [label, node_name])
		return
	var font_size := node.get_theme_font_size("font_size")
	if font_size > max_size:
		failures.append("%s font size expected <= %d, got %d" % [label, max_size, font_size])


func _assert_label_font_size(parent: Node, node_name: String, expected_size: int, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Label
	if node == null:
		failures.append("%s missing label %s" % [label, node_name])
		return
	var font_size := node.get_theme_font_size("font_size")
	if font_size != expected_size:
		failures.append("%s font size expected %d, got %d" % [label, expected_size, font_size])


func _assert_exact_rect(parent: Control, node_name: String, expected_rect: Rect2, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Control
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return
	var actual_rect := Rect2(node.position, node.size)
	if not actual_rect.is_equal_approx(expected_rect):
		failures.append("%s rect expected %s, got %s" % [label, expected_rect, actual_rect])


func _assert_centered_label(parent: Node, node_name: String, label: String) -> void:
	var node := _find_descendant(parent, node_name) as Label
	if node == null:
		failures.append("%s missing label %s" % [label, node_name])
		return
	if node.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		failures.append("%s must be horizontally centered" % label)
	if node.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		failures.append("%s must be vertically centered" % label)


func _assert_emboldened_font(
	parent: Node,
	node_name: String,
	theme_key: String,
	expected_embolden: float,
	label: String
) -> void:
	var node := _find_descendant(parent, node_name) as Control
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return
	var font := node.get_theme_font(theme_key)
	if not font is FontVariation:
		failures.append("%s must use a FontVariation" % label)
		return
	var actual_embolden := (font as FontVariation).variation_embolden
	if not is_equal_approx(actual_embolden, expected_embolden):
		failures.append(
			"%s embolden expected %.2f, got %.2f" % [label, expected_embolden, actual_embolden]
		)


func _assert_rich_text_vertical_center(parent: Node, node_name: String, label: String) -> void:
	var node := _find_descendant(parent, node_name) as RichTextLabel
	if node == null:
		failures.append("%s missing RichTextLabel %s" % [label, node_name])
		return
	if node.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		failures.append("%s must be vertically centered" % label)


func _assert_vertical_non_overlap(parent: Control, first_name: String, second_name: String) -> void:
	var first := _find_descendant(parent, first_name) as Control
	var second := _find_descendant(parent, second_name) as Control
	if first == null or second == null:
		return

	var first_rect := first.get_global_rect()
	var second_rect := second.get_global_rect()
	if first_rect.position.y < second_rect.end.y and second_rect.position.y < first_rect.end.y:
		failures.append("%s overlaps %s: %s vs %s" % [first_name, second_name, first_rect, second_rect])


func _assert_panel_style(parent: Node, node_name: String, min_corner_radius: int, min_border_width: int, label: String) -> void:
	var node := _find_descendant(parent, node_name)
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return

	var panel := node as Panel
	if panel == null:
		failures.append("%s node %s is not a Panel" % [label, node.get_path()])
		return

	var panel_style := panel.get_theme_stylebox("panel")
	if panel_style is StyleBoxTexture:
		var texture_style := panel_style as StyleBoxTexture
		if texture_style.texture == null:
			failures.append("%s node %s has a StyleBoxTexture without texture" % [label, panel.get_path()])
		return

	var style := panel_style as StyleBoxFlat
	if style == null:
		failures.append("%s node %s has no StyleBoxFlat or StyleBoxTexture panel style" % [label, panel.get_path()])
		return

	for corner_radius in [
		style.corner_radius_top_left,
		style.corner_radius_top_right,
		style.corner_radius_bottom_left,
		style.corner_radius_bottom_right,
	]:
		if corner_radius < min_corner_radius:
			failures.append("%s corner radius expected at least %d, got %d" % [label, min_corner_radius, corner_radius])
			return

	for border_width in [
		style.border_width_left,
		style.border_width_top,
		style.border_width_right,
		style.border_width_bottom,
	]:
		if border_width < min_border_width:
			failures.append("%s border width expected at least %d, got %d" % [label, min_border_width, border_width])
			return


func _assert_panel_bg_luminance_below(parent: Node, node_name: String, max_luminance: float, label: String) -> void:
	var style := _get_panel_style(parent, node_name, label)
	if style == null:
		return
	if style.bg_color.get_luminance() > max_luminance:
		failures.append("%s background luminance expected <= %.2f, got %.2f" % [label, max_luminance, style.bg_color.get_luminance()])


func _assert_panel_border_luminance_below(parent: Node, node_name: String, max_luminance: float, label: String) -> void:
	var style := _get_panel_style(parent, node_name, label)
	if style == null:
		return
	if style.border_color.get_luminance() > max_luminance:
		failures.append("%s border luminance expected <= %.2f, got %.2f" % [label, max_luminance, style.border_color.get_luminance()])


func _get_panel_style(parent: Node, node_name: String, label: String) -> StyleBoxFlat:
	var node := _find_descendant(parent, node_name)
	if node == null:
		failures.append("%s missing node %s" % [label, node_name])
		return null

	var panel := node as Panel
	if panel == null:
		failures.append("%s node %s is not a Panel" % [label, node.get_path()])
		return null

	var panel_style := panel.get_theme_stylebox("panel")
	if panel_style is StyleBoxTexture:
		return null

	var style := panel_style as StyleBoxFlat
	if style == null:
		failures.append("%s node %s has no StyleBoxFlat or StyleBoxTexture panel style" % [label, panel.get_path()])
	return style


func _find_descendant(parent: Node, node_name: String) -> Node:
	if parent == null:
		return null

	var unique_node := parent.get_node_or_null("%%%s" % node_name)
	if unique_node != null:
		return unique_node

	return _find_descendant_recursive(parent, node_name)


func _find_descendant_recursive(parent: Node, node_name: String) -> Node:
	if parent.name == node_name:
		return parent

	for child in parent.get_children():
		var found := _find_descendant_recursive(child, node_name)
		if found != null:
			return found

	return null

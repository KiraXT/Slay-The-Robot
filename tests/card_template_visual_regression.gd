extends SceneTree

const CARD_SCENE_PATH := "res://scenes/ui/Card.tscn"
const CARD_DATA_SCRIPT_PATH := "res://data/prototype/CardData.gd"

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
		_assert_label(_find_descendant(visual, "CardFactionText"), case_data["faction"], "%s faction" % case_data["name"])
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
		"CardName",
		"CardTexture",
		"CardTypeBackground",
		"CardDescription",
		"CardStars",
		"CardFaction",
	]:
		_assert_rect_inside(visual, _find_descendant(visual, node_name) as Control, node_name)

	_assert_vertical_non_overlap(visual, "CardDescription", "CardTypeBackground")
	_assert_vertical_non_overlap(visual, "CardDescription", "CardStars")

	card.queue_free()
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
	data.card_energy_cost_is_variable = case_data.get("energy", "") == "X"
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


func _assert_vertical_non_overlap(parent: Control, first_name: String, second_name: String) -> void:
	var first := _find_descendant(parent, first_name) as Control
	var second := _find_descendant(parent, second_name) as Control
	if first == null or second == null:
		return

	var first_rect := first.get_global_rect()
	var second_rect := second.get_global_rect()
	if first_rect.position.y < second_rect.end.y and second_rect.position.y < first_rect.end.y:
		failures.append("%s overlaps %s: %s vs %s" % [first_name, second_name, first_rect, second_rect])


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

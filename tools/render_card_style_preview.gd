extends SceneTree

const PREVIEW_PATH := "tmp/card_style_preview/card_style_full_master_runtime.png"
const CARD_SCENE_PATH := "res://scenes/ui/Card.tscn"
const CARD_DATA_SCRIPT_PATH := "res://data/prototype/CardData.gd"
const CARD_SCALE := 1.35
const PREVIEW_CASES := [
	{
		"color": "color_red",
		"type": 0,
		"rarity": 2,
		"energy": 2,
		"name": "烈焰冲击",
		"description": "对敌人造成 10 点伤害。",
		"art": "external/sprites/cards/card_attack_big.png",
	},
	{
		"color": "color_blue",
		"type": 1,
		"rarity": 1,
		"energy": 1,
		"name": "误打误撞",
		"description": "随机打出弃牌堆中的 1 张牌。",
		"art": "external/sprites/cards/blue/randomize_hand_card.png",
	},
	{
		"color": "color_green",
		"type": 2,
		"rarity": 3,
		"energy": 2,
		"name": "生长核心",
		"description": "本回合获得额外力量。",
		"art": "external/sprites/cards/green/card_chorus.png",
	},
	{
		"color": "color_orange",
		"type": 3,
		"rarity": 0,
		"energy": 0,
		"name": "整备姿态",
		"description": "保留手牌并获得格挡。",
		"art": "external/sprites/cards/orange/card_ready_stance.png",
	},
	{
		"color": "color_white",
		"type": 4,
		"rarity": 2,
		"energy": 3,
		"name": "禁忌回响",
		"description": "触发上一张卡牌的效果。",
		"art": "external/sprites/cards/card_draft_random_attack.png",
	},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var card_scene := load(CARD_SCENE_PATH) as PackedScene
	var card_data_script := load(CARD_DATA_SCRIPT_PATH) as Script
	if card_scene == null or card_data_script == null or not card_data_script.can_instantiate():
		push_error("Unable to load runtime card preview dependencies")
		quit(1)
		return

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1100, 350)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var background := ColorRect.new()
	background.size = Vector2(viewport.size)
	background.color = Color(0.12, 0.15, 0.18, 1.0)
	viewport.add_child(background)

	for index in PREVIEW_CASES.size():
		var case_data: Dictionary = PREVIEW_CASES[index]
		var data = card_data_script.new()
		data.card_name = case_data["name"]
		data.card_description = case_data["description"]
		data.card_color_id = case_data["color"]
		data.card_type = case_data["type"]
		data.card_rarity = case_data["rarity"]
		data.card_energy_cost = case_data["energy"]
		data.card_requires_target = false
		data.card_texture_path = case_data["art"]

		var card := card_scene.instantiate()
		viewport.add_child(card)
		card.position = Vector2(20.0 + index * 215.0, 38.0)
		card.scale = Vector2.ONE * CARD_SCALE
		card.call("init", data, 0.0, false, false)

	await process_frame
	await process_frame
	await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/card_style_preview"))
	var image := viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("res://" + PREVIEW_PATH))
	if error != OK:
		push_error("Failed to save runtime card preview: %s" % error)
		quit(1)
		return
	print("CARD_STYLE_FULL_MASTER_PREVIEW_RENDERED: %s" % PREVIEW_PATH)
	quit(0)

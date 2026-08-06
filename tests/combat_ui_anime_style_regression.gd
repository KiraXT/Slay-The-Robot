extends SceneTree

const ROOT_SCENE_PATH := "res://scenes/Root.tscn"
const ENEMY_SCENE_PATH := "res://scenes/combatants/Enemy.tscn"
const HUD_BADGE_SCRIPT := "res://scripts/ui/CombatHudBadge.gd"
const INTENT_ICON_SCRIPT := "res://scripts/ui/IntentAttackIcon.gd"

const COMBAT_BADGE_BUTTONS := {
	"PauseButton": "pause",
	"MapButton": "map",
	"DeckButton": "deck",
	"Energy": "energy",
	"DrawPile": "draw",
	"DiscardPile": "discard",
	"ExhaustPile": "exhaust",
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_enemy_intent_badge()
	await _check_combat_hud_badges()
	await _check_consumable_button_badge()
	await _check_combat_card_pick_prompt_panel()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_enemy_intent_badge() -> void:
	var enemy_scene: Node = load(ENEMY_SCENE_PATH).instantiate()
	root.add_child(enemy_scene)
	await process_frame

	var intent := enemy_scene.get_node("Visible/Intent") as Control
	var rect := Rect2(intent.offset_left, intent.offset_top, intent.offset_right - intent.offset_left, intent.offset_bottom - intent.offset_top)
	if rect.size.x > 90.0 or rect.size.y > 44.0:
		failures.append("enemy intent must stay compact when it has no background")

	var panel := enemy_scene.get_node("Visible/Intent/BadgePanel") as Panel
	if panel.visible:
		failures.append("enemy intent must not render a background panel")

	var icon := enemy_scene.get_node("Visible/Intent/IntentTexture") as Control
	if icon == null:
		failures.append("enemy intent icon node must exist")
	elif icon.get_script() == null or icon.get_script().resource_path != INTENT_ICON_SCRIPT:
		failures.append("enemy intent must use the custom attack icon instead of the old flipper texture")
	else:
		if icon.size.x < 34.0 or icon.size.y < 34.0:
			failures.append("enemy intent attack icon must be large enough to read without a background")
		if str(icon.get("icon_style_id")) != "single_strike":
			failures.append("enemy intent attack icon must use the bold single-strike design")

	var amount := enemy_scene.get_node("Visible/Intent/IntentAmount") as Label
	var amount_font_size := amount.get_theme_font_size("font_size")
	if amount_font_size < 26 or amount_font_size > 30:
		failures.append("enemy intent amount must be readable but compact")
	if not amount.has_theme_color_override("font_color"):
		failures.append("enemy intent amount must override font color for background-free readability")
	elif amount.get_theme_color("font_color").r > 0.30:
		failures.append("enemy intent amount must use dark text over the bright combat background")
	if amount.get_theme_constant("outline_size") < 4:
		failures.append("enemy intent amount needs a bright outline over mixed backgrounds")

	if not enemy_scene.has_method("_format_attack_intent_text"):
		failures.append("Enemy must expose _format_attack_intent_text for compact multi-hit intent text")
	else:
		if enemy_scene.call("_format_attack_intent_text", 3, 2) != "3x2":
			failures.append("multi-hit intent text must be compact, e.g. 3x2")
		if enemy_scene.call("_format_attack_intent_text", 7, 1) != "7":
			failures.append("single-hit intent text must stay as the damage number")

	enemy_scene.queue_free()
	await process_frame


func _check_combat_hud_badges() -> void:
	var root_scene: Node = load(ROOT_SCENE_PATH).instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var combat := root_scene.get_node("RunScreen/Combat") as Control
	for button_name: String in COMBAT_BADGE_BUTTONS.keys():
		var button := combat.get_node(button_name) as TextureButton
		if button.texture_normal != null:
			failures.append("%s must not render the old white/cyan flipper texture" % button_name)
		var badge := button.get_node_or_null("BadgeVisual") as Control
		if badge == null:
			failures.append("%s must include a custom BadgeVisual child" % button_name)
			continue
		if badge.get_script() == null or badge.get_script().resource_path != HUD_BADGE_SCRIPT:
			failures.append("%s BadgeVisual must use CombatHudBadge.gd" % button_name)
		if str(badge.get("icon_id")) != str(COMBAT_BADGE_BUTTONS[button_name]):
			failures.append("%s BadgeVisual icon_id must be %s" % [button_name, COMBAT_BADGE_BUTTONS[button_name]])
		var surface_color_variant: Variant = badge.get("surface_color")
		if not surface_color_variant is Color:
			failures.append("%s BadgeVisual must expose a surface_color for light style validation" % button_name)
			continue
		var surface_color := surface_color_variant as Color
		if surface_color.r < 0.88 or surface_color.g < 0.88 or surface_color.b < 0.88:
			failures.append("%s BadgeVisual must use a light World-Flipper-style surface" % button_name)
		if button.size.x > 46.0 or button.size.y > 46.0:
			failures.append("%s must be 46px or smaller to avoid crowding combat" % button_name)
		if badge.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			failures.append("%s BadgeVisual must ignore mouse input" % button_name)

	for label_path: String in [
		"Energy/EnergyCount",
		"DrawPile/DrawCount",
		"DiscardPile/DiscardCount",
		"ExhaustPile/ExhaustCount",
	]:
		var label := combat.get_node(label_path) as Label
		if not label.has_theme_color_override("font_color"):
			failures.append("%s must override font color for the light badge" % label_path)
		elif label.get_theme_color("font_color").r > 0.30:
			failures.append("%s must use dark text on the light badge" % label_path)
		if label.get_theme_constant("outline_size") > 2:
			failures.append("%s must avoid heavy text outlines in the fresh UI style" % label_path)

	var end_turn := combat.get_node("EndTurnButton") as Button
	var normal_style := end_turn.get_theme_stylebox("normal") as StyleBoxFlat
	if normal_style == null or normal_style.bg_color.r < 0.85 or normal_style.bg_color.g < 0.45 or normal_style.bg_color.b > 0.25:
		failures.append("EndTurnButton must use a fresh orange primary button style")
	if not end_turn.has_theme_color_override("font_color"):
		failures.append("EndTurnButton must override font color for readability")
	elif end_turn.get_theme_color("font_color").v < 0.92:
		failures.append("EndTurnButton must use bright text on the orange button")

	root_scene.queue_free()
	await process_frame


func _check_consumable_button_badge() -> void:
	var consumable_scene := load("res://scenes/ui/ConsumableButton.tscn").instantiate() as TextureButton
	root.add_child(consumable_scene)
	await process_frame

	if consumable_scene.texture_normal != null:
		failures.append("ConsumableButton must not render the old default white/cyan flipper texture")
	var badge := consumable_scene.get_node_or_null("BadgeVisual") as Control
	if badge == null:
		failures.append("ConsumableButton must include a custom BadgeVisual child")
	elif badge.get_script() == null or badge.get_script().resource_path != HUD_BADGE_SCRIPT:
		failures.append("ConsumableButton BadgeVisual must use CombatHudBadge.gd")
	else:
		var surface_color_variant: Variant = badge.get("surface_color")
		if not surface_color_variant is Color:
			failures.append("ConsumableButton badge must expose a surface_color for light style validation")
		elif (surface_color_variant as Color).r < 0.88:
			failures.append("ConsumableButton badge must use the fresh light surface")
	if consumable_scene.get_node_or_null("IconTexture") == null:
		failures.append("ConsumableButton must display item art through an IconTexture child")

	consumable_scene.queue_free()
	await process_frame


func _check_combat_card_pick_prompt_panel() -> void:
	var root_scene: Node = load(ROOT_SCENE_PATH).instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var combat := root_scene.get_node("RunScreen/Combat") as Control
	var hand := combat.get_node("Hand") as Control
	var card_picking := combat.get_node("CardPicking") as Control
	if card_picking.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("CardPicking must ignore mouse input outside the confirm button")

	var prompt_panel := card_picking.get_node_or_null("CardPickPromptPanel") as PanelContainer
	if prompt_panel == null:
		failures.append("CardPicking must include a compact CardPickPromptPanel background")
		root_scene.queue_free()
		await process_frame
		return

	if prompt_panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("CardPickPromptPanel must not block hand card clicks")
	var panel_style := prompt_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style == null:
		failures.append("CardPickPromptPanel must use a StyleBoxFlat panel")
	else:
		if panel_style.bg_color.a < 0.56 or panel_style.bg_color.a > 0.86:
			failures.append("CardPickPromptPanel must use a readable translucent background")
		if panel_style.border_width_bottom < 2:
			failures.append("CardPickPromptPanel must keep a visible accent border")
		if panel_style.corner_radius_top_left > 10:
			failures.append("CardPickPromptPanel corners must stay compact")

	var label := prompt_panel.get_node_or_null("MarginContainer/VBoxContainer/CardPickLabel") as Label
	if label == null:
		failures.append("CardPickPromptPanel must contain the card pick label")
	var confirm_button := prompt_panel.get_node_or_null("MarginContainer/VBoxContainer/ConfirmPickButton") as Button
	if confirm_button == null:
		failures.append("CardPickPromptPanel must contain the confirm pick button")
	elif confirm_button.custom_minimum_size.x < 220.0 or confirm_button.custom_minimum_size.x > 360.0:
		failures.append("ConfirmPickButton must remain a compact command inside the prompt panel")

	if label != null and confirm_button != null:
		var short_action := _make_card_pick_action({
			"card_pick_text": "选择 {0} 张手牌。已选择 {1} 张牌",
			"min_card_amount": 1,
			"max_card_amount": 1,
		})
		hand.set("current_card_pick_action", short_action)
		hand.call("update_card_pick_ui")
		await process_frame
		var short_size := prompt_panel.size
		if short_size.x > 460.0 or short_size.y > 136.0:
			failures.append("short card pick prompt must fit content, got %.1fx%.1f" % [short_size.x, short_size.y])

		var long_action := _make_card_pick_action({
			"card_pick_text": "选择 {0} 张手牌随机化费用。已选择 {1} 张牌",
			"min_card_amount": 1,
			"max_card_amount": 3,
		})
		hand.set("current_card_pick_action", long_action)
		hand.call("update_card_pick_ui")
		await process_frame
		var long_size := prompt_panel.size
		if long_size.x <= short_size.x:
			failures.append("longer card pick prompt must grow from the short prompt")
		if long_size.x > 620.0 or long_size.y > 136.0:
			failures.append("long card pick prompt must stay compact, got %.1fx%.1f" % [long_size.x, long_size.y])

		var hand_top: float = (combat.get_node("Hand") as Control).global_position.y
		var panel_bottom: float = prompt_panel.global_position.y + prompt_panel.size.y
		if panel_bottom > hand_top - 20.0:
			failures.append("CardPickPromptPanel must stay above the hand cards")

	root_scene.queue_free()
	await process_frame


func _make_card_pick_action(values: Dictionary) -> Object:
	var action_script := load("res://scripts/actions/pick_card_actions/ActionBasePickCards.gd")
	var action: Object = action_script.new()
	var typed_values: Dictionary[String, Variant] = {}
	for key: Variant in values.keys():
		typed_values[str(key)] = values[key]
	action.set("values", typed_values)
	return action

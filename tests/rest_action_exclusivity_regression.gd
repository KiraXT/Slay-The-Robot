extends SceneTree

const ROOT_SCENE_PATH := "res://scenes/Root.tscn"
const UPGRADE_ACTION_ID := "rest_action_upgrade_card"
const REMOVE_ACTION_ID := "rest_action_remove_cards"
const REST_ACTION_ID := "rest_action_rest"

var failures: Array[String] = []
var game_global: Node
var previous_player_data


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	previous_player_data = game_global.player_data
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.player_deck.append(game_global.get_card_data_from_prototype("card_attack_basic"))
	_prepare_rest_location()

	var root_scene: Node = load(ROOT_SCENE_PATH).instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	var rest_overlay: Node = root_scene.get_node("RunScreen/RestOverlay")
	await _test_card_pick_restoration_keeps_the_rest_action_spent(root_scene, rest_overlay)

	root_scene.queue_free()
	await process_frame
	await process_frame
	game_global.player_data = previous_player_data

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _prepare_rest_location() -> void:
	game_global.player_data.player_run_seed = 20260809
	game_global.player_data.player_act = 1
	game_global.player_data.player_act_id = "act_1"
	game_global.player_data.player_location_id = "location_0"
	game_global.player_data.player_rng.clear()
	root.get_node("ActionGenerator").generate_act("act_1", 1)

	for location in game_global.get_all_act_locations():
		if location.location_type == 7:
			game_global.player_data.player_location_id = location.location_id
			return
	failures.append("generated test map must include a rest site")


func _test_card_pick_restoration_keeps_the_rest_action_spent(root_scene: Node, rest_overlay: Node) -> void:
	rest_overlay.call("_on_map_location_selected", game_global.get_player_location_data())
	var upgrade_button = _get_rest_action_button(rest_overlay, UPGRADE_ACTION_ID)
	if upgrade_button == null:
		failures.append("Upgrade button must be available before choosing a rest action")
		return

	upgrade_button.emit_signal("button_up")
	_assert_exclusive_actions_disabled(rest_overlay, "after choosing Upgrade")
	await process_frame

	var card_picker: Node = root_scene.get_node("RunScreen/CardSelectionOverlay")
	var cards: Array = card_picker.get_node("ScrollContainer/MarginContainer/CardContainer").get_children()
	if cards.is_empty():
		failures.append("Upgrade must open a card selection with an upgradeable deck card")
		return
	card_picker.call("_on_card_selected", cards.back())
	card_picker.call("_on_confirm_button_up")
	await process_frame
	await process_frame

	_assert_exclusive_actions_disabled(rest_overlay, "after returning from card selection")


func _assert_exclusive_actions_disabled(rest_overlay: Node, context: String) -> void:
	for action_id in [REST_ACTION_ID, UPGRADE_ACTION_ID, REMOVE_ACTION_ID]:
		var action_button = _get_rest_action_button(rest_overlay, action_id)
		if action_button == null:
			failures.append("%s button must remain present %s" % [action_id, context])
		elif not action_button.excluded or not action_button.disabled:
			failures.append("%s must be unavailable %s (excluded=%s disabled=%s)" % [
				action_id,
				context,
				action_button.excluded,
				action_button.disabled,
			])


func _get_rest_action_button(rest_overlay: Node, action_id: String):
	var buttons: Array = rest_overlay.get_node("ScrollContainer/MarginContainer/RestActionContainer").get_children()
	buttons.reverse()
	for button in buttons:
		if button.rest_action_object_id == action_id:
			return button
	return null

extends SceneTree

const STATUS_CHORUS := "status_effect_chorus"
const STATUS_BOOKMARK := "status_effect_bookmark_clip"
const STATUS_PACK_SORTING := "status_effect_pack_sorting"
const STATUS_READY_STANCE := "status_effect_ready_stance"
const ACTION_APPLY_STATUS := "res://scripts/actions/status_actions/ActionApplyStatus.gd"
const CARD_PLAY_REQUEST_SCRIPT := "res://data/CardPlayRequest.gd"
const COMBAT_STATS_SCRIPT := "res://data/mutable/CombatStatsData.gd"
const CARD_PICK_TYPE_HAND := 0
const CARD_TYPE_ATTACK := 0

var failures: Array[String] = []
var game_global: Node
var signals: Node
var action_handler: Node
var duplicate_requests: Array = []
var active_statuses: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	signals = root.get_node("Signals")
	action_handler = root.get_node("ActionHandler")
	_setup_player_data()
	await process_frame
	if game_global.player_data == null:
		failures.append("test setup must have player data")
		_finish()
		return

	await _test_bookmark_next_turn_only_changes_tagged_instance()
	await _test_pack_sorting_drawn_same_name_instance_is_isolated()
	await _test_ready_stance_waits_until_next_turn_and_cleans_tags()
	await _test_chorus_duplicate_status_instances_stack()

	_teardown_runtime()

	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _setup_player_data() -> void:
	var combat_stats = _new_combat_stats()
	if game_global.player_data == null or combat_stats == null:
		failures.append("test setup must load player data and combat stats")
		return

	game_global.player_data.player_character_object_id = "character_orange"
	game_global.player_data.player_energy = 3
	game_global.player_data.player_energy_max = 3
	game_global.player_data.player_current_combat_stats = combat_stats
	signals.player_turn_started.emit()


func _teardown_runtime() -> void:
	action_handler.clear_all_actions()
	for status_script in active_statuses:
		if status_script != null:
			status_script.status_charges = 0
	active_statuses.clear()
	if signals.card_play_requested.is_connected(_on_card_play_requested):
		signals.card_play_requested.disconnect(_on_card_play_requested)


func _test_bookmark_next_turn_only_changes_tagged_instance() -> void:
	_reset_runtime_state()
	var tagged_card = _fresh_card("card_attack_basic")
	var untagged_same_name = _fresh_card("card_attack_basic")
	tagged_card.add_card_tag("tag_bookmark_clip")
	_replace_player_pile("player_hand", [tagged_card, untagged_same_name])

	var bookmark_status = _new_status_script(STATUS_BOOKMARK, _status_custom_values("card_bookmark_clip", STATUS_BOOKMARK))
	await _drain_actions()

	_assert_equal(tagged_card.get_card_energy_cost(), 1, "bookmark must not reduce cost before next player turn")
	signals.player_turn_started.emit()
	await _drain_actions()

	_assert_equal(tagged_card.get_card_energy_cost(), 0, "bookmark must reduce the tagged card next player turn")
	_assert_equal(untagged_same_name.get_card_energy_cost(), 1, "bookmark must not affect a same-name untagged instance")
	_assert_false(tagged_card.card_tags.has("tag_bookmark_clip"), "bookmark must remove runtime tag after triggering")
	_assert_equal(bookmark_status.triggers_total, 1, "bookmark status must trigger once")


func _test_pack_sorting_drawn_same_name_instance_is_isolated() -> void:
	_reset_runtime_state()
	var tagged_card = _fresh_card("card_attack_basic")
	var untagged_same_name = _fresh_card("card_attack_basic")
	tagged_card.add_card_tag("tag_pack_sorting")
	_replace_player_pile("player_draw", [tagged_card, untagged_same_name])
	game_global.player_data.player_energy = 0

	var pack_status = _new_status_script(STATUS_PACK_SORTING, _status_custom_values("card_pack_sorting", STATUS_PACK_SORTING))
	await _drain_actions()

	signals.card_drawn.emit(untagged_same_name)
	await _drain_actions()
	_assert_equal(game_global.player_data.player_energy, 0, "pack sorting must ignore same-name untagged draw")
	_assert_true(tagged_card.card_tags.has("tag_pack_sorting"), "pack sorting must keep tag before tagged draw")

	signals.card_drawn.emit(tagged_card)
	await _drain_actions()
	_assert_equal(game_global.player_data.player_energy, 1, "pack sorting must grant energy when the tagged card is drawn")
	_assert_false(tagged_card.card_tags.has("tag_pack_sorting"), "pack sorting must remove tag after draw trigger")
	_assert_equal(pack_status.triggers_total, 1, "pack sorting status must trigger once")


func _test_ready_stance_waits_until_next_turn_and_cleans_tags() -> void:
	_reset_runtime_state()
	var attack_card = _fresh_card("card_attack_basic")
	var skill_card = _fresh_card("card_block_basic")
	_replace_player_pile("player_hand", [attack_card, skill_card])

	var tag_action_script := load("res://scripts/actions/cardset_actions/ActionTagCards.gd")
	var tag_action = tag_action_script.new()
	var tag_values: Dictionary[String, Variant] = {}
	tag_values["card_pick_type"] = CARD_PICK_TYPE_HAND
	tag_values["validator_data"] = [{
		"res://scripts/validators/card/ValidatorCardType.gd": {"card_types": [CARD_TYPE_ATTACK]}
	}]
	tag_values["card_tags_to_add"] = ["tag_ready_stance"]
	tag_action.values = tag_values
	tag_action.perform_action()

	_assert_true(attack_card.card_tags.has("tag_ready_stance"), "ready stance must tag attacks in hand")
	_assert_false(skill_card.card_tags.has("tag_ready_stance"), "ready stance must not tag skills")

	var ready_status = _new_status_script(STATUS_READY_STANCE, _status_custom_values("card_ready_stance", STATUS_READY_STANCE))
	await _drain_actions()

	var early_request = _card_play_request(attack_card, {"damage": 6})
	signals.card_play_started.emit(early_request)
	await _drain_actions()
	_assert_equal(early_request.card_values.get("damage"), 6, "ready stance must not boost before next player turn")

	signals.player_turn_started.emit()
	await _drain_actions()
	var next_turn_request = _card_play_request(attack_card, {"damage": 6})
	signals.card_play_started.emit(next_turn_request)
	await _drain_actions()
	_assert_equal(next_turn_request.card_values.get("damage"), 10, "ready stance must boost tagged attacks next turn")
	_assert_false(attack_card.card_tags.has("tag_ready_stance"), "ready stance must remove tag from played attack")

	var expiring_attack = _fresh_card("card_attack_basic")
	expiring_attack.add_card_tag("tag_ready_stance")
	_replace_player_pile("player_hand", [expiring_attack])
	signals.player_turn_ended.emit()
	await _drain_actions()
	_assert_false(expiring_attack.card_tags.has("tag_ready_stance"), "ready stance must clean leftover tags at turn end")
	_assert_equal(ready_status.triggers_total, 1, "ready stance status must only trigger for the played tagged attack")


func _test_chorus_duplicate_status_instances_stack() -> void:
	_reset_runtime_state()
	if not signals.card_play_requested.is_connected(_on_card_play_requested):
		signals.card_play_requested.connect(_on_card_play_requested)

	var chorus_values := _status_custom_values("card_chorus", STATUS_CHORUS)
	_new_status_script(STATUS_CHORUS, chorus_values)
	_new_status_script(STATUS_CHORUS, chorus_values)
	await _drain_actions()

	var attack_request = _card_play_request(_fresh_card("card_attack_basic"), {"damage": 6})
	duplicate_requests.clear()
	signals.card_play_started.emit(attack_request)
	await _drain_actions()
	_assert_equal(duplicate_requests.size(), 2, "two chorus instances must each duplicate the first matching card")

	duplicate_requests.clear()
	signals.card_play_started.emit(_card_play_request(_fresh_card("card_attack_basic"), {"damage": 6}))
	await _drain_actions()
	_assert_equal(duplicate_requests.size(), 0, "chorus instances must only trigger once per player turn")

	signals.player_turn_started.emit()
	await _drain_actions()
	duplicate_requests.clear()
	signals.card_play_started.emit(_card_play_request(_fresh_card("card_block_basic"), {"block": 5}))
	await _drain_actions()
	_assert_equal(duplicate_requests.size(), 2, "chorus instances must reset on the next player turn")


func _reset_runtime_state() -> void:
	action_handler.clear_all_actions()
	for status_script in active_statuses:
		if status_script != null:
			status_script.status_charges = 0
	active_statuses.clear()
	game_global.player_data.player_hand.clear()
	game_global.player_data.player_draw.clear()
	game_global.player_data.player_discard.clear()
	game_global.player_data.player_exhaust.clear()
	game_global.player_data.player_energy = 3
	game_global.player_data.player_current_combat_stats = _new_combat_stats()
	signals.player_turn_started.emit()
	duplicate_requests.clear()


func _new_combat_stats():
	var combat_stats_script = load(COMBAT_STATS_SCRIPT)
	if combat_stats_script == null:
		failures.append("Could not load CombatStatsData")
		return null
	return combat_stats_script.new("test_gap_c_full_runtime")


func _replace_player_pile(pile_name: String, cards: Array) -> void:
	match pile_name:
		"player_hand":
			game_global.player_data.player_hand.clear()
			for card in cards:
				game_global.player_data.player_hand.append(card)
		"player_draw":
			game_global.player_data.player_draw.clear()
			for card in cards:
				game_global.player_data.player_draw.append(card)
		"player_discard":
			game_global.player_data.player_discard.clear()
			for card in cards:
				game_global.player_data.player_discard.append(card)
		"player_exhaust":
			game_global.player_data.player_exhaust.clear()
			for card in cards:
				game_global.player_data.player_exhaust.append(card)
		_:
			failures.append("Unknown player pile %s" % pile_name)


func _new_status_script(status_id: String, custom_values: Dictionary):
	var status_data = game_global.get_status_effect_data(status_id)
	if status_data == null:
		failures.append("Missing status data for %s" % status_id)
		return null
	var status_script_resource = load(status_data.status_effect_script_path)
	if status_script_resource == null:
		failures.append("Missing status script for %s" % status_id)
		return null
	var status_script = status_script_resource.new()
	status_script.status_effect_data = status_data
	status_script.status_custom_values = custom_values.duplicate(true)
	status_script.status_charges = 1
	status_script._connect_signals()
	active_statuses.append(status_script)
	return status_script


func _fresh_card(card_id: String):
	return game_global.get_card_data_from_prototype(card_id)


func _status_custom_values(card_id: String, status_id: String) -> Dictionary:
	var card_data = game_global.get_card_data_from_prototype(card_id)
	for action_payload: Dictionary in card_data.card_play_actions:
		if action_payload.has(ACTION_APPLY_STATUS):
			var values: Dictionary = action_payload[ACTION_APPLY_STATUS]
			if values.get("status_effect_object_id", "") == status_id:
				return values.get("status_custom_values", {}).duplicate(true)
	failures.append("Missing status custom values for %s -> %s" % [card_id, status_id])
	return {}


func _card_play_request(card_data, card_values: Dictionary):
	var card_play_request_script := load(CARD_PLAY_REQUEST_SCRIPT)
	var request = card_play_request_script.new()
	request.card_data = card_data
	request.card_values = card_values.duplicate(true)
	request.input_energy = 1
	return request


func _on_card_play_requested(card_play_request, _require_energy: bool, _front_of_queue: bool) -> void:
	duplicate_requests.append(card_play_request)


func _drain_actions() -> void:
	await process_frame
	if action_handler.actions_being_performed:
		await action_handler.actions_ended
	await process_frame


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append(label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])

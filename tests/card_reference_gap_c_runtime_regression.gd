extends SceneTree

const ACTION_TAG_CARDS := "res://scripts/actions/cardset_actions/ActionTagCards.gd"
const ACTION_DUPLICATE_CURRENT_CARD_PLAY := "res://scripts/actions/meta_actions/ActionDuplicateCurrentCardPlay.gd"
const STATUS_TAGGED_CARD_TRIGGER := "res://scripts/status_effects/StatusEffectTaggedCardTrigger.gd"
const STATUS_ONCE_PER_TURN_TRIGGER := "res://scripts/status_effects/StatusEffectOncePerTurnTrigger.gd"

var failures: Array[String] = []
var game_global: Node
var signals: Node
var duplicate_signal_payloads: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	signals = root.get_node("Signals")

	_test_new_scripts_load()
	_test_action_tag_cards_adds_and_removes_runtime_tags()
	_test_duplicate_current_card_play_requests_free_duplicate()
	_test_status_sources_include_lifecycle_controls()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_new_scripts_load() -> void:
	for script_path: String in [
		ACTION_TAG_CARDS,
		ACTION_DUPLICATE_CURRENT_CARD_PLAY,
		STATUS_TAGGED_CARD_TRIGGER,
		STATUS_ONCE_PER_TURN_TRIGGER,
	]:
		if load(script_path) == null:
			failures.append("Could not load %s" % script_path)


func _test_action_tag_cards_adds_and_removes_runtime_tags() -> void:
	var action_script := load(ACTION_TAG_CARDS)
	if action_script == null:
		return

	var card_data = game_global.get_card_data_from_prototype("card_attack_basic")
	card_data.card_tags.clear()

	var add_action = action_script.new()
	var add_values: Dictionary[String, Variant] = {}
	add_values["picked_cards"] = [card_data]
	add_values["card_tags_to_add"] = ["tag_gap_c_runtime"]
	add_action.values = add_values
	add_action.perform_action()
	_assert_true(card_data.card_tags.has("tag_gap_c_runtime"), "ActionTagCards must add runtime tags")

	var remove_action = action_script.new()
	var remove_values: Dictionary[String, Variant] = {}
	remove_values["picked_cards"] = [card_data]
	remove_values["card_tags_to_remove"] = ["tag_gap_c_runtime"]
	remove_action.values = remove_values
	remove_action.perform_action()
	_assert_false(card_data.card_tags.has("tag_gap_c_runtime"), "ActionTagCards must remove runtime tags")


func _test_duplicate_current_card_play_requests_free_duplicate() -> void:
	var action_script := load(ACTION_DUPLICATE_CURRENT_CARD_PLAY)
	if action_script == null:
		return

	duplicate_signal_payloads.clear()
	if not signals.card_play_requested.is_connected(_on_card_play_requested):
		signals.card_play_requested.connect(_on_card_play_requested)

	var card_data = game_global.get_card_data_from_prototype("card_attack_basic")
	var card_play_request_script := load("res://data/CardPlayRequest.gd")
	if card_play_request_script == null:
		failures.append("Could not load CardPlayRequest.gd")
		return
	var card_play_request = card_play_request_script.new()
	card_play_request.card_data = card_data
	card_play_request.card_values = {"damage": 7}
	card_play_request.input_energy = 1
	card_play_request.is_duplicate_play = false

	var duplicate_action = action_script.new()
	duplicate_action.card_play_request = card_play_request
	var duplicate_values: Dictionary[String, Variant] = {}
	duplicate_action.values = duplicate_values
	duplicate_action.perform_action()

	_assert_equal(duplicate_signal_payloads.size(), 1, "Duplicate action must emit one card play request")
	if duplicate_signal_payloads.size() == 0:
		return

	var payload: Dictionary = duplicate_signal_payloads[0]
	var duplicate_request = payload["card_play_request"]
	_assert_true(duplicate_request.is_duplicate_play, "Duplicate request must be marked as duplicate")
	_assert_equal(duplicate_request.card_data, card_data, "Duplicate request must use the current card")
	_assert_equal(duplicate_request.card_values.get("damage"), 7, "Duplicate request must copy current request values")
	_assert_false(payload["require_energy"], "Duplicate request must not require energy")
	_assert_true(payload["front_of_queue"], "Duplicate request should be queued at the front")


func _test_status_sources_include_lifecycle_controls() -> void:
	var apply_status_source := FileAccess.get_file_as_string("res://scripts/actions/status_actions/ActionApplyStatus.gd")
	_assert_contains(
		apply_status_source,
		"add_status_effect_charges(status_effect_object_id, status_charge_amount, status_secondary_charge_amount, status_custom_values)",
		"ActionApplyStatus must pass custom values to non-forced status creation"
	)

	var once_per_turn_source := FileAccess.get_file_as_string(STATUS_ONCE_PER_TURN_TRIGGER)
	_assert_contains(
		once_per_turn_source,
		"consume_charge_on_trigger",
		"Once-per-turn trigger must be able to consume charges"
	)
	_assert_contains(
		once_per_turn_source,
		"expire_on_player_turn_ended",
		"Once-per-turn trigger must expire at player turn end when configured"
	)

	var tagged_source := FileAccess.get_file_as_string(STATUS_TAGGED_CARD_TRIGGER)
	_assert_contains(
		tagged_source,
		"arm_on_next_player_turn",
		"Tagged-card trigger must support next-turn arming"
	)
	_assert_contains(
		tagged_source,
		"remove_card_tags_on_expire",
		"Tagged-card trigger must clean tags on expiry"
	)


func _on_card_play_requested(card_play_request, require_energy: bool, front_of_queue: bool) -> void:
	duplicate_signal_payloads.append({
		"card_play_request": card_play_request,
		"require_energy": require_energy,
		"front_of_queue": front_of_queue,
	})


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append(label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])

extends SceneTree

const PREVIOUS_CARD_TYPE_VALIDATOR_PATH := "res://scripts/validators/card_plays/ValidatorPreviousCardType.gd"
const PREVIOUS_CARD_VALIDATOR_PATH := "res://scripts/validators/card_plays/ValidatorPreviousCard.gd"

var failures: Array[String] = []
var game_global: Node
var signals: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	signals = root.get_node("Signals")
	_test_validator_registration_sources()
	_test_previous_card_type_matches_turn_last_card()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_validator_registration_sources() -> void:
	var scripts_source := FileAccess.get_file_as_string("res://autoload/Scripts.gd")
	_assert_contains(
		scripts_source,
		"VALIDATOR_PREVIOUS_CARD_TYPE",
		"Scripts.gd must expose the previous-card-type validator"
	)
	_assert_contains(
		scripts_source,
		"VALIDATOR_PREVIOUS_CARD",
		"Scripts.gd must expose the generic previous-card validator"
	)
	_assert_contains(
		scripts_source,
		PREVIOUS_CARD_TYPE_VALIDATOR_PATH,
		"Scripts.gd previous-card-type validator path"
	)
	_assert_contains(
		scripts_source,
		PREVIOUS_CARD_VALIDATOR_PATH,
		"Scripts.gd previous-card validator path"
	)

	var excel_source := FileAccess.get_file_as_string("res://external/tools/excel_to_json.py")
	_assert_contains(
		excel_source,
		"ValidatorPreviousCardType",
		"Excel converter validator allowlist must include previous-card-type validator"
	)
	_assert_contains(
		excel_source,
		"ValidatorPreviousCard",
		"Excel converter validator allowlist must include generic previous-card validator"
	)


func _test_previous_card_type_matches_turn_last_card() -> void:
	var type_validator_script := load(PREVIOUS_CARD_TYPE_VALIDATOR_PATH)
	var generic_validator_script := load(PREVIOUS_CARD_VALIDATOR_PATH)
	var card_play_request_script := load("res://data/CardPlayRequest.gd")
	if type_validator_script == null:
		failures.append("Could not load %s" % PREVIOUS_CARD_TYPE_VALIDATOR_PATH)
		return
	if generic_validator_script == null:
		failures.append("Could not load %s" % PREVIOUS_CARD_VALIDATOR_PATH)
		return
	if card_play_request_script == null:
		failures.append("Could not load CardPlayRequest.gd")
		return

	var previous_player_data = game_global.player_data
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.init()
	signals.combat_started.emit("validator_previous_card_type_test")

	var type_validator = type_validator_script.new()
	var generic_validator = generic_validator_script.new()
	var attack_card = game_global.get_card_data_from_prototype("card_attack_basic")
	var skill_card = game_global.get_card_data_from_prototype("card_block_basic")

	_assert_false(
		type_validator.validate(null, null, _card_type_values([0])),
		"Validator must fail when no card was previously played this turn"
	)
	_assert_false(
		generic_validator.validate(null, null, _values({"card_type": 0})),
		"Generic validator must fail when must_exist defaults to true and no previous card exists"
	)
	_assert_true(
		generic_validator.validate(null, null, _values({"card_type": 0, "must_exist": false})),
		"Generic validator must pass missing previous card when must_exist is false"
	)

	var attack_play = card_play_request_script.new()
	attack_play.card_data = attack_card
	signals.card_played.emit(attack_play)

	_assert_true(
		type_validator.validate(skill_card, null, _card_type_values([0])),
		"Validator must match the previous card's type, not the current card argument"
	)
	_assert_true(
		generic_validator.validate(skill_card, null, _values({"card_type": 0})),
		"Generic validator must match the previous card's card_type"
	)
	_assert_true(
		generic_validator.validate(skill_card, null, _values({"card_types": [0]})),
		"Generic validator must match previous card when its type is in card_types"
	)
	_assert_true(
		generic_validator.validate(skill_card, null, _values({"card_object_id": attack_card.object_id})),
		"Generic validator must match the previous card's object id"
	)
	_assert_false(
		type_validator.validate(attack_card, null, _card_type_values([1])),
		"Validator must fail when the previous card type is not allowed"
	)
	_assert_false(
		generic_validator.validate(attack_card, null, _values({"card_type": 1})),
		"Generic validator must fail when the previous card type does not match"
	)

	var skill_play = card_play_request_script.new()
	skill_play.card_data = skill_card
	signals.card_played.emit(skill_play)

	_assert_true(
		type_validator.validate(null, null, _card_type_values([1])),
		"Validator must track the latest card played this turn"
	)
	_assert_true(
		generic_validator.validate(null, null, _values({"card_type": 1})),
		"Generic validator must track the latest card played this turn"
	)

	signals.enemy_turn_ended.emit()
	_assert_false(
		type_validator.validate(null, null, _card_type_values([1])),
		"Validator must reset when the turn advances"
	)
	_assert_false(
		generic_validator.validate(null, null, _values({"card_type": 1})),
		"Generic validator must reset when the turn advances"
	)

	var next_turn_play = card_play_request_script.new()
	next_turn_play.card_data = attack_card
	signals.card_played.emit(next_turn_play)
	signals.combat_ended.emit()

	_assert_false(
		type_validator.validate(null, null, _card_type_values([0])),
		"Validator must fail outside combat"
	)
	_assert_false(
		generic_validator.validate(null, null, _values({"card_type": 0})),
		"Generic validator must fail outside combat"
	)

	game_global.player_data = previous_player_data


func _card_type_values(card_types: Array[int]) -> Dictionary[String, Variant]:
	return {"card_types": card_types}


func _values(source: Dictionary) -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = {}
	for key in source:
		values[str(key)] = source[key]
	return values


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append("%s expected true" % label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append("%s expected false" % label)


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])

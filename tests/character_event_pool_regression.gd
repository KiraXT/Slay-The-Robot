extends SceneTree

const TEST_POOL_ID := "event_pool_act_1_dialogue"
const RED_EVENT_ID := "event_pick_something"
const BLUE_EVENT_ID := "event_act_1_easy_combat_1"
const FALLBACK_EVENT_ID := "event_pick_something"
const VALIDATOR_CHARACTER := "res://scripts/validators/ValidatorCharacter.gd"
const REMOVE_FAILED_STRATEGY := 1

var failures: Array[String] = []
var game_global: Node
var red_event
var blue_event
var test_pool
var original_red_event_pool_validator_data: Array[Dictionary] = []
var original_blue_event_pool_validator_data: Array[Dictionary] = []
var original_red_failed_strategy: int = 0
var original_blue_failed_strategy: int = 0
var original_pool_event_object_ids: Array[String] = []
var original_pool_fallback_event_object_id: String = ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	var previous_player_data = game_global.player_data

	if _prepare_test_data():
		_assert_character_validator("character_red", true)
		_assert_character_validator("character_blue", false)
		_assert_pool_selects_matching_event_for_red()
		_assert_pool_selects_matching_event_for_blue()

	_restore_test_data(previous_player_data)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _prepare_test_data() -> bool:
	red_event = game_global.get_event_data(RED_EVENT_ID)
	blue_event = game_global.get_event_data(BLUE_EVENT_ID)
	test_pool = game_global.get_event_pool_data(TEST_POOL_ID)

	if red_event == null:
		failures.append("Missing test red event: %s." % RED_EVENT_ID)
	if blue_event == null:
		failures.append("Missing test blue event: %s." % BLUE_EVENT_ID)
	if test_pool == null:
		failures.append("Missing test event pool: %s." % TEST_POOL_ID)
	if red_event == null or blue_event == null or test_pool == null:
		return false

	original_red_event_pool_validator_data.assign(red_event.event_pool_validator_data.duplicate(true))
	original_blue_event_pool_validator_data.assign(blue_event.event_pool_validator_data.duplicate(true))
	original_red_failed_strategy = red_event.location_event_pool_validator_failed_strategy
	original_blue_failed_strategy = blue_event.location_event_pool_validator_failed_strategy
	original_pool_event_object_ids.assign(test_pool.event_pool_event_object_ids.duplicate(true))
	original_pool_fallback_event_object_id = test_pool.event_pool_fallback_event_object_id

	red_event.event_pool_validator_data = _character_validators("character_red")
	red_event.location_event_pool_validator_failed_strategy = REMOVE_FAILED_STRATEGY
	blue_event.event_pool_validator_data = _character_validators("character_blue")
	blue_event.location_event_pool_validator_failed_strategy = REMOVE_FAILED_STRATEGY

	var event_object_ids: Array[String] = [BLUE_EVENT_ID, RED_EVENT_ID]
	test_pool.event_pool_event_object_ids = event_object_ids
	test_pool.event_pool_fallback_event_object_id = FALLBACK_EVENT_ID
	return true


func _restore_test_data(previous_player_data) -> void:
	if red_event != null:
		red_event.event_pool_validator_data = original_red_event_pool_validator_data
		red_event.location_event_pool_validator_failed_strategy = original_red_failed_strategy
	if blue_event != null:
		blue_event.event_pool_validator_data = original_blue_event_pool_validator_data
		blue_event.location_event_pool_validator_failed_strategy = original_blue_failed_strategy
	if test_pool != null:
		test_pool.event_pool_event_object_ids = original_pool_event_object_ids
		test_pool.event_pool_fallback_event_object_id = original_pool_fallback_event_object_id
	game_global.player_data = previous_player_data


func _character_validators(character_object_id: String) -> Array[Dictionary]:
	var validators: Array[Dictionary] = [{
		VALIDATOR_CHARACTER: {
			"character_object_ids": [character_object_id],
		}
	}]
	return validators


func _assert_character_validator(character_id: String, expected: bool) -> void:
	game_global.player_data = game_global.get_player_data_from_prototype(character_id.replace("character_", "player_"))
	var validators: Array[Dictionary] = _character_validators("character_red")
	var result: bool = game_global.validate(validators, null, null)
	if result != expected:
		failures.append("Expected ValidatorCharacter for %s to be %s, got %s." % [character_id, expected, result])


func _assert_pool_selects_matching_event_for_red() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.player_run_seed = 1
	var event_object_ids: Array[String] = [BLUE_EVENT_ID, RED_EVENT_ID]
	game_global.player_data.player_event_pools[TEST_POOL_ID] = event_object_ids

	var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(TEST_POOL_ID)
	if selected_event_id != RED_EVENT_ID:
		failures.append("Expected red player to select %s, got %s." % [RED_EVENT_ID, selected_event_id])

	var remaining_pool: Array = game_global.player_data.player_event_pools[TEST_POOL_ID]
	if remaining_pool.has(BLUE_EVENT_ID):
		failures.append("Expected failed blue event to be removed from red player's event pool.")


func _assert_pool_selects_matching_event_for_blue() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_blue")
	game_global.player_data.player_run_seed = 1
	var event_object_ids: Array[String] = [RED_EVENT_ID, BLUE_EVENT_ID]
	game_global.player_data.player_event_pools[TEST_POOL_ID] = event_object_ids

	var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(TEST_POOL_ID)
	if selected_event_id != BLUE_EVENT_ID:
		failures.append("Expected blue player to select %s, got %s." % [BLUE_EVENT_ID, selected_event_id])

	var remaining_pool: Array = game_global.player_data.player_event_pools[TEST_POOL_ID]
	if remaining_pool.has(RED_EVENT_ID):
		failures.append("Expected failed red event to be removed from blue player's event pool.")

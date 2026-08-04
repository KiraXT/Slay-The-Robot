extends SceneTree

const TEST_POOL_ID := "test_character_event_pool_regression_pool"
const RED_EVENT_ID := "test_character_event_pool_regression_red"
const BLUE_EVENT_ID := "test_character_event_pool_regression_blue"
const FALLBACK_EVENT_ID := "test_character_event_pool_regression_fallback"
const MISSING_EVENT_ID := "test_character_event_pool_regression_missing"

var failures: Array[String] = []
var game_global: Node
var red_event
var blue_event
var fallback_event
var test_pool


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	var previous_player_data = game_global.player_data

	if _prepare_test_data():
		_assert_validator_character_constant()
		_assert_character_validator("character_red", true)
		_assert_character_validator("character_blue", false)
		_assert_pool_selects_matching_event_for_red()
		_assert_pool_selects_matching_event_for_blue()
		_assert_pool_population_skips_blacklisted_events()
		_assert_pool_removes_missing_events()

	_cleanup_test_data(previous_player_data)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _prepare_test_data() -> bool:
	var event_data_script = game_global.CLASS_NAME_TO_CLASS.get("EventData")
	var event_pool_data_script = game_global.CLASS_NAME_TO_CLASS.get("EventPoolData")

	if event_data_script == null:
		failures.append("Global.CLASS_NAME_TO_CLASS 缺少 EventData 脚本映射。")
	if event_pool_data_script == null:
		failures.append("Global.CLASS_NAME_TO_CLASS 缺少 EventPoolData 脚本映射。")
	if event_data_script == null or event_pool_data_script == null:
		return false

	red_event = _new_test_event(event_data_script, RED_EVENT_ID, "character_red")
	blue_event = _new_test_event(event_data_script, BLUE_EVENT_ID, "character_blue")
	fallback_event = _new_test_event(event_data_script, FALLBACK_EVENT_ID)
	test_pool = event_pool_data_script.new(TEST_POOL_ID)
	var test_pool_event_object_ids: Array[String] = [BLUE_EVENT_ID, RED_EVENT_ID]
	test_pool.event_pool_event_object_ids = test_pool_event_object_ids
	test_pool.event_pool_fallback_event_object_id = FALLBACK_EVENT_ID

	game_global.register_rod(red_event, false)
	game_global.register_rod(blue_event, false)
	game_global.register_rod(fallback_event, false)
	game_global.register_rod(test_pool, false)
	return true


func _cleanup_test_data(previous_player_data) -> void:
	game_global._id_to_event_data.erase(RED_EVENT_ID)
	game_global._id_to_event_data.erase(BLUE_EVENT_ID)
	game_global._id_to_event_data.erase(FALLBACK_EVENT_ID)
	game_global._id_to_event_pool_data.erase(TEST_POOL_ID)
	game_global.player_data = previous_player_data


func _new_test_event(event_data_script: Script, event_id: String, character_object_id: String = ""):
	var event_data = event_data_script.new(event_id)
	if character_object_id != "":
		event_data.event_pool_validator_data = _character_validators(character_object_id)
	# EventData 默认为 FailedEventPoolStrategies.REMOVE，这里保持默认值即可。
	return event_data


func _character_validators(character_object_id: String) -> Array[Dictionary]:
	var validator_data: Dictionary = {}
	validator_data[Scripts.VALIDATOR_CHARACTER] = {
		"character_object_ids": [character_object_id],
	}
	var validators: Array[Dictionary] = [validator_data]
	return validators


func _assert_validator_character_constant() -> void:
	if Scripts.VALIDATOR_CHARACTER != "res://scripts/validators/ValidatorCharacter.gd":
		failures.append("Expected Scripts.VALIDATOR_CHARACTER to point at ValidatorCharacter.gd.")


func _assert_character_validator(character_id: String, expected: bool) -> void:
	game_global.player_data = game_global.get_player_data_from_prototype(character_id.replace("character_", "player_"))
	var validators: Array[Dictionary] = _character_validators("character_red")
	var result: bool = game_global.validate(validators, null, null)
	if result != expected:
		failures.append("Expected ValidatorCharacter for %s to be %s, got %s." % [character_id, expected, result])


func _assert_pool_selects_matching_event_for_red() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.player_run_seed = 1
	game_global.player_data.player_event_pools[TEST_POOL_ID] = [BLUE_EVENT_ID, RED_EVENT_ID]

	var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(TEST_POOL_ID)
	if selected_event_id != RED_EVENT_ID:
		failures.append("Expected red player to select %s, got %s." % [RED_EVENT_ID, selected_event_id])

	var remaining_pool: Array = game_global.player_data.player_event_pools[TEST_POOL_ID]
	if remaining_pool.has(BLUE_EVENT_ID):
		failures.append("Expected failed blue event to be removed from red player's event pool.")


func _assert_pool_selects_matching_event_for_blue() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_blue")
	game_global.player_data.player_run_seed = 1
	game_global.player_data.player_event_pools[TEST_POOL_ID] = [RED_EVENT_ID, BLUE_EVENT_ID]

	var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(TEST_POOL_ID)
	if selected_event_id != BLUE_EVENT_ID:
		failures.append("Expected blue player to select %s, got %s." % [BLUE_EVENT_ID, selected_event_id])

	var remaining_pool: Array = game_global.player_data.player_event_pools[TEST_POOL_ID]
	if remaining_pool.has(RED_EVENT_ID):
		failures.append("Expected failed red event to be removed from blue player's event pool.")


func _assert_pool_population_skips_blacklisted_events() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.player_run_seed = 1
	var blacklisted_event_ids: Array[String] = [BLUE_EVENT_ID]
	game_global.player_data.player_event_blacklisted_ids = blacklisted_event_ids

	var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(TEST_POOL_ID)
	if selected_event_id != RED_EVENT_ID:
		failures.append("Expected blacklisted event to be skipped and select %s, got %s." % [RED_EVENT_ID, selected_event_id])

	var remaining_pool: Array = game_global.player_data.player_event_pools[TEST_POOL_ID]
	if remaining_pool.has(BLUE_EVENT_ID):
		failures.append("Expected blacklisted event to be excluded when populating the event pool.")


func _assert_pool_removes_missing_events() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.player_run_seed = 1
	game_global.player_data.player_event_pools[TEST_POOL_ID] = [MISSING_EVENT_ID, RED_EVENT_ID]

	var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(TEST_POOL_ID)
	if selected_event_id != RED_EVENT_ID:
		failures.append("Expected missing event to be skipped and select %s, got %s." % [RED_EVENT_ID, selected_event_id])

	var remaining_pool: Array = game_global.player_data.player_event_pools[TEST_POOL_ID]
	if remaining_pool.has(MISSING_EVENT_ID):
		failures.append("Expected missing event ID to be removed from the event pool.")

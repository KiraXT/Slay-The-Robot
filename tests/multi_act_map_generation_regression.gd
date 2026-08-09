extends SceneTree

const PLAYER_ID := "player_red"
const TEST_SEED := 20260807
const LOCATION_DATA_SCRIPT := "res://data/mutable/LocationData.gd"
const LOCATION_TYPES := {
	"STARTING": 0,
	"COMBAT": 1,
	"MINIBOSS": 2,
	"BOSS": 3,
	"EVENT": 4,
	"TREASURE": 5,
	"SHOP": 6,
	"REST_SITE": 7,
}

var failures: Array[String] = []
var game_global: Node
var action_generator: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	action_generator = root.get_node("ActionGenerator")

	var previous_player_data = game_global.player_data
	_assert_generated_act_pools(
		"act_2",
		2,
		"event_pool_act_2_easy",
		"event_pool_act_2_hard",
		"event_pool_act_2_miniboss",
		"event_pool_act_2_boss",
		"event_act_2_boss_foundry_heart"
	)
	_assert_generated_act_pools(
		"act_3",
		3,
		"event_pool_act_3_easy",
		"event_pool_act_3_hard",
		"event_pool_act_3_miniboss",
		"event_pool_act_3_boss",
		"event_act_3_boss_overmind_core"
	)
	game_global.player_data = previous_player_data

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _assert_generated_act_pools(
	act_id: String,
	act_number: int,
	expected_easy_pool_id: String,
	expected_hard_pool_id: String,
	expected_miniboss_pool_id: String,
	expected_boss_pool_id: String,
	expected_boss_event_id: String
) -> void:
	game_global.player_data = game_global.get_player_data_from_prototype(PLAYER_ID)
	game_global.player_data.player_run_seed = TEST_SEED
	game_global.player_data.player_act = act_number - 1
	game_global.player_data.player_act_id = "act_%s" % str(max(1, act_number - 1))
	game_global.player_data.player_location_id = "location_previous_boss"
	game_global.player_data.player_rng.clear()

	var location_data_script = load(LOCATION_DATA_SCRIPT)
	if location_data_script == null:
		failures.append("LocationData script must load for multi-act map generation regression")
		return
	var previous_location = location_data_script.new()
	previous_location.location_id = "location_previous_boss"
	previous_location.location_act = act_number - 1
	previous_location.location_type = LOCATION_TYPES.BOSS
	previous_location.location_position = Vector2(400, 100)
	game_global.player_data.location_id_to_location_data[previous_location.location_id] = previous_location

	action_generator.generate_act(act_id, act_number)

	var locations: Array = game_global.get_all_act_locations()
	_assert_generated_combat_pools(act_id, locations, expected_easy_pool_id, expected_hard_pool_id)
	_assert_generated_miniboss_pools(act_id, locations, expected_miniboss_pool_id)

	var boss_location = _get_single_location_of_type(locations, LOCATION_TYPES.BOSS)
	if boss_location == null:
		return
	if boss_location.location_event_pool_object_id != expected_boss_pool_id:
		failures.append("%s boss location should use %s, got %s" % [
			act_id,
			expected_boss_pool_id,
			boss_location.location_event_pool_object_id,
		])

	var actual_event_id: String = boss_location.get_location_event_object_id()
	if actual_event_id != expected_boss_event_id:
		failures.append("%s boss location should resolve %s, got %s" % [
			act_id,
			expected_boss_event_id,
			actual_event_id,
		])


func _assert_generated_combat_pools(act_id: String, locations: Array, expected_easy_pool_id: String, expected_hard_pool_id: String) -> void:
	var saw_easy_combat := false
	var saw_hard_combat := false
	for location in locations:
		if location.location_type != LOCATION_TYPES.COMBAT:
			continue
		var expected_pool_id := expected_hard_pool_id
		if int(location.location_index.y) < 3:
			expected_pool_id = expected_easy_pool_id
			saw_easy_combat = true
		else:
			saw_hard_combat = true
		if location.location_event_pool_object_id != expected_pool_id:
			failures.append("%s combat floor %s should use %s, got %s" % [
				act_id,
				location.location_index.y,
				expected_pool_id,
				location.location_event_pool_object_id,
			])
	if not saw_easy_combat:
		failures.append("%s should generate at least one easy combat location" % act_id)
	if not saw_hard_combat:
		failures.append("%s should generate at least one hard combat location" % act_id)


func _assert_generated_miniboss_pools(act_id: String, locations: Array, expected_pool_id: String) -> void:
	var saw_miniboss := false
	for location in locations:
		if location.location_type != LOCATION_TYPES.MINIBOSS:
			continue
		saw_miniboss = true
		if location.location_event_pool_object_id != expected_pool_id:
			failures.append("%s miniboss location should use %s, got %s" % [
				act_id,
				expected_pool_id,
				location.location_event_pool_object_id,
			])
	if not saw_miniboss:
		failures.append("%s should generate at least one miniboss location" % act_id)


func _get_single_location_of_type(locations: Array, location_type: int):
	var matching_locations: Array = []
	for location in locations:
		if location.location_type == location_type:
			matching_locations.append(location)
	if matching_locations.size() != 1:
		failures.append("Expected one location of type %s, got %s." % [location_type, matching_locations.size()])
		return null
	return matching_locations[0]

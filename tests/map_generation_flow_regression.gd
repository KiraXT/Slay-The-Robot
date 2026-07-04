extends SceneTree

const ACT_ID := "act_1"
const PLAYER_ID := "player_red"
const TEST_SEED := 20260705
const MIN_NORMAL_FLOOR_LOCATIONS := 3
const MAX_NORMAL_FLOOR_LOCATIONS := 5
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
	_generate_test_map()

	var locations = game_global.get_all_act_locations()
	var by_id := _get_locations_by_id(locations)
	var start_location = _get_single_location_of_type(locations, LOCATION_TYPES.STARTING)
	var boss_location = _get_single_location_of_type(locations, LOCATION_TYPES.BOSS)

	_assert_start_and_boss(start_location, boss_location)
	_assert_normal_floor_counts_vary(locations)
	_assert_route_graph_is_connected(locations, by_id, start_location)
	_assert_all_locations_are_reachable(locations, by_id, start_location)

	game_global.player_data = previous_player_data

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _generate_test_map() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype(PLAYER_ID)
	game_global.player_data.player_run_seed = TEST_SEED
	game_global.player_data.player_act = 1
	game_global.player_data.player_act_id = ACT_ID
	game_global.player_data.player_location_id = "location_0"
	game_global.player_data.player_rng.clear()
	action_generator.generate_act(ACT_ID, 1)


func _assert_start_and_boss(start_location, boss_location) -> void:
	if start_location == null:
		failures.append("Expected generated map to include one starting location.")
	elif start_location.location_next_location_ids.is_empty():
		failures.append("Expected starting location to connect to the first map row.")

	if boss_location == null:
		failures.append("Expected generated map to include one boss location.")


func _assert_normal_floor_counts_vary(locations: Array) -> void:
	var by_floor := _get_locations_by_floor(locations)
	var distinct_counts := {}
	var floor_counts: Array[int] = []

	for floor in by_floor.keys():
		var floor_locations: Array = by_floor[floor]
		if _floor_contains_type(floor_locations, LOCATION_TYPES.STARTING):
			continue
		if _floor_contains_type(floor_locations, LOCATION_TYPES.BOSS):
			continue

		var count := floor_locations.size()
		floor_counts.append(count)
		distinct_counts[count] = true

		if count < MIN_NORMAL_FLOOR_LOCATIONS or count > MAX_NORMAL_FLOOR_LOCATIONS:
			failures.append("Expected floor %s to have %s-%s locations, got %s." % [
				floor,
				MIN_NORMAL_FLOOR_LOCATIONS,
				MAX_NORMAL_FLOOR_LOCATIONS,
				count,
			])

	if distinct_counts.size() <= 1:
		failures.append("Expected normal floor counts to vary, got counts: %s." % [floor_counts])


func _assert_route_graph_is_connected(locations: Array, by_id: Dictionary, start_location) -> void:
	var incoming_counts := {}
	for location in locations:
		incoming_counts[location.location_id] = 0

	for location in locations:
		for next_location_id in location.location_next_location_ids:
			if not by_id.has(next_location_id):
				failures.append("Location %s connects to missing location %s." % [location.location_id, next_location_id])
				continue
			incoming_counts[next_location_id] += 1

		if location.location_type != LOCATION_TYPES.BOSS and location.location_next_location_ids.is_empty():
			failures.append("Non-boss location %s has no outgoing route." % [location.location_id])

	for location in locations:
		if start_location != null and location.location_id == start_location.location_id:
			continue
		if incoming_counts.get(location.location_id, 0) == 0:
			failures.append("Location %s has no incoming route." % [location.location_id])


func _assert_all_locations_are_reachable(locations: Array, by_id: Dictionary, start_location) -> void:
	if start_location == null:
		return

	var visited := {}
	var frontier: Array[String] = [start_location.location_id]

	while not frontier.is_empty():
		var current_id: String = frontier.pop_front()
		if visited.has(current_id):
			continue
		visited[current_id] = true

		var location = by_id.get(current_id)
		if location == null:
			continue
		for next_location_id in location.location_next_location_ids:
			if not visited.has(next_location_id):
				frontier.append(next_location_id)

	if visited.size() != locations.size():
		failures.append("Expected all generated locations to be reachable from start, reached %s of %s." % [
			visited.size(),
			locations.size(),
		])


func _get_locations_by_id(locations: Array) -> Dictionary:
	var by_id := {}
	for location in locations:
		by_id[location.location_id] = location
	return by_id


func _get_locations_by_floor(locations: Array) -> Dictionary:
	var by_floor := {}
	for location in locations:
		if not by_floor.has(location.location_floor):
			by_floor[location.location_floor] = []
		by_floor[location.location_floor].append(location)
	return by_floor


func _get_single_location_of_type(locations: Array, location_type: int):
	var matching_locations: Array = []
	for location in locations:
		if location.location_type == location_type:
			matching_locations.append(location)

	if matching_locations.size() != 1:
		failures.append("Expected one location of type %s, got %s." % [location_type, matching_locations.size()])
		return null

	return matching_locations[0]


func _floor_contains_type(floor_locations: Array, location_type: int) -> bool:
	for location in floor_locations:
		if location.location_type == location_type:
			return true
	return false

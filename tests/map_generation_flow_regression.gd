extends SceneTree

const ACT_ID := "act_1"
const PLAYER_ID := "player_red"
const TEST_SEED := 20260705
const MIN_NORMAL_FLOOR_LOCATIONS := 2
const MAX_NORMAL_FLOOR_LOCATIONS := 4
const GRID_SPACING := 140.0
const MAP_MIN_X := 120.0
const MAP_MAX_X := 680.0
const MAP_MIN_Y := 80.0
const POSITION_TOLERANCE := 1.0
const MIN_SAME_FLOOR_DISTANCE := 92.0
const MAX_ROUTE_CROSSINGS := 0
const MAX_BRANCHING_NODES := 8
const MAX_ROUTES_PER_LOCATION := 2
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
	_assert_start_and_boss_are_centered(start_location, boss_location)
	_assert_locations_are_staggered(locations)
	_assert_locations_stay_inside_generation_bounds(locations)
	_assert_locations_have_breathing_room(locations)
	_assert_route_crossings_are_limited(locations, by_id)
	_assert_routes_branch_sparingly(locations, by_id)
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


func _assert_start_and_boss_are_centered(start_location, boss_location) -> void:
	for location in [start_location, boss_location]:
		if location == null:
			continue
		if abs(location.location_position.x - 400.0) > POSITION_TOLERANCE:
			failures.append("%s should stay centered, got x=%s." % [
				location.location_id,
				location.location_position.x,
			])


func _assert_locations_are_staggered(locations: Array) -> void:
	var normal_by_floor := _get_locations_by_floor(locations)
	var staggered_floor_count := 0
	var off_grid_x_count := 0
	var checked_location_count := 0

	for floor in normal_by_floor.keys():
		var floor_locations: Array = normal_by_floor[floor]
		if _floor_contains_type(floor_locations, LOCATION_TYPES.STARTING):
			continue
		if _floor_contains_type(floor_locations, LOCATION_TYPES.BOSS):
			continue

		var first_y: Variant = null
		var floor_has_y_variation := false
		for location in floor_locations:
			checked_location_count += 1
			if first_y == null:
				first_y = location.location_position.y
			elif abs(location.location_position.y - first_y) > POSITION_TOLERANCE:
				floor_has_y_variation = true

			var nearest_grid_x: float = round(location.location_position.x / GRID_SPACING) * GRID_SPACING
			if abs(location.location_position.x - nearest_grid_x) > POSITION_TOLERANCE:
				off_grid_x_count += 1

		if floor_has_y_variation:
			staggered_floor_count += 1

	if staggered_floor_count < 5:
		failures.append("Expected at least 5 normal floors with vertical stagger, got %s." % staggered_floor_count)
	if off_grid_x_count < int(ceil(float(checked_location_count) * 0.5)):
		failures.append("Expected at least half of normal nodes off the fixed x grid, got %s of %s." % [
			off_grid_x_count,
			checked_location_count,
		])


func _assert_locations_stay_inside_generation_bounds(locations: Array) -> void:
	for location in locations:
		if location.location_position.x < MAP_MIN_X or location.location_position.x > MAP_MAX_X:
			failures.append("%s x position out of map bounds: %s." % [
				location.location_id,
				location.location_position.x,
			])
		if location.location_position.y < MAP_MIN_Y:
			failures.append("%s y position too close to top edge: %s." % [
				location.location_id,
				location.location_position.y,
			])


func _assert_locations_have_breathing_room(locations: Array) -> void:
	var by_floor := _get_locations_by_floor(locations)
	for floor in by_floor.keys():
		var floor_locations: Array = by_floor[floor]
		if _floor_contains_type(floor_locations, LOCATION_TYPES.STARTING):
			continue
		if _floor_contains_type(floor_locations, LOCATION_TYPES.BOSS):
			continue

		for first_index in range(floor_locations.size()):
			for second_index in range(first_index + 1, floor_locations.size()):
				var first_location = floor_locations[first_index]
				var second_location = floor_locations[second_index]
				var distance: float = first_location.location_position.distance_to(second_location.location_position)
				if distance < MIN_SAME_FLOOR_DISTANCE:
					failures.append("Expected floor %s locations to stay sparse; %s and %s are %.1fpx apart." % [
						floor,
						first_location.location_id,
						second_location.location_id,
						distance,
					])


func _assert_route_crossings_are_limited(locations: Array, by_id: Dictionary) -> void:
	var route_segments_by_floor_pair := {}
	for location in locations:
		for next_location_id in location.location_next_location_ids:
			var next_location = by_id.get(next_location_id)
			if next_location == null:
				continue
			var floor_pair_key := "%s:%s" % [location.location_floor, next_location.location_floor]
			if not route_segments_by_floor_pair.has(floor_pair_key):
				route_segments_by_floor_pair[floor_pair_key] = []
			route_segments_by_floor_pair[floor_pair_key].append([location, next_location])

	var crossing_count := 0
	for floor_pair_key in route_segments_by_floor_pair.keys():
		var segments: Array = route_segments_by_floor_pair[floor_pair_key]
		for first_index in range(segments.size()):
			for second_index in range(first_index + 1, segments.size()):
				var first_segment: Array = segments[first_index]
				var second_segment: Array = segments[second_index]
				if first_segment[0].location_id == second_segment[0].location_id:
					continue
				if first_segment[1].location_id == second_segment[1].location_id:
					continue
				if _segments_cross(
					first_segment[0].location_position,
					first_segment[1].location_position,
					second_segment[0].location_position,
					second_segment[1].location_position
				):
					crossing_count += 1

	if crossing_count > MAX_ROUTE_CROSSINGS:
		failures.append("Expected routes to avoid crossings, got %s crossing route pairs." % crossing_count)


func _assert_routes_branch_sparingly(locations: Array, by_id: Dictionary) -> void:
	var incoming_counts := {}
	for location in locations:
		incoming_counts[location.location_id] = 0

	var split_count := 0
	for location in locations:
		var outgoing_count: int = location.location_next_location_ids.size()
		if outgoing_count > MAX_ROUTES_PER_LOCATION:
			failures.append("Expected %s to have at most %s outgoing routes, got %s." % [
				location.location_id,
				MAX_ROUTES_PER_LOCATION,
				outgoing_count,
			])
		if outgoing_count > 1:
			split_count += 1

		for next_location_id in location.location_next_location_ids:
			if by_id.has(next_location_id):
				incoming_counts[next_location_id] += 1

	var merge_count := 0
	for location in locations:
		if location.location_type == LOCATION_TYPES.BOSS:
			continue

		var incoming_count: int = incoming_counts.get(location.location_id, 0)
		if incoming_count > MAX_ROUTES_PER_LOCATION:
			failures.append("Expected %s to have at most %s incoming routes, got %s." % [
				location.location_id,
				MAX_ROUTES_PER_LOCATION,
				incoming_count,
			])
		if incoming_count > 1:
			merge_count += 1

	if split_count + merge_count > MAX_BRANCHING_NODES:
		failures.append("Expected only sparse branching/merging, got %s split nodes and %s merge nodes." % [
			split_count,
			merge_count,
		])


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


func _segments_cross(first_start: Vector2, first_end: Vector2, second_start: Vector2, second_end: Vector2) -> bool:
	var first_orientation := _orientation(first_start, first_end, second_start)
	var second_orientation := _orientation(first_start, first_end, second_end)
	var third_orientation := _orientation(second_start, second_end, first_start)
	var fourth_orientation := _orientation(second_start, second_end, first_end)
	return first_orientation * second_orientation < 0.0 and third_orientation * fourth_orientation < 0.0


func _orientation(first: Vector2, second: Vector2, third: Vector2) -> float:
	var cross_product: float = (second - first).cross(third - first)
	if abs(cross_product) <= POSITION_TOLERANCE:
		return 0.0
	return sign(cross_product)


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

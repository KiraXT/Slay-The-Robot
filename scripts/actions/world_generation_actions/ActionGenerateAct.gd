## Generates the world map for an act. This is called at the start of a run and end of an act.
## See: ActionGenerator.generate_act() and generate_next_act()
## Changing this script and its params should be sufficient for most use cases,
## however you can supply different scripts to an ActData.act_action_script_path if you need multiple
## generation algorithms.
extends BaseAction

const MAP_CENTER_X := 400.0
const GRID_SPACING := 140.0
const MAP_MIN_X := 120.0
const MAP_MAX_X := 680.0
const MAP_MIN_Y := 80.0
const LOCATION_X_JITTER := GRID_SPACING * 0.16
const LOCATION_Y_JITTER := GRID_SPACING * 0.10
const DEFAULT_MIN_LOCATIONS_PER_FLOOR := 2
const DEFAULT_MAX_LOCATIONS_PER_FLOOR := 4
const STARTING_ROUTE_COUNT := 2
const MAX_ROUTES_PER_LOCATION := 2
const START_FLOOR_INDEX := -1


func perform_action() -> void:
	# generates all world locations from a seed and stores them in PlayerData
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		### Set rng seed
		var rng_name: String = action_interceptor_processor.get_shadowed_action_values("rng_name", "rng_world_generation") # allows using different rng
		var rng_world_generation: RandomNumberGenerator = Global.player_data.get_player_rng(rng_name)
		
		### Get the read only act data to determine additional generation
		var act_id: String = get_action_value("act_id", "")
		var act_data: ActData = Global.get_act_data(act_id)
		var act_number: int = get_action_value("act_number", Global.player_data.player_act)
		
		## Set player act to new act
		Global.player_data.player_act_id = act_id
		Global.player_data.player_act = act_number
		
		### parameters of grid
		var floors_per_act: int = action_interceptor_processor.get_shadowed_action_values("floors_per_act", 10)
		var max_locations_per_floor: int = action_interceptor_processor.get_shadowed_action_values("locations_per_floor", DEFAULT_MAX_LOCATIONS_PER_FLOOR)
		var min_locations_per_floor: int = action_interceptor_processor.get_shadowed_action_values("min_locations_per_floor", DEFAULT_MIN_LOCATIONS_PER_FLOOR)
		var location_obfuscation_rate: float = action_interceptor_processor.get_shadowed_action_values("location_obfuscation_rate", 0.5) # how often locations will be obfuscated
		var location_non_combat_event_rate: float = action_interceptor_processor.get_shadowed_action_values("location_non_combat_event_rate", 0.3) # how often locations will be a non combat event
		
		var generate_start_node: bool = act_number == 1
		min_locations_per_floor = max(1, min_locations_per_floor)
		max_locations_per_floor = max(min_locations_per_floor, max_locations_per_floor)
		var bottom_y: float = float(floors_per_act + 1) * GRID_SPACING
		
		### vars used for generation
		var location_position: Vector2 = Vector2.ZERO # current position in grid
		var floors: Array[Array] = [] # stores all generated locations in layers
		var location_id_counter: int = 0 # used to generate unique ids
		var floor_counter: int = 0
		
		
		
		### Generate/get starting node
		if generate_start_node:
			# creates a new starting node, mainly useful for the first act
			
			# clear existing locations; This isn't strictly necessary but clears up garbage
			Global.clear_locations()
			
			var starting_floor: Array[LocationData] = []
			var starting_location: LocationData = LocationData.new()
			# get a unique id and assign it
			starting_location.location_id = "location_0"
			Global.player_data.location_id_to_location_data["location_0"] = starting_location	# store as mapping in Global
			Global.player_data.player_location_id = starting_location.location_id
			# positioning and act
			starting_location.location_act = act_number
			starting_location.location_index = Vector2(0, START_FLOOR_INDEX)
			starting_location.location_position = _get_location_position(0, 1, START_FLOOR_INDEX, bottom_y)
			starting_location.location_floor = floor_counter
			# assign a type
			starting_location.location_type = LocationData.LOCATION_TYPES.STARTING
			# assign a random event
			starting_location.location_event_object_id = "event_act_1_easy_combat_1"
			# add node to layer
			starting_floor.append(starting_location)
			floors.append(starting_floor)
		else:
			# if no starting node generated, use the location the player is currently on (presumably from last act)
			# and treat it as a "starting" node to connect to the next act
			var current_location_data: LocationData = Global.get_player_location_data()
			
			# clear existing locations; This isn't strictly necessary but clears up garbage
			Global.clear_locations()
			
			# remap the previous boss floor as it still needs to exist
			Global.player_data.location_id_to_location_data[current_location_data.location_id] = current_location_data
			
			var current_floor: Array[LocationData] = [current_location_data]
			floors.append(current_floor) # will be connected to by first floor of this act
		
		### generate each floor
		var location_id: String = ""
		for k in floors_per_act:
			var current_floor: Array[LocationData] = []
			floor_counter += 1
			var current_floor_count: int = rng_world_generation.randi_range(min_locations_per_floor, max_locations_per_floor)
			if k == 0:
				current_floor_count = min(current_floor_count, STARTING_ROUTE_COUNT)

			### generate each node in a floor
			for i in current_floor_count:
				# make a node
				var location: LocationData = LocationData.new()
				# get a unique id and assign it
				location_id_counter += 1
				location_id = "location_" + str(act_number) + "_" + str(location_id_counter)
				location.location_id = location_id
				Global.player_data.location_id_to_location_data[location_id] = location	# store as mapping in PlayerData
				# positioning and act
				location.location_act = act_number
				location.location_index = Vector2(i, k)
				location_position = _get_location_position(i, current_floor_count, k, bottom_y, rng_world_generation, true)
				location.location_position = location_position
				location.location_floor = floor_counter
				
				if k == 4:
					location.location_type = LocationData.LOCATION_TYPES.MINIBOSS
					location.location_event_pool_object_id = act_data.act_miniboss_event_pool_object_id
				elif k == 6:
					location.location_type = LocationData.LOCATION_TYPES.REST_SITE
					#location.location_event_object_id = "event_act_1_easy_combat_1"
				elif k == 5:
					location.location_type = LocationData.LOCATION_TYPES.TREASURE
					# location.location_event_object_id = "event_act_1_easy_combat_1"
					location.location_event_pool_object_id = act_data.act_easy_combat_event_pool_object_id
				elif k == 3:
					location.location_type = LocationData.LOCATION_TYPES.SHOP
				elif k < 3:
					# easy pool
					location.location_type = LocationData.LOCATION_TYPES.COMBAT
					location.location_event_pool_object_id = act_data.act_easy_combat_event_pool_object_id
				else:
					# hard pool
					location.location_type = LocationData.LOCATION_TYPES.COMBAT
					location.location_event_pool_object_id = act_data.act_hard_combat_event_pool_object_id
				
				# randomly obfuscate some location types
				if [LocationData.LOCATION_TYPES.TREASURE, LocationData.LOCATION_TYPES.COMBAT].has(location.location_type):
					if rng_world_generation.randf() < location_obfuscation_rate:
						location.location_obfuscated = true
				
				# randomly convert some to dialogue events
				if [LocationData.LOCATION_TYPES.COMBAT].has(location.location_type):
					if rng_world_generation.randf() < location_non_combat_event_rate:
						location.location_obfuscated = true
						location.location_type = LocationData.LOCATION_TYPES.EVENT
						location.location_event_pool_object_id = act_data.act_non_combat_event_pool_object_id
				
				# add node to floor
				current_floor.append(location)

			current_floor.sort_custom(func(a: LocationData, b: LocationData): return a.location_position.x < b.location_position.x)

			if len(floors):
				var previous_floor: Array[LocationData] = floors[-1]
				_connect_floors(previous_floor, current_floor, rng_world_generation)
			floors.append(current_floor)
		
		### boss layer at end of act
		var boss_floor: Array[LocationData] = []
		floor_counter += 1
		# make a node
		var boss_location: LocationData = LocationData.new()
		# get a unique id and assign it
		location_id_counter += 1
		location_id = "location_" + str(act_number) + "_" + str(location_id_counter)
		boss_location.location_id = location_id
		Global.player_data.location_id_to_location_data[location_id] = boss_location	# store as mapping in Global
		# positioning and act
		boss_location.location_act = act_number
		boss_location.location_index = Vector2(0, floors_per_act)
		location_position = _get_location_position(0, 1, floors_per_act, bottom_y)
		boss_location.location_position = location_position
		boss_location.location_floor = floor_counter
		# assign a type
		boss_location.location_type = LocationData.LOCATION_TYPES.BOSS
		# assign a boss pool
		boss_location.location_event_pool_object_id = act_data.act_boss_event_pool_object_id
		
		# connect all locations directly below boss to it
		if len(floors):
			var previous_floor: Array[LocationData] = floors[-1]
			for previous_location in previous_floor:
				_connect_locations(previous_location, location_id)
		
		# add node to layer
		boss_floor.append(boss_location)
		floors.append(boss_floor)


func _get_location_position(
	location_index: int,
	floor_location_count: int,
	floor_index: int,
	bottom_y: float,
	rng_world_generation: RandomNumberGenerator = null,
	apply_jitter: bool = false
) -> Vector2:
	var center_offset := (float(location_index) - (float(floor_location_count - 1) / 2.0)) * GRID_SPACING
	var position := Vector2(MAP_CENTER_X + center_offset, bottom_y - (float(floor_index) * GRID_SPACING))
	if apply_jitter and rng_world_generation != null:
		position.x += rng_world_generation.randf_range(-LOCATION_X_JITTER, LOCATION_X_JITTER)
		position.y += rng_world_generation.randf_range(-LOCATION_Y_JITTER, LOCATION_Y_JITTER)
	position.x = clamp(position.x, MAP_MIN_X, MAP_MAX_X)
	position.y = max(position.y, MAP_MIN_Y)
	return position


func _connect_floors(previous_floor: Array[LocationData], current_floor: Array[LocationData], _rng_world_generation: RandomNumberGenerator) -> void:
	if previous_floor.is_empty() or current_floor.is_empty():
		return

	var route_pairs: Array[Vector2i] = []
	var outgoing_counts: Array[int] = []
	var incoming_counts: Array[int] = []
	outgoing_counts.resize(previous_floor.size())
	incoming_counts.resize(current_floor.size())
	outgoing_counts.fill(0)
	incoming_counts.fill(0)

	if previous_floor.size() == 1:
		for current_index in range(min(STARTING_ROUTE_COUNT, current_floor.size())):
			_add_route_pair(route_pairs, outgoing_counts, incoming_counts, 0, current_index)
		_apply_route_pairs(previous_floor, current_floor, route_pairs)
		return

	for previous_index in range(previous_floor.size()):
		var current_index := _map_index_to_floor(previous_index, previous_floor.size(), current_floor.size())
		_add_route_pair(route_pairs, outgoing_counts, incoming_counts, previous_index, current_index)

	for current_index in range(current_floor.size()):
		if incoming_counts[current_index] > 0:
			continue
		var previous_index := _map_index_to_floor(current_index, current_floor.size(), previous_floor.size())
		_add_route_pair(route_pairs, outgoing_counts, incoming_counts, previous_index, current_index)

	_apply_route_pairs(previous_floor, current_floor, route_pairs)


func _map_index_to_floor(index: int, from_count: int, to_count: int) -> int:
	if to_count <= 1:
		return 0
	if from_count <= 1:
		return int(floor(float(to_count - 1) / 2.0))
	var mapped_index := int(round(float(index) * float(to_count - 1) / float(from_count - 1)))
	return clamp(mapped_index, 0, to_count - 1)


func _add_route_pair(
	route_pairs: Array[Vector2i],
	outgoing_counts: Array[int],
	incoming_counts: Array[int],
	previous_index: int,
	current_index: int
) -> bool:
	if previous_index < 0 or previous_index >= outgoing_counts.size():
		return false
	if current_index < 0 or current_index >= incoming_counts.size():
		return false
	if outgoing_counts[previous_index] >= MAX_ROUTES_PER_LOCATION:
		return false
	if incoming_counts[current_index] >= MAX_ROUTES_PER_LOCATION:
		return false

	var route_pair := Vector2i(previous_index, current_index)
	if route_pairs.has(route_pair):
		return false
	if _route_pair_crosses_existing(route_pair, route_pairs):
		return false

	route_pairs.append(route_pair)
	outgoing_counts[previous_index] += 1
	incoming_counts[current_index] += 1
	return true


func _route_pair_crosses_existing(route_pair: Vector2i, route_pairs: Array[Vector2i]) -> bool:
	for existing_pair in route_pairs:
		if route_pair.x == existing_pair.x or route_pair.y == existing_pair.y:
			continue
		if (route_pair.x - existing_pair.x) * (route_pair.y - existing_pair.y) < 0:
			return true
	return false


func _apply_route_pairs(previous_floor: Array[LocationData], current_floor: Array[LocationData], route_pairs: Array[Vector2i]) -> void:
	for route_pair in route_pairs:
		_connect_locations(previous_floor[route_pair.x], current_floor[route_pair.y].location_id)


func _connect_locations(from_location: LocationData, to_location_id: String) -> void:
	if not from_location.location_next_location_ids.has(to_location_id):
		from_location.location_next_location_ids.append(to_location_id)

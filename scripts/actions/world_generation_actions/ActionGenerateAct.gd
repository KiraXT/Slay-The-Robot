## Generates the world map for an act. This is called at the start of a run and end of an act.
## See: ActionGenerator.generate_act() and generate_next_act()
## Changing this script and its params should be sufficient for most use cases,
## however you can supply different scripts to an ActData.act_action_script_path if you need multiple
## generation algorithms.
extends BaseAction

const MAP_CENTER_X := 400.0
const GRID_SPACING := 100.0
const DEFAULT_MIN_LOCATIONS_PER_FLOOR := 3
const DEFAULT_MAX_LOCATIONS_PER_FLOOR := 5
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
		var previous_floor_count: int = -1
		for k in floors_per_act:
			var current_floor: Array[LocationData] = []
			floor_counter += 1
			var current_floor_count: int = rng_world_generation.randi_range(min_locations_per_floor, max_locations_per_floor)
			if k > 0 and min_locations_per_floor < max_locations_per_floor and current_floor_count == previous_floor_count:
				current_floor_count += 1
				if current_floor_count > max_locations_per_floor:
					current_floor_count = min_locations_per_floor
			previous_floor_count = current_floor_count

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
				location_position = _get_location_position(i, current_floor_count, k, bottom_y)
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


func _get_location_position(location_index: int, floor_location_count: int, floor_index: int, bottom_y: float) -> Vector2:
	var center_offset := (float(location_index) - (float(floor_location_count - 1) / 2.0)) * GRID_SPACING
	return Vector2(MAP_CENTER_X + center_offset, bottom_y - (float(floor_index) * GRID_SPACING))


func _connect_floors(previous_floor: Array[LocationData], current_floor: Array[LocationData], rng_world_generation: RandomNumberGenerator) -> void:
	if previous_floor.is_empty() or current_floor.is_empty():
		return

	if previous_floor.size() == 1:
		for location in current_floor:
			_connect_locations(previous_floor[0], location.location_id)
		return

	for previous_location in previous_floor:
		var candidate_locations := _get_locations_sorted_by_horizontal_distance(previous_location.location_position.x, current_floor)
		var route_count: int = rng_world_generation.randi_range(1, min(2, candidate_locations.size()))
		for route_index in route_count:
			_connect_locations(previous_location, candidate_locations[route_index].location_id)

	for location in current_floor:
		if _has_incoming_route(previous_floor, location.location_id):
			continue
		var candidate_previous_locations := _get_locations_sorted_by_horizontal_distance(location.location_position.x, previous_floor)
		_connect_locations(candidate_previous_locations[0], location.location_id)


func _get_locations_sorted_by_horizontal_distance(origin_x: float, locations: Array[LocationData]) -> Array:
	var sorted_locations: Array = locations.duplicate()
	sorted_locations.sort_custom(func(a: LocationData, b: LocationData): return abs(a.location_position.x - origin_x) < abs(b.location_position.x - origin_x))
	return sorted_locations


func _has_incoming_route(previous_floor: Array[LocationData], location_id: String) -> bool:
	for previous_location in previous_floor:
		if previous_location.location_next_location_ids.has(location_id):
			return true
	return false


func _connect_locations(from_location: LocationData, to_location_id: String) -> void:
	if not from_location.location_next_location_ids.has(to_location_id):
		from_location.location_next_location_ids.append(to_location_id)

extends SceneTree

const CANVAS_SIZE := Vector2(1200.0, 700.0)
const ACT_ID := "act_1"
const PLAYER_ID := "player_red"
const TEST_SEED := 20260705
const LOCATION_TYPES := {
	"STARTING": 0,
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	_check_map_layout(root_scene)
	await _check_map_content(root_scene)

	root_scene.queue_free()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_map_layout(root_scene: Node) -> void:
	var map: Control = root_scene.get_node("RunScreen/Map")
	var scroll_container := map.get_node_or_null("ScrollContainer") as Control
	var legend_panel := map.get_node_or_null("LegendPanel") as Control
	var back_button := map.get_node_or_null("BackButton") as Control

	if scroll_container == null:
		failures.append("Map scroll container is missing")
		return
	if legend_panel == null:
		failures.append("Map legend panel is missing")
		return
	if back_button == null:
		failures.append("Map back button is missing")
		return

	_assert_rect_inside_canvas(scroll_container, "Map scroll container")
	_assert_rect_inside_canvas(legend_panel, "Map legend panel")
	_assert_rect_inside_canvas(back_button, "Map back button")
	_assert_no_overlap(scroll_container, legend_panel, "Map scroll container", "Map legend panel")
	_assert_no_overlap(back_button, legend_panel, "Map back button", "Map legend panel")

	if legend_panel.get_child_count() != 7:
		failures.append("Map legend should contain 7 entries, got %s" % legend_panel.get_child_count())

	for child in legend_panel.get_children():
		var row := child as Control
		if row == null:
			failures.append("Map legend contains a non-Control child")
			continue
		if not row.has_node("Icon"):
			failures.append("%s is missing Icon" % row.name)
		if not row.has_node("NameLabel"):
			failures.append("%s is missing NameLabel" % row.name)


func _check_map_content(root_scene: Node) -> void:
	var game_global: Node = root.get_node("Global")
	var action_generator: Node = root.get_node("ActionGenerator")
	var previous_player_data: Variant = game_global.player_data

	game_global.player_data = game_global.get_player_data_from_prototype(PLAYER_ID)
	game_global.player_data.player_run_seed = TEST_SEED
	game_global.player_data.player_act = 1
	game_global.player_data.player_act_id = ACT_ID
	game_global.player_data.player_location_id = "location_0"
	game_global.player_data.player_rng.clear()
	action_generator.generate_act(ACT_ID, 1)

	var locations: Array = game_global.get_all_act_locations()
	var map = root_scene.get_node("RunScreen/Map")
	map.populate_locations(locations)
	await process_frame
	await process_frame

	var location_container := map.get_node("ScrollContainer/LocationContainer") as Control
	var route_layer := location_container.get_node_or_null("RouteLayer") as Control
	if route_layer == null:
		failures.append("Map should create a RouteLayer behind map locations")
	else:
		if location_container.get_child_count() == 0 or location_container.get_child(0) != route_layer:
			failures.append("RouteLayer should be the first map child so routes render behind locations")
		var route_segments: Variant = route_layer.get("route_segments")
		if not route_segments is Array:
			failures.append("RouteLayer should expose generated route_segments for regression checks")
		elif route_segments.size() != _count_route_segments(locations):
			failures.append("RouteLayer should draw %s routes, got %s" % [
				_count_route_segments(locations),
				route_segments.size(),
			])
		else:
			_assert_route_layer_uses_bent_paths(route_layer, route_segments)

	if _find_map_location(location_container, LOCATION_TYPES.STARTING) == null:
		failures.append("Map should display the generated starting location")

	game_global.player_data = previous_player_data


func _assert_rect_inside_canvas(control: Control, label: String) -> void:
	var rect := control.get_global_rect()
	if rect.position.x < 0.0 or rect.position.y < 0.0:
		failures.append("%s starts outside the canvas: %s" % [label, rect])
	if rect.position.x + rect.size.x > CANVAS_SIZE.x:
		failures.append("%s extends past canvas width: %s" % [label, rect])
	if rect.position.y + rect.size.y > CANVAS_SIZE.y:
		failures.append("%s extends past canvas height: %s" % [label, rect])


func _assert_no_overlap(first: Control, second: Control, first_label: String, second_label: String) -> void:
	if first.get_global_rect().intersects(second.get_global_rect()):
		failures.append("%s overlaps %s" % [first_label, second_label])


func _count_route_segments(locations: Array) -> int:
	var route_count := 0
	for location in locations:
		route_count += location.location_next_location_ids.size()
	return route_count


func _assert_route_layer_uses_bent_paths(route_layer: Control, route_segments: Array) -> void:
	if not route_layer.has_method("get_route_points"):
		failures.append("RouteLayer should expose get_route_points for bent route drawing")
		return
	for segment in route_segments:
		var from_position: Vector2 = segment.get("from", Vector2.ZERO)
		var to_position: Vector2 = segment.get("to", Vector2.ZERO)
		if from_position.distance_to(to_position) <= 0.0:
			continue
		var points: Variant = route_layer.call("get_route_points", from_position, to_position)
		if not points is Array:
			failures.append("RouteLayer.get_route_points should return an Array")
			return
		if points.size() < 3:
			failures.append("Bent route should contain at least 3 sampled points, got %s" % points.size())
			return
		if _has_point_off_straight_line(points, from_position, to_position):
			return
	failures.append("Expected at least one rendered route to bend away from a straight line")


func _has_point_off_straight_line(points: Array, from_position: Vector2, to_position: Vector2) -> bool:
	var line_delta := to_position - from_position
	var line_length := line_delta.length()
	if line_length <= 0.0:
		return false
	for point in points:
		var distance: float = abs(line_delta.cross(point - from_position)) / line_length
		if distance > 2.0:
			return true
	return false


func _find_map_location(location_container: Control, location_type: int):
	for child in location_container.get_children():
		var location_data: Variant = child.get("location_data")
		if location_data != null and location_data.location_type == location_type:
			return child
	return null

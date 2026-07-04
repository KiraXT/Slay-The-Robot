extends SceneTree

const LOCATION_TYPES := {
	"COMBAT": 1,
	"MINIBOSS": 2,
	"BOSS": 3,
	"EVENT": 4,
	"TREASURE": 5,
	"SHOP": 6,
	"REST_SITE": 7,
}
const EXPECTED_TEXTURES := {
	LOCATION_TYPES.COMBAT: "external/sprites/ui/map_locations/map_location_combat.png",
	LOCATION_TYPES.EVENT: "external/sprites/ui/map_locations/map_location_event.png",
	LOCATION_TYPES.SHOP: "external/sprites/ui/map_locations/map_location_shop.png",
	LOCATION_TYPES.MINIBOSS: "external/sprites/ui/map_locations/map_location_miniboss.png",
	LOCATION_TYPES.BOSS: "external/sprites/ui/map_locations/map_location_boss.png",
	LOCATION_TYPES.REST_SITE: "external/sprites/ui/map_locations/map_location_rest_site.png",
	LOCATION_TYPES.TREASURE: "external/sprites/ui/map_locations/map_location_treasure.png",
}
const UNKNOWN_TEXTURE := "external/sprites/ui/map_locations/map_location_unknown.png"
const LOCATION_DATA_SCRIPT := "res://data/mutable/LocationData.gd"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("Global")

	await _assert_scene_has_no_static_texture()

	for location_type in EXPECTED_TEXTURES.keys():
		await _assert_location_texture(location_type, EXPECTED_TEXTURES[location_type])

	await _assert_obfuscated_event_uses_event_texture()
	await _assert_obfuscated_location_uses_unknown_texture()
	await _assert_map_label_removed()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _assert_location_texture(location_type: int, expected_path: String) -> void:
	var map_location = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame

	var location_data = _create_location_data()
	location_data.location_type = location_type
	location_data.location_position = Vector2(40, 40)
	map_location.init(location_data)

	_assert_texture_path(map_location.texture_normal, expected_path, _get_location_type_label(location_type))
	map_location.queue_free()
	await process_frame


func _assert_obfuscated_location_uses_unknown_texture() -> void:
	var map_location = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame

	var location_data = _create_location_data()
	location_data.location_type = LOCATION_TYPES.BOSS
	location_data.location_obfuscated = true
	location_data.location_visited = false
	map_location.init(location_data)

	_assert_texture_path(map_location.texture_normal, UNKNOWN_TEXTURE, "obfuscated location")
	map_location.queue_free()
	await process_frame


func _assert_obfuscated_event_uses_event_texture() -> void:
	var map_location = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame

	var location_data = _create_location_data()
	location_data.location_type = LOCATION_TYPES.EVENT
	location_data.location_obfuscated = true
	location_data.location_visited = false
	map_location.init(location_data)

	_assert_texture_path(map_location.texture_normal, EXPECTED_TEXTURES[LOCATION_TYPES.EVENT], "obfuscated event")
	map_location.queue_free()
	await process_frame


func _assert_map_label_removed() -> void:
	var map_location = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame
	if map_location.has_node("MapLabel"):
		failures.append("MapLocation should not keep the old MapLabel node")
	map_location.queue_free()
	await process_frame


func _assert_scene_has_no_static_texture() -> void:
	var map_location = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame
	if map_location.texture_normal != null:
		failures.append("MapLocation scene should not bind a static texture before init")
	map_location.queue_free()
	await process_frame


func _assert_texture_path(texture: Texture2D, expected_path: String, label: String) -> void:
	if texture == null:
		failures.append("%s has no texture" % label)
		return
	if not texture.resource_path.ends_with(expected_path):
		failures.append("%s texture should end with %s, got %s" % [label, expected_path, texture.resource_path])


func _create_location_data():
	var script: Script = load(LOCATION_DATA_SCRIPT)
	return script.new()


func _get_location_type_label(location_type: int) -> String:
	for label in LOCATION_TYPES.keys():
		if LOCATION_TYPES[label] == location_type:
			return label
	return "unknown type %s" % location_type

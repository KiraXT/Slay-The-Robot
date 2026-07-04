extends TextureButton
class_name MapLocation

const FALLBACK_TEXTURE_PATH := "sprites/ui/flipper/icon_map.png"
const UNKNOWN_TEXTURE_PATH := "external/sprites/ui/map_locations/map_location_unknown.png"
const LOCATION_TYPE_TO_TEXTURE_PATH := {
	LocationData.LOCATION_TYPES.COMBAT: "external/sprites/ui/map_locations/map_location_combat.png",
	LocationData.LOCATION_TYPES.EVENT: "external/sprites/ui/map_locations/map_location_event.png",
	LocationData.LOCATION_TYPES.SHOP: "external/sprites/ui/map_locations/map_location_shop.png",
	LocationData.LOCATION_TYPES.MINIBOSS: "external/sprites/ui/map_locations/map_location_miniboss.png",
	LocationData.LOCATION_TYPES.BOSS: "external/sprites/ui/map_locations/map_location_boss.png",
	LocationData.LOCATION_TYPES.REST_SITE: "external/sprites/ui/map_locations/map_location_rest_site.png",
	LocationData.LOCATION_TYPES.TREASURE: "external/sprites/ui/map_locations/map_location_treasure.png",
}

var location_data: LocationData = null
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal map_location_button_up(map_location: MapLocation)


func _ready():
	button_up.connect(_on_button_up)


func init(_location_data: LocationData):
	location_data = _location_data
	position = location_data.location_position
	texture_normal = _load_location_texture(get_location_texture_path(location_data))


static func get_location_texture_path(_location_data: LocationData) -> String:
	if _location_data.location_obfuscated and not _location_data.location_visited:
		return UNKNOWN_TEXTURE_PATH
	return LOCATION_TYPE_TO_TEXTURE_PATH.get(_location_data.location_type, UNKNOWN_TEXTURE_PATH)


func flash_location() -> void:
	animation_player.play("flash_map_location")


func _load_location_texture(texture_path: String) -> Texture2D:
	var texture: Texture2D = FileLoader.load_texture(texture_path)
	if texture.resource_path == "":
		texture = FileLoader.load_texture(FALLBACK_TEXTURE_PATH)
	return texture


func _on_button_up():
	location_data.location_visited = true
	map_location_button_up.emit(self)

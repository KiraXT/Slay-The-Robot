extends Control
class_name MenuBackdrop

const TITLE_LAYER_PATHS := {
	"Sky": "external/sprites/ui/title_screen/title_sky.png",
	"FarIslands": "external/sprites/ui/title_screen/title_far_islands.png",
	"MidRuins": "external/sprites/ui/title_screen/title_mid_ruins.png",
	"Platform": "external/sprites/ui/title_screen/title_platform.png",
	"Foreground": "external/sprites/ui/title_screen/title_foreground.png",
}

var active_background_index := 0
var background_tween: Tween
var idle_tween: Tween
var far_islands_rest_position := Vector2.ZERO
var mid_ruins_rest_position := Vector2.ZERO

@onready var background_layers: Array[TextureRect] = [$CharacterBackgroundA, $CharacterBackgroundB]


func _ready() -> void:
	load_title_layers()
	preload_character_backgrounds()
	start_idle_motion()


func load_title_layers() -> void:
	for node_name: String in TITLE_LAYER_PATHS:
		var layer: TextureRect = get_node(node_name)
		layer.texture = _load_optional_texture(TITLE_LAYER_PATHS[node_name])
		layer.visible = layer.texture.get_size() != Vector2.ZERO
	$FallbackSky.visible = not $Sky.visible
	far_islands_rest_position = $FarIslands.position
	mid_ruins_rest_position = $MidRuins.position


func preload_character_backgrounds() -> void:
	for character_id: String in Global._id_to_character_data:
		var character_data: CharacterData = Global.get_character_data(character_id)
		if character_data != null and _texture_file_exists(character_data.character_background_texture_path):
			FileLoader.load_texture(character_data.character_background_texture_path)


func set_character_background(path: String, immediate: bool = false) -> void:
	var current: TextureRect = background_layers[active_background_index]
	var target_index := 1 - active_background_index
	var target: TextureRect = background_layers[target_index]
	var texture: Texture2D = _load_optional_texture(path) if not path.is_empty() else $Platform.texture
	if texture == null or texture.get_size() == Vector2.ZERO:
		texture = $Platform.texture
	target.texture = texture
	if immediate:
		current.modulate.a = 0.0
		target.modulate.a = 1.0
		active_background_index = target_index
		return
	if background_tween != null and background_tween.is_valid():
		background_tween.kill()
	target.modulate.a = 0.0
	background_tween = create_tween().set_parallel(true)
	background_tween.tween_property(current, "modulate:a", 0.0, 0.22)
	background_tween.tween_property(target, "modulate:a", 1.0, 0.22)
	background_tween.tween_callback(_finish_background_swap.bind(target_index)).set_delay(0.22)


func start_idle_motion() -> void:
	if idle_tween != null and idle_tween.is_valid():
		return
	idle_tween = create_tween().set_loops()
	idle_tween.set_parallel(true)
	idle_tween.tween_property($FarIslands, "position:y", far_islands_rest_position.y - 3.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property($MidRuins, "position:y", mid_ruins_rest_position.y + 2.0, 2.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.chain().set_parallel(true)
	idle_tween.tween_property($FarIslands, "position:y", far_islands_rest_position.y, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property($MidRuins, "position:y", mid_ruins_rest_position.y, 2.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_idle_motion() -> void:
	if idle_tween != null and idle_tween.is_valid():
		idle_tween.kill()
	idle_tween = null
	$FarIslands.position = far_islands_rest_position
	$MidRuins.position = mid_ruins_rest_position


func _finish_background_swap(target_index: int) -> void:
	active_background_index = target_index
	background_tween = null


func _load_optional_texture(path: String) -> Texture2D:
	if not _texture_file_exists(path):
		return ImageTexture.new()
	return FileLoader.load_texture(path)


func _texture_file_exists(path: String) -> bool:
	return not path.is_empty() and FileAccess.file_exists(FileLoader._get_modified_filepath(path))

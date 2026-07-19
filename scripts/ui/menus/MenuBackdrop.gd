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
var idle_motion_enabled := false
var idle_time := 0.0
var far_origin := Vector2.ZERO
var mid_origin := Vector2.ZERO
var foreground_origin := Vector2.ZERO

@onready var background_layers: Array[TextureRect] = [$CharacterBackgroundA, $CharacterBackgroundB]
@onready var confirm_particles: CPUParticles2D = $ConfirmParticles


func _ready() -> void:
	far_origin = $FarIslands.position
	mid_origin = $MidRuins.position
	foreground_origin = $Foreground.position
	load_title_layers()
	preload_character_backgrounds()


func _process(delta: float) -> void:
	if not idle_motion_enabled:
		return
	idle_time += delta
	$FarIslands.position = far_origin + Vector2(sin(idle_time * 0.22) * 12.0, cos(idle_time * 0.16) * 2.0)
	$MidRuins.position = mid_origin + Vector2(sin(idle_time * 0.31) * 8.0, cos(idle_time * 0.21) * 2.0)
	$Foreground.position = foreground_origin + Vector2(sin(idle_time * 0.45) * 5.0, 0.0)


func load_title_layers() -> void:
	for node_name: String in TITLE_LAYER_PATHS:
		var layer: TextureRect = get_node(node_name)
		layer.texture = _load_optional_title_layer(TITLE_LAYER_PATHS[node_name])
		layer.visible = layer.texture.get_size() != Vector2.ZERO
	$FallbackSky.visible = not $Sky.visible


func preload_character_backgrounds() -> void:
	for character_id: String in Global._id_to_character_data:
		var character_data: CharacterData = Global.get_character_data(character_id)
		if character_data != null:
			FileLoader.load_texture_or_fallback(character_data.character_background_texture_path, "background")


func set_character_background(path: String, immediate: bool = false) -> void:
	var current: TextureRect = background_layers[active_background_index]
	var target_index := 1 - active_background_index
	var target: TextureRect = background_layers[target_index]
	var texture := _load_character_background(path)
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
	idle_motion_enabled = true
	_set_particle_state($AmbientParticles, true, 24)


func stop_idle_motion() -> void:
	idle_motion_enabled = false
	_set_particle_state($AmbientParticles, false, 24)
	$FarIslands.position = far_origin
	$MidRuins.position = mid_origin
	$Foreground.position = foreground_origin


func play_confirm_particles() -> void:
	_set_particle_state(confirm_particles, false, 16)
	confirm_particles.restart()
	_set_particle_state(confirm_particles, true, 16)


func stop_confirm_particles() -> void:
	_set_particle_state(confirm_particles, false, 16)


func _set_particle_state(node: Node, active: bool, amount: int) -> void:
	if node is GPUParticles2D or node is CPUParticles2D:
		node.amount = amount
		node.emitting = active


func _finish_background_swap(target_index: int) -> void:
	active_background_index = target_index
	background_tween = null


func _load_optional_title_layer(path: String) -> Texture2D:
	return _load_existing_texture(path)


func _load_character_background(path: String) -> Texture2D:
	return _load_first_available_texture([path], "background")


func _load_first_available_texture(paths: Array[String], fallback_type: String) -> Texture2D:
	for path: String in paths:
		var texture := _load_existing_texture(path)
		if texture != null and texture.get_size() != Vector2.ZERO:
			return texture
	return FileLoader.load_texture_or_fallback("", fallback_type)


func _load_existing_texture(path: String) -> Texture2D:
	if not _texture_file_exists(path):
		return ImageTexture.new()
	return FileLoader.load_texture(path)


func _texture_file_exists(path: String) -> bool:
	return not path.strip_edges().is_empty() and FileAccess.file_exists(FileLoader._get_modified_filepath(path))

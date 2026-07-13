extends SceneTree

const TITLE_ASSETS := {
	"external/sprites/ui/title_screen/title_sky.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_far_islands.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_mid_ruins.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_platform.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_foreground.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/title_ornament.png": Vector2i(1200, 700),
	"external/sprites/ui/title_screen/particle_soft.png": Vector2i(64, 64),
	"external/sprites/ui/title_screen/particle_spark.png": Vector2i(64, 64),
}
const CHARACTER_IDS := ["character_red", "character_blue", "character_green", "character_orange"]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_global := root.get_node("Global")
	for path: String in TITLE_ASSETS:
		_check_image(path, TITLE_ASSETS[path])
	for character_id: String in CHARACTER_IDS:
		var data = game_global.get_character_data(character_id)
		if data == null or data.character_background_texture_path.is_empty():
			failures.append("%s has no character background path" % character_id)
		else:
			_check_image(data.character_background_texture_path, Vector2i(1200, 700))
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

func _check_image(path: String, expected_size: Vector2i) -> void:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % path)
	if not FileAccess.file_exists(absolute_path):
		failures.append("Missing image: %s" % path)
		return
	var image := Image.load_from_file(absolute_path)
	if image == null or image.get_size() != expected_size:
		failures.append("%s must be %s" % [path, expected_size])

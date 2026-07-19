extends SceneTree

const CHARACTER_COMBAT_PATHS := [
	"external/sprites/characters/character_red/character_red.png",
	"external/sprites/characters/character_blue/character_blue.png",
	"external/sprites/characters/character_green/character_green.png",
	"external/sprites/characters/character_orange/character_orange.png",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path: String in CHARACTER_COMBAT_PATHS:
		if not _clean_image(path):
			quit(1)
			return
	print("CHARACTER_CHROMA_KEY_CLEANED")
	quit(0)


func _clean_image(path: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % path)
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		push_error("Cannot load character image: %s" % path)
		return false

	var changed_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if _is_chroma_green_rgb_residue(color):
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				changed_pixels += 1

	var result := image.save_png(absolute_path)
	if result != OK:
		push_error("Cannot save cleaned character image: %s" % path)
		return false
	print("%s cleaned %s chroma green RGB residue pixels" % [path, changed_pixels])
	return true


func _is_chroma_green_rgb_residue(color: Color) -> bool:
	return color.g > 0.86 and color.r < 0.22 and color.b < 0.22

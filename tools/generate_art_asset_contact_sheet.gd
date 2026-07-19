extends SceneTree

const OUTPUT_DIR := "designer/art_source/contact_sheets"
const OUTPUT_PATH := "designer/art_source/contact_sheets/phase-0-character-contract.png"
const CHARACTER_COMBAT_PATHS := [
	"external/sprites/characters/character_red/character_red.png",
	"external/sprites/characters/character_blue/character_blue.png",
	"external/sprites/characters/character_green/character_green.png",
	"external/sprites/characters/character_orange/character_orange.png",
]

const TILE_SIZE := Vector2i(260, 324)
const DISPLAY_SIZE := Vector2i(160, 220)
const THUMB_64 := Vector2i(64, 64)
const THUMB_32 := Vector2i(32, 32)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUTPUT_DIR))
	var sheet := Image.create(TILE_SIZE.x * CHARACTER_COMBAT_PATHS.size(), TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.10, 0.12, 1.0))

	for index in range(CHARACTER_COMBAT_PATHS.size()):
		var path: String = CHARACTER_COMBAT_PATHS[index]
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://%s" % path))
		if image == null or image.is_empty():
			push_error("Cannot load contact sheet source: %s" % path)
			quit(1)
			return
		_draw_character_tile(sheet, image, index)

	var result := sheet.save_png(ProjectSettings.globalize_path("res://%s" % OUTPUT_PATH))
	if result != OK:
		push_error("Cannot save contact sheet: %s" % OUTPUT_PATH)
		quit(1)
		return
	print("CONTACT_SHEET_GENERATED:%s" % OUTPUT_PATH)
	quit(0)


func _draw_character_tile(sheet: Image, source: Image, index: int) -> void:
	var tile_origin := Vector2i(TILE_SIZE.x * index, 0)
	_draw_rect(sheet, Rect2i(tile_origin + Vector2i(8, 8), TILE_SIZE - Vector2i(16, 16)), Color(0.94, 0.98, 1.0, 1.0))
	_draw_rect(sheet, Rect2i(tile_origin + Vector2i(8, 8), Vector2i(TILE_SIZE.x - 16, 4)), Color(0.18, 0.66, 0.82, 1.0))

	var cropped := _crop_to_used_rect(source)
	var display := _fit_image(cropped, DISPLAY_SIZE)
	var display_pos := tile_origin + Vector2i((TILE_SIZE.x - display.get_width()) / 2, 24)
	_draw_image_alpha(sheet, display, display_pos)

	var thumb64 := _fit_image(cropped, THUMB_64)
	var thumb32 := _fit_image(cropped, THUMB_32)
	_draw_image_alpha(sheet, thumb64, tile_origin + Vector2i(72, 252))
	_draw_image_alpha(sheet, thumb32, tile_origin + Vector2i(154, 268))


func _crop_to_used_rect(image: Image) -> Image:
	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return image.duplicate()
	return image.get_region(used_rect)


func _fit_image(image: Image, max_size: Vector2i) -> Image:
	var fitted := image.duplicate()
	var ratio: float = minf(float(max_size.x) / float(fitted.get_width()), float(max_size.y) / float(fitted.get_height()))
	var target_size := Vector2i(max(1, roundi(fitted.get_width() * ratio)), max(1, roundi(fitted.get_height() * ratio)))
	fitted.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	return fitted


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_image_alpha(target: Image, source: Image, position: Vector2i) -> void:
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var target_position := position + Vector2i(x, y)
			if target_position.x < 0 or target_position.y < 0 or target_position.x >= target.get_width() or target_position.y >= target.get_height():
				continue
			var source_color := source.get_pixel(x, y)
			if source_color.a <= 0.001:
				continue
			var base_color := target.get_pixel(target_position.x, target_position.y)
			var alpha := source_color.a
			var blended := Color(
				source_color.r * alpha + base_color.r * (1.0 - alpha),
				source_color.g * alpha + base_color.g * (1.0 - alpha),
				source_color.b * alpha + base_color.b * (1.0 - alpha),
				1.0
			)
			target.set_pixel(target_position.x, target_position.y, blended)

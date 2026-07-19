extends SceneTree

const OUTPUT_DIR := "designer/art_source/contact_sheets"
const OUTPUT_PATH := "designer/art_source/contact_sheets/phase-0-character-contract.png"
const CHARACTER_COMBAT_PATHS := [
	"external/sprites/characters/character_red/character_red.png",
	"external/sprites/characters/character_blue/character_blue.png",
	"external/sprites/characters/character_green/character_green.png",
	"external/sprites/characters/character_orange/character_orange.png",
]

const TILE_SIZE := Vector2i(320, 400)
const SOURCE_PREVIEW_SIZE := Vector2i(120, 200)
const DISPLAY_SIZE := Vector2i(120, 200)
const THUMB_64 := Vector2i(64, 64)
const THUMB_32 := Vector2i(32, 32)
const TILE_BACKGROUND := Color(0.82, 0.87, 0.92, 1.0)
const DARK_SWATCH := Color(0.10, 0.13, 0.17, 1.0)
const LIGHT_SWATCH := Color(0.95, 0.97, 1.0, 1.0)
const ACCENT_COLOR := Color(0.18, 0.66, 0.82, 1.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUTPUT_DIR))
	var sheet := Image.create(TILE_SIZE.x * CHARACTER_COMBAT_PATHS.size(), TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	sheet.fill(TILE_BACKGROUND)

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
	_draw_rect(sheet, Rect2i(tile_origin + Vector2i(8, 8), TILE_SIZE - Vector2i(16, 16)), Color(0.88, 0.92, 0.96, 1.0))
	_draw_rect(sheet, Rect2i(tile_origin + Vector2i(8, 8), Vector2i(TILE_SIZE.x - 16, 4)), ACCENT_COLOR)

	# The first preview preserves the source canvas; the second mirrors the in-game cropped display.
	_draw_preview(sheet, source, tile_origin + Vector2i(16, 16), Vector2i(136, 220), DARK_SWATCH, SOURCE_PREVIEW_SIZE)
	var cropped := _crop_to_used_rect(source)
	_draw_preview(sheet, cropped, tile_origin + Vector2i(168, 16), Vector2i(136, 220), LIGHT_SWATCH, DISPLAY_SIZE)
	_draw_preview(sheet, cropped, tile_origin + Vector2i(16, 252), Vector2i(96, 72), DARK_SWATCH, THUMB_64)
	_draw_preview(sheet, cropped, tile_origin + Vector2i(120, 252), Vector2i(96, 72), LIGHT_SWATCH, THUMB_64)
	_draw_preview(sheet, cropped, tile_origin + Vector2i(72, 340), Vector2i(80, 44), DARK_SWATCH, THUMB_32)
	_draw_preview(sheet, cropped, tile_origin + Vector2i(184, 340), Vector2i(80, 44), LIGHT_SWATCH, THUMB_32)


func _draw_preview(sheet: Image, source: Image, position: Vector2i, swatch_size: Vector2i, background: Color, preview_size: Vector2i) -> void:
	_draw_rect(sheet, Rect2i(position, swatch_size), background)
	var preview := _fit_image(source, preview_size)
	var preview_position := position + Vector2i(
		(swatch_size.x - preview.get_width()) / 2,
		(swatch_size.y - preview.get_height()) / 2
	)
	_draw_image_alpha(sheet, preview, preview_position)


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

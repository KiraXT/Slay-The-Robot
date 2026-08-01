extends SceneTree

const GLOW_PATH := "external/sprites/ui/card_styles/preview/shared/glow.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path("res://" + GLOW_PATH)
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		push_error("Could not load shared card glow: %s" % GLOW_PATH)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	var transparent_pixels := 0
	var edge_pixels := 0
	for y in image.get_height():
		for x in image.get_width():
			var color: Color = image.get_pixel(x, y)
			if color.a <= 0.05 and color.g > maxf(color.r, color.b) + 0.06:
				# A neutral transparent texel preserves the white/purple glow when filtered.
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.0))
				transparent_pixels += 1
			elif color.a > 0.05 and color.s > 0.25 and color.h > 0.28 and color.h < 0.62:
				# The intended glow is white/purple; preserve alpha while neutralizing chroma-key fringe.
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, color.a))
				edge_pixels += 1
	if image.save_png(absolute_path) != OK:
		push_error("Could not save shared card glow: %s" % GLOW_PATH)
		quit(1)
		return
	print("CARD_GLOW_CHROMA_CLEANED transparent=%d edge=%d" % [transparent_pixels, edge_pixels])
	quit(0)

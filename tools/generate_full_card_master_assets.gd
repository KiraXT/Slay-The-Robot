extends SceneTree

const SOURCE_PATH := "designer/art_source/card_styles/full_master_v1/card_master_chroma.png"
const OUTPUT_DIR := "external/sprites/ui/card_styles/full_master"
const MASTER_SIZE := Vector2i(576, 808)
const RIBBON_SOURCE_RECT := Rect2i(358, 874, 358, 94)
const RIBBON_SIZE := Vector2i(192, 56)

const MASTER_VARIANTS := {
	"card_master_red.png": {"hue": 0.99, "saturation": 0.95},
	"card_master_blue.png": {"hue": 0.59, "saturation": 0.95},
	"card_master_green.png": {"hue": 0.36, "saturation": 0.90},
	"card_master_gold.png": {"hue": 0.11, "saturation": 0.95},
	"card_master_silver.png": {"hue": 0.0, "saturation": 0.14, "silver": true},
}

const RIBBON_VARIANTS := {
	"ribbon_attack.png": {"hue": 0.01, "saturation": 1.0},
	"ribbon_skill.png": {"hue": 0.35, "saturation": 0.95},
	"ribbon_power.png": {"hue": 0.56, "saturation": 0.92},
	"ribbon_status.png": {"hue": 0.0, "saturation": 0.10},
	"ribbon_curse.png": {"hue": 0.78, "saturation": 0.95},
}


func _init() -> void:
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path("res://" + SOURCE_PATH))
	if source == null or source.is_empty():
		push_error("Unable to load full-card chroma master: %s" % SOURCE_PATH)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + OUTPUT_DIR + "/ribbons"))
	var transparent_master: Image = _remove_chroma(source)
	if not _save_master_variants(transparent_master):
		quit(1)
		return
	if not _save_ribbon_variants(source):
		quit(1)
		return

	print("FULL_CARD_MASTER_ASSETS_GENERATED")
	quit(0)


func _save_master_variants(source: Image) -> bool:
	for file_name: String in MASTER_VARIANTS:
		var variant: Image = _remap_purple(source, MASTER_VARIANTS[file_name])
		variant.resize(MASTER_SIZE.x, MASTER_SIZE.y, Image.INTERPOLATE_LANCZOS)
		if not _validate_master_transparency(variant, file_name):
			return false
		var path := ProjectSettings.globalize_path("res://" + OUTPUT_DIR + "/" + file_name)
		if variant.save_png(path) != OK:
			push_error("Unable to save full-card master: %s" % path)
			return false
	return true


func _save_ribbon_variants(source: Image) -> bool:
	var ribbon: Image = source.get_region(RIBBON_SOURCE_RECT)
	ribbon.convert(Image.FORMAT_RGBA8)
	for y in ribbon.get_height():
			for x in ribbon.get_width():
				var color: Color = ribbon.get_pixel(x, y)
				if _is_chroma_green(color):
					color = _decontaminate_chroma(color)
				elif _is_purple(color):
					color = Color.TRANSPARENT
				ribbon.set_pixel(x, y, color)

	for file_name: String in RIBBON_VARIANTS:
		var variant: Image = _remap_red(ribbon, RIBBON_VARIANTS[file_name])
		variant.resize(RIBBON_SIZE.x, RIBBON_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var path := ProjectSettings.globalize_path("res://" + OUTPUT_DIR + "/ribbons/" + file_name)
		if variant.save_png(path) != OK:
			push_error("Unable to save full-card ribbon: %s" % path)
			return false
	return true


func _remove_chroma(source: Image) -> Image:
	var result: Image = source.duplicate()
	for y in result.get_height():
		for x in result.get_width():
			var color: Color = result.get_pixel(x, y)
			if _is_chroma_green(color):
				color = _decontaminate_chroma(color)
			result.set_pixel(x, y, color)
	return result


func _remap_purple(source: Image, settings: Dictionary) -> Image:
	var result: Image = source.duplicate()
	var target_hue := float(settings["hue"])
	var saturation_scale := float(settings["saturation"])
	var make_silver := bool(settings.get("silver", false))
	for y in result.get_height():
		for x in result.get_width():
			var color: Color = result.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if _is_purple(color):
				var relative_hue: float = wrapf(color.h - 0.77, -0.5, 0.5)
				var saturation: float = color.s * saturation_scale
				var value: float = color.v
				if make_silver:
					saturation = minf(saturation, 0.14)
					value = minf(1.0, lerpf(value, value * 1.12, 0.45))
				result.set_pixel(
					x,
					y,
					Color.from_hsv(fposmod(target_hue + relative_hue * 0.18, 1.0), saturation, value, color.a)
				)
			elif color.s > 0.30 and (color.h < 0.14 or color.h > 0.94):
				var accent_saturation := color.s * saturation_scale
				var accent_value := color.v
				if make_silver:
					accent_saturation = minf(accent_saturation, 0.10)
					accent_value = minf(1.0, lerpf(accent_value, accent_value * 1.08, 0.35))
				result.set_pixel(x, y, Color.from_hsv(target_hue, accent_saturation, accent_value, color.a))
	return result


func _remap_red(source: Image, settings: Dictionary) -> Image:
	var result: Image = source.duplicate()
	var target_hue := float(settings["hue"])
	var saturation_scale := float(settings["saturation"])
	for y in result.get_height():
		for x in result.get_width():
			var color: Color = result.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if color.s > 0.25 and (color.h < 0.14 or color.h > 0.94):
				var saturation: float = color.s * saturation_scale
				result.set_pixel(x, y, Color.from_hsv(target_hue, saturation, color.v, color.a))
	return result


func _is_chroma_green(color: Color) -> bool:
	return color.g > 0.35 and color.g - maxf(color.r, color.b) > 0.12


func _decontaminate_chroma(color: Color) -> Color:
	var green_delta := color.g - maxf(color.r, color.b)
	var foreground_alpha := 1.0 - smoothstep(0.12, 0.58, green_delta)
	var output_alpha := color.a * foreground_alpha
	if foreground_alpha <= 0.001 or output_alpha <= 0.001:
		return Color.TRANSPARENT

	var removed_green := 1.0 - foreground_alpha
	return Color(
		clampf(color.r / foreground_alpha, 0.0, 1.0),
		clampf((color.g - removed_green) / foreground_alpha, 0.0, 1.0),
		clampf(color.b / foreground_alpha, 0.0, 1.0),
		output_alpha
	)


func _is_purple(color: Color) -> bool:
	return color.s > 0.18 and color.h > 0.67 and color.h < 0.90


func _validate_master_transparency(image: Image, file_name: String) -> bool:
	for point: Vector2i in [Vector2i(4, 404), Vector2i(288, 330)]:
		var alpha := image.get_pixelv(point).a
		if alpha > 0.05:
			push_error("%s retained chroma at %s with alpha %.3f" % [file_name, point, alpha])
			return false
	var ribbon_center := image.get_pixel(288, 503).a
	if ribbon_center <= 0.5:
		push_error("%s lost the reference ribbon body with alpha %.3f" % [file_name, ribbon_center])
		return false
	return true

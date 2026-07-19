extends SceneTree

const OUTPUT_DIR := "external/sprites/fallback"
const SPECS := [
	{"path": "external/sprites/fallback/fallback_card.png", "size": Vector2i(128, 128), "bg": Color(0.96, 0.98, 1.0, 1.0), "border": Color(0.16, 0.66, 0.82, 1.0), "mark": Color(1.0, 0.55, 0.20, 1.0)},
	{"path": "external/sprites/fallback/fallback_character.png", "size": Vector2i(256, 256), "bg": Color(0.94, 0.98, 1.0, 1.0), "border": Color(0.18, 0.55, 0.88, 1.0), "mark": Color(1.0, 0.64, 0.18, 1.0)},
	{"path": "external/sprites/fallback/fallback_enemy.png", "size": Vector2i(256, 256), "bg": Color(0.12, 0.15, 0.18, 1.0), "border": Color(0.95, 0.35, 0.28, 1.0), "mark": Color(1.0, 0.82, 0.26, 1.0)},
	{"path": "external/sprites/fallback/fallback_icon.png", "size": Vector2i(128, 128), "bg": Color(0.98, 0.98, 0.94, 1.0), "border": Color(0.15, 0.62, 0.72, 1.0), "mark": Color(0.24, 0.38, 0.44, 1.0)},
	{"path": "external/sprites/fallback/fallback_background.png", "size": Vector2i(1200, 700), "bg": Color(0.78, 0.96, 0.98, 1.0), "border": Color(0.16, 0.66, 0.82, 1.0), "mark": Color(1.0, 0.66, 0.20, 1.0)},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUTPUT_DIR))
	for spec: Dictionary in SPECS:
		_generate_fallback(spec)
	print("ALL_FALLBACK_ASSETS_GENERATED")
	quit(0)


func _generate_fallback(spec: Dictionary) -> void:
	var size: Vector2i = spec["size"]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(spec["bg"])
	_draw_border(image, spec["border"], max(3, int(min(size.x, size.y) * 0.04)))
	_draw_missing_mark(image, spec["mark"])
	var result: Error = image.save_png(ProjectSettings.globalize_path("res://%s" % spec["path"]))
	if result != OK:
		push_error("Failed to write fallback: %s" % spec["path"])
		quit(1)


func _draw_border(image: Image, color: Color, width: int) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if x < width or y < width or x >= image.get_width() - width or y >= image.get_height() - width:
				image.set_pixel(x, y, color)


func _draw_missing_mark(image: Image, color: Color) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var stroke: int = max(3, int(min(w, h) * 0.035))
	_draw_line(image, Vector2i(int(w * 0.30), int(h * 0.30)), Vector2i(int(w * 0.70), int(h * 0.70)), color, stroke)
	_draw_line(image, Vector2i(int(w * 0.70), int(h * 0.30)), Vector2i(int(w * 0.30), int(h * 0.70)), color, stroke)
	_draw_rect(image, Rect2i(Vector2i(int(w * 0.42), int(h * 0.18)), Vector2i(int(w * 0.16), int(h * 0.16))), color)


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color, width: int) -> void:
	var delta := Vector2(to_point - from_point)
	var length: int = max(1, int(delta.length()))
	for index in range(length + 1):
		var t := float(index) / float(length)
		var point: Vector2 = Vector2(from_point).lerp(Vector2(to_point), t)
		_draw_rect(image, Rect2i(Vector2i(roundi(point.x) - width / 2, roundi(point.y) - width / 2), Vector2i(width, width)), color)

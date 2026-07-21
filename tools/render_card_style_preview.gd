extends SceneTree

const STYLE_DIR := "external/data/card_styles/"
const STYLE_FILE := "card_style_preview.json"
const PREVIEW_PATH := "tmp/card_style_preview/card_style_reference_variants.png"
const CARD_SIZE := Vector2i(144, 184)
const PREVIEW_CASES := [
	{"color": "color_red", "type": "0", "name": "烈焰冲击"},
	{"color": "color_blue", "type": "1", "name": "误打误撞"},
	{"color": "color_green", "type": "2", "name": "生长核心"},
	{"color": "color_orange", "type": "3", "name": "整备姿态"},
	{"color": "color_white", "type": "4", "name": "禁忌回响"},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var file_loader := root.get_node("FileLoader")
	var style_data := file_loader.call("load_json", STYLE_DIR, STYLE_FILE) as Dictionary
	if style_data.is_empty():
		push_error("Missing reference card style data")
		quit(1)
		return

	var canvas := Image.create(840, 250, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.10, 0.12, 0.16, 1.0))
	for index in PREVIEW_CASES.size():
		if not _draw_card(canvas, file_loader, style_data, PREVIEW_CASES[index], Vector2i(20 + index * 164, 34)):
			quit(1)
			return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/card_style_preview"))
	var error := canvas.save_png(ProjectSettings.globalize_path("res://" + PREVIEW_PATH))
	if error != OK:
		push_error("Failed to save preview: %s" % error)
		quit(1)
		return
	print("CARD_STYLE_REFERENCE_PREVIEW_RENDERED: %s" % PREVIEW_PATH)
	quit(0)


func _draw_card(canvas: Image, file_loader: Node, style_data: Dictionary, case_data: Dictionary, origin: Vector2i) -> bool:
	var shared_slots := style_data.get("shared_slots", {}) as Dictionary
	var color_slots := style_data.get("color_slots", {}) as Dictionary
	var type_slots := style_data.get("type_slots", {}) as Dictionary
	var layers := [
		{"path": color_slots.get(case_data["color"], color_slots.get("default", "")), "rect": Rect2i(origin, CARD_SIZE)},
		{"path": shared_slots.get("header_bar", ""), "rect": Rect2i(origin + Vector2i(29, 4), Vector2i(103, 23))},
		{"path": shared_slots.get("art_frame", ""), "rect": Rect2i(origin + Vector2i(11, 27), Vector2i(122, 75))},
		{"path": shared_slots.get("description_panel", ""), "rect": Rect2i(origin + Vector2i(8, 105), Vector2i(128, 75))},
		{"path": type_slots.get(case_data["type"], type_slots.get("default", "")), "rect": Rect2i(origin + Vector2i(20, 96), Vector2i(104, 20))},
		{"path": shared_slots.get("energy_badge", ""), "rect": Rect2i(origin + Vector2i(-8, -8), Vector2i(38, 38))},
	]
	for layer: Dictionary in layers:
		if not _blend_reference_layer(canvas, str(layer["path"]), layer["rect"]):
			push_error("Missing reference layer for %s" % case_data["color"])
			return false
	return true


func _blend_reference_layer(canvas: Image, texture_path: String, target_rect: Rect2i) -> bool:
	if texture_path.is_empty():
		return false
	var absolute_path := ProjectSettings.globalize_path("res://" + texture_path)
	var layer := Image.load_from_file(absolute_path)
	if layer == null or layer.is_empty():
		return false
	layer.convert(Image.FORMAT_RGBA8)
	layer.resize(target_rect.size.x, target_rect.size.y, Image.INTERPOLATE_LANCZOS)
	canvas.blend_rect(layer, Rect2i(Vector2i.ZERO, target_rect.size), target_rect.position)
	return true

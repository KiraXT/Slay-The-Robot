extends SceneTree

const CARD_ART_DIRECTORY := "external/sprites/cards"
const OUTPUT_DIRECTORY := "tmp/card_art_alpha_cleanup"
const MANIFEST_PATH := "tools/card_art_alpha_cleanup_manifest.json"
const CANDIDATE_PIXEL_THRESHOLD := 64
const PREVIEW_TILE_SIZE := Vector2i(132, 132)
const PREVIEW_PAIR_SIZE := Vector2i(286, 148)
const PREVIEW_COLUMNS := 2

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var apply_changes := OS.get_cmdline_user_args().has("--apply")
	var card_paths: Array[String] = []
	_collect_png_paths(CARD_ART_DIRECTORY, card_paths)
	card_paths.sort()
	if card_paths.is_empty():
		failures.append("card art audit found no PNG files")
		_finish()
		return

	var output_root := ProjectSettings.globalize_path("res://" + OUTPUT_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(output_root)
	var candidates: Array[Dictionary] = []
	var previews: Array[Dictionary] = []
	for path: String in card_paths:
		var source := _load_image(path)
		if source == null:
			continue
		var contaminated_pixels := _count_green_edge_pixels(source)
		if contaminated_pixels < CANDIDATE_PIXEL_THRESHOLD:
			continue
		var cleaned := _clean_image(source)
		var remaining_pixels := _count_green_edge_pixels(cleaned)
		var processed_path := _processed_path_for(path)
		if not _save_image(cleaned, processed_path):
			continue
		candidates.append({
			"path": path,
			"contaminated_pixels_before": contaminated_pixels,
			"contaminated_pixels_after": remaining_pixels,
			"processed_preview": processed_path,
		})
		previews.append({"before": source, "after": cleaned})

	_write_candidates(candidates)
	_write_contact_sheet(previews)

	if apply_changes:
		_apply_manifest(candidates)
	else:
		print("CARD_ART_ALPHA_AUDIT_COMPLETE candidates=%d" % candidates.size())
	_finish()


func _apply_manifest(candidates: Array[Dictionary]) -> void:
	var approved_paths := _load_manifest_paths()
	if not failures.is_empty():
		_finish()
		return
	var candidates_by_path := {}
	for candidate: Dictionary in candidates:
		candidates_by_path[candidate["path"]] = candidate
	for path: String in approved_paths:
		if not candidates_by_path.has(path):
			failures.append("manifest path is not a current candidate: %s" % path)
	if not failures.is_empty():
		_finish()
		return
	for path: String in approved_paths:
		var candidate: Dictionary = candidates_by_path[path]
		var source := _load_image(candidate["processed_preview"])
		if source == null:
			continue
		if not _save_image(source, path):
			continue
		print("CARD_ART_ALPHA_APPLIED %s" % path)
	print("CARD_ART_ALPHA_APPLY_COMPLETE applied=%d" % approved_paths.size())
	_finish()


func _load_manifest_paths() -> Array[String]:
	var manifest_absolute_path := ProjectSettings.globalize_path("res://" + MANIFEST_PATH)
	if not FileAccess.file_exists(manifest_absolute_path):
		failures.append("card art alpha cleanup manifest is missing: %s" % MANIFEST_PATH)
		return []
	var file := FileAccess.open(manifest_absolute_path, FileAccess.READ)
	if file == null:
		failures.append("could not read cleanup manifest: %s" % MANIFEST_PATH)
		return []
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		failures.append("cleanup manifest is invalid JSON: %s" % MANIFEST_PATH)
		return []
	var raw_paths = json.data.get("approved_paths", [])
	if not raw_paths is Array:
		failures.append("cleanup manifest approved_paths must be an array")
		return []
	var approved_paths: Array[String] = []
	for value in raw_paths:
		if not value is String or not value.begins_with(CARD_ART_DIRECTORY + "/") or not value.ends_with(".png"):
			failures.append("cleanup manifest contains an invalid card art path: %s" % value)
			continue
		approved_paths.append(value)
	approved_paths.sort()
	return approved_paths


func _write_candidates(candidates: Array[Dictionary]) -> void:
	var output_path := ProjectSettings.globalize_path("res://" + OUTPUT_DIRECTORY + "/candidates.json")
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write candidate list: %s" % output_path)
		return
	file.store_string(JSON.stringify({"candidates": candidates}, "\t") + "\n")


func _write_contact_sheet(previews: Array[Dictionary]) -> void:
	var rows := maxi(1, ceili(float(previews.size()) / PREVIEW_COLUMNS))
	var sheet := Image.create(PREVIEW_COLUMNS * PREVIEW_PAIR_SIZE.x, rows * PREVIEW_PAIR_SIZE.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("20252d"))
	for index in previews.size():
		var pair_origin := Vector2i(index % PREVIEW_COLUMNS, index / PREVIEW_COLUMNS) * PREVIEW_PAIR_SIZE
		var preview: Dictionary = previews[index]
		_blit_preview_tile(sheet, preview["before"], pair_origin)
		_blit_preview_tile(sheet, preview["after"], pair_origin + Vector2i(PREVIEW_TILE_SIZE.x + 14, 0))
	var output_path := ProjectSettings.globalize_path("res://" + OUTPUT_DIRECTORY + "/contact_sheet.png")
	if sheet.save_png(output_path) != OK:
		failures.append("could not write contact sheet: %s" % output_path)


func _blit_preview_tile(sheet: Image, source: Image, origin: Vector2i) -> void:
	_draw_checkerboard(sheet, origin, PREVIEW_TILE_SIZE)
	var preview := source.duplicate()
	preview.resize(PREVIEW_TILE_SIZE.x, PREVIEW_TILE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	sheet.blend_rect(preview, Rect2i(Vector2i.ZERO, PREVIEW_TILE_SIZE), origin)
	_draw_border(sheet, origin, PREVIEW_TILE_SIZE, Color("5e6b78"))


func _draw_checkerboard(image: Image, origin: Vector2i, size: Vector2i) -> void:
	const CELL_SIZE := 12
	for y in range(0, size.y, CELL_SIZE):
		for x in range(0, size.x, CELL_SIZE):
			var light_cell := (x / CELL_SIZE + y / CELL_SIZE) % 2 == 0
			image.fill_rect(
				Rect2i(origin + Vector2i(x, y), Vector2i(mini(CELL_SIZE, size.x - x), mini(CELL_SIZE, size.y - y))),
				Color("d7dde2") if light_cell else Color("aeb9c2")
			)


func _draw_border(image: Image, origin: Vector2i, size: Vector2i, color: Color) -> void:
	image.fill_rect(Rect2i(origin, Vector2i(size.x, 1)), color)
	image.fill_rect(Rect2i(origin + Vector2i(0, size.y - 1), Vector2i(size.x, 1)), color)
	image.fill_rect(Rect2i(origin, Vector2i(1, size.y)), color)
	image.fill_rect(Rect2i(origin + Vector2i(size.x - 1, 0), Vector2i(1, size.y)), color)


func _processed_path_for(source_path: String) -> String:
	return OUTPUT_DIRECTORY.path_join("processed").path_join(source_path)


func _save_image(image: Image, relative_path: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path("res://" + relative_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if image.save_png(absolute_path) != OK:
		failures.append("could not save image: %s" % relative_path)
		return false
	return true


func _collect_png_paths(directory_path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(ProjectSettings.globalize_path("res://" + directory_path))
	if directory == null:
		failures.append("card art audit could not open %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if not entry_name.begins_with("."):
			var relative_path := directory_path.path_join(entry_name)
			if directory.current_is_dir():
				_collect_png_paths(relative_path, output)
			elif entry_name.to_lower().ends_with(".png"):
				output.append(relative_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _load_image(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://" + path))
	if image == null or image.is_empty():
		failures.append("could not load image: %s" % path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func _clean_image(source: Image) -> Image:
	var result := source.duplicate()
	for y in result.get_height():
		for x in result.get_width():
			var color: Color = result.get_pixel(x, y)
			if _is_green_edge_contamination(color):
				result.set_pixel(x, y, _decontaminate_chroma(color))
	return result


func _count_green_edge_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if _is_green_edge_contamination(image.get_pixel(x, y)):
				count += 1
	return count


func _is_green_edge_contamination(color: Color) -> bool:
	return (color.a > 0.01 and color.a < 0.99
			and color.g > 0.28
			and color.g > color.r * 1.18
			and color.g > color.b * 1.18)


func _decontaminate_chroma(color: Color) -> Color:
	var green_delta := color.g - maxf(color.r, color.b)
	var foreground_alpha := 1.0 - smoothstep(0.12, 0.58, green_delta)
	var output_alpha := color.a * foreground_alpha
	if foreground_alpha <= 0.001 or output_alpha <= 0.001:
		return Color.TRANSPARENT
	var removed_green := 1.0 - foreground_alpha
	var result := Color(
		clampf(color.r / foreground_alpha, 0.0, 1.0),
		clampf((color.g - removed_green) / foreground_alpha, 0.0, 1.0),
		clampf(color.b / foreground_alpha, 0.0, 1.0),
		output_alpha
	)
	# The master formula removes saturated chroma. This cap also neutralizes shallow
	# fringe pixels whose green delta is too small to receive alpha attenuation.
	result.g = minf(result.g, maxf(result.r, result.b) * 1.12)
	return result


func _finish() -> void:
	if failures.is_empty():
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)

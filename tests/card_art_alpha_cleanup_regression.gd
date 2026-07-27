extends SceneTree

const CARD_ART_DIRECTORY := "external/sprites/cards"
const MANIFEST_PATH := "tools/card_art_alpha_cleanup_manifest.json"
const CANDIDATE_PIXEL_THRESHOLD := 64

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var approved_paths := _load_manifest_paths()
	if approved_paths.is_empty():
		if failures.is_empty():
			failures.append("card art cleanup manifest has no approved paths")
		_finish()
		return

	for path: String in approved_paths:
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://" + path))
		if image == null or image.is_empty():
			failures.append("card art audit could not load %s" % path)
			continue
		image.convert(Image.FORMAT_RGBA8)
		var contaminated_pixels := _count_green_edge_pixels(image)
		if contaminated_pixels >= CANDIDATE_PIXEL_THRESHOLD:
			failures.append("%s retains %d semi-transparent green edge pixels" % [path, contaminated_pixels])

	_finish()


func _load_manifest_paths() -> Array[String]:
	var manifest_absolute_path := ProjectSettings.globalize_path("res://" + MANIFEST_PATH)
	if not FileAccess.file_exists(manifest_absolute_path):
		failures.append("card art cleanup manifest is missing: %s" % MANIFEST_PATH)
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
		if approved_paths.has(value):
			failures.append("cleanup manifest repeats a card art path: %s" % value)
			continue
		approved_paths.append(value)
	return approved_paths


func _finish() -> void:
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)
func _count_green_edge_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if _is_green_edge_contamination(color):
				count += 1
	return count


func _is_green_edge_contamination(color: Color) -> bool:
	return (color.a > 0.01 and color.a < 0.99
			and color.g > 0.28
			and color.g > color.r * 1.18
			and color.g > color.b * 1.18)

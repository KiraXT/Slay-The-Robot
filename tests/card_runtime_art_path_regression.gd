extends SceneTree

const MANIFEST_PATH := "res://tools/card_art_individualization_manifest.json"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest := _load_manifest()
	if manifest.is_empty():
		_finish()
		return

	var global = root.get_node("Global")
	for phase_name: String in ["pilot", "red", "colored", "team"]:
		for card_id: String in manifest.get("phases", {}).get(phase_name, []):
			var card_data = global.get_card_data(card_id)
			if card_data == null:
				failures.append("runtime card is missing: %s" % card_id)
				continue
			var color_folder := str(card_data.card_color_id).trim_prefix("color_")
			var expected_path := "external/sprites/cards/%s/%s.png" % [color_folder, card_id]
			if card_data.card_texture_path != expected_path:
				failures.append("%s uses %s instead of %s" % [card_id, card_data.card_texture_path, expected_path])
			elif not FileAccess.file_exists("res://" + expected_path):
				failures.append("runtime card art is missing: %s" % expected_path)

	_finish()


func _load_manifest() -> Dictionary:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		failures.append("card art manifest is missing")
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		failures.append("card art manifest is invalid")
		return {}
	return data


func _finish() -> void:
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)

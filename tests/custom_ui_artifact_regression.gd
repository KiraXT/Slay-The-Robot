extends SceneTree

const CUSTOM_UI_ACTION_PATH := "res://scripts/actions/custom_ui_actions/ActionCustomUI.gd"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var global = root.get_node("Global")
	_check_character_artifact_custom_ui(global, "character_blue")
	_check_character_artifact_custom_ui(global, "character_orange")

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_character_artifact_custom_ui(global: Node, character_object_id: String) -> void:
	var character_data = global.get_character_data(character_object_id)
	for artifact_object_id: String in character_data.character_starting_artifact_ids:
		var artifact_data = global.get_artifact_data(artifact_object_id)
		for action_definition: Dictionary in artifact_data.artifact_first_turn_actions:
			if action_definition.has(CUSTOM_UI_ACTION_PATH):
				var custom_ui_values: Dictionary = action_definition[CUSTOM_UI_ACTION_PATH]
				var custom_ui_object_id = custom_ui_values.get("custom_ui_object_id", null)
				if typeof(custom_ui_object_id) != TYPE_STRING or custom_ui_object_id == "":
					failures.append("%s first turn custom UI action must define non-empty custom_ui_object_id" % artifact_object_id)

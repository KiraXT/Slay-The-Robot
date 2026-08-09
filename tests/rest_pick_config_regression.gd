extends SceneTree

const PICK_ACTION_PATH := "res://scripts/actions/pick_card_actions/ActionPickCards.gd"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var global = root.get_node("Global")
	_check_rest_action(global, "rest_action_upgrade_card")
	_check_rest_action(global, "rest_action_remove_cards")

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_rest_action(global: Node, object_id: String) -> void:
	var rest_action = global.get_rest_action_data(object_id)
	var pick_values: Dictionary = rest_action.rest_actions[0][PICK_ACTION_PATH]

	if rest_action.rest_action_cost_type != RestActionData.REST_ACTION_COST_TYPES.EXCLUSIVE:
		failures.append("%s must consume the current rest action" % object_id)
	if pick_values.get("quick_pick", true):
		failures.append("%s should disable quick_pick" % object_id)
	if not pick_values.get("force_manual_selection", false):
		failures.append("%s should force manual selection" % object_id)

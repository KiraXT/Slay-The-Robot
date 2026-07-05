extends SceneTree

const HAND_SCRIPT_PATH := "res://scripts/ui/Hand.gd"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source := FileAccess.get_file_as_string(HAND_SCRIPT_PATH)
	if source == "":
		failures.append("failed to read %s" % HAND_SCRIPT_PATH)
	else:
		_check_drag_keeps_card_in_hand_and_draws_arrow(source)
		_check_drag_visuals_survive_hand_resets(source)
		_check_hover_scale_has_fast_slow_rhythm(source)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_drag_keeps_card_in_hand_and_draws_arrow(source: String) -> void:
	var drag_started_body := _function_body(source, "_on_card_drag_started")
	var process_body := _function_body(source, "_process")
	var drag_ended_body := _function_body(source, "_on_card_drag_ended")
	var cleanup_body := _function_body(source, "_cleanup_drag_state")
	var arrow_body := _function_body(source, "_update_drag_arrow_head")

	_assert_not_contains(
		drag_started_body,
		"card.position = Vector2.ZERO",
		"drag start should not reset the card to its default hand position"
	)
	_assert_contains(
		drag_started_body,
		"card.position.y = CARD_HOVERED_HEIGHT",
		"drag start should keep the card raised instead of moving it out of hand"
	)
	_assert_contains(
		drag_started_body,
		"card.pivot.scale = Vector2.ONE * CARD_HOVERED_SCALE",
		"drag start should hold the hovered max scale"
	)
	_assert_not_contains(
		process_body,
		"_update_dragged_card_position(mouse_pos)",
		"drag process should not move the card body with the pointer"
	)
	_assert_not_contains(
		drag_ended_body,
		"_update_dragged_card_position(mouse_pos)",
		"drag release should not snap the card body to the pointer"
	)
	_assert_contains(
		process_body,
		"_update_drag_line(dragged_card.pivot.global_position, mouse_pos)",
		"drag process should keep the line anchored to the card"
	)
	_assert_contains(
		process_body,
		"_update_drag_arrow_head(mouse_pos)",
		"drag process should update the Slay-the-Spire-style arrow head"
	)
	_assert_contains(
		cleanup_body,
		"drag_arrow_head.visible = false",
		"drag cleanup should hide the arrow head"
	)
	_assert_contains(
		arrow_body,
		"drag_arrow_head.polygon = PackedVector2Array",
		"drag arrow should render a polygon head"
	)


func _check_hover_scale_has_fast_slow_rhythm(source: String) -> void:
	var hover_body := _function_body(source, "_tween_card_hover_visual")

	_assert_contains(
		source,
		"const CARD_HOVER_SCALE_IN_TIME: float = 0.09",
		"hover scale should define a short fast-in phase"
	)
	_assert_contains(
		source,
		"const CARD_HOVER_SCALE_SETTLE_TIME: float = 0.13",
		"hover scale should define a slower settle phase"
	)
	_assert_contains(
		hover_body,
		"CARD_HOVER_OVERSHOOT_MULTIPLIER",
		"hover scale should overshoot before settling"
	)
	_assert_contains(
		hover_body,
		"set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)",
		"hover scale-in should use a quick easing curve"
	)
	_assert_contains(
		hover_body,
		"set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)",
		"hover settle should ease out more slowly"
	)


func _check_drag_visuals_survive_hand_resets(source: String) -> void:
	var reset_deck_body := _function_body(source, "reset_deck")
	var combat_ended_body := _function_body(source, "_on_combat_ended")
	var run_ended_body := _function_body(source, "_on_run_ended")

	_assert_contains(
		source,
		"func _is_drag_visual_node(child: Node) -> bool:",
		"hand should centralize runtime drag visual filtering"
	)
	for body in [reset_deck_body, combat_ended_body, run_ended_body]:
		_assert_contains(
			body,
			"_is_drag_visual_node(child)",
			"hand reset should not free runtime drag line or arrow nodes"
		)
	_assert_not_contains(
		source,
		"if child == drag_line:\n\t\t\tcontinue",
		"hand reset should not only protect drag_line while freeing drag_arrow_head"
	)


func _function_body(source: String, function_name: String) -> String:
	var signature := "func %s" % function_name
	var start := source.find(signature)
	if start < 0:
		failures.append("missing function %s" % function_name)
		return ""

	var next_function := source.find("\nfunc ", start + signature.length())
	if next_function < 0:
		return source.substr(start)
	return source.substr(start, next_function - start)


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])


func _assert_not_contains(haystack: String, needle: String, label: String) -> void:
	if haystack.contains(needle):
		failures.append("%s: found `%s`" % [label, needle])

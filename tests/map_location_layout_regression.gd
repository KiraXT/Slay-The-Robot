extends SceneTree

const CANVAS_SIZE := Vector2(1200.0, 700.0)

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	_check_map_layout(root_scene)

	root_scene.queue_free()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_map_layout(root_scene: Node) -> void:
	var map: Control = root_scene.get_node("RunScreen/Map")
	var scroll_container := map.get_node_or_null("ScrollContainer") as Control
	var legend_panel := map.get_node_or_null("LegendPanel") as Control
	var back_button := map.get_node_or_null("BackButton") as Control

	if scroll_container == null:
		failures.append("Map scroll container is missing")
		return
	if legend_panel == null:
		failures.append("Map legend panel is missing")
		return
	if back_button == null:
		failures.append("Map back button is missing")
		return

	_assert_rect_inside_canvas(scroll_container, "Map scroll container")
	_assert_rect_inside_canvas(legend_panel, "Map legend panel")
	_assert_rect_inside_canvas(back_button, "Map back button")
	_assert_no_overlap(scroll_container, legend_panel, "Map scroll container", "Map legend panel")
	_assert_no_overlap(back_button, legend_panel, "Map back button", "Map legend panel")

	if legend_panel.get_child_count() != 7:
		failures.append("Map legend should contain 7 entries, got %s" % legend_panel.get_child_count())

	for child in legend_panel.get_children():
		var row := child as Control
		if row == null:
			failures.append("Map legend contains a non-Control child")
			continue
		if not row.has_node("Icon"):
			failures.append("%s is missing Icon" % row.name)
		if not row.has_node("NameLabel"):
			failures.append("%s is missing NameLabel" % row.name)


func _assert_rect_inside_canvas(control: Control, label: String) -> void:
	var rect := control.get_global_rect()
	if rect.position.x < 0.0 or rect.position.y < 0.0:
		failures.append("%s starts outside the canvas: %s" % [label, rect])
	if rect.position.x + rect.size.x > CANVAS_SIZE.x:
		failures.append("%s extends past canvas width: %s" % [label, rect])
	if rect.position.y + rect.size.y > CANVAS_SIZE.y:
		failures.append("%s extends past canvas height: %s" % [label, rect])


func _assert_no_overlap(first: Control, second: Control, first_label: String, second_label: String) -> void:
	if first.get_global_rect().intersects(second.get_global_rect()):
		failures.append("%s overlaps %s" % [first_label, second_label])

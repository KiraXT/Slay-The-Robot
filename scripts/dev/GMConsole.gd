extends Control
class_name GMConsole

const GMCommandExecutorScript := preload("res://scripts/dev/GMCommandExecutor.gd")

var executor: GMCommandExecutor = GMCommandExecutorScript.new()
var output_label: RichTextLabel
var input_line: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide_console()


func toggle() -> void:
	if visible:
		hide_console()
	else:
		show_console()


func show_console() -> void:
	if not executor.is_enabled():
		return
	visible = true
	input_line.grab_focus()


func hide_console() -> void:
	visible = false
	if input_line != null:
		input_line.release_focus()


func submit_command(command_text: String) -> Dictionary:
	var result: Dictionary = executor.execute(command_text)
	if result.get("clear_output", false):
		output_label.clear()
		input_line.clear()
		return result
	_append_output("> %s" % command_text)
	_append_output(str(result.get("message", "")))
	input_line.clear()
	return result


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 12.0
	offset_top = 12.0
	offset_right = -12.0
	offset_bottom = 220.0

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	output_label = RichTextLabel.new()
	output_label.name = "Output"
	output_label.fit_content = false
	output_label.scroll_following = true
	output_label.custom_minimum_size = Vector2(0, 150)
	layout.add_child(output_label)

	input_line = LineEdit.new()
	input_line.name = "Input"
	input_line.placeholder_text = "GM command"
	input_line.text_submitted.connect(_on_input_submitted)
	layout.add_child(input_line)


func _append_output(text: String) -> void:
	output_label.append_text(text + "\n")


func _on_input_submitted(command_text: String) -> void:
	submit_command(command_text)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_console()
		get_viewport().set_input_as_handled()

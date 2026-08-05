extends RefCounted
class_name TooltipSizer

const MIN_TOOLTIP_WIDTH := 112.0
const MAX_TOOLTIP_WIDTH := 260.0
const HORIZONTAL_CONTENT_MARGIN := 24.0
const LINE_HEIGHT := 18.0


static func apply_to(panel: Control, rich_text_label: RichTextLabel, plain_text: String) -> void:
	var text := plain_text.strip_edges()
	if text == "":
		panel.custom_minimum_size = Vector2.ZERO
		rich_text_label.custom_minimum_size = Vector2.ZERO
		return
	var content_width: float = clampf(
		_get_longest_line_width(text),
		MIN_TOOLTIP_WIDTH - HORIZONTAL_CONTENT_MARGIN,
		MAX_TOOLTIP_WIDTH - HORIZONTAL_CONTENT_MARGIN
	)
	var tooltip_width: float = content_width + HORIZONTAL_CONTENT_MARGIN
	var visual_lines := _count_visual_lines(text, content_width)
	rich_text_label.custom_minimum_size = Vector2(content_width, max(LINE_HEIGHT, visual_lines * LINE_HEIGHT))
	panel.custom_minimum_size = Vector2(tooltip_width, 0.0)
	rich_text_label.update_minimum_size()
	panel.update_minimum_size()


static func _count_visual_lines(text: String, wrap_width: float) -> int:
	var visual_lines := 0
	for line in text.split("\n", true):
		var line_width := _get_line_width(line)
		visual_lines += maxi(1, ceili(line_width / wrap_width))
	return visual_lines


static func _get_longest_line_width(text: String) -> float:
	var longest := 0.0
	for line in text.split("\n", true):
		longest = maxf(longest, _get_line_width(line))
	return longest


static func _get_line_width(line: String) -> float:
	var width := 0.0
	for index in range(line.length()):
		var codepoint := line.unicode_at(index)
		if codepoint > 255:
			width += 13.0
		else:
			width += 7.0
	return width

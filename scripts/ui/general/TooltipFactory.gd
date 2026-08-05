extends RefCounted
class_name TooltipFactory

const TOOLTIP_SCENE := preload("res://scenes/ui/general/Tooltip.tscn")
const TITLE_COLOR := "#f7d27a"
const BODY_COLOR := "#dbe7ee"


static func create_text_tooltip(text: String) -> Control:
	var tooltip: Control = TOOLTIP_SCENE.instantiate()
	if tooltip.has_method("set_tooltip_bb_code"):
		tooltip.call("set_tooltip_bb_code", format_plain_text_tooltip(text))
	return tooltip


static func format_plain_text_tooltip(text: String) -> String:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return ""
	var lines := cleaned.split("\n", false)
	var title := _escape_bbcode(lines[0].strip_edges())
	var bb_code := "[color=%s][b]%s[/b][/color]" % [TITLE_COLOR, title]
	var body_lines := PackedStringArray()
	for index in range(1, lines.size()):
		var line := lines[index].strip_edges()
		if line != "":
			body_lines.append(_escape_bbcode(line))
	if not body_lines.is_empty():
		bb_code += "\n[color=%s]%s[/color]" % [BODY_COLOR, "\n".join(body_lines)]
	return bb_code


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")

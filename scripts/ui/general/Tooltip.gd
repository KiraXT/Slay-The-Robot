# tooltip displaying info
extends PanelContainer

@onready var rich_text_label: RichTextLabel = $RichTextLabel


func set_tooltip_bb_code(bb_code: String) -> void:
	if rich_text_label == null:
		rich_text_label = $RichTextLabel
	rich_text_label.parse_bbcode(bb_code)


func set_tooptip_bb_code(bb_code: String) -> void:
	set_tooltip_bb_code(bb_code)

# tooltip displaying info
extends PanelContainer

const TOOLTIP_SIZER_SCRIPT := preload("res://scripts/ui/general/TooltipSizer.gd")

@onready var rich_text_label: RichTextLabel = $RichTextLabel


func set_tooltip_bb_code(bb_code: String) -> void:
	if rich_text_label == null:
		rich_text_label = $RichTextLabel
	rich_text_label.parse_bbcode(bb_code)
	TOOLTIP_SIZER_SCRIPT.apply_to(self, rich_text_label, rich_text_label.get_parsed_text())


func set_tooptip_bb_code(bb_code: String) -> void:
	set_tooltip_bb_code(bb_code)

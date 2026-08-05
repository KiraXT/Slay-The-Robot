extends PanelContainer
class_name StyledTooltipPanel

const TOOLTIP_FACTORY_SCRIPT := preload("res://scripts/ui/general/TooltipFactory.gd")


func _make_custom_tooltip(for_text: String) -> Object:
	return TOOLTIP_FACTORY_SCRIPT.create_text_tooltip(for_text)

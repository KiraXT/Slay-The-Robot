# UI element for a status effect
extends TextureRect
class_name StatusEffect

const TOOLTIP_FACTORY_SCRIPT := preload("res://scripts/ui/general/TooltipFactory.gd")

var status_effect_script: BaseStatusEffect

@onready var status_charge_label: Label = $StatusChargeLabel
@onready var status_secondary_charge_label = $StatusSecondaryChargeLabel

func update_status_charge_display() -> void:
	visible = status_effect_script.status_effect_data.status_effect_is_visible
	
	if status_effect_script.status_charges == 1 and not status_effect_script.status_effect_data.status_effect_stacks:
		status_charge_label.text = ""
	else:
		status_charge_label.text = str(status_effect_script.status_charges)
	
	if status_effect_script.status_secondary_charges == 0:
		status_secondary_charge_label.text = ""
	else:
		status_secondary_charge_label.text = str(status_effect_script.status_secondary_charges)
	
	
	tooltip_text = status_effect_script.status_effect_data.status_effect_name


func _make_custom_tooltip(for_text: String) -> Object:
	return TOOLTIP_FACTORY_SCRIPT.create_text_tooltip(for_text)

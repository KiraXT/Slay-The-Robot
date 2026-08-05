# represents a consumable slot
# can be empty
extends TextureButton
class_name ConsumableButton

const TOOLTIP_FACTORY_SCRIPT := preload("res://scripts/ui/general/TooltipFactory.gd")

@onready var icon_texture: TextureRect = $IconTexture
@onready var badge_visual: Control = $BadgeVisual

var consumable_slot_index: int = 0	# which consumable slot this button corresponds to

signal consumable_slot_button_up(slot_index: int)

func _ready():
	texture_normal = null
	button_up.connect(_on_button_up)

func init(_consumable_slot_index: int):
	consumable_slot_index = _consumable_slot_index
	texture_normal = null
	
	var consumable_data: ConsumableData = Global.get_player_consumable_in_slot_index(consumable_slot_index)
	if consumable_data != null:
		icon_texture.texture = FileLoader.load_texture(consumable_data.consumable_texture_path)
		badge_visual.set("draw_icon", false)
		self_modulate.a = 1.0
		# set tooltip
		tooltip_text = consumable_data.consumable_name
		if consumable_data.consumable_description != "":
			tooltip_text += "\n" + consumable_data.consumable_description
	else:
		# empty consumable slot
		icon_texture.texture = null
		badge_visual.set("draw_icon", true)
		self_modulate.a = 0.62
		tooltip_text = ""
	


func _on_button_up():
	consumable_slot_button_up.emit(consumable_slot_index)


func _make_custom_tooltip(for_text: String) -> Object:
	return TOOLTIP_FACTORY_SCRIPT.create_text_tooltip(for_text)

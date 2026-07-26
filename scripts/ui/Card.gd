# UI element representing a CardData
extends Control
class_name Card

var card_data: CardData = null
var card_listeners: Array[BaseCardListener] = []

const CARDS_RERENDER_LAZILY: bool = true # throttles card display generation to next frame
var _card_is_rerendering: bool = false

const CARD_TEXT_IMAGE_SIZE: int = 16	# images in card descriptions will be set to this size
const ENERGY_ICON_KEYWORD: String = "[energy_icon]"	# tells description to display an energy icon in place

const CARD_TYPE_LABELS: Dictionary = {
	CardData.CARD_TYPES.ATTACK: "攻击",
	CardData.CARD_TYPES.SKILL: "技能",
	CardData.CARD_TYPES.POWER: "能力",
	CardData.CARD_TYPES.STATUS: "状态",
	CardData.CARD_TYPES.CURSE: "诅咒",
}

const CARD_RARITY_STARS: Dictionary = {
	CardData.CARD_RARITIES.BASIC: "★",
	CardData.CARD_RARITIES.COMMON: "★★",
	CardData.CARD_RARITIES.UNCOMMON: "★★★",
	CardData.CARD_RARITIES.RARE: "★★★★",
	CardData.CARD_RARITIES.GENERATED: "",
}

const CARD_DEFAULT_FRAME_COLOR: Color = Color(0.86, 0.88, 0.92, 1.0)
const CARD_NEUTRAL_FRAME_COLOR: Color = Color(0.70, 0.73, 0.76, 1.0)
const CARD_NEUTRAL_FRAME_EDGE_COLOR: Color = Color(0.46, 0.49, 0.52, 1.0)
const CARD_NEUTRAL_FRAME_BORDER_COLOR: Color = Color(0.62, 0.65, 0.68, 1.0)

const CARD_STYLE_PACK_DIR := "external/data/card_styles/"
const CARD_STYLE_PACK_FILE := "card_style_preview.json"
const CARD_TYPE_FALLBACK_TEXTURE_PATH := "external/sprites/ui/card_styles/full_master/ribbons/ribbon_status.png"
const CARD_ART_FALLBACK_RECT := Rect2(15.0, 34.0, 116.0, 76.0)
const CARD_ART_MASTER_RECT := Rect2(17.0, 34.0, 114.0, 94.0)
const CARD_STYLE_SHARED_PANEL_MAP := {
	"CardGlow": "glow",
}
const CARD_STYLE_LEGACY_LAYERS := [
	"ColorBackground",
	"CardBackground",
	"CardHeaderBackground",
	"CardArtFrame",
	"CardDescriptionBackground",
	"CardTypeConnector",
	"CardFactionBadge",
	"CardFactionStamp",
	"EnergySprite",
]

@onready var card_button: Button = %CardButton

@onready var pivot: Node2D = $Pivot

@onready var card_art_background: TextureRect = %CardArtBackground
@onready var card_texture: TextureRect = %CardTexture
@onready var card_chrome: TextureRect = %CardChrome
@onready var card_name: RichLabelAutoSizer = %CardName
@onready var card_type: Label = %CardType
@onready var card_description: RichLabelAutoSizer = %CardDescription
@onready var card_energy_cost: Label = %EnergyCost
@onready var card_color: Panel = %ColorBackground
@onready var card_background: Panel = %CardBackground
@onready var card_header_background: Panel = %CardHeaderBackground
@onready var card_art_frame: Panel = %CardArtFrame
@onready var card_description_background: Panel = %CardDescriptionBackground
@onready var card_type_background: TextureRect = %CardTypeBackground
@onready var card_type_connector: Panel = %CardTypeConnector
@onready var card_faction_badge: Panel = %CardFactionBadge
@onready var card_faction_stamp: Panel = %CardFactionStamp
@onready var card_stars: Label = %CardStars
@onready var energy_sprite: Panel = %EnergySprite
var _using_full_card_master := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_glow: Panel = %CardGlow

@onready var keyword_container = $Pivot/KeywordContainer
@onready var keyword_timer = $KeywordTimer

const KEYWORD_HOVER_DELAY: float = 0.5

signal card_selected(Card)
signal card_right_clicked(Card)
signal card_hovered(Card)
signal card_unhovered(Card)

signal card_drag_started(Card)
signal card_drag_ended(Card)
signal card_drag_cancelled(Card)

func init(_card_data: CardData, angular_offset: float, connect_combat_signals: bool = false, connect_ui_signals: bool = true):
	card_data = _card_data
	pivot.rotation_degrees = angular_offset
	
	# signals used for cards in player's hand
	if connect_combat_signals:
		Signals.card_discarded.connect(_on_card_discarded)
		Signals.card_play_started.connect(_on_card_play_started)
		Signals.card_exhausted.connect(_on_card_exhausted)
		Signals.card_banished.connect(_on_card_banished)
		Signals.card_drawn.connect(_on_card_drawn)
		Signals.card_added_to_draw.connect(_on_card_added_to_draw)
		Signals.card_properties_changed.connect(_on_card_properties_changed)
		Signals.card_turn_energy_changed.connect(_on_card_turn_energy_changed)
		Signals.card_upgraded.connect(_on_card_upgraded)
		Signals.card_transformed.connect(_on_card_transformed)
	# flag to disable cards so they're not interactable by player
	if connect_ui_signals:
		card_button.gui_input.connect(_on_button_gui_input)
		card_button.button_down.connect(_on_button_down)
		card_button.button_up.connect(_on_button_up)
		card_button.mouse_entered.connect(_on_mouse_entered)
		card_button.mouse_exited.connect(_on_mouse_exited)
		keyword_timer.timeout.connect(_on_keyword_timeout)
	
	update_card_display()
	
	# initialize card listeners if in hand
	if Global.player_data.player_hand.has(card_data):
		card_listeners = _generate_card_listeners(card_data.card_listeners)
	

func update_card_display(selected_enemy: Enemy = null) -> void:
	if _card_is_rerendering:
		return
	if CARDS_RERENDER_LAZILY:
		_card_is_rerendering = true
		await get_tree().process_frame
		if not is_instance_valid(self):
			return
		_card_is_rerendering = false
	
	# update visuals
	if card_data.card_texture_path != "":
		card_texture.texture = FileLoader.load_texture(card_data.card_texture_path)
	
	# updates the card's display
	card_name.set_bbcode("[center]" + card_data.get_card_name() + "[/center]")
	card_description.set_bbcode(get_card_description(selected_enemy))
	card_type.text = _get_card_type_label(card_data.card_type)
	card_stars.text = _get_card_star_label(card_data.card_rarity)
	
	var color_data: ColorData = Global.get_color_data(card_data.card_color_id)
	_apply_card_palette(color_data, card_data.card_color_id)
	_apply_card_style_pack(card_data.card_color_id, card_data.card_type)
	
	energy_sprite.visible = card_data.card_is_playable and not _using_full_card_master
	card_energy_cost.visible = card_data.card_is_playable
	
	var energy_cost_text: String
	if card_data.card_energy_cost_is_variable:
		energy_cost_text = "X"
		if card_data.card_energy_cost_variable_upper_bound >= 1:
			energy_cost_text = "X-" + str(card_data.card_energy_cost_variable_upper_bound)
	else:
		energy_cost_text = str(card_data.get_card_energy_cost())
	_update_energy_cost_visual(energy_cost_text)

func _get_card_type_label(card_type_id: int) -> String:
	if CARD_TYPE_LABELS.has(card_type_id):
		return CARD_TYPE_LABELS[card_type_id]
	if card_type_id >= 0 and card_type_id < CardData.CARD_TYPES.keys().size():
		return CardData.CARD_TYPES.keys()[card_type_id]
	return ""


func _get_card_star_label(card_rarity_id: int) -> String:
	return CARD_RARITY_STARS.get(card_rarity_id, "")


func _apply_card_palette(color_data: ColorData, card_color_id: String) -> void:
	_using_full_card_master = false
	card_chrome.visible = false
	card_background.visible = true
	_set_card_art_rect(CARD_ART_FALLBACK_RECT)
	_set_legacy_card_layers_visible(true)
	var frame_color := CARD_DEFAULT_FRAME_COLOR
	if color_data != null:
		frame_color = color_data.color

	var background_color := Color(1.0, 1.0, 1.0, 0.98)
	if frame_color.get_luminance() < 0.82:
		background_color = frame_color.lightened(0.82)

	var frame_edge := frame_color.darkened(0.20)
	var frame_highlight := frame_color.lightened(0.45)
	var type_color := frame_color.darkened(0.10)
	var description_border := frame_color.lightened(0.50)
	var panel_white := Color(1.0, 1.0, 1.0, 0.96)
	if card_color_id == "color_white":
		frame_color = CARD_NEUTRAL_FRAME_COLOR
		frame_edge = CARD_NEUTRAL_FRAME_EDGE_COLOR
		frame_highlight = CARD_NEUTRAL_FRAME_BORDER_COLOR
		type_color = CARD_NEUTRAL_FRAME_BORDER_COLOR
		description_border = CARD_NEUTRAL_FRAME_BORDER_COLOR.lightened(0.28)
		background_color = Color(0.96, 0.97, 0.98, 0.98)

	card_art_background.texture = _create_card_art_gradient(frame_color)
	_set_panel_style(card_color, frame_color, frame_highlight)
	_set_panel_style(card_background, background_color, panel_white)
	_set_panel_style(card_art_frame, panel_white, frame_edge)
	_set_panel_style(card_description_background, panel_white, description_border)
	card_type_background.texture = _load_style_texture(CARD_TYPE_FALLBACK_TEXTURE_PATH)
	card_type_background.self_modulate = type_color
	_set_panel_style(card_type_connector, frame_color, frame_highlight)
	_set_panel_style(card_faction_badge, frame_color.darkened(0.20), frame_highlight)
	_set_panel_style(card_faction_stamp, frame_color.darkened(0.20), frame_highlight)
	_set_panel_style(energy_sprite, Color(0.08, 0.36, 0.86, 1.0), frame_highlight)

func _set_panel_style(panel: Panel, bg_color: Color, border_color: Color) -> void:
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	else:
		style = style.duplicate()
	style.bg_color = bg_color
	style.border_color = border_color
	panel.add_theme_stylebox_override("panel", style)


func _apply_card_style_pack(card_color_id: String, card_type_id: int) -> void:
	var style_path := CARD_STYLE_PACK_DIR + CARD_STYLE_PACK_FILE
	if not FileAccess.file_exists(FileLoader._get_modified_filepath(style_path)):
		return
	var style_data := FileLoader.load_json(CARD_STYLE_PACK_DIR, CARD_STYLE_PACK_FILE)
	var master_slots: Dictionary = style_data.get("master_slots", {})
	var master_path := _get_style_variant_path(master_slots, card_color_id)
	var type_slots: Dictionary = style_data.get("type_slots", {})
	var type_path := _get_style_variant_path(type_slots, str(card_type_id))
	if not _try_apply_full_card_master(master_path, type_path):
		return

	_using_full_card_master = true
	card_chrome.visible = true
	_set_card_art_rect(CARD_ART_MASTER_RECT)
	_set_legacy_card_layers_visible(false)
	var shared_slots: Dictionary = style_data.get("shared_slots", {})
	for panel_name: String in CARD_STYLE_SHARED_PANEL_MAP:
		var panel := _get_card_style_panel(panel_name)
		if panel == null:
			continue
		var texture_path := str(shared_slots.get(CARD_STYLE_SHARED_PANEL_MAP[panel_name], ""))
		_apply_texture_stylebox(panel, texture_path)

	card_type_background.visible = true
	card_name.add_theme_color_override("default_color", Color.WHITE)
	card_name.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.92))
	card_name.add_theme_constant_override("outline_size", 2)


func _get_style_variant_path(slots: Dictionary, key: String) -> String:
	return str(slots.get(key, slots.get("default", "")))


func _set_legacy_card_layers_visible(is_visible: bool) -> void:
	for node_name: String in CARD_STYLE_LEGACY_LAYERS:
		var node := get_node_or_null("%" + node_name) as CanvasItem
		if node != null:
			node.visible = is_visible


func _try_apply_full_card_master(master_path: String, type_path: String) -> bool:
	var master_texture := _load_style_texture(master_path)
	var type_texture := _load_style_texture(type_path)
	if master_texture == null or type_texture == null:
		return false
	card_chrome.texture = master_texture
	card_type_background.texture = type_texture
	card_type_background.self_modulate = Color.WHITE
	return true


func _load_style_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null
	if not FileAccess.file_exists(FileLoader._get_modified_filepath(texture_path)):
		return null
	var texture := FileLoader.load_texture(texture_path)
	if texture == null or texture.get_size() == Vector2.ZERO:
		return null
	return texture


func _set_control_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func _set_card_art_rect(rect: Rect2) -> void:
	_set_control_rect(card_art_background, rect)
	_set_control_rect(card_texture, rect)


func _create_card_art_gradient(frame_color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		frame_color.lightened(0.88),
		frame_color.lightened(0.68),
		frame_color.lightened(0.38),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.08, 0.05)
	texture.fill_to = Vector2(0.92, 0.95)
	return texture


func _update_energy_cost_visual(cost_text: String) -> void:
	card_energy_cost.text = cost_text
	card_energy_cost.add_theme_font_size_override("font_size", 19 if cost_text.length() <= 2 else 14)


func _get_card_style_panel(panel_name: String) -> Panel:
	match panel_name:
		"CardHeaderBackground":
			return card_header_background
		"ColorBackground":
			return card_color
		"CardBackground":
			return card_background
		"CardArtFrame":
			return card_art_frame
		"CardDescriptionBackground":
			return card_description_background
		"EnergySprite":
			return energy_sprite
		"CardGlow":
			return card_glow
		_:
			return null


func _apply_texture_stylebox(panel: Panel, texture_path: String) -> void:
	var texture := _load_style_texture(texture_path)
	if texture == null:
		return
	_apply_texture_stylebox_texture(panel, texture)


func _apply_texture_stylebox_texture(panel: Panel, texture: Texture2D) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 8
	style.texture_margin_top = 8
	style.texture_margin_right = 8
	style.texture_margin_bottom = 8
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	panel.add_theme_stylebox_override("panel", style)


func set_card_glow(_visible: bool) -> void:
	card_glow.visible = _visible

func toggle_card_glow() -> void:
	card_glow.visible = !card_glow.visible

func can_play_card() -> bool:
	if not card_data.card_is_playable:
		return false
	if Global.player_data.player_energy < card_data.get_card_energy_cost():
		return false
	
	if not _validate_card():
		return false
	
	return true

func get_card_description(selected_target: BaseCombatant = null) -> String:
	# generates a card description for a card
	var modified_description_bb_code: String = card_data.card_description
	

	# generate fake card request
	var card_play_request: CardPlayRequest = CardPlayRequest.new()	# generate fake request
	card_play_request.card_data = card_data
	card_play_request.selected_target = selected_target
	
	# figure out what actions/values to calculate for the preview
	var card_description_preview_data: Array[Array] = []
	if len(card_data.card_description_preview_overrides) == 0:
		# with no overrides, assume basic block and attack
		card_description_preview_data = [
		 ["damage", Scripts.ACTION_ATTACK],
		 ["block", Scripts.ACTION_BLOCK]
		]
	else:
		# use the card's preview overrides
		card_description_preview_data = card_data.card_description_preview_overrides
	
	var player: Player = Global.get_player()
	
	# iterate over the preview data to determine any differences in the card's values
	for preview_data in card_description_preview_data:
		if len(preview_data) >= 2:
			var key_name: String = preview_data[0]
			var action_script_path: String = preview_data[1]
			
			if card_data.card_description.contains("[" + key_name + "]"):
				var action_data: Array[Dictionary] = [{action_script_path: {}}]
				var generated_action: BaseAction = ActionGenerator.create_actions(player, card_play_request, [selected_target], action_data, null)[0]
				var action_interceptor_processor: ActionInterceptorProcessor = generated_action._intercept_action([selected_target], true)[0]
				
				var card_value: int = card_data.card_values.get(key_name, 0)
				var value_substring: String = str(card_value)
				
				if action_interceptor_processor.shadowed_action_values.has(key_name):
					var intercepted_value: int = action_interceptor_processor.get_shadowed_action_values(key_name, card_value)
					
					# compare the intercepted valus to the card's values
					if intercepted_value < card_value:
						value_substring = "[color=red]" + str(intercepted_value) + "[/color]" # worse: red
					if intercepted_value > card_value:
						value_substring = "[color=green]" + str(intercepted_value) + "[/color]" # better: green
				
				modified_description_bb_code = modified_description_bb_code.replace("["+key_name+"]", value_substring)
			
	# do a second pass for non intercepted values in card description
	for key_name in card_data.card_values.keys():
		var non_intercepted_value: Variant = card_data.card_values[key_name]
		if non_intercepted_value is float:
			non_intercepted_value = int(non_intercepted_value)
		modified_description_bb_code = modified_description_bb_code.replace("["+key_name+"]", str(non_intercepted_value))
	
	# replace energy icon with external image bbcode
	if card_data.card_description.contains(ENERGY_ICON_KEYWORD):
		var character_data: CharacterData = Global.get_character_data(Global.player_data.player_character_object_id)
		if character_data != null:
			var image_bb_code: String = "[img width={0}]{1}[/img]".format([CARD_TEXT_IMAGE_SIZE, character_data.character_text_energy_texture_path])
			modified_description_bb_code = modified_description_bb_code.replace(ENERGY_ICON_KEYWORD, image_bb_code)
	
	return modified_description_bb_code

func _generate_card_listeners(listener_data: Array[Dictionary]) -> Array[BaseCardListener]:
	var generated_card_listeners: Array[BaseCardListener] = []
	for card_listener_data in listener_data:
		for card_listener_path in card_listener_data:
			var listener_asset = load(card_listener_path)
			var listener_values: Dictionary = card_listener_data[card_listener_path]
			var card_listener: BaseCardListener = listener_asset.new(self, listener_values)
			generated_card_listeners.append(card_listener)
	
	return generated_card_listeners

## Checks if card passes all validators to play it
func _validate_card() -> bool:
	return Global.validate(card_data.card_play_validators, card_data, null)

func _glow_validation() -> bool:
	# determines glow logic
	if len(card_data.card_glow_validators) == 0:
		if len(card_data.card_play_validators) > 0:
			return _validate_card() # if no glow validators use play validators
		else:
			return false
	else:
		# use glow validators
		return Global.validate(card_data.card_glow_validators, card_data, null)

func _is_card_in_hand() -> bool:
	return Global.player_data.player_hand.has(card_data)

func _attempt_hand_glow() -> void:
	# tests to see if cards in hand that require validation meet validation and glow
	if _is_card_in_hand():
		set_card_glow(_glow_validation())

func _on_button_gui_input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		card_drag_cancelled.emit(self)
		card_right_clicked.emit(self)

func _on_mouse_entered():
	keyword_timer.start(KEYWORD_HOVER_DELAY)
	card_hovered.emit(self)
	
func _on_mouse_exited():
	keyword_timer.stop()
	keyword_container.clear_keywords()
	card_unhovered.emit(self)

func _on_keyword_timeout():
	keyword_container.populate_card_keywords(card_data)

func _on_card_properties_changed(_card_data: CardData):
	if card_data == _card_data:
		update_card_display()

func _on_card_turn_energy_changed(_card_data: CardData):
	if card_data == _card_data:
		update_card_display()

func _on_card_upgraded(_card_data: CardData):
	if card_data == _card_data:
		update_card_display()

func _on_card_transformed(_card_data: CardData):
	if card_data == _card_data:
		# # reset card listeners to newly transformed card and rerender if in hand
		if Global.player_data.player_hand.has(card_data):
			card_listeners = _generate_card_listeners(card_data.card_listeners)
			update_card_display()

func _on_card_discarded(_card_data: CardData, _is_manual_discard: bool):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_play_started(card_play_request: CardPlayRequest):
	if card_data == card_play_request.card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_exhausted(_card_data: CardData):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_banished(_card_data: CardData, _in_limbo: bool):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_drawn(_card_data: CardData):
	_attempt_hand_glow()

func _on_card_added_to_draw(_card_data: CardData):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func disconnect_non_ui_signals() -> void:
	# disconnects everything except internal clicking signals
	pass

func _on_button_down():
	card_drag_started.emit(self)
	card_selected.emit(self)  # backward compat for overlays

func _on_button_up():
	card_drag_ended.emit(self)

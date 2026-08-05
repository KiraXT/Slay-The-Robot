## UI menu to display all content in the game such as all cards
extends Control

@onready var title_screen: Control = get_parent()
@onready var back_button: Button = $BackButton
@onready var cards_button: Button = $VBoxContainer/Button
@onready var enemies_button: Button = $VBoxContainer/Button2
@onready var artifacts_button: Button = $VBoxContainer/Button3
@onready var codex_card_container: GridContainer = $ScrollContainer/MarginContainer/CodexCardContainer

const CODEX_ENTRY_SIZE: Vector2 = Vector2(150, 220)
const CODEX_IMAGE_SIZE: Vector2 = Vector2(112, 88)
const CODEX_ACCENT_CYAN := Color(0.133333, 0.831373, 0.839216, 1.0)
const CODEX_ACCENT_GOLD := Color(0.968627, 0.760784, 0.360784, 1.0)
const CODEX_PANEL_BG := Color(1.0, 1.0, 1.0, 0.94)
const CODEX_IMAGE_BG := Color(0.894118, 0.980392, 0.980392, 0.76)
const CODEX_TEXT_MUTED := Color(0.258824, 0.337255, 0.384314, 1.0)
const STYLED_TOOLTIP_PANEL_SCRIPT := preload("res://scripts/ui/general/StyledTooltipPanel.gd")

func _ready():
	back_button.button_up.connect(_on_back_button_up)
	cards_button.button_up.connect(_on_cards_button_up)
	enemies_button.button_up.connect(_on_enemies_button_up)
	artifacts_button.button_up.connect(_on_artifacts_button_up)

func populate_codex_menu() -> void:
	populate_codex_card_container()

func populate_codex_card_container() -> void:
	clear_codex_card_container()
	codex_card_container.columns = 6

	# creates all cards in the game to display
	var card_object_ids: Array = Global._id_to_card_data.keys()

	for card_object_id: String in card_object_ids:
		var card_data: CardData = Global.get_card_data(card_object_id)

		# generate an un-interactable card object for display
		var card: Card = Scenes.CARD.instantiate()
		codex_card_container.add_child(card)
		card.init(card_data, 0, false, false)

func populate_codex_enemy_container() -> void:
	clear_codex_card_container()
	codex_card_container.columns = 6

	var enemy_object_ids: Array = Global._id_to_enemy_data.keys()
	for enemy_object_id: String in enemy_object_ids:
		var enemy_data: EnemyData = Global.get_enemy_data(enemy_object_id)
		if enemy_data != null:
			codex_card_container.add_child(_create_enemy_codex_entry(enemy_data))

func populate_codex_artifact_container() -> void:
	clear_codex_card_container()
	codex_card_container.columns = 6

	var artifact_object_ids: Array = Global._id_to_artifact_data.keys()
	for artifact_object_id: String in artifact_object_ids:
		var artifact_data: ArtifactData = Global.get_artifact_data(artifact_object_id)
		if artifact_data != null:
			codex_card_container.add_child(_create_artifact_codex_entry(artifact_data))

func clear_codex_card_container() -> void:
	for child in codex_card_container.get_children():
		child.queue_free()

func _create_enemy_codex_entry(enemy_data: EnemyData) -> Control:
	var entry := _create_base_codex_entry(CODEX_ACCENT_CYAN)
	var content: VBoxContainer = entry.get_node("MarginContainer/VBoxContainer")

	var texture_panel := _create_codex_image_panel(enemy_data.enemy_texture_path)
	content.add_child(texture_panel)
	content.add_child(_create_codex_label(enemy_data.enemy_name, 16))
	content.add_child(_create_codex_label("HP %s/%s" % [enemy_data.enemy_health, enemy_data.enemy_health_max], 13))

	var enemy_type_label := _get_enum_label(EnemyData.ENEMY_TYPES.keys(), enemy_data.enemy_type)
	var details := enemy_type_label
	if enemy_data.enemy_block > 0:
		details += " | Block %s" % enemy_data.enemy_block
	if enemy_data.enemy_is_minion:
		details += " | Minion"
	content.add_child(_create_codex_label(details, 12))

	entry.tooltip_text = "%s\n%s\nHP %s/%s" % [
		enemy_data.enemy_name,
		details,
		enemy_data.enemy_health,
		enemy_data.enemy_health_max,
	]
	return entry

func _create_artifact_codex_entry(artifact_data: ArtifactData) -> Control:
	var entry := _create_base_codex_entry(CODEX_ACCENT_GOLD)
	var content: VBoxContainer = entry.get_node("MarginContainer/VBoxContainer")

	var texture_panel := _create_codex_image_panel(artifact_data.artifact_texture_path)
	content.add_child(texture_panel)
	content.add_child(_create_codex_label(artifact_data.artifact_name, 16))

	var rarity_label := _get_enum_label(ArtifactData.ARTIFACT_RARITIES.keys(), artifact_data.artifact_rarity)
	content.add_child(_create_codex_label("%s | %s" % [rarity_label, artifact_data.artifact_color_id], 12))
	content.add_child(_create_codex_label(artifact_data.artifact_description, 12, HORIZONTAL_ALIGNMENT_LEFT))

	entry.tooltip_text = artifact_data.artifact_name
	if artifact_data.artifact_description != "":
		entry.tooltip_text += "\n%s\n%s" % [rarity_label, artifact_data.artifact_description]
	return entry

func _create_base_codex_entry(accent_color: Color = CODEX_ACCENT_CYAN) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_script(STYLED_TOOLTIP_PANEL_SCRIPT)
	panel.custom_minimum_size = CODEX_ENTRY_SIZE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", _create_codex_entry_style(accent_color))

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "VBoxContainer"
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	return panel

func _create_codex_entry_style(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CODEX_PANEL_BG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.border_color = accent_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0.0745098, 0.384314, 0.439216, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

func _create_codex_image_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CODEX_IMAGE_BG
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.82)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style

func _create_codex_image_panel(texture_path: String) -> PanelContainer:
	var image_panel := PanelContainer.new()
	image_panel.name = "ImagePanel"
	image_panel.custom_minimum_size = CODEX_IMAGE_SIZE
	image_panel.add_theme_stylebox_override("panel", _create_codex_image_style())

	var texture_rect := TextureRect.new()
	texture_rect.name = "TextureRect"
	texture_rect.custom_minimum_size = CODEX_IMAGE_SIZE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = FileLoader.load_texture(texture_path)
	image_panel.add_child(texture_rect)
	return image_panel

func _create_codex_label(text: String, font_size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	if font_size <= 13:
		label.add_theme_color_override("font_color", CODEX_TEXT_MUTED)
	return label

func _get_enum_label(enum_keys: Array, enum_value: int) -> String:
	if enum_value >= 0 and enum_value < len(enum_keys):
		return str(enum_keys[enum_value]).capitalize()
	return str(enum_value)

func _on_cards_button_up() -> void:
	populate_codex_card_container()

func _on_enemies_button_up() -> void:
	populate_codex_enemy_container()

func _on_artifacts_button_up() -> void:
	populate_codex_artifact_container()

func _on_back_button_up():
	clear_codex_card_container()
	title_screen.show_main_menu()

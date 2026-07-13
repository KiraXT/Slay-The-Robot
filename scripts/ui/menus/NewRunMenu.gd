extends Control

signal character_changed(character_data: CharacterData)
signal run_requested(character_object_id: String, run_seed: int, difficulty_level: int, custom_modifier_ids: Array[String])
signal back_requested

@onready var title_screen: Control = get_parent()

@onready var character_name_label = $CharacterNameLabel
@onready var character_health_label = $CharacterHealthLabel
@onready var character_money_label = $CharacterMoneyLabel
@onready var character_description_label = $CharacterDescriptionLabel
@onready var character_artifact_texture_rect = $CharacterArtifactTextureRect
@onready var character_artifact_name_label = $CharacterArtifactNameLabel
@onready var character_artifact_description_label = $CharacterArtifactDescriptionLabel
@onready var empty_state_label: Label = $EmptyStateLabel
@onready var decrease_difficulty_button = $DifficultySelect/DecreaseDifficultyButton
@onready var difficulty_label = $DifficultySelect/DifficultyLabel
@onready var increase_difficulty_button = $DifficultySelect/IncreaseDifficultyButton
@onready var custom_run_modifier_button_container = $CustomRunModifierButtonContainer
@onready var character_button_container = $CharacterButtonContainer
@onready var start_run_button: Button = $StartRunButton
@onready var seed_input: LineEdit = $SeedInput
@onready var back_button: Button = $BackButton

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0
var run_request_locked := false


func _ready() -> void:
	start_run_button.button_up.connect(_on_start_run_button_up)
	back_button.button_up.connect(_on_back_button_up)
	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)
	seed_input.text_changed.connect(_on_seed_input_text_changed)
	character_button_container.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)


func _on_seed_input_text_changed(new_text: String) -> void:
	var caret_column: int = seed_input.caret_column
	seed_input.text = str(new_text.to_int())
	seed_input.caret_column = min(caret_column, len(seed_input.text))


func _on_character_selected(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data == null:
		selected_character_object_id = ""
		clear_character_info()
		start_run_button.disabled = true
		empty_state_label.visible = true
		return
	selected_character_object_id = character_object_id
	populate_character_info(character_object_id)
	start_run_button.disabled = false
	empty_state_label.visible = false
	character_changed.emit(character_data)


func _on_decrease_difficulty_button() -> void:
	selected_difficulty_level = max(0, selected_difficulty_level - 1)
	difficulty_label.text = "Difficulty " + str(selected_difficulty_level)


func _on_increase_difficulty_button() -> void:
	selected_difficulty_level = min(selected_difficulty_level + 1, len(PlayerData.DIFFICULTY_RUN_MODIFIER_OBJECT_IDS))
	difficulty_label.text = "Difficulty " + str(selected_difficulty_level)


func populate_new_run_menu() -> void:
	run_request_locked = false
	selected_character_object_id = ""
	var has_characters: bool = character_button_container.populate_character_buttons()
	custom_run_modifier_button_container.populate_custom_run_modifiers()
	if not has_characters:
		clear_character_info()
		empty_state_label.visible = true
		start_run_button.disabled = true


func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data == null:
		clear_character_info()
		return
	character_name_label.text = character_data.character_name
	character_health_label.text = "HP: {0}".format([character_data.character_starting_health])
	character_money_label.text = "Money: {0}".format([character_data.character_starting_money])
	character_description_label.text = character_data.character_description
	clear_character_artifact_info()
	if character_data.character_starting_artifact_ids.is_empty():
		return
	var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
	if artifact_data != null:
		character_artifact_texture_rect.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
		character_artifact_name_label.text = artifact_data.artifact_name
		character_artifact_description_label.text = artifact_data.artifact_description


func clear_character_info() -> void:
	character_name_label.text = ""
	character_health_label.text = ""
	character_money_label.text = ""
	character_description_label.text = ""
	clear_character_artifact_info()


func clear_character_artifact_info() -> void:
	character_artifact_texture_rect.texture = FileLoader.load_texture("external/sprites/ui/flipper/icon_menu.png")
	character_artifact_name_label.text = "无初始遗物"
	character_artifact_description_label.text = ""


func _on_start_run_button_up() -> void:
	if run_request_locked or selected_character_object_id.is_empty():
		return
	run_request_locked = true
	run_requested.emit(
		selected_character_object_id,
		seed_input.text.to_int(),
		selected_difficulty_level,
		custom_run_modifier_button_container.selected_custom_run_modififers.duplicate(),
	)


func _on_back_button_up() -> void:
	back_requested.emit()


func _on_run_ended() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	visible = not has_save_file
	populate_new_run_menu()

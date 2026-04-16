# Settings menu for resolution and other options
extends Control

@onready var title_screen: Control = $%TitleScreen
@onready var resolution_option_button: OptionButton = $ResolutionOptionButton
@onready var back_button: Button = $BackButton

func _ready():
	back_button.button_up.connect(_on_back_button_up)
	resolution_option_button.item_selected.connect(_on_resolution_selected)
	_populate_resolution_options()

func _populate_resolution_options() -> void:
	resolution_option_button.clear()

	var current_size: Vector2 = Global.user_settings_data.settings_window_size
	var selected_index: int = -1
	var index: int = 0

	for label: String in ResolutionManager.RESOLUTION_PRESETS.keys():
		resolution_option_button.add_item(label, index)
		var size: Vector2 = ResolutionManager.RESOLUTION_PRESETS[label]
		resolution_option_button.set_item_metadata(index, size)

		if current_size == size:
			selected_index = index

		index += 1

	if selected_index >= 0:
		resolution_option_button.select(selected_index)

func _on_resolution_selected(index: int) -> void:
	var size: Variant = resolution_option_button.get_item_metadata(index)
	if size is Vector2:
		ResolutionManager.apply_resolution(int(size.x), int(size.y))

func _on_back_button_up():
	title_screen.show_main_menu()

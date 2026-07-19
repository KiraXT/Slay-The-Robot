# title screen of game
# composed of sub menus with their own logic
# does nothing except control sub menu display logic
extends Control

const ICON_MENU_PATH := "external/sprites/ui/flipper/icon_menu.png"

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var settings_menu = $SettingsMenu

func _ready():
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)

func hide_menus():
	main_menu.visible = false
	new_run_menu.visible = false
	codex_menu.visible = false
	settings_menu.visible = false

func show_main_menu():
	hide_menus()
	main_menu.visible = true

func show_new_run_menu():
	hide_menus()
	new_run_menu.visible = true
	new_run_menu.populate_new_run_menu()

func show_codex_menu():
	hide_menus()
	codex_menu.visible = true
	codex_menu.populate_codex_menu()

func show_settings_menu():
	hide_menus()
	settings_menu.visible = true

func _load_character_portrait(character_data: CharacterData) -> Texture2D:
	return _load_first_available_character_portrait([
		character_data.character_texture_path,
		character_data.character_icon_texture_path,
		ICON_MENU_PATH,
	])

func _load_first_available_character_portrait(paths: Array[String]) -> Texture2D:
	for path: String in paths:
		var texture := _load_optional_texture(path)
		if texture != null and texture.get_size() != Vector2.ZERO:
			return texture
	return FileLoader.load_texture_or_fallback("", "character")


func _load_optional_texture(path: String) -> Texture2D:
	if not FileLoader._texture_file_exists(path):
		return ImageTexture.new()
	return FileLoader.load_texture(path)

func _on_run_started():
	visible = false

func _on_run_ended():
	visible = true

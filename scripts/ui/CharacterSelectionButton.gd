extends TextureButton
class_name CharacterSelectionButton

const ICON_MENU_PATH := "external/sprites/ui/flipper/icon_menu.png"

var character_object_id: String = ""	# the character id this button represents

func _ready():
	button_up.connect(_on_button_up)
	
func init(_character_object_id: String) -> void:
	character_object_id = _character_object_id
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null:
		texture_normal = _load_avatar_texture(character_data.character_icon_texture_path)

func _on_button_up():
	Signals.character_selected.emit(character_object_id)

func _load_avatar_texture(path: String) -> Texture2D:
	return _load_first_available_avatar_texture([path, ICON_MENU_PATH])

func _load_first_available_avatar_texture(paths: Array[String]) -> Texture2D:
	for path: String in paths:
		var texture := _load_optional_texture(path)
		if texture != null and texture.get_size() != Vector2.ZERO:
			return texture
	return FileLoader.load_texture_or_fallback("", "character")

func _load_optional_texture(path: String) -> Texture2D:
	if not FileLoader._texture_file_exists(path):
		return ImageTexture.new()
	return FileLoader.load_texture(path)

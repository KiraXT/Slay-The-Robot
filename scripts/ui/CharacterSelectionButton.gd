extends TextureButton
class_name CharacterSelectionButton

signal selected(character_object_id: String)

var character_object_id: String = ""


func _ready() -> void:
	button_up.connect(_on_button_up)


func init(_character_object_id: String) -> void:
	character_object_id = _character_object_id
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null and character_data.character_icon_texture_path != "":
		texture_normal = FileLoader.load_texture(character_data.character_icon_texture_path)


func _on_button_up() -> void:
	selected.emit(character_object_id)

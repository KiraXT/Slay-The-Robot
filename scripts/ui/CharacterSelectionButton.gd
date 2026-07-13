extends TextureButton
class_name CharacterSelectionButton

signal selected(character_object_id: String)

const ICON_MENU_PATH := "external/sprites/ui/flipper/icon_menu.png"

var character_object_id: String = ""

@onready var avatar: TextureRect = $AvatarFrame/Avatar
@onready var focus_outline: Control = $FocusOutline
@onready var selection_decoration: Control = $SelectionDecoration


func _ready() -> void:
	button_up.connect(_on_button_up)
	toggled.connect(_on_toggled)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_refresh_selection_decoration(button_pressed)


func init(_character_object_id: String) -> void:
	character_object_id = _character_object_id
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data == null:
		return
	avatar.texture = _load_avatar_texture(character_data.character_icon_texture_path)
	var color_data := Global.get_color_data(character_data.character_color_id)
	if color_data != null:
		selection_decoration.modulate = color_data.color


func _on_button_up() -> void:
	selected.emit(character_object_id)


func _on_toggled(is_selected: bool) -> void:
	_refresh_selection_decoration(is_selected)


func _on_focus_entered() -> void:
	focus_outline.visible = true


func _on_focus_exited() -> void:
	focus_outline.visible = false


func _refresh_selection_decoration(is_selected: bool) -> void:
	selection_decoration.visible = is_selected


func _load_avatar_texture(path: String) -> Texture2D:
	var texture := _load_optional_texture(path)
	if texture == null or texture.get_size() == Vector2.ZERO:
		texture = _load_optional_texture(ICON_MENU_PATH)
	return texture


func _load_optional_texture(path: String) -> Texture2D:
	if not _texture_file_exists(path):
		return null
	return FileLoader.load_texture(path)


func _texture_file_exists(path: String) -> bool:
	return not path.is_empty() and FileAccess.file_exists(FileLoader._get_modified_filepath(path))

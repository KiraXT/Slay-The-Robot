extends TextureButton
class_name CharacterSelectionButton

signal selected(character_object_id: String)

const ICON_MENU_PATH := "external/sprites/ui/flipper/icon_menu.png"

var character_object_id: String = ""
var motion_tween: Tween
var avatar_rest_position: Vector2

@onready var avatar: TextureRect = $AvatarFrame/Avatar
@onready var focus_outline: Control = $FocusOutline
@onready var selection_decoration: Control = $SelectionDecoration


func _ready() -> void:
	avatar_rest_position = avatar.position
	button_up.connect(_on_button_up)
	toggled.connect(_on_toggled)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_refresh_selection_decoration(button_pressed)
	_refresh_focus_outline()


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
	_refresh_focus_outline()


func _on_focus_entered() -> void:
	_animate_avatar_focus(true)
	_refresh_focus_outline()


func _on_focus_exited() -> void:
	_animate_avatar_focus(false)
	_refresh_focus_outline()


func _refresh_selection_decoration(is_selected: bool) -> void:
	selection_decoration.visible = is_selected


func _refresh_focus_outline() -> void:
	focus_outline.visible = button_pressed or has_focus()


func _animate_avatar_focus(focused: bool) -> void:
	if motion_tween != null and motion_tween.is_valid():
		motion_tween.kill()
	motion_tween = create_tween()
	motion_tween.tween_property(avatar, "position:y", avatar_rest_position.y - 8.0 if focused else avatar_rest_position.y, 0.12)


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

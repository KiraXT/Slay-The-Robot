extends RefCounted
class_name ArtUIShell

const ROLE_META := "art_ui_shell_role"

const SURFACE := Color(1.0, 1.0, 1.0, 0.92)
const SURFACE_STRONG := Color(1.0, 1.0, 1.0, 0.98)
const CYAN := Color(0.13, 0.83, 0.84, 1.0)
const CYAN_DARK := Color(0.10, 0.39, 0.47, 1.0)
const BLUE := Color(0.17, 0.49, 0.94, 1.0)
const ORANGE := Color(1.0, 0.69, 0.14, 1.0)
const ORANGE_DEEP := Color(1.0, 0.32, 0.26, 1.0)
const TEXT := Color(0.12, 0.16, 0.21, 1.0)


static func ensure_color_panel(parent: Control, node_name: String, rect: Rect2, role: String, color: Color = SURFACE, insert_after_node_name: String = "") -> ColorRect:
	var panel := parent.get_node_or_null(node_name) as ColorRect
	if panel == null:
		panel = ColorRect.new()
		panel.name = node_name
		parent.add_child(panel)
	_move_panel(parent, panel, insert_after_node_name)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta(ROLE_META, role)
	panel.position = rect.position
	panel.size = rect.size
	panel.color = color
	panel.show()
	return panel


static func ensure_label_badge(parent: Control, node_name: String, rect: Rect2, role: String, color: Color = ORANGE) -> ColorRect:
	var badge := ensure_color_panel(parent, node_name, rect, role, color)
	badge.color = color
	return badge


static func apply_button(button: Button, role: String = "secondary") -> void:
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_box(role, false))
	button.add_theme_stylebox_override("hover", _button_box(role, true))
	button.add_theme_stylebox_override("pressed", _button_box("pressed", true))
	button.add_theme_stylebox_override("disabled", _button_box("disabled", false))


static func apply_label_capsule(label: Label, role: String = "resource") -> void:
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", 26)
	label.set_meta(ROLE_META, role)


static func apply_texture_button_shell(button: TextureButton, role: String = "icon_button") -> void:
	button.set_meta(ROLE_META, role)
	button.modulate = Color.WHITE
	button.self_modulate = Color.WHITE
	button.tooltip_text = button.tooltip_text


static func style_card_shell(background: ColorRect, art_frame: ColorRect, description_panel: ColorRect, faction_badge: ColorRect, faction_color: Color) -> void:
	background.color = Color(1.0, 1.0, 1.0, 0.97)
	art_frame.color = Color(0.89, 0.98, 1.0, 1.0)
	description_panel.color = Color(1.0, 1.0, 1.0, 0.92)
	faction_badge.color = faction_color
	faction_badge.set_meta(ROLE_META, "card_faction")


static func _button_box(role: String, active: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = ORANGE if role == "primary" or active else SURFACE_STRONG
	if role == "pressed":
		box.bg_color = BLUE
	if role == "disabled":
		box.bg_color = Color(0.83, 0.87, 0.90, 0.72)
	box.border_color = ORANGE_DEEP if role == "primary" or active else CYAN
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = 5
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_right = 12
	box.corner_radius_bottom_left = 12
	box.shadow_color = Color(0.07, 0.38, 0.44, 0.20)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func _move_panel(parent: Control, panel: CanvasItem, insert_after_node_name: String) -> void:
	if insert_after_node_name != "":
		var reference := parent.get_node_or_null(insert_after_node_name)
		if reference != null:
			parent.move_child(panel, reference.get_index() + 1)
			return
	parent.move_child(panel, 0)

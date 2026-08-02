extends ScrollContainer

signal character_selected(character_object_id: String)

@onready var grid_container = $GridContainer


func populate_character_buttons() -> bool:
	clear_character_buttons()
	var character_object_ids: Array = Global._id_to_character_data.keys()
	character_object_ids.sort()
	var first_button: TextureButton = null
	var first_character_object_id: String = ""
	for character_object_id: String in character_object_ids:
		var character_selection_button: TextureButton = Scenes.CHARACTER_SELECTION_BUTTON.instantiate()
		grid_container.add_child(character_selection_button)
		character_selection_button.init(character_object_id)
		character_selection_button.connect("selected", _on_button_selected)
		if first_button == null:
			first_button = character_selection_button
			first_character_object_id = character_object_id
	if first_button == null:
		return false
	first_button.button_pressed = true
	first_button.grab_focus()
	first_button.emit_signal("selected", first_character_object_id)
	return true


func clear_character_buttons() -> void:
	for child in grid_container.get_children():
		child.queue_free()


func _on_button_selected(character_object_id: String) -> void:
	character_selected.emit(character_object_id)

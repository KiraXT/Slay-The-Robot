@tool
extends EditorPlugin

const IMPORT_BUTTON_NAME = "Reimport Cards from CSV"

func _enter_tree():
	# Add a menu item to the Project menu
	add_tool_menu_item(IMPORT_BUTTON_NAME, _on_import_cards)

func _exit_tree():
	# Clean up
	remove_tool_menu_item(IMPORT_BUTTON_NAME)

func _on_import_cards():
	var output = []
	var exit_code = OS.execute("python", ["external/tools/csv_to_json.py"], output, true)

	var message = ""
	if output.size() > 0:
		message = output[0]

	if exit_code == 0:
		print("Card import successful!")
		print(message)
		# Show a success dialog
		var dialog = AcceptDialog.new()
		dialog.title = "Card Import"
		dialog.dialog_text = "Cards imported successfully!\n\n" + message
		dialog.dialog_hide_on_ok = true
		get_editor_interface().get_base_control().add_child(dialog)
		dialog.popup_centered(Vector2(400, 300))
	else:
		push_error("Card import failed!")
		push_error(message)
		# Show an error dialog
		var dialog = AcceptDialog.new()
		dialog.title = "Card Import Failed"
		dialog.dialog_text = "Failed to import cards.\n\nCheck the Output panel for details."
		dialog.dialog_hide_on_ok = true
		get_editor_interface().get_base_control().add_child(dialog)
		dialog.popup_centered(Vector2(400, 200))

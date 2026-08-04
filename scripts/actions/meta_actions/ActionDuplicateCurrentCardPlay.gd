# Requests one free duplicate of the current card play.
extends BaseAction


func is_instant_action() -> bool:
	return true


func perform_action() -> void:
	if card_play_request == null:
		return
	if card_play_request.card_data == null:
		return
	if bool(get_action_value("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return

	var duplicate_request: CardPlayRequest = CardPlayRequest.new()
	duplicate_request.card_data = card_play_request.card_data
	duplicate_request.selected_target = card_play_request.selected_target
	duplicate_request.card_values = card_play_request.card_values.duplicate(true)
	duplicate_request.refundable_energy = 0
	duplicate_request.input_energy = card_play_request.input_energy
	duplicate_request.is_duplicate_play = true

	var front_of_queue: bool = bool(get_action_value("front_of_queue", true))
	Signals.card_play_requested.emit(duplicate_request, false, front_of_queue)


func _to_string() -> String:
	return "Duplicate Current Card Play Action"

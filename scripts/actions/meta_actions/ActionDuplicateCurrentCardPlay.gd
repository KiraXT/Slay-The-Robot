# Requests a free duplicate play of the current card.
extends BaseAction

func is_instant_action() -> bool:
	return true

func perform_action() -> void:
	if card_play_request == null or card_play_request.card_data == null:
		return
	if card_play_request.is_duplicate_play:
		return

	var duplicate_request: CardPlayRequest = CardPlayRequest.new()
	duplicate_request.card_data = card_play_request.card_data
	duplicate_request.selected_target = card_play_request.selected_target
	duplicate_request.card_values = card_play_request.card_values.duplicate(true)
	duplicate_request.refundable_energy = 0
	duplicate_request.input_energy = card_play_request.input_energy
	duplicate_request.is_duplicate_play = true
	duplicate_request.hand_at_play_time = card_play_request.hand_at_play_time.duplicate(false)
	Signals.card_play_requested.emit(duplicate_request, false, true)

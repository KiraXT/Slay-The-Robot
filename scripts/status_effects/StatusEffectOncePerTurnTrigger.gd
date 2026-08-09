# Generic status effect that executes configured actions the first N times a matching event happens each player turn.
extends BaseStatusEffect

var triggers_this_turn: int = 0


func _connect_signals() -> void:
	Signals.player_turn_started.connect(_on_player_turn_started)
	if bool(status_custom_values.get("expire_on_player_turn_ended", false)):
		Signals.player_turn_ended.connect(_on_player_turn_ended)

	var trigger_signal: String = str(status_custom_values.get("trigger_signal", ""))
	match trigger_signal:
		"card_play_started":
			Signals.card_play_started.connect(_on_card_play_event)
		"card_played":
			Signals.card_played.connect(_on_card_play_event)
		"card_drawn":
			Signals.card_drawn.connect(_on_card_data_event)
		"card_discarded":
			Signals.card_discarded.connect(_on_card_discarded)
		"card_exhausted":
			Signals.card_exhausted.connect(_on_card_data_event)
		_:
			push_error("Unsupported once-per-turn trigger_signal: %s" % trigger_signal)


func _disconnect_signals() -> void:
	if Signals.player_turn_started.is_connected(_on_player_turn_started):
		Signals.player_turn_started.disconnect(_on_player_turn_started)
	if Signals.player_turn_ended.is_connected(_on_player_turn_ended):
		Signals.player_turn_ended.disconnect(_on_player_turn_ended)

	var trigger_signal: String = str(status_custom_values.get("trigger_signal", ""))
	match trigger_signal:
		"card_play_started":
			if Signals.card_play_started.is_connected(_on_card_play_event):
				Signals.card_play_started.disconnect(_on_card_play_event)
		"card_played":
			if Signals.card_played.is_connected(_on_card_play_event):
				Signals.card_played.disconnect(_on_card_play_event)
		"card_drawn":
			if Signals.card_drawn.is_connected(_on_card_data_event):
				Signals.card_drawn.disconnect(_on_card_data_event)
		"card_discarded":
			if Signals.card_discarded.is_connected(_on_card_discarded):
				Signals.card_discarded.disconnect(_on_card_discarded)
		"card_exhausted":
			if Signals.card_exhausted.is_connected(_on_card_data_event):
				Signals.card_exhausted.disconnect(_on_card_data_event)


func _on_player_turn_started() -> void:
	triggers_this_turn = 0


func _on_player_turn_ended() -> void:
	_consume_charges(status_charges)


func _on_card_play_event(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	_attempt_trigger(card_play_request.card_data, card_play_request)


func _on_card_data_event(card_data: CardData) -> void:
	var card_play_request: CardPlayRequest = CardPlayRequest.new()
	card_play_request.card_data = card_data
	if card_data != null:
		card_play_request.card_values = card_data.card_values.duplicate(true)
	_attempt_trigger(card_data, card_play_request)


func _on_card_discarded(card_data: CardData, _is_manual_discard: bool) -> void:
	_on_card_data_event(card_data)


func _attempt_trigger(card_data: CardData, card_play_request: CardPlayRequest) -> void:
	if status_charges <= 0:
		return
	if not Global.is_player_turn():
		return
	if not _can_trigger(card_data):
		return

	var max_triggers_per_turn: int = int(status_custom_values.get("max_triggers_per_turn", 1))
	if triggers_this_turn >= max_triggers_per_turn:
		return

	var action_data: Array[Dictionary] = []
	action_data.assign(status_custom_values.get("action_data", []))
	if action_data.is_empty():
		return

	triggers_this_turn += 1
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [parent_combatant], action_data, null)
	ActionHandler.add_actions(generated_actions)
	if bool(status_custom_values.get("consume_charge_on_trigger", false)):
		_consume_charges(1)


func _can_trigger(card_data: CardData) -> bool:
	if card_data == null:
		return false
	if status_custom_values.has("card_object_id_filter"):
		if card_data.object_id != str(status_custom_values["card_object_id_filter"]):
			return false
	if status_custom_values.has("card_type_filter"):
		var filter_value: Variant = status_custom_values["card_type_filter"]
		if filter_value is Array:
			var accepted_types: Array[int] = []
			accepted_types.assign(filter_value)
			return accepted_types.has(card_data.card_type)
		return card_data.card_type == int(filter_value)
	return true


func _consume_charges(charge_amount: int) -> void:
	if charge_amount <= 0:
		return
	if parent_combatant == null:
		return
	var removed_charges: int = min(charge_amount, status_charges)
	if removed_charges > 0:
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -removed_charges, 0)

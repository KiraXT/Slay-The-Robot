# Modifies the next matching card play request, then optionally consumes itself.
extends BaseStatusEffect

func _connect_signals() -> void:
	Signals.card_play_started.connect(_on_card_play_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)

func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if parent_combatant == null:
		return
	if not parent_combatant.is_alive():
		return
	if not Global.is_player_turn():
		return
	if card_play_request == null or card_play_request.card_data == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	if not _matches_card(card_play_request.card_data):
		return

	_apply_value_modifiers(card_play_request)

	if bool(status_custom_values.get("consume_charge_on_trigger", true)):
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -1)

func _on_player_turn_ended() -> void:
	if parent_combatant == null:
		return
	if bool(status_custom_values.get("clear_on_player_turn_end", true)) and status_charges != 0:
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -status_charges)

func _matches_card(card_data: CardData) -> bool:
	if card_data == null:
		return false
	if status_custom_values.has("card_object_id_filter"):
		var filter_value: Variant = status_custom_values["card_object_id_filter"]
		if filter_value is Array:
			var accepted_ids: Array[String] = []
			accepted_ids.assign(filter_value)
			if not accepted_ids.has(card_data.object_id):
				return false
		elif card_data.object_id != str(filter_value):
			return false
	if status_custom_values.has("card_type_filter"):
		var type_filter: Variant = status_custom_values["card_type_filter"]
		if type_filter is Array:
			var accepted_types: Array[int] = []
			accepted_types.assign(type_filter)
			if not accepted_types.has(card_data.card_type):
				return false
		elif card_data.card_type != int(type_filter):
			return false
	return true

func _apply_value_modifiers(card_play_request: CardPlayRequest) -> void:
	var value_modifiers: Dictionary = status_custom_values.get("value_modifiers", {})
	for value_key in value_modifiers.keys():
		if not card_play_request.card_values.has(value_key):
			continue
		var existing_value: int = int(card_play_request.card_values[value_key])
		var modifier: int = int(value_modifiers[value_key])
		card_play_request.card_values[value_key] = max(0, existing_value + modifier)

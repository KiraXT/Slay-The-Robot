# Modifies the next matching card play request, then optionally consumes itself.
extends BaseStatusEffect

var is_active: bool = true
var value_modifier_queue: Array[Dictionary] = []

func _connect_signals() -> void:
	Signals.card_play_started.connect(_on_card_play_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)

func _disconnect_signals() -> void:
	is_active = false
	if Signals.card_play_started.is_connected(_on_card_play_started):
		Signals.card_play_started.disconnect(_on_card_play_started)
	if Signals.player_turn_ended.is_connected(_on_player_turn_ended):
		Signals.player_turn_ended.disconnect(_on_player_turn_ended)

func on_status_reapplied(charge_amount: int, _secondary_charge_amount: int, custom_values: Dictionary) -> void:
	if charge_amount <= 0:
		return
	_ensure_value_modifier_queue()
	var reapplied_value_modifiers: Dictionary = custom_values.get("value_modifiers", status_custom_values.get("value_modifiers", {}))
	if reapplied_value_modifiers.is_empty():
		return
	for _i in range(charge_amount):
		value_modifier_queue.append(reapplied_value_modifiers.duplicate(true))

func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if not is_active:
		return
	if parent_combatant == null:
		return
	if status_charges <= 0:
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

	var value_modifiers: Dictionary = _get_next_value_modifiers()
	_apply_value_modifiers(card_play_request, value_modifiers)

	if bool(status_custom_values.get("consume_charge_on_trigger", true)):
		_consume_next_value_modifiers()
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -1)

func _on_player_turn_ended() -> void:
	if not is_active:
		return
	if parent_combatant == null:
		return
	if status_charges <= 0:
		return
	if bool(status_custom_values.get("clear_on_player_turn_end", true)):
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -status_charges)

func _matches_card(card_data: CardData) -> bool:
	if card_data == null:
		return false
	if status_custom_values.has("card_object_id_filter"):
		var filter_value: Variant = status_custom_values["card_object_id_filter"]
		if filter_value is Array:
			var matches_object_id: bool = false
			for accepted_id in filter_value:
				if str(accepted_id) == card_data.object_id:
					matches_object_id = true
					break
			if not matches_object_id:
				return false
		elif card_data.object_id != str(filter_value):
			return false
	if status_custom_values.has("card_type_filter"):
		var type_filter: Variant = status_custom_values["card_type_filter"]
		if type_filter is Array:
			var matches_card_type: bool = false
			for accepted_type in type_filter:
				if int(accepted_type) == card_data.card_type:
					matches_card_type = true
					break
			if not matches_card_type:
				return false
		elif card_data.card_type != int(type_filter):
			return false
	if status_custom_values.has("card_tag_filter"):
		var tag_filter: Variant = status_custom_values["card_tag_filter"]
		if tag_filter is Array:
			var matches_card_tag: bool = false
			for accepted_tag in tag_filter:
				if card_data.card_tags.has(str(accepted_tag)):
					matches_card_tag = true
					break
			if not matches_card_tag:
				return false
		elif not card_data.card_tags.has(str(tag_filter)):
			return false
	return true

func _apply_value_modifiers(card_play_request: CardPlayRequest, value_modifiers: Dictionary) -> void:
	for value_key in value_modifiers.keys():
		if not card_play_request.card_values.has(value_key):
			continue
		var existing_value: int = int(card_play_request.card_values[value_key])
		var modifier: int = int(value_modifiers[value_key])
		card_play_request.card_values[value_key] = max(0, existing_value + modifier)

func _get_next_value_modifiers() -> Dictionary:
	_ensure_value_modifier_queue()
	if not value_modifier_queue.is_empty():
		return value_modifier_queue[0]
	return status_custom_values.get("value_modifiers", {})

func _consume_next_value_modifiers() -> void:
	_ensure_value_modifier_queue()
	if not value_modifier_queue.is_empty():
		value_modifier_queue.pop_front()

func _ensure_value_modifier_queue() -> void:
	if not value_modifier_queue.is_empty():
		return
	var value_modifiers: Dictionary = status_custom_values.get("value_modifiers", {})
	if value_modifiers.is_empty():
		return
	for _i in range(status_charges):
		value_modifier_queue.append(value_modifiers.duplicate(true))

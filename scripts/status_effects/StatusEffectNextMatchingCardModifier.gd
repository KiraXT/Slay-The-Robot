# Modifies the next matching card play request, then optionally consumes itself.
extends BaseStatusEffect

var value_modifier_queue: Array[Dictionary] = []


func _connect_signals() -> void:
	Signals.card_play_started.connect(_on_card_play_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)
	_queue_custom_values(status_custom_values)


func _disconnect_signals() -> void:
	if Signals.card_play_started.is_connected(_on_card_play_started):
		Signals.card_play_started.disconnect(_on_card_play_started)
	if Signals.player_turn_ended.is_connected(_on_player_turn_ended):
		Signals.player_turn_ended.disconnect(_on_player_turn_ended)


func on_status_reapplied(_charge_amount: int, _secondary_charge_amount: int, custom_values: Dictionary) -> void:
	_queue_custom_values(custom_values)


func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if parent_combatant == null:
		return
	if not parent_combatant.is_alive():
		return
	if not Global.is_player_turn():
		return
	if card_play_request == null or card_play_request.card_data == null:
		return
	var trigger_values := _get_next_trigger_values()
	if bool(trigger_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	if not _matches_card(card_play_request.card_data, trigger_values):
		return

	_apply_value_modifiers(card_play_request, trigger_values)

	if bool(trigger_values.get("consume_charge_on_trigger", true)):
		if not value_modifier_queue.is_empty():
			value_modifier_queue.pop_front()
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -1)


func _on_player_turn_ended() -> void:
	if parent_combatant == null:
		return
	if bool(status_custom_values.get("clear_on_player_turn_end", true)) and status_charges != 0:
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -status_charges)


func _matches_card(card_data: CardData, trigger_values: Dictionary) -> bool:
	if card_data == null:
		return false
	if trigger_values.has("card_object_id_filter"):
		var filter_value: Variant = trigger_values["card_object_id_filter"]
		if filter_value is Array:
			var accepted_ids: Array[String] = []
			for item in filter_value:
				accepted_ids.append(str(item))
			if not accepted_ids.has(card_data.object_id):
				return false
		elif card_data.object_id != str(filter_value):
			return false
	if trigger_values.has("card_type_filter"):
		var type_filter: Variant = trigger_values["card_type_filter"]
		if type_filter is Array:
			var accepted_types: Array[int] = []
			for item in type_filter:
				accepted_types.append(int(item))
			if not accepted_types.has(card_data.card_type):
				return false
		elif card_data.card_type != int(type_filter):
			return false
	if trigger_values.has("card_tag_filter"):
		var required_tags := _get_string_array(trigger_values, "card_tag_filter")
		if required_tags.is_empty():
			return true
		var matched_tags := 0
		for card_tag: String in required_tags:
			if card_data.card_tags.has(card_tag):
				matched_tags += 1
		if matched_tags == 0:
			return false
		if bool(trigger_values.get("require_all_tags", true)) and matched_tags < required_tags.size():
			return false
	return true


func _apply_value_modifiers(card_play_request: CardPlayRequest, trigger_values: Dictionary) -> void:
	var value_modifiers: Dictionary = trigger_values.get("value_modifiers", {})
	var operation: String = str(trigger_values.get("operation", "add"))
	for value_key in value_modifiers.keys():
		if not card_play_request.card_values.has(value_key):
			continue
		var existing_value: int = int(card_play_request.card_values[value_key])
		var modifier: int = int(value_modifiers[value_key])
		if operation == "set":
			card_play_request.card_values[value_key] = modifier
		else:
			card_play_request.card_values[value_key] = max(0, existing_value + modifier)


func _queue_custom_values(custom_values: Dictionary) -> void:
	if custom_values.is_empty():
		return
	value_modifier_queue.append(custom_values.duplicate(true))


func _get_next_trigger_values() -> Dictionary:
	if not value_modifier_queue.is_empty():
		return value_modifier_queue[0]
	return status_custom_values


func _get_string_array(trigger_values: Dictionary, key: String) -> Array[String]:
	var returned: Array[String] = []
	var value: Variant = trigger_values.get(key, [])
	if value is Array:
		for item in value:
			returned.append(str(item))
		return returned
	if value is PackedStringArray:
		for item in value:
			returned.append(item)
		return returned
	if value is String:
		var text: String = value.strip_edges()
		if text != "":
			returned.append(text)
	return returned

# Executes configured actions for card instances carrying runtime tags.
extends BaseStatusEffect

var triggers_total: int = 0
var is_armed: bool = true


func _connect_signals() -> void:
	is_armed = not bool(status_custom_values.get("arm_on_next_player_turn", false))
	Signals.player_turn_started.connect(_on_player_turn_started)

	if _should_expire_on_player_turn_end():
		Signals.player_turn_ended.connect(_on_player_turn_ended)

	var trigger_signal: String = _get_trigger_signal()
	match trigger_signal:
		"card_play_started":
			Signals.card_play_started.connect(_on_card_play_started)
		"card_played":
			Signals.card_played.connect(_on_card_played)
		"card_drawn":
			Signals.card_drawn.connect(_on_card_drawn)
		"card_discarded":
			Signals.card_discarded.connect(_on_card_discarded)
		"card_exhausted":
			Signals.card_exhausted.connect(_on_card_exhausted)
		"player_turn_started":
			pass
		_:
			push_error("Unsupported tagged-card trigger_signal: %s" % trigger_signal)


func _disconnect_signals() -> void:
	if Signals.player_turn_started.is_connected(_on_player_turn_started):
		Signals.player_turn_started.disconnect(_on_player_turn_started)
	if Signals.player_turn_ended.is_connected(_on_player_turn_ended):
		Signals.player_turn_ended.disconnect(_on_player_turn_ended)

	var trigger_signal: String = _get_trigger_signal()
	match trigger_signal:
		"card_play_started":
			if Signals.card_play_started.is_connected(_on_card_play_started):
				Signals.card_play_started.disconnect(_on_card_play_started)
		"card_played":
			if Signals.card_played.is_connected(_on_card_played):
				Signals.card_played.disconnect(_on_card_played)
		"card_drawn":
			if Signals.card_drawn.is_connected(_on_card_drawn):
				Signals.card_drawn.disconnect(_on_card_drawn)
		"card_discarded":
			if Signals.card_discarded.is_connected(_on_card_discarded):
				Signals.card_discarded.disconnect(_on_card_discarded)
		"card_exhausted":
			if Signals.card_exhausted.is_connected(_on_card_exhausted):
				Signals.card_exhausted.disconnect(_on_card_exhausted)


func _on_player_turn_started() -> void:
	if bool(status_custom_values.get("arm_on_next_player_turn", false)) and not is_armed:
		is_armed = true
	if _get_trigger_signal() == "player_turn_started":
		_attempt_trigger_for_cards(_get_matching_cards_from_piles(), null)


func _on_player_turn_ended() -> void:
	if bool(status_custom_values.get("arm_on_next_player_turn", false)) and not is_armed:
		return
	if _should_remove_card_tags_on_expire():
		for card_data: CardData in _get_matching_cards_from_piles():
			_remove_configured_tags(card_data)
	_consume_charges(status_charges)


func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	_attempt_trigger_for_cards([card_play_request.card_data], card_play_request)


func _on_card_played(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	_attempt_trigger_for_cards([card_play_request.card_data], card_play_request)


func _on_card_drawn(card_data: CardData) -> void:
	_attempt_trigger_for_cards([card_data], null)


func _on_card_discarded(card_data: CardData, _is_manual_discard: bool) -> void:
	_attempt_trigger_for_cards([card_data], null)


func _on_card_exhausted(card_data: CardData) -> void:
	_attempt_trigger_for_cards([card_data], null)


func _attempt_trigger_for_cards(cards: Array, event_card_play_request: CardPlayRequest) -> void:
	if not _can_attempt_trigger():
		return

	var matching_cards: Array[CardData] = []
	for candidate in cards:
		if candidate is CardData and _card_matches(candidate):
			if not matching_cards.has(candidate):
				matching_cards.append(candidate)
	if matching_cards.is_empty():
		return

	var action_data: Array[Dictionary] = []
	action_data.assign(status_custom_values.get("action_data", []))

	var processed_count: int = 0
	for card_data: CardData in matching_cards:
		if _has_reached_max_triggers():
			break

		var card_play_request: CardPlayRequest = event_card_play_request
		if card_play_request == null or card_play_request.card_data != card_data:
			card_play_request = _create_card_play_request(card_data)

		if not action_data.is_empty():
			var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [parent_combatant], action_data, null)
			ActionHandler.add_actions(generated_actions)

		triggers_total += 1
		processed_count += 1

		if _should_remove_tag_on_trigger():
			_remove_configured_tags(card_data)

	if processed_count > 0 and bool(status_custom_values.get("consume_charge_on_trigger", false)):
		_consume_charges(processed_count)


func _can_attempt_trigger() -> bool:
	if status_charges <= 0:
		return false
	if not is_armed:
		return false
	if _has_reached_max_triggers():
		return false

	var require_player_turn: bool = bool(status_custom_values.get("require_player_turn", _get_trigger_signal() != "player_turn_started"))
	if require_player_turn and not Global.is_player_turn():
		return false
	return true


func _has_reached_max_triggers() -> bool:
	var max_triggers_total: int = int(status_custom_values.get("max_triggers_total", 0))
	return max_triggers_total > 0 and triggers_total >= max_triggers_total


func _card_matches(card_data: CardData) -> bool:
	if card_data == null:
		return false

	if status_custom_values.has("card_object_id_filter"):
		if card_data.object_id != str(status_custom_values["card_object_id_filter"]):
			return false

	if status_custom_values.has("card_type_filter"):
		var accepted_types: Array[int] = []
		var filter_value: Variant = status_custom_values["card_type_filter"]
		if filter_value is Array:
			for item in filter_value:
				accepted_types.append(int(item))
		else:
			accepted_types.append(int(filter_value))
		if not accepted_types.has(card_data.card_type):
			return false

	var required_tags: Array[String] = _get_string_array("card_tags", [])
	if not required_tags.is_empty():
		var matched_tags: int = 0
		for card_tag: String in required_tags:
			if card_data.card_tags.has(card_tag):
				matched_tags += 1
		if matched_tags == 0:
			return false
		if bool(status_custom_values.get("require_all_tags", true)) and matched_tags < required_tags.size():
			return false

	return true


func _get_matching_cards_from_piles() -> Array[CardData]:
	var matching_cards: Array[CardData] = []
	for pile_name: String in _get_string_array("search_card_piles", ["hand"]):
		for card_data in _get_pile_by_name(pile_name):
			if card_data is CardData and _card_matches(card_data):
				if not matching_cards.has(card_data):
					matching_cards.append(card_data)
	return matching_cards


func _get_pile_by_name(pile_name: String) -> Array:
	if Global.player_data == null:
		return []
	match pile_name:
		"hand":
			return Global.player_data.player_hand
		"draw":
			return Global.player_data.player_draw
		"discard":
			return Global.player_data.player_discard
		"exhaust":
			return Global.player_data.player_exhaust
		"combat", "all":
			var cards: Array = []
			cards.append_array(Global.player_data.player_hand)
			cards.append_array(Global.player_data.player_draw)
			cards.append_array(Global.player_data.player_discard)
			cards.append_array(Global.player_data.player_exhaust)
			return cards
	return []


func _create_card_play_request(card_data: CardData) -> CardPlayRequest:
	var card_play_request: CardPlayRequest = CardPlayRequest.new()
	card_play_request.card_data = card_data
	card_play_request.card_values = card_data.card_values.duplicate(true)
	return card_play_request


func _remove_configured_tags(card_data: CardData) -> void:
	var changed: bool = false
	for card_tag: String in _get_string_array("card_tags", []):
		if card_data.card_tags.has(card_tag):
			card_data.remove_card_tag(card_tag)
			changed = true
	for card_tag: String in _get_string_array("card_tags_to_remove_on_trigger", []):
		if card_data.card_tags.has(card_tag):
			card_data.remove_card_tag(card_tag)
			changed = true
	if changed:
		Signals.card_properties_changed.emit(card_data)


func _should_remove_tag_on_trigger() -> bool:
	return bool(status_custom_values.get("remove_tag_on_trigger", status_custom_values.get("remove_card_tags_on_trigger", true)))


func _should_expire_on_player_turn_end() -> bool:
	return bool(status_custom_values.get("expire_on_player_turn_end", status_custom_values.get("expire_on_player_turn_ended", false)))


func _should_remove_card_tags_on_expire() -> bool:
	return bool(status_custom_values.get("remove_card_tags_on_expire", false))


func _consume_charges(charge_amount: int) -> void:
	if charge_amount <= 0:
		return
	if parent_combatant == null:
		return
	var removed_charges: int = min(charge_amount, status_charges)
	if removed_charges > 0:
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -removed_charges, 0)


func _get_trigger_signal() -> String:
	return str(status_custom_values.get("trigger_signal", ""))


func _get_string_array(key: String, default_value: Array = []) -> Array[String]:
	var returned: Array[String] = []
	var value: Variant = status_custom_values.get(key, default_value)
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

# Executes configured actions when a tagged runtime card matches a configured event.
extends BaseStatusEffect

var is_active: bool = true
var trigger_is_connected: bool = false
var active_window_started: bool = false

func _connect_signals() -> void:
	is_active = not bool(status_custom_values.get("activate_on_next_player_turn", false))
	active_window_started = is_active
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)

	var trigger_signal: String = str(status_custom_values.get("trigger_signal", ""))
	match trigger_signal:
		"card_drawn":
			Signals.card_drawn.connect(_on_card_data_event)
			trigger_is_connected = true
		"card_play_started":
			Signals.card_play_started.connect(_on_card_play_started)
			trigger_is_connected = true
		"player_turn_started":
			trigger_is_connected = true
		_:
			push_error("Unsupported tagged card trigger_signal: %s" % trigger_signal)

func _disconnect_signals() -> void:
	if Signals.player_turn_started.is_connected(_on_player_turn_started):
		Signals.player_turn_started.disconnect(_on_player_turn_started)
	if Signals.player_turn_ended.is_connected(_on_player_turn_ended):
		Signals.player_turn_ended.disconnect(_on_player_turn_ended)
	if Signals.card_drawn.is_connected(_on_card_data_event):
		Signals.card_drawn.disconnect(_on_card_data_event)
	if Signals.card_play_started.is_connected(_on_card_play_started):
		Signals.card_play_started.disconnect(_on_card_play_started)

func _on_player_turn_started() -> void:
	is_active = true
	active_window_started = true
	if str(status_custom_values.get("trigger_signal", "")) == "player_turn_started":
		for card_data: CardData in _get_all_tagged_cards():
			_attempt_trigger(card_data, _make_card_play_request(card_data))

func _on_player_turn_ended() -> void:
	if bool(status_custom_values.get("expire_on_player_turn_end", false)) and active_window_started:
		_remove_tags_from_cards(_get_all_tagged_cards())
		if parent_combatant != null and status_charges > 0:
			parent_combatant.add_status_effect_charges(status_effect_data.object_id, -status_charges)

func _on_card_data_event(card_data: CardData) -> void:
	_attempt_trigger(card_data, _make_card_play_request(card_data))

func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null:
		return
	if bool(status_custom_values.get("ignore_duplicate_plays", true)) and card_play_request.is_duplicate_play:
		return
	_attempt_trigger(card_play_request.card_data, card_play_request)

func _attempt_trigger(card_data: CardData, card_play_request: CardPlayRequest) -> void:
	if not is_active:
		return
	if status_charges <= 0:
		return
	if card_data == null:
		return
	if not _matches_card(card_data):
		return

	var action_data: Array = status_custom_values.get("action_data", [])
	if not action_data.is_empty():
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [parent_combatant], _with_picked_card(action_data, card_data), null)
		ActionHandler.add_actions(generated_actions)

	if bool(status_custom_values.get("remove_tag_on_trigger", true)):
		_remove_tags_from_cards([card_data])

	if bool(status_custom_values.get("consume_charge_on_trigger", false)) and parent_combatant != null:
		parent_combatant.add_status_effect_charges(status_effect_data.object_id, -1)

func _matches_card(card_data: CardData) -> bool:
	if not _matches_tag_filter(card_data):
		return false
	if status_custom_values.has("card_type_filter"):
		var type_filter: Variant = status_custom_values["card_type_filter"]
		if type_filter is Array:
			for accepted_type in type_filter:
				if int(accepted_type) == card_data.card_type:
					return true
			return false
		return card_data.card_type == int(type_filter)
	return true

func _matches_tag_filter(card_data: CardData) -> bool:
	var tag_filter: Variant = status_custom_values.get("card_tag_filter", [])
	if tag_filter is String:
		return card_data.card_tags.has(str(tag_filter))
	if tag_filter is Array:
		for tag in tag_filter:
			if card_data.card_tags.has(str(tag)):
				return true
		return false
	return false

func _get_all_tagged_cards() -> Array[CardData]:
	var tagged_cards: Array[CardData] = []
	var piles: Array = [
		Global.player_data.player_hand,
		Global.player_data.player_draw,
		Global.player_data.player_discard,
		Global.player_data.player_exhaust,
	]
	for pile: Array in piles:
		for card_data: CardData in pile:
			if card_data != null and _matches_card(card_data) and not tagged_cards.has(card_data):
				tagged_cards.append(card_data)
	return tagged_cards

func _remove_tags_from_cards(cards: Array) -> void:
	var tag_filter: Variant = status_custom_values.get("card_tag_filter", [])
	var tags_to_remove: Array[String] = []
	if tag_filter is String:
		tags_to_remove.append(str(tag_filter))
	elif tag_filter is Array:
		for tag in tag_filter:
			tags_to_remove.append(str(tag))

	for card_data: CardData in cards:
		if card_data == null:
			continue
		for tag: String in tags_to_remove:
			card_data.remove_card_tag(tag)
		Signals.card_properties_changed.emit(card_data)

func _with_picked_card(action_data: Array, card_data: CardData) -> Array:
	var prepared_actions: Array = action_data.duplicate(true)
	for action_entry in prepared_actions:
		if not (action_entry is Dictionary):
			continue
		for script_path in action_entry.keys():
			if action_entry[script_path] is Dictionary:
				action_entry[script_path]["picked_cards"] = [card_data]
	return prepared_actions

func _make_card_play_request(card_data: CardData) -> CardPlayRequest:
	var card_play_request: CardPlayRequest = CardPlayRequest.new()
	card_play_request.card_data = card_data
	if card_data != null:
		card_play_request.card_values = card_data.card_values.duplicate(true)
	return card_play_request

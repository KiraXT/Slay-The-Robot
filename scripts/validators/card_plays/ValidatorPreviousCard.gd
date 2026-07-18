# Validator for checking the card played immediately before the current card this turn.
extends BaseValidator


func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var card_play_request: CardPlayRequest = null
	if action != null:
		card_play_request = action.card_play_request

	var combat_stats_data: CombatStatsData = Global.get_combat_stats()
	if combat_stats_data == null:
		return false != _get_bool(values, "invert", false)

	var previous_card: CardData = _get_previous_card(combat_stats_data, card_play_request)
	var must_exist: bool = _get_bool(values, "must_exist", true)
	if previous_card == null:
		return (not must_exist) != _get_bool(values, "invert", false)

	var matches: bool = _matches_previous_card(previous_card, values)
	return matches != _get_bool(values, "invert", false)


func _get_previous_card(combat_stats_data: CombatStatsData, current_request: CardPlayRequest) -> CardData:
	for index in range(combat_stats_data.cards_played_this_turn.size() - 1, -1, -1):
		var request: CardPlayRequest = combat_stats_data.cards_played_this_turn[index]
		if request == current_request:
			continue
		if request.card_data != null:
			return request.card_data
	return null


func _matches_previous_card(previous_card: CardData, values: Dictionary[String, Variant]) -> bool:
	var matches: bool = true
	if values.has("card_type"):
		matches = matches and previous_card.card_type == int(values["card_type"])
	if values.has("card_types"):
		var card_types: Array[int] = []
		card_types.assign(values["card_types"])
		matches = matches and card_types.has(previous_card.card_type)
	if values.has("card_object_id"):
		matches = matches and previous_card.object_id == str(values["card_object_id"])
	if values.has("card_object_ids"):
		var card_object_ids: Array[String] = []
		card_object_ids.assign(values["card_object_ids"])
		matches = matches and card_object_ids.has(previous_card.object_id)
	if values.has("card_tag"):
		matches = matches and previous_card.card_tags.has(str(values["card_tag"]))
	if values.has("card_tags"):
		var card_tags: Array[String] = []
		card_tags.assign(values["card_tags"])
		var has_tag := false
		for card_tag: String in card_tags:
			if previous_card.card_tags.has(card_tag):
				has_tag = true
				break
		matches = matches and has_tag
	return matches


func _get_bool(values: Dictionary[String, Variant], key: String, default_value: bool) -> bool:
	if not values.has(key):
		return default_value
	var value: Variant = values[key]
	if value is bool:
		return value
	if value is String:
		return value.to_lower() in ["true", "yes", "1"]
	return bool(value)

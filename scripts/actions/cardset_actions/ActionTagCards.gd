# Adds or removes runtime tags on selected card instances.
extends BaseCardsetAction


func perform_action() -> void:
	var tags_to_add: Array[String] = _coerce_string_array(
		get_action_value("card_tags_to_add", get_action_value("card_tags", [])),
		"card_tags_to_add"
	)
	var tags_to_remove: Array[String] = _coerce_string_array(
		get_action_value("card_tags_to_remove", []),
		"card_tags_to_remove"
	)
	var picked_cards: Array[CardData] = _get_picked_cards()

	for card_data: CardData in picked_cards:
		var changed: bool = false
		for card_tag: String in tags_to_add:
			if not card_data.card_tags.has(card_tag):
				card_data.add_card_tag(card_tag)
				changed = true
		for card_tag: String in tags_to_remove:
			if card_data.card_tags.has(card_tag):
				card_data.remove_card_tag(card_tag)
				changed = true
		if changed:
			Signals.card_properties_changed.emit(card_data)


func _to_string() -> String:
	return "Tag Cards Action"

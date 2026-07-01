# Adds or removes runtime tags on picked cards.
extends BaseCardsetAction

func perform_action() -> void:
	var add_tags: Array[String] = []
	add_tags.assign(get_action_value("add_tags", []))
	var remove_tags: Array[String] = []
	remove_tags.assign(get_action_value("remove_tags", []))

	for card_data: CardData in _get_picked_cards():
		if card_data == null:
			continue
		for card_tag: String in add_tags:
			card_data.add_card_tag(card_tag)
		for card_tag: String in remove_tags:
			card_data.remove_card_tag(card_tag)
		Signals.card_properties_changed.emit(card_data)

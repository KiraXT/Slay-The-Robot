# Validator for checking the previous card played this turn.
extends BaseValidator


func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var card_types: Array[int] = []
	card_types.assign(_get_validator_value("card_types", values, _action, []))
	if card_types.is_empty():
		return false

	var combat_stats_data: CombatStatsData = Global.get_combat_stats()
	if combat_stats_data == null:
		return false

	var previous_card_play: CardPlayRequest = combat_stats_data.get_turn_last_card_play()
	if previous_card_play == null or previous_card_play.card_data == null:
		return false

	return card_types.has(previous_card_play.card_data.card_type)

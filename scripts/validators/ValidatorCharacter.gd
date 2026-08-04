## Validator for checking the current player's character.
extends BaseValidator

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var character_object_ids: Array[String] = []
	character_object_ids.assign(_get_validator_value("character_object_ids", values, _action, []))
	if character_object_ids.is_empty():
		return true
	return character_object_ids.has(Global.player_data.player_character_object_id)

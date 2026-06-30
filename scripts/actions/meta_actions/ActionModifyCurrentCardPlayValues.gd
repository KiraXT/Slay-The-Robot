# Modifies values on the current CardPlayRequest only. Does not mutate CardData.
extends BaseAction

func is_instant_action() -> bool:
	return true

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		if card_play_request == null:
			continue

		var value_modifiers: Dictionary = action_interceptor_processor.get_shadowed_action_values("value_modifiers", {})
		var operation: String = action_interceptor_processor.get_shadowed_action_values("operation", "add")
		for value_key in value_modifiers.keys():
			var existing_value: int = int(card_play_request.card_values.get(value_key, 0))
			var modifier: int = int(value_modifiers[value_key])
			match operation:
				"set":
					card_play_request.card_values[value_key] = modifier
				_:
					card_play_request.card_values[value_key] = max(0, existing_value + modifier)

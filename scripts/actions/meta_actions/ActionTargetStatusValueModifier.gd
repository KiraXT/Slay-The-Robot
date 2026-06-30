# Wraps child actions and adjusts one child value from each target's status charges.
extends BaseAction

func is_instant_action() -> bool:
	return true

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			continue
		
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values("status_effect_object_id", "")
		var charge_key: String = action_interceptor_processor.get_shadowed_action_values("charge_key", "status_charges")
		var multiplier: int = action_interceptor_processor.get_shadowed_action_values("multiplier", 1)
		var value_key: String = action_interceptor_processor.get_shadowed_action_values("value_key", "damage")
		var operation: String = action_interceptor_processor.get_shadowed_action_values("operation", "add")
		var default_value: int = action_interceptor_processor.get_shadowed_action_values("default_value", 0)
		var action_data: Array = action_interceptor_processor.get_shadowed_action_values("action_data", [])
		
		if status_effect_object_id == "" or action_data.is_empty():
			push_error("ActionTargetStatusValueModifier requires status_effect_object_id and action_data")
			continue
		
		var status_value: int = _get_status_value(target, status_effect_object_id, charge_key, default_value)
		var scaled_value: int = status_value * multiplier
		var modified_action_data: Array[Dictionary] = _build_modified_action_data(action_data, value_key, scaled_value, operation)
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [target], modified_action_data, self)
		ActionHandler.add_actions(generated_actions)

func _get_status_value(target: BaseCombatant, status_effect_object_id: String, charge_key: String, default_value: int) -> int:
	var status_effects: Array = target.status_id_to_status_effects.get(status_effect_object_id, [])
	if status_effects.is_empty():
		return default_value
	
	var selected_value: int = default_value
	for item in status_effects:
		var status_effect: StatusEffect = item
		var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
		var current_value: int = default_value
		match charge_key:
			"status_secondary_charges":
				current_value = status_effect_script.status_secondary_charges
			_:
				current_value = status_effect_script.status_charges
		if abs(current_value) > abs(selected_value):
			selected_value = current_value
	return selected_value

func _build_modified_action_data(action_data: Array, value_key: String, scaled_value: int, operation: String) -> Array[Dictionary]:
	var modified_action_data: Array[Dictionary] = []
	for action_definition in action_data.duplicate(true):
		for action_script_path in action_definition:
			var action_values: Dictionary = action_definition[action_script_path]
			var existing_value: int = int(action_values.get(value_key, _get_card_play_value(value_key, 0)))
			if operation == "set":
				action_values[value_key] = scaled_value
			else:
				action_values[value_key] = existing_value + scaled_value
		modified_action_data.append(action_definition)
	return modified_action_data

func _get_card_play_value(value_key: String, default_value: int) -> int:
	if card_play_request == null:
		return default_value
	if card_play_request.card_values.has(value_key):
		return int(card_play_request.card_values[value_key])
	if card_play_request.card_data != null and card_play_request.card_data.card_values.has(value_key):
		return int(card_play_request.card_data.card_values[value_key])
	return default_value

extends SceneTree

const ACTION_ATTACK_GENERATOR := "res://scripts/actions/meta_actions/ActionAttackGenerator.gd"
const ACTION_APPLY_STATUS := "res://scripts/actions/status_actions/ActionApplyStatus.gd"
const ACTION_ADD_HEALTH := "res://scripts/actions/ActionAddHealth.gd"
const ACTION_BLOCK := "res://scripts/actions/ActionBlock.gd"
const ACTION_VALIDATOR := "res://scripts/actions/meta_actions/ActionValidator.gd"
const ACTION_DRAW_GENERATOR := "res://scripts/actions/meta_actions/ActionDrawGenerator.gd"
const ACTION_CYCLE_ENEMY_INTENT := "res://scripts/actions/enemy_actions/ActionCycleEnemyIntent.gd"
const ACTION_IMPROVE_CARD_VALUES := "res://scripts/actions/cardset_actions/ActionImproveCardValues.gd"
const ACTION_RESHUFFLE := "res://scripts/actions/ActionReshuffle.gd"
const ACTION_VARIABLE_COST_MODIFIER := "res://scripts/actions/meta_actions/ActionVariableCostModifier.gd"
const ACTION_ADD_ENERGY := "res://scripts/actions/ActionAddEnergy.gd"
const ACTION_END_TURN := "res://scripts/actions/ActionEndTurn.gd"
const ACTION_PICK_CARDS := "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
const VALIDATOR_CARD_ID := "res://scripts/validators/card/ValidatorCardID.gd"
const TARGET_OVERRIDE_ALL_ENEMIES := 4

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_action_handler_keeps_declared_order()
	_test_base_cardset_action_can_select_cards_from_pile()
	_test_card_effect_configs_match_descriptions()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_action_handler_keeps_declared_order() -> void:
	var source := FileAccess.get_file_as_string("res://autoload/ActionHandler.gd")
	_assert_contains(
		source,
		"for action_index in range(len(actions) - 1, -1, -1):",
		"ActionHandler must push stack actions in reverse so pop_back executes declared order"
	)
	_assert_contains(
		source,
		"action_stack.append([actions[action_index]])",
		"ActionHandler must append individual stack actions from the reversed index"
	)


func _test_base_cardset_action_can_select_cards_from_pile() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actions/cardset_actions/BaseCardsetAction.gd")
	_assert_contains(
		source,
		"var card_pick_type: int = get_action_value(\"card_pick_type\", -1)",
		"Cardset actions must support deriving a source pile from card_pick_type"
	)
	_assert_contains(
		source,
		"CardFilter.new(input_cardset).filter_card_validators",
		"Cardset actions must filter derived pile cards with validator_data"
	)


func _test_card_effect_configs_match_descriptions() -> void:
	_assert_top_level_paths("card_attack_corrosion.json", [ACTION_ATTACK_GENERATOR, ACTION_APPLY_STATUS])
	_assert_top_level_paths("card_cycle_enemy_intent.json", [ACTION_ATTACK_GENERATOR, ACTION_CYCLE_ENEMY_INTENT])
	_assert_top_level_paths("card_reshuffle_draw.json", [ACTION_RESHUFFLE, ACTION_DRAW_GENERATOR])
	_assert_top_level_paths("card_law.json", [ACTION_ATTACK_GENERATOR, ACTION_IMPROVE_CARD_VALUES])
	_assert_top_level_paths("card_attack_heal_unblocked_damage.json", [ACTION_ATTACK_GENERATOR, ACTION_ADD_HEALTH])
	_assert_top_level_paths("end_turn_card.json", [ACTION_BLOCK, ACTION_END_TURN, ACTION_BLOCK])
	_assert_top_level_paths("custom_block_card.json", [ACTION_BLOCK, ACTION_BLOCK])
	_assert_top_level_paths("randomize_hand_card.json", [ACTION_DRAW_GENERATOR, ACTION_PICK_CARDS])

	var healing_attack := _card_properties("card_attack_heal_unblocked_damage.json")
	var heal_actions: Array = healing_attack["card_play_actions"]
	if len(heal_actions) >= 2 and heal_actions[0].has(ACTION_ATTACK_GENERATOR) and heal_actions[1].has(ACTION_ADD_HEALTH):
		var attack_values: Dictionary = heal_actions[0][ACTION_ATTACK_GENERATOR]
		var heal_values: Dictionary = heal_actions[1][ACTION_ADD_HEALTH]
		_assert_equal(attack_values.get("target_override"), TARGET_OVERRIDE_ALL_ENEMIES, "Healing attack must damage all enemies")
		_assert_equal(
			heal_values.get("custom_key_names", {}).get("health_amount"),
			"unblocked_damage_capped",
			"Healing attack must heal from unblocked capped damage"
		)

	var conditional_block := _card_properties("attack_with_conditional_block_card.json")
	_assert_nested_action(conditional_block, ACTION_VALIDATOR, "passed_action_data", ACTION_BLOCK, "Conditional block attack must add block when validation passes")

	var conditional_draw := _card_properties("attack_with_conditional_draw_card.json")
	_assert_nested_action(conditional_draw, ACTION_VALIDATOR, "passed_action_data", ACTION_DRAW_GENERATOR, "Conditional draw attack must draw two on pass")
	_assert_nested_action(conditional_draw, ACTION_VALIDATOR, "failed_action_data", ACTION_DRAW_GENERATOR, "Conditional draw attack must draw one on fail")

	var improving_attack := _card_properties("card_improving_attack.json")
	_assert_top_level_paths("card_improving_attack.json", [ACTION_BLOCK, ACTION_ATTACK_GENERATOR])
	var improving_attack_actions: Array = improving_attack["card_play_actions"]
	var on_lethal: Array = improving_attack_actions[1][ACTION_ATTACK_GENERATOR].get("actions_on_lethal", [])
	_assert_path_list(_action_paths(on_lethal), [ACTION_IMPROVE_CARD_VALUES], "Improving attack must improve itself on lethal")

	var attack_block := _card_properties("card_attack_block.json")
	_assert_path_list(_action_paths(attack_block.get("card_end_of_turn_actions", [])), [ACTION_BLOCK], "Attack/block retain card must block at end of turn")

	var initial_block := _card_properties("card_block_initial.json")
	_assert_path_list(_action_paths(initial_block.get("card_initial_combat_actions", [])), [ACTION_BLOCK], "Initial block card must block at combat start")

	var retain_block := _card_properties("improving_retain_block_card.json")
	_assert_path_list(_action_paths(retain_block.get("card_retain_actions", [])), [ACTION_IMPROVE_CARD_VALUES], "Improving retain block must improve on retain")

	var x_attack := _card_properties("variable_cost_attack_card.json")
	var x_action: Dictionary = x_attack["card_play_actions"][0][ACTION_VARIABLE_COST_MODIFIER]
	_assert_equal(x_action.get("multiplied_values"), ["damage"], "X attack must multiply damage by input energy")
	_assert_path_list(_action_paths(x_action.get("action_data", [])), [ACTION_ATTACK_GENERATOR], "X attack must generate an attack")

	var custom_block := _card_properties("custom_block_card.json")
	_assert_equal(custom_block.get("card_values", {}).get("custom_block_1"), 3, "Custom block must define first block value")
	_assert_equal(custom_block.get("card_values", {}).get("custom_block_2"), 4, "Custom block must define second block value")

	var draw_energy := _card_properties("card_energy_on_draw.json")
	_assert_equal(draw_energy.get("card_values", {}).get("energy_amount"), 1, "Draw energy card must define energy amount")
	_assert_path_list(_action_paths(draw_energy.get("card_draw_actions", [])), [ACTION_ADD_ENERGY], "Draw energy card must gain energy when drawn")

	var discard_energy := _card_properties("card_energy_on_discard.json")
	_assert_equal(discard_energy.get("card_values", {}).get("energy_amount"), 1, "Discard energy card must define energy amount")
	_assert_path_list(_action_paths(discard_energy.get("card_discard_actions", [])), [ACTION_ADD_ENERGY], "Discard energy card must gain energy when discarded")


func _card_properties(file_name: String) -> Dictionary:
	var path := "res://external/data/cards/%s" % file_name
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		failures.append("Could not read %s" % path)
		return {}
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		failures.append("Could not parse %s" % path)
		return {}
	return parsed.get("properties", {})


func _action_paths(actions: Array) -> Array:
	var paths: Array = []
	for action in actions:
		if action is Dictionary:
			for action_path in action.keys():
				paths.append(action_path)
	return paths


func _assert_top_level_paths(file_name: String, expected_paths: Array) -> void:
	var properties := _card_properties(file_name)
	_assert_path_list(_action_paths(properties.get("card_play_actions", [])), expected_paths, "%s play actions" % file_name)


func _assert_path_list(actual: Array, expected: Array, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])


func _assert_nested_action(properties: Dictionary, wrapper_path: String, child_key: String, expected_child_path: String, label: String) -> void:
	for action in properties.get("card_play_actions", []):
		if action is Dictionary and action.has(wrapper_path):
			var child_actions: Array = action[wrapper_path].get(child_key, [])
			if _action_paths(child_actions).has(expected_child_path):
				return
	failures.append("%s: missing %s under %s.%s" % [label, expected_child_path, wrapper_path, child_key])


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])

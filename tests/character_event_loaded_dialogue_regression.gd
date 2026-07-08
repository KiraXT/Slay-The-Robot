extends SceneTree

const EVENT_POOL_ID := "event_pool_act_1_dialogue"
const CHARACTER_EVENTS := {
	"character_red": [
		"event_red_broken_boxing_ring",
		"event_red_warning_line_gate",
	],
	"character_blue": [
		"event_blue_scattered_toolbox",
		"event_blue_runaway_shuffler",
	],
	"character_green": [
		"event_green_echo_tuning_room",
		"event_green_corrosion_tank",
	],
	"character_orange": [
		"event_orange_prep_supply_stop",
		"event_orange_hidden_backpack_pocket",
	],
}

var failures: Array[String] = []
var game_global: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	var previous_player_data = game_global.player_data

	_assert_loaded_dialogue_data()
	_assert_real_pool_uses_character_validators()

	game_global.player_data = previous_player_data

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _assert_loaded_dialogue_data() -> void:
	for character_id: String in CHARACTER_EVENTS:
		for event_id: String in CHARACTER_EVENTS[character_id]:
			var event_data = game_global.get_event_data(event_id)
			if event_data == null:
				failures.append("Missing loaded event data for %s." % event_id)
				continue

			var validators: Array[Dictionary] = event_data.event_pool_validator_data
			var expected_validators: Array[Dictionary] = [_character_validator(character_id)]
			if validators != expected_validators:
				failures.append("Expected %s to be filtered to %s." % [event_id, character_id])

			if event_data.event_dialogue_object_id != "":
				failures.append("Expected %s to use embedded dialogue data only." % event_id)

			var dialogue_data = event_data.get_dialogue_data()
			if dialogue_data == null:
				failures.append("Expected %s to load embedded DialogueData." % event_id)
				continue

			var initial_state_id: String = dialogue_data.dialogue_initial_dialogue_state_object_id
			var dialogue_state = dialogue_data.get_dialogue_state(initial_state_id)
			if dialogue_state == null:
				failures.append("Expected %s to load initial DialogueStateData %s." % [event_id, initial_state_id])
				continue

			if dialogue_state.dialogue_state_dialogue_texture_path != "":
				failures.append("Expected %s dialogue texture path to be empty." % event_id)
			if dialogue_state.dialogue_state_dialogue_option_object_ids.size() != 3:
				failures.append("Expected %s to load exactly 3 dialogue options." % event_id)

			for option_id: String in dialogue_state.dialogue_state_dialogue_option_object_ids:
				var dialogue_option = dialogue_data.get_dialogue_option(option_id)
				if dialogue_option == null:
					failures.append("Expected %s to load DialogueOptionData %s." % [event_id, option_id])
					continue
				if dialogue_option.dialogue_option_bbcode == "":
					failures.append("Expected %s option %s to have bbcode text." % [event_id, option_id])
				if not dialogue_option.dialogue_option_visible_on_failed_validation:
					failures.append("Expected %s option %s to remain visible on failed validation." % [event_id, option_id])


func _assert_real_pool_uses_character_validators() -> void:
	var pool_data = game_global.get_event_pool_data(EVENT_POOL_ID)
	if pool_data == null:
		failures.append("Missing loaded event pool %s." % EVENT_POOL_ID)
		return
	if pool_data.event_pool_fallback_event_object_id != "event_pick_something":
		failures.append("Expected %s fallback to remain event_pick_something." % EVENT_POOL_ID)
	for event_ids: Array in CHARACTER_EVENTS.values():
		for event_id: String in event_ids:
			if not pool_data.event_pool_event_object_ids.has(event_id):
				failures.append("Expected loaded pool %s to include %s." % [EVENT_POOL_ID, event_id])

	for character_id: String in CHARACTER_EVENTS:
		var matching_event_id: String = CHARACTER_EVENTS[character_id][0]
		var blocked_character_id: String = _first_other_character_id(character_id)
		var blocked_event_id: String = CHARACTER_EVENTS[blocked_character_id][0]
		var player_id: String = character_id.replace("character_", "player_")

		game_global.player_data = game_global.get_player_data_from_prototype(player_id)
		game_global.player_data.player_run_seed = 1
		game_global.player_data.player_event_pools[EVENT_POOL_ID] = [blocked_event_id, matching_event_id]

		var selected_event_id: String = game_global.player_data.get_next_event_object_id_from_pool(EVENT_POOL_ID)
		if selected_event_id != matching_event_id:
			failures.append("Expected %s to skip %s and select %s, got %s." % [
				character_id,
				blocked_event_id,
				matching_event_id,
				selected_event_id,
			])


func _character_validator(character_id: String) -> Dictionary:
	var validator_data: Dictionary = {}
	validator_data[Scripts.VALIDATOR_CHARACTER] = {
		"character_object_ids": [character_id],
	}
	return validator_data


func _first_other_character_id(character_id: String) -> String:
	for candidate_character_id: String in CHARACTER_EVENTS:
		if candidate_character_id != character_id:
			return candidate_character_id
	return ""

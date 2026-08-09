extends SceneTree

const PICK_CARDS_PATH := "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
const CHANGE_CARD_PROPERTIES_PATH := "res://scripts/actions/cardset_actions/ActionChangeCardProperties.gd"

var failures: Array[String] = []
var game_global: Node
var previous_player_data


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	previous_player_data = game_global.player_data
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")

	_test_top_deck_artifact_selection()

	game_global.player_data = previous_player_data
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_top_deck_artifact_selection() -> void:
	var attack_card = game_global.get_card_data_from_prototype("card_attack_basic")
	var skill_card = game_global.get_card_data_from_prototype("card_block_basic")
	var hand_attack_card = game_global.get_card_data_from_prototype("card_attack_basic")
	game_global.player_data.player_deck.clear()
	game_global.player_data.player_deck.append(attack_card)
	game_global.player_data.player_deck.append(skill_card)
	game_global.player_data.player_hand.clear()
	game_global.player_data.player_hand.append(hand_attack_card)

	var artifact_data = game_global.get_artifact_data("artifact_top_deck_attack_card")
	var pick_values: Dictionary = artifact_data.artifact_add_actions[0][PICK_CARDS_PATH]
	var pick_action = load(PICK_CARDS_PATH).new()
	var typed_pick_values: Dictionary[String, Variant] = {}
	typed_pick_values.assign(pick_values)
	pick_action.values = typed_pick_values

	var pickable_cards: Array = pick_action.get_pickable_cards()
	_assert_equal(pickable_cards.size(), 1, "top-deck artifact must only offer attack cards from the permanent deck")
	if pickable_cards.size() != 1:
		return
	_assert_true(pickable_cards[0] == attack_card, "top-deck artifact must ignore matching cards outside the permanent deck")

	pick_action.picked_cards = pickable_cards
	var change_values: Dictionary = pick_values["action_data"][0][CHANGE_CARD_PROPERTIES_PATH]
	var change_action = load(CHANGE_CARD_PROPERTIES_PATH).new()
	var typed_change_values: Dictionary[String, Variant] = {}
	typed_change_values.assign(change_values)
	change_action.values = typed_change_values
	change_action.parent_action = pick_action
	change_action.perform_action()

	_assert_equal(attack_card.card_first_shuffle_priority, 1, "selected attack must be prioritized for the first combat shuffle")
	_assert_equal(skill_card.card_first_shuffle_priority, 0, "unselected deck cards must keep their existing shuffle priority")
	_assert_equal(hand_attack_card.card_first_shuffle_priority, 0, "hand cards must not be modified by deck selection")


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])

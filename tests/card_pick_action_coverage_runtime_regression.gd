extends SceneTree

const PICK_UPGRADE_CARDS_PATH := "res://scripts/actions/pick_card_actions/ActionPickUpgradeCards.gd"
const UPGRADE_CARDS_PATH := "res://scripts/actions/cardset_actions/ActionUpgradeCards.gd"
const VALIDATOR_DECK_HAS_UPGRADEABLE_CARD_PATH := "res://scripts/validators/deck/ValidatorDeckHasUpgradeableCard.gd"

var failures: Array[String] = []
var game_global: Node
var previous_player_data


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	previous_player_data = game_global.player_data
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")

	_test_permanent_upgrade_card()
	_test_permanent_upgrade_card_requires_upgradeable_deck_card()
	_test_combat_deck_upgrade_card()

	game_global.player_data = previous_player_data
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_permanent_upgrade_card() -> void:
	var deck_card = game_global.get_card_data_from_prototype("card_attack_basic")
	var hand_card = game_global.get_card_data_from_prototype("card_attack_basic")
	game_global.player_data.player_deck.clear()
	game_global.player_data.player_deck.append(deck_card)
	game_global.player_data.player_hand.clear()
	game_global.player_data.player_hand.append(hand_card)

	var card_data = game_global.get_card_data("card_upgrade_card")
	var pick_values: Dictionary = card_data.card_play_actions[0][PICK_UPGRADE_CARDS_PATH]
	var pick_action = load(PICK_UPGRADE_CARDS_PATH).new()
	var typed_pick_values: Dictionary[String, Variant] = {}
	typed_pick_values.assign(pick_values)
	pick_action.values = typed_pick_values

	var pickable_cards: Array = pick_action.get_pickable_cards()
	_assert_equal(pickable_cards.size(), 1, "permanent upgrade must only offer permanent deck cards")
	if pickable_cards.size() != 1:
		return
	pick_action.picked_cards = pickable_cards
	pick_action.perform_async_action()

	_assert_equal(deck_card.card_upgrade_amount, 1, "selected permanent deck card must be upgraded")
	_assert_equal(hand_card.card_upgrade_amount, 0, "hand cards must not be upgraded by permanent upgrade")


func _test_permanent_upgrade_card_requires_upgradeable_deck_card() -> void:
	var fully_upgraded_card = game_global.get_card_data_from_prototype("card_attack_basic")
	fully_upgraded_card.upgrade_card()
	game_global.player_data.player_deck.clear()
	game_global.player_data.player_deck.append(fully_upgraded_card)

	var card_data = game_global.get_card_data("card_upgrade_card")
	var validator = load(VALIDATOR_DECK_HAS_UPGRADEABLE_CARD_PATH).new()
	var validator_values: Dictionary[String, Variant] = {}
	_assert_false(
		validator.validate(card_data, null, validator_values),
		"permanent upgrade card must be unplayable without an upgradeable deck card"
	)


func _test_combat_deck_upgrade_card() -> void:
	var permanent_card = game_global.get_card_data_from_prototype("card_attack_basic")
	var draw_card = game_global.get_card_data_from_prototype("card_attack_basic")
	var discard_card = game_global.get_card_data_from_prototype("card_block_basic")
	var hand_card = game_global.get_card_data_from_prototype("card_attack_big")
	game_global.player_data.player_deck.clear()
	game_global.player_data.player_deck.append(permanent_card)
	game_global.player_data.player_draw.clear()
	game_global.player_data.player_draw.append(draw_card)
	game_global.player_data.player_discard.clear()
	game_global.player_data.player_discard.append(discard_card)
	game_global.player_data.player_hand.clear()
	game_global.player_data.player_hand.append(hand_card)

	var card_data = game_global.get_card_data("upgrade_entire_deck_card")
	var upgrade_values: Dictionary = card_data.card_play_actions[0][UPGRADE_CARDS_PATH]
	var upgrade_action = load(UPGRADE_CARDS_PATH).new()
	var typed_upgrade_values: Dictionary[String, Variant] = {}
	typed_upgrade_values.assign(upgrade_values)
	upgrade_action.values = typed_upgrade_values
	upgrade_action.perform_action()

	_assert_equal(draw_card.card_upgrade_amount, 1, "combat draw pile card must be upgraded")
	_assert_equal(discard_card.card_upgrade_amount, 1, "combat discard pile card must be upgraded")
	_assert_equal(hand_card.card_upgrade_amount, 1, "combat hand card must be upgraded")
	_assert_equal(permanent_card.card_upgrade_amount, 0, "permanent deck card must not be upgraded")


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append(label)

extends SceneTree

const ACTION_BASE_PICK_CARDS := "res://scripts/actions/pick_card_actions/ActionBasePickCards.gd"
const ACTION_GRANT_REWARDS := "res://scripts/actions/rewards/ActionGrantRewards.gd"
const CARD_RARITY_RARE := 3

var failures: Array[String] = []
var game_global: Node
var signals: Node
var randomizer: Node
var reward_payloads: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	signals = root.get_node("Signals")
	randomizer = root.get_node("Random")
	await process_frame

	_test_card_pack_weighted_draft_uses_pack_weights()
	_test_consumable_rewards_generate_known_ids()
	_test_grant_rewards_emits_consumables_and_custom_actions()

	_finish()


func _finish() -> void:
	if signals.reward_grant_requested.is_connected(_on_reward_grant_requested):
		signals.reward_grant_requested.disconnect(_on_reward_grant_requested)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _test_card_pack_weighted_draft_uses_pack_weights() -> void:
	var card_pack_data = game_global.get_card_pack_data("card_pack_all")
	if card_pack_data == null:
		failures.append("card_pack_all must exist")
		return
	card_pack_data.card_pack_rarity_weights = {
		"common": 0,
		"uncommon": 0,
		"rare": 100,
	}

	var pick_action_script = load(ACTION_BASE_PICK_CARDS)
	if pick_action_script == null:
		failures.append("ActionBasePickCards must load")
		return

	var pick_action = pick_action_script.new()
	var values: Dictionary[String, Variant] = {}
	values["draft_card_pack_id"] = "card_pack_all"
	values["draft_is_weighted"] = true
	values["draft_max_card_amount"] = 3
	values["rng_name"] = "rng_reward_configuration_runtime"
	pick_action.values = values

	var drafted_cards: Array = pick_action.get_drafted_cards()
	_assert_equal(drafted_cards.size(), 3, "weighted card pack draft must return requested cards")
	for card_data in drafted_cards:
		_assert_equal(card_data.card_rarity, CARD_RARITY_RARE, "weighted card pack draft must respect rare-only pack weights")


func _test_consumable_rewards_generate_known_ids() -> void:
	var consumable_ids: Array = randomizer.get_location_consumable_rewards(game_global.get_player_location_data(), 2)
	_assert_equal(consumable_ids.size(), 2, "consumable rewards must generate requested count while enough consumables exist")

	var seen_ids: Dictionary = {}
	for consumable_id: String in consumable_ids:
		_assert_true(game_global.get_consumable_data(consumable_id) != null, "consumable reward id must map to ConsumableData")
		_assert_false(seen_ids.has(consumable_id), "consumable rewards should not duplicate ids in one reward batch")
		seen_ids[consumable_id] = true


func _test_grant_rewards_emits_consumables_and_custom_actions() -> void:
	reward_payloads.clear()
	if not signals.reward_grant_requested.is_connected(_on_reward_grant_requested):
		signals.reward_grant_requested.connect(_on_reward_grant_requested)

	var grant_action_script = load(ACTION_GRANT_REWARDS)
	if grant_action_script == null:
		failures.append("ActionGrantRewards must load")
		return

	var custom_action_data: Array = [{
		"test_custom_reward": {
			"reward_button_text": "Repair",
			"reward_button_actions": [{
				Scripts.ACTION_ADD_HEALTH: {"health_amount": 5}
			}]
		}
	}]

	var grant_action = grant_action_script.new()
	var values: Dictionary[String, Variant] = {}
	values["reward_group"] = 2
	values["money_amount"] = 11
	values["card_drafts"] = []
	values["artifact_ids"] = []
	values["consumable_ids"] = ["consumable_heal"]
	values["custom_action_data"] = custom_action_data
	grant_action.values = values
	grant_action.perform_action()

	_assert_equal(reward_payloads.size(), 1, "grant rewards must emit one reward payload")
	if reward_payloads.is_empty():
		return

	var payload: Dictionary = reward_payloads[0]
	_assert_equal(payload["reward_group"], 2, "reward payload must include group")
	_assert_equal(payload["money_amount"], 11, "reward payload must include money")
	_assert_equal(payload["consumable_ids"].size(), 1, "reward payload must include consumable ids")
	_assert_equal(payload["consumable_ids"][0], "consumable_heal", "reward payload must preserve consumable id")
	_assert_equal(payload["custom_action_data"].size(), 1, "reward payload must include custom action data")
	_assert_true(payload["custom_action_data"][0]["test_custom_reward"].has("reward_button_actions"), "custom reward data must keep reward_button_actions")


func _on_reward_grant_requested(reward_group: int, money_amount: int, card_drafts: Array[Array], artifact_ids: Array[String], consumable_ids: Array[String], custom_action_data: Array) -> void:
	reward_payloads.append({
		"reward_group": reward_group,
		"money_amount": money_amount,
		"card_drafts": card_drafts,
		"artifact_ids": artifact_ids,
		"consumable_ids": consumable_ids,
		"custom_action_data": custom_action_data,
	})


func _assert_true(value: bool, label: String) -> void:
	if not value:
		failures.append(label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		failures.append(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, expected, actual])

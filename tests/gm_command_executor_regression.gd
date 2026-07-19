extends SceneTree

const GM_EXECUTOR_SCRIPT := "res://scripts/dev/GMCommandExecutor.gd"
const COMBAT_STATS_SCRIPT := "res://data/mutable/CombatStatsData.gd"
const DRAW_TOP := 4

var failures: Array[String] = []
var game_global: Node
var signals: Node
var action_handler: Node
var executor
var previous_player_data
var previous_is_run: bool
var hand_requests: Array = []
var draw_requests: Array = []
var consumable_requests: Array[String] = []
var enemy_spawn_requests: Array = []
var combat_ended_count := 0
var energy_signal_amounts: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_global = root.get_node("Global")
	signals = root.get_node("Signals")
	action_handler = root.get_node("ActionHandler")
	previous_player_data = game_global.player_data
	previous_is_run = game_global.is_run
	executor = load(GM_EXECUTOR_SCRIPT).new()

	_connect_spy_signals()
	_setup_run()

	_assert_true(executor.call("is_enabled"), "GM executor should be enabled in non-exported test runs")
	_assert_error("", "ERR: empty command")
	_assert_error("missing command", "ERR: unknown command 'missing'. Use help.")
	_assert_ok_contains("help", "cards all")
	_assert_clear_result()
	_assert_requires_run()

	_setup_run()
	_test_add_single_card_to_deck()
	_test_add_all_cards_to_deck()
	_test_combat_required_for_hand_and_draw()
	_test_add_card_to_hand_and_draw_in_combat()
	_test_add_artifact()
	_test_add_all_artifacts()
	_test_add_consumable()
	_test_add_consumable_full_slots_errors()
	_test_money_hp_energy()
	_test_actions_clear()
	_test_enemy_spawn_and_combat_win_require_combat()
	_test_enemy_spawn_and_combat_win()

	_disconnect_spy_signals()
	action_handler.clear_all_actions()
	game_global.player_data = previous_player_data
	game_global.is_run = previous_is_run

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _connect_spy_signals() -> void:
	signals.card_add_to_hand_requested.connect(_on_card_add_to_hand_requested)
	signals.card_add_to_draw_requested.connect(_on_card_add_to_draw_requested)
	signals.add_consumable_requested.connect(_on_add_consumable_requested)
	signals.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
	signals.combat_ended.connect(_on_combat_ended)
	signals.energy_added.connect(_on_energy_added)


func _disconnect_spy_signals() -> void:
	if signals.card_add_to_hand_requested.is_connected(_on_card_add_to_hand_requested):
		signals.card_add_to_hand_requested.disconnect(_on_card_add_to_hand_requested)
	if signals.card_add_to_draw_requested.is_connected(_on_card_add_to_draw_requested):
		signals.card_add_to_draw_requested.disconnect(_on_card_add_to_draw_requested)
	if signals.add_consumable_requested.is_connected(_on_add_consumable_requested):
		signals.add_consumable_requested.disconnect(_on_add_consumable_requested)
	if signals.enemy_spawn_requested.is_connected(_on_enemy_spawn_requested):
		signals.enemy_spawn_requested.disconnect(_on_enemy_spawn_requested)
	if signals.combat_ended.is_connected(_on_combat_ended):
		signals.combat_ended.disconnect(_on_combat_ended)
	if signals.energy_added.is_connected(_on_energy_added):
		signals.energy_added.disconnect(_on_energy_added)


func _setup_run() -> void:
	game_global.player_data = game_global.get_player_data_from_prototype("player_red")
	game_global.player_data.player_character_object_id = "character_red"
	game_global.player_data.player_health = 50
	game_global.player_data.player_health_max = 50
	game_global.player_data.player_money = 0
	game_global.player_data.player_energy = 3
	game_global.player_data.player_energy_max = 3
	game_global.player_data.player_deck.clear()
	game_global.player_data.player_draw.clear()
	game_global.player_data.player_discard.clear()
	game_global.player_data.player_exhaust.clear()
	game_global.player_data.player_hand.clear()
	game_global.player_data.player_artifact_uid_to_artifact_data.clear()
	game_global.player_data.player_consumable_slot_to_consumable_object_id.clear()
	game_global.player_data.player_current_combat_stats = null
	game_global.is_run = true
	hand_requests.clear()
	draw_requests.clear()
	consumable_requests.clear()
	enemy_spawn_requests.clear()
	combat_ended_count = 0
	energy_signal_amounts.clear()


func _set_combat(active: bool) -> void:
	if active:
		var combat_stats_script := load(COMBAT_STATS_SCRIPT)
		game_global.player_data.player_current_combat_stats = combat_stats_script.new("gm_command_test")
	else:
		game_global.player_data.player_current_combat_stats = null


func _assert_requires_run() -> void:
	game_global.is_run = false
	var result: Dictionary = executor.call("execute", "money set 10")
	_assert_false(result.ok, "money set should fail without an active run")
	_assert_equal(result.message, "ERR: command requires an active run", "run gate error message")
	game_global.is_run = true


func _test_add_single_card_to_deck() -> void:
	var before_count: int = game_global.player_data.player_deck.size()
	var result: Dictionary = executor.call("execute", "card add card_attack_basic deck")
	_assert_true(result.ok, "card add card_attack_basic deck should succeed")
	_assert_equal(game_global.player_data.player_deck.size(), before_count + 1, "card add should append one deck card")
	_assert_equal(game_global.player_data.player_deck.back().object_id, "card_attack_basic", "added deck card id")


func _test_add_all_cards_to_deck() -> void:
	game_global.player_data.player_deck.clear()
	var expected_count: int = game_global.get_all_cards().size()
	var result: Dictionary = executor.call("execute", "cards all deck")
	_assert_true(result.ok, "cards all deck should succeed")
	_assert_equal(game_global.player_data.player_deck.size(), expected_count, "cards all should add every loaded card")


func _test_combat_required_for_hand_and_draw() -> void:
	_set_combat(false)
	_assert_error("card add card_attack_basic hand", "ERR: command requires combat")
	_assert_error("card add card_attack_basic draw", "ERR: command requires combat")


func _test_add_card_to_hand_and_draw_in_combat() -> void:
	_set_combat(true)
	var hand_result: Dictionary = executor.call("execute", "card add card_attack_basic hand")
	_assert_true(hand_result.ok, "card add hand should succeed in combat")
	_assert_equal(hand_requests.size(), 1, "card add hand should emit one hand request")
	_assert_equal(hand_requests[0].cards[0].object_id, "card_attack_basic", "hand request card id")

	var draw_result: Dictionary = executor.call("execute", "card add card_block_basic draw")
	_assert_true(draw_result.ok, "card add draw should succeed in combat")
	_assert_equal(draw_requests.size(), 1, "card add draw should emit one draw request")
	_assert_equal(draw_requests[0].cards[0].object_id, "card_block_basic", "draw request card id")
	_assert_equal(draw_requests[0].destination, DRAW_TOP, "draw request destination should be draw top")


func _test_add_artifact() -> void:
	var result: Dictionary = executor.call("execute", "artifact add artifact_draw_on_kill")
	_assert_true(result.ok, "artifact add should succeed")
	_assert_equal(game_global.player_data.get_player_artifacts_with_artifact_id("artifact_draw_on_kill").size(), 1, "player should receive artifact")


func _test_add_all_artifacts() -> void:
	game_global.player_data.player_artifact_uid_to_artifact_data.clear()
	var expected_count: int = game_global.get_all_artifacts().size()
	var result: Dictionary = executor.call("execute", "artifacts all")
	_assert_true(result.ok, "artifacts all should succeed")
	_assert_equal(game_global.player_data.get_player_artifacts().size(), expected_count, "artifacts all should add every loaded artifact")


func _test_add_consumable() -> void:
	game_global.player_data.player_consumable_slot_to_consumable_object_id.clear()
	var result: Dictionary = executor.call("execute", "consumable add consumable_heal")
	_assert_true(result.ok, "consumable add should succeed")
	_assert_equal(consumable_requests.size(), 1, "consumable add should emit add request")
	_assert_equal(consumable_requests[0], "consumable_heal", "consumable request id")


func _test_add_consumable_full_slots_errors() -> void:
	game_global.player_data.player_consumable_slot_to_consumable_object_id = {
		"0": "consumable_heal",
		"1": "consumable_block",
		"2": "consumable_damaging",
	}
	var result: Dictionary = executor.call("execute", "consumable add consumable_heal")
	_assert_false(result.ok, "consumable add should fail when slots are full")
	_assert_equal(result.message, "ERR: no empty consumable slots", "full consumable slot error")


func _test_money_hp_energy() -> void:
	_assert_ok_contains("money set 42", "money set to 42")
	_assert_equal(game_global.player_data.player_money, 42, "money set value")
	_assert_ok_contains("money add 8", "money changed by 8")
	_assert_equal(game_global.player_data.player_money, 50, "money add value")

	_assert_ok_contains("hp set 21", "hp set to 21")
	_assert_equal(game_global.player_data.player_health, 21, "hp set value")
	_assert_ok_contains("hp heal 5", "hp changed by 5")
	_assert_equal(game_global.player_data.player_health, 26, "hp heal value")
	_assert_ok_contains("hp max 80", "max hp set to 80")
	_assert_equal(game_global.player_data.player_health_max, 80, "hp max value")

	_assert_ok_contains("energy set 9", "energy set to 9")
	_assert_equal(game_global.player_data.player_energy, 9, "energy set value")
	_assert_ok_contains("energy add -4", "energy changed by -4")
	_assert_equal(game_global.player_data.player_energy, 5, "energy add value")
	_assert_true(energy_signal_amounts.size() >= 2, "energy commands should emit energy_added for UI refresh")


func _test_actions_clear() -> void:
	action_handler.action_stack.append([])
	action_handler.current_action_queue.append(null)
	var result: Dictionary = executor.call("execute", "actions clear")
	_assert_true(result.ok, "actions clear should succeed")
	_assert_equal(action_handler.action_stack.size(), 0, "action stack should be empty")
	_assert_equal(action_handler.current_action_queue.size(), 0, "current action queue should be empty")


func _test_enemy_spawn_and_combat_win_require_combat() -> void:
	_set_combat(false)
	_assert_error("enemy spawn enemy_1 2", "ERR: command requires combat")
	_assert_error("combat win", "ERR: command requires combat")


func _test_enemy_spawn_and_combat_win() -> void:
	_set_combat(true)
	var spawn_result: Dictionary = executor.call("execute", "enemy spawn enemy_1 2")
	_assert_true(spawn_result.ok, "enemy spawn should succeed")
	_assert_equal(enemy_spawn_requests.size(), 1, "enemy spawn should emit one request")
	_assert_equal(enemy_spawn_requests[0].enemy_id, "enemy_1", "enemy spawn id")
	_assert_equal(enemy_spawn_requests[0].slot, 2, "enemy spawn slot")

	var win_result: Dictionary = executor.call("execute", "combat win")
	_assert_true(win_result.ok, "combat win should succeed")
	_assert_equal(combat_ended_count, 1, "combat win should emit combat_ended")


func _assert_clear_result() -> void:
	var result: Dictionary = executor.call("execute", "clear")
	_assert_true(result.ok, "clear should succeed")
	_assert_equal(result.get("clear_output", false), true, "clear result should request output clearing")


func _assert_ok_contains(command: String, expected_text: String) -> void:
	var result: Dictionary = executor.call("execute", command)
	_assert_true(result.ok, "%s should succeed" % command)
	if not str(result.message).contains(expected_text):
		failures.append("Expected '%s' result to contain '%s', got '%s'." % [command, expected_text, result.message])


func _assert_error(command: String, expected_message: String) -> void:
	var result: Dictionary = executor.call("execute", command)
	_assert_false(result.ok, "%s should fail" % command)
	_assert_equal(result.message, expected_message, "%s error message" % command)


func _on_card_add_to_hand_requested(cards: Array[CardData], hand_card_count_max: int) -> void:
	hand_requests.append({"cards": cards, "max": hand_card_count_max})


func _on_card_add_to_draw_requested(cards: Array[CardData], card_destination: int) -> void:
	draw_requests.append({"cards": cards, "destination": card_destination})


func _on_add_consumable_requested(consumable_object_id: String) -> void:
	consumable_requests.append(consumable_object_id)


func _on_enemy_spawn_requested(enemy_object_id: String, slot_id: int) -> void:
	enemy_spawn_requests.append({"enemy_id": enemy_object_id, "slot": slot_id})


func _on_combat_ended() -> void:
	combat_ended_count += 1


func _on_energy_added(energy_amount: int) -> void:
	energy_signal_amounts.append(energy_amount)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s." % [message, expected, actual])

# GM Command Console Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现一个可通过数字键 `1` 左边物理键呼出的文本 GM 控制台，用于快速测试所有卡牌、遗物、消耗品、资源和基础战斗状态。

**Architecture:** `Root.gd` 只负责创建/切换控制台入口，`scripts/dev/GMConsole.gd` 负责 UI 输入输出，`scripts/dev/GMCommandExecutor.gd` 负责命令解析、校验和运行态修改。执行器复用现有 `Global` 数据表、`PlayerData` 方法、`Signals` 和 `ActionHandler`，不修改 JSON 数据结构。

**Tech Stack:** Godot 4.6、GDScript、现有 SceneTree 回归测试、项目现有 autoload 单例。

## Global Constraints

- 用户沟通和项目开发文档默认中文。
- 呼出键使用数字键 `1` 左边的物理键，优先识别 `physical_keycode == KEY_QUOTELEFT`。
- 第一版提供文本命令输入和结果输出，不做完整图形 GM 面板。
- 第一版覆盖卡牌、遗物、消耗品、金币、生命、能量、敌人生成、结束战斗和清空 action 队列。
- 第一版不做事件、地图、商店、宝箱跳转测试。
- GM 代码集中放在 `scripts/dev/`，避免污染卡牌、遗物、战斗和普通 UI 脚本。
- 默认仅在非 exported 环境启用，不进入正式导出体验。
- 非法命令、非法 ID、状态不满足时返回明确错误，不导致游戏崩溃。
- 不修改 JSON 数据结构，不新增卡牌、遗物或敌人配置格式。

---

## File Structure

- Create `scripts/dev/GMCommandExecutor.gd`
  - 独立命令执行器，提供 `is_enabled() -> bool`、`execute(command_text: String) -> Dictionary` 和可测试的命令实现。
- Create `scripts/dev/GMConsole.gd`
  - 轻量 `Control`，在运行时构建输入框和输出日志，调用 `GMCommandExecutor.execute()`。
- Modify `scripts/Root.gd`
  - 创建 GM 控制台，捕获物理呼出键，转发切换行为，不承载命令逻辑。
- Create `tests/gm_command_executor_regression.gd`
  - 直接测试命令执行器的解析、状态校验和运行态修改。
- Create `tests/gm_console_toggle_regression.gd`
  - 实例化 `Root.tscn`，测试 GM 控制台入口存在、可切换、错误命令不崩溃。

---

### Task 1: GM 命令执行器

**Files:**
- Create: `scripts/dev/GMCommandExecutor.gd`
- Create: `tests/gm_command_executor_regression.gd`

**Interfaces:**
- Consumes: `Global.is_run: bool`
- Consumes: `Global.player_data: PlayerData`
- Consumes: `Global.get_card_data(card_object_id: String) -> CardData`
- Consumes: `Global.get_card_data_from_prototype(card_object_id: String) -> CardData`
- Consumes: `Global.get_artifact_data(artifact_id: String) -> ArtifactData`
- Consumes: `Global.get_consumable_data(consumable_object_id: String) -> ConsumableData`
- Consumes: `Global.get_enemy_data(enemy_object_id: String) -> EnemyData`
- Consumes: `Global.is_player_in_combat() -> bool`
- Consumes: `PlayerData.add_card_to_deck(card_data: CardData) -> void`
- Consumes: `PlayerData.add_artifact(artifact_id: String) -> void`
- Consumes: `Signals.card_add_to_hand_requested(cards: Array[CardData], hand_card_count_max: int)`
- Consumes: `Signals.card_add_to_draw_requested(cards: Array[CardData], card_destination: int)`
- Consumes: `Signals.add_consumable_requested(consumable_object_id: String)`
- Consumes: `Signals.enemy_spawn_requested(enemy_object_id: String, slot_id: int)`
- Consumes: `Signals.combat_ended`
- Consumes: `Signals.energy_added(energy_amount: int)`
- Consumes: `ActionHandler.clear_all_actions() -> void`
- Produces: `GMCommandExecutor.is_enabled() -> bool`
- Produces: `GMCommandExecutor.execute(command_text: String) -> Dictionary`
- Produces result dictionaries with keys:
  - `ok: bool`
  - `message: String`
  - `clear_output: bool` only for `clear`

- [ ] **Step 1: Write the failing executor regression test**

Create `tests/gm_command_executor_regression.gd`:

```gdscript
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
	var before_count := game_global.player_data.player_deck.size()
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
```

- [ ] **Step 2: Run the executor test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/gm_command_executor_regression.gd
```

Expected: FAIL because `res://scripts/dev/GMCommandExecutor.gd` does not exist.

- [ ] **Step 3: Create the executor script**

Create `scripts/dev/GMCommandExecutor.gd`:

```gdscript
extends RefCounted
class_name GMCommandExecutor

const RESULT_OK := "ok"
const RESULT_MESSAGE := "message"
const RESULT_CLEAR_OUTPUT := "clear_output"

const PILE_DECK := "deck"
const PILE_HAND := "hand"
const PILE_DRAW := "draw"
const VALID_CARD_PILES := [PILE_DECK, PILE_HAND, PILE_DRAW]


func is_enabled() -> bool:
	return not OS.has_feature("exported")


func execute(command_text: String) -> Dictionary:
	var tokens := _tokenize(command_text)
	if tokens.is_empty():
		return _error("ERR: empty command")
	if not is_enabled():
		return _error("ERR: GM commands are disabled")

	match tokens[0]:
		"help":
			return _success(_get_help_text())
		"clear":
			return {
				RESULT_OK: true,
				RESULT_MESSAGE: "OK: console cleared",
				RESULT_CLEAR_OUTPUT: true,
			}
		"card":
			return _execute_card(tokens)
		"cards":
			return _execute_cards(tokens)
		"artifact":
			return _execute_artifact(tokens)
		"artifacts":
			return _execute_artifacts(tokens)
		"consumable":
			return _execute_consumable(tokens)
		"money":
			return _execute_money(tokens)
		"hp":
			return _execute_hp(tokens)
		"energy":
			return _execute_energy(tokens)
		"enemy":
			return _execute_enemy(tokens)
		"combat":
			return _execute_combat(tokens)
		"actions":
			return _execute_actions(tokens)
		_:
			return _error("ERR: unknown command '%s'. Use help." % tokens[0])


func _tokenize(command_text: String) -> Array[String]:
	var tokens: Array[String] = []
	for token: String in command_text.strip_edges().split(" ", false):
		var normalized := token.strip_edges().to_lower()
		if not normalized.is_empty():
			tokens.append(normalized)
	return tokens


func _get_help_text() -> String:
	return "\n".join([
		"GM commands:",
		"help",
		"clear",
		"cards all [deck|hand|draw]",
		"card add <card_id> [deck|hand|draw]",
		"artifacts all",
		"artifact add <artifact_id>",
		"consumable add <consumable_id>",
		"money set/add <amount>",
		"hp set/heal/max <amount>",
		"energy set/add <amount>",
		"enemy spawn <enemy_id> [slot]",
		"combat win",
		"actions clear",
	])


func _execute_card(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 3 or tokens[1] != "add":
		return _error("ERR: usage: card add <card_id> [deck|hand|draw]")
	return _add_card(tokens[2], _get_optional_pile(tokens, 3))


func _execute_cards(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 2 or tokens[1] != "all":
		return _error("ERR: usage: cards all [deck|hand|draw]")
	var pile := _get_optional_pile(tokens, 2)
	if not VALID_CARD_PILES.has(pile):
		return _error("ERR: invalid card pile '%s'" % pile)
	if pile != PILE_DECK:
		var combat_error := _require_combat()
		if not combat_error.is_empty():
			return combat_error

	var count := 0
	for card_data: CardData in Global.get_all_cards():
		var result := _add_card(card_data.object_id, pile)
		if not result.ok:
			return result
		count += 1
	return _success("OK: added %d cards to %s" % [count, pile])


func _execute_artifact(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 3 or tokens[1] != "add":
		return _error("ERR: usage: artifact add <artifact_id>")
	return _add_artifact(tokens[2])


func _execute_artifacts(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 2 or tokens[1] != "all":
		return _error("ERR: usage: artifacts all")

	var count := 0
	for artifact_data: ArtifactData in Global.get_all_artifacts():
		var result := _add_artifact(artifact_data.object_id)
		if not result.ok:
			return result
		count += 1
	return _success("OK: added %d artifacts" % count)


func _execute_consumable(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 3 or tokens[1] != "add":
		return _error("ERR: usage: consumable add <consumable_id>")
	var consumable_id := tokens[2]
	if Global.get_consumable_data(consumable_id) == null:
		return _error("ERR: consumable not found: %s" % consumable_id)
	if Global.player_data.are_consumable_slots_full():
		return _error("ERR: no empty consumable slots")
	Signals.add_consumable_requested.emit(consumable_id)
	return _success("OK: requested consumable %s" % consumable_id)


func _execute_money(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 3:
		return _error("ERR: usage: money set/add <amount>")
	var parsed := _parse_int(tokens[2])
	if not parsed.ok:
		return _error("ERR: invalid integer: %s" % tokens[2])
	match tokens[1]:
		"set":
			Global.player_data.player_money = max(parsed.value, 0)
			Signals.player_money_changed.emit()
			return _success("OK: money set to %d" % Global.player_data.player_money)
		"add":
			Global.player_data.add_money(parsed.value)
			return _success("OK: money changed by %d" % parsed.value)
	return _error("ERR: usage: money set/add <amount>")


func _execute_hp(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 3:
		return _error("ERR: usage: hp set/heal/max <amount>")
	var parsed := _parse_int(tokens[2])
	if not parsed.ok:
		return _error("ERR: invalid integer: %s" % tokens[2])
	match tokens[1]:
		"set":
			Global.player_data.set_health(parsed.value)
			return _success("OK: hp set to %d" % Global.player_data.player_health)
		"heal":
			Global.player_data.add_health(parsed.value)
			return _success("OK: hp changed by %d" % parsed.value)
		"max":
			Global.player_data.set_health(Global.player_data.player_health, parsed.value)
			return _success("OK: max hp set to %d" % Global.player_data.player_health_max)
	return _error("ERR: usage: hp set/heal/max <amount>")


func _execute_energy(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() < 3:
		return _error("ERR: usage: energy set/add <amount>")
	var parsed := _parse_int(tokens[2])
	if not parsed.ok:
		return _error("ERR: invalid integer: %s" % tokens[2])
	match tokens[1]:
		"set":
			var delta := parsed.value - Global.player_data.player_energy
			Global.player_data.player_energy = max(parsed.value, 0)
			Signals.energy_added.emit(delta)
			return _success("OK: energy set to %d" % Global.player_data.player_energy)
		"add":
			Global.player_data.player_energy = max(Global.player_data.player_energy + parsed.value, 0)
			Signals.energy_added.emit(parsed.value)
			return _success("OK: energy changed by %d" % parsed.value)
	return _error("ERR: usage: energy set/add <amount>")


func _execute_enemy(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	var combat_error := _require_combat()
	if not combat_error.is_empty():
		return combat_error
	if tokens.size() < 3 or tokens[1] != "spawn":
		return _error("ERR: usage: enemy spawn <enemy_id> [slot]")
	var enemy_id := tokens[2]
	if Global.get_enemy_data(enemy_id) == null:
		return _error("ERR: enemy not found: %s" % enemy_id)
	var slot := 0
	if tokens.size() >= 4:
		var parsed := _parse_int(tokens[3])
		if not parsed.ok:
			return _error("ERR: invalid integer: %s" % tokens[3])
		slot = parsed.value
	Signals.enemy_spawn_requested.emit(enemy_id, slot)
	return _success("OK: spawned enemy %s at slot %d" % [enemy_id, slot])


func _execute_combat(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	var combat_error := _require_combat()
	if not combat_error.is_empty():
		return combat_error
	if tokens.size() >= 2 and tokens[1] == "win":
		ActionHandler.clear_all_actions()
		Signals.combat_ended.emit()
		return _success("OK: combat ended")
	return _error("ERR: usage: combat win")


func _execute_actions(tokens: Array[String]) -> Dictionary:
	var run_error := _require_run()
	if not run_error.is_empty():
		return run_error
	if tokens.size() >= 2 and tokens[1] == "clear":
		ActionHandler.clear_all_actions()
		return _success("OK: actions cleared")
	return _error("ERR: usage: actions clear")


func _add_card(card_id: String, pile: String) -> Dictionary:
	if not VALID_CARD_PILES.has(pile):
		return _error("ERR: invalid card pile '%s'" % pile)
	if Global.get_card_data(card_id) == null:
		return _error("ERR: card not found: %s" % card_id)
	var card_data: CardData = Global.get_card_data_from_prototype(card_id)
	match pile:
		PILE_DECK:
			Global.player_data.add_card_to_deck(card_data)
			return _success("OK: added card %s to deck" % card_id)
		PILE_HAND:
			var combat_error := _require_combat()
			if not combat_error.is_empty():
				return combat_error
			Signals.card_add_to_hand_requested.emit([card_data], PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
			return _success("OK: added card %s to hand" % card_id)
		PILE_DRAW:
			var combat_error := _require_combat()
			if not combat_error.is_empty():
				return combat_error
			Signals.card_add_to_draw_requested.emit([card_data], CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_TOP)
			return _success("OK: added card %s to draw" % card_id)
	return _error("ERR: invalid card pile '%s'" % pile)


func _add_artifact(artifact_id: String) -> Dictionary:
	if Global.get_artifact_data(artifact_id) == null:
		return _error("ERR: artifact not found: %s" % artifact_id)
	Global.player_data.add_artifact(artifact_id)
	return _success("OK: added artifact %s" % artifact_id)


func _get_optional_pile(tokens: Array[String], index: int) -> String:
	if tokens.size() > index:
		return tokens[index]
	return PILE_DECK


func _require_run() -> Dictionary:
	if not Global.is_run:
		return _error("ERR: command requires an active run")
	return {}


func _require_combat() -> Dictionary:
	if not Global.is_player_in_combat():
		return _error("ERR: command requires combat")
	return {}


func _parse_int(text: String) -> Dictionary:
	if not text.is_valid_int():
		return {"ok": false, "value": 0}
	return {"ok": true, "value": text.to_int()}


func _success(message: String) -> Dictionary:
	return {
		RESULT_OK: true,
		RESULT_MESSAGE: message,
	}


func _error(message: String) -> Dictionary:
	return {
		RESULT_OK: false,
		RESULT_MESSAGE: message,
	}
```

- [ ] **Step 4: Run the executor test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/gm_command_executor_regression.gd
```

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 5: Commit Task 1**

Run:

```bash
git add scripts/dev/GMCommandExecutor.gd tests/gm_command_executor_regression.gd
git commit -m "feat: add GM command executor"
```

Expected: commit succeeds with only the executor and its test.

---

### Task 2: GM 控制台 UI 与根节点呼出

**Files:**
- Create: `scripts/dev/GMConsole.gd`
- Modify: `scripts/Root.gd`
- Create: `tests/gm_console_toggle_regression.gd`

**Interfaces:**
- Consumes: `GMCommandExecutor.is_enabled() -> bool`
- Consumes: `GMCommandExecutor.execute(command_text: String) -> Dictionary`
- Produces: `GMConsole.toggle() -> void`
- Produces: `GMConsole.show_console() -> void`
- Produces: `GMConsole.hide_console() -> void`
- Produces: `GMConsole.submit_command(command_text: String) -> Dictionary`
- Produces: `Root.gm_console: GMConsole`
- Produces: `Root._toggle_gm_console() -> void`
- Produces: `Root._is_gm_console_toggle_event(event: InputEvent) -> bool`

- [ ] **Step 1: Write the failing console toggle test**

Create `tests/gm_console_toggle_regression.gd`:

```gdscript
extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame

	if not root_scene.has_method("_toggle_gm_console"):
		failures.append("Root must expose _toggle_gm_console for the GM hotkey.")
	if not root_scene.has_method("_is_gm_console_toggle_event"):
		failures.append("Root must expose _is_gm_console_toggle_event for physical key testing.")
	if not root_scene.has_node("GMConsole"):
		failures.append("Root scene must have a GMConsole child.")
	else:
		var console: Node = root_scene.get_node("GMConsole")
		_assert_false(console.visible, "GMConsole should start hidden")

		root_scene.call("_toggle_gm_console")
		_assert_true(console.visible, "GMConsole should show after first toggle")

		var result: Dictionary = console.call("submit_command", "definitely_unknown")
		_assert_false(result.ok, "GMConsole should return errors from the executor without crashing")

		root_scene.call("_toggle_gm_console")
		_assert_false(console.visible, "GMConsole should hide after second toggle")

		var key_event := InputEventKey.new()
		key_event.pressed = true
		key_event.physical_keycode = KEY_QUOTELEFT
		_assert_true(root_scene.call("_is_gm_console_toggle_event", key_event), "Root should recognize KEY_QUOTELEFT as the GM toggle key")

		var release_event := InputEventKey.new()
		release_event.pressed = false
		release_event.physical_keycode = KEY_QUOTELEFT
		_assert_false(root_scene.call("_is_gm_console_toggle_event", release_event), "Root should ignore key release for the GM toggle")

	root_scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		failures.append(message)
```

- [ ] **Step 2: Run the console test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/gm_console_toggle_regression.gd
```

Expected: FAIL because `Root` does not yet expose GM console methods and `GMConsole` child does not exist.

- [ ] **Step 3: Create the console script**

Create `scripts/dev/GMConsole.gd`:

```gdscript
extends Control
class_name GMConsole

const GMCommandExecutorScript := preload("res://scripts/dev/GMCommandExecutor.gd")

var executor: GMCommandExecutor = GMCommandExecutorScript.new()
var output_label: RichTextLabel
var input_line: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide_console()


func toggle() -> void:
	if visible:
		hide_console()
	else:
		show_console()


func show_console() -> void:
	if not executor.is_enabled():
		return
	visible = true
	input_line.grab_focus()


func hide_console() -> void:
	visible = false
	if input_line != null:
		input_line.release_focus()


func submit_command(command_text: String) -> Dictionary:
	var result: Dictionary = executor.execute(command_text)
	if result.get("clear_output", false):
		output_label.clear()
		input_line.clear()
		return result
	_append_output("> %s" % command_text)
	_append_output(str(result.get("message", "")))
	input_line.clear()
	return result


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 12.0
	offset_top = 12.0
	offset_right = -12.0
	offset_bottom = 220.0

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	output_label = RichTextLabel.new()
	output_label.name = "Output"
	output_label.fit_content = false
	output_label.scroll_following = true
	output_label.custom_minimum_size = Vector2(0, 150)
	layout.add_child(output_label)

	input_line = LineEdit.new()
	input_line.name = "Input"
	input_line.placeholder_text = "GM command"
	input_line.text_submitted.connect(_on_input_submitted)
	layout.add_child(input_line)


func _append_output(text: String) -> void:
	output_label.append_text(text + "\n")


func _on_input_submitted(command_text: String) -> void:
	submit_command(command_text)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_console()
		get_viewport().set_input_as_handled()
```

- [ ] **Step 4: Wire the console into Root**

Modify `scripts/Root.gd`.

Add near the top:

```gdscript
const GM_CONSOLE_SCRIPT := preload("res://scripts/dev/GMConsole.gd")

var gm_console: GMConsole
```

Update `_ready()`:

```gdscript
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_gm_console()
```

Add these methods before `_input(event: InputEvent)`:

```gdscript
func _create_gm_console() -> void:
	if gm_console != null:
		return
	gm_console = GM_CONSOLE_SCRIPT.new()
	gm_console.name = "GMConsole"
	add_child(gm_console)


func _toggle_gm_console() -> void:
	if gm_console == null:
		return
	gm_console.toggle()


func _is_gm_console_toggle_event(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event
	return key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_QUOTELEFT
```

At the start of `_input(event: InputEvent)`, before mouse fallback handling, add:

```gdscript
	if _is_gm_console_toggle_event(event):
		_toggle_gm_console()
		get_viewport().set_input_as_handled()
		return
```

No manual change is required in `scenes/Root.tscn` because `Root.gd` creates the console at runtime. If Godot generates `.uid` files for new scripts when tests run, include only project-relevant `.gd.uid` files if the repository normally tracks them for scripts.

- [ ] **Step 5: Run the console test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/gm_console_toggle_regression.gd
```

Expected: `ALL_TESTS_PASSED`

- [ ] **Step 6: Run both GM tests**

Run:

```bash
godot --headless --path . --script tests/gm_command_executor_regression.gd
godot --headless --path . --script tests/gm_console_toggle_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

- [ ] **Step 7: Commit Task 2**

Run:

```bash
git add scripts/dev/GMConsole.gd scripts/Root.gd tests/gm_console_toggle_regression.gd
git commit -m "feat: add GM console hotkey UI"
```

Expected: commit succeeds with console UI, Root wiring, and toggle test.

---

### Task 3: Final Verification

**Files:**
- Test: `tests/gm_command_executor_regression.gd`
- Test: `tests/gm_console_toggle_regression.gd`
- Test: `tests/ui_mouse_fallback_regression.gd`
- Test: `tests/card_effects_regression.gd`

**Interfaces:**
- Consumes: Task 1 and Task 2 interfaces.
- Produces: verified GM command console implementation with focused and adjacent regressions passing.

- [ ] **Step 1: Run the focused GM tests**

Run:

```bash
godot --headless --path . --script tests/gm_command_executor_regression.gd
godot --headless --path . --script tests/gm_console_toggle_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

- [ ] **Step 2: Run existing input fallback regression**

Run:

```bash
godot --headless --path . --script tests/ui_mouse_fallback_regression.gd
```

Expected: `ALL_TESTS_PASSED`. This protects the existing `Root.gd` mouse fallback behavior that shares `_input()`.

- [ ] **Step 3: Run existing card effects regression**

Run:

```bash
godot --headless --path . --script tests/card_effects_regression.gd
```

Expected: `ALL_TESTS_PASSED`. This protects card data/action behavior touched indirectly by `card add` and `cards all`.

- [ ] **Step 4: Inspect git diff for unintended files**

Run:

```bash
git status --short
git diff -- scripts/dev/GMCommandExecutor.gd scripts/dev/GMConsole.gd scripts/Root.gd tests/gm_command_executor_regression.gd tests/gm_console_toggle_regression.gd
```

Expected: `git diff -- ...` prints no patch after Task 1 and Task 2 commits. `git status --short` may still show unrelated pre-existing workspace changes outside this plan.

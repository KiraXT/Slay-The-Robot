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
	for card_data in Global.get_all_cards():
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
	for artifact_data in Global.get_all_artifacts():
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
			var old_energy: int = Global.player_data.player_energy
			var new_energy: int = max(parsed.value, 0)
			var actual_delta: int = new_energy - old_energy
			Global.player_data.player_energy = new_energy
			Signals.energy_added.emit(actual_delta)
			return _success("OK: energy set to %d (changed by %d)" % [new_energy, actual_delta])
		"add":
			var old_energy: int = Global.player_data.player_energy
			var new_energy: int = max(old_energy + parsed.value, 0)
			var actual_delta: int = new_energy - old_energy
			Global.player_data.player_energy = new_energy
			Signals.energy_added.emit(actual_delta)
			return _success("OK: energy changed by %d" % actual_delta)
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
	var card_data = Global.get_card_data_from_prototype(card_id)
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

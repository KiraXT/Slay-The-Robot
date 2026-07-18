extends SceneTree

const CARD_DIR := "res://external/data/cards"
const RESOLVER_SCRIPT_PATH := "res://scripts/ui/CardPresentationResolver.gd"
const PRESENTATION_GENERATOR_PATH := "res://tools/generate_card_presentation_config.js"
const PRESENTATION_FIELDS := [
	"card_visual_profile",
	"card_play_sfx",
	"card_impact_vfx",
	"card_screen_shake",
	"card_hit_pause",
]

const EXPECTED_CARD_PRESENTATION := {
	"card_attack_basic": {
		"card_visual_profile": "attack",
		"card_play_sfx": "card_attack",
		"card_impact_vfx": "impact_slash",
		"card_screen_shake": "small",
		"card_hit_pause": 0.035,
	},
	"card_attack_big": {
		"card_visual_profile": "attack",
		"card_play_sfx": "card_attack_heavy",
		"card_impact_vfx": "impact_heavy",
		"card_screen_shake": "medium",
		"card_hit_pause": 0.055,
	},
	"variable_cost_attack_card": {
		"card_visual_profile": "attack",
		"card_play_sfx": "card_attack_heavy",
		"card_impact_vfx": "impact_heavy",
		"card_screen_shake": "medium",
		"card_hit_pause": 0.055,
	},
	"card_block_basic": {
		"card_visual_profile": "skill",
		"card_play_sfx": "card_skill_guard",
		"card_impact_vfx": "guard_burst",
		"card_screen_shake": "",
		"card_hit_pause": 0.0,
	},
	"card_draw": {
		"card_visual_profile": "skill",
		"card_play_sfx": "card_skill_draw",
		"card_impact_vfx": "card_flow",
		"card_screen_shake": "",
		"card_hit_pause": 0.0,
	},
	"card_vulnerable_enemies": {
		"card_visual_profile": "skill",
		"card_play_sfx": "card_status",
		"card_impact_vfx": "status_burst",
		"card_screen_shake": "small",
		"card_hit_pause": 0.025,
	},
	"card_weaken_enemies": {
		"card_visual_profile": "skill",
		"card_play_sfx": "card_status",
		"card_impact_vfx": "status_burst",
		"card_screen_shake": "small",
		"card_hit_pause": 0.025,
	},
	"card_duplicate_plays": {
		"card_visual_profile": "power",
		"card_play_sfx": "card_power",
		"card_impact_vfx": "power_aura",
		"card_screen_shake": "",
		"card_hit_pause": 0.025,
	},
	"card_duplicate_attacks": {
		"card_visual_profile": "skill",
		"card_play_sfx": "card_power",
		"card_impact_vfx": "power_aura",
		"card_screen_shake": "",
		"card_hit_pause": 0.025,
	},
	"card_bomb": {
		"card_visual_profile": "skill",
		"card_play_sfx": "card_status_heavy",
		"card_impact_vfx": "status_burst",
		"card_screen_shake": "medium",
		"card_hit_pause": 0.04,
	},
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var resolver_source := FileAccess.get_file_as_string(RESOLVER_SCRIPT_PATH)
	var generator_source := FileAccess.get_file_as_string(PRESENTATION_GENERATOR_PATH)
	_assert_not_empty(resolver_source, RESOLVER_SCRIPT_PATH)
	_assert_not_empty(generator_source, PRESENTATION_GENERATOR_PATH)
	var known_visual_profiles := _extract_string_array_constant(resolver_source, "KNOWN_VISUAL_PROFILE_IDS")
	var known_play_sfx_ids := _extract_string_array_constant(resolver_source, "KNOWN_PLAY_SFX_IDS")
	var known_impact_vfx_ids := _extract_string_array_constant(resolver_source, "KNOWN_IMPACT_VFX_IDS")
	var known_screen_shake_ids := _extract_string_array_constant(resolver_source, "KNOWN_SCREEN_SHAKE_IDS")

	for card_object_id in EXPECTED_CARD_PRESENTATION:
		_check_card_presentation(card_object_id, EXPECTED_CARD_PRESENTATION[card_object_id])
	_check_all_cards_have_presentation_fields(
		known_visual_profiles,
		known_play_sfx_ids,
		known_impact_vfx_ids,
		known_screen_shake_ids
	)
	if generator_source != "":
		_check_presentation_generator_source(generator_source)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_card_presentation(card_object_id: String, expected_properties: Dictionary) -> void:
	var path := "%s/%s.json" % [CARD_DIR, card_object_id]
	var source := FileAccess.get_file_as_string(path)
	if source == "":
		failures.append("failed to read %s" % path)
		return

	var parsed: Variant = JSON.parse_string(source)
	if not parsed is Dictionary:
		failures.append("%s must parse as a JSON dictionary" % path)
		return

	var properties: Dictionary = parsed.get("properties", {})
	for property_name in expected_properties:
		if not properties.has(property_name):
			failures.append("%s must define `%s` explicitly" % [card_object_id, property_name])
			continue
		var actual: Variant = properties[property_name]
		var expected: Variant = expected_properties[property_name]
		if actual != expected:
			failures.append(
				"%s `%s` expected `%s`, got `%s`" % [
					card_object_id,
					property_name,
					str(expected),
					str(actual),
				]
			)


func _check_all_cards_have_presentation_fields(
	known_visual_profiles: Array[String],
	known_play_sfx_ids: Array[String],
	known_impact_vfx_ids: Array[String],
	known_screen_shake_ids: Array[String]
) -> void:
	var card_dir := DirAccess.open(CARD_DIR)
	if card_dir == null:
		failures.append("failed to open %s" % CARD_DIR)
		return

	for file_name in card_dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := "%s/%s" % [CARD_DIR, file_name]
		var source := FileAccess.get_file_as_string(path)
		if source == "":
			failures.append("failed to read %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(source)
		if not parsed is Dictionary:
			failures.append("%s must parse as a JSON dictionary" % path)
			continue
		var properties: Dictionary = parsed.get("properties", {})
		var card_object_id: String = properties.get("object_id", file_name)
		for field_name in PRESENTATION_FIELDS:
			if not properties.has(field_name):
				failures.append("%s must explicitly define `%s`" % [card_object_id, field_name])
		if properties.has("card_hit_pause") and not (properties["card_hit_pause"] is int or properties["card_hit_pause"] is float):
			failures.append("%s `card_hit_pause` must be numeric" % card_object_id)
		_assert_allowed_value(card_object_id, "card_visual_profile", properties, known_visual_profiles)
		_assert_allowed_value(card_object_id, "card_play_sfx", properties, known_play_sfx_ids)
		_assert_allowed_value(card_object_id, "card_impact_vfx", properties, known_impact_vfx_ids)
		_assert_allowed_value(card_object_id, "card_screen_shake", properties, known_screen_shake_ids)


func _extract_string_array_constant(source: String, constant_name: String) -> Array[String]:
	var declaration := "const %s" % constant_name
	var declaration_start := source.find(declaration)
	if declaration_start < 0:
		failures.append("resolver must define `%s`" % constant_name)
		return []
	var assignment_start := source.find("=", declaration_start)
	var array_start := source.find("[", assignment_start)
	var array_end := source.find("]", array_start)
	if array_start < 0 or array_end < 0:
		failures.append("resolver `%s` must be an array literal" % constant_name)
		return []
	var parsed: Variant = JSON.parse_string(source.substr(array_start, array_end - array_start + 1))
	if not parsed is Array:
		failures.append("resolver `%s` must parse as a string array" % constant_name)
		return []
	var values: Array[String] = []
	for value in parsed:
		if not value is String:
			failures.append("resolver `%s` must only contain strings" % constant_name)
			continue
		values.append(value)
	return values


func _check_presentation_generator_source(source: String) -> void:
	for expected in [
		"const PRESENTATION_FIELDS = [",
		"\"card_visual_profile\"",
		"\"card_play_sfx\"",
		"\"card_impact_vfx\"",
		"\"card_screen_shake\"",
		"\"card_hit_pause\"",
		"function inferPresentation(properties)",
		"function cardHasAction(properties, actionName)",
		"const MANUAL_PRESENTATION_OVERRIDES = {",
		"card_bomb",
		"card_duplicate_attacks",
		"card_energy_on_draw",
		"card_energy_on_discard",
		"--check",
		"--write",
	]:
		_assert_contains(
			source,
			expected,
			"card presentation generator must support repeatable config generation"
		)


func _assert_allowed_value(card_object_id: String, field_name: String, properties: Dictionary, allowed_values: Array[String]) -> void:
	if not properties.has(field_name):
		return
	var value: Variant = properties[field_name]
	if not value is String:
		failures.append("%s `%s` must be a string" % [card_object_id, field_name])
		return
	if not allowed_values.has(value):
		failures.append("%s `%s` uses unknown id `%s`" % [card_object_id, field_name, value])


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])


func _assert_not_empty(value: String, label: String) -> void:
	if value == "":
		failures.append("failed to read %s" % label)

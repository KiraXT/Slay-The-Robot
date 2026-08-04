extends SceneTree

const HAND_SCRIPT_PATH := "res://scripts/ui/Hand.gd"
const COMBAT_SCRIPT_PATH := "res://scripts/ui/Combat.gd"
const CARD_DATA_SCRIPT_PATH := "res://data/prototype/CardData.gd"
const SIGNALS_SCRIPT_PATH := "res://autoload/Signals.gd"
const RESOLVER_SCRIPT_PATH := "res://scripts/ui/CardPresentationResolver.gd"
const PRESENTER_SCRIPT_PATH := "res://scripts/ui/CombatFeedbackPresenter.gd"
const SFX_LIBRARY_SCRIPT_PATH := "res://scripts/ui/CombatFeedbackSfxLibrary.gd"
const SFX_GENERATOR_SCRIPT_PATH := "res://tools/generate_combat_sfx_assets.js"
const VFX_SCENE_PATH := "res://scenes/ui/vfx/CardImpactVFX.tscn"
const VFX_SCRIPT_PATH := "res://scripts/ui/vfx/CardImpactVFX.gd"
const DEFAULT_SFX_IDS := [
	"card_attack",
	"card_attack_heavy",
	"card_skill",
	"card_skill_draw",
	"card_skill_guard",
	"card_skill_heal",
	"card_skill_item",
	"card_status",
	"card_status_heavy",
	"card_power",
	"card_energy",
	"impact_damage",
	"block_gain",
	"block_hit",
	"block_break",
	"status_apply",
	"energy_change",
	"pile_draw",
	"pile_discard",
	"pile_exhaust",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hand_source := FileAccess.get_file_as_string(HAND_SCRIPT_PATH)
	var combat_source := FileAccess.get_file_as_string(COMBAT_SCRIPT_PATH)
	var card_data_source := FileAccess.get_file_as_string(CARD_DATA_SCRIPT_PATH)
	var signals_source := FileAccess.get_file_as_string(SIGNALS_SCRIPT_PATH)
	var resolver_source := FileAccess.get_file_as_string(RESOLVER_SCRIPT_PATH)
	var presenter_source := FileAccess.get_file_as_string(PRESENTER_SCRIPT_PATH)
	var sfx_library_source := FileAccess.get_file_as_string(SFX_LIBRARY_SCRIPT_PATH)
	var sfx_generator_source := FileAccess.get_file_as_string(SFX_GENERATOR_SCRIPT_PATH)
	var vfx_scene_source := FileAccess.get_file_as_string(VFX_SCENE_PATH)
	var vfx_script_source := FileAccess.get_file_as_string(VFX_SCRIPT_PATH)

	_assert_not_empty(hand_source, HAND_SCRIPT_PATH)
	_assert_not_empty(combat_source, COMBAT_SCRIPT_PATH)
	_assert_not_empty(card_data_source, CARD_DATA_SCRIPT_PATH)
	_assert_not_empty(signals_source, SIGNALS_SCRIPT_PATH)
	_assert_not_empty(resolver_source, RESOLVER_SCRIPT_PATH)
	_assert_not_empty(presenter_source, PRESENTER_SCRIPT_PATH)
	_assert_not_empty(sfx_library_source, SFX_LIBRARY_SCRIPT_PATH)
	_assert_not_empty(sfx_generator_source, SFX_GENERATOR_SCRIPT_PATH)
	_assert_not_empty(vfx_scene_source, VFX_SCENE_PATH)
	_assert_not_empty(vfx_script_source, VFX_SCRIPT_PATH)

	if hand_source != "":
		_check_hand_release_and_target_feedback(hand_source)
		_check_hand_review_regressions(hand_source)
	if combat_source != "":
		_check_combat_owns_presenter(combat_source)
	if card_data_source != "":
		_check_card_visual_fields(card_data_source)
	if signals_source != "":
		_check_feedback_signals(signals_source)
	if resolver_source != "":
		_check_resolver_script_loads()
		_check_resolver_default_preset_source(resolver_source)
		_check_resolver_audio_and_vfx_hooks(resolver_source)
	if presenter_source != "":
		_check_presenter_script_loads()
		_check_presenter_signal_feedback(presenter_source)
		_check_presenter_consumes_card_visual_fields(presenter_source)
		_check_presenter_uses_resolver(presenter_source)
		_check_presenter_audio_hooks(presenter_source)
		_check_presenter_auto_registers_sfx(presenter_source)
		_check_presenter_uses_vfx_scene(presenter_source)
	if sfx_library_source != "":
		_check_sfx_library_script_loads()
		_check_sfx_library_source(sfx_library_source)
		_check_default_sfx_assets_load()
	if sfx_generator_source != "":
		_check_sfx_generator_source(sfx_generator_source)
	if vfx_scene_source != "":
		_check_vfx_scene_loads()
	if vfx_script_source != "":
		_check_vfx_script_source(vfx_script_source)

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_hand_release_and_target_feedback(source: String) -> void:
	var drag_started_body := _function_body(source, "_on_card_drag_started")
	var drag_ended_body := _function_body(source, "_on_card_drag_ended")
	var execute_body := _function_body(source, "_execute_card_play")
	var highlight_body := _function_body(source, "_update_drag_target_highlight")

	_assert_contains(
		drag_started_body,
		"_show_invalid_card_feedback(card,",
		"unplayable card drag attempts must produce immediate invalid feedback"
	)
	_assert_contains(
		drag_ended_body,
		"_show_invalid_card_feedback(card, CARD_INVALID_TARGET_COLOR)",
		"invalid target release must visibly reject the play"
	)
	_assert_contains(
		execute_body,
		"_get_card_release_target(card, target)",
		"card release animation must use a card-type-aware release target"
	)
	_assert_contains(
		execute_body,
		"CARD_PLAY_RELEASE_WINDUP_TIME",
		"card release animation must have a windup beat before flying out"
	)
	_assert_contains(
		execute_body,
		"CARD_PLAY_RELEASE_TRAVEL_TIME",
		"card release animation must have a separate travel beat"
	)
	_assert_contains(
		highlight_body,
		"_apply_drag_target_feedback(target)",
		"drag target hover must apply combatant emphasis, not only a border"
	)
	_assert_contains(
		source,
		"func _update_drag_line_color(has_valid_target: bool) -> void:",
		"targeting arrow must change color for valid and invalid targets"
	)


func _check_hand_review_regressions(source: String) -> void:
	var drag_ended_body := _function_body(source, "_on_card_drag_ended")
	var hover_target_body := _function_body(source, "_get_drag_hover_target")
	var add_queue_body := _function_body(source, "add_card_to_play_queue")
	var play_card_body := _function_body(source, "_play_card")

	_assert_contains(
		source,
		"func _is_valid_card_play_target(card: Card, target: BaseCombatant) -> bool:",
		"hand must centralize card target eligibility"
	)
	_assert_contains(
		drag_ended_body,
		"_is_valid_card_play_target(card, target)",
		"drag release must validate target eligibility before playing"
	)
	_assert_not_contains(
		drag_ended_body,
		"target == player and card.card_data.card_requires_target",
		"generic target-required cards must not treat the player as valid"
	)
	_assert_contains(
		hover_target_body,
		"_is_valid_card_play_target(card, player)",
		"hover detection must use the same target eligibility for player hover"
	)
	_assert_contains(
		play_card_body,
		"Signals.card_moved_to_pile.emit(card_play_request.card_data, \"discard\")",
		"normal played cards must emit discard pile feedback"
	)
	_assert_contains(
		add_queue_body,
		"if energy_cost > 0:",
		"zero-cost cards must not emit energy spend feedback"
	)


func _check_combat_owns_presenter(source: String) -> void:
	_assert_contains(
		source,
		"const COMBAT_FEEDBACK_PRESENTER_SCRIPT",
		"Combat must preload the combat feedback presenter"
	)
	_assert_contains(
		source,
		"combat_feedback_presenter.init(",
		"Combat must initialize the feedback presenter with combat UI nodes"
	)


func _check_card_visual_fields(source: String) -> void:
	for field_name in [
		"card_visual_profile",
		"card_play_sfx",
		"card_impact_vfx",
		"card_screen_shake",
		"card_hit_pause",
	]:
		_assert_contains(
			source,
			"@export var %s" % field_name,
			"CardData must expose %s for data-driven presentation overrides" % field_name
		)


func _check_feedback_signals(source: String) -> void:
	_assert_contains(
		source,
		"signal combatant_status_applied",
		"status application must emit a feedback signal"
	)
	_assert_contains(
		source,
		"signal card_energy_spent",
		"manual card energy spending must emit a feedback signal"
	)
	_assert_contains(
		source,
		"signal card_moved_to_pile",
		"card pile movement must emit a dedicated feedback signal"
	)


func _check_presenter_signal_feedback(source: String) -> void:
	for method_name in [
		"play_damage_feedback",
		"play_block_gain_feedback",
		"play_block_hit_feedback",
		"play_block_break_feedback",
		"play_status_feedback",
		"play_energy_feedback",
		"play_pile_feedback",
		"play_card_started_feedback",
	]:
		_assert_contains(
			source,
			"func %s" % method_name,
			"CombatFeedbackPresenter must implement %s" % method_name
		)
	_assert_contains(
		source,
		"Signals.combatant_damaged.connect",
		"presenter must listen for damage feedback"
	)
	_assert_contains(
		source,
		"Signals.combatant_status_applied.connect",
		"presenter must listen for status feedback"
	)
	_assert_contains(
		source,
		"Signals.card_energy_spent.connect",
		"presenter must listen for energy spend feedback"
	)
	_assert_contains(
		source,
		"Signals.card_moved_to_pile.connect",
		"presenter must listen for pile movement feedback"
	)
	_assert_contains(
		source,
		"AudioStreamPlayer",
		"presenter must include an audio layer hook even when no streams are configured"
	)


func _check_presenter_consumes_card_visual_fields(source: String) -> void:
	var damage_body := _function_body(source, "play_damage_feedback")
	var status_body := _function_body(source, "play_status_feedback")
	var started_body := _function_body(source, "play_card_started_feedback")
	var played_body := _function_body(source, "_on_card_played")
	var impact_body := _function_body(source, "_apply_configured_impact_feedback")

	_assert_contains(
		source,
		"var _active_card_play_request: CardPlayRequest = null",
		"presenter must keep the active card play context for impact overrides"
	)
	_assert_contains(
		source,
		"Signals.card_played.connect(_on_card_played)",
		"presenter must clear card play context when the card finishes"
	)
	_assert_contains(
		started_body,
		"_active_card_play_request = card_play_request",
		"card play start feedback must store active card context"
	)
	_assert_contains(
		played_body,
		"_active_card_play_request = null",
		"card play finished feedback must clear active card context"
	)
	_assert_contains(
		damage_body,
		"_apply_configured_impact_feedback(base_combatant)",
		"damage feedback must apply card impact overrides"
	)
	_assert_contains(
		status_body,
		"_apply_configured_impact_feedback(base_combatant)",
		"status feedback must apply card impact overrides"
	)
	for field_name in ["card_impact_vfx", "card_screen_shake", "card_hit_pause"]:
		_assert_contains(
			impact_body,
			"_get_%s(card_data)" % field_name,
			"configured impact feedback must consume %s through preset fallback" % field_name
		)
	for method_name in ["_get_card_impact_vfx", "_get_card_screen_shake", "_get_card_hit_pause"]:
		_assert_contains(
			source,
			"func %s(card_data: CardData)" % method_name,
			"presenter must expose %s so every card has a tunable fallback" % method_name
		)
	_assert_contains(
		source,
		"func _apply_screen_shake(preset: String) -> void:",
		"presenter must support configured screen shake presets"
	)
	_assert_contains(
		source,
		"func _apply_hit_pause(duration: float) -> void:",
		"presenter must support configured hit pause"
	)
	_assert_contains(
		source,
		"func _play_impact_vfx(base_combatant: BaseCombatant, effect_id: String) -> void:",
		"presenter must support configured impact vfx"
	)


func _check_presenter_uses_resolver(source: String) -> void:
	for expected in [
		"const CARD_PRESENTATION_RESOLVER_SCRIPT := preload(\"res://scripts/ui/CardPresentationResolver.gd\")",
		"var presentation_resolver: RefCounted = CARD_PRESENTATION_RESOLVER_SCRIPT.new()",
		"presentation_resolver.get_card_impact_vfx(card_data)",
		"presentation_resolver.get_card_screen_shake(card_data)",
		"presentation_resolver.get_card_hit_pause(card_data)",
		"presentation_resolver.get_card_visual_profile(card_data)",
		"presentation_resolver.get_card_play_sfx(card_data)",
		"presentation_resolver.get_impact_vfx_color(effect_id)",
	]:
		_assert_contains(
			source,
			expected,
			"CombatFeedbackPresenter must delegate presentation rules through resolver"
		)
	_assert_not_contains(
		source,
		"func _card_has_action(card_data: CardData, action_name: String) -> bool:",
		"card action inspection must live in CardPresentationResolver"
	)
	_assert_not_contains(
		source,
		"func _is_heavy_attack(card_data: CardData) -> bool:",
		"heavy attack classification must live in CardPresentationResolver"
	)


func _check_resolver_default_preset_source(source: String) -> void:
	var impact_body := _function_body(source, "get_card_impact_vfx")
	var shake_body := _function_body(source, "get_card_screen_shake")
	var pause_body := _function_body(source, "get_card_hit_pause")

	for expected in [
		"card_data.card_impact_vfx",
		"CardData.CARD_TYPES.ATTACK",
		"CardData.CARD_TYPES.SKILL",
		"CardData.CARD_TYPES.POWER",
		"impact_slash",
		"impact_heavy",
		"status_burst",
		"guard_burst",
		"power_aura",
		"_card_has_action(card_data, \"ActionApplyStatus.gd\")",
		"_card_has_action(card_data, \"ActionBlock.gd\")",
	]:
		_assert_contains(
			impact_body,
			expected,
			"impact preset fallback must include %s" % expected
		)

	for expected in ["card_data.card_screen_shake", "\"medium\"", "\"small\"", "_is_heavy_attack(card_data)"]:
		_assert_contains(
			shake_body,
			expected,
			"screen shake fallback must include %s" % expected
		)

	for expected in ["card_data.card_hit_pause", "0.035", "0.055", "0.025", "_is_heavy_attack(card_data)"]:
		_assert_contains(
			pause_body,
			expected,
			"hit pause fallback must include %s" % expected
		)

	_assert_contains(
		source,
		"func get_card_visual_profile(card_data: CardData) -> String:",
		"resolver must own visual profile resolution"
	)
	_assert_contains(
		source,
		"func get_card_play_sfx(card_data: CardData) -> String:",
		"resolver must own play sfx resolution"
	)
	_assert_contains(
		source,
		"func _card_has_action(card_data: CardData, action_name: String) -> bool:",
		"resolver must inspect card action names for fallback presets"
	)
	_assert_contains(
		source,
		"func _is_heavy_attack(card_data: CardData) -> bool:",
		"resolver must classify high-impact attacks for stronger feedback"
	)


func _check_presenter_audio_hooks(source: String) -> void:
	var play_sfx_body := _function_body(source, "_play_sfx")

	_assert_contains(
		source,
		"var sound_id_to_stream: Dictionary[String, AudioStream] = {}",
		"presenter must expose a sound id registry for real audio assets"
	)
	_assert_contains(
		source,
		"func register_sfx_stream(sound_id: String, stream: AudioStream) -> void:",
		"presenter must allow Combat or data loaders to register real audio streams"
	)
	_assert_contains(
		play_sfx_body,
		"sound_id_to_stream.get(_sound_id, null)",
		"play_sfx must resolve configured sound ids through the registry"
	)
	_assert_contains(
		play_sfx_body,
		"audio_player.stream = stream",
		"play_sfx must assign the resolved stream to the AudioStreamPlayer"
	)
	_assert_contains(
		play_sfx_body,
		"audio_player.play()",
		"play_sfx must play registered streams"
	)


func _check_presenter_auto_registers_sfx(source: String) -> void:
	_assert_contains(
		source,
		"const COMBAT_FEEDBACK_SFX_LIBRARY_SCRIPT := preload(\"res://scripts/ui/CombatFeedbackSfxLibrary.gd\")",
		"presenter must preload the default combat sfx library"
	)
	_assert_contains(
		source,
		"sfx_library.register_default_sfx(self)",
		"presenter must auto-register default placeholder sfx during init"
	)


func _check_sfx_library_script_loads() -> void:
	var sfx_library_script := load(SFX_LIBRARY_SCRIPT_PATH)
	if sfx_library_script == null:
		failures.append("CombatFeedbackSfxLibrary script must load without parse errors")


func _check_sfx_library_source(source: String) -> void:
	for expected in [
		"class_name CombatFeedbackSfxLibrary",
		"const DEFAULT_SFX_PATHS",
		"func register_default_sfx(presenter: Node) -> void:",
		"func load_sfx_stream(path: String) -> AudioStream:",
		"presenter.register_sfx_stream(sound_id, stream)",
		"func get_default_sfx_paths() -> Dictionary:",
	]:
		_assert_contains(
			source,
			expected,
			"default sfx library must expose automatic registration"
		)
	for sound_id in DEFAULT_SFX_IDS:
		_assert_contains(
			source,
			"\"%s\"" % sound_id,
			"default sfx library must register `%s`" % sound_id
		)


func _check_default_sfx_assets_load() -> void:
	var sfx_library_script := load(SFX_LIBRARY_SCRIPT_PATH)
	if sfx_library_script == null:
		return
	var sfx_library = sfx_library_script.new()
	for sound_id in DEFAULT_SFX_IDS:
		var path := "res://external/audio/sfx/%s.wav" % sound_id
		if not FileAccess.file_exists(path):
			failures.append("default sfx asset missing `%s`" % path)
			continue
		var stream: AudioStream = sfx_library.load_sfx_stream(path)
		if stream == null or not stream is AudioStream:
			failures.append("default sfx asset `%s` must parse as AudioStream" % path)


func _check_sfx_generator_source(source: String) -> void:
	for expected in [
		"const SFX_SPECS = {",
		"writeWav(",
		"sampleRate",
		"external/audio/sfx",
	]:
		_assert_contains(
			source,
			expected,
			"sfx generator must keep placeholder wav assets reproducible"
		)
	for sound_id in DEFAULT_SFX_IDS:
		_assert_contains(
			source,
			"%s:" % sound_id,
			"sfx generator must be able to regenerate `%s`" % sound_id
		)


func _check_presenter_uses_vfx_scene(source: String) -> void:
	var play_vfx_body := _function_body(source, "_play_impact_vfx")
	_assert_contains(
		source,
		"const CARD_IMPACT_VFX_SCENE := preload(\"res://scenes/ui/vfx/CardImpactVFX.tscn\")",
		"presenter must preload the reusable impact vfx scene"
	)
	_assert_contains(
		play_vfx_body,
		"CARD_IMPACT_VFX_SCENE.instantiate()",
		"presenter must instantiate the reusable impact vfx scene"
	)
	_assert_contains(
		play_vfx_body,
		"impact_vfx.init(effect_id, presentation_resolver.get_impact_vfx_color(effect_id))",
		"presenter must initialize scene vfx with resolved effect color"
	)
	_assert_contains(
		source,
		"func _play_fallback_impact_vfx(base_combatant: BaseCombatant, effect_id: String) -> void:",
		"presenter must keep a fallback vfx path when scene loading fails"
	)


func _check_vfx_scene_loads() -> void:
	var vfx_scene := load(VFX_SCENE_PATH)
	if vfx_scene == null:
		failures.append("CardImpactVFX scene must load without parse errors")


func _check_vfx_script_source(source: String) -> void:
	for expected in [
		"class_name CardImpactVFX",
		"func init(_effect_id: String, _effect_color: Color) -> void:",
		"func _build_slash() -> void:",
		"func _build_ring() -> void:",
		"func _build_radial_sparks() -> void:",
		"func _play_animation() -> void:",
		"Line2D.new()",
		"Polygon2D.new()",
		"queue_free",
	]:
		_assert_contains(
			source,
			expected,
			"CardImpactVFX must provide reusable procedural combat impact visuals"
		)


func _check_resolver_audio_and_vfx_hooks(source: String) -> void:
	var color_body := _function_body(source, "get_impact_vfx_color")

	for effect_id in ["guard_burst", "power_aura", "card_flow", "energy_surge", "heal_burst", "item_spark"]:
		_assert_contains(
			color_body,
			"normalized.contains(\"%s\")" % effect_id,
			"impact vfx color mapping must handle %s" % effect_id
		)


func _check_resolver_script_loads() -> void:
	var resolver_script := load(RESOLVER_SCRIPT_PATH)
	if resolver_script == null:
		failures.append("CardPresentationResolver script must load without parse errors")


func _check_presenter_script_loads() -> void:
	var presenter_script := load(PRESENTER_SCRIPT_PATH)
	if presenter_script == null:
		failures.append("CombatFeedbackPresenter script must load without parse errors")


func _function_body(source: String, function_name: String) -> String:
	var signature := "\nfunc %s" % function_name
	var start := source.find(signature)
	if start < 0 and source.begins_with(signature.strip_edges()):
		start = 0
	if start < 0:
		failures.append("missing function %s" % function_name)
		return ""

	var next_function := source.find("\nfunc ", start + signature.length())
	if next_function < 0:
		return source.substr(start)
	return source.substr(start, next_function - start)


func _assert_not_empty(value: String, label: String) -> void:
	if value == "":
		failures.append("failed to read %s" % label)


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])


func _assert_not_contains(haystack: String, needle: String, label: String) -> void:
	if haystack.contains(needle):
		failures.append("%s: found `%s`" % [label, needle])

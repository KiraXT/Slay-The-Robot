extends SceneTree

const PREVIEW_SCENE_PATH := "res://scenes/dev/CombatFeedbackPreview.tscn"
const PREVIEW_SCRIPT_PATH := "res://scripts/dev/CombatFeedbackPreview.gd"
const RESOLVER_SCRIPT_PATH := "res://scripts/ui/CardPresentationResolver.gd"
const SFX_LIBRARY_SCRIPT_PATH := "res://scripts/ui/CombatFeedbackSfxLibrary.gd"

const EXPECTED_VFX_IDS := [
	"impact_slash",
	"impact_heavy",
	"status_burst",
	"guard_burst",
	"power_aura",
	"card_flow",
	"energy_surge",
	"heal_burst",
	"item_spark",
	"skill_spark",
]
const EXPECTED_SFX_IDS := [
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
	var preview_source := FileAccess.get_file_as_string(PREVIEW_SCRIPT_PATH)
	_assert_not_empty(preview_source, PREVIEW_SCRIPT_PATH)
	_check_scene_loads()
	if preview_source != "":
		_check_preview_source(preview_source)
		_check_preview_instantiates()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_scene_loads() -> void:
	var preview_scene := load(PREVIEW_SCENE_PATH)
	if preview_scene == null:
		failures.append("CombatFeedbackPreview scene must load without parse errors")


func _check_preview_source(source: String) -> void:
	for expected in [
		"const CARD_IMPACT_VFX_SCENE := preload(\"res://scenes/ui/vfx/CardImpactVFX.tscn\")",
		"const CARD_PRESENTATION_RESOLVER_SCRIPT := preload(\"res://scripts/ui/CardPresentationResolver.gd\")",
		"const COMBAT_FEEDBACK_SFX_LIBRARY_SCRIPT := preload(\"res://scripts/ui/CombatFeedbackSfxLibrary.gd\")",
		"func _build_preview_ui() -> void:",
		"func _preview_vfx(effect_id: String) -> void:",
		"func _preview_sfx(sound_id: String) -> void:",
		"audio_player.play()",
	]:
		_assert_contains(source, expected, "preview must expose manual VFX/SFX controls")

	for effect_id in EXPECTED_VFX_IDS:
		_assert_contains(source, "\"%s\"" % effect_id, "preview must include VFX `%s`" % effect_id)
	for sound_id in EXPECTED_SFX_IDS:
		_assert_contains(source, "\"%s\"" % sound_id, "preview must include SFX `%s`" % sound_id)


func _check_preview_instantiates() -> void:
	var preview_scene: PackedScene = load(PREVIEW_SCENE_PATH)
	if preview_scene == null:
		return
	var preview := preview_scene.instantiate()
	if preview == null:
		failures.append("CombatFeedbackPreview scene must instantiate")
		return
	root.add_child(preview)
	await process_frame
	if preview.get_node_or_null("Layout") == null:
		failures.append("CombatFeedbackPreview must build a Layout container")
	if preview.get_node_or_null("VFXAnchor") == null:
		failures.append("CombatFeedbackPreview must build a VFXAnchor")
	if preview.get_node_or_null("CombatFeedbackPreviewAudio") == null:
		failures.append("CombatFeedbackPreview must build an audio player")
	preview.queue_free()


func _assert_not_empty(value: String, label: String) -> void:
	if value == "":
		failures.append("failed to read %s" % label)


func _assert_contains(haystack: String, needle: String, label: String) -> void:
	if not haystack.contains(needle):
		failures.append("%s: missing `%s`" % [label, needle])

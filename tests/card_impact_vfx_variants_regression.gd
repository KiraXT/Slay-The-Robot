extends SceneTree

const VFX_SCENE_PATH := "res://scenes/ui/vfx/CardImpactVFX.tscn"
const EXPECTED_EFFECT_CHILDREN := {
	"impact_slash": ["Slash", "SlashEcho"],
	"impact_heavy": ["HeavyCore", "HeavyShard0", "HeavyShockwave"],
	"status_burst": ["StatusRing", "StatusSpark0"],
	"guard_burst": ["GuardRing", "GuardFacet0"],
	"power_aura": ["PowerRing", "PowerRune0"],
	"card_flow": ["CardTrail0", "CardTrail1"],
	"energy_surge": ["EnergyBolt", "EnergyFork0"],
	"heal_burst": ["HealRing", "HealCrossVertical", "HealCrossHorizontal"],
	"item_spark": ["ItemGlint", "ItemSpark0"],
	"skill_spark": ["SkillSpark0", "SkillSpark1"],
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var vfx_scene: PackedScene = load(VFX_SCENE_PATH)
	if vfx_scene == null:
		failures.append("CardImpactVFX scene must load")
	else:
		for effect_id in EXPECTED_EFFECT_CHILDREN:
			_check_effect_children(vfx_scene, effect_id, EXPECTED_EFFECT_CHILDREN[effect_id])

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_effect_children(vfx_scene: PackedScene, effect_id: String, expected_child_names: Array) -> void:
	var vfx := vfx_scene.instantiate()
	if vfx == null:
		failures.append("%s must instantiate" % effect_id)
		return
	root.add_child(vfx)
	vfx.init(effect_id, Color(1.0, 0.8, 0.3, 1.0))

	for child_name in expected_child_names:
		if vfx.get_node_or_null(child_name) == null:
			failures.append("%s must build child `%s`" % [effect_id, child_name])

	if vfx.get_child_count() < expected_child_names.size():
		failures.append("%s must build at least %s visual nodes" % [effect_id, expected_child_names.size()])

	vfx.queue_free()

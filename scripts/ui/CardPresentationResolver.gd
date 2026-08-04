extends RefCounted
class_name CardPresentationResolver

const KNOWN_VISUAL_PROFILE_IDS: Array[String] = ["attack", "skill", "power", "curse"]
const KNOWN_PLAY_SFX_IDS: Array[String] = [
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
]
const KNOWN_IMPACT_VFX_IDS: Array[String] = [
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
const KNOWN_SCREEN_SHAKE_IDS: Array[String] = ["", "small", "medium", "large", "heavy", "none"]


func get_card_visual_profile(card_data: CardData) -> String:
	if card_data == null:
		return "skill"
	if card_data.card_visual_profile != "":
		return card_data.card_visual_profile
	match card_data.card_type:
		CardData.CARD_TYPES.ATTACK:
			return "attack"
		CardData.CARD_TYPES.POWER:
			return "power"
		CardData.CARD_TYPES.CURSE:
			return "curse"
		_:
			return "skill"


func get_card_play_sfx(card_data: CardData) -> String:
	if card_data == null:
		return "card_skill"
	if card_data.card_play_sfx != "":
		return card_data.card_play_sfx
	return "card_%s" % get_card_visual_profile(card_data)


func get_card_impact_vfx(card_data: CardData) -> String:
	if card_data == null:
		return ""
	if card_data.card_impact_vfx != "":
		return card_data.card_impact_vfx

	match card_data.card_type:
		CardData.CARD_TYPES.ATTACK:
			if _is_heavy_attack(card_data):
				return "impact_heavy"
			return "impact_slash"
		CardData.CARD_TYPES.SKILL:
			if _card_has_action(card_data, "ActionApplyStatus.gd"):
				return "status_burst"
			if _card_has_action(card_data, "ActionBlock.gd"):
				return "guard_burst"
			if _card_has_action(card_data, "ActionDrawGenerator.gd") or _card_has_action(card_data, "ActionPickCards.gd"):
				return "card_flow"
			return "skill_spark"
		CardData.CARD_TYPES.POWER:
			return "power_aura"
	return ""


func get_card_screen_shake(card_data: CardData) -> String:
	if card_data == null:
		return ""
	if card_data.card_screen_shake != "":
		return card_data.card_screen_shake

	match card_data.card_type:
		CardData.CARD_TYPES.ATTACK:
			if _is_heavy_attack(card_data):
				return "medium"
			return "small"
		CardData.CARD_TYPES.SKILL:
			if _card_has_action(card_data, "ActionApplyStatus.gd"):
				return "small"
	return ""


func get_card_hit_pause(card_data: CardData) -> float:
	if card_data == null:
		return 0.0
	if card_data.card_hit_pause > 0.0:
		return card_data.card_hit_pause
	if card_data.card_hit_pause < 0.0:
		return 0.0

	match card_data.card_type:
		CardData.CARD_TYPES.ATTACK:
			if _is_heavy_attack(card_data):
				return 0.055
			return 0.035
		CardData.CARD_TYPES.SKILL:
			if _card_has_action(card_data, "ActionApplyStatus.gd"):
				return 0.025
		CardData.CARD_TYPES.POWER:
			return 0.025
	return 0.0


func get_impact_vfx_color(effect_id: String) -> Color:
	var normalized := effect_id.to_lower()
	if normalized.contains("guard_burst"):
		return Color(0.40, 0.86, 1.0, 0.88)
	if normalized.contains("power_aura"):
		return Color(0.76, 0.55, 1.0, 0.86)
	if normalized.contains("card_flow"):
		return Color(0.38, 0.72, 1.0, 0.84)
	if normalized.contains("energy_surge"):
		return Color(0.35, 0.95, 1.0, 0.90)
	if normalized.contains("heal_burst"):
		return Color(0.46, 1.0, 0.62, 0.86)
	if normalized.contains("item_spark"):
		return Color(1.0, 0.88, 0.42, 0.88)
	if normalized.contains("poison") or normalized.contains("status"):
		return Color(0.46, 1.0, 0.58, 0.88)
	if normalized.contains("shock") or normalized.contains("electric"):
		return Color(0.38, 0.88, 1.0, 0.90)
	if normalized.contains("fire") or normalized.contains("burn") or normalized.contains("explosion"):
		return Color(1.0, 0.54, 0.24, 0.90)
	return Color(1.0, 0.95, 0.55, 0.90)


func _card_has_action(card_data: CardData, action_name: String) -> bool:
	if card_data == null:
		return false
	for action_data in card_data.card_play_actions:
		if not action_data is Dictionary:
			continue
		for action_path in action_data.keys():
			if str(action_path).ends_with(action_name):
				return true
	return false


func _is_heavy_attack(card_data: CardData) -> bool:
	if card_data == null or card_data.card_type != CardData.CARD_TYPES.ATTACK:
		return false
	if card_data.card_energy_cost_is_variable or card_data.card_energy_cost >= 2:
		return true
	return _get_card_total_damage_estimate(card_data) >= 12.0


func _get_card_total_damage_estimate(card_data: CardData) -> float:
	if card_data == null:
		return 0.0
	var damage_value: Variant = card_data.card_values.get("damage", 0)
	var attack_count_value: Variant = card_data.card_values.get("number_of_attacks", 1)
	var damage := 0.0
	var attack_count := 1.0
	if damage_value is int or damage_value is float:
		damage = float(damage_value)
	if attack_count_value is int or attack_count_value is float:
		attack_count = max(1.0, float(attack_count_value))
	return damage * attack_count

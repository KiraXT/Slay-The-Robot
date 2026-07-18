extends Node2D
class_name CardImpactVFX

const DEFAULT_EFFECT_COLOR := Color(1.0, 0.72, 0.34, 1.0)
const EFFECT_TIME := 0.24
const SLASH_WIDTH := 8.0
const SPARK_COUNT := 10
const RING_SEGMENTS := 18

var effect_id := ""
var effect_color := DEFAULT_EFFECT_COLOR
var animation_tween: Tween = null


func init(_effect_id: String, _effect_color: Color) -> void:
	effect_id = _effect_id
	effect_color = _effect_color
	_rebuild()
	_play_animation()


func _ready() -> void:
	if get_child_count() == 0:
		_rebuild()
		_play_animation()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var normalized := effect_id.to_lower()
	if normalized.contains("heavy"):
		_build_heavy_impact()
	elif normalized.contains("slash"):
		_build_slash()
	elif normalized.contains("status"):
		_build_status_burst()
	elif normalized.contains("guard"):
		_build_guard_burst()
	elif normalized.contains("power"):
		_build_power_aura()
	elif normalized.contains("card_flow"):
		_build_card_flow()
	elif normalized.contains("energy"):
		_build_energy_surge()
	elif normalized.contains("heal"):
		_build_heal_burst()
	elif normalized.contains("item"):
		_build_item_spark()
	else:
		_build_skill_spark()


func _build_slash() -> void:
	_add_line("Slash", [
		Vector2(-38.0, 28.0),
		Vector2(-10.0, -4.0),
		Vector2(40.0, -30.0),
	], SLASH_WIDTH, effect_color)
	_add_line("SlashEcho", [
		Vector2(-28.0, 38.0),
		Vector2(0.0, 8.0),
		Vector2(30.0, -18.0),
	], SLASH_WIDTH * 0.42, Color(effect_color.r, effect_color.g, effect_color.b, 0.45), 20)


func _build_heavy_impact() -> void:
	_add_polygon("HeavyCore", [
		Vector2(0.0, -30.0),
		Vector2(27.0, -12.0),
		Vector2(24.0, 20.0),
		Vector2(0.0, 34.0),
		Vector2(-24.0, 20.0),
		Vector2(-27.0, -12.0),
	], Color(effect_color.r, effect_color.g, effect_color.b, 0.48))
	for index in 6:
		var angle := TAU * float(index) / 6.0
		var direction := Vector2(cos(angle), sin(angle))
		var tangent := direction.rotated(PI * 0.5) * 5.0
		_add_polygon("HeavyShard%s" % index, [
			direction * 22.0 + tangent,
			direction * 48.0,
			direction * 22.0 - tangent,
		], effect_color)
	var shockwave := _add_ring("HeavyShockwave", 42.0, 7.0, Color(effect_color.r, effect_color.g, effect_color.b, 0.58))
	shockwave.z_index = 19


func _build_ring() -> void:
	_add_ring("Ring", 30.0, 5.0, effect_color)
	_add_polygon("Core", [
		Vector2(0.0, -18.0),
		Vector2(16.0, 0.0),
		Vector2(0.0, 18.0),
		Vector2(-16.0, 0.0),
	], Color(effect_color.r, effect_color.g, effect_color.b, 0.30), 20)


func _build_status_burst() -> void:
	_add_ring("StatusRing", 30.0, 5.0, effect_color)
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var direction := Vector2(cos(angle), sin(angle))
		_add_line("StatusSpark%s" % index, [
			direction * 8.0,
			direction * 30.0 + direction.rotated(PI * 0.18) * 8.0,
		], 3.0, Color(effect_color.r, effect_color.g, effect_color.b, 0.78))


func _build_guard_burst() -> void:
	_add_ring("GuardRing", 32.0, 6.0, effect_color)
	for index in 6:
		var angle := TAU * float(index) / 6.0 + PI / 6.0
		var direction := Vector2(cos(angle), sin(angle))
		var tangent := direction.rotated(PI * 0.5)
		_add_polygon("GuardFacet%s" % index, [
			direction * 16.0 + tangent * 6.0,
			direction * 34.0,
			direction * 16.0 - tangent * 6.0,
		], Color(effect_color.r, effect_color.g, effect_color.b, 0.42), 20)


func _build_power_aura() -> void:
	_add_ring("PowerRing", 34.0, 5.0, effect_color)
	_add_ring("PowerInnerRing", 19.0, 2.5, Color(effect_color.r, effect_color.g, effect_color.b, 0.55), 20)
	for index in 5:
		var angle := TAU * float(index) / 5.0 - PI * 0.5
		var center := Vector2(cos(angle), sin(angle)) * 32.0
		_add_polygon("PowerRune%s" % index, [
			center + Vector2(0.0, -7.0).rotated(angle),
			center + Vector2(6.0, 3.0).rotated(angle),
			center + Vector2(-6.0, 3.0).rotated(angle),
		], effect_color)


func _build_card_flow() -> void:
	for index in 3:
		var offset := float(index - 1) * 13.0
		_add_line("CardTrail%s" % index, [
			Vector2(-35.0, offset + 14.0),
			Vector2(-6.0, offset),
			Vector2(36.0, offset - 11.0),
		], 4.0, Color(effect_color.r, effect_color.g, effect_color.b, 0.74 - float(index) * 0.12))
	_add_polygon("CardFlash", [
		Vector2(-9.0, -14.0),
		Vector2(13.0, -9.0),
		Vector2(9.0, 14.0),
		Vector2(-13.0, 9.0),
	], Color(effect_color.r, effect_color.g, effect_color.b, 0.26), 20)


func _build_energy_surge() -> void:
	_add_line("EnergyBolt", [
		Vector2(-12.0, -36.0),
		Vector2(6.0, -12.0),
		Vector2(-3.0, -8.0),
		Vector2(15.0, 34.0),
	], 6.0, effect_color)
	for index in 4:
		var angle := -PI * 0.25 + float(index) * PI * 0.16
		var direction := Vector2(cos(angle), sin(angle))
		_add_line("EnergyFork%s" % index, [
			direction * 8.0,
			direction * 30.0 + Vector2(0.0, -12.0),
		], 3.0, Color(effect_color.r, effect_color.g, effect_color.b, 0.62))


func _build_heal_burst() -> void:
	_add_ring("HealRing", 29.0, 4.0, effect_color)
	_add_line("HealCrossVertical", [
		Vector2(0.0, -24.0),
		Vector2(0.0, 24.0),
	], 7.0, effect_color)
	_add_line("HealCrossHorizontal", [
		Vector2(-24.0, 0.0),
		Vector2(24.0, 0.0),
	], 7.0, effect_color)
	for index in 6:
		var direction := Vector2(cos(TAU * float(index) / 6.0), sin(TAU * float(index) / 6.0))
		_add_line("HealSpark%s" % index, [direction * 24.0, direction * 40.0], 2.5, Color(effect_color.r, effect_color.g, effect_color.b, 0.58))


func _build_item_spark() -> void:
	_add_polygon("ItemGlint", [
		Vector2(0.0, -36.0),
		Vector2(8.0, -8.0),
		Vector2(36.0, 0.0),
		Vector2(8.0, 8.0),
		Vector2(0.0, 36.0),
		Vector2(-8.0, 8.0),
		Vector2(-36.0, 0.0),
		Vector2(-8.0, -8.0),
	], Color(effect_color.r, effect_color.g, effect_color.b, 0.42))
	for index in 6:
		var direction := Vector2(cos(TAU * float(index) / 6.0), sin(TAU * float(index) / 6.0))
		_add_line("ItemSpark%s" % index, [direction * 10.0, direction * 30.0], 3.0, effect_color)


func _build_skill_spark() -> void:
	for index in SPARK_COUNT:
		var angle := TAU * float(index) / float(SPARK_COUNT)
		var direction := Vector2(cos(angle), sin(angle))
		_add_line("SkillSpark%s" % index, [
			direction * 10.0,
			direction * 34.0,
		], 4.0, effect_color)


func _build_radial_sparks() -> void:
	for index in SPARK_COUNT:
		var angle := TAU * float(index) / float(SPARK_COUNT)
		var direction := Vector2(cos(angle), sin(angle))
		_add_line("Spark%s" % index, [
			direction * 10.0,
			direction * 34.0,
		], 4.0, effect_color)


func _play_animation() -> void:
	if animation_tween != null and animation_tween.is_valid():
		animation_tween.kill()
	scale = Vector2(0.35, 0.35)
	modulate.a = 1.0

	animation_tween = create_tween()
	animation_tween.tween_property(self, "scale", Vector2(1.12, 1.12), EFFECT_TIME * 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation_tween.parallel().tween_property(self, "modulate:a", 0.0, EFFECT_TIME)
	animation_tween.tween_callback(queue_free)


func _add_line(
	node_name: String,
	points: Array[Vector2],
	width: float,
	color: Color,
	z_index_value: int = 21
) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array(points)
	line.z_index = z_index_value
	add_child(line)
	return line


func _add_ring(
	node_name: String,
	radius: float,
	width: float,
	color: Color,
	z_index_value: int = 21
) -> Line2D:
	var ring := Line2D.new()
	ring.name = node_name
	ring.width = width
	ring.default_color = color
	ring.closed = true
	ring.z_index = z_index_value
	for index in RING_SEGMENTS:
		var angle := TAU * float(index) / float(RING_SEGMENTS)
		ring.add_point(Vector2(cos(angle), sin(angle)) * radius)
	add_child(ring)
	return ring


func _add_polygon(
	node_name: String,
	points: Array[Vector2],
	color: Color,
	z_index_value: int = 21
) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array(points)
	polygon.z_index = z_index_value
	add_child(polygon)
	return polygon

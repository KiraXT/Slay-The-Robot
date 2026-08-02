extends Control
class_name IntentAttackIcon

@export var icon_style_id: String = "single_strike":
	set(value):
		icon_style_id = value
		queue_redraw()

@export var accent_color: Color = Color(1.0, 0.22, 0.10, 1.0):
	set(value):
		accent_color = value
		queue_redraw()

@export var blade_color: Color = Color(1.0, 0.92, 0.72, 1.0):
	set(value):
		blade_color = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var rect := Rect2(Vector2.ZERO, size).grow(-1.0)
	var center := rect.get_center()
	var scale := minf(rect.size.x, rect.size.y) / 40.0
	_draw_single_strike(center, scale)


func _draw_single_strike(center: Vector2, scale: float) -> void:
	var white_outline := Color(1.0, 1.0, 1.0, 0.96)
	var dark_outline := Color(0.16, 0.12, 0.10, 1.0)
	var hot_core := Color(1.0, 0.54, 0.10, 1.0)
	var spark := Color(1.0, 0.90, 0.28, 1.0)

	var outer := PackedVector2Array([
		center + Vector2(-14.0, 12.0) * scale,
		center + Vector2(-4.0, -14.0) * scale,
		center + Vector2(16.0, -16.0) * scale,
		center + Vector2(7.0, -3.0) * scale,
		center + Vector2(14.0, 12.0) * scale,
		center + Vector2(-3.0, 5.0) * scale,
	])
	_draw_offset_polygon(outer, Vector2(1.4, 1.8) * scale, Color(0.0, 0.0, 0.0, 0.14))
	draw_colored_polygon(outer, white_outline)

	var outline := _scaled_polygon(center, scale, [
		Vector2(-11.0, 9.0),
		Vector2(-2.5, -10.5),
		Vector2(12.5, -12.5),
		Vector2(4.8, -2.0),
		Vector2(10.5, 8.8),
		Vector2(-2.0, 3.0),
	])
	draw_colored_polygon(outline, dark_outline)

	var body := _scaled_polygon(center, scale, [
		Vector2(-7.5, 6.0),
		Vector2(-0.5, -8.0),
		Vector2(8.5, -9.5),
		Vector2(1.7, -0.8),
		Vector2(6.6, 6.2),
		Vector2(-0.8, 1.8),
	])
	draw_colored_polygon(body, accent_color)

	var highlight := _scaled_polygon(center, scale, [
		Vector2(-2.0, -4.8),
		Vector2(4.4, -7.2),
		Vector2(1.0, -1.0),
		Vector2(4.2, 3.2),
		Vector2(0.2, 0.8),
	])
	draw_colored_polygon(highlight, hot_core)

	draw_line(center + Vector2(-13.0, -8.0) * scale, center + Vector2(-8.0, -13.0) * scale, spark, 2.4 * scale, true)
	draw_line(center + Vector2(12.0, 1.0) * scale, center + Vector2(17.0, -2.0) * scale, spark, 2.2 * scale, true)


func _scaled_polygon(center: Vector2, scale: float, points: Array[Vector2]) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point: Vector2 in points:
		polygon.append(center + point * scale)
	return polygon


func _draw_offset_polygon(points: PackedVector2Array, offset: Vector2, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point: Vector2 in points:
		polygon.append(point + offset)
	draw_colored_polygon(polygon, color)

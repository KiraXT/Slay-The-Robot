extends Control
class_name CombatHudBadge

@export var icon_id: String = "generic":
	set(value):
		icon_id = value
		queue_redraw()

@export var accent_color: Color = Color(0.92, 0.20, 0.13, 1.0):
	set(value):
		accent_color = value
		queue_redraw()

@export var surface_color: Color = Color(0.98, 0.99, 1.0, 0.94):
	set(value):
		surface_color = value
		queue_redraw()

@export var border_color: Color = Color(0.78, 0.84, 0.86, 0.95):
	set(value):
		border_color = value
		queue_redraw()

@export var draw_icon: bool = true:
	set(value):
		draw_icon = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var rect := Rect2(Vector2.ZERO, size)
	_draw_badge(rect)
	if draw_icon:
		_draw_icon(rect.grow(-8.0))


func _draw_badge(rect: Rect2) -> void:
	var radius := minf(rect.size.x, rect.size.y) * 0.22
	_draw_round_rect(rect.position + Vector2(0.0, 2.0), rect.size, radius, Color(0.0, 0.0, 0.0, 0.16))
	_draw_round_rect(rect.position, rect.size, radius, border_color)
	_draw_round_rect(rect.position + Vector2(2.0, 2.0), rect.size - Vector2(4.0, 4.0), maxf(0.0, radius - 2.0), surface_color)
	draw_line(rect.position + Vector2(radius, 4.0), rect.position + Vector2(rect.size.x - radius, 4.0), Color(1.0, 1.0, 1.0, 0.75), 1.2, true)
	draw_circle(rect.position + Vector2(rect.size.x - 7.0, 7.0), 3.0, accent_color)


func _draw_round_rect(position: Vector2, rect_size: Vector2, radius: float, color: Color) -> void:
	radius = minf(radius, minf(rect_size.x, rect_size.y) * 0.5)
	draw_rect(Rect2(position + Vector2(radius, 0.0), Vector2(rect_size.x - radius * 2.0, rect_size.y)), color)
	draw_rect(Rect2(position + Vector2(0.0, radius), Vector2(rect_size.x, rect_size.y - radius * 2.0)), color)
	draw_circle(position + Vector2(radius, radius), radius, color)
	draw_circle(position + Vector2(rect_size.x - radius, radius), radius, color)
	draw_circle(position + Vector2(radius, rect_size.y - radius), radius, color)
	draw_circle(position + Vector2(rect_size.x - radius, rect_size.y - radius), radius, color)


func _draw_icon(rect: Rect2) -> void:
	var center := rect.get_center()
	var scale := minf(rect.size.x, rect.size.y) / 34.0
	var light := accent_color
	var dark := Color(0.18, 0.20, 0.23, 1.0)

	match icon_id:
		"pause":
			_draw_pause(center, scale, light, dark)
		"map":
			_draw_map(center, scale, light, dark)
		"deck":
			_draw_deck(center, scale, light, dark)
		"energy":
			_draw_energy(center, scale, light, dark)
		"draw":
			_draw_draw_pile(center, scale, light, dark)
		"discard":
			_draw_discard(center, scale, light, dark)
		"exhaust":
			_draw_exhaust(center, scale, light, dark)
		"consumable":
			_draw_consumable(center, scale, light, dark)
		_:
			_draw_consumable(center, scale, light, dark)


func _draw_pause(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	for offset_x in [-5.0, 5.0]:
		var rect := Rect2(center + Vector2(offset_x - 3.0, -12.0) * scale, Vector2(6.0, 24.0) * scale)
		draw_rect(rect.grow(1.0 * scale), Color(1.0, 1.0, 1.0, 0.85))
		draw_rect(rect, dark)


func _draw_map(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	var points := [
		center + Vector2(-12.0, 9.0) * scale,
		center + Vector2(-2.0, -10.0) * scale,
		center + Vector2(10.0, 8.0) * scale,
	]
	draw_line(points[0], points[1], dark, 4.0 * scale, true)
	draw_line(points[1], points[2], dark, 4.0 * scale, true)
	draw_line(points[0], points[1], accent_color, 2.2 * scale, true)
	draw_line(points[1], points[2], light, 2.2 * scale, true)
	for point: Vector2 in points:
		draw_circle(point, 3.6 * scale, Color(1.0, 1.0, 1.0, 1.0))
		draw_circle(point, 2.4 * scale, accent_color)


func _draw_deck(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	for i in range(3):
		var offset := Vector2(float(i) * 3.0, float(i) * -3.0) * scale
		var rect := Rect2(center + Vector2(-12.0, -9.0) * scale + offset, Vector2(20.0, 24.0) * scale)
		draw_rect(rect.grow(1.2 * scale), Color(1.0, 1.0, 1.0, 0.95), false, 2.0 * scale)
		draw_rect(rect, dark, false, 1.8 * scale)
	draw_line(center + Vector2(-5.0, 4.0) * scale, center + Vector2(6.0, 4.0) * scale, accent_color, 3.0 * scale, true)


func _draw_energy(center: Vector2, scale: float, _light: Color, dark: Color) -> void:
	var bolt := PackedVector2Array([
		center + Vector2(-3.0, -15.0) * scale,
		center + Vector2(10.0, -3.0) * scale,
		center + Vector2(3.0, -2.0) * scale,
		center + Vector2(8.0, 15.0) * scale,
		center + Vector2(-10.0, -1.0) * scale,
		center + Vector2(-2.0, -2.0) * scale,
	])
	var shadow := PackedVector2Array()
	for point: Vector2 in bolt:
		shadow.append(point + Vector2(1.0, 1.2) * scale)
	draw_colored_polygon(shadow, Color(1.0, 1.0, 1.0, 0.90))
	draw_colored_polygon(bolt, Color(1.0, 0.74, 0.16, 1.0))


func _draw_draw_pile(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	_draw_deck(center + Vector2(-1.0, 1.0) * scale, scale * 0.9, light, dark)
	draw_line(center + Vector2(-8.0, -13.0) * scale, center + Vector2(8.0, -13.0) * scale, accent_color, 3.0 * scale, true)
	draw_line(center + Vector2(8.0, -13.0) * scale, center + Vector2(4.0, -17.0) * scale, accent_color, 3.0 * scale, true)


func _draw_discard(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	draw_line(center + Vector2(0.0, -14.0) * scale, center + Vector2(0.0, 5.0) * scale, dark, 3.6 * scale, true)
	draw_line(center + Vector2(-7.0, -2.0) * scale, center + Vector2(0.0, 6.0) * scale, dark, 3.6 * scale, true)
	draw_line(center + Vector2(7.0, -2.0) * scale, center + Vector2(0.0, 6.0) * scale, dark, 3.6 * scale, true)
	draw_line(center + Vector2(-12.0, 12.0) * scale, center + Vector2(12.0, 12.0) * scale, accent_color, 3.2 * scale, true)


func _draw_exhaust(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	for angle in [0.0, PI / 4.0, PI / 2.0, PI * 3.0 / 4.0]:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(center - dir * 12.0 * scale, center + dir * 12.0 * scale, dark, 2.8 * scale, true)
	draw_circle(center, 4.0 * scale, accent_color)


func _draw_consumable(center: Vector2, scale: float, light: Color, dark: Color) -> void:
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -14.0) * scale,
		center + Vector2(13.0, 0.0) * scale,
		center + Vector2(0.0, 14.0) * scale,
		center + Vector2(-13.0, 0.0) * scale,
	])
	var shadow := PackedVector2Array()
	for point: Vector2 in diamond:
		shadow.append(point + Vector2(1.0, 1.2) * scale)
	draw_colored_polygon(shadow, Color(1.0, 1.0, 1.0, 0.92))
	draw_colored_polygon(diamond, accent_color)
	draw_line(center + Vector2(-6.0, 0.0) * scale, center + Vector2(6.0, 0.0) * scale, Color(1.0, 1.0, 1.0, 1.0), 2.6 * scale, true)
	draw_line(center + Vector2(0.0, -6.0) * scale, center + Vector2(0.0, 6.0) * scale, Color(1.0, 1.0, 1.0, 1.0), 2.6 * scale, true)

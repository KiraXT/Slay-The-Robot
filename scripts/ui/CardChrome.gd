extends Control
class_name CardChrome

var frame_color: Color = Color(0.70, 0.13, 0.13, 1.0)
var accent_color: Color = Color(0.48, 0.08, 0.08, 1.0)
var highlight_color: Color = Color(0.90, 0.33, 0.28, 1.0)
var body_color: Color = Color(0.98, 0.985, 0.99, 1.0)
var panel_color: Color = Color(1.0, 1.0, 1.0, 0.98)
var panel_border_color: Color = Color(0.78, 0.82, 0.86, 1.0)
var art_border_color: Color = Color(0.12, 0.16, 0.21, 0.82)


func set_palette(base_color: Color, edge_color: Color, light_color: Color, card_body_color: Color) -> void:
	frame_color = base_color
	accent_color = edge_color
	highlight_color = light_color
	body_color = card_body_color
	panel_color = Color(1.0, 1.0, 1.0, 0.98)
	panel_border_color = Color(0.77, 0.81, 0.85, 1.0)
	art_border_color = Color(0.12, 0.16, 0.21, 0.82)
	if base_color.get_luminance() > 0.76:
		panel_border_color = edge_color.lightened(0.28)
		art_border_color = edge_color.darkened(0.08)
	queue_redraw()


func _draw() -> void:
	_draw_outer_shell()
	_draw_top_name_plate()
	_draw_art_frame()
	_draw_type_ribbon()
	_draw_effect_panel()


func _draw_outer_shell() -> void:
	var shadow := accent_color.darkened(0.20)
	var outer := [
		Vector2(16, 0),
		Vector2(124, 0),
		Vector2(142, 17),
		Vector2(142, 166),
		Vector2(126, 184),
		Vector2(16, 184),
		Vector2(0, 168),
		Vector2(0, 16),
	]
	var right_edge := [
		Vector2(124, 0),
		Vector2(142, 17),
		Vector2(142, 166),
		Vector2(126, 184),
		Vector2(112, 184),
		Vector2(132, 163),
		Vector2(132, 22),
		Vector2(112, 0),
	]
	var body := [
		Vector2(21, 7),
		Vector2(117, 7),
		Vector2(134, 23),
		Vector2(134, 161),
		Vector2(118, 177),
		Vector2(22, 177),
		Vector2(8, 163),
		Vector2(8, 22),
	]

	_draw_poly(_offset_points(outer, Vector2(3, 3)), Color(0.05, 0.07, 0.09, 0.22))
	_draw_poly(outer, frame_color)
	_draw_poly(right_edge, shadow)
	_draw_poly(body, body_color)
	_draw_polyline(body, panel_border_color.lightened(0.10), 1.2)

	draw_line(Vector2(12, 24), Vector2(12, 160), highlight_color.lightened(0.15), 1.4, true)
	draw_line(Vector2(16, 9), Vector2(110, 9), Color(1, 1, 1, 0.62), 1.0, true)
	draw_line(Vector2(10, 164), Vector2(23, 177), Color(1, 1, 1, 0.58), 1.0, true)


func _draw_top_name_plate() -> void:
	var plate := [
		Vector2(18, 9),
		Vector2(114, 9),
		Vector2(128, 22),
		Vector2(128, 30),
		Vector2(18, 30),
	]
	_draw_poly(plate, Color(1.0, 1.0, 1.0, 0.88))
	_draw_polyline(plate, Color(0.78, 0.82, 0.86, 0.55), 0.9)

	var fold_light := [
		Vector2(114, 8),
		Vector2(130, 20),
		Vector2(130, 33),
		Vector2(114, 21),
	]
	var fold_shadow := [
		Vector2(130, 20),
		Vector2(135, 28),
		Vector2(135, 45),
		Vector2(130, 33),
	]
	_draw_poly(fold_light, Color(0.93, 0.95, 0.96, 0.86))
	_draw_poly(fold_shadow, Color(0.80, 0.83, 0.86, 0.58))


func _draw_art_frame() -> void:
	var border := [
		Vector2(11, 27),
		Vector2(133, 27),
		Vector2(133, 102),
		Vector2(11, 102),
	]
	var inner := [
		Vector2(14, 30),
		Vector2(130, 30),
		Vector2(130, 99),
		Vector2(14, 99),
	]
	_draw_poly(border, art_border_color)
	_draw_poly(inner, panel_color)
	draw_line(Vector2(13, 28), Vector2(34, 28), highlight_color, 1.6, true)
	draw_line(Vector2(132, 80), Vector2(132, 101), highlight_color, 1.4, true)
	draw_line(Vector2(112, 101), Vector2(132, 101), highlight_color, 1.4, true)


func _draw_type_ribbon() -> void:
	var shadow := [
		Vector2(24, 98),
		Vector2(120, 98),
		Vector2(133, 106),
		Vector2(120, 116),
		Vector2(24, 116),
		Vector2(11, 106),
	]
	var ribbon := [
		Vector2(25, 96),
		Vector2(119, 96),
		Vector2(131, 106),
		Vector2(119, 116),
		Vector2(25, 116),
		Vector2(13, 106),
	]
	_draw_poly(shadow, accent_color.darkened(0.18))
	_draw_poly(ribbon, frame_color.darkened(0.06))
	draw_line(Vector2(30, 98), Vector2(114, 98), highlight_color.lightened(0.14), 1.0, true)
	draw_line(Vector2(27, 115), Vector2(117, 115), accent_color.darkened(0.20), 1.0, true)


func _draw_effect_panel() -> void:
	var frame := [
		Vector2(8, 105),
		Vector2(136, 105),
		Vector2(136, 174),
		Vector2(130, 180),
		Vector2(14, 180),
		Vector2(8, 174),
	]
	var fill := [
		Vector2(10, 107),
		Vector2(134, 107),
		Vector2(134, 172),
		Vector2(128, 178),
		Vector2(16, 178),
		Vector2(10, 172),
	]
	_draw_poly(frame, panel_border_color)
	_draw_poly(fill, panel_color)
	draw_line(Vector2(15, 107), Vector2(130, 107), Color(1, 1, 1, 0.72), 1.0, true)
	_draw_circuit_pattern()


func _draw_circuit_pattern() -> void:
	var pattern_color := highlight_color.lightened(0.28)
	pattern_color.a = 0.13
	for i in range(0, 5):
		var y := 118.0 + float(i) * 9.0
		var x := 97.0 + float(i % 2) * 6.0
		draw_line(Vector2(x, y), Vector2(x + 9, y), pattern_color, 1.0, true)
		draw_line(Vector2(x + 9, y), Vector2(x + 9, y + 4), pattern_color, 1.0, true)
		draw_line(Vector2(x + 9, y + 4), Vector2(x + 19, y + 4), pattern_color, 1.0, true)


func _draw_poly(points: Array, color: Color) -> void:
	var packed_points := PackedVector2Array()
	var colors := PackedColorArray()
	for point in points:
		packed_points.append(point)
		colors.append(color)
	draw_polygon(packed_points, colors)


func _draw_polyline(points: Array, color: Color, width: float) -> void:
	var packed_points := PackedVector2Array()
	for point in points:
		packed_points.append(point)
	if points.size() > 0:
		packed_points.append(points[0])
	draw_polyline(packed_points, color, width, true)


func _offset_points(points: Array, offset: Vector2) -> Array:
	var shifted := []
	for point in points:
		shifted.append(point + offset)
	return shifted

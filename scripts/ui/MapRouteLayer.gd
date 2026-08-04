extends Control
class_name MapRouteLayer

const DASH_LENGTH := 10.0
const GAP_LENGTH := 8.0
const ROUTE_GLOW_WIDTH := 10.0
const ROUTE_CORE_WIDTH := 4.0
const ROUTE_CURVE_SEGMENTS := 12
const ROUTE_MIN_BEND := 8.0
const ROUTE_MAX_BEND := 20.0
const ROUTE_GLOW_COLOR := Color(0.28, 0.78, 1.0, 0.28)
const ROUTE_CORE_COLOR := Color(0.96, 1.0, 1.0, 0.88)
const ROUTE_NODE_COLOR := Color(0.42, 0.88, 1.0, 0.55)

var route_segments: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_route_segments(segments: Array[Dictionary]) -> void:
	route_segments = segments
	queue_redraw()


func _draw() -> void:
	for segment in route_segments:
		var from_position: Vector2 = segment.get("from", Vector2.ZERO)
		var to_position: Vector2 = segment.get("to", Vector2.ZERO)
		var route_points := get_route_points(from_position, to_position)
		_draw_dashed_path(route_points, ROUTE_GLOW_COLOR, ROUTE_GLOW_WIDTH)
		_draw_dashed_path(route_points, ROUTE_CORE_COLOR, ROUTE_CORE_WIDTH)
		draw_circle(from_position, 5.0, ROUTE_NODE_COLOR)
		draw_circle(to_position, 5.0, ROUTE_NODE_COLOR)


func get_route_points(from_position: Vector2, to_position: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var control_point := _get_route_control_point(from_position, to_position)
	for index in range(ROUTE_CURVE_SEGMENTS + 1):
		var t := float(index) / float(ROUTE_CURVE_SEGMENTS)
		points.append(_quadratic_bezier(from_position, control_point, to_position, t))
	return points


func _get_route_control_point(from_position: Vector2, to_position: Vector2) -> Vector2:
	var delta := to_position - from_position
	if delta.length() <= 0.0:
		return from_position
	var normal := Vector2(-delta.y, delta.x).normalized()
	var hash_value := int(abs(from_position.x * 13.0 + from_position.y * 7.0 + to_position.x * 5.0 + to_position.y * 3.0))
	var bend_sign := -1.0 if hash_value % 2 == 0 else 1.0
	var bend_amount: float = clamp(abs(delta.x) * 0.08 + ROUTE_MIN_BEND, ROUTE_MIN_BEND, ROUTE_MAX_BEND)
	return from_position.lerp(to_position, 0.5) + (normal * bend_sign * bend_amount)


func _quadratic_bezier(from_position: Vector2, control_position: Vector2, to_position: Vector2, t: float) -> Vector2:
	var inverse_t := 1.0 - t
	return (inverse_t * inverse_t * from_position) + (2.0 * inverse_t * t * control_position) + (t * t * to_position)


func _draw_dashed_path(points: Array[Vector2], color: Color, width: float) -> void:
	if points.size() < 2:
		return

	var draw_dash := true
	var remaining_pattern_length := DASH_LENGTH
	for point_index in range(points.size() - 1):
		var segment_start := points[point_index]
		var segment_end := points[point_index + 1]
		var delta := segment_end - segment_start
		var segment_length := delta.length()
		if segment_length <= 0.0:
			continue

		var direction := delta / segment_length
		var consumed := 0.0
		while consumed < segment_length:
			var step: float = min(remaining_pattern_length, segment_length - consumed)
			if draw_dash:
				draw_line(
					segment_start + (direction * consumed),
					segment_start + (direction * (consumed + step)),
					color,
					width,
					true
				)
			consumed += step
			remaining_pattern_length -= step
			if remaining_pattern_length <= 0.001:
				draw_dash = not draw_dash
				remaining_pattern_length = DASH_LENGTH if draw_dash else GAP_LENGTH

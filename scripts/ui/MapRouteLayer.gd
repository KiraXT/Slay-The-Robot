extends Control
class_name MapRouteLayer

const DASH_LENGTH := 10.0
const GAP_LENGTH := 8.0
const ROUTE_GLOW_WIDTH := 10.0
const ROUTE_CORE_WIDTH := 4.0
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
		_draw_dashed_route(from_position, to_position, ROUTE_GLOW_COLOR, ROUTE_GLOW_WIDTH)
		_draw_dashed_route(from_position, to_position, ROUTE_CORE_COLOR, ROUTE_CORE_WIDTH)
		draw_circle(from_position, 5.0, ROUTE_NODE_COLOR)
		draw_circle(to_position, 5.0, ROUTE_NODE_COLOR)


func _draw_dashed_route(from_position: Vector2, to_position: Vector2, color: Color, width: float) -> void:
	var delta: Vector2 = to_position - from_position
	var route_length: float = delta.length()
	if route_length <= 0.0:
		return

	var direction: Vector2 = delta / route_length
	var distance: float = 0.0
	while distance < route_length:
		var dash_end_distance: float = min(distance + DASH_LENGTH, route_length)
		draw_line(
			from_position + (direction * distance),
			from_position + (direction * dash_end_distance),
			color,
			width,
			true
		)
		distance += DASH_LENGTH + GAP_LENGTH

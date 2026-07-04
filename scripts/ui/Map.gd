extends Control

const MAP_ROUTE_LAYER_SCRIPT := preload("res://scripts/ui/MapRouteLayer.gd")

@onready var scroll_container = $ScrollContainer
@onready var location_container = $ScrollContainer/LocationContainer
@onready var back_button: Button = $BackButton
@onready var background_panel: ColorRect = $Background2

@onready var map_button = %MapButton

var can_travel: bool = false	# if clicking on a location brings you to the next location
var legend_panel: VBoxContainer = null

## Adds a margin to the bottom of the map display
const MAP_Y_MARGIN: float = 150
const MAP_SCROLL_POSITION := Vector2(96, 72)
const MAP_SCROLL_SIZE := Vector2(834, 584)
const MAP_LEGEND_POSITION := Vector2(960, 88)
const MAP_LEGEND_SIZE := Vector2(188, 524)
const MAP_BACK_BUTTON_POSITION := Vector2(32, 32)
const MAP_BACK_BUTTON_SIZE := Vector2(96, 32)
const MAP_BACKGROUND_PANEL_OFFSET_LEFT: float = -504
const MAP_BACKGROUND_PANEL_OFFSET_RIGHT: float = 548
const MAP_LOCATION_CENTER_OFFSET := Vector2(40, 40)
const ROUTE_LAYER_NAME := "RouteLayer"

const MAP_LEGEND_ENTRIES := [
	{"type": LocationData.LOCATION_TYPES.COMBAT, "label": "基础战斗"},
	{"type": LocationData.LOCATION_TYPES.EVENT, "label": "神秘事件"},
	{"type": LocationData.LOCATION_TYPES.SHOP, "label": "商店"},
	{"type": LocationData.LOCATION_TYPES.MINIBOSS, "label": "小型 BOSS"},
	{"type": LocationData.LOCATION_TYPES.BOSS, "label": "大型 BOSS"},
	{"type": LocationData.LOCATION_TYPES.TREASURE, "label": "宝箱"},
	{"type": LocationData.LOCATION_TYPES.REST_SITE, "label": "篝火"},
]

func _ready():
	_configure_map_layout()
	_ensure_legend_panel()
	_populate_legend_panel()
	
	map_button.button_up.connect(_on_map_button_up)
	back_button.button_up.connect(_on_back_button_up)
	
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	
	Signals.dialogue_ended.connect(_on_dialogue_ended)
	
	Signals.chest_opened.connect(_on_chest_opened)
	Signals.shop_opened.connect(_on_shop_opened)
	
	Signals.map_location_selected.connect(_on_map_location_selected)
		

func _configure_map_layout() -> void:
	scroll_container.position = MAP_SCROLL_POSITION
	scroll_container.size = MAP_SCROLL_SIZE
	back_button.position = MAP_BACK_BUTTON_POSITION
	back_button.size = MAP_BACK_BUTTON_SIZE
	background_panel.offset_left = MAP_BACKGROUND_PANEL_OFFSET_LEFT
	background_panel.offset_right = MAP_BACKGROUND_PANEL_OFFSET_RIGHT


func _ensure_legend_panel() -> void:
	legend_panel = get_node_or_null("LegendPanel") as VBoxContainer
	if legend_panel == null:
		legend_panel = VBoxContainer.new()
		legend_panel.name = "LegendPanel"
		add_child(legend_panel)
	
	legend_panel.position = MAP_LEGEND_POSITION
	legend_panel.size = MAP_LEGEND_SIZE
	legend_panel.custom_minimum_size = MAP_LEGEND_SIZE
	legend_panel.add_theme_constant_override("separation", 8)


func _populate_legend_panel() -> void:
	for child in legend_panel.get_children():
		child.queue_free()
	
	for entry: Dictionary in MAP_LEGEND_ENTRIES:
		var row := HBoxContainer.new()
		row.name = "%sLegend" % str(entry["label"])
		row.custom_minimum_size = Vector2(MAP_LEGEND_SIZE.x, 64)
		row.add_theme_constant_override("separation", 8)
		legend_panel.add_child(row)
		
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		
		var label := Label.new()
		label.name = "NameLabel"
		label.text = entry["label"]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		
		var location_data := LocationData.new()
		location_data.location_type = entry["type"]
		icon.texture = FileLoader.load_texture(MapLocation.get_location_texture_path(location_data))


func populate_locations(locations: Array[LocationData] = Global.get_all_act_locations()):
	clear_locations()
	
	var next_locations: Array[LocationData] = Global.get_next_locations()
	var max_y: float = 0.0 # the highest location position, used to determine container size
	var max_x: float = MAP_SCROLL_SIZE.x
	var route_segments := _build_route_segments(locations)
	var route_layer = MAP_ROUTE_LAYER_SCRIPT.new()
	route_layer.name = ROUTE_LAYER_NAME
	route_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location_container.add_child(route_layer)
	
	var current_map_location: MapLocation = null
	
	for location_data in locations:
		var map_location: MapLocation = Scenes.MAP_LOCATION.instantiate()
		location_container.add_child(map_location)
		map_location.init(location_data)
		
		map_location.map_location_button_up.connect(_on_map_location_button_up)
		
		max_y = max(max_y, location_data.location_position.y)
		max_x = max(max_x, location_data.location_position.x + MAP_LOCATION_CENTER_OFFSET.x + MAP_Y_MARGIN)
		
		# flash the locations the player can travel to
		if can_travel:
			if next_locations.has(location_data):
				map_location.flash_location()
				current_map_location = map_location
		
		#if location_data == Global.get_player_location_data():
			#current_map_location = map_location
	
	# set the size of the container to make scrolling posible
	var container_size := Vector2(max_x, max_y + MAP_Y_MARGIN)
	location_container.custom_minimum_size = container_size
	location_container.size = container_size
	route_layer.size = container_size
	route_layer.set_route_segments(route_segments)
	
	# wait a frame to ensure container is properly resized
	await Global.get_tree().process_frame
	# set the scroll
	if current_map_location != null:
		current_map_location.grab_focus()
	else:
		# presumably the invisible starting location, set to bottom
		scroll_container.scroll_vertical = max_y
	

func clear_locations() -> void:
	for child in location_container.get_children():
		location_container.remove_child(child)
		child.queue_free()


func _build_route_segments(locations: Array[LocationData]) -> Array[Dictionary]:
	var locations_by_id := {}
	for location_data in locations:
		locations_by_id[location_data.location_id] = location_data

	var route_segments: Array[Dictionary] = []
	for location_data in locations:
		for next_location_id in location_data.location_next_location_ids:
			var next_location: LocationData = locations_by_id.get(next_location_id)
			if next_location == null:
				continue
			route_segments.append({
				"from": location_data.location_position + MAP_LOCATION_CENTER_OFFSET,
				"to": next_location.location_position + MAP_LOCATION_CENTER_OFFSET,
			})
	return route_segments

func show_map():
	populate_locations()
	visible = true

func hide_map():
	visible = false

func _on_map_button_up():
	show_map()

func _on_map_location_button_up(map_location: MapLocation):
	# map must be in travel mode
	if can_travel:
		# must be adjacent to player location
		if Global.get_next_locations().has(map_location.location_data):
			# visit the location
			ActionGenerator.generate_visit_location(map_location.location_data.location_id)
	
func _on_map_location_selected(location_data: LocationData):
	# disable travel mode
	can_travel = false
	hide_map()

func _on_combat_started(_event_id: String):
	can_travel = false

func _on_combat_ended():
	can_travel = true

func _on_chest_opened():
	can_travel = true

func _on_shop_opened():
	can_travel = true

func _on_dialogue_ended():
	var player: Player = Global.get_player()
	if player.is_alive():
		can_travel = true
		show_map()
	else:
		hide_map()

func _on_back_button_up():
	hide_map()
	get_combined_minimum_size()

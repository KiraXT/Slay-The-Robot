## UI component for a selectable option. Used for run start options and dialogue options.
## Supports rich text.
extends Button
class_name DialogueOption

@onready var rich_text_label = $RichTextLabel

const NORMAL_MODULATE := Color(1, 1, 1, 1)
const HOVER_MODULATE := Color(1.04, 1.04, 1.04, 1)
const PRESSED_MODULATE := Color(0.92, 0.96, 0.96, 1)
const NORMAL_SCALE := Vector2.ONE
const PRESSED_SCALE := Vector2(0.985, 0.985)

## The dialogue option this button represents. Run start option buttons will have this as empty.
var dialogue_option_object_id: String = ""

var action_data: Array[Dictionary] = []
var validators: Array[Dictionary] = []
var option_enabled: bool = false
var is_hovered := false
var feedback_tween: Tween

signal dialogue_option_clicked(dialogue_option: DialogueOption)

func _ready():
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func init(_dialogue_option_object_id: String, option_bbcode: String, option_failed_validator_bbcode: String, _action_data: Array[Dictionary], _validators: Array[Dictionary]) -> void:
	dialogue_option_object_id = _dialogue_option_object_id
	action_data = _action_data
	validators = _validators
	option_enabled = validate_dialogue_option()
	if option_enabled:
		set_dialogue_bb_code(option_bbcode)
		disabled = false
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		set_dialogue_bb_code(option_failed_validator_bbcode)
		disabled = true
		mouse_default_cursor_shape = Control.CURSOR_ARROW

func validate_dialogue_option() -> bool:
	# checks if option passes all validators
	var game_global := get_node_or_null("/root/Global")
	if game_global == null:
		return validators.is_empty()
	return game_global.validate(validators, null, null)

func set_dialogue_bb_code(bb_code: String) -> void:
	rich_text_label.parse_bbcode(bb_code)

func _on_button_down() -> void:
	if option_enabled:
		_play_pressed_feedback()


func _on_button_up() -> void:
	if option_enabled:
		dialogue_option_clicked.emit(self)


func _on_mouse_entered() -> void:
	is_hovered = true
	if option_enabled:
		_play_hover_feedback()


func _on_mouse_exited() -> void:
	is_hovered = false
	_play_normal_feedback()


func _play_hover_feedback() -> void:
	_tween_feedback(NORMAL_SCALE, HOVER_MODULATE, 0.08)


func _play_pressed_feedback() -> void:
	_tween_feedback(PRESSED_SCALE, PRESSED_MODULATE, 0.05)
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_interval(0.05)
		tween.tween_callback(func() -> void:
			if is_instance_valid(self):
				_tween_feedback(NORMAL_SCALE, HOVER_MODULATE if is_hovered else NORMAL_MODULATE, 0.08)
		)


func _play_normal_feedback() -> void:
	_tween_feedback(NORMAL_SCALE, NORMAL_MODULATE, 0.08)


func _tween_feedback(target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
	scale = target_scale
	self_modulate = target_modulate
	if duration <= 0.0:
		return
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "scale", target_scale, duration)
	feedback_tween.parallel().tween_property(self, "self_modulate", target_modulate, duration)

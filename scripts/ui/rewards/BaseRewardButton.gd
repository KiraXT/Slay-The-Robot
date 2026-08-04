extends Button
class_name BaseRewardButton

var action_on_click: BaseAction = null
var actions_on_click: Array[BaseAction] = []
var reward_group: int = 0

func _ready():
	button_up.connect(_on_button_up)

func init(_action_on_click, _reward_group: int) -> void:
	actions_on_click.clear()
	action_on_click = null
	if _action_on_click is Array:
		actions_on_click.assign(_action_on_click)
		if not actions_on_click.is_empty():
			action_on_click = actions_on_click[0]
	else:
		action_on_click = _action_on_click
	reward_group = _reward_group

func _on_button_up():
	if not actions_on_click.is_empty():
		ActionHandler.add_actions(actions_on_click)
	elif action_on_click != null:
		ActionHandler.add_action(action_on_click)
	queue_free()

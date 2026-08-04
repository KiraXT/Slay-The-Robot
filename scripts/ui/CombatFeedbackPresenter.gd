extends Node
class_name CombatFeedbackPresenter

const CARD_PRESENTATION_RESOLVER_SCRIPT := preload("res://scripts/ui/CardPresentationResolver.gd")
const CARD_IMPACT_VFX_SCENE := preload("res://scenes/ui/vfx/CardImpactVFX.tscn")
const COMBAT_FEEDBACK_SFX_LIBRARY_SCRIPT := preload("res://scripts/ui/CombatFeedbackSfxLibrary.gd")

const DAMAGE_FLASH_COLOR := Color(1.0, 0.55, 0.45, 1.0)
const BLOCK_FLASH_COLOR := Color(0.35, 0.82, 1.0, 1.0)
const BLOCK_BREAK_COLOR := Color(1.0, 0.80, 0.25, 1.0)
const STATUS_FLASH_COLOR := Color(0.78, 0.58, 1.0, 1.0)
const ENERGY_FLASH_COLOR := Color(0.35, 0.88, 1.0, 1.0)
const PILE_FLASH_COLOR := Color(1.0, 0.95, 0.45, 1.0)

const QUICK_FLASH_TIME := 0.08
const SETTLE_TIME := 0.14
const SHAKE_STEP_TIME := 0.035
const HIT_PAUSE_TIME_SCALE := 0.08
const IMPACT_VFX_TIME := 0.22

var combat: Control
var hand: Control
var player: BaseCombatant
var energy_button: CanvasItem
var draw_pile_button: CanvasItem
var discard_pile_button: CanvasItem
var exhaust_pile_button: CanvasItem
var audio_player: AudioStreamPlayer
var sound_id_to_stream: Dictionary[String, AudioStream] = {}
var presentation_resolver: RefCounted = CARD_PRESENTATION_RESOLVER_SCRIPT.new()

var _active_tweens: Dictionary = {}
var _original_scales: Dictionary = {}
var _original_positions: Dictionary = {}
var _original_modulates: Dictionary = {}
var _active_card_play_request: CardPlayRequest = null
var _hit_pause_active := false
var _hit_pause_generation := 0
var _hit_pause_restore_time_scale := 1.0


func init(
	_combat: Control,
	_hand: Control,
	_player: BaseCombatant,
	_energy_button: CanvasItem,
	_draw_pile_button: CanvasItem,
	_discard_pile_button: CanvasItem,
	_exhaust_pile_button: CanvasItem
) -> void:
	combat = _combat
	hand = _hand
	player = _player
	energy_button = _energy_button
	draw_pile_button = _draw_pile_button
	discard_pile_button = _discard_pile_button
	exhaust_pile_button = _exhaust_pile_button

	audio_player = AudioStreamPlayer.new()
	audio_player.name = "CombatFeedbackAudio"
	add_child(audio_player)
	var sfx_library: RefCounted = COMBAT_FEEDBACK_SFX_LIBRARY_SCRIPT.new()
	sfx_library.register_default_sfx(self)

	Signals.card_play_started.connect(play_card_started_feedback)
	Signals.card_played.connect(_on_card_played)
	Signals.card_energy_spent.connect(play_energy_feedback)
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.card_added_to_draw.connect(_on_card_added_to_draw)
	Signals.card_moved_to_pile.connect(_on_card_moved_to_pile)
	Signals.energy_added.connect(_on_energy_added)

	Signals.combatant_damaged.connect(play_damage_feedback)
	Signals.combatant_block_added.connect(play_block_gain_feedback)
	Signals.combatant_blocked.connect(play_block_hit_feedback)
	Signals.combatant_block_broken.connect(play_block_break_feedback)
	Signals.combatant_status_applied.connect(play_status_feedback)


func play_damage_feedback(base_combatant: BaseCombatant, _unblocked_damage: int) -> void:
	if not _is_feedback_target_valid(base_combatant):
		return
	_flash_canvas_item(base_combatant.sprite, DAMAGE_FLASH_COLOR)
	_shake_node(base_combatant.sprite, Vector2(10.0, 0.0), 3)
	_pulse_node(base_combatant.layered_health_bar, 1.05)
	_apply_configured_impact_feedback(base_combatant)
	_play_sfx("impact_damage")


func play_block_gain_feedback(base_combatant: BaseCombatant) -> void:
	if not _is_feedback_target_valid(base_combatant):
		return
	_flash_canvas_item(base_combatant.block, BLOCK_FLASH_COLOR)
	_pulse_node(base_combatant.block, 1.22)
	_play_sfx("block_gain")


func play_block_hit_feedback(base_combatant: BaseCombatant, _damage_blocked: int) -> void:
	if not _is_feedback_target_valid(base_combatant):
		return
	_flash_canvas_item(base_combatant.block, BLOCK_FLASH_COLOR)
	_shake_node(base_combatant.block, Vector2(7.0, 0.0), 3)
	_play_sfx("block_hit")


func play_block_break_feedback(base_combatant: BaseCombatant) -> void:
	if not _is_feedback_target_valid(base_combatant):
		return
	_flash_canvas_item(base_combatant.sprite, BLOCK_BREAK_COLOR)
	_shake_node(base_combatant.sprite, Vector2(12.0, 0.0), 4)
	_play_sfx("block_break")


func play_status_feedback(
	base_combatant: BaseCombatant,
	_status_effect_object_id: String,
	_charge_amount: int,
	_secondary_charge_amount: int
) -> void:
	if not _is_feedback_target_valid(base_combatant):
		return
	_flash_canvas_item(base_combatant.status_container, STATUS_FLASH_COLOR)
	_pulse_node(base_combatant.status_container, 1.16)
	_apply_configured_impact_feedback(base_combatant)
	_play_sfx("status_apply")


func play_energy_feedback(_card_play_request = null, _energy_amount: int = 0) -> void:
	if _energy_amount <= 0:
		return
	if not is_instance_valid(energy_button):
		return
	_flash_canvas_item(energy_button, ENERGY_FLASH_COLOR)
	_pulse_node(energy_button, 1.14)
	_play_sfx("energy_change")


func play_pile_feedback(pile_name: String) -> void:
	var target: CanvasItem = null
	match pile_name:
		"draw":
			target = draw_pile_button
		"discard":
			target = discard_pile_button
		"exhaust":
			target = exhaust_pile_button

	if not is_instance_valid(target):
		return
	_flash_canvas_item(target, PILE_FLASH_COLOR)
	_pulse_node(target, 1.10)
	_play_sfx("pile_%s" % pile_name)


func play_card_started_feedback(card_play_request: CardPlayRequest) -> void:
	_active_card_play_request = card_play_request
	if card_play_request == null or card_play_request.card_data == null:
		return
	if is_instance_valid(player):
		_pulse_node(player.sprite, _get_card_start_pulse_scale(card_play_request.card_data))
	_play_sfx(_get_card_play_sfx(card_play_request.card_data))


func _on_card_played(card_play_request: CardPlayRequest) -> void:
	if _active_card_play_request == card_play_request:
		_active_card_play_request = null


func _on_card_drawn(_card_data: CardData) -> void:
	play_pile_feedback("draw")


func _on_card_added_to_draw(_card_data: CardData) -> void:
	play_pile_feedback("draw")


func _on_card_moved_to_pile(_card_data: CardData, pile_name: String) -> void:
	play_pile_feedback(pile_name)


func _on_energy_added(energy_amount: int) -> void:
	play_energy_feedback(null, energy_amount)


func register_sfx_stream(sound_id: String, stream: AudioStream) -> void:
	if sound_id == "" or stream == null:
		return
	sound_id_to_stream[sound_id] = stream


func _get_active_card_data() -> CardData:
	if _active_card_play_request == null:
		return null
	return _active_card_play_request.card_data


func _apply_configured_impact_feedback(base_combatant: BaseCombatant) -> void:
	var card_data := _get_active_card_data()
	if card_data == null:
		return

	var card_impact_vfx := _get_card_impact_vfx(card_data)
	var card_screen_shake := _get_card_screen_shake(card_data)
	var card_hit_pause := _get_card_hit_pause(card_data)
	if card_impact_vfx != "":
		_play_impact_vfx(base_combatant, card_impact_vfx)
	if card_screen_shake != "":
		_apply_screen_shake(card_screen_shake)
	if card_hit_pause > 0.0:
		_apply_hit_pause(card_hit_pause)


func _get_card_impact_vfx(card_data: CardData) -> String:
	return presentation_resolver.get_card_impact_vfx(card_data)


func _get_card_screen_shake(card_data: CardData) -> String:
	return presentation_resolver.get_card_screen_shake(card_data)


func _get_card_hit_pause(card_data: CardData) -> float:
	return presentation_resolver.get_card_hit_pause(card_data)


func _apply_screen_shake(preset: String) -> void:
	if preset == "" or not is_instance_valid(combat):
		return

	var normalized := preset.to_lower()
	if normalized == "none":
		return

	var offset := Vector2(5.0, 0.0)
	var steps := 3
	match normalized:
		"medium":
			offset = Vector2(9.0, 0.0)
			steps = 4
		"large", "heavy":
			offset = Vector2(14.0, 0.0)
			steps = 5
		_:
			if normalized.is_valid_float():
				offset = Vector2(max(0.0, normalized.to_float()), 0.0)
				steps = 4

	_shake_node(combat, offset, steps)


func _apply_hit_pause(duration: float) -> void:
	if duration <= 0.0 or not is_inside_tree():
		return

	_hit_pause_generation += 1
	var generation := _hit_pause_generation
	if not _hit_pause_active:
		_hit_pause_restore_time_scale = Engine.time_scale
	_hit_pause_active = true
	Engine.time_scale = min(_hit_pause_restore_time_scale, HIT_PAUSE_TIME_SCALE)

	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_restore_hit_pause.bind(generation), CONNECT_ONE_SHOT)


func _restore_hit_pause(generation: int) -> void:
	if generation != _hit_pause_generation:
		return
	Engine.time_scale = _hit_pause_restore_time_scale
	_hit_pause_active = false


func _play_impact_vfx(base_combatant: BaseCombatant, effect_id: String) -> void:
	if effect_id == "" or not is_instance_valid(base_combatant) or not is_instance_valid(base_combatant.fade_container):
		return

	var impact_vfx := CARD_IMPACT_VFX_SCENE.instantiate()
	if impact_vfx == null or not impact_vfx.has_method("init"):
		_play_fallback_impact_vfx(base_combatant, effect_id)
		return

	impact_vfx.name = "CardImpactVFX_%s" % effect_id
	impact_vfx.z_index = 20
	base_combatant.fade_container.add_child(impact_vfx)
	impact_vfx.init(effect_id, presentation_resolver.get_impact_vfx_color(effect_id))


func _play_fallback_impact_vfx(base_combatant: BaseCombatant, effect_id: String) -> void:
	if effect_id == "" or not is_instance_valid(base_combatant) or not is_instance_valid(base_combatant.fade_container):
		return

	var burst := Polygon2D.new()
	burst.name = "CardImpactVFX_%s" % effect_id
	burst.polygon = PackedVector2Array([
		Vector2(0.0, -34.0),
		Vector2(10.0, -10.0),
		Vector2(34.0, 0.0),
		Vector2(10.0, 10.0),
		Vector2(0.0, 34.0),
		Vector2(-10.0, 10.0),
		Vector2(-34.0, 0.0),
		Vector2(-10.0, -10.0),
	])
	burst.color = _get_impact_vfx_color(effect_id)
	burst.z_index = 20
	burst.scale = Vector2(0.25, 0.25)
	base_combatant.fade_container.add_child(burst)

	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2(1.15, 1.15), QUICK_FLASH_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, IMPACT_VFX_TIME)
	tween.tween_callback(burst.queue_free)


func _get_impact_vfx_color(effect_id: String) -> Color:
	return presentation_resolver.get_impact_vfx_color(effect_id)


func _get_card_start_pulse_scale(card_data: CardData) -> float:
	match _get_card_visual_profile(card_data):
		"attack":
			return 1.05
		"power":
			return 1.12
		_:
			return 1.08


func _get_card_play_sfx(card_data: CardData) -> String:
	return presentation_resolver.get_card_play_sfx(card_data)


func _get_card_visual_profile(card_data: CardData) -> String:
	return presentation_resolver.get_card_visual_profile(card_data)


func _is_feedback_target_valid(base_combatant: BaseCombatant) -> bool:
	return is_instance_valid(base_combatant) and is_instance_valid(base_combatant.sprite)


func _pulse_node(node: Node, target_scale: float) -> void:
	if not is_instance_valid(node):
		return
	var original_scale: Variant = _get_original_scale(node)
	if not original_scale is Vector2:
		return

	_kill_tween(node, "scale")
	var tween := create_tween()
	_active_tweens[_tween_key(node, "scale")] = tween
	tween.tween_property(node, "scale", original_scale * target_scale, QUICK_FLASH_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original_scale, SETTLE_TIME).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _flash_canvas_item(item: CanvasItem, color: Color) -> void:
	if not is_instance_valid(item):
		return
	var original_modulate := _get_original_modulate(item)
	_kill_tween(item, "modulate")
	var tween := create_tween()
	_active_tweens[_tween_key(item, "modulate")] = tween
	tween.tween_property(item, "modulate", color, QUICK_FLASH_TIME)
	tween.tween_property(item, "modulate", original_modulate, SETTLE_TIME)


func _shake_node(node: Node, offset: Vector2, steps: int) -> void:
	if not is_instance_valid(node):
		return
	var original_position: Variant = _get_original_position(node)
	if not original_position is Vector2:
		return

	_kill_tween(node, "position")
	var tween := create_tween()
	_active_tweens[_tween_key(node, "position")] = tween
	for index in steps:
		var direction := 1.0 if index % 2 == 0 else -1.0
		tween.tween_property(node, "position", original_position + offset * direction, SHAKE_STEP_TIME)
	tween.tween_property(node, "position", original_position, SHAKE_STEP_TIME)


func _get_original_scale(node: Node) -> Variant:
	var key := node.get_instance_id()
	if not _original_scales.has(key):
		_original_scales[key] = node.get("scale")
	return _original_scales[key]


func _get_original_position(node: Node) -> Variant:
	var key := node.get_instance_id()
	if not _original_positions.has(key):
		_original_positions[key] = node.get("position")
	return _original_positions[key]


func _get_original_modulate(item: CanvasItem) -> Color:
	var key := item.get_instance_id()
	if not _original_modulates.has(key):
		_original_modulates[key] = item.modulate
	return _original_modulates[key]


func _kill_tween(node: Node, property_key: String) -> void:
	var key := _tween_key(node, property_key)
	var tween: Tween = _active_tweens.get(key, null)
	if tween != null and tween.is_valid():
		tween.kill()
	_active_tweens.erase(key)


func _tween_key(node: Node, property_key: String) -> String:
	return "%s:%s" % [node.get_instance_id(), property_key]


func _play_sfx(_sound_id: String) -> void:
	if audio_player == null:
		return
	var stream: AudioStream = sound_id_to_stream.get(_sound_id, null)
	if stream == null:
		return
	audio_player.stream = stream
	audio_player.play()

extends Control
class_name CombatFeedbackPreview

const CARD_IMPACT_VFX_SCENE := preload("res://scenes/ui/vfx/CardImpactVFX.tscn")
const CARD_PRESENTATION_RESOLVER_SCRIPT := preload("res://scripts/ui/CardPresentationResolver.gd")
const COMBAT_FEEDBACK_SFX_LIBRARY_SCRIPT := preload("res://scripts/ui/CombatFeedbackSfxLibrary.gd")

const VFX_IDS := [
	"impact_slash",
	"impact_heavy",
	"status_burst",
	"guard_burst",
	"power_aura",
	"card_flow",
	"energy_surge",
	"heal_burst",
	"item_spark",
	"skill_spark",
]
const SFX_IDS := [
	"card_attack",
	"card_attack_heavy",
	"card_skill",
	"card_skill_draw",
	"card_skill_guard",
	"card_skill_heal",
	"card_skill_item",
	"card_status",
	"card_status_heavy",
	"card_power",
	"card_energy",
	"impact_damage",
	"block_gain",
	"block_hit",
	"block_break",
	"status_apply",
	"energy_change",
	"pile_draw",
	"pile_discard",
	"pile_exhaust",
]

var presentation_resolver: RefCounted = CARD_PRESENTATION_RESOLVER_SCRIPT.new()
var sfx_library: RefCounted = COMBAT_FEEDBACK_SFX_LIBRARY_SCRIPT.new()
var audio_player: AudioStreamPlayer
var vfx_anchor: Node2D
var active_vfx: Node2D = null
var sound_id_to_stream: Dictionary[String, AudioStream] = {}


func _ready() -> void:
	_build_preview_ui()
	_load_sfx_streams()
	_update_vfx_anchor_position()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_vfx_anchor_position()


func _build_preview_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.075, 0.086, 0.10, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := HBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 24.0
	layout.offset_top = 24.0
	layout.offset_right = -24.0
	layout.offset_bottom = -24.0
	layout.add_theme_constant_override("separation", 32)
	add_child(layout)

	layout.add_child(_build_button_column("VFX", VFX_IDS, _preview_vfx))

	var stage := CenterContainer.new()
	stage.name = "Stage"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(stage)

	var stage_label := Label.new()
	stage_label.name = "StageLabel"
	stage_label.text = "Preview"
	stage_label.modulate = Color(0.72, 0.78, 0.84, 1.0)
	stage.add_child(stage_label)

	layout.add_child(_build_button_column("SFX", SFX_IDS, _preview_sfx))

	vfx_anchor = Node2D.new()
	vfx_anchor.name = "VFXAnchor"
	add_child(vfx_anchor)

	audio_player = AudioStreamPlayer.new()
	audio_player.name = "CombatFeedbackPreviewAudio"
	add_child(audio_player)


func _build_button_column(title: String, ids: Array, callback: Callable) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(220.0, 0.0)
	column.add_theme_constant_override("separation", 6)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate = Color(0.86, 0.90, 0.95, 1.0)
	column.add_child(title_label)

	for id in ids:
		var button := Button.new()
		button.text = str(id)
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0.0, 30.0)
		button.pressed.connect(callback.bind(str(id)))
		column.add_child(button)

	return column


func _load_sfx_streams() -> void:
	for sound_id in SFX_IDS:
		var path := "res://external/audio/sfx/%s.wav" % sound_id
		var stream: AudioStream = sfx_library.load_sfx_stream(path)
		if stream != null:
			sound_id_to_stream[sound_id] = stream


func _preview_vfx(effect_id: String) -> void:
	if is_instance_valid(active_vfx):
		active_vfx.queue_free()

	var impact_vfx := CARD_IMPACT_VFX_SCENE.instantiate()
	if impact_vfx == null or not impact_vfx.has_method("init"):
		return
	active_vfx = impact_vfx
	vfx_anchor.add_child(impact_vfx)
	impact_vfx.init(effect_id, presentation_resolver.get_impact_vfx_color(effect_id))


func _preview_sfx(sound_id: String) -> void:
	var stream: AudioStream = sound_id_to_stream.get(sound_id, null)
	if stream == null or audio_player == null:
		return
	audio_player.stream = stream
	audio_player.play()


func _update_vfx_anchor_position() -> void:
	if not is_instance_valid(vfx_anchor):
		return
	vfx_anchor.position = size * 0.5

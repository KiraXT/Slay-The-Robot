extends RefCounted
class_name CombatFeedbackSfxLibrary

const DEFAULT_SFX_PATHS := {
	"card_attack": "res://external/audio/sfx/card_attack.wav",
	"card_attack_heavy": "res://external/audio/sfx/card_attack_heavy.wav",
	"card_skill": "res://external/audio/sfx/card_skill.wav",
	"card_skill_draw": "res://external/audio/sfx/card_skill_draw.wav",
	"card_skill_guard": "res://external/audio/sfx/card_skill_guard.wav",
	"card_skill_heal": "res://external/audio/sfx/card_skill_heal.wav",
	"card_skill_item": "res://external/audio/sfx/card_skill_item.wav",
	"card_status": "res://external/audio/sfx/card_status.wav",
	"card_status_heavy": "res://external/audio/sfx/card_status_heavy.wav",
	"card_power": "res://external/audio/sfx/card_power.wav",
	"card_energy": "res://external/audio/sfx/card_energy.wav",
	"impact_damage": "res://external/audio/sfx/impact_damage.wav",
	"block_gain": "res://external/audio/sfx/block_gain.wav",
	"block_hit": "res://external/audio/sfx/block_hit.wav",
	"block_break": "res://external/audio/sfx/block_break.wav",
	"status_apply": "res://external/audio/sfx/status_apply.wav",
	"energy_change": "res://external/audio/sfx/energy_change.wav",
	"pile_draw": "res://external/audio/sfx/pile_draw.wav",
	"pile_discard": "res://external/audio/sfx/pile_discard.wav",
	"pile_exhaust": "res://external/audio/sfx/pile_exhaust.wav",
}


func register_default_sfx(presenter: Node) -> void:
	if presenter == null or not presenter.has_method("register_sfx_stream"):
		return
	for sound_id in DEFAULT_SFX_PATHS:
		var stream := load_sfx_stream(DEFAULT_SFX_PATHS[sound_id])
		if stream == null:
			continue
		presenter.register_sfx_stream(sound_id, stream)


func load_sfx_stream(path: String) -> AudioStream:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44:
		return null
	if not _matches_ascii(bytes, 0, "RIFF") or not _matches_ascii(bytes, 8, "WAVE"):
		return null

	var channels := 0
	var sample_rate := 0
	var bits_per_sample := 0
	var audio_format := 0
	var data_offset := -1
	var data_size := 0
	var offset := 12
	while offset + 8 <= bytes.size():
		var chunk_size := _read_u32_le(bytes, offset + 4)
		var chunk_data_offset := offset + 8
		if chunk_data_offset + chunk_size > bytes.size():
			break
		if _matches_ascii(bytes, offset, "fmt "):
			audio_format = _read_u16_le(bytes, chunk_data_offset)
			channels = _read_u16_le(bytes, chunk_data_offset + 2)
			sample_rate = _read_u32_le(bytes, chunk_data_offset + 4)
			bits_per_sample = _read_u16_le(bytes, chunk_data_offset + 14)
		elif _matches_ascii(bytes, offset, "data"):
			data_offset = chunk_data_offset
			data_size = chunk_size
			break

		offset = chunk_data_offset + chunk_size
		if chunk_size % 2 == 1:
			offset += 1

	if audio_format != 1 or channels < 1 or channels > 2 or bits_per_sample != 16 or data_offset < 0:
		return null

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = channels == 2
	stream.data = bytes.slice(data_offset, data_offset + data_size)
	return stream


func get_default_sfx_paths() -> Dictionary:
	return DEFAULT_SFX_PATHS.duplicate()


func _matches_ascii(bytes: PackedByteArray, offset: int, text: String) -> bool:
	if offset < 0 or offset + text.length() > bytes.size():
		return false
	for index in text.length():
		if bytes[offset + index] != text.unicode_at(index):
			return false
	return true


func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 1 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 3 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)

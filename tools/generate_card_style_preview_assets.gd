extends SceneTree

const SOURCE_PATH := "/var/folders/ry/2r63g3f95j75153j_dvjtnnm0000gn/T/codex-clipboard-5072602a-7ed1-49bf-9540-8da02fd731da.png"
const OUTPUT_ROOT := "external/sprites/ui/card_styles/preview/"

const CROPS := {
	"shared/header_bar": Rect2i(1120, 147, 190, 34),
	"shared/art_frame": Rect2i(1090, 116, 242, 194),
	"shared/description_panel": Rect2i(1382, 117, 252, 178),
	"shared/energy_badge": Rect2i(740, 114, 70, 70),
	"shared/glow": Rect2i(430, 445, 242, 178),
	"frames/frame_blue": Rect2i(128, 974, 100, 153),
	"frames/frame_green": Rect2i(230, 974, 100, 153),
	"frames/frame_red": Rect2i(332, 974, 100, 153),
	"frames/frame_gold": Rect2i(434, 974, 100, 153),
	"frames/frame_silver": Rect2i(536, 974, 100, 153),
	"ribbons/ribbon_attack": Rect2i(744, 584, 102, 50),
	"ribbons/ribbon_skill": Rect2i(846, 584, 102, 50),
	"ribbons/ribbon_power": Rect2i(948, 584, 102, 50),
	"ribbons/ribbon_curse": Rect2i(1050, 584, 102, 50),
	"ribbons/ribbon_status": Rect2i(1152, 584, 102, 50),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source == null or source.is_empty():
		push_error("Failed to load reference source: %s" % SOURCE_PATH)
		quit(1)
		return

	print("REFERENCE_SOURCE_SIZE=%s" % source.get_size())
	for slot_name: String in CROPS:
		var image := source.get_region(CROPS[slot_name])
		image.convert(Image.FORMAT_RGBA8)
		_remove_reference_green(image)
		var output_path := OUTPUT_ROOT + slot_name + ".png"
		var absolute_directory := ProjectSettings.globalize_path("res://" + output_path.get_base_dir())
		DirAccess.make_dir_recursive_absolute(absolute_directory)
		var save_error := image.save_png(ProjectSettings.globalize_path("res://" + output_path))
		if save_error != OK:
			push_error("Failed to save %s: %s" % [output_path, save_error])
			quit(1)
			return
		print("GENERATED_REFERENCE_SLOT=%s size=%s" % [slot_name, image.get_size()])

	print("CARD_STYLE_REFERENCE_ASSETS_GENERATED")
	quit(0)


func _remove_reference_green(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var non_green: float = max(pixel.r, pixel.b)
			if pixel.g > 0.42 and pixel.g - non_green > 0.10:
				pixel.a = 0.0
				image.set_pixel(x, y, pixel)


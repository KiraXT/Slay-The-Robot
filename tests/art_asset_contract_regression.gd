extends SceneTree

const ART_ASSET_GUIDE := "designer/ART_ASSET_GUIDE.md"
const ASSET_REPLACEMENT_GUIDE := "designer/ASSET_REPLACEMENT_GUIDE.md"
const CONTACT_SHEET_TOOL := "tools/generate_art_asset_contact_sheet.gd"
const CONTACT_SHEET_PATH := "designer/art_source/contact_sheets/phase-0-character-contract.png"
const CONTACT_SHEET_SIZE := Vector2i(1040, 324)

const CHARACTER_COMBAT_PATHS := [
	"external/sprites/characters/character_red/character_red.png",
	"external/sprites/characters/character_blue/character_blue.png",
	"external/sprites/characters/character_green/character_green.png",
	"external/sprites/characters/character_orange/character_orange.png",
]

const FALLBACK_ASSETS := {
	"external/sprites/fallback/fallback_card.png": Vector2i(128, 128),
	"external/sprites/fallback/fallback_character.png": Vector2i(256, 256),
	"external/sprites/fallback/fallback_enemy.png": Vector2i(256, 256),
	"external/sprites/fallback/fallback_icon.png": Vector2i(128, 128),
	"external/sprites/fallback/fallback_background.png": Vector2i(1200, 700),
}

const REQUIRED_DOC_PHRASES := {
	ART_ASSET_GUIDE: [
		"卡牌插画",
		"512 x 512",
		"事件插画",
		"768 x 768",
		"角色战斗立绘",
		"真实透明 PNG",
		"无绿底",
		"contact sheet",
		"32px",
		"64px",
	],
	ASSET_REPLACEMENT_GUIDE: [
		"external/sprites/fallback/",
		"fallback_card.png",
		"fallback_character.png",
		"fallback_enemy.png",
		"fallback_icon.png",
		"fallback_background.png",
		"contact sheet",
	],
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_docs()
	_check_character_combat_images()
	_check_fallback_assets()
	_check_fallback_api()
	_check_character_texture_candidate_order()
	_check_tool_exists(CONTACT_SHEET_TOOL)
	_check_contact_sheet()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_docs() -> void:
	for doc_path: String in REQUIRED_DOC_PHRASES.keys():
		var text := _read_project_text(doc_path)
		if text.is_empty():
			failures.append("Missing or empty doc: %s" % doc_path)
			continue
		for phrase: String in REQUIRED_DOC_PHRASES[doc_path]:
			if not text.contains(phrase):
				failures.append("%s must mention `%s`" % [doc_path, phrase])


func _check_character_combat_images() -> void:
	for path: String in CHARACTER_COMBAT_PATHS:
		var image := _load_project_image(path)
		if image == null:
			continue
		var image_size := image.get_size()
		if image_size.y < 500 or image_size.y > 620:
			failures.append("%s combat image height must stay in the current 500-620px range" % path)
		var chroma_green_pixels := _count_chroma_green_rgb_residue(image)
		if chroma_green_pixels > 0:
			failures.append("%s has %s chroma green RGB residue pixels, including transparent pixels; limit is 0" % [path, chroma_green_pixels])
		_check_corners_not_chroma_green(image, path)


func _check_corners_not_chroma_green(image: Image, path: String) -> void:
	var max_x := image.get_width() - 1
	var max_y := image.get_height() - 1
	var corners := [
		Vector2i(0, 0),
		Vector2i(max_x, 0),
		Vector2i(0, max_y),
		Vector2i(max_x, max_y),
	]
	for corner: Vector2i in corners:
		if _is_chroma_green_rgb_residue(image.get_pixel(corner.x, corner.y)):
			failures.append("%s corner %s still contains chroma green RGB residue" % [path, corner])


func _check_fallback_assets() -> void:
	for path: String in FALLBACK_ASSETS:
		var image := _load_project_image(path)
		if image == null:
			continue
		var expected_size: Vector2i = FALLBACK_ASSETS[path]
		if image.get_size() != expected_size:
			failures.append("%s must be %s but is %s" % [path, expected_size, image.get_size()])


func _check_fallback_api() -> void:
	var file_loader_source := _read_project_text("autoload/FileLoader.gd")
	if not file_loader_source.contains("func load_texture_or_fallback("):
		failures.append("FileLoader must expose load_texture_or_fallback")
	for fallback_type: String in ["card", "character", "enemy", "icon", "background"]:
		if not file_loader_source.contains("\"%s\"" % fallback_type):
			failures.append("FileLoader fallback map must include `%s`" % fallback_type)


func _check_character_texture_candidate_order() -> void:
	var character_selection_source := _read_project_text("scripts/ui/CharacterSelectionButton.gd")
	var title_screen_source := _read_project_text("scripts/ui/menus/TitleScreen.gd")
	for source_data: Dictionary in [
		{"path": "scripts/ui/CharacterSelectionButton.gd", "source": character_selection_source},
		{"path": "scripts/ui/menus/TitleScreen.gd", "source": title_screen_source},
	]:
		var source_path: String = source_data["path"]
		var source: String = source_data["source"]
		if source.contains("return FileLoader.load_texture_or_fallback(path, \"character\")"):
			failures.append("%s optional texture helper must not return the typed fallback before later candidates" % source_path)
		if not source.contains("return ImageTexture.new()"):
			failures.append("%s optional texture helper must return an empty texture for missing candidates" % source_path)
		if not source.contains("return FileLoader.load_texture(path)"):
			failures.append("%s optional texture helper must load existing candidates directly" % source_path)
	if not character_selection_source.contains("return FileLoader.load_texture_or_fallback(\"\", \"character\")"):
		failures.append("Character selection must use the typed character fallback only after icon candidates fail")
	if not title_screen_source.contains("return FileLoader.load_texture_or_fallback(\"\", \"character\")"):
		failures.append("Title screen must use the typed character fallback only after portrait candidates fail")


func _check_tool_exists(path: String) -> void:
	if not FileAccess.file_exists(_project_path(path)):
		failures.append("Missing tool: %s" % path)


func _check_contact_sheet() -> void:
	var image := _load_project_image(CONTACT_SHEET_PATH)
	if image == null:
		return
	if image.get_size() != CONTACT_SHEET_SIZE:
		failures.append("%s must be %s but is %s" % [CONTACT_SHEET_PATH, CONTACT_SHEET_SIZE, image.get_size()])
	var transparent_pixels := _count_transparent_pixels(image)
	if transparent_pixels > 0:
		failures.append("%s must be opaque; found %s transparent pixels" % [CONTACT_SHEET_PATH, transparent_pixels])


func _count_transparent_pixels(image: Image) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < 0.999:
				count += 1
	return count


func _count_chroma_green_rgb_residue(image: Image) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if _is_chroma_green_rgb_residue(image.get_pixel(x, y)):
				count += 1
	return count


func _is_chroma_green_rgb_residue(color: Color) -> bool:
	return color.g > 0.92 and color.r < 0.12 and color.b < 0.12


func _load_project_image(path: String) -> Image:
	var absolute_path := _project_path(path)
	if not FileAccess.file_exists(absolute_path):
		failures.append("Missing image: %s" % path)
		return null
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		failures.append("Invalid image: %s" % path)
		return null
	return image


func _read_project_text(path: String) -> String:
	var absolute_path := _project_path(path)
	if not FileAccess.file_exists(absolute_path):
		return ""
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _project_path(path: String) -> String:
	return ProjectSettings.globalize_path("res://%s" % path)

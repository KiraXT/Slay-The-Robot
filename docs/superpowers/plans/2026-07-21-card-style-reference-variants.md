# Reference Card Style Variants Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Split the user-supplied reference sheet into real card-frame and card-type assets, then select them from current card data in game.

**Architecture:** The card style JSON will contain shared assets, color-frame assets, and type-ribbon assets. Card.gd reads existing card_color_id and card_type to choose those real assets. Card.tscn gains one independent dark title-bar node, so the white card name does not depend on the frame color.

**Tech Stack:** Godot 4, GDScript, JSON, Godot Image, FileLoader, headless Godot tests.

## Global Constraints

- The only source for the new visible assets is /var/folders/ry/2r63g3f95j75153j_dvjtnnm0000gn/T/codex-clipboard-5072602a-7ed1-49bf-9540-8da02fd731da.png.
- Never use ColorRect, StyleBoxFlat, runtime tinting, or newly drawn color blocks to replace reference card frames or ribbons.
- Do not change CardData JSON, card gameplay, combat interaction, mouse interaction, card size, or animation behavior.
- Store replaceable assets under external/sprites/ui/card_styles/preview/ and retain external/data/card_styles/card_style_preview.json as the style entry point.
- Missing colors must use the extracted silver frame; missing types must use the extracted gray status ribbon.
- Do not stage, revert, clean, or delete unrelated worktree changes.

---

### Task 1: Define failing variant-contract tests

**Files:**
- Modify: tests/card_style_pack_preview_regression.gd
- Modify: tests/card_template_visual_regression.gd

**Interfaces:**
- Consumes: shared_slots, color_slots, and type_slots in card_style_preview.json.
- Produces: runtime texture-path checks for five frame colors, five card types, and title readability.

- [ ] **Step 1: Replace the single-purple-slot contract**

Add these constants to tests/card_style_pack_preview_regression.gd:

~~~gdscript
const REQUIRED_SHARED_SLOTS := [
	"header_bar", "art_frame", "description_panel", "energy_badge", "glow",
]
const COLOR_SLOT_BY_ID := {
	"color_red": "frame_red",
	"color_blue": "frame_blue",
	"color_green": "frame_green",
	"color_orange": "frame_gold",
	"color_white": "frame_silver",
}
const TYPE_SLOT_BY_ID := {
	CardData.CARD_TYPES.ATTACK: "ribbon_attack",
	CardData.CARD_TYPES.SKILL: "ribbon_skill",
	CardData.CARD_TYPES.POWER: "ribbon_power",
	CardData.CARD_TYPES.STATUS: "ribbon_status",
	CardData.CARD_TYPES.CURSE: "ribbon_curse",
}
~~~

Update _check_style_pack() to require dictionaries named shared_slots, color_slots, and type_slots. Check every configured asset path with FileAccess.file_exists().

- [ ] **Step 2: Add runtime asset-selection checks**

Add this helper and use it after Card.init() for red/attack, blue/skill, green/power, orange/status, and white/curse cards:

~~~gdscript
func _assert_variant_texture(panel: Panel, expected_path: String, label: String) -> void:
	var stylebox := panel.get_theme_stylebox("panel")
	if not stylebox is StyleBoxTexture:
		failures.append("%s must use a reference StyleBoxTexture" % label)
		return
	var texture := (stylebox as StyleBoxTexture).texture
	if texture == null or texture.resource_path != expected_path:
		failures.append("%s must use %s" % [label, expected_path])
~~~

Also assert that CardName has Color.WHITE and that CardHeaderBackground exists.

- [ ] **Step 3: Add title layout checks**

In tests/card_template_visual_regression.gd, assert CardName is inside CardHeaderBackground, CardName does not overlap CardArtFrame, and CardDescription does not overlap CardTypeBackground.

- [ ] **Step 4: Run the new tests before implementation**

Run: godot --headless --path . --script tests/card_style_pack_preview_regression.gd

Expected: FAIL because the current JSON has no shared_slots, color_slots, or type_slots.

Run: godot --headless --path . --script tests/card_template_visual_regression.gd

Expected: FAIL because CardHeaderBackground does not exist.

- [ ] **Step 5: Commit only the test contract**

~~~bash
git add tests/card_style_pack_preview_regression.gd tests/card_template_visual_regression.gd
git commit -m "test: define card reference style variants"
~~~

### Task 2: Generate real reference assets

**Files:**
- Modify: tools/generate_card_style_preview_assets.gd
- Create: external/sprites/ui/card_styles/preview/shared/header_bar.png
- Create: external/sprites/ui/card_styles/preview/shared/art_frame.png
- Create: external/sprites/ui/card_styles/preview/shared/description_panel.png
- Create: external/sprites/ui/card_styles/preview/shared/energy_badge.png
- Create: external/sprites/ui/card_styles/preview/shared/glow.png
- Create: external/sprites/ui/card_styles/preview/frames/frame_red.png
- Create: external/sprites/ui/card_styles/preview/frames/frame_blue.png
- Create: external/sprites/ui/card_styles/preview/frames/frame_green.png
- Create: external/sprites/ui/card_styles/preview/frames/frame_gold.png
- Create: external/sprites/ui/card_styles/preview/frames/frame_silver.png
- Create: external/sprites/ui/card_styles/preview/ribbons/ribbon_attack.png
- Create: external/sprites/ui/card_styles/preview/ribbons/ribbon_skill.png
- Create: external/sprites/ui/card_styles/preview/ribbons/ribbon_power.png
- Create: external/sprites/ui/card_styles/preview/ribbons/ribbon_status.png
- Create: external/sprites/ui/card_styles/preview/ribbons/ribbon_curse.png

**Interfaces:**
- Consumes: the 1656 x 1312 reference sheet.
- Produces: 15 transparent PNGs with the slot names used in Task 1.

- [ ] **Step 1: Declare direct-reference crops**

Use the following crop map in tools/generate_card_style_preview_assets.gd:

~~~gdscript
const SOURCE_PATH := "/var/folders/ry/2r63g3f95j75153j_dvjtnnm0000gn/T/codex-clipboard-5072602a-7ed1-49bf-9540-8da02fd731da.png"
const OUTPUT_ROOT := "external/sprites/ui/card_styles/preview/"
const CROPS := {
	"shared/header_bar": Rect2i(92, 63, 252, 63),
	"shared/art_frame": Rect2i(1090, 117, 240, 184),
	"shared/description_panel": Rect2i(1382, 117, 252, 178),
	"shared/energy_badge": Rect2i(740, 114, 70, 70),
	"shared/glow": Rect2i(430, 446, 242, 174),
	"frames/frame_blue": Rect2i(128, 974, 100, 153),
	"frames/frame_green": Rect2i(230, 974, 100, 153),
	"frames/frame_red": Rect2i(332, 974, 100, 153),
	"frames/frame_gold": Rect2i(434, 974, 100, 153),
	"frames/frame_silver": Rect2i(536, 974, 100, 153),
	"ribbons/ribbon_attack": Rect2i(747, 584, 100, 49),
	"ribbons/ribbon_skill": Rect2i(849, 584, 100, 49),
	"ribbons/ribbon_power": Rect2i(951, 584, 100, 49),
	"ribbons/ribbon_curse": Rect2i(1053, 584, 100, 49),
	"ribbons/ribbon_status": Rect2i(1155, 584, 100, 49),
}
~~~

If preview inspection shows a 1 to 3 pixel crop deviation, only adjust crop coordinates. Do not paint over it.

- [ ] **Step 2: Make the green sheet background transparent**

~~~gdscript
func _remove_reference_green(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var non_green := max(pixel.r, pixel.b)
			if pixel.g > 0.42 and pixel.g - non_green > 0.10:
				pixel.a = 0.0
				image.set_pixel(x, y, pixel)
~~~

Save each crop to OUTPUT_ROOT + slot_name + ".png". Print every slot name and CARD_STYLE_REFERENCE_ASSETS_GENERATED on success.

- [ ] **Step 3: Generate and inspect assets**

Run: godot --headless --path . --script tools/generate_card_style_preview_assets.gd

Expected: CARD_STYLE_REFERENCE_ASSETS_GENERATED and five frame files plus five ribbon files.

Run: sips -g pixelWidth -g pixelHeight external/sprites/ui/card_styles/preview/frames/frame_red.png external/sprites/ui/card_styles/preview/ribbons/ribbon_attack.png

Expected: both dimensions are nonzero. Visually inspect: no green sheet background, red card frame, and red attack ribbon.

- [ ] **Step 4: Commit the generator and assets**

~~~bash
git add tools/generate_card_style_preview_assets.gd external/sprites/ui/card_styles/preview
git commit -m "feat: add reference card style assets"
~~~

### Task 3: Apply data-driven reference variants in the card scene

**Files:**
- Modify: external/data/card_styles/card_style_preview.json
- Modify: scenes/ui/Card.tscn
- Modify: scripts/ui/Card.gd

**Interfaces:**
- Consumes: Task 2 reference PNGs.
- Produces: Card._apply_card_style_pack(card_color_id: String, card_type_id: int).

- [ ] **Step 1: Write the three-layer JSON map**

The JSON must contain shared_slots, color_slots, and type_slots. Its color map must be:

~~~json
{
	"color_red": "external/sprites/ui/card_styles/preview/frames/frame_red.png",
	"color_blue": "external/sprites/ui/card_styles/preview/frames/frame_blue.png",
	"color_green": "external/sprites/ui/card_styles/preview/frames/frame_green.png",
	"color_orange": "external/sprites/ui/card_styles/preview/frames/frame_gold.png",
	"color_white": "external/sprites/ui/card_styles/preview/frames/frame_silver.png",
	"default": "external/sprites/ui/card_styles/preview/frames/frame_silver.png"
}
~~~

Use the current numeric values of CardData.CARD_TYPES as type_slots keys. Map ATTACK, SKILL, POWER, STATUS, and CURSE to the corresponding extracted ribbons. The default must be ribbon_status.png.

- [ ] **Step 2: Add the independently textured title bar**

Add this node before CardName in scenes/ui/Card.tscn:

~~~tscn
[node name="CardHeaderBackground" type="Panel" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 29.0
offset_top = 4.0
offset_right = 132.0
offset_bottom = 27.0
mouse_filter = 2
show_behind_parent = true
~~~

Place CardName within this rectangle, set its default_color to Color(1, 1, 1, 1), and preserve the energy badge above the title bar.

- [ ] **Step 3: Replace unconditional purple application**

Use this core logic in scripts/ui/Card.gd:

~~~gdscript
const CARD_STYLE_SHARED_PANEL_MAP := {
	"CardHeaderBackground": "header_bar",
	"CardArtFrame": "art_frame",
	"CardDescriptionBackground": "description_panel",
	"EnergySprite": "energy_badge",
	"CardGlow": "glow",
}

func _apply_card_style_pack(card_color_id: String, card_type_id: int) -> void:
	var style_data := _load_card_style_pack()
	if style_data.is_empty():
		return
	_apply_shared_style_slots(style_data.get("shared_slots", {}))
	_apply_texture_stylebox(card_color, _mapped_style_path(style_data.get("color_slots", {}), card_color_id))
	_apply_texture_stylebox(card_type_background, _mapped_style_path(style_data.get("type_slots", {}), str(card_type_id)))
	card_name.add_theme_color_override("default_color", Color.WHITE)

func _mapped_style_path(slots: Dictionary, key: String) -> String:
	return str(slots.get(key, slots.get("default", "")))
~~~

Implement _load_card_style_pack() with the existing FileLoader path check, _apply_shared_style_slots() by iterating CARD_STYLE_SHARED_PANEL_MAP, and a CardHeaderBackground branch in _get_card_style_panel(). Call the new method from update_card_display() with card_data.card_color_id and card_data.card_type.

- [ ] **Step 4: Prevent corner distortion with texture margins**

In _apply_texture_stylebox(), set patch margins to 8 on all sides and use StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT for both axes. This only changes texture sampling; it must not generate a color layer.

- [ ] **Step 5: Run the feature tests**

Run: godot --headless --path . --script tests/card_style_pack_preview_regression.gd

Expected: ALL_TESTS_PASSED for five color frames, five type ribbons, and white title text.

Run: godot --headless --path . --script tests/card_template_visual_regression.gd

Expected: ALL_TESTS_PASSED with title, art, type, and description regions inside bounds.

- [ ] **Step 6: Commit the runtime selection**

~~~bash
git add external/data/card_styles/card_style_preview.json scenes/ui/Card.tscn scripts/ui/Card.gd
git commit -m "feat: apply reference card style variants"
~~~

### Task 4: Build a five-color/five-type visual preview

**Files:**
- Modify: tools/render_card_style_preview.gd
- Create: tmp/card_style_preview/card_style_reference_variants.png

**Interfaces:**
- Consumes: Task 3 JSON and Task 2 assets.
- Produces: a five-card comparison image.

- [ ] **Step 1: Define the preview cases**

~~~gdscript
const PREVIEW_CASES := [
	{"color": "color_red", "type": "0", "name": "烈焰冲击", "label": "攻击"},
	{"color": "color_blue", "type": "1", "name": "误打误撞", "label": "技能"},
	{"color": "color_green", "type": "2", "name": "生长核心", "label": "能力"},
	{"color": "color_orange", "type": "3", "name": "整备姿态", "label": "状态"},
	{"color": "color_white", "type": "4", "name": "禁忌回响", "label": "诅咒"},
]
~~~

If CardData enum values differ from these numeric strings, change only the case keys to the actual values.

- [ ] **Step 2: Compose only extracted layers**

For every case, select the JSON color_slots and type_slots path. Blend the extracted outer frame, header bar, art frame, description panel, ribbon, and energy badge in that order onto a 144 x 184 card region. Draw the card name in white. Do not draw any colored rectangle for a frame or ribbon.

- [ ] **Step 3: Render and visually inspect**

Run: godot --headless --path . --script tools/render_card_style_preview.gd

Expected: CARD_STYLE_REFERENCE_PREVIEW_RENDERED: tmp/card_style_preview/card_style_reference_variants.png.

Check the image for distinct red, blue, green, gold, and silver frames; red, green, blue, gray, and purple ribbons; white names on dark title bars; no double full-frame seams; and no visible green background.

- [ ] **Step 4: Run the final checks and commit**

Run: godot --headless --path . --script tests/card_style_pack_preview_regression.gd && godot --headless --path . --script tests/card_template_visual_regression.gd && git diff --check

Expected: both tests print ALL_TESTS_PASSED and git diff --check has no output.

~~~bash
git add tools/render_card_style_preview.gd
git commit -m "feat: render reference card style variants"
~~~

### Task 5: Confirm handoff scope

**Files:**
- Verify: scripts/ui/Card.gd
- Verify: scenes/ui/Card.tscn
- Verify: external/data/card_styles/card_style_preview.json
- Verify: external/sprites/ui/card_styles/preview/
- Verify: tmp/card_style_preview/card_style_reference_variants.png

**Interfaces:**
- Consumes: Tasks 1 through 4.
- Produces: verified in-game style selection and a user-facing preview.

- [ ] **Step 1: Check scoped changes**

Run: git status --short scripts/ui/Card.gd scenes/ui/Card.tscn external/data/card_styles external/sprites/ui/card_styles tests/card_style_pack_preview_regression.gd tests/card_template_visual_regression.gd tools/generate_card_style_preview_assets.gd tools/render_card_style_preview.gd

Expected: only files from this plan are included; preserve all unrelated worktree state.

- [ ] **Step 2: Perform a no-window load check**

Run: godot --headless --path . --quit

Expected: exit code 0 and no Card.tscn, StyleBoxTexture, or JSON-path parsing errors.

- [ ] **Step 3: Deliver the preview and evidence**

Show the absolute path of card_style_reference_variants.png, state that frames and ribbons were directly cropped from the reference resource, report both test results, and state that card gameplay logic was untouched.

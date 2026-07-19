# Art Asset Contract Phase 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Phase 0 of the overall art/UI optimization by locking the real asset contract, detecting bad character transparency, generating typed fallback assets, and producing contact sheets before any broader UI restyle.

**Architecture:** Keep runtime gameplay unchanged. Add one asset-contract regression test, deterministic Godot-based asset utility scripts, updated designer documentation, cleaned character combat PNGs, and backward-compatible typed fallback loading through `FileLoader`. Use existing JSON paths and external asset directories.

**Tech Stack:** Godot 4.6 GDScript, existing `FileLoader.gd`, PNG assets under `external/sprites/`, Markdown designer docs, Godot headless regression scripts.

## Global Constraints

- Documentation language is Chinese.
- Do not change card combat logic, enemy behavior, map generation, reward rules, or the JSON data-driven architecture.
- Do not introduce a frame animation system; Phase 0 uses static PNG assets and existing loading code.
- All character combat sprites must be real transparent PNGs with no chroma green RGB residue, including fully transparent pixels.
- All new fallback assets must live under `external/sprites/fallback/`.
- All image validation and generation must run through Godot headless scripts, not Python image libraries.
- Preserve existing paths and filenames for character runtime assets so current JSON does not need migration.
- Each task ends with a commit after the task-local verification passes.

---

## File Structure

- Create `tests/art_asset_contract_regression.gd`: verifies asset docs, character combat image transparency, fallback images, and contact sheet tool presence.
- Modify `designer/ART_ASSET_GUIDE.md`: replace stale size tables with the current real asset contract and chroma/contact-sheet rules.
- Modify `designer/ASSET_REPLACEMENT_GUIDE.md`: add fallback asset rows and contact-sheet acceptance steps.
- Create `tools/generate_asset_fallbacks.gd`: deterministically generates typed fallback PNGs.
- Create `tools/clean_character_chroma_key.gd`: removes pure chroma green from the four current character combat images.
- Create `tools/generate_art_asset_contact_sheet.gd`: generates a phase-0 character contract contact sheet.
- Modify `autoload/FileLoader.gd`: add typed fallback constants and `load_texture_or_fallback()`.
- Modify key image-loading call sites to use typed fallback loading while preserving existing data fields.
- Modify existing character PNG files in `external/sprites/characters/character_*/*character_*.png`: remove green background from combat sprites only.
- Create fallback PNGs in `external/sprites/fallback/`.
- Create `designer/art_source/contact_sheets/phase-0-character-contract.png`.

---

### Task 1: Add Failing Asset Contract Regression

**Files:**
- Create: `tests/art_asset_contract_regression.gd`

**Interfaces:**
- Consumes: existing docs and PNG paths.
- Produces: one headless regression entrypoint: `godot --headless --path . -s tests/art_asset_contract_regression.gd`.

- [ ] **Step 1: Write the failing regression**

Create `tests/art_asset_contract_regression.gd` with this content:

```gdscript
extends SceneTree

const ART_ASSET_GUIDE := "designer/ART_ASSET_GUIDE.md"
const ASSET_REPLACEMENT_GUIDE := "designer/ASSET_REPLACEMENT_GUIDE.md"
const CONTACT_SHEET_TOOL := "tools/generate_art_asset_contact_sheet.gd"

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
	_check_tool_exists(CONTACT_SHEET_TOOL)

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


func _check_tool_exists(path: String) -> void:
	if not FileAccess.file_exists(_project_path(path)):
		failures.append("Missing tool: %s" % path)


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
```

- [ ] **Step 2: Run the regression to verify it fails**

Run:

```bash
godot --headless --path . -s tests/art_asset_contract_regression.gd
```

Expected: exit code `1`. The failure list must include missing fallback files and chroma green RGB residue in at least one character combat image, including residue found in fully transparent pixels. It may also report stale text in `designer/ART_ASSET_GUIDE.md`.

- [ ] **Step 3: Commit the failing regression**

Run:

```bash
git add tests/art_asset_contract_regression.gd
git commit -m "test: add art asset contract regression"
```

---

### Task 2: Update Asset Contract Documentation

**Files:**
- Modify: `designer/ART_ASSET_GUIDE.md`
- Modify: `designer/ASSET_REPLACEMENT_GUIDE.md`

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-07-19-overall-art-ui-optimization-design.md`.
- Produces: docs that satisfy `tests/art_asset_contract_regression.gd`.

- [ ] **Step 1: Replace stale resource specification in `ART_ASSET_GUIDE.md`**

In `designer/ART_ASSET_GUIDE.md`, replace the old card, character, enemy, and event size claims with this source-of-truth table and rules. Keep the existing FileLoader and animation system sections after the table.

```markdown
## 2. 当前运行资产契约

所有外部美术资源统一放在 `external/sprites/`。运行图以游戏实际显示为准，不再使用早期 96x96 卡图或 96x96 事件图规格。

| 类型 | 存放路径 | 运行规格 | 格式 | 透明要求 | JSON 字段 |
| --- | --- | --- | --- | --- | --- |
| 卡牌插画 | `external/sprites/cards/` | `512 x 512` | PNG 优先 | 透明 PNG，允许无透明背景的语义图 | `card_texture_path` |
| 角色战斗立绘 | `external/sprites/characters/character_{color}/` | 当前高约 `512-600` | PNG | 真实透明 PNG，无绿底 | `character_texture_path` |
| 角色选择头像 | `external/sprites/characters/character_{color}/` | `256 x 256` | PNG | 透明 PNG | `character_icon_texture_path` |
| 角色能量图标 | `external/sprites/characters/character_{color}/` | `128 x 128` 或已验证 `16 x 16` 内嵌图 | PNG | 透明 PNG | `character_text_energy_texture_path` |
| 角色选择背景 | `external/sprites/characters/character_{color}/` | `1200 x 700` | PNG | 可不透明 | `character_background_texture_path` |
| 敌人战斗图 | `external/sprites/enemies/` | 小怪约 `64-128`，Boss 可到 `512` | PNG | 透明 PNG | `enemy_texture_path` |
| 事件插画 | `external/sprites/events/` | `768 x 768` | PNG/JPG | 可不透明 | `dialogue_state_dialogue_texture_path` |
| 战斗/章节背景 | `external/sprites/acts/`、`external/sprites/locations/` | `1200 x 700` 或 `2400 x 1400` | PNG/JPG | 不透明 | `act_background_texture_path` / `location_background_texture_path` / `event_background_texture_path` |
| 遗物图标 | `external/sprites/artifacts/` | `128 x 128` | PNG | 透明 PNG | `artifact_texture_path` |
| 消耗品图标 | `external/sprites/consumables/` | `128 x 128`，旧资源可为 `80 x 80` | PNG | 透明 PNG | `consumable_texture_path` |
| 状态图标 | `external/sprites/status_effects/` | `128 x 128`，旧资源可为 `80 x 80` | PNG | 透明 PNG | `status_effect_texture_path` |

## 3. 透明通道与绿底规则

角色、敌人、图标和卡牌插画运行图必须使用真实 alpha 通道。不得把 `#00ff00` 或其他纯色抠像底作为运行图背景提交。

验收标准：

1. 角色战斗立绘四角不能包含 chroma green RGB residue，即使这些像素的 alpha 为 `0`。
2. 角色战斗立绘中不得存在 chroma green RGB residue；清理工具必须检查所有像素的 RGB，不得只检查 opaque 像素。
3. 角色脚底、头发、武器和外轮廓必须完整可见。
4. 角色缩放到战斗显示高度约 `200px` 后仍能辨认主体。

## 4. Contact Sheet 验收

所有新增或替换的内容图必须生成 contact sheet。contact sheet 至少包含：

1. 原图预览。
2. 游戏显示尺寸预览。
3. `64px` 缩略图。
4. `32px` 缩略图。
5. 深色背景和浅色背景下的透明边检查。

Phase 0 的角色验收图输出到：

`designer/art_source/contact_sheets/phase-0-character-contract.png`

## 5. 类型化 fallback

类型化 fallback 资源统一放在 `external/sprites/fallback/`：

| 类型 | 文件 |
| --- | --- |
| 卡牌插画 fallback | `fallback_card.png` |
| 角色 fallback | `fallback_character.png` |
| 敌人 fallback | `fallback_enemy.png` |
| 通用图标 fallback | `fallback_icon.png` |
| 背景 fallback | `fallback_background.png` |

新增 UI 或资源加载点时，应优先使用 `FileLoader.load_texture_or_fallback(path, fallback_type)`，不要直接把缺图显示成空纹理或无语义图标。
```

- [ ] **Step 2: Add fallback and contact sheet notes to `ASSET_REPLACEMENT_GUIDE.md`**

In `designer/ASSET_REPLACEMENT_GUIDE.md`, add this section after the overview table:

```markdown
## 类型化 fallback 与验收输出

缺图 fallback 统一放在 `external/sprites/fallback/`。这些文件不是最终美术，只用于让缺图在游戏内明确暴露，同时避免空纹理破坏布局。

| fallback 类型 | 文件 | 尺寸 | 用途 |
| --- | --- | --- | --- |
| `card` | `external/sprites/fallback/fallback_card.png` | `128 x 128` | 卡牌插画缺失 |
| `character` | `external/sprites/fallback/fallback_character.png` | `256 x 256` | 玩家角色立绘或头像缺失 |
| `enemy` | `external/sprites/fallback/fallback_enemy.png` | `256 x 256` | 敌人战斗图缺失 |
| `icon` | `external/sprites/fallback/fallback_icon.png` | `128 x 128` | 遗物、状态、消耗品和通用小图标缺失 |
| `background` | `external/sprites/fallback/fallback_background.png` | `1200 x 700` | 战斗、事件或标题背景缺失 |

每次替换角色、敌人、卡图、事件图或图标后，必须生成 contact sheet 并在真实游戏尺寸下验收。Phase 0 角色验收图输出到：

`designer/art_source/contact_sheets/phase-0-character-contract.png`
```

- [ ] **Step 3: Run the asset contract regression**

Run:

```bash
godot --headless --path . -s tests/art_asset_contract_regression.gd
```

Expected: still fails because fallback images, the contact-sheet tool, and cleaned character images have not been created yet. It must no longer report missing required phrases in `designer/ART_ASSET_GUIDE.md` or `designer/ASSET_REPLACEMENT_GUIDE.md`.

- [ ] **Step 4: Commit the documentation update**

Run:

```bash
git add designer/ART_ASSET_GUIDE.md designer/ASSET_REPLACEMENT_GUIDE.md
git commit -m "docs: update art asset contract"
```

---

### Task 3: Generate Typed Fallback Assets

**Files:**
- Create: `tools/generate_asset_fallbacks.gd`
- Create: `external/sprites/fallback/fallback_card.png`
- Create: `external/sprites/fallback/fallback_character.png`
- Create: `external/sprites/fallback/fallback_enemy.png`
- Create: `external/sprites/fallback/fallback_icon.png`
- Create: `external/sprites/fallback/fallback_background.png`

**Interfaces:**
- Produces fallback files consumed by `FileLoader.load_texture_or_fallback(path, fallback_type)`.

- [ ] **Step 1: Create deterministic fallback generator**

Create `tools/generate_asset_fallbacks.gd`:

```gdscript
extends SceneTree

const OUTPUT_DIR := "external/sprites/fallback"
const SPECS := [
	{"path": "external/sprites/fallback/fallback_card.png", "size": Vector2i(128, 128), "bg": Color(0.96, 0.98, 1.0, 1.0), "border": Color(0.16, 0.66, 0.82, 1.0), "mark": Color(1.0, 0.55, 0.20, 1.0)},
	{"path": "external/sprites/fallback/fallback_character.png", "size": Vector2i(256, 256), "bg": Color(0.94, 0.98, 1.0, 1.0), "border": Color(0.18, 0.55, 0.88, 1.0), "mark": Color(1.0, 0.64, 0.18, 1.0)},
	{"path": "external/sprites/fallback/fallback_enemy.png", "size": Vector2i(256, 256), "bg": Color(0.12, 0.15, 0.18, 1.0), "border": Color(0.95, 0.35, 0.28, 1.0), "mark": Color(1.0, 0.82, 0.26, 1.0)},
	{"path": "external/sprites/fallback/fallback_icon.png", "size": Vector2i(128, 128), "bg": Color(0.98, 0.98, 0.94, 1.0), "border": Color(0.15, 0.62, 0.72, 1.0), "mark": Color(0.24, 0.38, 0.44, 1.0)},
	{"path": "external/sprites/fallback/fallback_background.png", "size": Vector2i(1200, 700), "bg": Color(0.78, 0.96, 0.98, 1.0), "border": Color(0.16, 0.66, 0.82, 1.0), "mark": Color(1.0, 0.66, 0.20, 1.0)},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUTPUT_DIR))
	for spec: Dictionary in SPECS:
		_generate_fallback(spec)
	print("ALL_FALLBACK_ASSETS_GENERATED")
	quit(0)


func _generate_fallback(spec: Dictionary) -> void:
	var size: Vector2i = spec["size"]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(spec["bg"])
	_draw_border(image, spec["border"], max(3, int(min(size.x, size.y) * 0.04)))
	_draw_missing_mark(image, spec["mark"])
	var result := image.save_png(ProjectSettings.globalize_path("res://%s" % spec["path"]))
	if result != OK:
		push_error("Failed to write fallback: %s" % spec["path"])
		quit(1)


func _draw_border(image: Image, color: Color, width: int) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if x < width or y < width or x >= image.get_width() - width or y >= image.get_height() - width:
				image.set_pixel(x, y, color)


func _draw_missing_mark(image: Image, color: Color) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var stroke := max(3, int(min(w, h) * 0.035))
	_draw_line(image, Vector2i(int(w * 0.30), int(h * 0.30)), Vector2i(int(w * 0.70), int(h * 0.70)), color, stroke)
	_draw_line(image, Vector2i(int(w * 0.70), int(h * 0.30)), Vector2i(int(w * 0.30), int(h * 0.70)), color, stroke)
	_draw_rect(image, Rect2i(Vector2i(int(w * 0.42), int(h * 0.18)), Vector2i(int(w * 0.16), int(h * 0.16))), color)


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


func _draw_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color, width: int) -> void:
	var delta := Vector2(to_point - from_point)
	var length := max(1, int(delta.length()))
	for index in range(length + 1):
		var t := float(index) / float(length)
		var point := Vector2(from_point).lerp(Vector2(to_point), t)
		_draw_rect(image, Rect2i(Vector2i(roundi(point.x) - width / 2, roundi(point.y) - width / 2), Vector2i(width, width)), color)
```

- [ ] **Step 2: Run the generator**

Run:

```bash
godot --headless --path . -s tools/generate_asset_fallbacks.gd
```

Expected: prints `ALL_FALLBACK_ASSETS_GENERATED` and creates the five PNG files under `external/sprites/fallback/`.

- [ ] **Step 3: Run the asset contract regression**

Run:

```bash
godot --headless --path . -s tests/art_asset_contract_regression.gd
```

Expected: still fails because character combat images still contain chroma green RGB residue, including fully transparent pixels, and the contact-sheet tool has not been created. It must no longer report missing fallback assets.

- [ ] **Step 4: Commit fallback generation**

Run:

```bash
git add tools/generate_asset_fallbacks.gd external/sprites/fallback
git commit -m "art: add typed fallback assets"
```

---

### Task 4: Clean Character Chroma Green and Generate Contact Sheet

**Files:**
- Create: `tools/clean_character_chroma_key.gd`
- Create: `tools/generate_art_asset_contact_sheet.gd`
- Modify: `external/sprites/characters/character_red/character_red.png`
- Modify: `external/sprites/characters/character_blue/character_blue.png`
- Modify: `external/sprites/characters/character_green/character_green.png`
- Modify: `external/sprites/characters/character_orange/character_orange.png`
- Create: `designer/art_source/contact_sheets/phase-0-character-contract.png`

**Interfaces:**
- Produces cleaned character PNGs consumed by current character JSON.
- Produces contact sheet consumed by manual visual review.

- [ ] **Step 1: Create the chroma cleanup tool**

Create `tools/clean_character_chroma_key.gd`:

```gdscript
extends SceneTree

const CHARACTER_COMBAT_PATHS := [
	"external/sprites/characters/character_red/character_red.png",
	"external/sprites/characters/character_blue/character_blue.png",
	"external/sprites/characters/character_green/character_green.png",
	"external/sprites/characters/character_orange/character_orange.png",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path: String in CHARACTER_COMBAT_PATHS:
		_clean_image(path)
	print("CHARACTER_CHROMA_KEY_CLEANED")
	quit(0)


func _clean_image(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path("res://%s" % path)
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		push_error("Cannot load character image: %s" % path)
		quit(1)
		return

	var changed_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if _is_chroma_green_rgb_residue(color):
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				changed_pixels += 1

	var result := image.save_png(absolute_path)
	if result != OK:
		push_error("Cannot save cleaned character image: %s" % path)
		quit(1)
	print("%s cleaned %s chroma green RGB residue pixels" % [path, changed_pixels])


func _is_chroma_green_rgb_residue(color: Color) -> bool:
	return color.g > 0.86 and color.r < 0.22 and color.b < 0.22
```

- [ ] **Step 2: Create the contact sheet generator**

Create `tools/generate_art_asset_contact_sheet.gd`:

```gdscript
extends SceneTree

const OUTPUT_DIR := "designer/art_source/contact_sheets"
const OUTPUT_PATH := "designer/art_source/contact_sheets/phase-0-character-contract.png"
const CHARACTER_COMBAT_PATHS := [
	"external/sprites/characters/character_red/character_red.png",
	"external/sprites/characters/character_blue/character_blue.png",
	"external/sprites/characters/character_green/character_green.png",
	"external/sprites/characters/character_orange/character_orange.png",
]

const TILE_SIZE := Vector2i(260, 300)
const DISPLAY_SIZE := Vector2i(160, 220)
const THUMB_64 := Vector2i(64, 64)
const THUMB_32 := Vector2i(32, 32)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUTPUT_DIR))
	var sheet := Image.create(TILE_SIZE.x * CHARACTER_COMBAT_PATHS.size(), TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.10, 0.12, 1.0))

	for index in range(CHARACTER_COMBAT_PATHS.size()):
		var path := CHARACTER_COMBAT_PATHS[index]
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://%s" % path))
		if image == null or image.is_empty():
			push_error("Cannot load contact sheet source: %s" % path)
			quit(1)
			return
		_draw_character_tile(sheet, image, index)

	var result := sheet.save_png(ProjectSettings.globalize_path("res://%s" % OUTPUT_PATH))
	if result != OK:
		push_error("Cannot save contact sheet: %s" % OUTPUT_PATH)
		quit(1)
	print("CONTACT_SHEET_GENERATED:%s" % OUTPUT_PATH)
	quit(0)


func _draw_character_tile(sheet: Image, source: Image, index: int) -> void:
	var tile_origin := Vector2i(TILE_SIZE.x * index, 0)
	_draw_rect(sheet, Rect2i(tile_origin + Vector2i(8, 8), TILE_SIZE - Vector2i(16, 16)), Color(0.94, 0.98, 1.0, 1.0))
	_draw_rect(sheet, Rect2i(tile_origin + Vector2i(8, 8), Vector2i(TILE_SIZE.x - 16, 4)), Color(0.18, 0.66, 0.82, 1.0))

	var cropped := _crop_to_used_rect(source)
	var display := _fit_image(cropped, DISPLAY_SIZE)
	var display_pos := tile_origin + Vector2i((TILE_SIZE.x - display.get_width()) / 2, 24)
	sheet.blit_rect(display, Rect2i(Vector2i.ZERO, display.get_size()), display_pos)

	var thumb64 := _fit_image(cropped, THUMB_64)
	var thumb32 := _fit_image(cropped, THUMB_32)
	sheet.blit_rect(thumb64, Rect2i(Vector2i.ZERO, thumb64.get_size()), tile_origin + Vector2i(72, 252))
	sheet.blit_rect(thumb32, Rect2i(Vector2i.ZERO, thumb32.get_size()), tile_origin + Vector2i(154, 268))


func _crop_to_used_rect(image: Image) -> Image:
	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return image.duplicate()
	return image.get_region(used_rect)


func _fit_image(image: Image, max_size: Vector2i) -> Image:
	var fitted := image.duplicate()
	var ratio := min(float(max_size.x) / float(fitted.get_width()), float(max_size.y) / float(fitted.get_height()))
	var target_size := Vector2i(max(1, roundi(fitted.get_width() * ratio)), max(1, roundi(fitted.get_height() * ratio)))
	fitted.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	return fitted


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)
```

- [ ] **Step 3: Run chroma cleanup and contact sheet generation**

Run:

```bash
godot --headless --path . -s tools/clean_character_chroma_key.gd
godot --headless --path . -s tools/generate_art_asset_contact_sheet.gd
```

Expected: the first command prints `CHARACTER_CHROMA_KEY_CLEANED`; the second prints `CONTACT_SHEET_GENERATED:designer/art_source/contact_sheets/phase-0-character-contract.png`.

- [ ] **Step 4: Run the asset contract regression**

Run:

```bash
godot --headless --path . -s tests/art_asset_contract_regression.gd
```

Expected: prints `ALL_TESTS_PASSED`.

- [ ] **Step 5: Commit cleaned assets and tools**

Run:

```bash
git add tools/clean_character_chroma_key.gd tools/generate_art_asset_contact_sheet.gd external/sprites/characters/character_red/character_red.png external/sprites/characters/character_blue/character_blue.png external/sprites/characters/character_green/character_green.png external/sprites/characters/character_orange/character_orange.png designer/art_source/contact_sheets/phase-0-character-contract.png
git commit -m "art: clean character combat transparency"
```

---

### Task 5: Add Typed Fallback Loading

**Files:**
- Modify: `autoload/FileLoader.gd`
- Modify: `scripts/ui/Card.gd`
- Modify: `scripts/combatants/BaseCombatant.gd`
- Modify: `scripts/combatants/Player.gd`
- Modify: `scripts/combatants/Enemy.gd`
- Modify selected existing texture-loading UI scripts listed below.

**Interfaces:**
- Produces: `FileLoader.load_texture_or_fallback(image_partial_path: String, fallback_type: String = "", is_absolute: bool = false) -> ImageTexture`.
- Consumes: fallback files created in Task 3.

- [ ] **Step 1: Add fallback API to `FileLoader.gd`**

In `autoload/FileLoader.gd`, add these constants after `VALID_IMAGE_EXTENSIONS`:

```gdscript
const FALLBACK_TEXTURE_PATHS: Dictionary = {
	"card": "external/sprites/fallback/fallback_card.png",
	"character": "external/sprites/fallback/fallback_character.png",
	"enemy": "external/sprites/fallback/fallback_enemy.png",
	"icon": "external/sprites/fallback/fallback_icon.png",
	"background": "external/sprites/fallback/fallback_background.png",
}
```

Add these methods below `load_texture()`:

```gdscript
func load_texture_or_fallback(image_partial_path: String, fallback_type: String = "", is_absolute: bool = false) -> ImageTexture:
	if _texture_file_exists(image_partial_path, is_absolute):
		return load_texture(image_partial_path, is_absolute)

	var fallback_path: String = FALLBACK_TEXTURE_PATHS.get(fallback_type, "")
	if fallback_path != "" and _texture_file_exists(fallback_path, false):
		return load_texture(fallback_path, false)

	return ImageTexture.new()


func _texture_file_exists(image_partial_path: String, is_absolute: bool = false) -> bool:
	if image_partial_path.strip_edges() == "":
		return false
	var full_path := image_partial_path
	if not is_absolute:
		full_path = _get_modified_filepath(image_partial_path)
	return FileAccess.file_exists(full_path)
```

- [ ] **Step 2: Update card and combatant texture loading**

Use these exact behavior changes:

```gdscript
# scripts/ui/Card.gd
card_texture.texture = FileLoader.load_texture_or_fallback(card_data.card_texture_path, "card")
```

```gdscript
# scripts/combatants/BaseCombatant.gd
func set_combat_sprite_texture(texture_path: String, target_visible_height: int, fallback_type: String = "character") -> void:
	var texture: Texture2D = FileLoader.load_texture_or_fallback(texture_path, fallback_type)
	sprite.texture = _create_fitted_combat_texture(texture, target_visible_height)
	_update_selection_bounds()
```

```gdscript
# scripts/combatants/Player.gd
set_combat_sprite_texture(character_data.character_texture_path, PLAYER_COMBAT_SPRITE_HEIGHT, "character")
```

```gdscript
# scripts/combatants/Enemy.gd
set_combat_sprite_texture(enemy_data.enemy_texture_path, ENEMY_COMBAT_SPRITE_HEIGHT, "enemy")
```

- [ ] **Step 3: Update common UI texture loading call sites**

Replace direct `FileLoader.load_texture(...)` calls with typed fallback loading according to this mapping:

| File | Loading target | Replacement |
| --- | --- | --- |
| `scripts/ui/Artifact.gd` | artifact texture | `FileLoader.load_texture_or_fallback(artifact_data.artifact_texture_path, "icon")` |
| `scripts/combatants/fades/ArtifactFade.gd` | artifact fade texture | `FileLoader.load_texture_or_fallback(artifact_data.artifact_texture_path, "icon")` |
| `scripts/combatants/BaseCombatant.gd` | status effect texture | `FileLoader.load_texture_or_fallback(status_effect_data.status_effect_texture_path, "icon")` |
| `scripts/ui/ConsumableButton.gd` | consumable texture | `FileLoader.load_texture_or_fallback(consumable_data.consumable_texture_path, "icon")` |
| `scripts/ui/shop/ConsumableShopButton.gd` | consumable shop icon | `FileLoader.load_texture_or_fallback(consumable_data.consumable_texture_path, "icon")` |
| `scripts/ui/shop/ArtifactShopButton.gd` | artifact shop icon | `FileLoader.load_texture_or_fallback(artifact_data.artifact_texture_path, "icon")` |
| `scripts/ui/rewards/ArtifactRewardButton.gd` | artifact reward icon | `FileLoader.load_texture_or_fallback(artifact_data.artifact_texture_path, "icon")` |
| `scripts/ui/RewardOverlay.gd` | consumable/custom reward icons | `FileLoader.load_texture_or_fallback(path_value, "icon")` |
| `scripts/ui/DialogueOverlay.gd` | dialogue image | `FileLoader.load_texture_or_fallback(current_dialogue_state.dialogue_state_dialogue_texture_path, "background")` |
| `scripts/ui/Combat.gd` | combat background | `FileLoader.load_texture_or_fallback(background_texture_path, "background")` |
| `scripts/ui/CharacterSelectionButton.gd` | character icon | `FileLoader.load_texture_or_fallback(path, "character")` |
| `scripts/ui/menus/TitleScreen.gd` | character portrait | `FileLoader.load_texture_or_fallback(path, "character")` |
| `scripts/ui/menus/MenuBackdrop.gd` | character background | `FileLoader.load_texture_or_fallback(path, "background")` |
| `scripts/ui/menus/CodexMenu.gd` | codex object texture | use `"card"` for cards, `"enemy"` for enemies, `"icon"` for artifacts |
| `scripts/ui/menus/NewRunMenu.gd` | starting artifact texture | `FileLoader.load_texture_or_fallback(artifact_data.artifact_texture_path, "icon")` |

For `RewardOverlay.gd`, use the existing local variable that contains the texture path. If the source is a consumable or custom icon path, the fallback type is `"icon"`.

- [ ] **Step 4: Add fallback regression checks**

Extend `tests/art_asset_contract_regression.gd` with this method:

```gdscript
func _check_fallback_api() -> void:
	var file_loader_source := _read_project_text("autoload/FileLoader.gd")
	if not file_loader_source.contains("func load_texture_or_fallback("):
		failures.append("FileLoader must expose load_texture_or_fallback")
	for fallback_type: String in ["card", "character", "enemy", "icon", "background"]:
		if not file_loader_source.contains("\"%s\"" % fallback_type):
			failures.append("FileLoader fallback map must include `%s`" % fallback_type)
```

Call `_check_fallback_api()` from `_run()` after `_check_fallback_assets()`.

- [ ] **Step 5: Run targeted regression**

Run:

```bash
godot --headless --path . -s tests/art_asset_contract_regression.gd
godot --headless --path . -s tests/card_template_visual_regression.gd
godot --headless --path . -s tests/title_screen_asset_regression.gd
```

Expected: each command prints `ALL_TESTS_PASSED`.

- [ ] **Step 6: Commit fallback loading**

Run:

```bash
git add autoload/FileLoader.gd scripts/ui/Card.gd scripts/combatants/BaseCombatant.gd scripts/combatants/Player.gd scripts/combatants/Enemy.gd scripts/ui/Artifact.gd scripts/combatants/fades/ArtifactFade.gd scripts/ui/ConsumableButton.gd scripts/ui/shop/ConsumableShopButton.gd scripts/ui/shop/ArtifactShopButton.gd scripts/ui/rewards/ArtifactRewardButton.gd scripts/ui/RewardOverlay.gd scripts/ui/DialogueOverlay.gd scripts/ui/Combat.gd scripts/ui/CharacterSelectionButton.gd scripts/ui/menus/TitleScreen.gd scripts/ui/menus/MenuBackdrop.gd scripts/ui/menus/CodexMenu.gd scripts/ui/menus/NewRunMenu.gd tests/art_asset_contract_regression.gd
git commit -m "feat: add typed texture fallbacks"
```

---

### Task 6: Final Phase 0 Verification

**Files:**
- Review only.

**Interfaces:**
- Consumes all deliverables from Tasks 1-5.
- Produces confidence that Phase 0 is complete.

- [ ] **Step 1: Run full relevant verification**

Run:

```bash
godot --headless --path . -s tests/art_asset_contract_regression.gd
godot --headless --path . -s tests/title_screen_asset_regression.gd
godot --headless --path . -s tests/ui_layout_bounds_regression.gd
godot --headless --path . -s tests/card_template_visual_regression.gd
godot --headless --path . -s tests/custom_ui_artifact_regression.gd
godot --headless --path . -s tests/rest_pick_config_regression.gd
```

Expected: each command prints `ALL_TESTS_PASSED`.

- [ ] **Step 2: Inspect changed files**

Run:

```bash
git status --short
git diff --stat HEAD
```

Expected: only Phase 0 files are changed after the previous commits. Existing unrelated workspace files remain unstaged.

- [ ] **Step 3: Open the contact sheet for manual review**

Open or preview:

```text
designer/art_source/contact_sheets/phase-0-character-contract.png
```

Expected: all four character combat sprites appear on clean light tiles, with no green background visible in the main preview, `64px` preview, or `32px` preview.

- [ ] **Step 4: Commit verification note if needed**

If Task 6 requires no code or asset changes, do not create an empty commit. If a verification note is added to an existing plan or docs file, commit only that file:

```bash
git add <changed-doc-file>
git commit -m "docs: record phase 0 verification"
```

Expected: no empty commit is created.

---

## Plan Self-Review

Spec coverage:

- Phase 0 doc updates are covered by Task 2.
- Character transparency and green background cleanup are covered by Tasks 1 and 4.
- Contact sheet generation is covered by Task 4 and final review in Task 6.
- Typed fallback assets are covered by Task 3.
- Runtime fallback loading is covered by Task 5.
- No UI restyle, combat stage art, role-chain card art, enemy redraw, or VFX expansion is included; those belong to later phase plans.

Placeholder scan:

- The plan contains exact files, commands, expected outputs, method names, and code blocks for new scripts and APIs.
- No task depends on an unnamed tool or unspecified validation.

Type consistency:

- `FileLoader.load_texture_or_fallback(image_partial_path: String, fallback_type: String = "", is_absolute: bool = false) -> ImageTexture` is the only new runtime texture-loading API.
- The fallback type strings are exactly `card`, `character`, `enemy`, `icon`, and `background`.
- The regression references the same fallback filenames generated by `tools/generate_asset_fallbacks.gd`.

# 选关地图图标更新 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将选关地图节点从英文文字节点改为透明图标节点，并在右侧显示固定中文图例栏。

**Architecture:** 地图节点继续由 `Map.gd` 实例化 `MapLocation.tscn`，`MapLocation.gd` 负责按 `LocationData.LOCATION_TYPES` 选择图标。`Map.gd` 在 `_ready()` 中配置地图布局并创建右侧 `LegendPanel`，用同一份映射填充图例贴图和中文名，避免场景文件直接绑定 PNG 导入资源。

**Tech Stack:** Godot 4.6、GDScript、`SceneTree` 回归测试、外部 PNG 资源、内置 image generation + 本地 chroma-key 抠图。

---

## 文件结构

- Create: `external/sprites/ui/map_locations/map_location_combat.png`
- Create: `external/sprites/ui/map_locations/map_location_event.png`
- Create: `external/sprites/ui/map_locations/map_location_shop.png`
- Create: `external/sprites/ui/map_locations/map_location_miniboss.png`
- Create: `external/sprites/ui/map_locations/map_location_boss.png`
- Create: `external/sprites/ui/map_locations/map_location_rest_site.png`
- Create: `external/sprites/ui/map_locations/map_location_treasure.png`
- Create: `external/sprites/ui/map_locations/map_location_unknown.png`
- Create: `tests/map_location_icon_regression.gd`
- Modify: `scripts/ui/MapLocation.gd`
- Modify: `scenes/ui/MapLocation.tscn`
- Modify: `scripts/ui/Map.gd`
- Create: `tests/map_location_layout_regression.gd`

## Task 1: 准备透明地图图标资源

**Files:**
- Create: `external/sprites/ui/map_locations/*.png`

- [ ] **Step 1: 从源图裁出 6 个图标**

Run this script from the repository root:

```bash
python3 - <<'PY'
from pathlib import Path
from PIL import Image

source = Path("/Users/xietong/Desktop/ChatGPT Image 2026年7月4日 22_26_32.png")
out_dir = Path("external/sprites/ui/map_locations")
out_dir.mkdir(parents=True, exist_ok=True)

names = [
    "map_location_combat.png",
    "map_location_event.png",
    "map_location_shop.png",
    "map_location_miniboss.png",
    "map_location_boss.png",
    "map_location_rest_site.png",
]

img = Image.open(source).convert("RGBA")
cell_w = img.width // 3
cell_h = img.height // 2

def chroma_remove(cell: Image.Image) -> Image.Image:
    px = cell.load()
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = px[x, y]
            green_distance = abs(r - 0) + abs(g - 255) + abs(b - 0)
            if g > 180 and r < 90 and b < 90 and green_distance < 190:
                px[x, y] = (r, g, b, 0)
            elif g > 145 and g > r * 1.6 and g > b * 1.6:
                alpha = max(0, min(255, int((255 - g) * 2.2)))
                px[x, y] = (r, g, b, min(a, alpha))
    return cell

def trim_and_pad(cell: Image.Image, padding: int = 12) -> Image.Image:
    alpha = cell.getchannel("A")
    bbox = alpha.getbbox()
    if bbox == None:
        return Image.new("RGBA", (80, 80), (0, 0, 0, 0))
    trimmed = cell.crop(bbox)
    canvas = Image.new("RGBA", (trimmed.width + padding * 2, trimmed.height + padding * 2), (0, 0, 0, 0))
    canvas.alpha_composite(trimmed, (padding, padding))
    canvas.thumbnail((512, 512), Image.Resampling.LANCZOS)
    return canvas

for index, name in enumerate(names):
    col = index % 3
    row = index // 3
    left = col * cell_w
    top = row * cell_h
    right = img.width if col == 2 else (col + 1) * cell_w
    bottom = img.height if row == 1 else (row + 1) * cell_h
    cell = img.crop((left, top, right, bottom))
    final = trim_and_pad(chroma_remove(cell))
    final.save(out_dir / name)

print("CROPPED_MAP_LOCATION_ICONS")
PY
```

- [ ] **Step 2: 生成宝箱图标**

Use the imagegen skill with this prompt:

```text
Use case: stylized-concept
Asset type: Godot map location icon
Primary request: Create one treasure chest floating island icon in the same cute fantasy isometric style as the provided six map-location icons.
Input images: provided 2x3 map location sheet as style reference.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for background removal.
Subject: a small floating island with a golden treasure chest at the center, blue water rim, grass, stones, flowers, and light fantasy game polish.
Style/medium: bright stylized 2D game art, isometric floating island, matching the reference image scale and detail density.
Composition/framing: centered, full subject visible, generous padding.
Constraints: no text, no watermark, no cast shadow, no contact shadow, no gradients or texture in the magenta background, do not use #ff00ff in the subject.
```

Copy the generated source image into `tmp/imagegen/map_location_treasure_source.png`, then run:

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/imagegen/scripts/remove_chroma_key.py" \
  --input tmp/imagegen/map_location_treasure_source.png \
  --out tmp/imagegen/map_location_treasure_alpha.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill

python3 - <<'PY'
from pathlib import Path
from PIL import Image

src = Path("tmp/imagegen/map_location_treasure_alpha.png")
dst = Path("external/sprites/ui/map_locations/map_location_treasure.png")
dst.parent.mkdir(parents=True, exist_ok=True)
img = Image.open(src).convert("RGBA")
bbox = img.getchannel("A").getbbox()
if bbox == None:
    raise SystemExit("treasure icon has no opaque pixels")
trimmed = img.crop(bbox)
canvas = Image.new("RGBA", (trimmed.width + 24, trimmed.height + 24), (0, 0, 0, 0))
canvas.alpha_composite(trimmed, (12, 12))
canvas.thumbnail((512, 512), Image.Resampling.LANCZOS)
canvas.save(dst)
print("TREASURE_ICON_READY")
PY
```

- [ ] **Step 3: 创建未知图标**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
from PIL import Image

src = Path("sprites/ui/flipper/icon_map.png")
dst = Path("external/sprites/ui/map_locations/map_location_unknown.png")
dst.parent.mkdir(parents=True, exist_ok=True)
img = Image.open(src).convert("RGBA")
img.thumbnail((160, 160), Image.Resampling.LANCZOS)
canvas = Image.new("RGBA", (184, 184), (0, 0, 0, 0))
canvas.alpha_composite(img, ((canvas.width - img.width) // 2, (canvas.height - img.height) // 2))
canvas.save(dst)
print("UNKNOWN_ICON_READY")
PY
```

- [ ] **Step 4: Verify asset dimensions and alpha**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
from PIL import Image
base = Path("external/sprites/ui/map_locations")
files = [
    "map_location_combat.png", "map_location_event.png", "map_location_shop.png",
    "map_location_miniboss.png", "map_location_boss.png", "map_location_rest_site.png",
    "map_location_treasure.png", "map_location_unknown.png",
]
for name in files:
    img = Image.open(base / name)
    assert img.mode == "RGBA", f"{name} must be RGBA, got {img.mode}"
    assert img.size[0] <= 512 and img.size[1] <= 512, f"{name} too large: {img.size}"
    assert img.getpixel((0, 0))[3] == 0, f"{name} top-left corner is not transparent"
print("ALL_ASSETS_OK")
PY
```

Expected: `ALL_ASSETS_OK`。

## Task 2: TDD 地图节点按类型显示图标

**Files:**
- Create: `tests/map_location_icon_regression.gd`
- Modify: `scripts/ui/MapLocation.gd`
- Modify: `scenes/ui/MapLocation.tscn`

- [ ] **Step 1: Write the failing test**

Create `tests/map_location_icon_regression.gd`:

```gdscript
extends SceneTree

const EXPECTED_TEXTURES := {
	LocationData.LOCATION_TYPES.COMBAT: "external/sprites/ui/map_locations/map_location_combat.png",
	LocationData.LOCATION_TYPES.EVENT: "external/sprites/ui/map_locations/map_location_event.png",
	LocationData.LOCATION_TYPES.SHOP: "external/sprites/ui/map_locations/map_location_shop.png",
	LocationData.LOCATION_TYPES.MINIBOSS: "external/sprites/ui/map_locations/map_location_miniboss.png",
	LocationData.LOCATION_TYPES.BOSS: "external/sprites/ui/map_locations/map_location_boss.png",
	LocationData.LOCATION_TYPES.REST_SITE: "external/sprites/ui/map_locations/map_location_rest_site.png",
	LocationData.LOCATION_TYPES.TREASURE: "external/sprites/ui/map_locations/map_location_treasure.png",
}
const UNKNOWN_TEXTURE := "external/sprites/ui/map_locations/map_location_unknown.png"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for location_type in EXPECTED_TEXTURES.keys():
		await _assert_location_texture(location_type, EXPECTED_TEXTURES[location_type])

	await _assert_obfuscated_location_uses_unknown_texture()
	_assert_map_label_removed()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _assert_location_texture(location_type: int, expected_path: String) -> void:
	var map_location: MapLocation = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame

	var location_data := LocationData.new()
	location_data.location_type = location_type
	location_data.location_position = Vector2(40, 40)
	map_location.init(location_data)

	_assert_texture_path(map_location.texture_normal, expected_path, LocationData.LOCATION_TYPES.keys()[location_type])
	map_location.queue_free()
	await process_frame


func _assert_obfuscated_location_uses_unknown_texture() -> void:
	var map_location: MapLocation = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame

	var location_data := LocationData.new()
	location_data.location_type = LocationData.LOCATION_TYPES.BOSS
	location_data.location_obfuscated = true
	location_data.location_visited = false
	map_location.init(location_data)

	_assert_texture_path(map_location.texture_normal, UNKNOWN_TEXTURE, "obfuscated location")
	map_location.queue_free()
	await process_frame


func _assert_map_label_removed() -> void:
	var map_location: MapLocation = load("res://scenes/ui/MapLocation.tscn").instantiate()
	root.add_child(map_location)
	await process_frame
	if map_location.has_node("MapLabel"):
		failures.append("MapLocation should not keep the old MapLabel node")
	map_location.queue_free()
	await process_frame


func _assert_texture_path(texture: Texture2D, expected_path: String, label: String) -> void:
	if texture == null:
		failures.append("%s has no texture" % label)
		return
	if not texture.resource_path.ends_with(expected_path):
		failures.append("%s texture should end with %s, got %s" % [label, expected_path, texture.resource_path])
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/map_location_icon_regression.gd
```

Expected: FAIL because `MapLocation` still uses `icon_map.png` and still has `MapLabel`。

- [ ] **Step 3: Write minimal implementation**

Update `scripts/ui/MapLocation.gd` to this shape:

```gdscript
extends TextureButton
class_name MapLocation

const FALLBACK_TEXTURE_PATH := "sprites/ui/flipper/icon_map.png"
const UNKNOWN_TEXTURE_PATH := "external/sprites/ui/map_locations/map_location_unknown.png"
const LOCATION_TYPE_TO_TEXTURE_PATH := {
	LocationData.LOCATION_TYPES.COMBAT: "external/sprites/ui/map_locations/map_location_combat.png",
	LocationData.LOCATION_TYPES.EVENT: "external/sprites/ui/map_locations/map_location_event.png",
	LocationData.LOCATION_TYPES.SHOP: "external/sprites/ui/map_locations/map_location_shop.png",
	LocationData.LOCATION_TYPES.MINIBOSS: "external/sprites/ui/map_locations/map_location_miniboss.png",
	LocationData.LOCATION_TYPES.BOSS: "external/sprites/ui/map_locations/map_location_boss.png",
	LocationData.LOCATION_TYPES.REST_SITE: "external/sprites/ui/map_locations/map_location_rest_site.png",
	LocationData.LOCATION_TYPES.TREASURE: "external/sprites/ui/map_locations/map_location_treasure.png",
}

var location_data: LocationData = null
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal map_location_button_up(map_location: MapLocation)


func _ready():
	button_up.connect(_on_button_up)


func init(_location_data: LocationData):
	location_data = _location_data
	position = location_data.location_position
	texture_normal = _load_location_texture(_get_location_texture_path(location_data))


static func get_location_texture_path(_location_data: LocationData) -> String:
	if _location_data.location_obfuscated and not _location_data.location_visited:
		return UNKNOWN_TEXTURE_PATH
	return LOCATION_TYPE_TO_TEXTURE_PATH.get(_location_data.location_type, UNKNOWN_TEXTURE_PATH)


func flash_location() -> void:
	animation_player.play("flash_map_location")


func _load_location_texture(texture_path: String) -> Texture2D:
	var texture := FileLoader.load_texture(texture_path)
	if texture.resource_path == "":
		texture = FileLoader.load_texture(FALLBACK_TEXTURE_PATH)
	return texture


func _get_location_texture_path(_location_data: LocationData) -> String:
	return get_location_texture_path(_location_data)


func _on_button_up():
	location_data.location_visited = true
	map_location_button_up.emit(self)
```

Update `scenes/ui/MapLocation.tscn`:

```text
Remove the MapLabel node.
Set root offsets to 80x80.
Keep AnimationPlayer and flash_map_location animation.
Keep ignore_texture_size = true and use stretch_mode that scales the texture inside the button.
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/map_location_icon_regression.gd
```

Expected: PASS with `ALL_TESTS_PASSED`。

## Task 3: TDD 右侧图例栏与地图布局

**Files:**
- Create: `tests/map_location_layout_regression.gd`
- Modify: `scripts/ui/Map.gd`

- [ ] **Step 1: Write the failing layout test**

Create `tests/map_location_layout_regression.gd`:

```gdscript
extends SceneTree

const CANVAS_SIZE := Vector2(1200.0, 700.0)

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_scene: Node = load("res://scenes/Root.tscn").instantiate()
	root.add_child(root_scene)
	await process_frame
	await process_frame

	_check_map_layout(root_scene)

	root_scene.queue_free()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_map_layout(root_scene: Node) -> void:
	var map: Control = root_scene.get_node("RunScreen/Map")
	var scroll_container: Control = map.get_node("ScrollContainer")
	var legend_panel: Control = map.get_node("LegendPanel")
	var back_button: Control = map.get_node("BackButton")

	_assert_rect_inside_canvas(scroll_container, "Map scroll container")
	_assert_rect_inside_canvas(legend_panel, "Map legend panel")
	_assert_rect_inside_canvas(back_button, "Map back button")
	_assert_no_overlap(scroll_container, legend_panel, "Map scroll container", "Map legend panel")
	_assert_no_overlap(back_button, legend_panel, "Map back button", "Map legend panel")

	if legend_panel.get_child_count() != 7:
		failures.append("Map legend should contain 7 entries, got %s" % legend_panel.get_child_count())


func _assert_rect_inside_canvas(control: Control, label: String) -> void:
	var rect := control.get_global_rect()
	if rect.position.x < 0.0 or rect.position.y < 0.0:
		failures.append("%s starts outside the canvas: %s" % [label, rect])
	if rect.position.x + rect.size.x > CANVAS_SIZE.x:
		failures.append("%s extends past canvas width: %s" % [label, rect])
	if rect.position.y + rect.size.y > CANVAS_SIZE.y:
		failures.append("%s extends past canvas height: %s" % [label, rect])


func _assert_no_overlap(first: Control, second: Control, first_label: String, second_label: String) -> void:
	if first.get_global_rect().intersects(second.get_global_rect()):
		failures.append("%s overlaps %s" % [first_label, second_label])
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/map_location_layout_regression.gd
```

Expected: FAIL because `RunScreen/Map/LegendPanel` does not exist yet。

- [ ] **Step 3: Add runtime legend container and fill it from Map.gd**

Modify `scripts/ui/Map.gd` to configure map layout and create `LegendPanel` at runtime:

```gdscript
@onready var background_panel: ColorRect = $Background2

var legend_panel: VBoxContainer = null

const MAP_SCROLL_POSITION := Vector2(96, 72)
const MAP_SCROLL_SIZE := Vector2(834, 584)
const MAP_LEGEND_POSITION := Vector2(960, 88)
const MAP_LEGEND_SIZE := Vector2(188, 524)
const MAP_BACK_BUTTON_POSITION := Vector2(32, 32)
const MAP_BACK_BUTTON_SIZE := Vector2(96, 32)
const MAP_BACKGROUND_PANEL_OFFSET_LEFT: float = -504
const MAP_BACKGROUND_PANEL_OFFSET_RIGHT: float = 548

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
	map_button.button_up.connect(_on_map_button_up)
	back_button.button_up.connect(_on_back_button_up)
	_populate_legend_panel()
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
```

- [ ] **Step 4: Run layout test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/map_location_layout_regression.gd
```

Expected: PASS with `ALL_TESTS_PASSED`。

## Task 4: 集成验证与提交

**Files:**
- All files changed in Tasks 1-3

- [ ] **Step 1: Run map icon regression**

Run:

```bash
godot --headless --path . --script tests/map_location_icon_regression.gd
```

Expected: PASS with `ALL_TESTS_PASSED`。

- [ ] **Step 2: Run layout regression**

Run:

```bash
godot --headless --path . --script tests/map_location_layout_regression.gd
```

Expected: PASS with `ALL_TESTS_PASSED`。

- [ ] **Step 3: Run project load check**

Run:

```bash
godot --headless --path . --quit
```

Expected: exit 0 without scene resource errors。

- [ ] **Step 4: Review changed files**

Run:

```bash
git status --short external/sprites/ui/map_locations scripts/ui/MapLocation.gd scenes/ui/MapLocation.tscn scripts/ui/Map.gd tests/map_location_icon_regression.gd tests/map_location_layout_regression.gd docs/superpowers/plans/2026-07-04-map-location-icons.md
```

Expected: only the intended files from this plan are listed, plus Godot-generated `.uid` files if the editor/runtime creates them for new tests。

- [ ] **Step 5: Commit**

Run:

```bash
git add external/sprites/ui/map_locations scripts/ui/MapLocation.gd scenes/ui/MapLocation.tscn scripts/ui/Map.gd tests/map_location_icon_regression.gd tests/map_location_layout_regression.gd docs/superpowers/plans/2026-07-04-map-location-icons.md
git commit -m "Refresh map location icons"
```

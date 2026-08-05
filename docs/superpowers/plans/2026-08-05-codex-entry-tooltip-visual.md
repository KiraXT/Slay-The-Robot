# 图鉴条目与 Tooltip 底框视觉优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将图鉴敌人/遗物灰色底板替换为项目 UI 风格的浅色卡片底座，并把所有通用 tooltip 改成紧凑深色信息框。

**Architecture:** 使用一个 `TooltipFactory` 统一生成自定义 tooltip，现有 `Tooltip.tscn` / `KeywordTooltip.tscn` 负责显示外观。图鉴条目继续由 `CodexMenu.gd` 运行时创建，但显式注入 `StyleBoxFlat` 底板样式；全局默认 `tooltip_text` 通过主题的 `TooltipPanel` / `TooltipLabel` 样式兜底。

**Tech Stack:** Godot 4、GDScript、`.tscn` 场景、`.tres` Theme 资源、headless `SceneTree` 回归测试。

## Global Constraints

- 去掉敌人和遗物图鉴条目的默认灰色面板，替换为符合当前 UI 的物件卡片底座。
- 将通用悬浮说明框改为紧凑、可读、遮挡更少的深色信息框，参考《杀戮尖塔》的说明框比例。
- 保持现有数据驱动内容不变，不改敌人、遗物、卡牌 JSON。
- 控制改动范围，避免影响卡牌本体渲染和战斗逻辑。
- 不引入新的图片九宫格资源，首版使用 Godot 样式框完成底板。

---

## File Structure

- Create: `scripts/ui/general/TooltipFactory.gd`
  - 负责把普通 `tooltip_text` 转成统一的 BBCode，并实例化 `Tooltip.tscn`。
- Create: `scripts/ui/general/StyledTooltipPanel.gd`
  - 负责让运行时创建的 `PanelContainer` 条目也能返回统一自定义 tooltip。
- Modify: `scripts/ui/general/Tooltip.gd`
  - 增加正确拼写的 `set_tooltip_bb_code()`，保留现有 `set_tooptip_bb_code()` 兼容入口。
- Modify: `scenes/ui/general/Tooltip.tscn`
  - 调整宽度、RichTextLabel 自动换行和滚动行为。
- Modify: `scenes/ui/general/KeywordTooltip.tscn`
  - 与普通 tooltip 使用同样宽度和换行约束。
- Modify: `themes/keyword_tooltip_theme.tres`
  - 把 tooltip panel 改为深色信息框，文字改为浅色。
- Modify: `themes/title_screen_theme.tres`
  - 增加默认 Godot tooltip 的深色兜底样式。
- Modify: `themes/run_screen_theme.tres`
  - 增加默认 Godot tooltip 的深色兜底样式。
- Modify: `scripts/ui/menus/CodexMenu.gd`
  - 为敌人/遗物条目添加浅色卡片底座、图片区底托和自定义 tooltip。
- Modify: `scripts/ui/Artifact.gd`
  - 为战斗顶部遗物的 `tooltip_text` 提供统一自定义 tooltip。
- Modify: `scripts/ui/ConsumableButton.gd`
  - 为消耗品 tooltip 提供统一自定义 tooltip。
- Modify: `scripts/combatants/StatusEffect.gd`
  - 为状态图标 tooltip 提供统一自定义 tooltip。
- Modify: `scripts/ui/CustomRunModifierCheckbox.gd`
  - 为自定义模式说明提供统一自定义 tooltip。
- Create: `tests/codex_tooltip_visual_regression.gd`
  - 验证图鉴条目底板、tooltip scene 尺寸、theme 样式和自定义 tooltip 工厂。

---

### Task 1: Tooltip 主题与工厂

**Files:**
- Create: `scripts/ui/general/TooltipFactory.gd`
- Modify: `scripts/ui/general/Tooltip.gd`
- Modify: `scenes/ui/general/Tooltip.tscn`
- Modify: `scenes/ui/general/KeywordTooltip.tscn`
- Modify: `themes/keyword_tooltip_theme.tres`
- Modify: `themes/title_screen_theme.tres`
- Modify: `themes/run_screen_theme.tres`
- Create: `tests/codex_tooltip_visual_regression.gd`

**Interfaces:**
- Consumes: `Scenes.TOOLTIP` continues to point at `res://scenes/ui/general/Tooltip.tscn`.
- Produces: `TooltipFactory.create_text_tooltip(text: String) -> Control`
- Produces: `TooltipFactory.format_plain_text_tooltip(text: String) -> String`
- Produces: `Tooltip.set_tooltip_bb_code(bb_code: String) -> void`
- Produces: `Tooltip.set_tooptip_bb_code(bb_code: String) -> void` remains as compatibility alias.

- [ ] **Step 1: Write the failing test**

Create `tests/codex_tooltip_visual_regression.gd` with this initial content:

```gdscript
extends SceneTree

const TOOLTIP_SCENE_PATH := "res://scenes/ui/general/Tooltip.tscn"
const KEYWORD_TOOLTIP_SCENE_PATH := "res://scenes/ui/general/KeywordTooltip.tscn"
const KEYWORD_THEME_PATH := "res://themes/keyword_tooltip_theme.tres"
const TITLE_THEME_PATH := "res://themes/title_screen_theme.tres"
const RUN_THEME_PATH := "res://themes/run_screen_theme.tres"
const TOOLTIP_FACTORY_PATH := "res://scripts/ui/general/TooltipFactory.gd"
const EXPECTED_TOOLTIP_WIDTH_MIN := 248.0
const EXPECTED_TOOLTIP_WIDTH_MAX := 272.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_tooltip_scene(load(TOOLTIP_SCENE_PATH).instantiate(), "Tooltip.tscn")
	_assert_tooltip_scene(load(KEYWORD_TOOLTIP_SCENE_PATH).instantiate(), "KeywordTooltip.tscn")
	_assert_tooltip_theme(load(KEYWORD_THEME_PATH), "keyword tooltip theme", true)
	_assert_tooltip_theme(load(TITLE_THEME_PATH), "title screen theme", false)
	_assert_tooltip_theme(load(RUN_THEME_PATH), "run screen theme", false)
	_assert_tooltip_factory()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _assert_tooltip_scene(tooltip: Control, label: String) -> void:
	if tooltip.custom_minimum_size.x < EXPECTED_TOOLTIP_WIDTH_MIN or tooltip.custom_minimum_size.x > EXPECTED_TOOLTIP_WIDTH_MAX:
		failures.append("%s width must stay near 260px, got %.1f" % [label, tooltip.custom_minimum_size.x])
	var rich_text_label: RichTextLabel = tooltip.get_node_or_null("RichTextLabel")
	if rich_text_label == null:
		failures.append("%s must contain RichTextLabel" % label)
	else:
		if rich_text_label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			failures.append("%s RichTextLabel must autowrap" % label)
		if rich_text_label.scroll_active:
			failures.append("%s RichTextLabel scrolling must stay disabled" % label)
	tooltip.queue_free()


func _assert_tooltip_theme(theme: Theme, label: String, panel_container: bool) -> void:
	var style_type := "TooltipPanel"
	if panel_container:
		style_type = "PanelContainer"
	if not theme.has_stylebox("panel", style_type):
		failures.append("%s must explicitly provide %s/panel" % [label, style_type])
		return
	var panel_style := theme.get_stylebox("panel", style_type)
	if panel_style is not StyleBoxFlat:
		failures.append("%s must provide StyleBoxFlat for %s/panel" % [label, style_type])
		return
	var flat := panel_style as StyleBoxFlat
	if flat.bg_color.r > 0.22 or flat.bg_color.g > 0.26 or flat.bg_color.b > 0.32:
		failures.append("%s tooltip background must be dark, got %s" % [label, flat.bg_color])
	if flat.content_margin_left < 8.0 or flat.content_margin_left > 14.0:
		failures.append("%s tooltip left margin must be compact, got %.1f" % [label, flat.content_margin_left])
	if flat.border_width_bottom < 1:
		failures.append("%s tooltip must keep a visible border" % label)


func _assert_tooltip_factory() -> void:
	var factory: Script = load(TOOLTIP_FACTORY_PATH)
	if factory == null:
		failures.append("TooltipFactory.gd must load")
		return
	var tooltip: Control = factory.create_text_tooltip("攻击格挡\n每进行3次攻击获得5点格挡")
	if tooltip == null:
		failures.append("TooltipFactory.create_text_tooltip must return a Control")
		return
	var rich_text_label: RichTextLabel = tooltip.get_node_or_null("RichTextLabel")
	if rich_text_label == null:
		failures.append("factory tooltip must contain RichTextLabel")
	else:
		if not rich_text_label.get_parsed_text().contains("攻击格挡"):
			failures.append("factory tooltip must preserve the title text")
		if not rich_text_label.get_parsed_text().contains("每进行3次攻击获得5点格挡"):
			failures.append("factory tooltip must preserve the body text")
	tooltip.queue_free()
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

Expected: FAIL because `TooltipFactory.gd` does not exist yet and tooltip themes still use the old light/default style.

- [ ] **Step 3: Implement tooltip factory and scene constraints**

Create `scripts/ui/general/TooltipFactory.gd`:

```gdscript
extends RefCounted
class_name TooltipFactory

const TOOLTIP_SCENE := preload("res://scenes/ui/general/Tooltip.tscn")
const TITLE_COLOR := "#f7d27a"
const BODY_COLOR := "#dbe7ee"


static func create_text_tooltip(text: String) -> Control:
	var tooltip: Control = TOOLTIP_SCENE.instantiate()
	if tooltip.has_method("set_tooltip_bb_code"):
		tooltip.call("set_tooltip_bb_code", format_plain_text_tooltip(text))
	return tooltip


static func format_plain_text_tooltip(text: String) -> String:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return ""
	var lines := cleaned.split("\n", false)
	var title := _escape_bbcode(lines[0].strip_edges())
	var bb_code := "[color=%s][b]%s[/b][/color]" % [TITLE_COLOR, title]
	var body_lines := PackedStringArray()
	for index in range(1, lines.size()):
		var line := lines[index].strip_edges()
		if line != "":
			body_lines.append(_escape_bbcode(line))
	if not body_lines.is_empty():
		bb_code += "\n[color=%s]%s[/color]" % [BODY_COLOR, body_lines.join("\n")]
	return bb_code


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")
```

Modify `scripts/ui/general/Tooltip.gd`:

```gdscript
# tooltip displaying info
extends PanelContainer

@onready var rich_text_label: RichTextLabel = $RichTextLabel


func set_tooltip_bb_code(bb_code: String) -> void:
	rich_text_label.parse_bbcode(bb_code)


func set_tooptip_bb_code(bb_code: String) -> void:
	set_tooltip_bb_code(bb_code)
```

In both `Tooltip.tscn` and `KeywordTooltip.tscn`:

```text
custom_minimum_size = Vector2(260, 0)
```

For each `RichTextLabel` node in those scenes:

```text
autowrap_mode = 2
fit_content = true
scroll_active = false
```

- [ ] **Step 4: Implement dark tooltip theme resources**

In `themes/keyword_tooltip_theme.tres`, add a dark `StyleBoxFlat` panel style for `PanelContainer/styles/panel`:

```text
bg_color = Color(0.0588235, 0.0784314, 0.105882, 0.94)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 3
border_color = Color(0.968627, 0.760784, 0.360784, 0.95)
corner_radius_top_left = 7
corner_radius_top_right = 7
corner_radius_bottom_right = 7
corner_radius_bottom_left = 7
shadow_color = Color(0, 0, 0, 0.3)
shadow_size = 7
shadow_offset = Vector2(0, 3)
content_margin_left = 11.0
content_margin_top = 8.0
content_margin_right = 11.0
content_margin_bottom = 9.0
```

Also set:

```text
RichTextLabel/colors/default_color = Color(0.858824, 0.905882, 0.933333, 1)
RichTextLabel/font_sizes/normal_font_size = 12
```

In both `themes/title_screen_theme.tres` and `themes/run_screen_theme.tres`, add a matching `StyleBoxFlat_tooltip_panel` sub-resource and these resource entries:

```text
TooltipLabel/colors/font_color = Color(0.858824, 0.905882, 0.933333, 1)
TooltipLabel/font_sizes/font_size = 12
TooltipPanel/styles/panel = SubResource("StyleBoxFlat_tooltip_panel")
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/general/TooltipFactory.gd scripts/ui/general/Tooltip.gd scenes/ui/general/Tooltip.tscn scenes/ui/general/KeywordTooltip.tscn themes/keyword_tooltip_theme.tres themes/title_screen_theme.tres themes/run_screen_theme.tres tests/codex_tooltip_visual_regression.gd
git commit -m "style: add compact tooltip shell"
```

---

### Task 2: 图鉴敌人/遗物条目底板

**Files:**
- Modify: `scripts/ui/menus/CodexMenu.gd`
- Create: `scripts/ui/general/StyledTooltipPanel.gd`
- Modify: `tests/codex_tooltip_visual_regression.gd`

**Interfaces:**
- Consumes: `TooltipFactory.create_text_tooltip(text: String) -> Control`
- Produces: `_create_base_codex_entry(accent_color: Color = CODEX_ACCENT_CYAN) -> PanelContainer`
- Produces: `_create_codex_image_panel(texture_path: String) -> PanelContainer`
- Produces: `_create_codex_tooltip(text: String) -> Control`

- [ ] **Step 1: Extend the failing test for codex entry shells**

Append this call inside `_run()` after `_assert_tooltip_factory()`:

```gdscript
	await _assert_codex_entry_shells()
```

Append these helper methods:

```gdscript
func _assert_codex_entry_shells() -> void:
	var packed: PackedScene = load("res://scenes/ui/menus/TitleScreen.tscn")
	var title_screen: Control = packed.instantiate()
	root.add_child(title_screen)
	await process_frame
	var codex_menu: Control = title_screen.get_node("CodexMenu")

	codex_menu.populate_codex_enemy_container()
	await process_frame
	_assert_first_codex_entry(codex_menu, "enemy codex entry")

	codex_menu.populate_codex_artifact_container()
	await process_frame
	_assert_first_codex_entry(codex_menu, "artifact codex entry")

	title_screen.queue_free()


func _assert_first_codex_entry(codex_menu: Control, label: String) -> void:
	var grid: GridContainer = codex_menu.get_node("ScrollContainer/MarginContainer/CodexCardContainer")
	if grid.get_child_count() == 0:
		failures.append("%s must create at least one entry" % label)
		return
	var entry: PanelContainer = grid.get_child(0)
	if not entry.has_theme_stylebox_override("panel"):
		failures.append("%s must override its panel style" % label)
	else:
		var style := entry.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			failures.append("%s panel style must be StyleBoxFlat" % label)
		elif style.bg_color.a < 0.90 or style.bg_color.r < 0.85:
			failures.append("%s panel must use a light card shell, got %s" % [label, style.bg_color])
	if not entry.has_node("MarginContainer/VBoxContainer/ImagePanel"):
		failures.append("%s must provide ImagePanel for icon staging" % label)
	if not entry.has_method("_make_custom_tooltip"):
		failures.append("%s must provide custom tooltip method" % label)
	var tooltip: Control = entry.call("_make_custom_tooltip", entry.tooltip_text)
	if tooltip == null:
		failures.append("%s custom tooltip must return a Control" % label)
	else:
		tooltip.queue_free()
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

Expected: FAIL because codex entries do not yet override panel styles, do not have `ImagePanel`, and do not expose custom tooltip generation.

- [ ] **Step 3: Add codex shell constants and helper script usage**

In `scripts/ui/menus/CodexMenu.gd`, add constants near the existing size constants:

```gdscript
const CODEX_ACCENT_CYAN := Color(0.133333, 0.831373, 0.839216, 1.0)
const CODEX_ACCENT_GOLD := Color(0.968627, 0.760784, 0.360784, 1.0)
const CODEX_PANEL_BG := Color(1.0, 1.0, 1.0, 0.94)
const CODEX_IMAGE_BG := Color(0.894118, 0.980392, 0.980392, 0.76)
const CODEX_TEXT_MUTED := Color(0.258824, 0.337255, 0.384314, 1.0)
```

Create `scripts/ui/general/StyledTooltipPanel.gd`:

```gdscript
extends PanelContainer
class_name StyledTooltipPanel


func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.create_text_tooltip(for_text)
```

Update the task file list and commit command to include `scripts/ui/general/StyledTooltipPanel.gd`.

- [ ] **Step 4: Implement codex entry style helpers**

Replace `_create_base_codex_entry()` with:

```gdscript
func _create_base_codex_entry(accent_color: Color = CODEX_ACCENT_CYAN) -> PanelContainer:
	var panel := StyledTooltipPanel.new()
	panel.custom_minimum_size = CODEX_ENTRY_SIZE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", _create_codex_entry_style(accent_color))

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "VBoxContainer"
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	return panel
```

Add:

```gdscript
func _create_codex_entry_style(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CODEX_PANEL_BG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.border_color = accent_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0.0745098, 0.384314, 0.439216, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _create_codex_image_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CODEX_IMAGE_BG
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.82)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style
```

- [ ] **Step 5: Implement image panel and muted labels**

Replace `_create_codex_texture()` with `_create_codex_image_panel()`:

```gdscript
func _create_codex_image_panel(texture_path: String) -> PanelContainer:
	var image_panel := PanelContainer.new()
	image_panel.name = "ImagePanel"
	image_panel.custom_minimum_size = CODEX_IMAGE_SIZE
	image_panel.add_theme_stylebox_override("panel", _create_codex_image_style())

	var texture_rect := TextureRect.new()
	texture_rect.name = "TextureRect"
	texture_rect.custom_minimum_size = CODEX_IMAGE_SIZE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = FileLoader.load_texture(texture_path)
	image_panel.add_child(texture_rect)
	return image_panel
```

Update enemy/artifact entry creation:

```gdscript
var texture_panel := _create_codex_image_panel(enemy_data.enemy_texture_path)
content.add_child(texture_panel)
```

and:

```gdscript
var texture_panel := _create_codex_image_panel(artifact_data.artifact_texture_path)
content.add_child(texture_panel)
```

In `_create_codex_label()`, add muted color for small labels:

```gdscript
if font_size <= 13:
	label.add_theme_color_override("font_color", CODEX_TEXT_MUTED)
```

- [ ] **Step 6: Wire custom tooltip content**

Keep `entry.tooltip_text` content equivalent to the current text. Do not remove existing enemy HP, enemy type, rarity, or artifact description. Because entries are now `StyledTooltipPanel`, no extra method is needed in `CodexMenu.gd`.

- [ ] **Step 7: Run test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add scripts/ui/menus/CodexMenu.gd scripts/ui/general/StyledTooltipPanel.gd tests/codex_tooltip_visual_regression.gd
git commit -m "style: refresh codex entry panels"
```

---

### Task 3: 通用控件自定义 tooltip 接入

**Files:**
- Modify: `scripts/ui/Artifact.gd`
- Modify: `scripts/ui/ConsumableButton.gd`
- Modify: `scripts/combatants/StatusEffect.gd`
- Modify: `scripts/ui/CustomRunModifierCheckbox.gd`
- Modify: `tests/codex_tooltip_visual_regression.gd`

**Interfaces:**
- Consumes: `TooltipFactory.create_text_tooltip(text: String) -> Control`
- Produces: `_make_custom_tooltip(for_text: String) -> Object` on each scripted tooltip-bearing control.

- [ ] **Step 1: Extend failing test for scripted tooltip providers**

Append this call inside `_run()` after `_assert_tooltip_factory()`:

```gdscript
	_assert_scripted_tooltip_providers()
```

Append:

```gdscript
func _assert_scripted_tooltip_providers() -> void:
	var script_paths := [
		"res://scripts/ui/Artifact.gd",
		"res://scripts/ui/ConsumableButton.gd",
		"res://scripts/combatants/StatusEffect.gd",
		"res://scripts/ui/CustomRunModifierCheckbox.gd",
	]
	for path: String in script_paths:
		var script: Script = load(path)
		if script == null:
			failures.append("%s must load" % path)
			continue
		if not script.source_code.contains("func _make_custom_tooltip"):
			failures.append("%s must explicitly implement _make_custom_tooltip" % path)
			continue
		var instance: Object = script.new()
		if not instance.has_method("_make_custom_tooltip"):
			failures.append("%s must implement _make_custom_tooltip" % path)
		else:
			var tooltip: Control = instance.call("_make_custom_tooltip", "标题\n说明")
			if tooltip == null:
				failures.append("%s _make_custom_tooltip must return a Control" % path)
			else:
				tooltip.queue_free()
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

Expected: FAIL because the four scripts do not yet implement `_make_custom_tooltip`.

- [ ] **Step 3: Add `_make_custom_tooltip` to tooltip-bearing scripts**

In each of these files:

- `scripts/ui/Artifact.gd`
- `scripts/ui/ConsumableButton.gd`
- `scripts/combatants/StatusEffect.gd`
- `scripts/ui/CustomRunModifierCheckbox.gd`

Add this method near the bottom:

```gdscript
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.create_text_tooltip(for_text)
```

Do not change existing `tooltip_text` assignment logic.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

Expected: PASS.

- [ ] **Step 5: Run broad UI validation**

Run:

```bash
godot --headless --path . --script tests/title_screen_performance_regression.gd
godot --headless --path . --script tests/ui_layout_bounds_regression.gd
godot --headless --path . --quit
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/Artifact.gd scripts/ui/ConsumableButton.gd scripts/combatants/StatusEffect.gd scripts/ui/CustomRunModifierCheckbox.gd tests/codex_tooltip_visual_regression.gd
git commit -m "style: use compact tooltips across UI"
```

---

## Final Verification

- [ ] Run focused regression:

```bash
godot --headless --path . --script tests/codex_tooltip_visual_regression.gd
```

- [ ] Run existing title and layout regressions:

```bash
godot --headless --path . --script tests/title_screen_performance_regression.gd
godot --headless --path . --script tests/ui_layout_bounds_regression.gd
```

- [ ] Run project load smoke test:

```bash
godot --headless --path . --quit
```

- [ ] Check formatting:

```bash
git diff --check
```

- [ ] Inspect final touched files:

```bash
git status --short scripts/ui/general/TooltipFactory.gd scripts/ui/general/StyledTooltipPanel.gd scripts/ui/general/Tooltip.gd scenes/ui/general/Tooltip.tscn scenes/ui/general/KeywordTooltip.tscn themes/keyword_tooltip_theme.tres themes/title_screen_theme.tres themes/run_screen_theme.tres scripts/ui/menus/CodexMenu.gd scripts/ui/Artifact.gd scripts/ui/ConsumableButton.gd scripts/combatants/StatusEffect.gd scripts/ui/CustomRunModifierCheckbox.gd tests/codex_tooltip_visual_regression.gd docs/superpowers/plans/2026-08-05-codex-entry-tooltip-visual.md
```

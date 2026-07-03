# Card Template Visual Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有卡牌 UI 改成已批准的 B 方案“弹射世界式亮色模块”：费用、卡名、卡图、类型、效果、星级、阵营徽记位置稳定，且中文文本不超框。

**Architecture:** 保持 `Card.tscn` 作为唯一卡牌视觉场景，`Card.gd.update_card_display()` 作为唯一刷新入口。数据仍由现有 `CardData` 字段驱动，不新增 JSON 必填字段；阵营、星级、中文类型文本由 `card_color_id`、`card_rarity`、`card_type` 派生。新增一个 Godot headless 回归测试覆盖显示映射和核心节点边界。

**Tech Stack:** Godot 4、GDScript、`.tscn` 场景资源、现有 `RichLabelAutoSizer`、Godot headless SceneTree tests。

---

## 文件结构

- Create: `tests/card_template_visual_regression.gd`
  - 负责实例化 `scenes/ui/Card.tscn`，用多组 `CardData` 验证阵营、星级、中文类型、费用文本和关键节点边界。
- Modify: `scripts/ui/Card.gd`
  - 负责新增卡牌视觉 helper：类型中文名、星级文本、阵营徽记、颜色派生和新版节点绑定。
- Modify: `scenes/ui/Card.tscn`
  - 负责重排卡牌节点：亮色外框、费用圆章、卡名条、阵营徽记、卡图、类型条、描述区、底部星级。

实现前注意：当前工作区已有用户/生成的未提交改动，且 `scenes/ui/Card.tscn` 已有一处资源变更：

```diff
-[ext_resource type="Texture2D" uid="uid://nh32y87hcke5" path="res://icon.svg" id="1_7f6u3"]
+[ext_resource type="Texture2D" path="res://sprites/ui/flipper/icon_deck.png" id="1_7f6u3"]
```

保留这处变更，不要恢复为 `res://icon.svg`。

---

### Task 1: 添加卡牌视觉回归测试

**Files:**
- Create: `tests/card_template_visual_regression.gd`

- [ ] **Step 1: 创建失败测试**

创建 `tests/card_template_visual_regression.gd`，内容如下：

```gdscript
extends SceneTree

const CARD_SCENE_PATH := "res://scenes/ui/Card.tscn"
const CARD_SIZE := Vector2(144.0, 184.0)

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_visual_mappings()
	await _check_layout_bounds()

	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _check_visual_mappings() -> void:
	var cases := [
		{
			"name": "red basic attack",
			"color_id": "color_red",
			"type": CardData.CARD_TYPES.ATTACK,
			"rarity": CardData.CARD_RARITIES.BASIC,
			"faction": "拳",
			"stars": "★",
			"type_label": "攻击",
			"energy": "1",
		},
		{
			"name": "green common skill",
			"color_id": "color_green",
			"type": CardData.CARD_TYPES.SKILL,
			"rarity": CardData.CARD_RARITIES.COMMON,
			"faction": "藤",
			"stars": "★★",
			"type_label": "技能",
			"energy": "2",
		},
		{
			"name": "blue uncommon power",
			"color_id": "color_blue",
			"type": CardData.CARD_TYPES.POWER,
			"rarity": CardData.CARD_RARITIES.UNCOMMON,
			"faction": "流",
			"stars": "★★★",
			"type_label": "能力",
			"energy": "X",
		},
		{
			"name": "orange rare status",
			"color_id": "color_orange",
			"type": CardData.CARD_TYPES.STATUS,
			"rarity": CardData.CARD_RARITIES.RARE,
			"faction": "械",
			"stars": "★★★★",
			"type_label": "状态",
			"energy": "3",
		},
		{
			"name": "purple generated curse",
			"color_id": "color_purple",
			"type": CardData.CARD_TYPES.CURSE,
			"rarity": CardData.CARD_RARITIES.GENERATED,
			"faction": "蚀",
			"stars": "",
			"type_label": "诅咒",
			"energy": "0",
		},
	]

	for case_data in cases:
		var card := await _render_card(case_data)
		_assert_label(card, "Pivot/CardVisual/CardFaction/CardFactionText", case_data["faction"], "%s faction" % case_data["name"])
		_assert_label(card, "Pivot/CardVisual/CardStars", case_data["stars"], "%s stars" % case_data["name"])
		_assert_label(card, "Pivot/CardVisual/CardTypeBackground/CardType", case_data["type_label"], "%s type" % case_data["name"])
		_assert_label(card, "Pivot/CardVisual/EnergySprite/EnergyCost", case_data["energy"], "%s energy" % case_data["name"])
		card.queue_free()
		await process_frame


func _check_layout_bounds() -> void:
	var card := await _render_card({
		"name": "long text",
		"color_id": "color_white",
		"type": CardData.CARD_TYPES.SKILL,
		"rarity": CardData.CARD_RARITIES.RARE,
		"energy": "1",
	})

	var visual := card.get_node("Pivot/CardVisual") as Control
	for path in [
		"CardName",
		"CardTexture",
		"CardTypeBackground",
		"CardDescription",
		"CardStars",
		"CardFaction",
	]:
		_assert_local_rect_inside(visual, visual.get_node(path) as Control, path)

	card.queue_free()
	await process_frame


func _render_card(case_data: Dictionary) -> Card:
	var packed_scene := load(CARD_SCENE_PATH) as PackedScene
	var card := packed_scene.instantiate() as Card
	root.add_child(card)

	var data := CardData.new()
	data.card_name = "超长卡名测试用例"
	data.card_description = "这是一段很长的中文描述，用于确认效果文本区域不会覆盖类型条、星级条或卡牌边框。"
	data.card_color_id = case_data["color_id"]
	data.card_type = case_data["type"]
	data.card_rarity = case_data["rarity"]
	data.card_energy_cost = int(case_data.get("energy", "1")) if str(case_data.get("energy", "1")).is_valid_int() else 1
	data.card_energy_cost_is_variable = case_data.get("energy", "") == "X"
	data.card_requires_target = false
	data.card_texture_path = ""

	card.init(data, 0.0, false, false)
	await process_frame
	await process_frame
	return card


func _assert_label(card: Card, path: NodePath, expected: String, label: String) -> void:
	if not card.has_node(path):
		failures.append("%s missing node %s" % [label, path])
		return

	var node := card.get_node(path) as Label
	if node == null:
		failures.append("%s node %s is not a Label" % [label, path])
		return

	if node.text != expected:
		failures.append("%s expected `%s`, got `%s`" % [label, expected, node.text])


func _assert_local_rect_inside(parent: Control, child: Control, label: String) -> void:
	if child == null:
		failures.append("%s is missing" % label)
		return

	var rect := child.get_rect()
	if rect.position.x < 0.0 or rect.position.y < 0.0:
		failures.append("%s starts outside card: %s" % [label, rect])
		return

	if rect.position.x + rect.size.x > CARD_SIZE.x:
		failures.append("%s exceeds card width: %s" % [label, rect])

	if rect.position.y + rect.size.y > CARD_SIZE.y:
		failures.append("%s exceeds card height: %s" % [label, rect])
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
godot --headless --path . -s tests/card_template_visual_regression.gd
```

Expected: FAIL，至少包含缺少 `Pivot/CardVisual/CardFaction/CardFactionText` 或 `Pivot/CardVisual/CardStars` 的错误，因为新版节点尚未实现。

- [ ] **Step 3: 提交测试**

```bash
git add tests/card_template_visual_regression.gd
git commit -m "Add card template visual regression test"
```

---

### Task 2: 扩展 Card.gd 的显示映射

**Files:**
- Modify: `scripts/ui/Card.gd`

- [ ] **Step 1: 添加常量和节点绑定**

在 `const ENERGY_ICON_KEYWORD` 后添加：

```gdscript
const CARD_TYPE_LABELS: Dictionary = {
	CardData.CARD_TYPES.ATTACK: "攻击",
	CardData.CARD_TYPES.SKILL: "技能",
	CardData.CARD_TYPES.POWER: "能力",
	CardData.CARD_TYPES.STATUS: "状态",
	CardData.CARD_TYPES.CURSE: "诅咒",
}

const CARD_RARITY_STARS: Dictionary = {
	CardData.CARD_RARITIES.BASIC: "★",
	CardData.CARD_RARITIES.COMMON: "★★",
	CardData.CARD_RARITIES.UNCOMMON: "★★★",
	CardData.CARD_RARITIES.RARE: "★★★★",
	CardData.CARD_RARITIES.GENERATED: "",
}

const CARD_FACTION_LABELS: Dictionary = {
	"color_red": "拳",
	"color_green": "藤",
	"color_blue": "流",
	"color_orange": "械",
	"color_white": "核",
	"color_purple": "蚀",
}

const CARD_DEFAULT_FRAME_COLOR: Color = Color(0.86, 0.88, 0.92, 1.0)
```

在现有 `@onready` 区域调整节点绑定为：

```gdscript
@onready var card_texture: TextureRect = %CardTexture
@onready var card_name: RichLabelAutoSizer = %CardName
@onready var card_type: Label = %CardType
@onready var card_description: RichLabelAutoSizer = %CardDescription
@onready var card_energy_cost: Label = %EnergyCost
@onready var card_color: ColorRect = %ColorBackground
@onready var card_background: ColorRect = %CardBackground
@onready var card_type_background: ColorRect = %CardTypeBackground
@onready var card_faction_background: ColorRect = %CardFaction
@onready var card_faction_text: Label = %CardFactionText
@onready var card_stars: Label = %CardStars
@onready var energy_sprite: ColorRect = %EnergySprite
```

- [ ] **Step 2: 更新 `update_card_display()`**

将 `card_type.text = ...` 和颜色设置区域替换为：

```gdscript
	card_type.text = _get_card_type_label(card_data.card_type)
	card_faction_text.text = _get_card_faction_label(card_data.card_color_id)
	card_stars.text = _get_card_star_label(card_data.card_rarity)
	
	var color_data: ColorData = Global.get_color_data(card_data.card_color_id)
	_apply_card_palette(color_data)
	
	energy_sprite.visible = card_data.card_is_playable
```

保留费用文本逻辑：

```gdscript
	if card_data.card_energy_cost_is_variable:
		card_energy_cost.text = "X"
		if card_data.card_energy_cost_variable_upper_bound >= 1:
			card_energy_cost.text = "X-" + str(card_data.card_energy_cost_variable_upper_bound)
	else:
		card_energy_cost.text = str(card_data.get_card_energy_cost())
```

- [ ] **Step 3: 添加 helper 方法**

在 `set_card_glow()` 前添加：

```gdscript
func _get_card_type_label(card_type_id: int) -> String:
	if CARD_TYPE_LABELS.has(card_type_id):
		return CARD_TYPE_LABELS[card_type_id]
	if card_type_id >= 0 and card_type_id < CardData.CARD_TYPES.keys().size():
		return CardData.CARD_TYPES.keys()[card_type_id]
	return ""


func _get_card_star_label(card_rarity_id: int) -> String:
	return CARD_RARITY_STARS.get(card_rarity_id, "")


func _get_card_faction_label(card_color_id: String) -> String:
	return CARD_FACTION_LABELS.get(card_color_id, "?")


func _apply_card_palette(color_data: ColorData) -> void:
	var frame_color := CARD_DEFAULT_FRAME_COLOR
	if color_data != null:
		frame_color = color_data.color
	
	card_color.color = frame_color
	card_type_background.color = frame_color.darkened(0.12)
	card_faction_background.color = frame_color.darkened(0.08)
	energy_sprite.color = Color(0.16, 0.39, 0.88, 1.0)
	
	var background_color := Color(1.0, 1.0, 1.0, 0.98)
	if frame_color.get_luminance() < 0.82:
		background_color = frame_color.lightened(0.82)
	card_background.color = background_color
```

- [ ] **Step 4: 运行测试确认仍失败但脚本能解析**

Run:

```bash
godot --headless --path . -s tests/card_template_visual_regression.gd
```

Expected: FAIL，原因仍是 `Card.tscn` 缺少 `%CardFaction`、`%CardStars` 等节点；不应出现 GDScript parse error。

- [ ] **Step 5: 提交脚本映射**

```bash
git add scripts/ui/Card.gd
git commit -m "Add card visual display mappings"
```

---

### Task 3: 重排 Card.tscn 为亮色模块

**Files:**
- Modify: `scenes/ui/Card.tscn`

- [ ] **Step 1: 保留现有资源头**

确认文件顶部继续使用当前默认卡图资源：

```gdscript
[ext_resource type="Texture2D" path="res://sprites/ui/flipper/icon_deck.png" id="1_7f6u3"]
```

不要恢复成 `res://icon.svg`。

- [ ] **Step 2: 替换 CardVisual 内部视觉节点**

在 `CardVisual` 下保留 `CardGlow`、`ColorBackground`、`CardButton` 外部交互不变。将视觉节点整理为以下结构和坐标：

```gdscript
[node name="CardGlow" type="ColorRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
visible = false
layout_mode = 2
offset_left = -8.0
offset_top = -8.0
offset_right = 152.0
offset_bottom = 192.0
color = Color(0.262745, 0.811765, 0.964706, 0.45)

[node name="ColorBackground" type="ColorRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 2
offset_right = 144.0
offset_bottom = 184.0
color = Color(0.258824, 0.411765, 0.882353, 1)

[node name="CardBackground" type="ColorRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 2
offset_left = 4.0
offset_top = 4.0
offset_right = 140.0
offset_bottom = 180.0
color = Color(1, 1, 1, 0.98)

[node name="CardName" type="RichTextLabel" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 32.0
offset_top = 7.0
offset_right = 108.0
offset_bottom = 26.0
theme_override_colors/default_color = Color(0.121569, 0.156863, 0.207843, 1)
theme_override_font_sizes/normal_font_size = 12
bbcode_enabled = true
text = "Card Name"
scroll_active = false
script = ExtResource("3_8gkbw")
_max_size = 12
_min_size = 8
_current_font_size = 12
_editor_defaults_set = true

[node name="CardTexture" type="TextureRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 31.0
offset_right = 132.0
offset_bottom = 101.0
texture = ExtResource("1_7f6u3")
expand_mode = 1
stretch_mode = 5

[node name="CardTypeBackground" type="ColorRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 105.0
offset_right = 132.0
offset_bottom = 124.0
color = Color(0.258824, 0.411765, 0.882353, 1)

[node name="CardType" type="Label" parent="Pivot/CardVisual/CardTypeBackground"]
unique_name_in_owner = true
layout_mode = 0
offset_right = 120.0
offset_bottom = 19.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_constants/line_spacing = -3
theme_override_font_sizes/font_size = 12
text = "攻击"
horizontal_alignment = 1
vertical_alignment = 1

[node name="CardDescription" type="RichTextLabel" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 129.0
offset_right = 132.0
offset_bottom = 167.0
theme_override_colors/default_color = Color(0.121569, 0.156863, 0.207843, 1)
theme_override_font_sizes/normal_font_size = 11
bbcode_enabled = true
text = "100/100"
scroll_active = false
script = ExtResource("3_8gkbw")
_max_size = 11
_min_size = 7
_current_font_size = 11
_editor_defaults_set = true

[node name="CardStars" type="Label" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 9.0
offset_top = 168.0
offset_right = 88.0
offset_bottom = 181.0
theme_override_colors/font_color = Color(1, 0.835294, 0.184314, 1)
theme_override_constants/line_spacing = -3
theme_override_font_sizes/font_size = 12
text = "★★"
vertical_alignment = 1

[node name="EnergySprite" type="ColorRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = -6.0
offset_top = -6.0
offset_right = 28.0
offset_bottom = 28.0
color = Color(0.160784, 0.392157, 0.878431, 1)
metadata/_edit_group_ = true

[node name="EnergyCost" type="Label" parent="Pivot/CardVisual/EnergySprite"]
unique_name_in_owner = true
layout_mode = 0
offset_right = 34.0
offset_bottom = 34.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_constants/line_spacing = -3
theme_override_font_sizes/font_size = 15
text = "3"
horizontal_alignment = 1
vertical_alignment = 1

[node name="CardFaction" type="ColorRect" parent="Pivot/CardVisual"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 113.0
offset_top = 6.0
offset_right = 139.0
offset_bottom = 32.0
color = Color(0.258824, 0.411765, 0.882353, 1)

[node name="CardFactionText" type="Label" parent="Pivot/CardVisual/CardFaction"]
unique_name_in_owner = true
layout_mode = 0
offset_right = 26.0
offset_bottom = 26.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_constants/line_spacing = -3
theme_override_font_sizes/font_size = 13
text = "流"
horizontal_alignment = 1
vertical_alignment = 1
```

Godot `ColorRect` 本身不是圆角节点；本任务先用方形色块完成结构和数据驱动。圆角感由小尺寸、颜色层级和固定分区体现。若后续需要真正圆角，可单独引入 `Panel` + `StyleBoxFlat`，不放进本次范围。

- [ ] **Step 3: 确认 CardButton 覆盖范围不变**

保留现有按钮配置：

```gdscript
[node name="CardButton" type="Button" parent="Pivot"]
unique_name_in_owner = true
self_modulate = Color(1, 1, 1, 0)
custom_minimum_size = Vector2(144, 184)
offset_left = -72.0
offset_top = -90.0
offset_right = 72.0
offset_bottom = 94.0
button_mask = 1
metadata/_edit_lock_ = true
```

- [ ] **Step 4: 运行测试确认通过**

Run:

```bash
godot --headless --path . -s tests/card_template_visual_regression.gd
```

Expected:

```text
ALL_TESTS_PASSED
```

- [ ] **Step 5: 提交场景重排**

```bash
git add scenes/ui/Card.tscn
git commit -m "Refresh card template layout"
```

---

### Task 4: 运行项目级验证

**Files:**
- Modify: none

- [ ] **Step 1: 运行新增卡牌视觉测试**

Run:

```bash
godot --headless --path . -s tests/card_template_visual_regression.gd
```

Expected:

```text
ALL_TESTS_PASSED
```

- [ ] **Step 2: 运行现有 UI 布局测试**

Run:

```bash
godot --headless --path . -s tests/ui_layout_bounds_regression.gd
```

Expected:

```text
ALL_TESTS_PASSED
```

- [ ] **Step 3: 运行 Godot headless 项目加载**

Run:

```bash
godot --headless --path . --quit
```

Expected: exit code 0，输出中没有 `ERROR:`、`SCRIPT ERROR:` 或场景资源加载失败。

- [ ] **Step 4: 检查只包含本任务相关改动**

Run:

```bash
git diff --stat HEAD
git status --short tests/card_template_visual_regression.gd scripts/ui/Card.gd scenes/ui/Card.tscn docs/superpowers/plans/2026-07-03-card-template-visual.md
```

Expected: 只显示本任务涉及的测试、`Card.gd`、`Card.tscn` 和计划文档。工作区中其他已有脏文件可以存在，但不要加入本任务提交。

- [ ] **Step 5: 提交计划文档**

如果计划文档尚未提交：

```bash
git add docs/superpowers/plans/2026-07-03-card-template-visual.md
git commit -m "Add card template visual implementation plan"
```

---

## 自审记录

- Spec coverage: 计划覆盖设计中的视觉结构、颜色/阵营映射、星级映射、文本边界、数据流和验证要求。
- Placeholder scan: 未发现占位词、延后实现语句或引用其他任务替代具体步骤的写法。
- Type consistency: 测试路径、节点路径和 `Card.gd` onready 名称一致：`CardFaction`、`CardFactionText`、`CardStars`、`CardTypeBackground`、`CardBackground`。

# 卡牌视觉细节修正实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修正费用与卡名的视觉居中和字重，为透明卡图增加随卡色变化的浅色渐变，并让参考资源类型铭牌完整叠加在连续横梁上。

**Architecture:** `Card.tscn` 提供固定的五层卡面结构，`Card.gd` 根据卡色生成渐变并控制费用字号，参考母版生成器只负责从同一张参考图输出完整卡框和精确裁切的类型铭牌。测试同时约束场景层级、运行时样式和输出 PNG 的透明度、比例与横梁连续性。

**Tech Stack:** Godot 4、GDScript、Godot `GradientTexture2D`、`FontVariation`、PNG 参考资源。

## Global Constraints

- 卡牌固定尺寸保持 `144 x 202`。
- 完整母版卡图区域为 `Rect2(17, 34, 114, 94)`；回退区域为 `Rect2(15, 34, 116, 76)`。
- 卡名区域为 `Rect2(34, 6, 90, 24)`，字号 8 至 12，`variation_embolden = 0.65`。
- 费用区域为 `Rect2(2, 3, 38, 38)`，短文本字号 19，长文本字号 14，`variation_embolden = 0.8`。
- 类型铭牌区域为 `Rect2(49, 119, 48, 14)`，输出资源为 `192 x 56`。
- 渐变方向为左上至右下，颜色采样依次使用主色 `lightened(0.88)`、`lightened(0.68)`、`lightened(0.38)`。
- 类型资源只能从 `designer/art_source/card_styles/full_master_v1/card_master_chroma.png` 裁切和重映射，不使用程序绘制色块补齐。
- 不修改卡牌数据、角色立绘文件、战斗逻辑和交互行为。

---

### Task 1: 锁定版式、字重和渐变图层

**Files:**
- Modify: `tests/card_template_visual_regression.gd`
- Modify: `tests/card_style_pack_preview_regression.gd`

**Interfaces:**
- Consumes: `Card.tscn` 中现有的 `CardVisual`、`CardTexture`、`CardName`、`EnergyCost`。
- Produces: 对 `CardArtBackground`、文字对齐、字重、矩形和费用动态字号的失败测试。

- [ ] **Step 1: 在模板回归测试中加入版式断言**

在 `_check_card_detail_treatment()` 中增加以下约束：

```gdscript
_assert_exact_rect(visual, "CardName", Rect2(34.0, 6.0, 90.0, 24.0), "card name")
_assert_exact_rect(visual, "EnergyCost", Rect2(2.0, 3.0, 38.0, 38.0), "energy cost")
_assert_centered_label(visual, "EnergyCost", "energy cost")
_assert_emboldened_font(visual, "EnergyCost", "font", 0.8, "energy cost")
_assert_emboldened_font(visual, "CardName", "normal_font", 0.65, "card name")
_assert_rich_text_vertical_center(visual, "CardName", "card name")
```

扩展 `_render_card()`，允许测试传入 `variable_upper_bound`；增加一个 `X-12` 用例并断言字号为 14，普通费用断言字号为 19。

- [ ] **Step 2: 在样式包回归测试中加入渐变和层级断言**

在 `_assert_master_layer_order()` 中查找 `CardArtBackground`，并要求：

```gdscript
background.get_index() < art.get_index()
art.get_index() < chrome.get_index()
background.get_global_rect().is_equal_approx(art.get_global_rect())
```

增加 `_assert_card_art_gradient()`，要求背景纹理是 `GradientTexture2D`，填充方向为 `Vector2(0.08, 0.05)` 至 `Vector2(0.92, 0.95)`，三个颜色采样不透明且首尾颜色不同。

- [ ] **Step 3: 运行测试并确认按预期失败**

Run:

```bash
godot --headless --path . --script tests/card_template_visual_regression.gd
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
```

Expected: 第一个测试报告缺少加粗、精确矩形或动态字号；第二个测试报告缺少 `CardArtBackground`。

---

### Task 2: 实现卡名、费用和卡图渐变

**Files:**
- Modify: `scenes/ui/Card.tscn`
- Modify: `scripts/ui/Card.gd`
- Test: `tests/card_template_visual_regression.gd`
- Test: `tests/card_style_pack_preview_regression.gd`

**Interfaces:**
- Consumes: Task 1 的场景和运行时断言。
- Produces:
  - `@onready var card_art_background: TextureRect`
  - `_create_card_art_gradient(frame_color: Color) -> GradientTexture2D`
  - `_set_card_art_rect(rect: Rect2) -> void`
  - `_update_energy_cost_visual(cost_text: String) -> void`

- [ ] **Step 1: 调整场景节点和字体资源**

在 `Card.tscn` 中引用 `res://fonts/ArialUnicode.ttf`，创建两个 `FontVariation`：

```ini
[sub_resource type="FontVariation" id="FontVariation_card_name"]
base_font = ExtResource("card_font")
variation_embolden = 0.65

[sub_resource type="FontVariation" id="FontVariation_energy_cost"]
base_font = ExtResource("card_font")
variation_embolden = 0.8
```

在 `CardTexture` 前添加同矩形的 `CardArtBackground: TextureRect`。将 `CardName` 改为 `Rect2(34, 6, 90, 24)`、最大字号 12、垂直居中并使用标题字体变化。将 `EnergyCost` 改为 `Rect2(2, 3, 38, 38)`、字号 19、描边 3 并使用费用字体变化。

- [ ] **Step 2: 在运行时生成浅色渐变**

在 `_apply_card_palette()` 确定白卡中性色后调用：

```gdscript
card_art_background.texture = _create_card_art_gradient(frame_color)
```

实现：

```gdscript
func _create_card_art_gradient(frame_color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		frame_color.lightened(0.88),
		frame_color.lightened(0.68),
		frame_color.lightened(0.38),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.08, 0.05)
	texture.fill_to = Vector2(0.92, 0.95)
	return texture
```

使用 `_set_card_art_rect(rect)` 同时设置 `CardArtBackground` 和 `CardTexture`，保证完整母版和回退模式几何一致。

- [ ] **Step 3: 按文本长度更新费用字号**

先计算完整费用文本，再统一调用：

```gdscript
func _update_energy_cost_visual(cost_text: String) -> void:
	card_energy_cost.text = cost_text
	card_energy_cost.add_theme_font_size_override(
		"font_size",
		19 if cost_text.length() <= 2 else 14
	)
```

保留不可打出卡牌的可见性逻辑，不修改费用计算。

- [ ] **Step 4: 运行版式与样式包测试**

Run:

```bash
godot --headless --path . --script tests/card_template_visual_regression.gd
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
```

Expected: 两个测试均打印 `ALL_TESTS_PASSED`。

- [ ] **Step 5: 提交版式与渐变修改**

```bash
git add scenes/ui/Card.tscn scripts/ui/Card.gd tests/card_template_visual_regression.gd tests/card_style_pack_preview_regression.gd
git commit -m "feat: polish card text and art background"
```

---

### Task 3: 锁定参考横梁和类型铭牌资源

**Files:**
- Modify: `tests/card_style_pack_preview_regression.gd`

**Interfaces:**
- Consumes: 当前 `master_slots` 和 `type_slots` 输出路径。
- Produces: 对完整横梁 alpha、类型铭牌尺寸、透明边界和可见中心的失败测试。

- [ ] **Step 1: 添加资源几何与透明度测试**

在 `_check_style_pack()` 中增加：

```gdscript
_check_master_ribbon_continuity(style_data)
_check_type_ribbon_geometry(style_data)
```

`_check_master_ribbon_continuity()` 加载每张母版，要求 `Vector2i(288, 503)` 的 alpha 大于 `0.5`。`_check_type_ribbon_geometry()` 要求每张类型 PNG 尺寸等于 `Vector2i(192, 56)`、中心 alpha 大于 `0.5`、四角至少一个 alpha 小于 `0.05`。

- [ ] **Step 2: 将运行时类型节点约束改为 TextureRect**

把 `_assert_panel_texture()` 替换为 `_assert_texture_rect()`，并断言 `CardTypeBackground` 的矩形等于 `Rect2(49, 119, 48, 14)`、纹理拉伸保持固定比例。

- [ ] **Step 3: 运行样式包测试并确认按预期失败**

Run:

```bash
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
```

Expected: 报告母版横梁中心透明、类型资源尺寸仍为 `240 x 64`，并且运行时类型节点仍是 `Panel`。

---

### Task 4: 从参考母版重建连续横梁和类型铭牌

**Files:**
- Modify: `tools/generate_full_card_master_assets.gd`
- Modify: `scenes/ui/Card.tscn`
- Modify: `scripts/ui/Card.gd`
- Regenerate: `external/sprites/ui/card_styles/full_master/card_master_red.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/card_master_blue.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/card_master_green.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/card_master_gold.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/card_master_silver.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/ribbons/ribbon_attack.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/ribbons/ribbon_skill.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/ribbons/ribbon_power.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/ribbons/ribbon_status.png`
- Regenerate: `external/sprites/ui/card_styles/full_master/ribbons/ribbon_curse.png`
- Test: `tests/card_style_pack_preview_regression.gd`

**Interfaces:**
- Consumes: Task 3 的 PNG 与运行时节点断言。
- Produces: 精确裁切类型纹理和 `_try_apply_full_card_master()` 的直接纹理赋值。

- [ ] **Step 1: 修正参考资源生成器**

修改常量：

```gdscript
const RIBBON_SOURCE_RECT := Rect2i(358, 874, 358, 94)
const RIBBON_SIZE := Vector2i(192, 56)
```

在 `_remove_chroma()` 中删除 `_is_master_ribbon_body()` 的透明清除分支，保留整条参考横梁。类型裁片仍移除绿色背景和属于连接段的紫色像素，再通过 `_remap_red()` 生成五类颜色。

将 `_validate_master_transparency()` 的横梁检查改为：

```gdscript
if image.get_pixel(288, 503).a <= 0.5:
	push_error("%s lost the reference ribbon body" % file_name)
	return false
```

- [ ] **Step 2: 把类型背景改为参考纹理节点**

将 `CardTypeBackground` 改为 `TextureRect`，区域设为 `Rect2(49, 119, 48, 14)`，并让子节点 `CardType` 填满 `48 x 14`。回退状态使用现有参考状态铭牌作为基础纹理，通过 `self_modulate` 适配旧卡框颜色，不绘制新的矩形。

在 `Card.gd` 中把类型节点声明改为：

```gdscript
@onready var card_type_background: TextureRect = %CardTypeBackground
```

`_try_apply_full_card_master()` 验证两张纹理成功后，直接执行：

```gdscript
card_chrome.texture = master_texture
card_type_background.texture = type_texture
card_type_background.self_modulate = Color.WHITE
```

- [ ] **Step 3: 重新生成参考资源**

Run:

```bash
godot --headless --path . --script tools/generate_full_card_master_assets.gd
```

Expected: 打印 `FULL_CARD_MASTER_ASSETS_GENERATED`。

- [ ] **Step 4: 运行样式包和模板测试**

Run:

```bash
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
godot --headless --path . --script tests/card_template_visual_regression.gd
```

Expected: 两个测试均打印 `ALL_TESTS_PASSED`。

- [ ] **Step 5: 提交参考资源修正**

```bash
git add tools/generate_full_card_master_assets.gd scenes/ui/Card.tscn scripts/ui/Card.gd tests/card_style_pack_preview_regression.gd external/sprites/ui/card_styles/full_master
git commit -m "fix: preserve card type ribbon continuity"
```

---

### Task 5: 生成预览并完成最终验证

**Files:**
- Verify: `tmp/card_style_preview/card_style_full_master_runtime.png`

**Interfaces:**
- Consumes: Tasks 2 和 4 的最终运行时卡面。
- Produces: 可供人工对照的卡牌预览图和完整验证证据。

- [ ] **Step 1: 生成运行时预览**

Run:

```bash
godot --headless --path . --script tools/render_card_style_preview.gd
```

Expected: 生成 `tmp/card_style_preview/card_style_full_master_runtime.png`。

- [ ] **Step 2: 视觉检查**

检查红、蓝、绿卡：

- 费用数字位于圆形费用球有效区域中央，字重明显。
- 卡名位于黑色标题栏中央，白字、加粗且不遮挡徽记。
- 角色透明区域后方显示对应卡色的浅色斜向渐变。
- 类型横梁两侧连续，攻击、技能和能力铭牌完整覆盖中央，不出现挖空或矩形补丁。

- [ ] **Step 3: 运行完整验证**

Run:

```bash
godot --headless --path . --quit
godot --headless --path . --script tests/card_template_visual_regression.gd
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
git diff --check
```

Expected: Godot 项目加载退出码为 0，两个回归测试打印 `ALL_TESTS_PASSED`，`git diff --check` 无错误。

- [ ] **Step 4: 核对提交范围**

Run:

```bash
git status --short
git diff --stat HEAD~2..HEAD
```

Expected: 本轮提交只包含计划列出的卡牌场景、脚本、测试、生成器和生成资源；工作区原有的其他改动保持未暂存。

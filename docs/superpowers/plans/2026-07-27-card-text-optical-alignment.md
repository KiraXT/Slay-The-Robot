# 卡牌文字光学对齐微调实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将费用文字在上一轮基础上继续右移 2 像素，并保持卡名位置不变。

**Architecture:** 只修改 `Card.tscn` 中两个文字控件的固定矩形，不改变字体、字号、自动缩放和运行时脚本。模板回归测试继续使用精确矩形断言防止位置回退。

**Tech Stack:** Godot 4、GDScript、Godot 场景资源。

## Global Constraints

- 费用区域必须从 `Rect2(4, 1, 38, 38)` 改为 `Rect2(6, 1, 38, 38)`。
- 卡名区域保持 `Rect2(34, 8, 90, 24)`。
- 不修改字号、字重、文字内容、卡框资源、卡图、渐变、类型铭牌或战斗逻辑。

---

### Task 1: 调整费用和卡名的光学位置

**Files:**
- Modify: `tests/card_template_visual_regression.gd`
- Modify: `scenes/ui/Card.tscn`

**Interfaces:**
- Consumes: `_assert_exact_rect()` 对 `CardName` 和 `EnergyCost` 的现有矩形约束。
- Produces: 固定矩形 `CardName = Rect2(34, 8, 90, 24)`、`EnergyCost = Rect2(6, 1, 38, 38)`。

- [ ] **Step 1: 更新精确矩形断言**

将模板测试中的两个断言改为：

```gdscript
_assert_exact_rect(visual, "CardName", Rect2(34.0, 8.0, 90.0, 24.0), "card name")
_assert_exact_rect(visual, "EnergyCost", Rect2(6.0, 1.0, 38.0, 38.0), "energy cost")
```

- [ ] **Step 2: 运行测试并确认失败**

Run:

```bash
godot --headless --path . --script tests/card_template_visual_regression.gd
```

Expected: 报告费用实际区域仍为 `Rect2(4, 1, 38, 38)`。

- [ ] **Step 3: 修改场景坐标**

在 `Card.tscn` 中设置：

```ini
[node name="CardName" type="RichTextLabel" parent="Pivot/CardVisual"]
offset_left = 34.0
offset_top = 8.0
offset_right = 124.0
offset_bottom = 32.0

[node name="EnergyCost" type="Label" parent="Pivot/CardVisual"]
offset_left = 6.0
offset_top = 1.0
offset_right = 44.0
offset_bottom = 39.0
```

- [ ] **Step 4: 运行两组回归测试**

Run:

```bash
godot --headless --path . --script tests/card_template_visual_regression.gd
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
```

Expected: 两个测试均打印 `ALL_TESTS_PASSED`。

- [ ] **Step 5: 重新生成运行时预览**

Run:

```bash
godot --path . --rendering-method gl_compatibility --script tools/render_card_style_preview.gd
```

Expected: 打印 `CARD_STYLE_FULL_MASTER_PREVIEW_RENDERED`，并更新 `tmp/card_style_preview/card_style_full_master_runtime.png`。

- [ ] **Step 6: 核对视觉和提交**

视觉确认费用相对提交 `1ec14a0` 右移 2 像素、纵向位置不变，卡名位置不变；长文本不溢出。随后执行：

```bash
git diff --check -- scenes/ui/Card.tscn tests/card_template_visual_regression.gd
git add -- scenes/ui/Card.tscn tests/card_template_visual_regression.gd
git commit -m "fix: refine card text optical alignment"
```

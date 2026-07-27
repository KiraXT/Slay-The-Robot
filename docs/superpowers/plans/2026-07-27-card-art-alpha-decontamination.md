# 卡图透明边缘批量去绿实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 批量清理人工确认的卡图半透明绿色边缘污染，不影响其他卡图与运行时显示链路。

**Architecture:** 一个 Godot 工具以默认审计模式扫描并生成候选清单、处理结果和对照图；视觉确认后把路径写入受版本控制的白名单。只有传入 `--apply` 时才写回白名单中的候选源图。一个回归脚本复用相同的污染判定，确保写回图不再保留候选阈值的绿色透明残边。

**Tech Stack:** Godot 4、GDScript、Godot `Image` API、PNG。

## Global Constraints

- 扫描范围固定为 `external/sprites/cards/**/*.png`。
- 候选像素条件：`0.01 < alpha < 0.99`、`green > 0.28`、`green > red * 1.18`、`green > blue * 1.18`。
- 单图候选像素数达到 64 才进入候选清单；候选结果只用于审计，不自动写回。
- 仅 `tools/card_art_alpha_cleanup_manifest.json` 中且仍属于候选的图片允许重编码或修改。
- 不修改 `autoload/FileLoader.gd`、`scripts/ui/Card.gd`、`scenes/ui/Card.tscn`、卡牌 CSV 或运行时 shader。
- 默认运行必须只输出到 `tmp/card_art_alpha_cleanup/`；只有 `--apply` 可以覆盖候选 PNG。

---

### Task 1: 建立污染回归基线

**Files:**
- Create: `tests/card_art_alpha_cleanup_regression.gd`

**Interfaces:**
- Consumes: `external/sprites/cards/**/*.png`、`tools/card_art_alpha_cleanup_manifest.json`。
- Produces: `_count_green_edge_pixels(image: Image) -> int`，用于检测白名单卡图的绿色边缘候选数量。

- [x] **Step 1: 编写失败回归测试**

创建测试，递归收集卡图 PNG，对每张资源调用：

```gdscript
func _count_green_edge_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if (color.a > 0.01 and color.a < 0.99
					and color.g > 0.40
					and color.g - maxf(color.r, color.b) > 0.24):
				count += 1
	return count
```

当任意白名单 PNG 的计数大于等于 64 时输出路径与计数并以退出码 1 结束。测试同时校验白名单路径存在，且不包含候选范围之外的路径。

- [x] **Step 2: 运行测试确认失败**

Run:

```bash
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
```

Expected: 在白名单建立前测试报告缺少白名单；在白名单建立后，至少报告已确认的污染卡图。

---

### Task 2: 实现只读审计与处理预览工具

**Files:**
- Create: `tools/clean_card_art_alpha_edges.gd`
- Create: `tools/card_art_alpha_cleanup_manifest.json`
- Test: `tests/card_art_alpha_cleanup_regression.gd`

**Interfaces:**
- Consumes: `_is_green_edge_contamination(color: Color) -> bool`、`_decontaminate_chroma(color: Color) -> Color`。
- Produces:
  - `tmp/card_art_alpha_cleanup/candidates.json`
  - `tmp/card_art_alpha_cleanup/processed/<relative-card-path>.png`
  - `tmp/card_art_alpha_cleanup/contact_sheet.png`

- [x] **Step 1: 实现确定性去绿函数**

在工具中实现与卡框生成器一致的计算，只对判定命中的像素调用：

```gdscript
func _decontaminate_chroma(color: Color) -> Color:
	var green_delta := color.g - maxf(color.r, color.b)
	var foreground_alpha := 1.0 - smoothstep(0.12, 0.58, green_delta)
	var output_alpha := color.a * foreground_alpha
	if foreground_alpha <= 0.001 or output_alpha <= 0.001:
		return Color.TRANSPARENT
	var removed_green := 1.0 - foreground_alpha
	return Color(
		clampf(color.r / foreground_alpha, 0.0, 1.0),
		clampf((color.g - removed_green) / foreground_alpha, 0.0, 1.0),
		clampf(color.b / foreground_alpha, 0.0, 1.0),
		output_alpha
	)
```

- [x] **Step 2: 实现审计模式**

默认模式递归读取所有卡图。只有候选计数至少为 64 的图片才生成处理副本；候选 JSON 记录 `path`、`contaminated_pixels_before`、`contaminated_pixels_after`。未命中图片不输出处理副本。

工具必须把透明图合成到中性棋盘底图上，输出前后并列的 `contact_sheet.png`，方便视觉确认轮廓和绿色特效没有被裁掉。

- [x] **Step 3: 运行审计并检查预览**

Run:

```bash
godot --headless --path . --script tools/clean_card_art_alpha_edges.gd
```

Expected: 打印候选数量，生成 JSON、处理副本和对照图；`external/sprites/cards/` 没有文件变化。

- [x] **Step 4: 运行回归测试确认仍失败**

Run:

```bash
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
```

Expected: 因白名单源图尚未写回，继续报告相同白名单资源。

---

### Task 3: 限定写回候选资源并验证游戏

**Files:**
- Modify: `external/sprites/cards/<approved paths from manifest>`
- Test: `tests/card_art_alpha_cleanup_regression.gd`
- Verify: `tmp/card_art_alpha_cleanup/contact_sheet.png`

**Interfaces:**
- Consumes: Task 2 输出的 `candidates.json`、候选处理副本与人工确认白名单。
- Produces: 清理后的白名单源图，保留原文件路径和尺寸。

- [x] **Step 1: 实现 `--apply` 写回开关**

当 `OS.get_cmdline_user_args().has("--apply")` 为真时，工具只覆盖同时存在于 `candidates.json` 和白名单中的源图；默认模式不得写入 `external/sprites/cards/`。

- [x] **Step 2: 写回候选图**

Run:

```bash
godot --headless --path . --script tools/clean_card_art_alpha_edges.gd -- --apply
```

Expected: 输出每个写回路径，且 `git status --short -- external/sprites/cards` 只列出白名单中的 PNG。

- [x] **Step 3: 验证污染清零与尺寸保持**

Run:

```bash
godot --headless --path . --script tests/card_art_alpha_cleanup_regression.gd
godot --headless --path . --script tests/card_template_visual_regression.gd
godot --headless --path . --script tests/card_style_pack_preview_regression.gd
godot --headless --path . --quit
```

Expected: 四个命令均以退出码 0 结束；清理测试打印 `ALL_TESTS_PASSED`。

- [x] **Step 4: 生成运行时卡牌预览并视觉检查**

Run:

```bash
godot --path . --rendering-method gl_compatibility --script tools/render_card_style_preview.gd
```

Expected: 更新 `tmp/card_style_preview/card_style_full_master_runtime.png`；红色与白色卡图边缘没有绿色残留。

- [x] **Step 5: 差异检查与提交**

Run:

```bash
git diff --check -- tools/clean_card_art_alpha_edges.gd tests/card_art_alpha_cleanup_regression.gd external/sprites/cards
git add tools/clean_card_art_alpha_edges.gd tests/card_art_alpha_cleanup_regression.gd external/sprites/cards
git commit -m "fix: clean green contamination from card art"
```

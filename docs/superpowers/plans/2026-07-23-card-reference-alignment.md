# 完整卡牌母版替换 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** 直接清理完整参考卡图并作为连续母版接入，消除多块资源拼接感，同时保留动态插画、名称、描述、费用、类型和星级。

**Architecture:** 动态插画位于底层，透明完整卡牌母版位于中层，名称、描述、费用、类型与星级位于顶层。五种卡色由同一母版做保明暗的色相映射，类型条从同一母版裁切并独立换色。

**Tech Stack:** Godot 4、GDScript、JSON、Image、headless Godot。

## Global Constraints

- 不改动 CardData 或卡牌逻辑。
- 不使用新增纯色色块替代参考资源，所有可见边框均来自完整参考卡图。
- 每张卡只能显示一种主色框架。
- 所有用户既有改动保持不动。

---

### Task 1: 定义整卡母版失败测试

**Files:**
- Modify: tests/card_template_visual_regression.gd
- Modify: tests/card_style_pack_preview_regression.gd

- [x] 断言样式包包含五色完整母版与五类类型条。
- [x] 断言场景层级为动态插画、完整母版、动态文字与数值。
- [x] 断言旧拼接面板在完整母版启用时全部隐藏。

### Task 2: 清理完整参考卡图

**Files:**
- Create: designer/art_source/card_styles/full_master_v1/card_master_chroma.png
- Create: tools/generate_full_card_master_assets.gd
- Create: external/sprites/ui/card_styles/full_master/

- [x] 从完整参考卡清除卡名、费用数字、类型文字、插画、描述与星级。
- [x] 将外部背景和插画窗口转换为透明通道。
- [x] 从同一母版生成五色卡框和五类空白类型条，并校验透明区域。

### Task 3: 重排运行时层级

**Files:**
- Modify: scenes/ui/Card.tscn
- Modify: scripts/ui/Card.gd
- Modify: external/data/card_styles/card_style_preview.json

- [x] 新增 CardChrome 完整母版层，CardTexture 移至其下方。
- [x] 名称、描述、费用与星级移至母版上方。
- [x] 隐藏旧拼接层，保留为母版缺失时的回退节点。
- [x] 标题使用白字与深色描边，类型条按卡型独立切换。

### Task 4: 验证与预览

**Files:**
- Modify: tools/render_card_style_preview.gd
- Create: tmp/card_style_preview/card_style_full_master_runtime.png

- [x] 渲染五张不同颜色卡牌，分别使用五种类型条。
- [x] 运行两项卡牌回归、无窗口 Godot 加载和 git diff --check。
- [x] 人工检查透明边缘、类型条层级、标题与描述区域。

### Task 5: 独立审查修正

**Files:**
- Modify: scripts/ui/Card.gd
- Modify: scenes/ui/shop/CardShopButton.tscn
- Modify: tools/generate_full_card_master_assets.gd
- Modify: tests/card_style_pack_preview_regression.gd
- Modify: tests/card_template_visual_regression.gd

- [x] 母版与类型条资源同时验证成功后再切换，资源缺失时完整回退。
- [x] 调整旧框架回退时的插画顺序与尺寸。
- [x] 将商店价格区域移动到 202 高卡牌下方。
- [x] 清除半透明边缘中的色键绿色 RGB，并增加像素级回归。

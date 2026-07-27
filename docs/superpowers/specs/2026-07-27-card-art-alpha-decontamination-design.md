# 卡图透明边缘批量去绿设计

## 目标

修复 `external/sprites/cards/` 下卡图 PNG 的半透明绿色边缘污染，避免卡牌展示时出现类似抠图不完整的绿色残留。

本轮只处理通过污染检测的卡图；未命中的卡图不重编码、不移动路径、不改变像素。

## 根因

卡图通过 `FileLoader.load_texture()` 直接从 PNG 创建运行时纹理。部分源图的半透明边缘仍携带绿色抠图底色，缩放并与卡图背景混合后显现为绿色残边。

已有的卡框资源生成器包含同类去绿处理，但卡图资源此前没有走这一流程。

## 两阶段处理

### 阶段 1：审计与预览

新增可重复运行的 Godot 工具，扫描 `external/sprites/cards/**/*.png` 并生成：

- 候选清单：`tmp/card_art_alpha_cleanup/candidates.json`。
- 每张候选资源的污染像素数量。
- 处理前后对照图：`tmp/card_art_alpha_cleanup/contact_sheet.png`。

单个像素被判定为绿色污染需同时满足：

```gdscript
color.a > 0.01 and color.a < 0.99
and color.g > 0.40
and color.g - maxf(color.r, color.b) > 0.24
```

只有污染像素数量不少于 64 的卡图进入候选清单。这个下限能覆盖已确认污染的 `card_red.png`、`card_attack_basic.png`、`card_block_basic.png`，同时忽略零星的正常高光噪点。

### 阶段 2：安全写回

工具只读取候选清单中的资源。对每个命中像素使用与卡框资源一致的去绿计算：降低由绿色污染推导出的透明度，并重新计算 RGB，保留非命中像素完全不变。

处理前先在 `tmp/card_art_alpha_cleanup/processed/` 生成输出和对照图；视觉检查通过后，才覆盖候选资源的原 PNG。原 PNG 由 Git 追踪，因此任何单图变更都可精确回退。

## 运行时边界

- 不修改 `autoload/FileLoader.gd`、`scripts/ui/Card.gd`、`scenes/ui/Card.tscn` 或卡牌数据路径。
- 不新增 shader，不改变卡图缩放模式。
- 不处理卡框、类型铭牌、角色战斗立绘、敌人或背景图。
- 不处理没有达到 64 像素阈值的卡图。

## 验收标准

1. 候选清单只包含污染计数达到阈值的卡图。
2. 每张写回卡图的污染像素计数由正数降为 0。
3. 非候选卡图的内容保持不变。
4. 所有处理后的 PNG 保持原始尺寸与 alpha 通道。
5. 卡牌模板和样式包回归测试继续通过。
6. 运行时预览中红色和白色卡图不再出现绿色半透明残边。

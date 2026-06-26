# Red Character Art Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 统一红色角色的头像、能量图标与高频卡牌插图，使其与当前 Tifa 风格战斗立绘保持一致。

**Architecture:** 直接替换现有图片资源，不改动资源加载逻辑与数据路径。优先保持现有文件名和尺寸规范，降低接入风险；生成或挑选完成后只做尺寸、透明通道与显示适配校验。

**Tech Stack:** Godot 资源管线、PNG 位图资源、Codex built-in image generation workflow、项目既有图片路径约定

---

### Task 1: 固化替换范围与落地路径

**Files:**
- Modify: `docs/superpowers/plans/2026-06-27-red-character-art-unification-plan.md`
- Review: `docs/superpowers/specs/2026-06-27-red-character-art-unification-design.md`
- Review: `designer/ASSET_REPLACEMENT_GUIDE.md`

- [ ] **Step 1: 核对本轮替换清单**

确认以下目标文件为本轮唯一替换范围：

```text
external/sprites/characters/character_red/character_red_icon.png
external/sprites/characters/character_red/character_red_text_energy.png
external/sprites/cards/red/card_red.png
external/sprites/cards/card_attack_basic.png
external/sprites/cards/card_attack_big.png
external/sprites/cards/card_grant_energy.png
external/sprites/cards/card_weaken_enemies.png
external/sprites/cards/card_block_basic.png
external/sprites/cards/card_draft_random_attack.png
```

- [ ] **Step 2: 核对尺寸与透明要求**

按以下规格执行，不扩展额外尺寸：

```text
character_red_icon.png -> 256x256, transparent PNG
character_red_text_energy.png -> 128x128, transparent PNG
all card art targets -> 512x512, transparent PNG
```

- [ ] **Step 3: 确认风格锚点**

统一以现有文件作为视觉锚点：

```text
external/sprites/characters/character_red/character_red.png
```

要求保留：黑长发、红黑白主色、拳击/近战气质、轻机械手臂设定。

### Task 2: 产出并替换红色角色 UI 资源

**Files:**
- Modify: `external/sprites/characters/character_red/character_red_icon.png`
- Modify: `external/sprites/characters/character_red/character_red_text_energy.png`

- [ ] **Step 1: 产出角色头像**

目标要求：

```text
半身或近景头像，脸部和红色拳套同时可辨认，自信且备战状态，适合 64x64 UI 按钮缩放后识别。
```

- [ ] **Step 2: 校验角色头像规格**

校验项：

```text
文件存在
PNG
256x256
保留透明通道
缩小后脸部轮廓不糊成一团
```

- [ ] **Step 3: 产出能量图标**

目标要求：

```text
强符号化，不直接使用完整头像，优先拳印/拳套/格斗能量徽记，适合卡牌文本内嵌小尺寸显示。
```

- [ ] **Step 4: 校验能量图标规格**

校验项：

```text
文件存在
PNG
128x128
保留透明通道
小尺寸下轮廓清晰
```

### Task 3: 产出并替换红色卡组共用图

**Files:**
- Modify: `external/sprites/cards/red/card_red.png`

- [ ] **Step 1: 产出红色卡组共用卡图**

目标要求：

```text
表现同一角色的爆发型近战职业感，主体集中，红黑主色明确，不使用复杂背景，适合卡牌中部裁切。
```

- [ ] **Step 2: 校验共用卡图规格**

校验项：

```text
文件存在
PNG
512x512
保留透明通道
缩小预览时主体仍集中在中心区域
```

### Task 4: 产出并替换六张高频单卡插图

**Files:**
- Modify: `external/sprites/cards/card_attack_basic.png`
- Modify: `external/sprites/cards/card_attack_big.png`
- Modify: `external/sprites/cards/card_grant_energy.png`
- Modify: `external/sprites/cards/card_weaken_enemies.png`
- Modify: `external/sprites/cards/card_block_basic.png`
- Modify: `external/sprites/cards/card_draft_random_attack.png`

- [ ] **Step 1: 产出基础攻击图**

动作语义：

```text
基础直拳，简洁有力，冲击感明确。
```

- [ ] **Step 2: 产出重攻击图**

动作语义：

```text
更强爆发性的重拳或下砸拳，强调力度和破坏感。
```

- [ ] **Step 3: 产出能量获得图**

动作语义：

```text
蓄力、聚气、战斗能量汇聚，符号化光效可以更强。
```

- [ ] **Step 4: 产出群体弱化图**

动作语义：

```text
压制、威慑、打断对手节奏，允许更偏气势型构图。
```

- [ ] **Step 5: 产出基础格挡图**

动作语义：

```text
架势、防守、臂部格挡或交叉防御，强调防御姿态而非攻击。
```

- [ ] **Step 6: 产出随机攻击抽取图**

动作语义：

```text
快速切换招式、组合拳选择感、卡牌或连招意象。
```

- [ ] **Step 7: 统一规格校验**

六张图统一检查：

```text
PNG
512x512
透明通道正常
主体与当前角色人设一致
卡牌缩略显示时动作可辨
```

### Task 5: 资源验证与提交整理

**Files:**
- Review: `external/sprites/characters/character_red/character_red_icon.png`
- Review: `external/sprites/characters/character_red/character_red_text_energy.png`
- Review: `external/sprites/cards/red/card_red.png`
- Review: `external/sprites/cards/card_attack_basic.png`
- Review: `external/sprites/cards/card_attack_big.png`
- Review: `external/sprites/cards/card_grant_energy.png`
- Review: `external/sprites/cards/card_weaken_enemies.png`
- Review: `external/sprites/cards/card_block_basic.png`
- Review: `external/sprites/cards/card_draft_random_attack.png`

- [ ] **Step 1: 运行尺寸与格式校验**

至少确认以下结果：

```text
角色头像 256x256
能量图标 128x128
卡图 7 张均为 512x512
全部为 PNG
需要透明的资源透明通道存在
```

- [ ] **Step 2: 进行视觉抽样复核**

重点确认：

```text
头像不是旧机器人风
能量图标不是旧齿轮头
高频卡图与战斗立绘为同一角色语义
不存在明显背景残留或裁边错误
```

- [ ] **Step 3: 整理变更说明**

输出内容包含：

```text
替换了哪些资源
资源现在的规格
是否仍有后续建议扩展项
```

# Blue Shared Card Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将蓝色角色共用卡图替换为贴近八柰见 JK 学生气质、以面包和日常杂物为主的轻喜剧卡图。

**Architecture:** 保持现有资源路径不变，只替换 `external/sprites/cards/blue/card_blue.png`。以当前蓝色角色立绘为视觉锚点生成一张新的透明底卡图，并做本地抠底、尺寸规范化与最终校验。

**Tech Stack:** Godot 资源管线、PNG 位图资源、Codex built-in image generation workflow、Pillow 抠底后处理

---

### Task 1: 固定替换范围与资源约束

**Files:**
- Modify: `docs/superpowers/plans/2026-06-27-blue-card-shared-art.md`
- Review: `docs/superpowers/specs/2026-06-27-blue-card-shared-art-design.md`
- Review: `external/sprites/characters/character_blue/character_blue.png`

- [x] **Step 1: 确认唯一替换目标**

```text
external/sprites/cards/blue/card_blue.png
```

- [x] **Step 2: 确认输出规格**

```text
512x512
PNG
透明底
```

- [x] **Step 3: 确认风格约束**

```text
人物锚点为当前蓝色角色立绘
学生制服、蓝发、JK 日常气质
道具以面包、便当、饮料、书包等日常物件为主
避免拳击、重击、爆裂冲击波等红色角色风格
情绪为轻松吐槽系，带一点“被卷进战斗”的动态感
```

### Task 2: 生成并落库蓝色共用卡图

**Files:**
- Modify: `external/sprites/cards/blue/card_blue.png`

- [x] **Step 1: 生成新卡图源图**

目标要求：

```text
以蓝色角色本人为主角
画面中出现面包、便当、饮料或书包等日常物件
动作为轻喜剧动态，不是正统战斗角色爆发动作
背景使用单色抠像底，便于透明化
```

- [x] **Step 2: 执行透明背景处理**

校验项：

```text
主体边缘可接受
头发边缘无明显残留底色
道具边缘无明显白边或绿边
```

- [x] **Step 3: 规范尺寸并覆盖目标文件**

执行要求：

```text
将结果统一到 512x512
保持 PNG
保留透明通道
覆盖 external/sprites/cards/blue/card_blue.png
```

### Task 3: 结果校验

**Files:**
- Review: `external/sprites/cards/blue/card_blue.png`

- [x] **Step 1: 规格校验**

```text
pixelWidth: 512
pixelHeight: 512
hasAlpha: yes
```

- [x] **Step 2: 视觉校验**

```text
缩小后仍能认出是蓝色角色
人物不是单纯站姿裁切
面包/日常杂物元素存在但不拥挤
与红色角色卡图有明显风格区分
```

- [x] **Step 3: 输出变更说明**

```text
说明替换文件
说明规格
说明是否建议继续扩展蓝色角色的 icon / energy / 单卡资源
```

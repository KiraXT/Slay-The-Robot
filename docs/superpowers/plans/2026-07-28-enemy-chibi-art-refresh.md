# Enemy Chibi Art Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前实际出现在敌人数据中的战斗敌人立绘，统一替换为接近玩家角色的 Q 版二次元机器人风格。

**Architecture:** 保持 `external/data/enemies/*.json` 的 `enemy_texture_path` 不变，直接替换同路径 PNG 资源。生成阶段使用玩家角色立绘作为风格参考，输出透明 PNG，Godot 继续通过 `BaseCombatant.set_combat_sprite_texture()` 做现有高度适配。

**Tech Stack:** Godot 4.6.2、GDScript、PNG RGBA 资源、Codex built-in image generation、local chroma-key alpha cleanup.

## Global Constraints

- 只修改敌人立绘资源和本计划文档。
- 不修改敌人数值、行动逻辑、战斗站位、UI、卡牌模板。
- 输出资源必须为 PNG RGBA，边缘透明，无纯色背景残留。
- 视觉方向：Q 版二次元、粗描边、短比例、清晰色块、简化机器人结构，贴合当前玩家角色战斗立绘。
- 替换对象仅限 `external/data/enemies/*.json` 中实际引用的 `external/sprites/enemies/*.png`。

---

### Task 1: Asset Target List

**Files:**
- Read: `external/data/enemies/*.json`
- Modify: none

**Interfaces:**
- Consumes: enemy data `enemy_texture_path`
- Produces: exact replacement list for Task 2

- [ ] **Step 1: Collect referenced enemy textures**

Run: `rg -n "enemy_texture_path" external/data/enemies/*.json`

Expected: identify only runtime-referenced enemy PNGs under `external/sprites/enemies/`.

- [ ] **Step 2: Confirm no UI/card files are in scope**

Run: `git status --short external/data external/sprites scenes scripts tests`

Expected: existing unrelated generated files may remain visible, but no card UI files are modified by this task.

### Task 2: Generate Replacement Enemy Sprites

**Files:**
- Modify: `external/sprites/enemies/enemy_1.png`
- Modify: `external/sprites/enemies/enemy_2.png`
- Modify: `external/sprites/enemies/enemy_3.png`
- Modify: `external/sprites/enemies/enemy_4.png`
- Modify: `external/sprites/enemies/enemy_minion_1.png`
- Modify: `external/sprites/enemies/enemy_minion_2.png`
- Modify: `external/sprites/enemies/enemy_act_1_micro_drone.png`
- Modify: `external/sprites/enemies/enemy_act_1_scout_striker.png`
- Modify: `external/sprites/enemies/enemy_act_1_disruptor_unit.png`
- Modify: `external/sprites/enemies/enemy_act_1_scrap_shield_guard.png`
- Modify: `external/sprites/enemies/enemy_act_1_miniboss_1.png`
- Modify: `external/sprites/enemies/enemy_act_1_miniboss_2.png`
- Modify: `external/sprites/enemies/enemy_act_1_miniboss_bastion_guard.png`
- Modify: `external/sprites/enemies/enemy_act_1_miniboss_command_core.png`
- Modify: `external/sprites/enemies/enemy_act_1_boss_1.png`

**Interfaces:**
- Consumes: player style reference `external/sprites/characters/character_red/character_red.png`
- Produces: same-path RGBA enemy PNGs consumed by current enemy JSON

- [ ] **Step 1: Generate each enemy on a removable chroma-key background**

Use the player character as style reference and the current enemy as subject reference.

Prompt constraints for every asset:
```text
Q-version anime robot enemy combat sprite, matching the player character style reference: large head or dominant readable silhouette, short body proportions, thick clean black outline, bright simple color blocks, simplified metal parts, expressive glowing eyes, no realistic dense mechanical detail.
Full body centered, 3/4 view facing left toward the player, transparent-ready game sprite composition.
Place the subject on a perfectly flat solid #ff00ff chroma-key background, no shadow, no floor, no text, no watermark, no background props, no #ff00ff in the subject.
```

- [ ] **Step 2: Remove chroma-key background**

Run the installed chroma cleanup helper with `--auto-key border --soft-matte --despill`.

Expected: output PNG has alpha channel and transparent corners.

- [ ] **Step 3: Replace exact runtime paths**

Copy cleaned PNGs over the matching `external/sprites/enemies/*.png` paths.

Expected: enemy JSON references do not need changes.

### Task 3: Verification

**Files:**
- Test: `tests/character_event_pool_regression.gd`
- Test: `tests/reward_configuration_runtime_regression.gd`
- Test: Godot project load

**Interfaces:**
- Consumes: replaced enemy PNGs
- Produces: verification evidence before commit

- [ ] **Step 1: Verify enemy event data still loads**

Run: `godot --headless --path . --script tests/character_event_pool_regression.gd`

Expected: `ALL_TESTS_PASSED`.

- [ ] **Step 2: Verify runtime configuration still loads**

Run: `godot --headless --path . --script tests/reward_configuration_runtime_regression.gd`

Expected: `ALL_TESTS_PASSED`.

- [ ] **Step 3: Verify project startup**

Run: `godot --headless --path . --quit`

Expected: exit code 0.

- [ ] **Step 4: Review git scope**

Run: `git status --short external/sprites/enemies docs/superpowers/plans/2026-07-28-enemy-chibi-art-refresh.md`

Expected: only the intended enemy PNGs and this plan are included for commit.

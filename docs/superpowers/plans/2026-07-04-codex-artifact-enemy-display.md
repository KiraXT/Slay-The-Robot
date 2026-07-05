# Codex Artifact Enemy Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让目录页像展示卡牌一样切换展示怪物和神器。

**Architecture:** 在 `CodexMenu.gd` 中保留现有卡牌生成逻辑，新增类型按钮事件和只读条目生成函数。只读条目直接读取 `EnemyData` / `ArtifactData` 字段，不复用战斗敌人或可交互神器控件。

**Tech Stack:** Godot 4、GDScript、现有 `SceneTree` 回归测试。

---

### Task 1: 回归测试

**Files:**
- Create: `tests/codex_menu_display_regression.gd`

- [ ] **Step 1: Write the failing test**

测试实例化 `Root.tscn`，调用 `populate_codex_menu()`，再模拟 Enemies 和 Artifacts 按钮点击，验证网格内容数量和按钮状态。

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/codex_menu_display_regression.gd`

Expected: FAIL，因为当前 `Button2` / `Button3` 禁用，且 `CodexMenu.gd` 没有切换方法。

### Task 2: 目录切换实现

**Files:**
- Modify: `scripts/ui/menus/CodexMenu.gd`
- Modify: `scenes/Root.tscn`

- [ ] **Step 1: Enable Enemies and Artifacts buttons**

在 `Root.tscn` 中给 Cards、Enemies、Artifacts 按钮使用稳定节点名，并解除 Enemies / Artifacts 的禁用状态。Consumables 保持禁用。

- [ ] **Step 2: Implement minimal menu population**

在 `CodexMenu.gd` 中连接三个按钮；Cards 清空网格后沿用现有卡牌实例化；Enemies 和 Artifacts 清空网格后创建只读展示条目。

- [ ] **Step 3: Run regression test**

Run: `godot --headless --path . --script tests/codex_menu_display_regression.gd`

Expected: PASS with `ALL_TESTS_PASSED`。

### Task 3: 全量验证

**Files:**
- Test only.

- [ ] **Step 1: Run Godot smoke check**

Run: `godot --headless --path . --quit`

Expected: process exits with code 0 and no parser errors.

- [ ] **Step 2: Run related layout regression**

Run: `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`

Expected: PASS with `ALL_TESTS_PASSED`。

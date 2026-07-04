# Slay Map Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为选关地图加入起始点、随机层节点数量和虚线路线。

**Architecture:** `ActionGenerateAct.gd` 负责生成不规则但连通的路线图；`Map.gd` 负责显示起点和按数据连接绘制虚线；测试覆盖生成结构和 UI 表现。保持现有 `LocationData` 数据结构，不新增存档字段。

**Tech Stack:** Godot 4.6、GDScript、现有 SceneTree 回归测试。

---

### Task 1: 生成器结构回归

**Files:**
- Create: `tests/map_generation_flow_regression.gd`
- Modify: `scripts/actions/world_generation_actions/ActionGenerateAct.gd`

- [ ] **Step 1: 写失败测试**

测试生成 `act_1` 后必须有起点、每层数量不是固定 5、所有节点可从起点到达、BOSS 可达。

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless --path . --script tests/map_generation_flow_regression.gd`
Expected: FAIL，原因包含楼层数量仍固定或路径结构未满足新规则。

- [ ] **Step 3: 改生成逻辑**

把普通层节点数量改为 RNG 生成 3-5 个；按每层数量居中计算位置；改连接算法为基于相邻层横向位置建立至少一入一出的连接。

- [ ] **Step 4: 运行测试确认通过**

Run: `godot --headless --path . --script tests/map_generation_flow_regression.gd`
Expected: `ALL_TESTS_PASSED`

### Task 2: 地图显示与虚线路线

**Files:**
- Modify: `scripts/ui/Map.gd`
- Modify: `tests/map_location_layout_regression.gd`

- [ ] **Step 1: 写失败测试**

扩展布局回归：地图不跳过起点；存在 `RouteLayer`；路线段数量等于地图数据连接数量。

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless --path . --script tests/map_location_layout_regression.gd`
Expected: FAIL，原因包含缺少起点或缺少路线层。

- [ ] **Step 3: 实现显示**

`populate_locations()` 先创建 `RouteLayer`，绘制所有 `location_next_location_ids` 对应虚线，再实例化节点，确保虚线在节点下方。

- [ ] **Step 4: 运行地图测试确认通过**

Run: `godot --headless --path . --script tests/map_location_layout_regression.gd`
Expected: `ALL_TESTS_PASSED`

### Task 3: 全量验证与提交

**Files:**
- Verify: `tests/map_generation_flow_regression.gd`
- Verify: `tests/map_location_icon_regression.gd`
- Verify: `tests/map_location_layout_regression.gd`

- [ ] **Step 1: 运行地图相关回归**

Run each Godot headless test and confirm `ALL_TESTS_PASSED`.

- [ ] **Step 2: 暂存并提交**

只暂存地图生成、地图 UI、地图测试和本计划/设计文件，避免带入现有无关脏文件。

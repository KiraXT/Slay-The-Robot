### Task 7: 全量验证、视觉验收和文档一致性

**Files:**
- Modify if verification finds defects: title/selection files from Tasks 1-6 only.
- Modify: `docs/superpowers/specs/2026-07-12-title-character-selection-performance-design.md`
- Track: `docs/superpowers/plans/2026-07-12-title-character-selection-performance.md`

**Interfaces:**
- Consumes: 所有前置任务提交。
- Produces: 通过自动化和人工视觉验收的标题/选人流程，以及与实现一致的规格和计划。

- [ ] **Step 1: 运行 Godot 解析烟雾检查**

Run: `godot --headless --path . --quit`

Expected: exit code 0，无 parser error、场景资源错误或无效节点路径。

- [ ] **Step 2: 运行完整相关回归**

```bash
godot --headless --path . --script tests/title_screen_asset_regression.gd
godot --headless --path . --script tests/title_screen_performance_regression.gd
godot --headless --path . --script tests/ui_layout_bounds_regression.gd
godot --headless --path . --script tests/codex_menu_display_regression.gd
```

Expected: 每个测试均输出 `ALL_TESTS_PASSED` 并以 0 退出。

- [ ] **Step 3: 启动游戏进行标题视觉验收**

Run: `godot --path .`

在 1200x700 逻辑画布和 1920x1080 窗口下检查：标题文字清晰；菜单不遮挡角色群像；前景不遮挡焦点；无存档和有存档两种菜单高度均在画布内；空闲动画不改变点击区。

- [ ] **Step 4: 逐角色进行选人视觉验收**

依次选择红、蓝、绿、橙角色并截图。检查每张立绘完整可见、背景地平线不跳动、阵营色清晰但不染满画面、详情和初始遗物不越界、右侧难度/种子/自定义规则完整可用。

- [ ] **Step 5: 验证输入和异常路径**

用鼠标、键盘和手柄分别执行：跳过标题、进入选人、连续切换、返回主菜单、进入图鉴、进入设置、确认开局。演出期间快速重复确认和取消，确认没有半透明节点、错位、无焦点或重复开局。

- [ ] **Step 6: 检查差异范围**

Run: `git status --short`

Expected: 本任务文件与项目已有无关脏文件清晰分离；不得暂存 `external/user_settings.json`、`.superpowers/`、`.DS_Store`、`tmp/` 或本任务之外的生成文件。

- [ ] **Step 7: 提交验证修正和文档**

只暂存本计划、规格补正和验证中产生的标题/选人修正：

```bash
git add docs/superpowers/specs/2026-07-12-title-character-selection-performance-design.md docs/superpowers/plans/2026-07-12-title-character-selection-performance.md
git commit -m "docs: finalize title screen implementation plan"
```

如果 Step 3-5 修改了实现文件，将这些实现修正与对应测试加入同一次最终提交；无实现修正时仅提交两份文档。

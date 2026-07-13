# Task 7 Report: 全量验证、视觉验收和文档一致性

状态：BLOCKED

验证基线：`bbdc21d`（Task 6 已复审通过）

## 自动化验证

| 命令 | 结果 | 说明 |
| --- | --- | --- |
| `godot --headless --path . --quit` | PASS，退出码 0 | 未出现 parser error、场景资源错误或无效节点路径。仅输出既有 `FileLoader` 导出模板提示。 |
| `godot --headless --path . --script tests/title_screen_asset_regression.gd` | FAIL，退出码 1 | Task 1 的 RED 资产测试：缺少 `title_sky.png`、`title_far_islands.png`、`title_mid_ruins.png`、`title_platform.png`、`title_foreground.png`、`title_ornament.png`、`particle_soft.png`、`particle_spark.png`；红、蓝、绿、橙角色的 `character_background_texture_path` 均为空。未修改测试、资产或角色 JSON。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | PASS，退出码 0 | 输出 `ALL_TESTS_PASSED`。退出时仍有既有 `ObjectDB instances leaked` 和 `4 resources still in use` 警告。 |
| `godot --headless --path . --script tests/ui_layout_bounds_regression.gd` | FAIL，退出码 1 | 仅命中任务前已有的战斗 UI 问题：`Hand cards extend below the combat canvas: bottom 718.0, limit 688.0`。未出现标题三栏布局、标题节点或标题重叠断言失败；未修复战斗 UI。 |
| `godot --headless --path . --script tests/codex_menu_display_regression.gd` | PASS，退出码 0 | 输出 `ALL_TESTS_PASSED`。退出时仍有既有 `ObjectDB instances leaked` 和 `9 resources still in use` 警告。 |

## GUI 与视觉验收

已启动 `godot --path .`，引擎成功初始化 Metal 渲染器；随后 GUI 状态读取被任务中断，未取得可审阅截图，也未完成标题、四个角色状态和鼠标/键盘/手柄的交互验收。

完整视觉验收同时受 Task 1 阻塞：八张标题分层/粒子图片和四个角色背景路径尚未交付，因此无法对最终标题舞台、角色背景地平线和色彩表现作出验收结论。

## 工作区范围

`git status --short` 显示的既有无关未跟踪内容包括：

- `.superpowers/sdd/` 的前序任务简报、报告和 review diff；
- `designer/art_source/validation-pack/2026-06/` 的导入副产物；
- `scripts/validators/ValidatorCharacter.gd.uid` 与若干 `tests/*.uid`；
- Task 1 的未跟踪 RED 测试 `tests/title_screen_asset_regression.gd`。

本任务只新增本报告并更新计划；未暂存或修改 Task 1 资产/数据、战斗 UI、`external/user_settings.json`、`.DS_Store`、`tmp/` 或上述无关文件。

## 文档一致性

规格无需修改：它准确描述最终目标行为。计划补充了本轮验证状态、两项失败的归因和恢复步骤，使当前实现状态与未完成的 Task 1 资产工作明确分离。

## 阻塞与恢复

1. 完成并提交 Task 1 的八张标题素材、四张角色背景图及四个角色 JSON 的 `character_background_texture_path` 后，重新运行 `tests/title_screen_asset_regression.gd`。
2. 在可观察的桌面 GUI 会话中重启游戏，在 1200x700 逻辑画布和 1920x1080 窗口下截取标题、选人稳定态和四个角色选中态；完成鼠标、键盘、手柄及快速确认/取消路径验收。
3. 战斗手牌越界由其所有者单独修复后，重跑 `tests/ui_layout_bounds_regression.gd`；该问题不阻塞标题实现的归因，但阻止四项回归全绿。
4. 两项失败消除并完成 GUI 验收后，Task 7 才可从 `BLOCKED` 更新为 `DONE`。

# Task 4 Report: 角色选择数据流与单次开局请求

## 实现提交

- 初始实现 SHA：`c0006eb`，`refactor: isolate character selection flow`
- 初始报告 SHA：`0f4ab0a`，`docs: add task 4 report`
- 独立审查补修 SHA：`5f6373e`，`fix: cancel stale title run requests`

## 独立审查补修

- `TitleScreen` 保存最后有效的 `CharacterData`，并通过 `get_current_character_data()` 暴露给后续 Task 5 舞台层；本任务未实现 `MenuBackdrop`。
- 从 LEAVING 返回主菜单时清空 pending 请求并终止活动 LEAVING tween。过期或重复的 `transition_finished("LEAVING")` 在状态不再为 LEAVING 或请求已被消费时忽略。
- 开始运行前先消费 pending 请求，防止同步信号重入导致重复 `Global.start_run()`。
- 标题回归在实例化场景前删除隔离测试目录的存档，避免本机继续游戏存档影响主菜单焦点断言。
- 扩展回归覆盖按钮本地 `selected -> character_selected -> character_changed` 链、空角色列表、无初始遗物/遗物数据缺失清理、CharacterData 舞台接口、取消旧请求、规则数组快照以及重复 LEAVING 完成。

## RED / GREEN 证据

- RED: 新增标题回归后运行 `godot --headless --path . --script tests/title_screen_performance_regression.gd`，失败于缺少 `character_changed`、`run_requested`，且无效角色未禁用开始按钮。
- GREEN: 实现局部角色选择信号、完整开局请求、请求锁、空状态和 TitleScreen 的 LEAVING 延迟开局后，使用隔离 Godot 用户目录运行同一标题回归，输出 `ALL_TESTS_PASSED`。

## 修改文件

- `scripts/ui/CharacterSelectionButton.gd`
- `scripts/ui/CharacterButtonContainer.gd`
- `scripts/ui/menus/NewRunMenu.gd`
- `scripts/ui/menus/TitleScreen.gd`
- `scenes/ui/menus/TitleScreen.tscn`
- `tests/title_screen_performance_regression.gd`

## 验证结果

| 验证 | 结果 |
| --- | --- |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_final_title --path . --script tests/title_screen_performance_regression.gd` | 通过：`ALL_TESTS_PASSED`；真实开局检查仍有既有退出资源警告 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_smoke --path . --quit` | 通过 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_codex --path . --script tests/codex_menu_display_regression.gd` | 通过：`ALL_TESTS_PASSED`；退出时仍有既有 ObjectDB/资源泄漏警告 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_layout --path . --script tests/ui_layout_bounds_regression.gd` | 已知基线失败：战斗手牌 bottom `718.0` 超过 limit `688.0` |
| `git diff --check` | 通过 |

## 未处理基线项

- Task 1 的 `tests/title_screen_asset_regression.gd` 与美术/角色 JSON 仍阻塞，未修改、暂存或提交。
- `tests/ui_layout_bounds_regression.gd` 的手牌边界失败与本任务无关。
- Codex 菜单回归退出时的 ObjectDB/资源泄漏警告为既有问题。
- 默认 Godot `user://logs` 在受限运行环境中可能无法轮转日志；使用隔离用户目录后的回归正常通过。

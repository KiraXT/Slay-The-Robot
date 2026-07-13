# Task 4 Report: 角色选择数据流与单次开局请求

## 实现提交

- SHA: `c0006eb`
- Message: `refactor: isolate character selection flow`

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
| `godot --headless --user-data-dir /tmp/slay_robot_task4_godot_user --path . --script tests/title_screen_performance_regression.gd` | 通过：`ALL_TESTS_PASSED` |
| `godot --headless --path . --quit` | 通过 |
| `godot --headless --path . --script tests/codex_menu_display_regression.gd` | 通过：`ALL_TESTS_PASSED`；退出时仍有既有 ObjectDB/资源泄漏警告 |
| `godot --headless --path . --script tests/ui_layout_bounds_regression.gd` | 已知基线失败：战斗手牌 bottom `718.0` 超过 limit `688.0` |
| `git diff --check` | 通过 |

## 未处理基线项

- Task 1 的 `tests/title_screen_asset_regression.gd` 与美术/角色 JSON 仍阻塞，未修改、暂存或提交。
- `tests/ui_layout_bounds_regression.gd` 的手牌边界失败与本任务无关。
- Codex 菜单回归退出时的 ObjectDB/资源泄漏警告为既有问题。
- 默认 Godot `user://logs` 在受限运行环境中可能无法轮转日志；使用隔离用户目录后的回归正常通过。

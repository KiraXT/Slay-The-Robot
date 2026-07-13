# Task 4 Report: 角色选择数据流与单次开局请求

## 实现提交

- 初始实现 SHA：`c0006eb`，`refactor: isolate character selection flow`
- 初始报告 SHA：`0f4ab0a`，`docs: add task 4 report`
- 独立审查补修 SHA：`5f6373e`，`fix: cancel stale title run requests`
- 第二轮审查补修 SHA：`02c8343`，`fix: bind title runs to transition generations`

## 独立审查补修

- `TitleScreen` 保存最后有效的 `CharacterData`，并通过 `get_current_character_data()` 暴露给后续 Task 5 舞台层；本任务未实现 `MenuBackdrop`。
- 从 LEAVING 返回主菜单时清空 pending 请求并终止活动 LEAVING tween。过期或重复的 `transition_finished("LEAVING")` 在状态不再为 LEAVING 或请求已被消费时忽略。
- 开始运行前先消费 pending 请求，防止同步信号重入导致重复 `Global.start_run()`。
- 标题回归在实例化场景前删除隔离测试目录的存档，避免本机继续游戏存档影响主菜单焦点断言。
- 扩展回归覆盖按钮本地 `selected -> character_selected -> character_changed` 链、空角色列表、无初始遗物/遗物数据缺失清理、CharacterData 舞台接口、取消旧请求、规则数组快照以及重复 LEAVING 完成。

## 第二轮审查补修

- 每个 LEAVING 请求获得单调递增 generation；活动 tween 的完成回调绑定该 generation，`complete_leaving_request()` 仅消费当前 generation。
- 测试在第二个 LEAVING 请求演出期间显式投递第一个 generation 的完成，验证旧回调不启动也不消费新请求；随后等待第二个 tween 自然完成。
- TitleScreen 提供可替换的开局观察器，回归断言最终消费的实际参数包含角色、种子 `27182`、难度 `1` 和自定义规则 `pending_modifier`，并证明后续 UI 数组修改没有污染 pending 快照。
- 回归实际调用 `_on_character_selected("missing_character")`，并断言禁用开始与空状态；在无初始遗物及遗物数据缺失时，断言备用 `icon_menu.png` 纹理已被使用。

## 最终复审补修

- 删除 `TitleScreen.set_run_start_handler()` 和 `run_start_handler`，LEAVING 请求完成后只能调用实际 `Global.start_run()`。
- 标题回归不再替换启动行为：保留 generation 竞态顺序（旧 generation 在新请求 LEAVING 期间到达），通过真实 `Signals.run_started`、`Global.is_run` 和 `Global.player_data` 断言旧回调未启动，新请求自然完成后实际收到角色、种子 `27182`、难度 `1` 及完整规则数组 `["run_modifier_difficulty_1", <真实 custom modifier>]`。
- 测试使用运行时加载的真实 custom modifier ID，并在启动请求后清空 UI 选择数组，证明 `pending_run_request` 的规则快照未被后续修改污染；测试结束后调用真实 `Global.end_run()` 并删除隔离存档。

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
| `godot --headless --user-data-dir /tmp/slay_robot_task4_round2_green --path . --script tests/title_screen_performance_regression.gd` | 通过：`ALL_TESTS_PASSED` |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_round2_smoke --path . --quit` | 通过 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_round2_codex --path . --script tests/codex_menu_display_regression.gd` | 通过：`ALL_TESTS_PASSED`；退出时仍有既有 ObjectDB/资源泄漏警告 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_round2_layout --path . --script tests/ui_layout_bounds_regression.gd` | 已知基线失败：战斗手牌 bottom `718.0` 超过 limit `688.0` |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_final_review_red2 --path . --script tests/title_screen_performance_regression.gd` | RED：仅失败于旧 `set_run_start_handler` 仍存在，证明新测试不依赖替身 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_final_review_green --path . --script tests/title_screen_performance_regression.gd` | 通过：`ALL_TESTS_PASSED`；实际开局后仍有既有退出资源警告 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_final_review_smoke --path . --quit` | 通过 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_final_review_codex --path . --script tests/codex_menu_display_regression.gd` | 通过：`ALL_TESTS_PASSED`；退出时仍有既有 ObjectDB/资源泄漏警告 |
| `godot --headless --user-data-dir /tmp/slay_robot_task4_final_review_layout --path . --script tests/ui_layout_bounds_regression.gd` | 已知基线失败：战斗手牌 bottom `718.0` 超过 limit `688.0` |
| `git diff --check` | 通过 |

## 未处理基线项

- Task 1 的 `tests/title_screen_asset_regression.gd` 与美术/角色 JSON 仍阻塞，未修改、暂存或提交。
- `tests/ui_layout_bounds_regression.gd` 的手牌边界失败与本任务无关。
- Codex 菜单回归退出时的 ObjectDB/资源泄漏警告为既有问题。
- 默认 Godot `user://logs` 在受限运行环境中可能无法轮转日志；使用隔离用户目录后的回归正常通过。

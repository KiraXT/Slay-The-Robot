# Task 7 Report: 全量验证、视觉验收和文档一致性

状态：DONE

验证基线：`4b3b4fa` 之后补齐 Task 1 资产、角色 JSON 与战斗手牌布局基线。

## 自动化验证

| 命令 | 结果 | 说明 |
| --- | --- | --- |
| `godot --headless --path . --quit` | PASS，退出码 0 | 未出现 parser error、场景资源错误或无效节点路径。仅输出既有 `FileLoader` 导出模板提示。 |
| `sips -g pixelWidth -g pixelHeight external/sprites/ui/title_screen/*.png external/sprites/characters/character_*/character_*_background.png` | PASS，退出码 0 | 标题/角色背景均为 1200x700；`particle_soft.png` 与 `particle_spark.png` 均为 64x64。 |
| `godot --headless --path . --script tests/title_screen_asset_regression.gd` | PASS，退出码 0 | 输出 `ALL_TESTS_PASSED`；八张标题分层/粒子图片和四个角色背景路径均已登记。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | PASS，退出码 0 | 输出 `ALL_TESTS_PASSED`。退出时仍有既有 `ObjectDB instances leaked` 和 `4 resources still in use` 警告。 |
| `godot --headless --path . --script tests/ui_layout_bounds_regression.gd` | PASS，退出码 0 | 输出 `ALL_TESTS_PASSED`；战斗手牌基准上移后不再越过 700 画布安全边界。 |
| `godot --headless --path . --script tests/codex_menu_display_regression.gd` | PASS，退出码 0 | 输出 `ALL_TESTS_PASSED`。退出时仍有既有 `ObjectDB instances leaked` 和 `9 resources still in use` 警告。 |

## GUI 与视觉验收

使用临时脚本启动真实 Godot 窗口并自动截图：

`godot --path . --script tmp_title_visual_validation.gd`

结果：PASS，输出 `SCREENSHOTS_WRITTEN:/tmp/slay_robot_title_validation`。

生成截图：

- `/tmp/slay_robot_title_validation/main_menu.png`
- `/tmp/slay_robot_title_validation/character_select.png`
- `/tmp/slay_robot_title_validation/character_red.png`
- `/tmp/slay_robot_title_validation/character_blue.png`
- `/tmp/slay_robot_title_validation/character_green.png`
- `/tmp/slay_robot_title_validation/character_orange.png`

抽查结果：主菜单、选人稳定态和红色角色选中态均非空；标题舞台、角色立绘、左侧角色信息、初始遗物、底部头像、右侧难度/自定义规则/种子/开始/返回控件均在 1200x700 画布内。角色选中截图通过真实 `CharacterButtonContainer` 选择信号生成，左侧信息、头像选中态和中间立绘同步更新。

临时截图脚本只用于验收，已从工作区删除；截图保留在 `/tmp/slay_robot_title_validation` 供本轮检查追溯。

## 已补齐内容

- 新增八张标题分层/粒子 PNG：天空、远景浮岛、中景遗迹、平台、前景、装饰、柔光粒子、星光粒子。
- 新增红、蓝、绿、橙四个角色背景 PNG，并在四个角色 JSON 中登记 `character_background_texture_path`。
- 将原本失败的 Task 1 资产回归转为通过。
- 将战斗手牌容器和 `HandSizeExceededRect` 从 y=624 上移到 y=590，消除 `ui_layout_bounds_regression.gd` 的既有越界失败。

## 文档一致性

计划和进度台账已更新为当前状态：Task 1 已补齐，Task 7 自动化与截图验收已完成。规格无需修改，原目标约束仍与实现一致。

## 剩余风险

`tests/title_screen_performance_regression.gd` 与 `tests/codex_menu_display_regression.gd` 在退出阶段仍会输出既有 ObjectDB/resource 警告；本轮未改变该行为，测试退出码为 0 且功能断言通过。

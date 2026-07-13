# Task 3 实施报告

## 状态

已完成并提交：`ab13d00 feat: add skippable title screen transitions`

## 实现内容

- 新增 `TitlePerformanceController`，提供标题入场、主菜单与角色选择切换、开局确认、跳过当前 Tween，以及四个稳定最终状态函数。
- `TitleScreen` 改为状态协调器，公开状态名称与跳过接口；处理转场完成、窗口焦点恢复、临时状态输入跳过，以及 Codex/Settings 返回后的焦点恢复。
- 标题场景增加 `Backdrop`、`TitleOrnament`、根级 `GameTitle`、`TransitionOverlay` 和控制器节点，并为控制器依赖的节点设置唯一名称。
- 标题回归测试覆盖入场/新开局/返回跳过、窗口焦点恢复后的稳定状态、位置/缩放/透明度/鼠标过滤器及 Settings 返回的焦点恢复。

## RED/GREEN 证据

- RED：`godot --headless --path . --script tests/title_screen_performance_regression.gd` 因 `skip_active_transition` 不存在失败。
- GREEN：同一命令最终输出 `ALL_TESTS_PASSED`。
- 实现期间还发现并修复控制器唯一节点依赖、测试脚本视口作用域和测试在入场阶段过早记录坐标的问题；最终回归已覆盖这些路径。

## 测试命令与结果

| 命令 | 结果 |
| --- | --- |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | RED：缺少跳过接口。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | 中间失败：控制器全局类型/菜单唯一节点未就绪，已修复。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | GREEN：`ALL_TESTS_PASSED`。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | 扩展断言首次解析失败：测试错误调用 `SceneTree.get_viewport()`，已修复。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | 扩展断言首次失败：测试在入场动画中记录坐标，已修复基线采样时机。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | 最终 GREEN：`ALL_TESTS_PASSED`。 |
| `godot --headless --path . --quit` | 通过，退出码 0，无解析或场景错误。 |
| `godot --headless --path . --script tests/codex_menu_display_regression.gd` | 通过：`ALL_TESTS_PASSED`；退出时保留既有 ObjectDB/资源泄漏警告。 |
| `godot --headless --path . --script tests/ui_layout_bounds_regression.gd` | 失败：既有战斗手牌边界 `718.0 > 688.0`，与 Task 3 无关。 |

未运行、未修改、未暂存 `tests/title_screen_asset_regression.gd`；未暂存首次导入产生的 `.import`/`.uid` 文件。

## 文件变更

- 新增：`scripts/ui/menus/TitlePerformanceController.gd`
- 修改：`scripts/ui/menus/TitleScreen.gd`
- 修改：`scenes/ui/menus/TitleScreen.tscn`
- 修改：`tests/title_screen_performance_regression.gd`

## 自审和关注点

- 稳定状态统一同步设置可见性、位置、缩放、透明度与鼠标过滤器；跳过和窗口恢复都会完成到同一稳定状态。
- 未涉及 Task 1 美术、Task 4 信号/开局数据流或后续三栏布局。
- 关注点：布局回归的战斗手牌失败和 Codex 退出泄漏警告仍存在，均非本任务引入。

## 审查补修（后续提交）

### 实现内容

- 将瞬态状态的输入处理从 `_unhandled_input()` 提升到 `_input()`，在 GUI 控件处理前完成跳过并调用 `set_input_as_handled()`，使确认、取消和鼠标按下不会传递到可见子按钮。
- 修正根级 `GameTitle` 的右侧锚点偏移，并移除原先依赖 `MainMenu` 40px 高度的垂直锚点，保持 1200px 标题画布水平居中。
- 角色选择返回主菜单的自然完成和跳过路径都会选择主菜单纵向列表中首个可见、可聚焦按钮；Settings 返回复用同一回退逻辑。
- 回归测试通过 `Input.parse_input_event()` 分发真实确认、取消和鼠标点击，验证它们仅跳过转场、不启动 run，并检查主菜单/角色选择最终状态的装饰、标题、遮罩和隐藏菜单属性。

### RED/GREEN 证据

- 测试扩展的首次运行因测试使用了错误的输入注入 API `Input.parse_input()` 而解析失败；改为 Godot 4.6 的 `Input.parse_input_event()`。
- 第二次测试编译不能解析 `Signals` 单例；改为从场景树取得 autoload 节点后连接 `run_started`。
- 行为 RED：标题未居中；确认键在入场期间先触发 `NewRunButton`，状态变为 `TO_CHARACTER_SELECT`；自然和跳过返回的焦点均为空。
- GREEN：`godot --headless --path . --script tests/title_screen_performance_regression.gd` 输出 `ALL_TESTS_PASSED`。

### 测试命令与结果

| 命令 | 结果 |
| --- | --- |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | RED：标题中心、确认输入拦截、自然/跳过返回焦点断言失败。 |
| `godot --headless --path . --script tests/title_screen_performance_regression.gd` | GREEN：`ALL_TESTS_PASSED`；覆盖真实确认、取消、鼠标输入、最终视觉状态和焦点恢复。 |
| `godot --headless --path . --quit` | 通过，退出码 0。 |
| `godot --headless --path . --script tests/codex_menu_display_regression.gd` | 通过：`ALL_TESTS_PASSED`；仍有既有 ObjectDB/资源泄漏退出警告。 |
| `godot --headless --path . --script tests/ui_layout_bounds_regression.gd` | 失败：既有战斗手牌边界 `718.0 > 688.0`，与本次补修无关。 |

### 文件变更与自审

- 修改：`scripts/ui/menus/TitleScreen.gd`、`scenes/ui/menus/TitleScreen.tscn`、`tests/title_screen_performance_regression.gd`。
- 本次未修改 `TitlePerformanceController.gd`、Task 1 美术资源或 Task 4 数据/开局接线；未暂存导入产物或 `tests/title_screen_asset_regression.gd`。
- 关注点：Codex 回归的资源泄漏警告及布局回归的战斗手牌失败仍需其各自任务处理。

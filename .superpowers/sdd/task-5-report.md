# Task 5 Report: 构建分层舞台、三栏选人布局和资源回退

状态：DONE_WITH_CONCERNS

## 执行记录

- Implementer `Bacon` 写入任务 5 半成品后长时间无响应，未返回报告或提交，已关闭。
- 收敛 agent `Noether` 接手后同样未返回报告或提交，已关闭。
- 主线程接管审计与最小修补：补充 `MenuBackdrop` 可选资源加载检查，避免 Task 1 背景资产缺失时调用 `FileLoader.load_texture()` 产生错误日志。

## 改动摘要

- 新增 `scripts/ui/menus/MenuBackdrop.gd`：
  - 暴露 `set_character_background(path, immediate)`、`preload_character_backgrounds()`、`start_idle_motion()`、`stop_idle_motion()`。
  - 分层加载标题背景，缺失资产时保留浅青 fallback 和平台 fallback。
  - 角色背景双缓冲淡变，切换时长 0.22 秒。
- 更新 `scenes/ui/menus/TitleScreen.tscn`：
  - 建立 `Backdrop` 分层节点。
  - 将 `NewRunMenu` 改为 `InfoPanel`、`CharacterStage`、`RunConfigPanel` 三栏稳定布局。
  - 保留 `TitlePerformanceController` 既有节点名，避免破坏任务 3/4 转场脚本引用。
- 更新 `scripts/ui/menus/TitleScreen.gd`：
  - 响应 `character_changed` 时刷新 `CharacterPortrait`、背景、舞台环和角色光。
  - 立绘缺失时回退到头像，再回退到 `icon_menu.png`。
- 更新 `scripts/ui/menus/NewRunMenu.gd`：
  - 将详情、难度、种子、自定义规则、开始和返回按钮引用迁移到新的 `InfoPanel` / `RunConfigPanel` 节点路径。
- 更新 `CharacterSelectionButton` 场景和脚本：
  - 按 72x72 稳定尺寸呈现头像。
  - 使用内部头像、焦点轮廓和选中装饰，避免选中/聚焦改变布局尺寸。
- 更新 `themes/title_screen_theme.tres`：
  - 收敛大圆角，保留白、青、金橙和阵营色对比。
- 更新回归测试：
  - `tests/ui_layout_bounds_regression.gd` 覆盖标题三栏节点、边界和重叠检查，并在 1920x1080 下复查。
  - `tests/title_screen_performance_regression.gd` 覆盖新节点路径、Backdrop 接口、72x72 角色按钮和角色舞台 fallback。

## 验证

- `godot --headless --path . --script tests/title_screen_performance_regression.gd`
  - 通过，输出 `ALL_TESTS_PASSED`。
  - 仍有既有退出资源警告：`ObjectDB instances leaked` / `4 resources still in use`。
  - 测试内部将头像路径改为 `sprites/ui/flipper/icon_menu.png` 时，Godot 仍提示外部图片加载导出警告；不影响测试结果。
- `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`
  - 失败原因仍为既有战斗手牌越界：`Hand cards extend below the combat canvas: bottom 718.0, limit 688.0`。
  - 未出现标题三栏布局、节点缺失或重叠失败。
- `godot --headless --path . --script tests/title_screen_asset_regression.gd`
  - 失败，原因是 Task 1 资产仍未生成：
    - 缺少标题背景/前景/粒子图片。
    - 角色 JSON 尚无 `character_background_texture_path`。

## 自查

- 任务 5 的代码路径不依赖 Task 1 资产存在，缺失时可以显示 fallback。
- `TitlePerformanceController` 既有命名保持不变。
- 未修改角色 JSON、未提交 Task 1 的 RED 资产测试。

## Concerns

- Task 1 资产生成仍阻塞，因此 `tests/title_screen_asset_regression.gd` 不能通过；任务 5 只能保证 fallback 可用。
- `tests/ui_layout_bounds_regression.gd` 仍包含战斗手牌既有失败；标题布局本身已通过该测试新增断言。
- 任务 5 起始实现来自两个静默中断的子 agent，已由主线程做局部审计和回归验证，但仍建议任务 5 后进行独立 review。

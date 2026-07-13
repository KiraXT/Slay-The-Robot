# Task 6 Report: Title Screen Performance

## 改动

- `TitlePerformanceController` 补齐标题入场、主菜单与角色选择切换、确认离场的时间线；稳定状态会恢复背景位置、菜单透明度、输入过滤和角色舞台缩放。
- `MenuBackdrop` 改为单一时间计数器驱动的空闲视差，停止时恢复三层原位；保留角色背景 0.22 秒交叉淡入淡出。
- `MainMenu` 为按钮复用 Tween，实现焦点/鼠标位移、颜色反馈、按下缩放，并提供默认焦点入口。
- `CharacterSelectionButton` 增加头像焦点升起动画，选中或键盘焦点均保持外框可见。
- `TitleScreen` 增加角色肖像 0.22 秒收敛切换，转场完成后恢复相应焦点，并把离场请求消费收敛到 `LEAVING` 完成信号。
- 扩展标题演出回归：稳定最终状态、重复新游戏请求、主菜单与头像焦点反馈、快速角色切换收敛和重复开始输入保护。

## TDD

先扩展 `tests/title_screen_performance_regression.gd`，红测确认缺少角色选择背景稳定位置、主菜单焦点位移、头像上浮和选中外框保持。随后补齐实现并转绿。

## 测试

1. `godot --headless --path . --script tests/title_screen_performance_regression.gd`
   - 结果：通过，输出 `ALL_TESTS_PASSED`。
   - 退出仍输出既有 `ObjectDB instances leaked` 和 `4 resources still in use` 警告。
2. `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`
   - 结果：失败，仅剩既有战斗手牌越界：`bottom 718.0, limit 688.0`。

## 自查

- 所有四类转场在完成或跳过后先应用稳定状态，再发出完成信号。
- `show_new_run_menu()` 在非主菜单状态直接返回，避免并发转场。
- 离场请求使用挂起请求和 generation 防止重复消费。
- 角色切换会终止旧 Tween，最终视觉以最后一次角色信号为准。
- 未修改 Task 1 资产、角色 JSON 或资产回归测试。

## Concerns

- 初始实现中的 `AmbientParticles`/`ConfirmParticles` 为 `Control` 占位节点，已在后续 review fix 中替换为可渲染的 `CPUParticles2D`。
- 标题性能回归通过后仍有既有资源清理警告；以 `--verbose` 复查时 Godot 因受限环境无法创建 `user://logs` 而启动崩溃，未对无关资源生命周期扩大修复范围。
- 布局回归仍只剩任务说明已知的战斗手牌越界；未改动战斗 UI。

## Review Fix: Title Particles

- 将 `Backdrop/AmbientParticles` 和 `Backdrop/ConfirmParticles` 从 `Control` 占位节点替换为带径向渐变纹理的 `CPUParticles2D`；两者保持在 `Backdrop` 内，不参与 Control 布局或鼠标命中。
- 空闲粒子固定 `amount = 24`，确认粒子固定 `amount = 16`；场景以关闭发射初始化，`start_idle_motion()`、`stop_idle_motion()` 和确认演出通过既有 `MenuBackdrop._set_particle_state()` 切换 `emitting`。
- `tests/title_screen_performance_regression.gd` 新增节点类型、固定数量、空闲启停及确认演出发射状态断言。

### 修复测试

1. `godot --headless --path . --script tests/title_screen_performance_regression.gd`
   - 结果：通过，输出 `ALL_TESTS_PASSED`。
   - 退出仍输出既有 `ObjectDB instances leaked` 和 `4 resources still in use` 警告。
2. `godot --headless --path . --script tests/ui_layout_bounds_regression.gd`
   - 结果：失败，仅剩已知的战斗手牌越界：`bottom 718.0, limit 688.0`；未改动战斗 UI。

# GM 控制台最终复审轻微问题修复报告

## Status

已完成最终复审提出的两项轻微问题修复。

## RED Failures Observed

在修改生产代码前，`godot --headless --path . --script tests/gm_command_executor_regression.gd` 按预期报告以下断言失败：

- 单卡加手牌的上限预期为现有手牌数加 1，实际为 `9999`。
- `cards all hand` 预期只发出一个批量请求，实际发出 92 个请求。
- `money add -8` 在金币为 0 时预期报告变化 `0`，实际报告 `-8`。
- `hp heal 5` 在生命值满时预期报告变化 `0`，实际报告 `5`。

## Fix Summary

- 移除固定的 GM 手牌上限。发牌请求改用当前手牌数量加本次请求卡牌数量。
- `cards all hand` 现在创建全部卡牌实例并一次性发出手牌请求。
- `money add` 和 `hp heal` 现在根据操作前后的值报告实际变化量。
- 回归测试覆盖非空手牌的精确上限、全卡批量请求及金币/生命的钳制边界。

## Verification Results

以下命令均以退出码 0 完成并输出 `ALL_TESTS_PASSED`：

- `godot --headless --path . --script tests/gm_command_executor_regression.gd`
- `godot --headless --path . --script tests/gm_console_toggle_regression.gd`
- `godot --headless --path . --script tests/ui_mouse_fallback_regression.gd`
- `godot --headless --path . --script tests/card_effects_regression.gd`

## Concerns

`gm_command_executor_regression.gd` 通过后仍输出既有的 ObjectDB 实例泄漏和 9 个资源仍在使用的提示；本次未扩大范围处理该测试清理问题。

## Commit SHA

`7ebe371`

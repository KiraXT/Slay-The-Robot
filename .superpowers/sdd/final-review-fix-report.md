# GM 控制台最终审查修复报告

## Status

已完成最终审查发现的两项重要问题和一项低风险解析问题的修复。

## RED Failures Observed

在生产代码修改前，执行以下命令：

```sh
godot --headless --path . --script tests/gm_command_executor_regression.gd
```

预期且实际观察到以下失败行：

```text
ERROR: commands should accept tabs and repeated whitespace between tokens
ERROR: card add hand should use a GM-specific hand limit above the normal cap
ERROR: cards all hand should use a limit large enough for all requested cards
```

在生产代码修改前，执行以下命令：

```sh
godot --headless --path . --script tests/gm_console_toggle_regression.gd
```

预期且实际观察到以下失败行：

```text
ERROR: Root input should hide a visible GMConsole before other Escape handlers
```

## Fix Summary By Finding

- 手牌命令：`GMCommandExecutor` 为 GM 发牌请求使用 9999 的专用手牌上限，避免 `card add ... hand` 和 `cards all hand` 在普通 10 张上限时静默弃牌。回归覆盖单卡和全卡请求。
- Escape：`Root._input()` 在控制台可见时优先识别按下、非连发的 `ui_cancel`，调用 `GMConsole.hide_console()`、标记输入已处理并返回。已移除 `GMConsole._unhandled_input()` 中较晚的 Escape 处理。
- 空白解析：命令 tokenizer 改为匹配非空白 token，支持制表符和重复空白。

## Verification Results

以下命令均输出 `ALL_TESTS_PASSED`：

```sh
godot --headless --path . --script tests/gm_command_executor_regression.gd
godot --headless --path . --script tests/gm_console_toggle_regression.gd
godot --headless --path . --script tests/ui_mouse_fallback_regression.gd
godot --headless --path . --script tests/card_effects_regression.gd
```

## Concerns / Follow-ups

- `gm_command_executor_regression.gd` 在通过后仍输出既有 `ObjectDB instances leaked at exit` 和 `9 resources still in use at exit` 警告。本次未进行超出 GM 审查范围的资源生命周期重构。

## Commit SHA

`2ee76b2`

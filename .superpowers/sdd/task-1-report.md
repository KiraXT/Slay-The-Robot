# Task 1 修复报告：角色事件池回归测试

## Status

DONE

## Commit

```text
1950af6 fix: isolate character event pool regression fixtures
```

## 本次修复

- 将 `tests/character_event_pool_regression.gd` 从“修改正式事件 / 正式事件池数据”的做法改为“动态创建并注册测试专用 `EventData` / `EventPoolData` 夹具”。
- 测试夹具通过 `Global.CLASS_NAME_TO_CLASS[...]` 动态构造，再经 `Global.register_rod(..., false)` 注册，避免 headless 模式下的静态类引用顺序问题。
- 测试结束后主动清理本次注册的测试事件与测试事件池，避免测试过程残留。
- 去掉裸常量 `REMOVE_FAILED_STRATEGY := 1`，改为依赖 `EventData` 默认的 `FailedEventPoolStrategies.REMOVE`，并在代码中注明意图。

## 验证

执行命令：

```bash
godot --headless --path . -s tests/character_event_pool_regression.gd
```

结果：

```text
Exit code: 0
ALL_TESTS_PASSED
```

说明：

- 本次未修改 Task 1 运行时代码，只修正测试隔离方式，因此未额外运行 `tests/map_generation_flow_regression.gd`。

## 自检

- 测试已不再依赖或覆写正式事件、正式事件池。
- 测试中的 `EventData` / `EventPoolData` 构造路径避免了先前的静态引用编译问题。
- 变更范围限制在 Task 1 允许的文件内：`tests/character_event_pool_regression.gd` 与 `.superpowers/sdd/task-1-report.md`。

## Concerns

- 报告中记录的是实际修复提交 `1950af6`；若后续还有补充提交，需要以最新交付记录为准。

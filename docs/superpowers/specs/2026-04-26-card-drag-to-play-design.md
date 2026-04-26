# Card Drag-to-Play 设计方案

**日期**: 2026-04-26
**目标**: 将卡牌释放机制从"点击卡牌-点击目标"改为"拖拽卡牌到目标释放"，包含轨迹线指引、卡牌放大效果，参考杀戮尖塔表现。

---

## 1. 目标

- 玩家左键按住卡牌并拖动到目标上方松开，即可完成释放
- 拖拽过程中显示轨迹线（从卡牌原始位置到鼠标位置）
- 拖拽时卡牌动态放大（基础 1.0x，最大 1.4x，根据到目标的距离等比放缩）
- 支持四种释放目标：敌人、自己（玩家）、无需目标区域、取消
- 拖拽中按右键可立即取消，卡牌弹回手牌

---

## 2. 修改文件清单

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `scripts/ui/Card.gd` | 修改 | 输入处理从 `gui_input` 改为 `button_down`/`button_up`，新增拖拽相关信号 |
| `scripts/ui/Hand.gd` | 修改 | 新增拖拽状态机、轨迹线管理、目标检测、释放/取消判定 |
| `scenes/ui/Card.tscn` | 修改 | 可选：调整 CardButton 属性以支持拖拽检测 |
| `scripts/ui/Combat.gd` | 不修改 | 保持现有回合管理逻辑，目标检测复用现有 SelectionButton |

---

## 3. 新增节点

在 `Hand.tscn`（或运行时动态创建）中添加：

```
Hand (Control)
├── ... (existing nodes)
└── DragLine (Line2D)          # 新增：拖拽轨迹线
    - visible: false
    - width: 3.0
    - default_color: Color(1, 1, 1, 0.6)   # 白色半透明
    - z_index: 100                         # 确保在最上层
```

**注意**: 轨迹线也可在 `Hand.gd._ready()` 中通过代码动态创建 `Line2D.new()`，避免修改 `.tscn` 场景文件。

---

## 4. Card.gd 改动

### 4.1 新增信号

```gdscript
signal card_drag_started(card: Card)        # 左键按下开始拖拽
signal card_drag_ended(card: Card)          # 左键松开结束拖拽
signal card_drag_cancelled(card: Card)      # 右键取消拖拽
```

### 4.2 输入处理改造

**当前逻辑**:
```gdscript
func _on_button_gui_input(event: InputEvent):
    if event.is_action_pressed("left_click"):
        card_selected.emit(self)
    if event.is_action_pressed("right_click"):
        card_right_clicked.emit(self)
```

**改造后逻辑**:
```gdscript
func _on_button_gui_input(event: InputEvent):
    if event.is_action_pressed("right_click"):
        card_drag_cancelled.emit(self)      # 拖拽中右键取消
        card_right_clicked.emit(self)       # 保持原有的右键功能

func _on_button_down():
    card_drag_started.emit(self)            # 左键按下开始拖拽

func _on_button_up():
    card_drag_ended.emit(self)              # 左键松开结束拖拽
```

**说明**:
- `card_selected` 信号保留但仅作为向后兼容，实际目标选择逻辑迁移到拖拽释放流程
- 原有的 `card_hovered` / `card_unhovered` 信号保持不变，用于关键词提示

---

## 5. Hand.gd 改动

### 5.1 新增变量

```gdscript
@onready var drag_line: Line2D = $DragLine    # 轨迹线节点

var is_dragging: bool = false
var dragged_card: Card = null
var drag_start_position: Vector2 = Vector2.ZERO    # 卡牌拖拽开始时的原始位置
var drag_original_scale: Vector2 = Vector2.ONE
const DRAG_TWEEN_TIME: float = 0.1
const CANCEL_TWEEN_TIME: float = 0.2

var _target_borders: Dictionary[BaseCombatant, Panel] = {}   # 目标高亮边框缓存
```

### 5.2 信号连接

在 `draw_cards()` / `add_cards_to_hand()` 中保持现有连接，并确保：
```gdscript
card.card_drag_started.connect(_on_card_drag_started)
card.card_drag_ended.connect(_on_card_drag_ended)
card.card_drag_cancelled.connect(_on_card_drag_cancelled)
```

### 5.3 拖拽开始

```gdscript
func _on_card_drag_started(card: Card):
    if hand_disabled: return
    if performing_card_right_click: return
    if not card.can_play_card(): return

    is_dragging = true
    dragged_card = card
    drag_start_position = card.pivot.global_position
    drag_original_scale = card.pivot.scale

    # 提升层级，确保卡牌显示在最上层
    card.z_index = 100

    # 显示轨迹线
    drag_line.visible = true
    drag_line.clear_points()
    drag_line.add_point(drag_start_position)
    drag_line.add_point(drag_start_position)

    # 暂停手牌排列中该卡牌的 tween（在 tween_hand 中处理）
```

### 5.4 拖拽过程（_process）

```gdscript
func _process(_delta: float):
    if not is_dragging or dragged_card == null:
        return

    var mouse_pos = get_global_mouse_position()

    # 更新卡牌位置到鼠标位置（居中）
    dragged_card.pivot.global_position = mouse_pos - (dragged_card.size * dragged_card.pivot.scale * 0.5)

    # 更新轨迹线终点
    drag_line.set_point_position(1, mouse_pos)

    # 目标检测与高亮
    var hover_target = _get_drag_hover_target(mouse_pos)
    _update_drag_target_highlight(hover_target)

    # 动态放大：根据到目标的距离等比放缩
    var dist: float = drag_start_position.distance_to(mouse_pos)
    if hover_target != null:
        dist = dragged_card.pivot.global_position.distance_to(hover_target.global_position)
    var scale_factor: float = clampf(dist / 400.0, 0.0, 1.0)
    var new_scale: float = 1.0 + scale_factor * 0.4
    dragged_card.pivot.scale = Vector2(new_scale, new_scale)

    # 更新卡牌描述预览（复用现有逻辑）
    if hover_target is Enemy:
        dragged_card.update_card_display(hover_target)
```

### 5.5 目标检测

```gdscript
func _get_drag_hover_target(mouse_pos: Vector2) -> BaseCombatant:
    # 检查敌人
    for enemy in combat.enemies:
        if enemy.is_alive() and enemy.selection_button.get_global_rect().has_point(mouse_pos):
            return enemy
    # 检查玩家
    if player.selection_button.get_global_rect().has_point(mouse_pos):
        return player
    return null
```

### 5.6 目标高亮

```gdscript
func _update_drag_target_highlight(target: BaseCombatant):
    # 清除所有敌人的高亮
    for enemy in combat.enemies:
        enemy.set_highlight(false)      # 假设敌人有 set_highlight 方法，或修改材质
    player.set_highlight(false)

    if target != null:
        target.set_highlight(true)
```

**具体实现**: 现有代码中敌人/玩家没有高亮方法。采用动态添加 `Panel` + `StyleBoxFlat` 边框实现边沿描边：

```gdscript
var _target_borders: Dictionary[BaseCombatant, Panel] = {}

func _update_drag_target_highlight(target: BaseCombatant):
    # 清除所有旧边框
    for combatant in _target_borders.keys():
        if is_instance_valid(_target_borders[combatant]):
            _target_borders[combatant].queue_free()
    _target_borders.clear()

    if target != null:
        var border = Panel.new()
        border.name = "TargetBorder"
        border.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var style = StyleBoxFlat.new()
        style.border_color = Color.YELLOW
        style.border_width_left = 3
        style.border_width_top = 3
        style.border_width_right = 3
        style.border_width_bottom = 3
        style.bg_color = Color.TRANSPARENT
        border.add_theme_stylebox_override("panel", style)
        border.set_anchors_preset(Control.PRESET_FULL_RECT)
        target.add_child(border)
        _target_borders[target] = border
```

边框颜色使用 `Color.YELLOW`（黄色），宽度 `3px`，背景透明。拖拽结束后自动清理。

### 5.7 拖拽结束（左键松开）

```gdscript
func _on_card_drag_ended(card: Card):
    if not is_dragging or dragged_card != card:
        return

    var mouse_pos = get_global_mouse_position()
    var target = _get_drag_hover_target(mouse_pos)

    # 情况 A: 悬停敌人 -> 攻击该敌人
    if target is Enemy and card.card_data.card_requires_target:
        _execute_card_play(card, target)
    # 情况 B: 悬停玩家 -> 对自己释放
    elif target == player and card.card_data.card_requires_target:
        _execute_card_play(card, target)
    # 情况 D: 无需目标 -> 直接释放（拖到屏幕上方或无目标区域）
    elif not card.card_data.card_requires_target:
        _execute_card_play(card, null)
    # 情况 C: 无有效目标 -> 取消释放，弹回手牌
    else:
        _cancel_drag()
```

### 5.8 执行释放

```gdscript
func _execute_card_play(card: Card, target: BaseCombatant):
    # 复用现有逻辑
    _unprompt_target()
    var card_play_request = CardPlayRequest.new()
    card_play_request.card_data = card.card_data
    card_play_request.selected_target = target
    add_card_to_play_queue(card_play_request, true, false)

    # 清理拖拽状态
    _cleanup_drag_state()
```

### 5.9 取消拖拽（情况 C 和右键）

```gdscript
func _cancel_drag():
    if dragged_card == null:
        return

    # 弹回动画
    var tween = create_tween()
    tween.tween_property(dragged_card.pivot, "position", drag_start_position, CANCEL_TWEEN_TIME)
    tween.parallel().tween_property(dragged_card.pivot, "scale", drag_original_scale, CANCEL_TWEEN_TIME)

    await tween.finished
    _cleanup_drag_state()
    tween_hand()        # 重新排列手牌

func _on_card_drag_cancelled(card: Card):
    if is_dragging and dragged_card == card:
        _cancel_drag()
```

### 5.10 清理状态

```gdscript
func _cleanup_drag_state():
    if dragged_card != null:
        dragged_card.z_index = 0
        dragged_card.pivot.scale = Vector2.ONE
    is_dragging = false
    dragged_card = null
    drag_line.visible = false
    drag_line.clear_points()
    _unprompt_target()
    _update_drag_target_highlight(null)
```

### 5.11 tween_hand 改造

在现有 `tween_hand()` 中，跳过正在拖拽的卡牌：

```gdscript
func tween_hand():
    for card in get_children():
        if card == dragged_card:
            continue        # 拖拽中的卡牌不受手牌排列控制
        # ... 现有逻辑不变
```

---

## 6. 视觉参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 基础放大比例 | `1.0x` | 拖拽开始时无额外放大 |
| 最大放大比例 | `1.4x` | 靠近目标时的最大放大 |
| 放大计算方式 | 动态 | `scale = 1.0 + min(dist / 400, 1.0) * 0.4`，dist 为卡牌到目标的距离（像素） |
| 放大更新频率 | 每帧 | 在 `_process` 中根据实时距离重新计算 |
| 取消弹回时间 | `0.2s` | 与手牌排列动画一致 |
| 轨迹线颜色 | `Color(0.5, 0.5, 0.5, 0.7)` | 灰色半透明 |
| 轨迹线宽度 | `3.0` | 足够明显但不抢眼 |
| 卡牌拖拽层级 | `z_index = 100` | 确保卡牌显示在所有 UI 元素之上 |

---

## 7. 边界情况处理

| 场景 | 处理方式 |
|------|---------|
| 拖拽到屏幕外松开 | 视为取消，卡牌弹回手牌 |
| 手牌被禁用（如敌人回合）| `hand_disabled` 时忽略拖拽开始 |
| 能量不足 | `can_play_card()` 返回 false，忽略拖拽开始 |
| 拖拽中回合结束 | 强制取消拖拽，调用 `_cancel_drag()` |
| 快速点击不拖动 | 视为短距离拖拽。若卡牌 `requires_target=false` 则直接释放；若需要目标则弹回手牌。未来可扩展为进入"目标锁定"模式（点击敌人释放），但本版本优先保证拖拽体验一致性 |
| 多张卡牌同时拖拽 | 不可能发生，`_on_card_drag_started` 中会检查 `is_dragging` |

---

## 8. 兼容性说明

- 保留 `card_selected` 信号的定义，但 `Hand.gd` 不再响应该信号进行目标选择（或改为兼容模式：收到 `card_selected` 时视为立即释放无需目标的卡牌）
- 保留右键功能：`card_right_clicked` 继续触发卡牌右键效果（如转换模式）
- 保留 `AnimationPlayer` 的 hover/unhover 动画，但拖拽时这些动画应被暂停（由拖拽状态覆盖）

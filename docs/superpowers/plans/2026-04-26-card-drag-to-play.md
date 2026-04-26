# Card Drag-to-Play Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two-step "click card → click target" play flow with a single drag-and-drop flow: hold left click on a card, drag it to a target (or empty area for no-target cards), and release to play. Includes a gray trail line, dynamic 1.0x→1.4x scale, and yellow edge outline highlights on valid targets. Right-click during drag cancels.

**Architecture:** Hand.gd becomes the centralized drag state machine (`_process` tracks mouse, updates trail line/scale, detects targets). Card.gd only emits start/end/cancel signals and handles input. Target detection reuses existing `selection_button.get_global_rect()` on `BaseCombatant`. Edge highlights are dynamic `Panel` + `StyleBoxFlat` children added to the hovered combatant. The old `current_selected_card` / `_on_enemy_clicked` target-selection path is deprecated for normal play and kept only for the existing card-picking UI.

**Tech Stack:** Godot 4 (GDScript), Tween, Line2D, Panel/StyleBoxFlat.

---

## Task 1: Card.tscn + Card.gd — Add drag signals and input handling

**Files:**
- Modify: `scenes/ui/Card.tscn`
- Modify: `scripts/ui/Card.gd`

- [ ] **Step 1: Restrict CardButton to left-click only**

In `scenes/ui/Card.tscn`, change the invisible `CardButton` so its `button_down` / `button_up` signals only fire for left click. Right clicks will still reach `_on_button_gui_input` for cancellation/right-click actions.

```
[node name="CardButton" type="Button" parent="Pivot"]
...
button_mask = 1
```

- [ ] **Step 2: Add new drag signals to Card.gd**

Add the three new signals after the existing ones (around line 33):

```gdscript
signal card_drag_started(Card)
signal card_drag_ended(Card)
signal card_drag_cancelled(Card)
```

- [ ] **Step 3: Replace left-click handling in `_on_button_gui_input`**

Replace the existing `_on_button_gui_input` so it no longer emits `card_selected` on left click. It still emits `card_drag_cancelled` + `card_right_clicked` on right click.

```gdscript
func _on_button_gui_input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		card_drag_cancelled.emit(self)
		card_right_clicked.emit(self)
```

- [ ] **Step 4: Add `_on_button_down` and `_on_button_up` handlers**

Append these new methods to `Card.gd`:

```gdscript
func _on_button_down():
	card_drag_started.emit(self)
	card_selected.emit(self)  # backward compat for overlays

func _on_button_up():
	card_drag_ended.emit(self)
```

- [ ] **Step 5: Connect `button_down` / `button_up` in `init()`**

In `init()`, inside the `if connect_ui_signals:` block (after the existing `card_button.gui_input.connect`), add:

```gdscript
		card_button.button_down.connect(_on_button_down)
		card_button.button_up.connect(_on_button_up)
```

- [ ] **Step 6: Commit**

```bash
git add scenes/ui/Card.tscn scripts/ui/Card.gd
git commit -m "feat: add drag start/end/cancel signals to Card"
```

---

## Task 2: Hand.gd — Drag state variables, Line2D, and signal wiring

**Files:**
- Modify: `scripts/ui/Hand.gd`

- [ ] **Step 1: Add drag state variables**

Add these variables after the existing `@onready var combat` line (or near the other state variables, around line 35):

```gdscript
### Drag-to-Play
var drag_line: Line2D
var is_dragging: bool = false
var dragged_card: Card = null
var drag_start_pivot_position: Vector2 = Vector2.ZERO
var drag_original_scale: Vector2 = Vector2.ONE
const DRAG_TWEEN_TIME: float = 0.1
const CANCEL_TWEEN_TIME: float = 0.2

var _target_borders: Dictionary = {}   # BaseCombatant -> Panel
```

- [ ] **Step 2: Create the trail Line2D in `_ready()`**

Append to `_ready()`, after the existing signal connections:

```gdscript
	drag_line = Line2D.new()
	drag_line.name = "DragLine"
	drag_line.visible = false
	drag_line.width = 3.0
	drag_line.default_color = Color(0.5, 0.5, 0.5, 0.7)
	drag_line.z_index = 100
	drag_line.top_level = true
	add_child(drag_line)
```

- [ ] **Step 3: Connect drag signals for newly drawn/added cards**

In `draw_cards()` (around line 593), after the existing `card.card_right_clicked.connect`, add:

```gdscript
		card.card_drag_started.connect(_on_card_drag_started)
		card.card_drag_ended.connect(_on_card_drag_ended)
		card.card_drag_cancelled.connect(_on_card_drag_cancelled)
```

Do the same in `add_cards_to_hand()` (around line 664).

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/Hand.gd
git commit -m "feat: add drag state machine and Line2D trail to Hand"
```

---

## Task 3: Hand.gd — Drag start, process loop, target detection, and scale

**Files:**
- Modify: `scripts/ui/Hand.gd`

- [ ] **Step 1: Implement `_on_card_drag_started`**

Add this method. It blocks picking mode, disabled hand, right-click actions, unplayable cards, and already-queued cards.

```gdscript
func _on_card_drag_started(card: Card):
	if current_card_pick_action != null:
		return
	if hand_disabled:
		return
	if performing_card_right_click:
		return
	if not card.can_play_card():
		return
	# cannot drag cards already queued
	for card_play_request in card_play_queue:
		if card_play_request.card_data == card.card_data:
			return

	is_dragging = true
	dragged_card = card
	drag_start_pivot_position = card.pivot.position
	drag_original_scale = card.pivot.scale

	# reset hover offset so the card doesn't float above the mouse
	card.position = Vector2.ZERO

	# bring to front
	card.z_index = 100

	# show trail line
	drag_line.visible = true
	drag_line.clear_points()
	drag_line.add_point(card.pivot.global_position)
	drag_line.add_point(card.pivot.global_position)
```

- [ ] **Step 2: Implement `_process` drag loop**

Add `_process` to Hand.gd. It centers the card on the mouse, updates the trail, detects targets, applies dynamic scale, and updates card description preview.

```gdscript
func _process(_delta: float):
	if not is_dragging or dragged_card == null:
		return

	var mouse_pos = get_global_mouse_position()

	# center card on mouse (pivot origin is roughly visual center)
	dragged_card.pivot.global_position = mouse_pos

	# update trail line
	drag_line.set_point_position(1, mouse_pos)

	# target detection
	var hover_target = _get_drag_hover_target(mouse_pos)
	_update_drag_target_highlight(hover_target)

	# dynamic scale: closer to target / further from hand = bigger
	var dist: float = drag_start_pivot_position.distance_to(dragged_card.pivot.position)
	if hover_target != null:
		dist = dragged_card.pivot.global_position.distance_to(hover_target.global_position)
		# invert: closer to target = larger
		var scale_factor: float = 1.0 - clampf(dist / 400.0, 0.0, 1.0)
		dragged_card.pivot.scale = Vector2.ONE * (1.0 + scale_factor * 0.4)
	else:
		# further from hand = larger
		var scale_factor: float = clampf(dist / 400.0, 0.0, 1.0)
		dragged_card.pivot.scale = Vector2.ONE * (1.0 + scale_factor * 0.4)

	# update description preview when hovering an enemy
	if hover_target is Enemy:
		dragged_card.update_card_display(hover_target)
```

- [ ] **Step 3: Implement target detection**

```gdscript
func _get_drag_hover_target(mouse_pos: Vector2) -> BaseCombatant:
	# check enemies
	for enemy in combat.enemies:
		if enemy.is_alive() and enemy.selection_button.get_global_rect().has_point(mouse_pos):
			return enemy
	# check player
	if player.selection_button.get_global_rect().has_point(mouse_pos):
		return player
	return null
```

- [ ] **Step 4: Skip dragged card in `tween_hand`**

In `tween_hand()`, inside the `for card in get_player_hand_cards():` loop, add at the very top:

```gdscript
		if card == dragged_card:
			continue
```

- [ ] **Step 5: Skip dragged card in hover/unhover handlers**

Update `_on_card_hovered` so it does not move the dragged card:

```gdscript
func _on_card_hovered(card: Card):
	for child in get_children():
		if child == dragged_card:
			continue
		if card == child:
			child.position.y = CARD_HOVERED_HEIGHT
			child.z_index = 1
		else:
			child.position.y = CARD_UNHOVERED_HEIGHT
			child.z_index = 0
```

Update `_on_card_unhovered`:

```gdscript
func _on_card_unhovered(_card: Card):
	for child in get_children():
		if child == dragged_card:
			continue
		child.position.y = CARD_UNHOVERED_HEIGHT
		child.z_index = 0
```

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/Hand.gd
git commit -m "feat: drag process loop, target detection, and dynamic scaling"
```

---

## Task 4: Hand.gd — Target highlight border system

**Files:**
- Modify: `scripts/ui/Hand.gd`

- [ ] **Step 1: Implement `_update_drag_target_highlight`**

Add this method. It creates/removes a yellow `Panel` border on the hovered combatant.

```gdscript
func _update_drag_target_highlight(target: BaseCombatant):
	# clear old borders
	for combatant in _target_borders.keys():
		var panel = _target_borders[combatant]
		if is_instance_valid(panel):
			panel.queue_free()
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

- [ ] **Step 2: Commit**

```bash
git add scripts/ui/Hand.gd
git commit -m "feat: add yellow edge outline highlight on drag hover targets"
```

---

## Task 5: Hand.gd — Drag end, execute, cancel, cleanup, and deprecate old selection flow

**Files:**
- Modify: `scripts/ui/Hand.gd`

- [ ] **Step 1: Implement `_on_card_drag_ended`**

```gdscript
func _on_card_drag_ended(card: Card):
	if not is_dragging or dragged_card != card:
		return

	var mouse_pos = get_global_mouse_position()
	var target = _get_drag_hover_target(mouse_pos)

	# A: hover enemy + requires target -> attack
	if target is Enemy and card.card_data.card_requires_target:
		_execute_card_play(card, target)
	# B: hover player + requires target -> self-cast
	elif target == player and card.card_data.card_requires_target:
		_execute_card_play(card, target)
	# D: no target required -> play anywhere
	elif not card.card_data.card_requires_target:
		_execute_card_play(card, null)
	# C: invalid target -> cancel
	else:
		_cancel_drag()
```

- [ ] **Step 2: Implement `_execute_card_play`**

```gdscript
func _execute_card_play(card: Card, target: BaseCombatant):
	_unprompt_target()
	var card_play_request = CardPlayRequest.new()
	card_play_request.card_data = card.card_data
	card_play_request.selected_target = target
	card_play_request.card_values = card.card_data.card_values.duplicate(true)
	add_card_to_play_queue(card_play_request, true, false)
	_cleanup_drag_state()
```

- [ ] **Step 3: Implement `_cancel_drag` and `_on_card_drag_cancelled`**

```gdscript
func _cancel_drag():
	if dragged_card == null:
		return

	var tween = create_tween()
	tween.tween_property(dragged_card.pivot, "position", drag_start_pivot_position, CANCEL_TWEEN_TIME)
	tween.parallel().tween_property(dragged_card.pivot, "scale", drag_original_scale, CANCEL_TWEEN_TIME)

	await tween.finished
	_cleanup_drag_state()
	tween_hand()

func _on_card_drag_cancelled(card: Card):
	if is_dragging and dragged_card == card:
		_cancel_drag()
```

- [ ] **Step 4: Implement `_cleanup_drag_state`**

```gdscript
func _cleanup_drag_state():
	if dragged_card != null:
		dragged_card.z_index = 0
		dragged_card.pivot.scale = drag_original_scale
		dragged_card.position = Vector2.ZERO
	is_dragging = false
	dragged_card = null
	drag_line.visible = false
	drag_line.clear_points()
	_unprompt_target()
	_update_drag_target_highlight(null)
```

- [ ] **Step 5: Deprecate old playing logic from `_on_card_selected`**

Replace `_on_card_selected` so it only handles card picking. Remove all the old target-selection and no-target instant-play logic.

```gdscript
func _on_card_selected(card: Card):
	# Drag system handles normal card plays; this path is only for card picking UI
	if current_card_pick_action != null:
		attempt_pick_card(card)
```

- [ ] **Step 6: Guard `_on_card_right_clicked` during drag**

At the top of `_on_card_right_clicked`, add:

```gdscript
func _on_card_right_clicked(card: Card):
	if is_dragging and dragged_card == card:
		return
	current_selected_card = null
	...
```

- [ ] **Step 7: Cancel drag when hand is disabled / combat ends**

In `_on_disable_hand_requested`, add a drag cancel before clearing state:

```gdscript
func _on_disable_hand_requested(_disabled: bool = true):
	hand_disabled = _disabled
	if hand_disabled:
		if is_dragging:
			_cancel_drag()
		current_selected_card = null
		_unprompt_target()
```

In `_on_combat_ended`, add at the top:

```gdscript
func _on_combat_ended():
	if is_dragging:
		_cleanup_drag_state()
	...
```

In `_on_run_ended`, add at the top:

```gdscript
func _on_run_ended():
	if is_dragging:
		_cleanup_drag_state()
	...
```

- [ ] **Step 8: Commit**

```bash
git add scripts/ui/Hand.gd
git commit -m "feat: drag end/cancel/execute, deprecate old target selection flow"
```

---

## Task 6: Integration test in Godot editor

**Files:**
- No file changes; run the game.

- [ ] **Step 1: Run the combat scene and verify basic drag**

Run: launch the game from the editor, enter a combat encounter.

Test:
1. Draw a card that **requires a target** (e.g., an Attack).
2. Left-click and hold the card. It should appear on top (`z_index = 100`) and follow the mouse.
3. A gray line should trail from the card's original hand position to the mouse.
4. Drag the card over an enemy. The enemy should get a yellow border outline.
5. Release. The card should play, energy should be deducted, and the card should leave hand.

- [ ] **Step 2: Verify no-target cards**

Test a card that does **not** require a target (e.g., a Block or buff).
1. Drag it anywhere (even barely) and release.
2. It should play immediately without needing a target.

- [ ] **Step 3: Verify cancel behaviors**

Test three cancel paths:
1. Drag a target card into empty space and release → card tweens back to hand.
2. Drag a target card and press **right click** while holding → card tweens back to hand.
3. Drag a card and end the turn (or wait for hand disable) → card tweens back to hand.

- [ ] **Step 4: Verify visual feedback**

1. Trail line color is gray (`Color(0.5,0.5,0.5,0.7)`), width 3.
2. Card grows to ~1.4x when close to a valid target or far from hand, and stays ~1.0x when near hand start with no target.
3. Yellow border appears only on the hovered combatant.
4. After release (play or cancel), all highlights and trail lines disappear.

- [ ] **Step 5: Verify no regressions**

1. Hover over cards in hand — they still rise (`CARD_HOVERED_HEIGHT`) and other cards stay flat.
2. `tween_hand()` still arranges cards neatly after plays/cancels.
3. Card picking UI (e.g., "choose a card to discard" effects) still works by clicking cards normally.
4. Right-clicking a card for its right-click action still works when NOT dragging.
5. Background click no longer crashes or leaves stale "Select a target" text.

- [ ] **Step 6: Commit if all tests pass**

```bash
git commit --allow-empty -m "test: verify drag-to-play in combat"
```

---

## Spec Coverage Checklist

| Spec Requirement | Implementing Task |
|------------------|-------------------|
| Left-click hold → drag start | Task 1 (Card signals), Task 3 (Hand drag start) |
| Trail line from original position to mouse | Task 2 (Line2D), Task 3 (`_process`) |
| Dynamic scale 1.0x→1.4x based on distance | Task 3 (`_process` scale logic) |
| Release over enemy → play on enemy | Task 5 (`_on_card_drag_ended` case A) |
| Release over self → play on self | Task 5 (`_on_card_drag_ended` case B) |
| No-target card → play anywhere on release | Task 5 (`_on_card_drag_ended` case D) |
| Invalid target / empty release → cancel tween back | Task 5 (`_on_card_drag_ended` case C, `_cancel_drag`) |
| Right-click during drag → cancel | Task 1 (`card_drag_cancelled` signal), Task 5 (`_on_card_drag_cancelled`) |
| Target edge highlight (yellow border) | Task 4 (`_update_drag_target_highlight`) |
| Hand disabled / turn ends → force cancel | Task 5 (`_on_disable_hand_requested`) |
| Backward compat for card picking UI | Task 5 (`_on_card_selected` keeps picking logic) |
| `tween_hand` skips dragged card | Task 3 (`tween_hand` skip) |

## Placeholder Scan

- No TBD/TODO/fill-in-later items.
- All code blocks contain complete, runnable GDScript.
- All file paths are exact.
- All signal names, variable names, and method names are consistent across tasks.

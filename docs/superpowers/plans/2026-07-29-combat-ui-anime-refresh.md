# Combat UI Anime Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the in-combat HUD with a light World Flipper-inspired style while keeping enemy attack intent clear and background-free.

**Architecture:** Keep this scoped to combat UI scene composition and small reusable draw controls. Enemy intent renders as attack icon plus compact damage text only; card frames, enemy sprites, backgrounds, and gameplay data stay unchanged.

**Tech Stack:** Godot 4, GDScript, `.tscn` scene resources, existing headless regression scripts.

## Global Constraints

Use Chinese user-facing updates. Keep edits scoped to battle UI. Do not replace card frame assets or enemy art in this pass. Use tests before production changes.

---

### Task 1: Combat UI Style Regression

**Files:**
- Create: `tests/combat_ui_anime_style_regression.gd`

**Interfaces:**
- Consumes: `res://scenes/Root.tscn`, `res://scenes/combatants/Enemy.tscn`
- Produces: a headless regression that fails on bulky dark HUD badges, oversized combat buttons, and any enemy intent background panel

- [ ] **Step 1: Write the failing test**

```gdscript
extends SceneTree

const ROOT_SCENE_PATH := "res://scenes/Root.tscn"
const ENEMY_SCENE_PATH := "res://scenes/combatants/Enemy.tscn"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_enemy_intent_badge()
	await _check_combat_hud_badges()
	if failures.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/combat_ui_anime_style_regression.gd`
Expected: FAIL because old nodes still use bulky dark HUD badges or an enemy intent background panel.

### Task 2: Background-Free Enemy Intent

**Files:**
- Create: `scripts/ui/IntentAttackIcon.gd`
- Modify: `scripts/combatants/Enemy.gd`
- Modify: `scenes/combatants/Enemy.tscn`
- Test: `tests/combat_ui_anime_style_regression.gd`

**Interfaces:**
- Produces: `Enemy._format_attack_intent_text(damage: int, number_of_attacks: int) -> String`
- Produces: `IntentTexture` as a custom drawn icon control, with no intent background panel rendered

- [ ] **Step 1: Implement the minimal enemy intent styling**

```gdscript
func _format_attack_intent_text(damage: int, number_of_attacks: int) -> String:
	if number_of_attacks > 1:
		return "%sx%s" % [damage, number_of_attacks]
	return str(damage)
```

- [ ] **Step 2: Run the focused test**

Run: `godot --headless --path . --script tests/combat_ui_anime_style_regression.gd`
Expected: enemy intent renders as attack icon plus compact text only.

### Task 3: Light Combat HUD Badges

**Files:**
- Create: `scripts/ui/CombatHudBadge.gd`
- Modify: `scenes/Root.tscn`
- Modify: `scenes/ui/ConsumableButton.tscn`
- Modify: `scripts/ui/ConsumableButton.gd`
- Test: `tests/combat_ui_anime_style_regression.gd`

**Interfaces:**
- Produces: `CombatHudBadge.icon_id: String`
- Produces: `CombatHudBadge.surface_color: Color`
- Produces: `ConsumableButton/IconTexture` for consumable item art inside the new badge

- [ ] **Step 1: Add reusable badge drawing**

Create one draw control with small light-surface icon variants for pause, map, deck, energy, draw, discard, exhaust, and consumable.

- [ ] **Step 2: Replace old combat button textures**

Set the combat `TextureButton.texture_normal` values to empty and add `BadgeVisual` children using the new draw control.

- [ ] **Step 3: Run focused and smoke tests**

Run: `godot --headless --path . --script tests/combat_ui_anime_style_regression.gd`
Run: `godot --headless --path . --quit`
Expected: all pass.

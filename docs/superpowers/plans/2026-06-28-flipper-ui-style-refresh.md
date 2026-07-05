# Flipper UI Style Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the game's overall UI image/style toward the provided World Flipper-inspired references without changing layout or gameplay.

**Architecture:** Keep all scene node positions, sizes, and scripts intact. Apply the style through theme resources, existing ColorRect/TextureButton visuals, generated reusable UI textures, and component-level color updates. Do not replace card art, character art, combat logic, or data schemas.

**Tech Stack:** Godot 4 `.tres` themes, `.tscn` scene resources, deterministic Pillow PNG generation, Godot headless tests.

---

### Task 1: Create Reusable UI Assets

**Files:**
- Create: `tmp/ui_flipper_style/build_ui_assets.py`
- Create: `external/sprites/ui/flipper/*.png`

- [x] **Step 1: Generate soft cyan background and pixel-style icons**

Create a light cyan/blue gradient background, white rounded chip, orange primary chip, and pixel-style icon PNGs for pause/menu/map/deck/energy/shop/chest/piles.

- [x] **Step 2: Validate asset sizes**

Confirm each generated asset is PNG and dimensions match intended use.

### Task 2: Update Themes

**Files:**
- Modify: `themes/title_screen_theme.tres`
- Modify: `themes/run_screen_theme.tres`
- Modify: `themes/keyword_tooltip_theme.tres`

- [x] **Step 1: Update title/run button style**

Use white rounded normal buttons with teal outlines, orange hover/pressed state, dark readable text, and light shadow.

- [x] **Step 2: Update tooltip panel style**

Use a white rounded panel with teal border and dark text sizing unchanged.

### Task 3: Update Main Scene Visuals

**Files:**
- Modify: `scenes/Root.tscn`

- [x] **Step 1: Add UI texture resources**

Register generated UI textures as `ext_resource` entries for the root scene.

- [x] **Step 2: Recolor title/combat backgrounds and overlays**

Replace dark purple/grey ColorRect values with light cyan translucent surfaces, white panels, and teal-tinted overlays.

- [x] **Step 3: Assign pixel-style icon textures**

Assign generated icons to existing TextureButton nodes without moving or resizing them.

### Task 4: Update UI Components

**Files:**
- Modify: `scenes/ui/Card.tscn`
- Modify: `scenes/ui/general/DialogueOption.tscn`
- Modify: `scenes/ui/general/KeywordContainer.tscn`
- Modify: `scenes/ui/general/KeywordTooltip.tscn`
- Modify: `scenes/ui/general/Tooltip.tscn`

- [x] **Step 1: Refresh card visual colors**

Use a white card interior, soft cyan glow, orange energy badge, and dark text surfaces while preserving node structure.

- [x] **Step 2: Refresh tooltip/dialogue panel modulation**

Use white/teal modulation instead of grey panels.

### Task 5: Validate

**Files:**
- Review: changed theme, scene, and asset files.

- [x] **Step 1: Run Godot regression tests**

Run:

```bash
godot --headless --path . -s tests/custom_ui_artifact_regression.gd
godot --headless --path . -s tests/rest_pick_config_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

- [x] **Step 2: Confirm no layout anchors or offsets changed intentionally**

Review diffs for scene visual-only changes: colors, style resources, texture assignments, and resource declarations.

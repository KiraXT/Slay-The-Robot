# Art UI Shell Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the first visible game surfaces read as one bright anime-inspired UI system without requiring new illustration batches.

**Architecture:** Add a small reusable `ArtUIShell` helper for styleboxes and apply it from existing UI scripts at runtime. Keep scene edits scoped to stable layout nodes and add regression coverage that checks visible shell nodes, resource capsules, and card chrome structure.

**Tech Stack:** Godot 4, GDScript, existing `.tscn` scenes, existing theme resources, Godot headless regression scripts.

## Global Constraints

- Use Chinese project documentation for superpower docs.
- Do not change card logic, enemy logic, map generation, reward rules, or JSON data schemas.
- Preserve the existing Slay-the-Spire-style interaction contract: top resources, middle combat, bottom hand, target drag, and right-bottom end-turn action.
- Visual direction is bright anime character focus plus World Flipper-style modular cyan/white panels and orange primary actions.
- Avoid introducing mandatory new bitmap illustration assets in Phase 1.
- Prefer reusable runtime UI shell styling over hand-editing many unrelated scene nodes.

---

### Task 1: Visible Shell Contract Test

**Files:**
- Create: `tests/art_ui_shell_phase_1_regression.gd`

**Interfaces:**
- Consumes: `scenes/Root.tscn`, `scenes/ui/Card.tscn`
- Produces: Regression expectations for named nodes and style metadata used by later tasks.

- [ ] **Step 1: Write the failing test**

Create `tests/art_ui_shell_phase_1_regression.gd` with checks for:
- `TitleScreen/MainMenu` has `ShellPanel` and `HeroBadge`.
- `TitleScreen/NewRunMenu` has `CharacterInfoPanel`, `RunSetupPanel`, and `ModifierPanel`.
- `RunScreen/Combat` has `TopResourceBar`, `LeftPileDock`, `RightPileDock`, and `HandTray`.
- `scenes/ui/Card.tscn` has `FactionBadge`, `ArtFrame`, and `DescriptionPanel`.

- [ ] **Step 2: Run the test and verify RED**

Run: `godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
Expected: exit 1 with missing node failures.

- [ ] **Step 3: Commit**

Commit message: `test: add art ui shell phase 1 contract`

### Task 2: Shared Runtime Shell Styling

**Files:**
- Create: `scripts/ui/ArtUIShell.gd`
- Modify: `scenes/Root.tscn`
- Modify: `scripts/ui/menus/TitleScreen.gd`
- Modify: `scripts/ui/menus/NewRunMenu.gd`
- Modify: `scripts/ui/Combat.gd`

**Interfaces:**
- Consumes: node names asserted by Task 1.
- Produces: `ArtUIShell.apply_panel(control, role)`, `ArtUIShell.apply_button(button, role)`, `ArtUIShell.apply_label_capsule(label, role)`, and `ArtUIShell.apply_texture_button_shell(button, role)`.

- [ ] **Step 1: Implement minimal style helper and scene nodes**

Add `ArtUIShell.gd` with reusable cyan/white/orange styleboxes. Add shell `PanelContainer`/`ColorRect` nodes for the title panels, combat resource bar, pile docks, and hand tray. Call styling helpers in `_ready()` of affected scripts.

- [ ] **Step 2: Run Task 1 test and verify GREEN**

Run: `godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
Expected: `ALL_TESTS_PASSED`.

- [ ] **Step 3: Commit**

Commit message: `feat: add visible art ui shell`

### Task 3: Card Chrome First-Pass Skin

**Files:**
- Modify: `scenes/ui/Card.tscn`
- Modify: `scripts/ui/Card.gd`
- Modify: `tests/art_ui_shell_phase_1_regression.gd`

**Interfaces:**
- Consumes: `ArtUIShell`.
- Produces: card chrome nodes that make faction, art window, and description panel visually explicit.

- [ ] **Step 1: Expand the test**

Assert `FactionBadge` receives a non-transparent color from the card color, `ArtFrame` sits behind the art, and `DescriptionPanel` exists behind description text.

- [ ] **Step 2: Run the test and verify RED**

Run: `godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
Expected: exit 1 for missing styling behavior.

- [ ] **Step 3: Implement minimal card chrome**

Add the three card shell nodes, color the badge from `ColorData`, and keep existing card dimensions and text layout.

- [ ] **Step 4: Run the test and verify GREEN**

Run: `godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
Expected: `ALL_TESTS_PASSED`.

- [ ] **Step 5: Commit**

Commit message: `feat: skin card chrome phase 1`

### Task 4: Verification

**Files:**
- Test only.

**Interfaces:**
- Consumes: all Phase 1 changes.
- Produces: verification evidence for completion.

- [ ] **Step 1: Run focused UI shell test**

Run: `godot --headless --path . --script tests/art_ui_shell_phase_1_regression.gd`
Expected: `ALL_TESTS_PASSED`.

- [ ] **Step 2: Run existing safety tests**

Run:
- `godot --headless --path . --script tests/art_asset_contract_regression.gd`
- `godot --headless --path . --script tests/custom_ui_artifact_regression.gd`
- `godot --headless --path . --script tests/rest_pick_config_regression.gd`

Expected: each prints `ALL_TESTS_PASSED`.

- [ ] **Step 3: Inspect diff scope**

Run: `git diff --stat main..HEAD`
Expected: changes limited to Phase 1 docs, one shell helper, visible UI scenes/scripts, and tests.

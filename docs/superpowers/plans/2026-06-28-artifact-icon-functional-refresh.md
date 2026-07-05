# Artifact Icon Functional Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace original robot/placeholder artifact icons with function-specific icons that match the current light pixel UI style.

**Architecture:** Keep artifact logic and object IDs unchanged. Generate deterministic 128x128 RGBA pixel-style icons under `external/sprites/artifacts/`, overwrite the generic robot color placeholders with non-robot emblems, add independent icons for every artifact JSON, and update only `artifact_texture_path` values.

**Tech Stack:** Godot JSON resources, PNG/RGBA sprites, Pillow-generated pixel UI icons, Godot headless tests.

---

### Task 1: Generate Artifact Icons

**Files:**
- Create: `tmp/artifact_icon_refresh/build_artifact_icons.py`
- Modify/Create: `external/sprites/artifacts/*.png`

- [x] **Step 1: Generate generic non-robot color emblems**

Replace `artifact_red.png`, `artifact_blue.png`, `artifact_green.png`, `artifact_orange.png`, `artifact_white.png`, `artifact_purple.png`, and `artifact_yellow.png` with colored gem/medal icons.

- [x] **Step 2: Generate one functional icon per artifact object ID**

Create independent icons such as coin gain, attack-shield trigger, boss crown, shop bag, draw-on-kill, retain hand, full heal, and deck shuffle.

### Task 2: Update Artifact JSON References

**Files:**
- Modify: `external/data/artifacts/*.json`

- [x] **Step 1: Replace shared color placeholder paths**

Every artifact JSON should point to `external/sprites/artifacts/<object_id>.png`.

- [x] **Step 2: Confirm no gameplay fields changed**

Only `artifact_texture_path` changes in artifact JSON files.

### Task 3: Validate

**Files:**
- Review: `external/sprites/artifacts/*.png`
- Review: `external/data/artifacts/*.json`

- [x] **Step 1: Build contact sheet**

Create `tmp/artifact_icon_refresh/contact_sheet.png` to visually confirm no robot placeholder remains.

- [x] **Step 2: Validate image sizes and JSON wiring**

All referenced artifact icons must exist, be 128x128 RGBA PNG, and match their artifact object ID.

- [x] **Step 3: Run Godot regression tests**

Run:

```bash
godot --headless --path . -s tests/custom_ui_artifact_regression.gd
godot --headless --path . -s tests/rest_pick_config_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

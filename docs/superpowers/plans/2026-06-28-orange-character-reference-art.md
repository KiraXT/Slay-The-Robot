# Orange Character Reference Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace the existing orange placeholder character with the user-provided blonde sporty student visual direction, then create orange card art that matches the updated character.

**Architecture:** Keep all existing `orange` data IDs and file paths. Generate chroma-key source images, remove backgrounds locally, normalize PNG sizes, and update only orange card `card_texture_path` fields to independent card images.

**Tech Stack:** Godot JSON resources, PNG/RGBA sprites, built-in image generation, Pillow chroma-key removal, Godot headless SceneTree tests.

---

### Task 1: Confirm Orange Scope

**Files:**
- Review: `external/data/characters/character_orange.json`
- Review: `external/data/cards/*.json`

- [x] **Step 1: Confirm existing orange character paths**

Run:

```bash
rg -n "character_orange|character_texture_path|character_icon_texture_path|character_text_energy_texture_path|color_orange" external/data/characters/character_orange.json
```

Expected paths:

```text
external/sprites/characters/character_orange/character_orange.png
external/sprites/characters/character_orange/character_orange_icon.png
external/sprites/characters/character_orange/character_orange_text_energy.png
```

- [x] **Step 2: Confirm orange cards**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 - <<'PY'
import json
from pathlib import Path
for path in sorted(Path('external/data/cards').glob('*.json')):
    data = json.loads(path.read_text())
    props = data.get('properties', {})
    if props.get('card_color_id') == 'color_orange':
        print(f"{path}\t{props['object_id']}\t{props['card_name']}\t{props['card_texture_path']}")
PY
```

Expected object IDs:

```text
block_if_exhaust_card
card_attack_big
card_block_big
card_energy_on_draw
card_special_discard
retain_hand_card
```

### Task 2: Generate Character Assets

**Files:**
- Modify: `external/sprites/characters/character_orange/character_orange.png`
- Modify: `external/sprites/characters/character_orange/character_orange_icon.png`
- Modify: `external/sprites/characters/character_orange/character_orange_text_energy.png`
- Create: `tmp/imagegen/orange-reference/character_orange_chroma.png`
- Create: `tmp/imagegen/orange-reference/character_orange_icon_chroma.png`

- [x] **Step 1: Generate `character_orange_chroma.png`**

Use the user-provided reference image as the visual identity reference. Generate a full-body anime game character on a flat `#00ff00` chroma-key background:

```text
Blonde teenage sporty student girl with twin braids, warm orange/yellow eyes, oversized teal track jacket with white and purple color blocks, orange T-shirt without readable text, purple plaid mini skirt, white socks, orange sneakers, carrying a backpack. Light confident campus tone, full-body standing pose, polished 2D anime game art, centered with generous padding, no text, no watermark.
```

- [x] **Step 2: Remove chroma key and resize combat art**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /Users/xietong/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  --input tmp/imagegen/orange-reference/character_orange_chroma.png \
  --out external/sprites/characters/character_orange/character_orange.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force
sips -z 512 512 external/sprites/characters/character_orange/character_orange.png
```

- [x] **Step 3: Generate `character_orange_icon_chroma.png`**

Generate a head-and-shoulders portrait on flat `#00ff00`:

```text
Head-and-shoulders portrait of the same blonde twin-braid sporty student girl, teal jacket collar and orange shirt visible, warm friendly expression, clear face silhouette, no text, no watermark.
```

- [x] **Step 4: Remove chroma key and resize icon**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /Users/xietong/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  --input tmp/imagegen/orange-reference/character_orange_icon_chroma.png \
  --out external/sprites/characters/character_orange/character_orange_icon.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force
sips -z 64 64 external/sprites/characters/character_orange/character_orange_icon.png
```

- [x] **Step 5: Create 16x16 text energy icon**

Create a small orange/yellow energy token derived from the character palette at:

```text
external/sprites/characters/character_orange/character_orange_text_energy.png
```

The icon should be a readable 16x16 orange/yellow spark or bolt with transparent background.

### Task 3: Generate Orange Card Source Images

**Files:**
- Create: `tmp/imagegen/orange-reference/<card_object_id>_chroma.png`
- Modify: `external/sprites/cards/orange/card_orange.png`

- [x] **Step 1: Use common card prompt constraints**

For every card image, use:

```text
512x512 anime game card illustration source on perfectly flat solid #00ff00 chroma-key background. Subject is the same blonde twin-braid sporty orange character: oversized teal jacket, orange T-shirt without readable text, purple skirt, orange sneakers, backpack. Polished 2D anime game art, readable at small card size, centered with padding. No text, no watermark, no cast shadow, no reflection. Avoid boxing, heavy weapons, explosions, dark dramatic lighting.
```

- [x] **Step 2: Generate shared fallback `card_orange_chroma.png`**

Specific subject:

```text
The orange character dashes forward with her backpack swinging, orange/yellow energy arcs around her sneakers and jacket, upbeat sporty motion. Generic orange deck fallback art.
```

- [x] **Step 3: Generate `retain_hand_card_chroma.png`**

Specific subject:

```text
The orange character uses a hair clip, bookmark, or backpack strap clip to pin several cards safely in place, showing cards being retained until next turn.
```

- [x] **Step 4: Generate `card_special_discard_chroma.png`**

Specific subject:

```text
The orange character swings her backpack open and tosses unwanted cards outward; each discarded card releases a small orange signal burst, showing discard triggering special custom signals.
```

- [x] **Step 5: Generate `card_energy_on_draw_chroma.png`**

Specific subject:

```text
The orange character draws a card and orange/yellow energy sparks jump out with a sports drink bottle and sneaker-like motion flash, showing energy gained when drawn.
```

- [x] **Step 6: Generate `block_if_exhaust_card_chroma.png`**

Specific subject:

```text
The orange character pulls her oversized teal jacket around herself as a shield while one card dissolves into golden particles nearby, showing block enabled by an exhausted card.
```

- [x] **Step 7: Generate `card_block_big_chroma.png`**

Specific subject:

```text
The orange character presses a card onto the top of a deck while her oversized jacket forms a yellow protective bubble; another card fades into particles, showing top-deck, block, and exhaust.
```

- [x] **Step 8: Generate `card_attack_big_chroma.png`**

Specific subject:

```text
The orange character launches into a sporty dash kick or backpack-swing strike with yellow motion streaks, coins popping out nearby, showing strong attack that gains money on kill and vanishes.
```

### Task 4: Convert Card Sources To Final Images

**Files:**
- Modify: `external/sprites/cards/orange/card_orange.png`
- Create: `external/sprites/cards/orange/block_if_exhaust_card.png`
- Create: `external/sprites/cards/orange/card_attack_big.png`
- Create: `external/sprites/cards/orange/card_block_big.png`
- Create: `external/sprites/cards/orange/card_energy_on_draw.png`
- Create: `external/sprites/cards/orange/card_special_discard.png`
- Create: `external/sprites/cards/orange/retain_hand_card.png`

- [x] **Step 1: Remove chroma key and resize all card images**

For each ID in:

```text
card_orange
block_if_exhaust_card
card_attack_big
card_block_big
card_energy_on_draw
card_special_discard
retain_hand_card
```

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /Users/xietong/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  --input tmp/imagegen/orange-reference/<id>_chroma.png \
  --out external/sprites/cards/orange/<id>.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force
sips -z 512 512 external/sprites/cards/orange/<id>.png
```

### Task 5: Update Orange Card JSON References

**Files:**
- Modify: `external/data/cards/block_if_exhaust_card.json`
- Modify: `external/data/cards/card_attack_big.json`
- Modify: `external/data/cards/card_block_big.json`
- Modify: `external/data/cards/card_energy_on_draw.json`
- Modify: `external/data/cards/card_special_discard.json`
- Modify: `external/data/cards/retain_hand_card.json`

- [x] **Step 1: Replace orange card texture paths**

Use this mapping:

```text
block_if_exhaust_card -> external/sprites/cards/orange/block_if_exhaust_card.png
card_attack_big -> external/sprites/cards/orange/card_attack_big.png
card_block_big -> external/sprites/cards/orange/card_block_big.png
card_energy_on_draw -> external/sprites/cards/orange/card_energy_on_draw.png
card_special_discard -> external/sprites/cards/orange/card_special_discard.png
retain_hand_card -> external/sprites/cards/orange/retain_hand_card.png
```

- [x] **Step 2: Confirm no gameplay fields changed**

Only `card_texture_path` should change in the six JSON files.

### Task 6: Validate Resources And Tests

**Files:**
- Review: `external/sprites/characters/character_orange/*.png`
- Review: `external/sprites/cards/orange/*.png`
- Review: `external/data/cards/*.json`

- [x] **Step 1: Validate image sizes and alpha**

Check:

```text
character_orange.png: 512x512 alpha
character_orange_icon.png: 64x64 alpha
character_orange_text_energy.png: 16x16 alpha
card_orange.png: 512x512 alpha
each independent orange card PNG: 512x512 alpha
```

- [x] **Step 2: Validate orange JSON wiring**

Confirm every `color_orange` card points to `external/sprites/cards/orange/<object_id>.png`.

- [x] **Step 3: Run Godot SceneTree tests**

Run:

```bash
godot --headless --path . -s tests/custom_ui_artifact_regression.gd
godot --headless --path . -s tests/rest_pick_config_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

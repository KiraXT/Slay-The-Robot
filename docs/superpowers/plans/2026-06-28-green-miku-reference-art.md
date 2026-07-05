# Green Miku Reference Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing green placeholder character with a teal twin-tail virtual singer visual direction, then create green card art that matches the updated character.

**Architecture:** Keep all existing `green` data IDs and file paths. Generate magenta chroma-key source images to protect teal hair/effects, remove backgrounds locally, normalize PNG sizes, and update only green card `card_texture_path` fields to independent card images.

**Tech Stack:** Godot JSON resources, PNG/RGBA sprites, built-in image generation, Pillow chroma-key removal, Godot headless SceneTree tests.

---

### Task 1: Confirm Green Scope

**Files:**
- Review: `external/data/characters/character_green.json`
- Review: `external/data/cards/*.json`

- [x] **Step 1: Confirm existing green character paths**

Expected paths:

```text
external/sprites/characters/character_green/character_green.png
external/sprites/characters/character_green/character_green_icon.png
external/sprites/characters/character_green/character_green_text_energy.png
```

- [x] **Step 2: Confirm green cards**

Expected object IDs:

```text
card_attack_corrosion
card_attack_in_center
card_block_without_attacks
card_bomb
card_cycle_enemy_intent
card_draft_random_attack
card_draft_random_player_pool
card_duplicate_plays
card_generate_shoves
card_improving_block
card_preserve_block
card_upgrade_card
```

### Task 2: Generate Character Assets

**Files:**
- Modify: `external/sprites/characters/character_green/character_green.png`
- Modify: `external/sprites/characters/character_green/character_green_icon.png`
- Modify: `external/sprites/characters/character_green/character_green_text_energy.png`
- Create: `tmp/imagegen/green-miku/character_green_chroma.png`
- Create: `tmp/imagegen/green-miku/character_green_icon_chroma.png`

- [x] **Step 1: Generate `character_green_chroma.png`**

Use the user-provided reference image as identity/style reference. Generate full-body character on flat `#ff00ff` background:

```text
Teal twin-tail virtual singer girl, very long cyan-green twin tails, headset with microphone, grey-white sleeveless top with teal tie, black detached sleeves, black skirt with teal digital accents, black thigh-high boots, upbeat electronic music performer tone, no readable logos or text.
```

- [x] **Step 2: Remove chroma key and resize combat art**

Output:

```text
external/sprites/characters/character_green/character_green.png
512x512 RGBA PNG
```

- [x] **Step 3: Generate and process `character_green_icon.png`**

Use a head-and-shoulders portrait of the same teal twin-tail singer. Output:

```text
external/sprites/characters/character_green/character_green_icon.png
64x64 RGBA PNG
```

- [x] **Step 4: Create `character_green_text_energy.png`**

Create a 16x16 cyan/green music-energy note or spark with transparent background.

### Task 3: Generate Green Card Sources

**Files:**
- Create: `tmp/imagegen/green-miku/<card_object_id>_chroma.png`
- Modify: `external/sprites/cards/green/card_green.png`

- [x] **Step 1: Generate shared fallback `card_green_chroma.png`**

Subject: teal twin-tail singer performing with cyan/green sound waves and floating music notes.

- [x] **Step 2: Generate `card_attack_corrosion_chroma.png`**

Subject: green sound waves and corrosive digital notes wrap around shadowy enemy silhouettes.

- [x] **Step 3: Generate `card_attack_in_center_chroma.png`**

Subject: singer stands behind three floating cards, the center card glows strongly.

- [x] **Step 4: Generate `card_block_without_attacks_chroma.png`**

Subject: singer creates a calm cyan sound barrier with only shield/skill cards nearby and no attack cards.

- [x] **Step 5: Generate `card_bomb_chroma.png`**

Subject: metronome/countdown music notes form a green timed energy bomb.

- [x] **Step 6: Generate `card_cycle_enemy_intent_chroma.png`**

Subject: singer adjusts headset/mixing panel while enemy intent icons rotate.

- [x] **Step 7: Generate `card_draft_random_attack_chroma.png`**

Subject: singer chooses one of three holographic attack cards.

- [x] **Step 8: Generate `card_duplicate_plays_chroma.png`**

Subject: first played card echoes into a second translucent copy with stage reverb rings.

- [x] **Step 9: Generate `card_draft_random_player_pool_chroma.png`**

Subject: singer opens a fan of random holographic cards from the player pool.

- [x] **Step 10: Generate `card_generate_shoves_chroma.png`**

Subject: rhythmic sound waves push multiple shove cards into the hand.

- [x] **Step 11: Generate `card_improving_block_chroma.png`**

Subject: singer places a card on top of a deck while layered sound shields grow stronger.

- [x] **Step 12: Generate `card_preserve_block_chroma.png`**

Subject: locked cyan sound shield persists around the singer.

- [x] **Step 13: Generate `card_upgrade_card_chroma.png`**

Subject: singer upgrades a card using a digital mixer/audio tuning panel and green upward glow.

### Task 4: Convert Sources To Final Images

**Files:**
- Modify: `external/sprites/cards/green/card_green.png`
- Create: `external/sprites/cards/green/card_attack_corrosion.png`
- Create: `external/sprites/cards/green/card_attack_in_center.png`
- Create: `external/sprites/cards/green/card_block_without_attacks.png`
- Create: `external/sprites/cards/green/card_bomb.png`
- Create: `external/sprites/cards/green/card_cycle_enemy_intent.png`
- Create: `external/sprites/cards/green/card_draft_random_attack.png`
- Create: `external/sprites/cards/green/card_draft_random_player_pool.png`
- Create: `external/sprites/cards/green/card_duplicate_plays.png`
- Create: `external/sprites/cards/green/card_generate_shoves.png`
- Create: `external/sprites/cards/green/card_improving_block.png`
- Create: `external/sprites/cards/green/card_preserve_block.png`
- Create: `external/sprites/cards/green/card_upgrade_card.png`

- [x] **Step 1: Remove magenta backgrounds and resize**

For each generated card source, remove chroma key and normalize to:

```text
512x512 RGBA PNG
```

### Task 5: Update Green Card JSON References

**Files:**
- Modify the eleven `external/data/cards/*.json` files for green cards.
- Modify `external/data/cards/card_draft_random_player_pool.json` because it currently uses the shared green card texture.

- [x] **Step 1: Replace green card texture paths**

Every `color_green` card should point to:

```text
external/sprites/cards/green/<object_id>.png
```

- [x] **Step 2: Replace the remaining shared green texture reference**

`card_draft_random_player_pool` should point to:

```text
external/sprites/cards/green/card_draft_random_player_pool.png
```

- [x] **Step 3: Confirm no gameplay fields changed**

Only `card_texture_path` should change in card JSON files.

### Task 6: Validate Resources And Tests

**Files:**
- Review: `external/sprites/characters/character_green/*.png`
- Review: `external/sprites/cards/green/*.png`
- Review: `external/data/cards/*.json`

- [x] **Step 1: Validate image sizes and alpha**

Required:

```text
character_green.png: 512x512 alpha
character_green_icon.png: 64x64 alpha
character_green_text_energy.png: 16x16 alpha
card_green.png and every independent green card: 512x512 alpha
```

- [x] **Step 2: Validate green JSON wiring**

Confirm every `color_green` card points to `external/sprites/cards/green/<object_id>.png`.

- [x] **Step 3: Run Godot SceneTree tests**

Run:

```bash
godot --headless --path . -s tests/custom_ui_artifact_regression.gd
godot --headless --path . -s tests/rest_pick_config_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

# Green Action Card Art Redo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the green card images that read as static element collages with action-driven card art where the green character's pose and motion communicate each card's meaning.

**Architecture:** Keep existing JSON paths and character assets. Regenerate only `external/sprites/cards/green/*.png` card images using magenta chroma-key sources, remove backgrounds locally, and validate final PNG dimensions/alpha. Existing JSON references already point to independent green card image paths.

**Tech Stack:** Built-in image generation, Pillow/chroma-key background removal, Godot headless tests.

---

### Task 1: Generate Action-Driven Sources

**Files:**
- Create: `tmp/imagegen/green-action-redo/<card_id>_chroma.png`
- Review reference: `external/sprites/characters/character_green/character_green.png`

- [x] **Step 1: Generate `card_green_chroma.png`**

Scene: the teal twin-tail singer performs a dynamic opening stage move with cyan-green music energy.

- [x] **Step 2: Generate `card_attack_corrosion_chroma.png`**

Scene: the teal twin-tail singer lunges forward singing into a headset mic, one hand sweeping a corrosive cyan-green sound wave through a shadow enemy.

- [x] **Step 3: Generate `card_attack_in_center_chroma.png`**

Scene: the singer plants her feet and fires a focused sound beam straight into a central target, with side targets left dim.

- [x] **Step 4: Generate `card_block_without_attacks_chroma.png`**

Scene: the singer braces with both arms and raises a calm sound shield, defensive posture only, no attack stance.

- [x] **Step 5: Generate `card_bomb_chroma.png`**

Scene: the singer crouches or pivots while tossing a glowing timed music-note bomb away from herself.

- [x] **Step 6: Generate `card_cycle_enemy_intent_chroma.png`**

Scene: the singer twists a headset dial or small mixer with an active body turn while enemy intent icons flip around her.

- [x] **Step 7: Generate `card_draft_random_attack_chroma.png`**

Scene: the singer reaches upward and pulls one glowing attack card from three floating cards, ready to strike.

- [x] **Step 8: Generate `card_draft_random_player_pool_chroma.png`**

Scene: the singer dives into a swirl of mixed holographic cards and snatches a random card mid-motion.

- [x] **Step 9: Generate `card_duplicate_plays_chroma.png`**

Scene: the singer performs a fast two-step move, with a second afterimage echoing the same card play.

- [x] **Step 10: Generate `card_generate_shoves_chroma.png`**

Scene: the singer dances into a wide sweeping step, pushing cards/enemies outward with rhythmic sound pressure.

- [x] **Step 11: Generate `card_improving_block_chroma.png`**

Scene: the singer stacks one shield layer over another with both hands, visibly strengthening the guard.

- [x] **Step 12: Generate `card_preserve_block_chroma.png`**

Scene: the singer holds a protective pose around a locked shield, keeping the barrier steady.

- [x] **Step 13: Generate `card_upgrade_card_chroma.png`**

Scene: the singer leans over a glowing card and tunes it like audio equipment, upgrading it with an upward surge.

### Task 2: Convert Sources To Final Assets

**Files:**
- Modify: `external/sprites/cards/green/card_green.png`
- Modify: `external/sprites/cards/green/card_attack_corrosion.png`
- Modify: `external/sprites/cards/green/card_attack_in_center.png`
- Modify: `external/sprites/cards/green/card_block_without_attacks.png`
- Modify: `external/sprites/cards/green/card_bomb.png`
- Modify: `external/sprites/cards/green/card_cycle_enemy_intent.png`
- Modify: `external/sprites/cards/green/card_draft_random_attack.png`
- Modify: `external/sprites/cards/green/card_draft_random_player_pool.png`
- Modify: `external/sprites/cards/green/card_duplicate_plays.png`
- Modify: `external/sprites/cards/green/card_generate_shoves.png`
- Modify: `external/sprites/cards/green/card_improving_block.png`
- Modify: `external/sprites/cards/green/card_preserve_block.png`
- Modify: `external/sprites/cards/green/card_upgrade_card.png`

- [x] **Step 1: Remove magenta chroma key from every source**

Use the installed `remove_chroma_key.py` helper with `--auto-key border`, `--soft-matte`, and `--despill`.

- [x] **Step 2: Resize every final image**

Every final card image must be a 512x512 RGBA PNG.

### Task 3: Validate And Test

**Files:**
- Review: `external/sprites/cards/green/*.png`
- Review: `external/data/cards/*.json`

- [x] **Step 1: Build contact sheet**

Create `tmp/imagegen/green-action-redo/contact_sheet.png` and inspect it for action-driven compositions.

- [x] **Step 2: Validate resources**

Confirm all twelve action-redone card images are 512x512 with alpha and all relevant JSON paths still point to independent green images.

- [x] **Step 3: Run Godot regression tests**

Run:

```bash
godot --headless --path . -s tests/custom_ui_artifact_regression.gd
godot --headless --path . -s tests/rest_pick_config_regression.gd
```

Expected: both print `ALL_TESTS_PASSED`.

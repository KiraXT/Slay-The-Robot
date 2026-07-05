# Blue Individual Card Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace the blue deck's shared card image with thirteen effect-specific card images that preserve Yana's clumsy, everyday student tone.

**Architecture:** Create one transparent PNG per blue card at `external/sprites/cards/blue/<card_object_id>.png`, then update each blue card JSON `card_texture_path` to the matching image. Keep `external/sprites/cards/blue/card_blue.png` as the shared fallback asset, but stop pointing every blue card at it.

**Tech Stack:** Godot JSON resources, PNG/RGBA sprites, built-in image generation, local chroma-key removal with Pillow.

---

### Task 1: Confirm Blue Card Inventory

**Files:**
- Review: `docs/superpowers/specs/2026-06-27-blue-card-individual-art-design.md`
- Review: `external/data/cards/*.json`

- [x] **Step 1: List blue cards from JSON**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 - <<'PY'
import json
from pathlib import Path
for path in sorted(Path('external/data/cards').glob('*.json')):
    data = json.loads(path.read_text())
    props = data.get('properties', {})
    if props.get('card_color_id') == 'color_blue':
        print(f"{path}\t{props['object_id']}\t{props['card_name']}\t{props['card_texture_path']}")
PY
```

Expected: exactly thirteen blue cards, all currently using `external/sprites/cards/blue/card_blue.png`.

- [x] **Step 2: Keep non-blue cards out of scope**

Confirm no card with `card_color_id` other than `color_blue` is edited in this work.

### Task 2: Generate Thirteen Chroma-Key Source Images

**Files:**
- Create: `tmp/imagegen/blue-individual/<card_object_id>_chroma.png`
- Review: `external/sprites/characters/character_blue/character_blue.png`

- [x] **Step 1: Use the common prompt constraints for every card**

Use this common prompt block for every image generation request:

```text
Use case: stylized-concept
Asset type: 512x512 game card illustration source for a Godot deckbuilder; final subject will be cut out to transparent PNG.
Visual identity: Yana, a clumsy blue-haired JK student character with short blue hair, white school shirt, blue skirt, yellow ribbon, white socks, loafers, youthful everyday comedy tone.
Style/medium: polished 2D anime game art, cohesive cel-shaded illustration, clean linework, readable at small card size.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for background removal. The background must be one uniform color with no shadows, gradients, texture, floor plane, or lighting variation.
Composition/framing: one clear card-art vignette centered with generous padding, no hard crop, no complex background, readable silhouette.
Constraints: no text, no watermark, no logo, no cast shadow, no contact shadow, no reflection. Do not use #00ff00 anywhere in the subject.
Avoid: punching pose, heavy weapon, explosion, fire, cracked ground, red combat effects, dark dramatic lighting, generic icon-only art, standing portrait crop.
```

- [x] **Step 2: Generate `card_draw`**

Specific subject:

```text
Yana kneels beside an open school bag, hurriedly pulling out a fan of cards and homework papers, surprised and flustered. The image clearly reads as drawing cards/resources from a bag.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_draw_chroma.png
```

- [x] **Step 3: Generate `card_discard_hand`**

Specific subject:

```text
Yana drops a messy hand of cards by accident; cards scatter outward while she reaches forward to recover them, embarrassed and panicked. The image clearly reads as discarding the whole hand and scrambling to recover.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_discard_hand_chroma.png
```

- [x] **Step 4: Generate `card_reshuffle_draw`**

Specific subject:

```text
Yana stuffs a pile of scattered cards back into a school bag or deck box while cards swirl in a small loop around her. The image clearly reads as reshuffling a discard pile back into the draw pile.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_reshuffle_draw_chroma.png
```

- [x] **Step 5: Generate `card_pick_from_discard`**

Specific subject:

```text
Yana crouches on the ground searching through scattered cards and loose papers, holding up one chosen card with a relieved but awkward expression. The image clearly reads as selecting a card from the discard pile.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_pick_from_discard_chroma.png
```

- [x] **Step 6: Generate `add_to_draw_from_discard_card`**

Specific subject:

```text
Yana collects recovered cards from the floor and awkwardly places two cards on top of a neat draw deck, like reorganizing mixed-up class notes. The image clearly reads as returning discard cards to the draw pile.
```

Save source as:

```text
tmp/imagegen/blue-individual/add_to_draw_from_discard_card_chroma.png
```

- [x] **Step 7: Generate `card_play_from_discard`**

Specific subject:

```text
Yana snatches a card from a messy discard pile on the floor and plays it in the same motion while holding her school bag up like a clumsy shield. The image clearly reads as playing a card from discard and gaining a little block.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_play_from_discard_chroma.png
```

- [x] **Step 8: Generate `card_discard_attacks_from_draw`**

Specific subject:

```text
Yana anxiously pulls dangerous red attack cards out from the top of a blue deck and tosses them away, as if filtering out trouble. The image clearly reads as discarding attack cards from the draw pile.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_discard_attacks_from_draw_chroma.png
```

- [x] **Step 9: Generate `randomize_hand_card`**

Specific subject:

```text
Yana holds a messy hand of cards while energy tokens, coins, bento stickers, and changing number symbols spin around unpredictably. The image clearly reads as randomizing card costs.
```

Save source as:

```text
tmp/imagegen/blue-individual/randomize_hand_card_chroma.png
```

- [x] **Step 10: Generate `card_add_consumable`**

Specific subject:

```text
Yana opens a lunch bag and accidentally pulls out a bottled drink, small ointment tube, snack, and little consumable gadgets, looking surprised that useful items came out. The image clearly reads as generating a random consumable.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_add_consumable_chroma.png
```

- [x] **Step 11: Generate `card_attack_rng`**

Specific subject:

```text
Yana closes her eyes and wildly throws bread, a drink bottle, and stationery in different directions, with playful motion arcs and an uncertain hit. The image clearly reads as random damage.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_attack_rng_chroma.png
```

- [x] **Step 12: Generate `card_improving_attack`**

Specific subject:

```text
Yana starts in a clumsy defensive stance with her school bag as a shield, but a small blue glow and tiny shield marks show she is unexpectedly improving. The image clearly reads as block plus attack that grows after a kill.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_improving_attack_chroma.png
```

- [x] **Step 13: Generate `card_attack_heal_unblocked_damage`**

Specific subject:

```text
Yana spills a bottled drink or bento soup outward in a splash that hits shadowy enemy silhouettes, while soft blue recovery sparkles splash back toward her. The image clearly reads as attack damage converting into healing.
```

Save source as:

```text
tmp/imagegen/blue-individual/card_attack_heal_unblocked_damage_chroma.png
```

- [x] **Step 14: Generate `self_attaching_attack_card`**

Specific subject:

```text
Yana points in panic as a sticky note or card attaches itself to a shadowy enemy silhouette, with a little blue target mark. The image clearly reads as a card automatically attaching to a random enemy at combat start.
```

Save source as:

```text
tmp/imagegen/blue-individual/self_attaching_attack_card_chroma.png
```

### Task 3: Convert Sources To Final Transparent Card Images

**Files:**
- Create: `external/sprites/cards/blue/add_to_draw_from_discard_card.png`
- Create: `external/sprites/cards/blue/card_add_consumable.png`
- Create: `external/sprites/cards/blue/card_attack_heal_unblocked_damage.png`
- Create: `external/sprites/cards/blue/card_attack_rng.png`
- Create: `external/sprites/cards/blue/card_discard_attacks_from_draw.png`
- Create: `external/sprites/cards/blue/card_discard_hand.png`
- Create: `external/sprites/cards/blue/card_draw.png`
- Create: `external/sprites/cards/blue/card_improving_attack.png`
- Create: `external/sprites/cards/blue/card_pick_from_discard.png`
- Create: `external/sprites/cards/blue/card_play_from_discard.png`
- Create: `external/sprites/cards/blue/card_reshuffle_draw.png`
- Create: `external/sprites/cards/blue/randomize_hand_card.png`
- Create: `external/sprites/cards/blue/self_attaching_attack_card.png`

- [x] **Step 1: Remove chroma-key backgrounds**

For each `<card_object_id>`, run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /Users/xietong/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  --input tmp/imagegen/blue-individual/<card_object_id>_chroma.png \
  --out external/sprites/cards/blue/<card_object_id>.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill \
  --force
```

- [x] **Step 2: Resize final images to 512x512**

For each final file, run:

```bash
sips -z 512 512 external/sprites/cards/blue/<card_object_id>.png
```

- [x] **Step 3: Inspect final images**

Use image viewing on the final files and confirm:

```text
The image is not blank.
The character/world tone is blue-haired Yana, student objects, and clumsy comedy.
The card effect is distinguishable from the other blue card images.
No obvious green chroma fringe remains around hair, papers, cards, or props.
```

### Task 4: Update Blue Card JSON References

**Files:**
- Modify: `external/data/cards/add_to_draw_from_discard_card.json`
- Modify: `external/data/cards/card_add_consumable.json`
- Modify: `external/data/cards/card_attack_heal_unblocked_damage.json`
- Modify: `external/data/cards/card_attack_rng.json`
- Modify: `external/data/cards/card_discard_attacks_from_draw.json`
- Modify: `external/data/cards/card_discard_hand.json`
- Modify: `external/data/cards/card_draw.json`
- Modify: `external/data/cards/card_improving_attack.json`
- Modify: `external/data/cards/card_pick_from_discard.json`
- Modify: `external/data/cards/card_play_from_discard.json`
- Modify: `external/data/cards/card_reshuffle_draw.json`
- Modify: `external/data/cards/randomize_hand_card.json`
- Modify: `external/data/cards/self_attaching_attack_card.json`

- [x] **Step 1: Replace each `card_texture_path`**

Update every blue card JSON path using this mapping:

```text
add_to_draw_from_discard_card -> external/sprites/cards/blue/add_to_draw_from_discard_card.png
card_add_consumable -> external/sprites/cards/blue/card_add_consumable.png
card_attack_heal_unblocked_damage -> external/sprites/cards/blue/card_attack_heal_unblocked_damage.png
card_attack_rng -> external/sprites/cards/blue/card_attack_rng.png
card_discard_attacks_from_draw -> external/sprites/cards/blue/card_discard_attacks_from_draw.png
card_discard_hand -> external/sprites/cards/blue/card_discard_hand.png
card_draw -> external/sprites/cards/blue/card_draw.png
card_improving_attack -> external/sprites/cards/blue/card_improving_attack.png
card_pick_from_discard -> external/sprites/cards/blue/card_pick_from_discard.png
card_play_from_discard -> external/sprites/cards/blue/card_play_from_discard.png
card_reshuffle_draw -> external/sprites/cards/blue/card_reshuffle_draw.png
randomize_hand_card -> external/sprites/cards/blue/randomize_hand_card.png
self_attaching_attack_card -> external/sprites/cards/blue/self_attaching_attack_card.png
```

- [x] **Step 2: Do not modify gameplay fields**

Confirm only `card_texture_path` changes in the thirteen JSON files.

### Task 5: Validate Resource Wiring

**Files:**
- Review: `external/data/cards/*.json`
- Review: `external/sprites/cards/blue/*.png`

- [x] **Step 1: Validate JSON paths and image files**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 - <<'PY'
import json
from pathlib import Path
from PIL import Image

errors = []
for path in sorted(Path('external/data/cards').glob('*.json')):
    data = json.loads(path.read_text())
    props = data.get('properties', {})
    if props.get('card_color_id') != 'color_blue':
        continue
    object_id = props['object_id']
    expected = Path(f'external/sprites/cards/blue/{object_id}.png')
    actual = Path(props.get('card_texture_path', ''))
    if actual != expected:
        errors.append(f'{object_id}: expected {expected}, got {actual}')
        continue
    if not actual.exists():
        errors.append(f'{object_id}: missing image {actual}')
        continue
    image = Image.open(actual).convert('RGBA')
    if image.size != (512, 512):
        errors.append(f'{object_id}: expected 512x512, got {image.size}')
    alpha = image.getchannel('A')
    corners = [alpha.getpixel((0, 0)), alpha.getpixel((511, 0)), alpha.getpixel((0, 511)), alpha.getpixel((511, 511))]
    if corners != [0, 0, 0, 0]:
        errors.append(f'{object_id}: corners not transparent: {corners}')

if errors:
    print('\\n'.join(errors))
    raise SystemExit(1)
print('BLUE_CARD_ART_VALID')
PY
```

Expected: `BLUE_CARD_ART_VALID`.

- [x] **Step 2: Confirm changed files**

Run:

```bash
git diff --name-only -- external/data/cards external/sprites/cards/blue
```

Expected: the thirteen blue card JSON files, thirteen new blue card PNG files, and any pre-existing `card_blue.png` modification from earlier work. No non-blue card JSON should appear.

- [x] **Step 3: Run Godot tests if available**

Run:

```bash
command -v godot || command -v godot4
```

If a Godot executable is available, run the project's existing SceneTree tests using that executable. If no Godot executable is available, record that automated Godot tests could not be run in this environment.

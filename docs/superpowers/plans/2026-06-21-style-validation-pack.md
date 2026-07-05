# Style Validation Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce and wire a first-pass 19-asset visual validation pack that proves the chosen art direction works in the real game UI and that the current asset replacement pipeline is viable without first completing the full card-layer refactor.

**Architecture:** This phase deliberately separates asset production from structural UI refactors. New images are generated into stable runtime paths under `external/sprites/`, while source briefs, prompt templates, masters, and review notes live under `designer/art_source/`. For Excel-managed content (`cards`, `artifacts`, `events`), path changes flow through `external/config/*.xlsx` and the existing Python converters. For JSON-managed content (`characters`, `enemies`, `status_effects`, `consumables`), path changes are made directly in JSON.

**Tech Stack:** Godot 4, GDScript data-driven content, Excel workbooks in `external/config/`, Python converter scripts in `external/tools/`, Codex `image_gen`, macOS image inspection tools.

---

## Task 1: Create the validation-pack source structure and manifest

**Files:**
- Create: `designer/art_source/validation-pack/2026-06/README.md`
- Create: `designer/art_source/validation-pack/2026-06/asset-manifest.csv`
- Create: `designer/art_source/validation-pack/2026-06/prompt-template.md`
- Create: `designer/art_source/validation-pack/2026-06/review-notes.md`

- [ ] **Step 1: Create the validation-pack directories**

Run:

```bash
mkdir -p designer/art_source/validation-pack/2026-06
mkdir -p designer/art_source/validation-pack/2026-06/briefs
mkdir -p designer/art_source/validation-pack/2026-06/masters
mkdir -p designer/art_source/validation-pack/2026-06/contact-sheets
```

Expected: all four directories exist under `designer/art_source/validation-pack/2026-06`.

- [ ] **Step 2: Write the pack README**

Create `designer/art_source/validation-pack/2026-06/README.md` with:

```md
# 2026-06 Style Validation Pack

This pack is the first production test for the approved visual direction:

- UI shell: wasteland screen-print
- Content art: hand-drawn adventure cartoon

The pack exists to answer two questions:

1. Does the art direction read correctly inside the real game UI at gameplay sizes?
2. Can the existing asset pipeline replace representative content without first finishing the larger art-system refactor?

The pack includes 19 runtime assets:

- 2 character assets
- 2 enemy assets
- 6 card assets
- 1 event illustration
- 8 icon-scale assets

Source of truth:

- Briefs and prompt rules: this folder
- Runtime targets: `external/sprites/`
- Cards / artifacts / events path changes: maintain in Excel, then re-export JSON
- Characters / enemies / status effects / consumables path changes: maintain directly in JSON
```

- [ ] **Step 3: Write the exact asset manifest**

Create `designer/art_source/validation-pack/2026-06/asset-manifest.csv` with:

```csv
asset_id,asset_type,source_object_id,display_name,runtime_output_path,source_of_truth,format,target_px,notes
character_red_combat,character,character_red,红色角色战斗立绘,external/sprites/characters/character_red/character_red.png,json,png,512,3/4 view combat pose
character_red_icon,character_icon,character_red,红色角色头像,external/sprites/characters/character_red/character_red_icon.png,json,png,256,head and shoulders
enemy_1_combat,enemy,enemy_1,红色敌人,external/sprites/enemies/enemy_1.png,json,png,512,small normal enemy
enemy_act_1_boss_1_combat,enemy,enemy_act_1_boss_1,第一幕Boss,external/sprites/enemies/enemy_act_1_boss_1.png,json,png,512,large boss silhouette
card_attack_basic_art,card,card_attack_basic,基础攻击,external/sprites/cards/card_attack_basic.png,excel,png,512,basic attack read
card_block_basic_art,card,card_block_basic,基础格挡,external/sprites/cards/card_block_basic.png,excel,png,512,basic defense read
card_attack_big_art,card,card_attack_big,强力攻击,external/sprites/cards/card_attack_big.png,excel,png,512,big hit plus money reward read
card_weaken_enemies_art,card,card_weaken_enemies,施加虚弱,external/sprites/cards/card_weaken_enemies.png,excel,png,512,debuff read
card_grant_energy_art,card,card_grant_energy,能量牌,external/sprites/cards/card_grant_energy.png,excel,png,512,energy gain read
card_draft_random_attack_art,card,card_draft_random_attack,抽取攻击牌,external/sprites/cards/card_draft_random_attack.png,excel,png,512,draft or discover read
event_pick_something_illustration,event,event_pick_something,测试事件,external/sprites/events/event_pick_something.png,excel,png,768,single focal event illustration
artifact_block_on_attacks_icon,artifact,artifact_block_on_attacks,攻击格挡,external/sprites/artifacts/artifact_block_on_attacks.png,excel,png,128,reward icon
artifact_add_money_icon,artifact,artifact_add_money,获得金币,external/sprites/artifacts/artifact_add_money.png,excel,png,128,reward icon
artifact_right_click_shuffle_deck_icon,artifact,artifact_right_click_shuffle_deck,洗牌重置,external/sprites/artifacts/artifact_right_click_shuffle_deck.png,excel,png,128,utility icon
status_effect_weaken_icon,status_effect,status_effect_weaken,虚弱,external/sprites/status_effects/status_effect_weaken.png,json,png,128,debuff icon
status_effect_vulnerable_icon,status_effect,status_effect_vulnerable,易伤,external/sprites/status_effects/status_effect_vulnerable.png,json,png,128,debuff icon
consumable_heal_icon,consumable,consumable_heal,治疗药剂,external/sprites/consumables/consumable_heal.png,json,png,128,potion icon
consumable_damaging_icon,consumable,consumable_damaging,伤害药剂,external/sprites/consumables/consumable_damaging.png,json,png,128,potion icon
character_red_energy_icon,ui_content_icon,character_red,红色能量图标,external/sprites/characters/character_red/character_red_text_energy.png,json,png,128,inline energy symbol
```

- [ ] **Step 4: Write the shared prompt template**

Create `designer/art_source/validation-pack/2026-06/prompt-template.md` with:

```md
# Prompt Template

## Style Block

hand-drawn adventure cartoon illustration, post-apocalyptic robot world, bold uneven ink outlines, screen-print inspired limited palette, readable silhouette, expressive action, subtle paper grain, controlled detail density

## Constraint Block

no text, no letters, no numbers, no watermark, no card frame, no UI elements, single focal point, safe margins, clean readable silhouette

## Per-asset fill-in fields

- subject
- action
- camera
- palette accent
- mood
- gameplay read
- background handling

## Export rules

- Runtime outputs go to the `runtime_output_path` listed in `asset-manifest.csv`
- Transparent subjects export as PNG
- Event illustration may stay PNG for this pack to preserve crisp linework
- Do not bake text, counters, rarity, or button chrome into any generated image
```

- [ ] **Step 5: Create the review log**

Create `designer/art_source/validation-pack/2026-06/review-notes.md` with:

```md
# Review Notes

Use one section per review pass:

## Pass 1

- Character:
- Enemies:
- Cards:
- Event:
- Icons:

## Pass 2

- Character:
- Enemies:
- Cards:
- Event:
- Icons:
```

- [ ] **Step 6: Commit**

```bash
git add designer/art_source/validation-pack/2026-06
git commit -m "docs: add style validation pack manifest"
```

## Task 2: Write the 19 asset briefs

**Files:**
- Create: `designer/art_source/validation-pack/2026-06/briefs/character-red.md`
- Create: `designer/art_source/validation-pack/2026-06/briefs/enemies.md`
- Create: `designer/art_source/validation-pack/2026-06/briefs/cards.md`
- Create: `designer/art_source/validation-pack/2026-06/briefs/event-and-icons.md`

- [ ] **Step 1: Write the character brief**

Create `designer/art_source/validation-pack/2026-06/briefs/character-red.md` with:

```md
# Character Red

## character_red_combat

- subject: stocky red robot adventurer with simple friendly mask face, broad shoulders, worn metal shell, visible repair seams
- action: braced forward in a ready-to-fight stance, one arm raised as if about to strike
- camera: 3/4 view, full body
- palette accent: saturated red with off-white face details and dark ink edges
- mood: determined, slightly scrappy
- gameplay read: starter melee fighter
- background handling: transparent background, no ground shadow baked in

## character_red_icon

- subject: same red robot hero
- action: calm but ready expression
- camera: head-and-shoulders portrait
- palette accent: same red accent as combat art
- mood: readable and iconic
- gameplay read: hero portrait recognizable at 64px
- background handling: transparent background

## character_red_energy_icon

- subject: simplified red robot energy emblem derived from the hero silhouette
- action: none
- camera: centered icon
- palette accent: red fill with white facial cutouts
- mood: clean and utility-focused
- gameplay read: inline energy token readable in card text
- background handling: transparent background
```

- [ ] **Step 2: Write the enemy brief**

Create `designer/art_source/validation-pack/2026-06/briefs/enemies.md` with:

```md
# Enemies

## enemy_1_combat

- subject: small hostile red robot with sharper silhouette than the player, scavenger posture, chipped armor
- action: leaning in aggressively as if about to jab
- camera: 3/4 view, full body
- palette accent: red with darker industrial grime
- mood: annoying frontline attacker
- gameplay read: basic early enemy
- background handling: transparent background

## enemy_act_1_boss_1_combat

- subject: large red boss robot with heavy torso, asymmetrical armor, summon-device details, commanding silhouette
- action: looming forward with one arm open as if deploying minions
- camera: 3/4 view, full body
- palette accent: deep red, dark steel, small warning-color accents
- mood: dangerous and dominant
- gameplay read: chapter boss that summons support units
- background handling: transparent background
```

- [ ] **Step 3: Write the card brief**

Create `designer/art_source/validation-pack/2026-06/briefs/cards.md` with:

```md
# Cards

All card images in this phase are stand-alone square illustrations for the current `card_texture_path` field. They must read as isolated art icons inside the existing card UI.

## card_attack_basic_art

- subject: direct strike by a simple robot weapon or fist
- action: fast forward hit with a clear impact burst
- camera: medium close-up
- palette accent: white-neutral base with combat red accent
- mood: straightforward and immediate
- gameplay read: basic attack

## card_block_basic_art

- subject: improvised metal plate or shield wall
- action: incoming impact stopped cleanly
- camera: medium close-up
- palette accent: white-neutral base with cool steel accent
- mood: sturdy and reliable
- gameplay read: basic block

## card_attack_big_art

- subject: heavy finishing blow with coins or loot burst implied
- action: oversized strike with strong motion arc
- camera: medium close-up
- palette accent: orange accent with reward-gold secondary accent
- mood: explosive, greedy, high impact
- gameplay read: expensive strong attack with kill reward

## card_weaken_enemies_art

- subject: hostile robot being hit by a draining or glitching debuff pulse
- action: visible destabilization, stagger, or static distortion
- camera: medium close-up
- palette accent: red base with sickly debuff accent
- mood: tactical pressure
- gameplay read: weaken or debuff

## card_grant_energy_art

- subject: battery core, energy canister, or power transfer
- action: charge surging outward in two clear pulses
- camera: centered icon-like composition
- palette accent: red base with bright energy highlight
- mood: efficient and empowering
- gameplay read: gain energy

## card_draft_random_attack_art

- subject: three attack schematics or weapon choices fanning outward
- action: one highlighted choice emerging from a spread
- camera: centered icon-like composition
- palette accent: green base with bright selection accent
- mood: clever and opportunistic
- gameplay read: draft or discover an attack
```

- [ ] **Step 4: Write the event and icon brief**

Create `designer/art_source/validation-pack/2026-06/briefs/event-and-icons.md` with:

```md
# Event And Icons

## event_pick_something_illustration

- subject: a tempting cache or strange machine offering a risky trade
- action: object glowing invitingly while feeling slightly unsafe
- camera: medium shot with single focal prop
- palette accent: toxic green highlight in a dark wasteland setting
- mood: tempting but suspicious
- gameplay read: choose between painful trade-offs
- background handling: full square illustration, keep important detail away from extreme edges

## artifact_block_on_attacks_icon

- subject: attack tally turning into a shield
- gameplay read: repeated attacks generate block

## artifact_add_money_icon

- subject: scrap coins or metal currency stack
- gameplay read: gain money

## artifact_right_click_shuffle_deck_icon

- subject: circular arrow around a deck stack
- gameplay read: reshuffle utility

## status_effect_weaken_icon

- subject: slumped robot head with fading signal
- gameplay read: weakened attack output

## status_effect_vulnerable_icon

- subject: cracked armor plate with exposed core
- gameplay read: takes more damage

## consumable_heal_icon

- subject: repair vial or coolant injector
- gameplay read: healing potion

## consumable_damaging_icon

- subject: volatile explosive flask
- gameplay read: damage potion
```

- [ ] **Step 5: Commit**

```bash
git add designer/art_source/validation-pack/2026-06/briefs
git commit -m "docs: add validation pack art briefs"
```

## Task 3: Generate first-pass assets and process them into runtime files

**Files:**
- Create: `external/sprites/enemies/enemy_1.png`
- Create: `external/sprites/enemies/enemy_act_1_boss_1.png`
- Create: `external/sprites/cards/card_attack_basic.png`
- Create: `external/sprites/cards/card_block_basic.png`
- Create: `external/sprites/cards/card_attack_big.png`
- Create: `external/sprites/cards/card_weaken_enemies.png`
- Create: `external/sprites/cards/card_grant_energy.png`
- Create: `external/sprites/cards/card_draft_random_attack.png`
- Create: `external/sprites/artifacts/artifact_block_on_attacks.png`
- Create: `external/sprites/artifacts/artifact_add_money.png`
- Create: `external/sprites/artifacts/artifact_right_click_shuffle_deck.png`
- Create: `external/sprites/status_effects/status_effect_weaken.png`
- Create: `external/sprites/status_effects/status_effect_vulnerable.png`
- Create: `external/sprites/consumables/consumable_heal.png`
- Create: `external/sprites/consumables/consumable_damaging.png`
- Modify: `external/sprites/characters/character_red/character_red.png`
- Modify: `external/sprites/characters/character_red/character_red_icon.png`
- Modify: `external/sprites/characters/character_red/character_red_text_energy.png`
- Modify: `external/sprites/events/event_pick_something.png`

- [ ] **Step 1: Create the new runtime directories**

Run:

```bash
mkdir -p external/sprites/status_effects
mkdir -p external/sprites/consumables
```

Expected: both runtime directories exist.

- [ ] **Step 2: Generate four candidates per asset using the shared prompt template**

For each row in `designer/art_source/validation-pack/2026-06/asset-manifest.csv`, use Codex `image_gen` with:

```text
[Style Block]
[Per-asset brief]
[Constraint Block]
transparent background if runtime format is png and the asset is not an event illustration
```

Save the four candidate masters under:

```text
designer/art_source/validation-pack/2026-06/masters/<asset_id>/candidate-1.png
designer/art_source/validation-pack/2026-06/masters/<asset_id>/candidate-2.png
designer/art_source/validation-pack/2026-06/masters/<asset_id>/candidate-3.png
designer/art_source/validation-pack/2026-06/masters/<asset_id>/candidate-4.png
```

Expected: every manifest row has exactly four candidates.

- [ ] **Step 3: Select one candidate per asset and export runtime-size files**

Selection rule:

```md
- Prioritize silhouette and gameplay readability over large-image detail
- Reject images with fake text, extra limbs, broken perspective, muddy focal point, or edge-crowding
- Keep card art centered enough to survive the current card crop
```

Export the approved runtime files to the exact `runtime_output_path` values from `asset-manifest.csv`.

Use these size caps:

```text
512px: character, enemy, card
256px: character icon
128px: icons
768px: event
```

Expected: all 19 approved runtime files exist at their final paths.

- [ ] **Step 4: Produce contact sheets for gameplay-size review**

For each category, create one contact sheet PNG:

```text
designer/art_source/validation-pack/2026-06/contact-sheets/characters.png
designer/art_source/validation-pack/2026-06/contact-sheets/enemies.png
designer/art_source/validation-pack/2026-06/contact-sheets/cards.png
designer/art_source/validation-pack/2026-06/contact-sheets/event-and-icons.png
```

Each contact sheet must show both:

```md
- the master/approved image
- a reduced-size preview approximating in-game readability
```

- [ ] **Step 5: Log first-pass review findings**

Add the first review decisions to `designer/art_source/validation-pack/2026-06/review-notes.md`, including:

```md
- approved as-is
- needs prompt retry
- needs cleanup or crop adjustment
- fails gameplay readability
```

- [ ] **Step 6: Commit**

```bash
git add designer/art_source/validation-pack/2026-06 external/sprites
git commit -m "feat: add first-pass style validation art pack"
```

## Task 4: Wire the pilot assets into live content paths

**Files:**
- Modify: `external/data/enemies/enemy_1.json`
- Modify: `external/data/enemies/enemy_act_1_boss_1.json`
- Modify: `external/data/status_effects/status_effect_weaken.json`
- Modify: `external/data/status_effects/status_effect_vulnerable.json`
- Modify: `external/data/consumables/consumable_heal.json`
- Modify: `external/data/consumables/consumable_damaging.json`
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/artifacts.xlsx`
- Modify: `external/config/events.xlsx`
- Regenerate: `external/data/cards/*.json`
- Regenerate: `external/data/artifacts/*.json`
- Regenerate: `external/data/events/*.json`

- [ ] **Step 1: Point JSON-managed content to dedicated pilot files**

Update these fields:

```json
// external/data/enemies/enemy_1.json
"enemy_texture_path": "external/sprites/enemies/enemy_1.png"

// external/data/enemies/enemy_act_1_boss_1.json
"enemy_texture_path": "external/sprites/enemies/enemy_act_1_boss_1.png"

// external/data/status_effects/status_effect_weaken.json
"status_effect_texture_path": "external/sprites/status_effects/status_effect_weaken.png"

// external/data/status_effects/status_effect_vulnerable.json
"status_effect_texture_path": "external/sprites/status_effects/status_effect_vulnerable.png"

// external/data/consumables/consumable_heal.json
"consumable_texture_path": "external/sprites/consumables/consumable_heal.png"

// external/data/consumables/consumable_damaging.json
"consumable_texture_path": "external/sprites/consumables/consumable_damaging.png"
```

Do not change `character_red.json` paths in this task because its three target files already match the approved runtime paths.

- [ ] **Step 2: Update the Excel-managed pilot rows**

Change the following workbook fields:

```text
cards.xlsx
- card_attack_basic.card_texture_path = external/sprites/cards/card_attack_basic.png
- card_block_basic.card_texture_path = external/sprites/cards/card_block_basic.png
- card_attack_big.card_texture_path = external/sprites/cards/card_attack_big.png
- card_weaken_enemies.card_texture_path = external/sprites/cards/card_weaken_enemies.png
- card_grant_energy.card_texture_path = external/sprites/cards/card_grant_energy.png
- card_draft_random_attack.card_texture_path = external/sprites/cards/card_draft_random_attack.png

artifacts.xlsx
- artifact_block_on_attacks.artifact_texture_path = external/sprites/artifacts/artifact_block_on_attacks.png
- artifact_add_money.artifact_texture_path = external/sprites/artifacts/artifact_add_money.png
- artifact_right_click_shuffle_deck.artifact_texture_path = external/sprites/artifacts/artifact_right_click_shuffle_deck.png

events.xlsx
- event_pick_something.dialogue_state_dialogue_texture_path = external/sprites/events/event_pick_something.png
```

Preserve all other columns unchanged.

- [ ] **Step 3: Regenerate cards, artifacts, and events from Excel**

Run:

```bash
python3 external/tools/convert.py --cards --artifacts --events
```

Expected: converter exits successfully and rewrites the corresponding JSON files without validation errors.

- [ ] **Step 4: Smoke-check the generated JSON**

Run:

```bash
rg -n 'external/sprites/cards/card_attack_basic.png|external/sprites/cards/card_block_basic.png|external/sprites/cards/card_attack_big.png|external/sprites/cards/card_weaken_enemies.png|external/sprites/cards/card_grant_energy.png|external/sprites/cards/card_draft_random_attack.png|external/sprites/artifacts/artifact_block_on_attacks.png|external/sprites/artifacts/artifact_add_money.png|external/sprites/artifacts/artifact_right_click_shuffle_deck.png|external/sprites/events/event_pick_something.png' external/data/cards external/data/artifacts external/data/events
```

Expected: the regenerated JSON contains the new dedicated sprite paths for all ten pilot rows.

- [ ] **Step 5: Commit**

```bash
git add external/data/enemies/enemy_1.json external/data/enemies/enemy_act_1_boss_1.json external/data/status_effects/status_effect_weaken.json external/data/status_effects/status_effect_vulnerable.json external/data/consumables/consumable_heal.json external/data/consumables/consumable_damaging.json external/config/cards.xlsx external/config/artifacts.xlsx external/config/events.xlsx external/data/cards external/data/artifacts external/data/events
git commit -m "feat: wire style validation pack into pilot content"
```

## Task 5: Verify the pack inside the real UI and document decisions

**Files:**
- Modify: `designer/art_source/validation-pack/2026-06/review-notes.md`
- Create: `designer/art_source/validation-pack/2026-06/final-acceptance.md`

- [ ] **Step 1: Run the game and check the required screens**

Open the project in Godot and verify these screens manually:

```md
- New Run: character portrait and character description block
- Combat: red hero, enemy_1, boss silhouette, six chosen cards in hand, energy icon
- Event: `event_pick_something` illustration and option readability
- Any screen showing artifacts, status effects, or consumables tied to the selected pilot icons
```

Record screenshots for each of the above.

- [ ] **Step 2: Evaluate against the acceptance checklist**

Use this checklist and append the results to `designer/art_source/validation-pack/2026-06/review-notes.md`:

```md
- readable at gameplay size
- silhouette distinct from nearby assets
- palette matches approved style
- no fake glyphs or broken anatomy
- card crop survives current card UI
- event art does not crowd prompt text
- icon reads at 32px and 64px
```

- [ ] **Step 3: Write the go / no-go summary**

Create `designer/art_source/validation-pack/2026-06/final-acceptance.md` with:

```md
# Final Acceptance

## Result

## Approved Assets

## Assets Requiring Another Pass

## Pipeline Findings
```

Then fill it with the actual go/no-go decision, the exact approved asset IDs, the exact rejected asset IDs, and concrete notes about pipeline friction discovered during this pack.

- [ ] **Step 4: Commit**

```bash
git add designer/art_source/validation-pack/2026-06
git commit -m "docs: record style validation pack review"
```

## Task 6: Prepare the handoff into phase 1 engineering

**Files:**
- Create: `designer/art_source/validation-pack/2026-06/phase-1-inputs.md`

- [ ] **Step 1: Summarize the engineering implications**

Create `designer/art_source/validation-pack/2026-06/phase-1-inputs.md` with:

```md
# Phase 1 Inputs

## Confirmed

## Blockers

## Required Next Changes
```

Then replace each section with concrete findings from this validation pack; do not leave generic bullets behind.

- [ ] **Step 2: Commit**

```bash
git add designer/art_source/validation-pack/2026-06/phase-1-inputs.md
git commit -m "docs: capture phase 1 inputs from style validation"
```

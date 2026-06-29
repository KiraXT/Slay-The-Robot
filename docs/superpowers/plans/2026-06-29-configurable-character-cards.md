# Configurable Character Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first set of new character cards that can be represented with existing card JSON actions and keep the Excel card ledger updated.

**Architecture:** This pass is data-first. New cards are added as JSON resources under `external/data/cards/`, with no new gameplay scripts. A lightweight Python regression check validates required card ids, ownership, and key trigger/action fields. `external/config/cards.xlsx` and `external/config/cards.csv` are updated as card ledger artifacts; complex action arrays are documented there as JSON text where the current converter cannot express them through simple columns.

**Tech Stack:** Godot 4 data resources, JSON card definitions, Excel workbook via openpyxl, Python validation script.

---

## Files

- Create: `tests/card_configurable_cards_regression.py`
  - Validates that the selected new cards exist and use only existing action scripts.
  - Validates key trigger fields such as `card_draw_actions`, `card_discard_actions`, and `card_retain_actions`.
- Create: `external/data/cards/card_hasty_sorting.json`
- Create: `external/data/cards/card_something_fell_out.json`
- Create: `external/data/cards/card_quick_search.json`
- Create: `external/data/cards/card_by_accident.json`
- Create: `external/data/cards/card_backup_drink.json`
- Create: `external/data/cards/card_first_beat.json`
- Create: `external/data/cards/card_distorted_note.json`
- Create: `external/data/cards/card_tuning.json`
- Create: `external/data/cards/card_warmup.json`
- Create: `external/data/cards/card_sports_drink.json`
- Create: `external/data/cards/card_bag_swing.json`
- Create: `external/data/cards/card_old_item_reuse.json`
- Create: `external/data/cards/card_sprint_start.json`
- Create: `external/data/cards/card_opening_strike.json`
- Create: `external/data/cards/card_finisher.json`
- Modify: `external/config/cards.xlsx`
  - Append ledger rows for all new cards.
  - Add optional ledger columns for complex JSON fields if absent: `card_values_json`, `card_play_actions_json`, `card_draw_actions_json`, `card_discard_actions_json`, `card_retain_actions_json`, `card_listeners_json`.
- Modify: `external/config/cards.csv`
  - Export the updated workbook sheet to UTF-8 CSV.

## Cards In Scope

These are implementable with current actions, validators, combat stats, and card trigger fields:

- Blue: `card_hasty_sorting`, `card_something_fell_out`, `card_quick_search`, `card_by_accident`, `card_backup_drink`
- Green: `card_first_beat`, `card_distorted_note`, `card_tuning`
- Orange: `card_warmup`, `card_sports_drink`, `card_bag_swing`, `card_old_item_reuse`, `card_sprint_start`
- Red: `card_opening_strike`, `card_finisher`

## Cards Out of Scope

These need new gameplay logic and should not be implemented in this pass:

- Red `追击`: exact previous-card-type validation.
- Red `连段起手`: exact next-attack modifier.
- Green `回声护盾`: exact previous-card-type validation.
- Green `副歌`: robust first attack/skill duplication as an automatic effect.
- Green `节拍器`: power that automatically modifies each turn's first card.
- Green `终场爆音`: damage based on target status charges.
- Orange `夹好书签`: applying a future discount to an arbitrary retained card with precise next-turn expiration.
- Orange `背包整理`: attaching a draw trigger to another selected card.
- Orange `轻装上阵`: power that triggers on the first exhaust each turn.
- Orange `准备姿态`: retaining all attacks and improving them only next turn.
- Orange `最后一件`: if exact "cards exhausted this combat" scaling is needed on a specific damage action, do it in a later tuning pass after validating `ActionVariableCombatStatsModifier` UX.

### Task 1: Write Regression Check

**Files:**
- Create: `tests/card_configurable_cards_regression.py`

- [ ] **Step 1: Add the failing test script**

Create a Python script that:

```python
#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "external" / "data" / "cards"

EXPECTED = {
    "card_hasty_sorting": "color_blue",
    "card_something_fell_out": "color_blue",
    "card_quick_search": "color_blue",
    "card_by_accident": "color_blue",
    "card_backup_drink": "color_blue",
    "card_first_beat": "color_green",
    "card_distorted_note": "color_green",
    "card_tuning": "color_green",
    "card_warmup": "color_orange",
    "card_sports_drink": "color_orange",
    "card_bag_swing": "color_orange",
    "card_old_item_reuse": "color_orange",
    "card_sprint_start": "color_orange",
    "card_opening_strike": "color_red",
    "card_finisher": "color_red",
}

REQUIRED_ACTIONS = {
    "card_something_fell_out": ["card_discard_actions"],
    "card_sports_drink": ["card_draw_actions"],
    "card_warmup": ["card_retain_actions"],
    "card_sprint_start": ["card_draw_actions"],
}

ALLOWED_SCRIPT_PREFIXES = (
    "res://scripts/actions/",
    "res://scripts/validators/",
    "res://scripts/card_listeners/",
)

def load_card(card_id: str) -> dict:
    path = CARDS / f"{card_id}.json"
    assert path.exists(), f"missing card JSON: {path}"
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)["properties"]

def walk_scripts(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.startswith("res://"):
                yield key
            yield from walk_scripts(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_scripts(child)

def main() -> None:
    for card_id, color_id in EXPECTED.items():
        card = load_card(card_id)
        assert card["object_id"] == card_id
        assert card["card_color_id"] == color_id
        assert card["card_appears_in_card_packs"] is True
        assert card["card_rarity"] in (1, 2, 3)
        assert card["card_type"] in (0, 1, 2)
        assert card["card_texture_path"], f"{card_id} should have a texture path"
        for script_path in walk_scripts(card):
            assert script_path.startswith(ALLOWED_SCRIPT_PREFIXES), script_path

    for card_id, fields in REQUIRED_ACTIONS.items():
        card = load_card(card_id)
        for field in fields:
            assert field in card, f"{card_id} missing {field}"
            assert len(card[field]) > 0, f"{card_id} has empty {field}"

    print(f"validated {len(EXPECTED)} configurable cards")

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the regression check and verify it fails**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
```

Expected: FAIL on the first missing new card JSON.

### Task 2: Add New Card JSON

**Files:**
- Create all card JSON files listed in Files.

- [ ] **Step 1: Add JSON card definitions**

Use existing action scripts only. Use shared color card art paths:

- Blue: `external/sprites/cards/blue/card_blue.png`
- Green: `external/sprites/cards/green/card_green.png`
- Orange: `external/sprites/cards/orange/card_orange.png`
- Red: `external/sprites/cards/red/card_red.png`

Key implementation details:

- `card_hasty_sorting`: `ActionPickCards` from hand, then `ActionDiscardCards`, then `ActionVariableCardsetModifier` wrapping `ActionDrawGenerator`.
- `card_something_fell_out`: unplayable skill with `card_discard_actions` granting energy.
- `card_quick_search`: `ActionPickCards` from discard, then add to hand and set selected card cost to 0 until turn.
- `card_by_accident`: random `ActionPickCards` from discard, then `ActionPlayCards`.
- `card_backup_drink`: `ActionAddConsumable`, then `ActionValidator` on `CARDS_DISCARDED > 0` to draw 1.
- `card_first_beat`: `ActionValidator` on `CARDS_PLAYED == 0` to choose a stronger action branch.
- `card_distorted_note`: attack, apply corrosion, then conditionally cycle enemy intent if selected target is attacking.
- `card_tuning`: pick one hand card and improve its combat copy values.
- `card_warmup`: block, innate retain, `card_retain_actions` improve its block.
- `card_sports_drink`: `card_draw_actions` add energy, play action draws, and card exhausts.
- `card_bag_swing`: base attack plus conditional bonus attack when `CARDS_EXHAUSTED > 0`.
- `card_old_item_reuse`: pick one hand card, exhaust it, gain block, draw 1.
- `card_sprint_start`: `card_draw_actions` set its own cost to 0 until turn, attack.
- `card_opening_strike`: attack, then apply vulnerable if target is attacking.
- `card_finisher`: `ActionVariableCombatStatsModifier` using `CARDS_PLAYED` to scale attack damage.

- [ ] **Step 2: Run the regression check and verify it passes**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
```

Expected: `validated 15 configurable cards`.

### Task 3: Update Excel and CSV Ledger

**Files:**
- Modify: `external/config/cards.xlsx`
- Modify: `external/config/cards.csv`

- [ ] **Step 1: Append ledger rows**

Use openpyxl to append rows for each new card using existing workbook columns. If missing, append these optional columns:

```text
card_play_actions_json
card_values_json
card_draw_actions_json
card_discard_actions_json
card_retain_actions_json
card_listeners_json
```

For cards whose complex action payloads cannot be represented through the simple `action_type` columns, store the final JSON field content in the corresponding `*_json` ledger column.

- [ ] **Step 2: Export CSV**

Write the `Cards` worksheet to `external/config/cards.csv` as UTF-8 CSV.

- [ ] **Step 3: Validate ledger rows**

Run a Python check that each new card id appears exactly once in both `cards.xlsx` and `cards.csv`.

### Task 4: Full Verification

**Files:**
- Test existing Godot project loading and data integrity.

- [ ] **Step 1: Run Python regression check**

Run:

```bash
/Users/xietong/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/card_configurable_cards_regression.py
```

Expected: pass.

- [ ] **Step 2: Run Godot tests**

Run:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: existing test suite passes. If the project does not have GUT available, run:

```bash
godot --headless --path . --quit
```

Expected: project loads without parse/data errors.

- [ ] **Step 3: Review git diff**

Run:

```bash
git diff -- external/data/cards tests external/config/cards.xlsx external/config/cards.csv docs/superpowers/plans/2026-06-29-configurable-character-cards.md
```

Expected: only intended card JSON, regression test, workbook/CSV ledger, and this plan changed.

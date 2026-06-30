# Card Reference Gap A Design

**Goal:** Implement the first low-risk batch from `2026-06-30-card-development-reference.md` and configure the cards it unlocks.

**Chosen approach:** Minimal general-purpose capabilities first. This pass adds only the script support needed for:

- previous-card validation,
- target status charge based value scaling,
- Excel-to-JSON preservation of complex card fields.

It then configures three cards:

- Red `card_pursuit` / `追击`
- Green `card_echo_shield` / `回声护盾`
- Green `card_finale_burst` / `终场爆音`

## Scope

### In Scope

- Add a validator that checks the previous card played this turn.
- Add an action or meta action that reads a target status effect charge and applies the result to child actions.
- Extend the Excel-to-JSON card converter so JSON text columns can preserve complex fields.
- Add JSON card definitions for the three newly unlocked cards.
- Update the card ledger in `external/config/cards.xlsx` and `external/config/cards.csv`.
- Add regression coverage for new scripts, new cards, and complex-field conversion.

### Out of Scope

- Next-card or next-attack temporary modifiers.
- Per-turn-first automatic powers.
- Runtime attachment of triggers to arbitrary selected card instances.
- Exact next-turn-only expiration rules.
- Final number balance and new card art.

## Architecture

### Previous Card Validator

Create `scripts/validators/card_plays/ValidatorPreviousCard.gd`.

The validator reads the current combat card-play history and checks the card immediately before the current card. It must avoid counting the card currently being resolved as its own previous card.

Supported config:

- `card_type`: optional integer card type match.
- `card_object_id`: optional string card id match.
- `card_tag`: optional tag match.
- `must_exist`: default `true`. If true, the first card of the turn fails.
- `invert`: default `false`.

The initial card configs only require `card_type`, but the validator should support id and tag now because the reference calls those out and they are cheap within the same boundary.

### Target Status Charge Scaling

Create `scripts/actions/meta_actions/ActionTargetStatusValueModifier.gd`, a reusable action that:

1. Reads a configured status effect from each action target.
2. Selects a charge field from that status effect.
3. Multiplies it by a configured multiplier.
4. Writes or adds the result into child action values.
5. Executes the child action for the same target.

Supported config:

- `status_effect_object_id`: required.
- `charge_key`: default `status_effect_charge`.
- `multiplier`: default `1`.
- `value_key`: child action value to write, usually `damage`.
- `operation`: `set` or `add`, default `add`.
- `default_value`: value used when the target has no matching status, default `0`.
- `action_data`: child action array.

For multi-target use, each target must read its own status state. This prevents one enemy's corrosion or bomb value from leaking into another enemy's damage calculation.

### Excel Complex Field Support

Extend `external/tools/excel_to_json.py` if present; if the repo only has card extraction/import helper scripts, add the converter in that expected path.

Supported JSON text columns:

- `card_values_json`
- `card_play_actions_json`
- `card_draw_actions_json`
- `card_discard_actions_json`
- `card_retain_actions_json`
- `card_listeners_json`

When a cell is non-empty:

- parse it as JSON,
- fail clearly if parsing fails,
- write it to the corresponding card property,
- preserve the nested structure exactly.

This pass does not replace existing simple-column conversion. JSON text columns override or fill only their matching complex fields.

## Card Configurations

### Red `card_pursuit`

Behavior: Deal damage. If the previous card played this turn was an attack, draw 1 card.

Implementation:

- Base attack via existing attack generator.
- Conditional draw via `ActionValidator` and `ValidatorPreviousCard` with `card_type = attack`.

Acceptance:

- First card of the turn does not draw.
- Playing any attack before `card_pursuit` draws 1.
- Playing a skill before `card_pursuit` does not draw.

### Green `card_echo_shield`

Behavior: Gain block. If the previous card played this turn was also a skill, gain extra block.

Implementation:

- Base block via existing block action.
- Conditional block via `ActionValidator` and `ValidatorPreviousCard` with `card_type = skill`.

Acceptance:

- First card of the turn gets only base block.
- Skill into `card_echo_shield` grants extra block.
- Attack into `card_echo_shield` does not grant extra block.

### Green `card_finale_burst`

Behavior: Deal damage based on the target's corrosion charges.

Implementation:

- Use `ActionTargetStatusValueModifier.gd` wrapping an attack or direct damage action.
- Configure `status_effect_object_id = status_effect_corrosion`, `charge_key = status_effect_charge`, and `value_key = damage`.

Acceptance:

- Target with no matching status takes only the configured default contribution.
- Target with matching status takes extra damage proportional to its own charges.
- Multiple enemies resolve independently from their own status values.

## Error Handling

- Missing previous card returns false when `must_exist` is true.
- Unknown card type, id, or tag simply fails validation rather than crashing.
- Missing status effect uses `default_value`.
- Invalid Excel JSON text fails conversion with the card id, column name, and parser error.
- Missing child action data in the status scaling action logs an error and performs no child action.

## Testing

Add focused regression checks:

- New card JSON files exist, load, and reference existing scripts.
- New validator and scaling action script paths exist.
- `card_pursuit`, `card_echo_shield`, and `card_finale_burst` contain the expected complex action fields.
- Excel-to-JSON preserves complex JSON fields for at least one representative card.
- Existing configurable card regression still passes.
- Godot headless project load succeeds.

If practical in the current test harness, add GDScript tests for:

- previous-card validator true and false cases,
- target status scaling with no status and with matching status.

## Implementation Order

1. Add failing regression coverage for the three cards and two new scripts.
2. Implement the previous-card validator.
3. Implement target status charge scaling.
4. Extend Excel complex-field conversion.
5. Add the three card JSON files.
6. Update `cards.xlsx` and `cards.csv`.
7. Run Python regression checks and Godot headless load.

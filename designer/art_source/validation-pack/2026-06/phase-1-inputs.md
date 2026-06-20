# Phase 1 Inputs

## Confirmed

- The approved B-direction works inside the existing dark UI shell without requiring a full interface redesign first.
- Hand-drawn/cartoon content art is readable in combat, card, event, and icon contexts at the current gameplay sizes.
- The runtime path layout under `external/sprites/` is sufficient for an incremental art-replacement program.
- A mixed maintenance model is already proven: Excel-managed path updates for cards/artifacts/events and direct JSON edits for enemies/status effects/consumables.

## Blockers

- Workbook editing and JSON regeneration are still fragile if they are not treated as one atomic step.
- Card visuals still inherit the limits of the current monolithic card image approach; crop pressure and frame/text coupling remain structural constraints.
- There is no dedicated manifest-driven export tool yet for selecting approved generated candidates and pushing them into runtime targets automatically.

## Required Next Changes

- Build the next production batch around a manifest-first workflow so each approved asset ID, runtime path, prompt source, and review status stays synchronized.
- Add a lightweight art-pipeline helper that can validate workbook path changes and rerun the JSON converters in one pass.
- Plan the card-system refactor so illustration, frame, and text can evolve independently before large-scale card art replacement begins.
- Expand the approved style set horizontally next: more enemies, more event illustrations, more artifact/status icons, then a broader card sample after the card presentation constraints are addressed.

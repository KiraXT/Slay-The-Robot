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

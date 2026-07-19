# Task 1 Report

## Status

DONE_WITH_CONCERNS

## Implementation

Created `tests/art_asset_contract_regression.gd` with the exact asset paths, fallback dimensions, required documentation phrases, character combat image checks, chroma-green checks, and contact-sheet tool check specified by the Task 1 brief.

The only compatibility adjustment was adding an explicit `int` type to `allowed_green_pixels`, because Godot 4.6 treats the brief's `max(4, ...)` inference as a warning and the project treats warnings as errors. This does not change the threshold or behavior.

## Verification

Command:

```text
godot --headless --path . -s tests/art_asset_contract_regression.gd
```

The valid run exited with code `1` after executing the test and reported missing fallback images, missing required guide phrases, and the missing contact-sheet tool. The run also emitted failures from the existing project autoload/import state. An initial run before the type adjustment stopped at a test-script parse error; after the adjustment the test script parsed and ran.

Subsequent reruns were blocked by the restricted environment's inability to create Godot `user://logs` files and then crashed during Godot logger initialization. This is an environment concern, not a test assertion failure.

## Commit

`d512e7b test: add art asset contract regression`

Only `tests/art_asset_contract_regression.gd` was committed. Existing worktree changes in `.superpowers/sdd/progress.md` and `.superpowers/sdd/task-1-brief.md` were left untouched.

## Controller Review Fix

Updated the phase plan's global constraint, Task 1, Task 2 acceptance wording, and Task 4 cleanup tool contract to detect chroma-green RGB residue regardless of alpha. Fully transparent pixels with pure green RGB are now treated as residue and are cleaned by the planned tool. Updated `tests/art_asset_contract_regression.gd` and synchronized `.superpowers/sdd/task-1-brief.md`; no brief-generation script was present in the repository, so synchronization was performed directly from the amended plan.

## Fix Verification

Exact command:

```text
godot --headless --path . -s tests/art_asset_contract_regression.gd
```

Exit code: `1`.

Relevant output included:

```text
external/sprites/characters/character_red/character_red.png has 115127 chroma green RGB residue pixels, including transparent pixels; limit is 0
external/sprites/characters/character_blue/character_blue.png has 99071 chroma green RGB residue pixels, including transparent pixels; limit is 0
external/sprites/characters/character_green/character_green.png has 153579 chroma green RGB residue pixels, including transparent pixels; limit is 0
external/sprites/characters/character_orange/character_orange.png has 108534 chroma green RGB residue pixels, including transparent pixels; limit is 0
Missing image: external/sprites/fallback/fallback_card.png
Missing image: external/sprites/fallback/fallback_character.png
Missing image: external/sprites/fallback/fallback_enemy.png
Missing image: external/sprites/fallback/fallback_icon.png
Missing image: external/sprites/fallback/fallback_background.png
```

The run also emitted pre-existing autoload/import parse and missing-resource errors before the focused test completed its own assertions.

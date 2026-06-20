# Review Notes

Use one section per review pass:

## Pass 1

- Character: approved as-is. Selected `character_red_combat` candidate 2, `character_red_icon` candidate 2, `character_red_energy_icon` candidate 1. Hero face read and cleaner silhouette are holding at preview size.
- Enemies: approved as-is. Selected `enemy_1_combat` candidate 2 and `enemy_act_1_boss_1_combat` candidate 1. Enemy shapes read darker and more jagged than the player on first pass.
- Cards: approved as-is. Selected `card_attack_basic_art` candidate 2, `card_block_basic_art` candidate 4, `card_attack_big_art` candidate 2, `card_weaken_enemies_art` candidate 2, `card_grant_energy_art` candidate 2, `card_draft_random_attack_art` candidate 1. No prompt retry needed before in-game testing; `card_attack_big_art` and `card_draft_random_attack_art` should still be watched for crop pressure in the real card window.
- Event: approved as-is. Selected `event_pick_something_illustration` candidate 2 because the single glowing machine reads more clearly than the other first-pass options.
- Icons: approved as-is. Selected `artifact_block_on_attacks_icon` candidate 1, `artifact_add_money_icon` candidate 1, `artifact_right_click_shuffle_deck_icon` candidate 1, `status_effect_weaken_icon` candidate 1, `status_effect_vulnerable_icon` candidate 2, `consumable_heal_icon` candidate 3, `consumable_damaging_icon` candidate 4. `consumable_damaging_icon` required a direct follow-up generation batch after the earlier run stopped; no further cleanup is needed before UI validation.

## Pass 2

- Character: verified in New Run and combat UI. `character_red_combat`, `character_red_icon`, and `character_red_energy_icon` remain readable at gameplay size, and the approved red-player silhouette now fits the existing UI shell without needing layout changes.
- Enemies: verified in combat. `enemy_1_combat` and `enemy_act_1_boss_1_combat` now separate cleanly from the player by silhouette and value grouping. The boss summon pose reads correctly inside the current encounter composition.
- Cards: verified in hand view after the dedicated card font path fixes. All six pilot card illustrations survive the current crop and rotation treatment. `card_attack_big_art` still has the highest crop pressure, but not enough to block the pack.
- Event: verified in the live event panel. `event_pick_something_illustration` leaves enough quiet space for the prompt and option stack, and the focal machine shape remains clear after scaling.
- Icons: verified across artifact, status, consumable, and inline energy usages. All selected icons read at gameplay size and are stronger than the legacy placeholder look, especially the artifact and status-effect set.

### Acceptance Checklist

- readable at gameplay size: pass
- silhouette distinct from nearby assets: pass
- palette matches approved style: pass
- no fake glyphs or broken anatomy: pass after routing all player-facing text through the Chinese-capable font setup
- card crop survives current card UI: pass
- event art does not crowd prompt text: pass
- icon reads at 32px and 64px: pass

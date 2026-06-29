# Four Character Card Mechanics Design

**Goal:** Establish the first-pass card design direction for the four playable characters by making their mechanics clear first, then mapping each mechanic back to character behavior and visual identity.

**Chosen approach:** Option 2, mechanic realignment. Existing cards remain the base material, but mechanics are reassigned so each character has a cleaner identity. New cards should fill gaps rather than replace the whole card pool.

## Current Card Pool Snapshot

The project currently has 66 card JSON files in `external/data/cards/`.

Approximate current distribution:

| Color | Current count | Current role |
|---|---:|---|
| Red | 19 | Attack chains, conditional attacks, vulnerable/weaken, attack duplication, some hand transformation |
| Blue | 13 | Draw, discard, discard pile reuse, random cost, random attacks, consumables |
| Green | 11 | Corrosion, delayed bomb, intent control, card duplication, card upgrading, persistent block |
| Orange | 6 | Retain, exhaust/banish, draw trigger energy, special discard, top-deck setup |
| White | 11 | Basic and general-purpose cards, generated cards, debug/special cards |
| Purple | 6 | Experimental cross-mechanics: retain growth, discard energy, deck upgrade, damage scaling |

The first design pass should aim for each character to have roughly 15-18 standard draftable cards. Red already has enough volume and mostly needs cleanup. Blue is close but needs discard payoff. Green needs more rhythm-condition cards. Orange needs the most new cards.

## Design Principles

1. Mechanics come first, but every stream must still read as character behavior.
2. Each character should have one clear core identity, one resource or defense axis, and one higher-ceiling payoff axis.
3. Avoid letting every character solve problems the same way. Draw, discard, retain, exhaust, copying, and upgrades should each have a primary owner.
4. First pass should prove identity and flow, not perfect balance.
5. Existing action scripts should be reused where possible. New scripts are acceptable only when a card concept cannot be expressed with current JSON/action composition.

## Character Boundaries

| Character | Core identity | Mechanics they should own | Mechanics they should avoid owning |
|---|---|---|---|
| Red | Close-range combo, pressure, burst | Multi-hit attacks, adjacent/position requirements, enemy-attacking rewards, vulnerable/weaken, attack duplication | Large draw-discard loops, long-term upgrade growth, retain preparation |
| Blue | Draw-discard loops, recovery from chaos, random payoff | Draw, discard, discard pile reuse, randomized costs, temporary consumables, discard-triggered payoff | Stable attack burst, permanent growth, exhaust as the main engine |
| Green | Rhythm control, delayed payoff, growth | Corrosion, delayed bombs, enemy intent control, first-card or repeated-type rhythm conditions, play duplication, upgrades, persistent block | Heavy randomness, pure burst attacks, backpack-style retain preparation |
| Orange | Preparation, retain, draw triggers, exhaust payoff | Retain, top-deck setup, draw-triggered effects, exhaust/banish, delayed release after setup | Draw-discard loops as the main engine, enemy control, red-style combo pressure |

## Character Streams

### Red

Player feel: active, close-range, pressuring enemies and building toward a strong attack turn.

Streams:

- **Combo chain:** low-cost attacks, multi-hit attacks, attacks that reward previous attacks.
- **Pressure counter:** extra block, damage, vulnerable, or weaken when the enemy is attacking.
- **Burst turn:** duplicate attacks, reduce costs, and reward many cards or attacks played in one turn.

Suggested new connector cards:

| Card concept | Function |
|---|---|
| Pursuit | Deal damage. If the previous card played this turn was an attack, draw 1 card. |
| Opening Strike | Deal damage. If the target is attacking, apply vulnerable. |
| Combo Starter | The next attack this turn costs less. |
| Finisher | Deal damage. Gains damage for each attack played this turn. |

### Blue

Player feel: messy but resourceful. The player discards, redraws, recovers cards from discard, and turns unstable hands into value.

Streams:

- **Draw-discard loop:** discard cards to draw, gain energy, or gain block.
- **Discard pile reuse:** pick cards from discard, play from discard, reshuffle discard into draw.
- **Random recovery:** randomized costs, random attacks, temporary consumables, and accidental payoff.

Suggested new connector cards:

| Card concept | Function |
|---|---|
| Hasty Sorting | Discard up to 2 cards. Draw 1 for each discarded card. |
| Something Fell Out | When discarded, gain energy or block. It may be unplayable. |
| Quick Search | Pick 1 card from discard and add it to hand with reduced cost this turn. |
| By Accident | Randomly play 1 card from discard. |
| Backup Drink | Generate a random consumable. If a card was discarded this turn, also draw. |

### Green

Player feel: controlled rhythm, delayed pressure, and gradual improvement. The player plans around first cards, repeated card types, enemy intent, corrosion, and upgrades.

Streams:

- **Rhythm control:** first-card effects, same-type follow-ups, enemy intent changes.
- **Echo performance:** copy the first card, generate shoves, repeat effects.
- **Tuning growth:** upgrade cards, improve card values, preserve or grow block.

Suggested new connector cards:

| Card concept | Function |
|---|---|
| First Beat | Gains an extra effect if it is the first card played this turn. |
| Echo Shield | Gain block. If the previous card was also a skill, gain more block. |
| Chorus | Duplicate the first attack or skill played this turn. |
| Distorted Note | Deal damage and apply corrosion. If the enemy is attacking, cycle its intent. |
| Metronome | Power. Each turn, the first card played has increased values. |
| Tuning | Improve one card in hand for the rest of combat. |
| Finale Burst | Deal damage based on corrosion or bomb charges on enemies. |

### Orange

Player feel: prepares ahead, packs tools, retains key cards, and cashes out after setup.

Streams:

- **Retain preparation:** keep key cards, reduce their future cost, or improve them after retain.
- **Draw triggers:** top-deck setup and effects that trigger when drawn.
- **Exhaust payoff:** exhaust/banish cards for damage, block, energy, draw, or money.

Suggested new connector cards:

| Card concept | Function |
|---|---|
| Bookmark Clip | Retain 1 card. That card costs less next turn. |
| Warmup | Gain block. If retained, this card's block improves. |
| Pack Sorting | Put 1 card from hand on top of draw pile. When drawn, gain energy. |
| Sports Drink | When drawn, gain energy. When played, draw and exhaust this card. |
| Bag Swing | Deal damage. If a card was exhausted this turn, deal more damage. |
| Old Item Reuse | Exhaust 1 card. Gain block and draw 1. |
| Travel Light | Power. The first time each turn a card is exhausted, gain energy. |
| Ready Stance | Retain all attacks. Those attacks deal more damage next turn. |
| Sprint Start | Costs less if drawn this turn. |
| Last Item | Deal damage based on the number of cards exhausted this combat. |

## Existing Card Realignment

### Blue Ownership

| Card | Recommendation | Reason |
|---|---|---|
| `attack_lower_cost_on_discard_card` | Move to blue | Cost reduction depends on discard count, making it a draw-discard payoff. |
| `card_energy_on_discard` | Move from purple to blue | Key discard payoff card. |
| `card_discard_block` | Move to blue | Discard-for-block gives blue a survival axis. |
| `card_discard_hand` | Keep blue | Main draw-discard engine. |
| `card_pick_from_discard` | Keep blue | Core discard pile selection tool. |
| `card_play_from_discard` | Keep blue | Main discard pile payoff. |
| `card_reshuffle_draw` | Keep blue | Core pile-cycle utility. |
| `randomize_hand_card` | Keep blue | Random recovery axis. |
| `card_add_consumable` | Keep blue | Random temporary tool, framed as improvised recovery. |
| `card_attack_rng` | Keep blue | Random output. |
| `transform_hand_card` | Move to blue | Better as chaotic recovery than red combo. |

### Red Ownership

| Card | Recommendation | Reason |
|---|---|---|
| `card_duplicate_attacks` | Keep/move to red | Attack duplication is red's burst payoff. |
| `card_requires_adjacency` | Keep red | Hand position can read as close-range combo. |
| `attack_with_conditional_block_card` | Keep red | Enemy-attacking reward fits counter-pressure. |
| `attack_with_conditional_draw_card` | Keep red | Acceptable as combo smoothing, not a broad draw engine. |
| `cards_played_attack_card` | Keep red | Finisher for burst turns. |
| `card_law` | Keep red | Can be framed as repeated fighting forms or combo rules. |
| `set_hand_energy_card` | Keep red | Rare burst-turn enabler. |
| `card_vulnerable_enemies` | Keep red | Breaks enemy defense for pressure. |
| `card_weaken_enemies` | Keep red | Pressure and defensive counterplay. |

### Green Ownership

| Card | Recommendation | Reason |
|---|---|---|
| `card_attack_corrosion` | Keep green | Main ongoing status pressure. |
| `card_bomb` | Keep green | Delayed payoff. |
| `card_cycle_enemy_intent` | Keep green | Enemy control axis. |
| `card_duplicate_plays` | Keep green | Echo/first-card duplication. |
| `card_generate_shoves` | Keep green | Rhythm/sonic shove generation. |
| `card_improving_block` | Keep green | Combat growth. |
| `card_preserve_block` | Keep green | Persistent shield. |
| `card_upgrade_card` | Keep green | Tuning and growth. |
| `upgrade_entire_deck_card` | Move from purple to green | Rare large upgrade payoff. |
| `improving_retain_block_card` | Move from purple to green | Retain appears in the text, but growth shield is more green than orange. |

### Orange Ownership

| Card | Recommendation | Reason |
|---|---|---|
| `retain_hand_card` | Keep orange | Retain preparation core. |
| `card_energy_on_draw` | Keep orange | Draw-trigger core. |
| `card_block_big` | Keep orange | Top-deck plus exhaust/block identity card. |
| `block_if_exhaust_card` | Keep orange | Requires exhaust to enable defense. |
| `card_special_discard` | Keep orange | Special backpack-style trigger, distinct from blue's draw-discard loop. |
| `card_attack_big` | Keep orange | Exhaust/ethereal burst with money payoff. |
| `card_attack_block` | Move from purple to orange | Retained attack/block behavior fits preparation. |
| `attack_increase_cost_on_damage_taken_card` | Leave purple/general for now | It can fit red or orange, but neither needs it in the first pass. |

### General Pool

Keep these as white/general/special unless a later pass needs them:

- `card_attack_basic`
- `card_block_basic`
- `custom_block_card`
- `variable_cost_attack_card`
- `add_health_card`
- `card_draft_random_player_pool`
- `card_shove`
- `card_restart_combat`
- `card_debug_log`

## First Implementation Boundary

The first implementation pass should be split into three phases.

### Phase 1: Realign Existing Cards

- Adjust card colors for the agreed ownership changes.
- Adjust starting decks so each character starts with cards that match its identity.
- Keep white and purple as general/experimental pools for cards not yet assigned.

### Phase 2: Fill Gaps

- Red: add only a few combo connector cards.
- Blue: add discard payoff cards.
- Green: add rhythm-condition cards.
- Orange: add retain, draw-trigger, and exhaust payoff cards.

### Phase 3: Tune Numbers

- Validate that each stream can form a coherent deck.
- Tune costs, damage, block, status stacks, and rarity only after the streams are playable.
- Do not chase final balance in the first pass.

## Acceptance Criteria

1. Each character has three explainable streams.
2. Each character has roughly 15-18 standard draftable cards after the first pass.
3. Starting decks show the core identity without giving complete combos immediately.
4. Blue and orange discard behavior stays distinct: blue is draw-discard cycling, orange is special preparation or backpack-trigger behavior.
5. Green duplication and upgrading support rhythm and growth instead of becoming pure burst.
6. Red draw or cost reduction exists only as combo smoothing and does not become a full resource-loop identity.
7. Existing JSON/action patterns remain the default implementation path.

## Out of Scope

- Final balance values.
- Full new art direction for every card.
- New UI for custom character resources.
- Replacing the whole existing card pool.
- Adding a new color, player, or character slot.

## Open Follow-Up

The next step after approving this design is to write an implementation plan that lists the exact JSON edits, new cards, starting deck changes, and validation commands.

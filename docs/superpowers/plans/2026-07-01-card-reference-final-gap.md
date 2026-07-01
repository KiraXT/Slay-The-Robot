# Final Card Reference Gap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现并配置剩余 4 张计划卡牌：`副歌`、`夹好书签`、`背包整理`、`准备姿态`。

**Architecture:** 复用现有 JSON/action/status 数据流。新增少量通用脚本：标记运行时牌实例、监听带 tag 的牌、复制当前出牌请求；然后用状态和 actions 组合配置 4 张卡牌。

**Tech Stack:** Godot 4、GDScript、JSON 数据资源、Python 回归测试、CSV/XLSX 台账。

---

## Files

- Create: `tests/card_reference_final_gap_regression.py`
- Create: `scripts/actions/cardset_actions/ActionModifyCardTags.gd`
- Create: `scripts/actions/meta_actions/ActionDuplicateCurrentCardPlay.gd`
- Create: `scripts/status_effects/StatusEffectTaggedCardTrigger.gd`
- Create: `external/data/status_effects/status_effect_chorus.json`
- Create: `external/data/status_effects/status_effect_bookmark_clip.json`
- Create: `external/data/status_effects/status_effect_pack_sorting.json`
- Create: `external/data/status_effects/status_effect_ready_stance.json`
- Create: `external/data/cards/card_chorus.json`
- Create: `external/data/cards/card_bookmark_clip.json`
- Create: `external/data/cards/card_pack_sorting.json`
- Create: `external/data/cards/card_ready_stance.json`
- Modify: `scripts/status_effects/StatusEffectOncePerTurnTrigger.gd`
- Modify: `scripts/status_effects/StatusEffectNextMatchingCardModifier.gd`
- Modify: `tests/card_configurable_cards_regression.py`
- Modify: `external/config/cards.csv`
- Modify: `external/config/cards.xlsx`

## Tasks

### Task 1: Failing Regression

- [ ] Add `tests/card_reference_final_gap_regression.py`.
- [ ] Assert that the new action/status scripts exist.
- [ ] Assert that the 4 card JSON files and 4 status JSON files exist.
- [ ] Assert that `cards.csv` contains all 4 card IDs.
- [ ] Run the new test and confirm it fails because files are missing.

### Task 2: Shared Scripts

- [ ] Add `ActionModifyCardTags.gd` to add/remove a configured tag on picked cards.
- [ ] Add `ActionDuplicateCurrentCardPlay.gd` to duplicate the current `CardPlayRequest` as a free duplicate play.
- [ ] Add `_disconnect_signals()` to `StatusEffectOncePerTurnTrigger.gd`.
- [ ] Extend `StatusEffectOncePerTurnTrigger.gd` so it can run action data with the original card play request.
- [ ] Add tag filtering to `StatusEffectNextMatchingCardModifier.gd`.
- [ ] Add `StatusEffectTaggedCardTrigger.gd` to listen for `card_drawn`, `card_play_started`, player turn start/end, and execute configured actions for tagged cards.
- [ ] Run the final gap regression and confirm it now fails on missing data resources.

### Task 3: Card and Status JSON

- [ ] Add `status_effect_chorus.json`, `status_effect_bookmark_clip.json`, `status_effect_pack_sorting.json`, and `status_effect_ready_stance.json`.
- [ ] Add `card_chorus.json`, `card_bookmark_clip.json`, `card_pack_sorting.json`, and `card_ready_stance.json`.
- [ ] Configure `副歌` as a green power applying `status_effect_chorus`.
- [ ] Configure `夹好书签` to pick one hand card, retain it, tag it, and apply the discount trigger state.
- [ ] Configure `背包整理` to pick one hand card, tag it, apply the draw trigger state, and move it to draw top.
- [ ] Configure `准备姿态` to pick all attacks in hand automatically, retain them, tag them, and apply next-turn damage trigger state.
- [ ] Run the final gap regression and confirm data checks pass except ledger/configurable-card count.

### Task 4: Ledger and Existing Regression

- [ ] Update `tests/card_configurable_cards_regression.py` from 22 to 26 expected configurable cards.
- [ ] Append the 4 new cards to `external/config/cards.csv`.
- [ ] Update `external/config/cards.xlsx` with matching ledger rows.
- [ ] Run all Python card regressions.
- [ ] Run Godot headless load verification.
- [ ] Run `git diff --check`.

### Task 5: Commit and Review

- [ ] Inspect the diff for unrelated changes.
- [ ] Commit the implementation.
- [ ] Run final verification from the committed branch.

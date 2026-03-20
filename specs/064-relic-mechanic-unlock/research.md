# Research: Relic Mechanic Unlock Tags (064)

## Existing Architecture

### RelicData.gd
`tags: Array[String]` already exists — no data-model changes required. Tags are plain strings (e.g. `"burn"`, `"chain"`).

### relics.json structure
Top-level `"relics"` dict keyed by tier (`"common"`, `"uncommon"`, `"rare"`), each mapping relic ID → entry dict with `name`, `tags`, `effect_stat`, `effect_mult`, `description`, `deck_count`. The `tags` array is already present in every entry.

### RelicManagerImpl — current flow
- `build_pool()` — parses JSON, populates `_all_by_tier` and `_decks` (shuffled expanded decks).
- `_build_expanded_deck(tier, exclude_id)` — builds shuffled deck from `_all_by_tier[tier]`, skipping `exclude_id`. Called at build time and on reshuffle.
- `draw_offer(tier)` — draws 2 distinct relics from the deck; strips remaining copies of `left.id` in-place before second draw.
- `draw_boss_offer()` — draws from `_all_by_tier["rare"]` directly (not from deck), excluding `active_relic_ids`.
- `pick_relic(id)` — appends id to `active_relic_ids`. No tag processing currently.
- `reset()` — clears all instance state including `active_relic_ids` and the pool.

### Tag classification problem
Current tags include category labels (`"combat"`, `"survival"`, `"projectile"`) mixed with mechanic-specific labels (`"burn"`, `"chain"`). A naïve "all non-`_unlocked` tags are mechanics" rule would cause picking `chaining_stone` (tags `["projectile", "chain"]`) to activate the `projectile` mechanic, blocking all other projectile relics.

**Decision**: Only treat a tag as a mechanic gate if there exists at least one relic in the loaded pool whose tags array contains `"<tag>_unlocked"`. This is fully data-driven — adding or removing `_unlocked` relics from JSON controls which tags become gates, with no code changes.

**Rationale**: Respects the YAGNI principle (Constitution V) — no hard-coded list of "special" mechanic names. `relics.json` is the sole source of truth for which tags are mechanic gates (Constitution II).

## Where to filter — deck build vs. draw time

**Decision**: Filter at `_build_expanded_deck` call sites (initial build and reshuffle).

**Rationale**: `_build_expanded_deck` is already the canonical place to shape the pool. Filtering there means eligibility is baked into the deck at build/reshuffle time, with no per-draw overhead. Because `burn` has `deck_count: 1`, after a single draw-and-strip cycle there are no remaining copies in the live deck, so the next reshuffle (which sees the mechanic as active) correctly excludes it.

**Alternative considered**: Filter every draw inside `draw_offer`. Rejected — higher complexity, no benefit for the current data set (all mechanic relics have `deck_count: 1`).

## Boss offer

`draw_boss_offer()` scans `_all_by_tier["rare"]` directly. Must also apply eligibility filtering using the same `_is_relic_eligible()` helper for consistency (FR-008).

## Mechanic tag computation

`_mechanic_tag_names: Array[String]` is precomputed in `build_pool()` by collecting every tag string of the form `"X_unlocked"` across the full pool and extracting `X`. Cleared in `reset()` and rebuilt by `build_pool()` each run.

## New relic entries in relics.json

Two unlock relics to demonstrate and exercise the feature:
- `burn_damage` (uncommon) — tags `["burn_unlocked"]`, bonus burn-damage effect.
- `chain_reach` (uncommon) — tags `["chain_unlocked"]`, chain relic synergy.

These also serve as data for the unit tests.

## Reset

`_activated_mechanics` and `_mechanic_tag_names` are both instance fields on `RelicManagerImpl`. `reset()` already clears instance state; we extend it to clear these two new fields. `RelicManager._on_run_started()` already calls `_impl.reset()` then `_impl.build_pool()`, so the order is correct.

## Unit test strategy

Add to `tests/unit/test_relic_deck.gd`:
- Picking a mechanic relic activates the mechanic and next deck reshuffle excludes it / includes `_unlocked` relics.
- `_unlocked` relics are absent from fresh deck (no mechanic active).
- Picking a non-mechanic relic (category tag only) does NOT activate any mechanic.
- Multiple independent mechanic pairs do not cross-contaminate.
- Boss offer respects mechanic eligibility.

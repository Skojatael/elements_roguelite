# Research: Relic Weighted Draws

**Feature**: 023-relic-weighted-draws
**Date**: 2026-03-03

---

## Decision 1: Where tier weights are stored

**Decision**: Add `relic_tier_weights` to `data/meta_config.json` — the existing balance config file already loaded by `ResourceManager.get_meta_config()`.

**Rationale**: `meta_config.json` is already the canonical home for tunable balance numbers (shard_divisor, damage_upgrade costs). Weights belong there. No new file, no new ResourceManager method.

**Alternatives considered**: Storing weights inside `relics.json` as a top-level key — rejected because weights are balance config, not content config.

---

## Decision 2: State design in RelicManagerImpl

**Decision**: Replace the flat `relic_pool: Array[RelicData]` with three internal structures:
- `_relics_by_id: Dictionary` — `id → RelicData` for fast stat lookup (replaces the per-call rebuild in `compute_stat_mult`)
- `_all_by_tier: Dictionary` — `tier → Array[RelicData]` full set per tier, kept immutable as the reshuffle source
- `_decks: Dictionary` — `tier → Array[RelicData]` current draw deck per tier, consumed and reshuffled on exhaustion
- `_tier_weights: Dictionary` — `tier → float` loaded once at build time

**Rationale**: Clean separation between "what relics exist" (lookup), "the full tier set" (reshuffle source), and "the current draw order" (deck). `compute_stat_mult` becomes O(active_relics) instead of O(pool_size + active_relics).

**Alternatives considered**: Keeping `relic_pool` flat and building tier sub-arrays dynamically at draw time — rejected because it mixes draw-state mutation with data lookup.

---

## Decision 3: build_pool signature

**Decision**: Change `build_pool(raw: Dictionary)` to `build_pool(relics_raw: Dictionary, config_raw: Dictionary)`. The autoload passes both `ResourceManager.get_relics()` and `ResourceManager.get_meta_config()`.

**Rationale**: RelicManagerImpl is a RefCounted — keeping it free of direct autoload dependencies makes it independently testable. Caller (RelicManager autoload) already has access to both sources and passes data in.

**Alternatives considered**: Loading ResourceManager inside build_pool — rejected (breaks thin-layer boundary; RefCounted calling an autoload couples them).

---

## Decision 4: Weighted tier selection algorithm

**Decision**: Linear scan with cumulative weight threshold. Roll `randf()` in [0, 1), iterate tiers in deterministic key order accumulating weight, select the tier where cumulative weight first exceeds the roll. Fallback to last tier if float precision prevents a match.

**Rationale**: Simple, correct, zero dependencies. Pool sizes are small (3 tiers). Performance is irrelevant.

**Alternatives considered**: Alias method, binary search on prefix sums — both overkill for 3 tiers.

---

## Decision 5: Deck draw direction

**Decision**: Use `pop_back()` — draw from the end of the shuffled array. GDScript `Array.pop_back()` is O(1); `pop_front()` is O(n).

**Rationale**: Performance correctness. Shuffled array has no meaningful "front" vs "back".

---

## Decision 6: Single-relic and empty-pool fallbacks

**Decision**: Preserve existing behaviour exactly.
- Total relics across all tiers == 0 → `draw_offer()` returns `[]`
- Total relics == 1 → returns `[relic, relic]`
- Otherwise → two independent `_draw_one()` calls

**Rationale**: Existing callers already handle these cases; no breakage.

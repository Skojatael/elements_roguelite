# Data Model: Relic Weighted Draws

**Feature**: 023-relic-weighted-draws
**Date**: 2026-03-03

---

## Runtime State — RelicManagerImpl (modified)

**File**: `scripts/managers/RelicManagerImpl.gd`

Replaces `relic_pool: Array[RelicData]` with:

| Field | Type | Description |
|---|---|---|
| `_relics_by_id` | `Dictionary` | `id → RelicData` — full lookup map for stat computation |
| `_all_by_tier` | `Dictionary` | `tier → Array[RelicData]` — immutable full set per tier; used as reshuffle source |
| `_decks` | `Dictionary` | `tier → Array[RelicData]` — current draw deck per tier; consumed via `pop_back()`; reshuffled when empty |
| `_tier_weights` | `Dictionary` | `tier → float` — normalised draw probabilities loaded from config |

`active_relic_ids`, `standard_rooms_cleared`, `OFFER_INTERVAL` — unchanged.

---

## Data Source Changes

### data/meta_config.json — MODIFIED

Add top-level key:

```json
"relic_tier_weights": {
    "common":   0.6,
    "uncommon": 0.3,
    "rare":     0.1
}
```

### data/relics.json — MODIFIED

Add `"uncommon"` tier section:

```json
{
    "relics": {
        "common":   { ... },
        "uncommon": {
            "<id>": { "name": "...", "tags": [...], "effect_stat": "...", "effect_mult": ..., "description": "..." }
        },
        "rare":     { ... }
    }
}
```

---

## State Flow

```
run_started
  └─ RelicManagerImpl.reset()
  └─ RelicManagerImpl.build_pool(relics_raw, config_raw)
       ├─ parse relics_raw → _relics_by_id, _all_by_tier
       ├─ load config_raw["relic_tier_weights"] → _tier_weights
       └─ for each tier: _decks[tier] = _all_by_tier[tier].duplicate().shuffled()

draw_offer() called
  ├─ total == 0 → return []
  ├─ total == 1 → return [single, single]
  └─ return [_draw_one(), _draw_one()]
       └─ _draw_one():
            ├─ roll randf() → select tier by cumulative weight
            ├─ if _decks[tier].is_empty():
            │    _decks[tier] = _all_by_tier[tier].duplicate()
            │    _decks[tier].shuffle()
            └─ return _decks[tier].pop_back()

compute_stat_mult(stat)
  └─ iterates active_relic_ids → looks up each in _relics_by_id (no rebuild)

run_ended
  └─ RelicManagerImpl.reset() → clears all four dicts + active_relic_ids
```

---

## Tier Weight Normalisation

Weights loaded from config are normalised at `build_pool` time so they always sum to 1.0:

```
total = sum of all weight values
_tier_weights[tier] = raw_weight / total   for each tier
```

Only tiers that have at least one relic entry are included in `_tier_weights`. Tiers present in the weight config but absent from relics.json are ignored.

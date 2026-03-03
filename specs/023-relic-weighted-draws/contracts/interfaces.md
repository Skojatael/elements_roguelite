# Contracts: Relic Weighted Draws

**Feature**: 023-relic-weighted-draws
**Date**: 2026-03-03

---

## RelicManagerImpl (scripts/managers/RelicManagerImpl.gd) — MODIFIED

### Removed field
```gdscript
var relic_pool: Array[RelicData] = []   # REMOVED
```

### New fields
```gdscript
var _relics_by_id: Dictionary = {}      # id → RelicData
var _all_by_tier: Dictionary = {}       # tier → Array[RelicData]  (reshuffle source)
var _decks: Dictionary = {}             # tier → Array[RelicData]  (draw state)
var _tier_weights: Dictionary = {}      # tier → float             (normalised)
```

### reset() — MODIFIED
```gdscript
## Clears all run state.
func reset() -> void:
    active_relic_ids = []
    standard_rooms_cleared = 0
    _relics_by_id = {}
    _all_by_tier = {}
    _decks = {}
    _tier_weights = {}
```

### build_pool() — MODIFIED signature
```gdscript
## Parses relics JSON and config into per-tier decks and weight table.
## relics_raw: output of ResourceManager.get_relics()
## config_raw: output of ResourceManager.get_meta_config()
func build_pool(relics_raw: Dictionary, config_raw: Dictionary) -> void
```

**Behaviour**:
1. Parse `relics_raw["relics"]` into `_relics_by_id` and `_all_by_tier`.
2. Load `config_raw["relic_tier_weights"]`; only include tiers present in `_all_by_tier`; normalise so weights sum to 1.0 → store in `_tier_weights`.
3. For each tier: duplicate and shuffle its `_all_by_tier` array → store in `_decks`.
4. Print pool summary.

### draw_offer() — MODIFIED
```gdscript
## Returns Array[RelicData] of exactly 2 entries.
## Empty if no relics defined. Both same if only 1 relic exists.
## Otherwise draws two cards independently via _draw_one().
func draw_offer() -> Array[RelicData]
```

### New private method
```gdscript
## Selects a tier by weight, draws from that tier's deck.
## Reshuffles the tier's deck from _all_by_tier if it is empty.
func _draw_one() -> RelicData
```

### compute_stat_mult() — MODIFIED (internal only, same signature)
```gdscript
## Now uses _relics_by_id directly instead of building a lookup from relic_pool.
func compute_stat_mult(stat: String) -> float
```

---

## RelicManager (autoload/RelicManager.gd) — MODIFIED

### _on_run_started() — MODIFIED
```gdscript
func _on_run_started() -> void:
    _impl.reset()
    _impl.build_pool(ResourceManager.get_relics(), ResourceManager.get_meta_config())
    relics_cleared.emit()
```

---

## data/meta_config.json — MODIFIED

```json
{
    "shard_divisor": 3,
    "damage_upgrade": { ... },
    "relic_tier_weights": {
        "common":   0.6,
        "uncommon": 0.3,
        "rare":     0.1
    }
}
```

---

## data/relics.json — MODIFIED

Add `"uncommon"` section alongside existing `"common"` and `"rare"`.

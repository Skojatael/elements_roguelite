# Interface Contracts: Crit Relic Integration

**Feature**: 052-crit-relic-integration

## RelicManagerImpl — new method

```gdscript
## Returns the combined additive bonus for all held relics with effect_stat == stat.
## Returns 0.0 if no held relics match the stat.
func compute_stat_addend(stat: String) -> float
```

- Iterates `active_relic_ids`, sums `effect_mult` for each relic whose `effect_stat == stat`.
- Returns `0.0` when no relics match (additive identity; base value unchanged).

## RelicManager (autoload) — new method

```gdscript
## Returns the combined additive bonus for the given stat across all active relics.
## Returns 0.0 if no relics modify that stat.
func get_stat_addend(stat: String) -> float
```

Thin wrapper: `return _impl.compute_stat_addend(stat)`.

## CombatComponent — modified fields and method

```gdscript
# New base fields (set in _ready(), immutable thereafter)
var _base_crit_chance: float = 0.0
var _base_crit_multiplier: float = 0.5

# Existing fields become effective (recomputed)
var _crit_chance: float       # effective, updated by _recompute_stats()
var _crit_multiplier: float   # effective, updated by _recompute_stats()
```

`_recompute_stats()` extended:
```gdscript
_crit_chance    = minf(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
_crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")
```

## SkillComponent — new fields, connections, and method

```gdscript
# New base fields (set in _load_skill_data(), immutable thereafter)
var _base_crit_chance: float = 0.0
var _base_crit_multiplier: float = 0.5

# Existing fields become effective (recomputed)
var _crit_chance: float       # effective
var _crit_multiplier: float   # effective
```

New `_recompute_crit_stats()`:
```gdscript
func _recompute_crit_stats() -> void:
    _crit_chance     = minf(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
    _crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")
```

New signal connections in `_ready()`:
```gdscript
RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_crit_stats())
RelicManager.relics_cleared.connect(func() -> void: _recompute_crit_stats())
RunManager.run_started.connect(func(_m: String) -> void: _recompute_crit_stats())
```

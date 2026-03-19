# Quickstart: Damage Reduction Implementation

**Feature**: 062-damage-reduction
**Date**: 2026-03-18

---

## What this feature adds

A `damage_reduction` stat (float, 0.0–0.5) on `StatsComponent` that reduces all incoming damage before HP is deducted. Stacks additively from relics (player) or is set directly from data (enemies).

---

## Files changed (no new files)

| File | What changes |
|------|-------------|
| `scripts/data_models/EnemyData.gd` | New field `damage_reduction` |
| `scenes/player/components/StatsComponent.gd` | New fields + `take_damage()` formula + relic recompute |
| `scenes/combat/enemies/Enemy.gd` | `initialize()` sets `_stats.damage_reduction` |
| `data/player.json` | Add `damage_reduction_cap: 0.5` |
| `data/relics.json` | Add `iron_veil` common relic |

---

## Implementation order

1. **`data/player.json`** — add the cap value first (data-first per constitution).
2. **`data/relics.json`** — add the `iron_veil` relic entry.
3. **`EnemyData.gd`** — add `damage_reduction` field and update `from_dict()`.
4. **`StatsComponent.gd`** — add fields, update `_ready()`, `take_damage()`, `_on_relic_applied()`.
5. **`Enemy.gd`** — set `_stats.damage_reduction` inside `initialize()`.
6. **Test** — verify player takes reduced damage; verify enemy with authored DR takes reduced damage.

---

## Key code snippets

### StatsComponent — new fields
```gdscript
var damage_reduction: float = 0.0
var _damage_reduction_cap: float = 0.5
```

### StatsComponent — `_ready()` (player branch addition)
```gdscript
_damage_reduction_cap = float(stats.get("damage_reduction_cap", 0.5))
```

### StatsComponent — `take_damage()` (mitigated — melee, projectile)
```gdscript
func take_damage(amount: float) -> void:
    var effective: float = amount * (1.0 - damage_reduction)
    current_health = maxf(current_health - effective, 0.0)
    health_changed.emit(current_health, max_health)
    if current_health == 0.0:
        died.emit()
```

### StatsComponent — `take_damage_raw()` (unmitigated — burn DoT)
```gdscript
func take_damage_raw(amount: float) -> void:
    current_health = maxf(current_health - amount, 0.0)
    health_changed.emit(current_health, max_health)
    if current_health == 0.0:
        died.emit()
```

### StatsComponent — `_on_relic_applied()` (append after existing max_health recompute)
```gdscript
damage_reduction = minf(_damage_reduction_cap, RelicManager.get_stat_addend("damage_reduction"))
```

### EnemyData — new field and from_dict
```gdscript
var damage_reduction: float = 0.0
# in from_dict():
result.damage_reduction = float(data.get("damage_reduction", 0.0))
```

### Enemy — initialize()
```gdscript
_stats.damage_reduction = data.damage_reduction
```

### Enemy — burn tick in `_physics_process()` (bypass DR)
```gdscript
# Replace: take_damage(burn_dmg)
# With:
_stats.take_damage_raw(burn_dmg)
```

---

## Verification checklist

- [ ] Player with `iron_veil` relic takes 10% less melee contact damage
- [ ] Player with `iron_veil` relic takes 10% less projectile damage
- [ ] Two `iron_veil` relics → 20% reduction (additive confirmed)
- [ ] Player without any DR relics → unchanged damage (0.0 * reduction = 0 change)
- [ ] Enemy with `damage_reduction: 0.20` in JSON → player deals 20% less damage to it
- [ ] Enemy with no `damage_reduction` field in JSON → no change (defaults to 0.0)
- [ ] DR cannot exceed 50% regardless of relic count
- [ ] Burn damage on an enemy with DR > 0 still deals full burn damage (unmitigated)
- [ ] Releasing all relics (relics_cleared) resets player DR to 0.0

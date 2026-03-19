# Data Model: Damage Reduction

**Feature**: 062-damage-reduction
**Date**: 2026-03-18

---

## Modified Entities

### EnemyData (`scripts/data_models/EnemyData.gd`)

New field:

| Field | Type | Default | Source |
|-------|------|---------|--------|
| `damage_reduction` | `float` | `0.0` | `enemies.json` (optional per entry) |

Constraint: value should be authored in [0.0, 0.5]; no runtime clamping for enemies (authored by content creators).

`from_dict()` reads: `float(data.get("damage_reduction", 0.0))`.

---

### StatsComponent (`scenes/player/components/StatsComponent.gd`)

New fields:

| Field | Type | Default | Scope |
|-------|------|---------|-------|
| `damage_reduction` | `float` | `0.0` | public — read by nothing external; written by `Enemy.initialize()` (enemies) or `_on_relic_applied()` (player) |
| `_damage_reduction_cap` | `float` | `0.5` | private — player only; read from `player.json → stats.damage_reduction_cap` |

**State transitions (player only)**:
- `_ready()` → `_damage_reduction_cap` read from `player.json`; `damage_reduction = 0.0`
- `_on_relic_applied()` → `damage_reduction = minf(_damage_reduction_cap, RelicManager.get_stat_addend("damage_reduction"))`
- On `relics_cleared` (via existing lambda) → same as `_on_relic_applied("")` → recomputes to 0.0 when no DR relics held

**`take_damage()` formula** (mitigated — melee, projectile):
```
effective_damage = amount * (1.0 - damage_reduction)
current_health   = maxf(current_health - effective_damage, 0.0)
```

**`take_damage_raw()` formula** (unmitigated — burn DoT, future bypass callers):
```
current_health = maxf(current_health - amount, 0.0)
```
Same signal emission and `died` logic as `take_damage()`; DR is simply not applied.

---

## JSON Schema Changes

### `data/player.json` — `stats` section

Add one key:
```json
"stats": {
  "max_health": 100.0,
  "damage_reduction_cap": 0.5
}
```

### `data/relics.json` — `common` tier

Add one entry:
```json
"iron_veil": {
  "name": "Iron Veil",
  "tags": ["survival"],
  "effect_stat": "damage_reduction",
  "effect_mult": 0.10,
  "description": "Take 10% less damage",
  "deck_count": 2
}
```

`effect_mult: 0.10` — consumed by `compute_stat_addend("damage_reduction")` which sums these additively.

### `data/enemies.json` — optional per-entry field

No existing entries are changed. Future entries may include:
```json
"damage_reduction": 0.20
```
Field is optional; `EnemyData.from_dict()` defaults to `0.0` when absent.

---

## Relic Stacking Example

Player holds two `iron_veil` relics (deck_count allows repeats after reshuffle):

```
get_stat_addend("damage_reduction") = 0.10 + 0.10 = 0.20
damage_reduction = minf(0.5, 0.20) = 0.20
effective_damage = 100.0 * (1.0 - 0.20) = 80.0
```

Player holds five iron_veil relics (5 × 0.10 = 0.50, at cap):

```
get_stat_addend("damage_reduction") = 0.50
damage_reduction = minf(0.5, 0.50) = 0.50
effective_damage = 100.0 * (1.0 - 0.50) = 50.0
```

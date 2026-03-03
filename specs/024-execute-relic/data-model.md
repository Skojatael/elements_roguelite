# Data Model: Conditional Damage Relics

**Feature**: 024-execute-relic
**Date**: 2026-03-03

---

## data/relics.json — MODIFIED

Add two entries under `"uncommon"`:

```json
"executioners_mark": {
    "name": "Executioner's Mark",
    "tags": ["combat"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "description": "+35% damage to enemies below 30% HP"
},
"berserker_stone": {
    "name": "Berserker Stone",
    "tags": ["combat"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "description": "+30% damage when below 50% HP"
}
```

**Notes**:
- `effect_stat: ""` and `effect_mult: 1.0` are intentional. `compute_stat_mult()` in RelicManagerImpl only applies mult when `effect_stat` matches a queried stat — empty string never matches, so these relics contribute nothing to the flat multiplier table. Their bonuses are applied conditionally in CombatComponent at hit time.
- `RelicData.from_dict()` handles empty `effect_stat` without changes — it defaults to `""` already.
- Future conditional relics of similar type follow the same pattern: `effect_stat: ""`, `effect_mult: 1.0`, and a code addition in CombatComponent.

---

## RelicData (scripts/data_models/RelicData.gd) — UNCHANGED

No schema changes. Existing fields cover both new entries.

---

## Runtime State

### RelicManagerImpl — MODIFIED (method only)

New method:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `get_hit_damage_mult()` | `target_hp_ratio: float, attacker_hp_ratio: float` | `float` | Combined multiplier from all active conditional relics; 1.0 if none apply |

All relic ID knowledge and thresholds live here. No relic logic leaks into callers.

### CombatComponent — MODIFIED

New field:

| Field | Type | Description |
|---|---|---|
| `_stats_component` | `StatsComponent` | `@onready` via `$"../StatsComponent"`; same sibling-path pattern as `$"../AttackArea"`; used to compute attacker HP ratio at hit time |

`CombatComponent` is unaware of specific relic IDs — it only computes context ratios and applies the multiplier returned by `RelicManager.get_hit_damage_mult()`.

### Enemy — MODIFIED (method only)

New method:

| Method | Returns | Description |
|---|---|---|
| `get_hp_ratio()` | `float` | `current_health / max_health`; returns `1.0` if `max_health <= 0` |

---

## Hit Damage Calculation Flow (after this feature)

```
_physics_process fires, attack timer elapses
  └─ target = _overlapping_enemies[0] as Enemy
  └─ attacker_ratio = _stats_component.current_health / _stats_component.max_health
  └─ dmg = attack_damage × RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio)
       └─ RelicManagerImpl.get_hit_damage_mult():
            ├─ mult = 1.0
            ├─ if has("executioners_mark") and target_hp_ratio < 0.30 → mult *= 1.35
            ├─ if has("berserker_stone") and attacker_hp_ratio < 0.50 → mult *= 1.30
            └─ return mult
  └─ target.take_damage(dmg)
```

Bonuses stack multiplicatively. All conditional relic logic is co-located in `RelicManagerImpl`.

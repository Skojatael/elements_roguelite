# Data Model: Burn Relic Damage Scaling (065)

**Feature Branch**: `065-burn-relic-scaling`
**Date**: 2026-03-19

---

## JSON Data Changes

`data/relics.json` — three conditional relics gain new fields: `condition_type`, `condition_threshold`, `condition_mult`. Non-conditional relics are unchanged.

**Bottled Oil** (common) — unchanged:
- Key: `burn_dot_damage`, `effect_stat: "burn_damage"`, `effect_mult: 0.20`
- `compute_stat_mult("burn_damage")` returns `1.20` when held

**Searing Seal** (uncommon) — new condition fields added:
```json
"condition_type": "target_is_burning",
"condition_threshold": 0.0,
"condition_mult": 1.50
```

**executioners_mark** (rare) — values moved from code to data:
```json
"condition_type": "target_hp_below",
"condition_threshold": 0.30,
"condition_mult": 1.35
```

**berserker_stone** (rare) — values moved from code to data:
```json
"condition_type": "attacker_hp_below",
"condition_threshold": 0.50,
"condition_mult": 1.30
```

---

## Entity Changes

### `scenes/combat/enemies/Enemy.gd`

**New method** (add after `get_hp_ratio()`):

```gdscript
## Returns true if the enemy currently has an active burn effect.
## Returns false if no burn has ever been applied or if the burn has expired.
func is_burning() -> bool:
	if _burn == null:
		return false
	return _burn.is_active()
```

No other changes to Enemy.

---

### `scripts/data_models/RelicData.gd`

**New fields**:
```gdscript
var condition_type: String = ""
var condition_threshold: float = 0.0
var condition_mult: float = 1.0
```

Parsed in `from_dict()` alongside existing fields. Non-conditional relics omit these from JSON and receive the defaults.

---

### `scripts/managers/RelicManagerImpl.gd`

**Modified method** — `get_hit_damage_mult()`:

Old signature:
```gdscript
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float
```

New signature:
```gdscript
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> float
```

New body replaces hard-coded ID/value checks with a generic loop over active relics:
```gdscript
for relic_id in active_relic_ids:
    var r = _relics_by_id.get(relic_id)
    if r.condition_type.is_empty(): continue
    match r.condition_type:
        "target_hp_below":   if target_hp_ratio < r.condition_threshold: mult *= r.condition_mult
        "attacker_hp_below": if attacker_hp_ratio < r.condition_threshold: mult *= r.condition_mult
        "target_is_burning": if target_is_burning: mult *= r.condition_mult
```

No relic IDs or multiplier values are hard-coded. The three condition type strings form a stable, closed set.

---

### `autoload/RelicManager.gd`

**Modified method** — `get_hit_damage_mult()` wrapper:

Old:
```gdscript
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
    return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)
```

New:
```gdscript
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float, target_is_burning: bool) -> float:
    return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio, target_is_burning)
```

Pure delegation. No logic added. Thin-wrapper rule respected.

---

### `scenes/player/components/CombatComponent.gd`

**Modified call site** in `_physics_process()`:

Old:
```gdscript
RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio)
```

New:
```gdscript
RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio, target.is_burning())
```

`target` is already typed as `Enemy`, so `.is_burning()` resolves without a cast.

---

### `scenes/combat/projectiles/Projectile.gd`

**Modified `_on_body_entered()`** — scale tick damage before passing to `on_burn_hit()`:

Old:
```gdscript
primary.on_burn_hit(_damage * _burn_damage_per_tick, _burn_duration, _burn_extend_seconds)
```

New:
```gdscript
primary.on_burn_hit(_damage * _burn_damage_per_tick * RelicManager.get_stat_mult("burn_damage"), _burn_duration, _burn_extend_seconds)
```

**Modified `_try_chain()`** — same change for chain target:

Old:
```gdscript
chain_target.on_burn_hit(_damage * _burn_damage_per_tick, _burn_duration, _burn_extend_seconds)
```

New:
```gdscript
chain_target.on_burn_hit(_damage * _burn_damage_per_tick * RelicManager.get_stat_mult("burn_damage"), _burn_duration, _burn_extend_seconds)
```

Only the burn tick argument is scaled. `_damage` used for direct hits is unchanged.

---

### `tests/unit/test_relic_deck.gd`

All existing `get_hit_damage_mult()` calls must add `false` as the third argument. New Searing Seal tests to be added.

---

## Data Flow Diagrams

### Burn Tick Damage Flow (Bottled Oil)

```
Player fires Magic Missile
  └─► Projectile._on_body_entered(body)
        ├─► primary.take_damage(_damage)           [direct hit — unscaled]
        └─► if has_burn_relic():
                scaled_tick = _damage
                            * _burn_damage_per_tick
                            * RelicManager.get_stat_mult("burn_damage")
                                             ↑
                                   [1.20 if Bottled Oil held, else 1.0]
                primary.on_burn_hit(scaled_tick, duration, extend)
                      └─► BurnEffect.apply(scaled_tick, duration)

Enemy._physics_process(delta)
  └─► burn_dmg = _burn.process(delta)   [returns scaled tick_damage or 0.0]
        └─► _stats.take_damage_raw(burn_dmg)
```

### Conditional Hit Multiplier Flow (Searing Seal)

```
CombatComponent._physics_process(delta)
  └─► target: Enemy
        ├─► target.get_hp_ratio()           → target_hp_ratio
        ├─► _stats_component.current_health / max_health → attacker_ratio
        └─► target.is_burning()             → target_is_burning
              └─► _burn != null and _burn.is_active()

      RelicManager.get_hit_damage_mult(target_hp_ratio, attacker_ratio, target_is_burning)
        └─► RelicManagerImpl.get_hit_damage_mult(...)
              mult = 1.0
              if executioners_mark and target_hp_ratio < 0.30: mult *= 1.35
              if berserker_stone   and attacker_ratio < 0.50:  mult *= 1.30
              if burn_damage        and target_is_burning:      mult *= 1.50
              return mult

      dmg = apply_crit(attack_damage * mult, crit_chance, crit_multiplier)
      target.take_damage(dmg)
```

### Stacking Example (all conditions met)

```
executioners_mark + berserker_stone + searing_seal, target burning, target < 30% HP, player < 50% HP:
  mult = 1.0 × 1.35 × 1.30 × 1.50 = 2.6325
```

All three checks are independent branches and apply multiplicatively.

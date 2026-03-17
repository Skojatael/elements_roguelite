# GDScript Contracts: 053-magic-missile-chain

## RelicManagerImpl (`scripts/managers/RelicManagerImpl.gd`)

### New method

```gdscript
## Returns true if the chaining_stone relic is active in this run.
## Pure query — no side effects.
func has_chain_relic() -> bool:
    return active_relic_ids.has("chaining_stone")
```

---

## RelicManager (`autoload/RelicManager.gd`)

### New method (thin wrapper)

```gdscript
## Delegates to RelicManagerImpl.has_chain_relic().
func has_chain_relic() -> bool:
    return _impl.has_chain_relic()
```

---

## Projectile (`scenes/combat/projectiles/Projectile.gd`)

### Extended setup signature

```gdscript
## chain_damage_mult: fraction of _damage applied to the chained target.
## Pass 1.0 if no chain behaviour is wanted (safe default).
func setup(target: Enemy, damage: float, speed: float, max_distance: float, chain_damage_mult: float) -> void:
```

**Callers**: `SkillComponent._on_skill_button_pressed()` — must pass `_chain_damage_mult`.

### New helper

```gdscript
## Attempts to chain-hit the closest living enemy to this projectile's position,
## excluding primary_target. No-op if relic not held or no valid second target.
func _try_chain(primary_target: Enemy) -> void:
```

**Called from**: `_on_body_entered()`, before `queue_free()`.

---

## SkillComponent (`scenes/player/components/SkillComponent.gd`)

### New instance variable

```gdscript
var _chain_damage_mult: float = 1.0
```

### Change in `_load_skill_data()` — add one line inside the magic_missile loop body

```gdscript
_chain_damage_mult = float((entry as Dictionary).get("chain_damage_mult", 1.0))
```

### Change in `_on_skill_button_pressed()` — extend projectile.setup() call

```gdscript
# Before:
projectile.setup(target, damage, _speed, _max_distance)
# After:
projectile.setup(target, damage, _speed, _max_distance, _chain_damage_mult)
```

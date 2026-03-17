# GDScript Contracts: 054-magic-missile-burn

## `scripts/data_models/BurnEffect.gd` (NEW)

```gdscript
class_name BurnEffect
extends RefCounted

var remaining_duration: float = 0.0
var tick_damage: float = 0.0
var _seconds_until_next_tick: float = 0.0

## Sets initial burn state. Resets tick timer to 1.0s.
func apply(p_tick_damage: float, duration: float) -> void

## Adds seconds to remaining_duration. No-op if amount <= 0.
func extend(seconds: float) -> void

## Advances time by delta. Returns tick_damage if a 1-second tick fired this frame, else 0.0.
## Returns 0.0 immediately if not is_active().
func process(delta: float) -> float

## Returns true while remaining_duration > 0.0.
func is_active() -> bool
```

---

## `RelicManagerImpl` (`scripts/managers/RelicManagerImpl.gd`)

### New method

```gdscript
## Returns true if the burn relic is active this run.
func has_burn_relic() -> bool:
    return active_relic_ids.has("burn")
```

---

## `RelicManager` (`autoload/RelicManager.gd`)

### New method (thin wrapper)

```gdscript
## Delegates to RelicManagerImpl.has_burn_relic().
func has_burn_relic() -> bool:
    return _impl.has_burn_relic()
```

---

## `Enemy` (`scenes/combat/enemies/Enemy.gd`)

### New field

```gdscript
var _burn: BurnEffect = null
```

### New public method

```gdscript
## Applies burn if none active, or extends existing burn duration.
## tick_dmg: damage per 1-second tick
## base_duration: seconds for a fresh burn
## extend_seconds: seconds added to an existing active burn
func on_burn_hit(tick_dmg: float, base_duration: float, extend_seconds: float) -> void:
    if _burn != null and _burn.is_active():
        _burn.extend(extend_seconds)
        return
    _burn = BurnEffect.new()
    _burn.apply(tick_dmg, base_duration)
```

### Addition to `_physics_process(delta)` — before existing contact damage block

```gdscript
if _burn != null and _burn.is_active():
    var burn_dmg: float = _burn.process(delta)
    if burn_dmg > 0.0:
        take_damage(burn_dmg)
```

---

## `SkillComponent` (`scenes/player/components/SkillComponent.gd`)

### New instance variables

```gdscript
var _burn_damage_per_tick: float = 0.0
var _burn_duration: float = 2.0
var _burn_extend_seconds: float = 2.0
```

### Addition to `_load_skill_data()` — alongside other JSON reads

```gdscript
_burn_damage_per_tick = float((entry as Dictionary).get("burn_damage_per_tick", 0.0))
_burn_duration = float((entry as Dictionary).get("burn_duration", 2.0))
_burn_extend_seconds = float((entry as Dictionary).get("burn_extend_seconds", 2.0))
```

### Change to `_on_skill_button_pressed()` — extend setup() call

```gdscript
# Before:
projectile.setup(target, damage, _speed, _max_distance, _chain_damage_mult)
# After:
projectile.setup(target, damage, _speed, _max_distance, _chain_damage_mult,
    _burn_damage_per_tick, _burn_duration, _burn_extend_seconds)
```

---

## `Projectile` (`scenes/combat/projectiles/Projectile.gd`)

### New fields

```gdscript
var _burn_damage_per_tick: float = 0.0
var _burn_duration: float = 2.0
var _burn_extend_seconds: float = 2.0
```

### Extended `setup()` signature

```gdscript
func setup(
    target: Enemy,
    damage: float,
    speed: float,
    max_distance: float,
    chain_damage_mult: float,
    burn_damage_per_tick: float,
    burn_duration: float,
    burn_extend_seconds: float
) -> void
```

### Addition to `_on_body_entered()` — after `primary.take_damage(_damage)`

```gdscript
if RelicManager.has_burn_relic():
    primary.on_burn_hit(_damage * _burn_damage_per_tick, _burn_duration, _burn_extend_seconds)
```

### Addition to `_try_chain()` — after `chain_target.take_damage(...)`

```gdscript
if RelicManager.has_burn_relic():
    chain_target.on_burn_hit(_damage * _burn_damage_per_tick, _burn_duration, _burn_extend_seconds)
```

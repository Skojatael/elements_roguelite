# Data Model: 054-magic-missile-burn

## JSON Schema Changes

### `data/skills.json` — magic_missile entry (add three fields)

```json
{
  "id": "magic_missile",
  "speed": 600.0,
  "max_distance": 2200.0,
  "max_charges": 3,
  "cooldown": 1.0,
  "chain_damage_mult": 0.5,
  "burn_damage_per_tick": 0.10,
  "burn_duration": 2.0,
  "burn_extend_seconds": 2.0
}
```

**New fields**:
- `burn_damage_per_tick: float` — fraction of projectile damage applied per burn tick. `0.10` = 10% per tick × 2 ticks = 20% total over base duration.
- `burn_duration: float` — initial burn duration in seconds on first hit. Default `2.0`.
- `burn_extend_seconds: float` — seconds added to an existing burn on each re-hit. Default `2.0`.

---

### `data/relics.json` — add burn to uncommon tier

```json
"burn": {
  "name": "Living Ember",
  "tags": ["projectile", "burn"],
  "effect_stat": "",
  "effect_mult": 1.0,
  "description": "Magic Missile ignites enemies, dealing 20% attack damage over 2s. Additional hits extend the burn."
}
```

---

## New Script: `scripts/data_models/BurnEffect.gd`

```
class_name BurnEffect extends RefCounted

var remaining_duration: float = 0.0
var tick_damage: float = 0.0
var _seconds_until_next_tick: float = 0.0
```

**Methods** (pure — no autoloads, no Node deps):

| Method | Signature | Behaviour |
|--------|-----------|-----------|
| `apply` | `(tick_damage: float, duration: float) -> void` | Sets `remaining_duration`, `tick_damage`, resets `_seconds_until_next_tick` to `1.0` |
| `extend` | `(seconds: float) -> void` | Adds `seconds` to `remaining_duration` |
| `process` | `(delta: float) -> float` | Decrements `remaining_duration` and `_seconds_until_next_tick` by `delta`. Returns `tick_damage` if tick fired this frame, `0.0` otherwise. Returns `0.0` without side effects when `remaining_duration <= 0` |
| `is_active` | `() -> bool` | Returns `remaining_duration > 0.0` |

**State transitions:**
```
[inactive] → apply() → [burning: remaining>0, tick pending]
[burning]  → process(delta) → returns 0.0 (no tick yet) or tick_damage (tick fired)
[burning]  → extend(seconds) → remaining_duration increases
[burning]  → process() with remaining reaching 0 → [inactive]
```

---

## GDScript State Changes

### `Enemy.gd` — new fields and method

```gdscript
var _burn: BurnEffect = null
```

New public method:
```gdscript
func on_burn_hit(tick_dmg: float, base_duration: float, extend_seconds: float) -> void
```

Processing addition in `_physics_process(delta)`:
```gdscript
if _burn != null and _burn.is_active():
    var burn_dmg: float = _burn.process(delta)
    if burn_dmg > 0.0:
        take_damage(burn_dmg)
```

### `SkillComponent.gd` — new instance variables

```gdscript
var _burn_damage_per_tick: float = 0.0
var _burn_duration: float = 2.0
var _burn_extend_seconds: float = 2.0
```

Read in `_load_skill_data()` from JSON. Passed to `Projectile.setup()`.

### `Projectile.gd` — new fields

```gdscript
var _burn_damage_per_tick: float = 0.0
var _burn_duration: float = 2.0
var _burn_extend_seconds: float = 2.0
```

Set in extended `setup()`. Used in `_on_body_entered()` and `_try_chain()`.

---

## Relationships

```
skills.json["magic_missile"]["burn_damage_per_tick/burn_duration/burn_extend_seconds"]
  └─ read by SkillComponent._load_skill_data()
  └─ passed to Projectile.setup()
  └─ stored as Projectile._burn_*
  └─ used in _on_body_entered() / _try_chain() → enemy.on_burn_hit(...)

relics.json["uncommon"]["burn"]
  └─ loaded by RelicManagerImpl.build_pool()
  └─ activated via RelicManager.pick_relic("burn")
  └─ queried by RelicManagerImpl.has_burn_relic()
  └─ exposed by RelicManager.has_burn_relic()
  └─ checked in Projectile before calling on_burn_hit()

Enemy._burn: BurnEffect (null when no burn)
  └─ set by on_burn_hit()
  └─ processed in _physics_process(delta)
  └─ damage applied via take_damage() → same kill credit path as direct hits
```

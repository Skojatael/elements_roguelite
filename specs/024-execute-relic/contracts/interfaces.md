# Contracts: Conditional Damage Relics

**Feature**: 024-execute-relic
**Date**: 2026-03-03

---

## data/relics.json — MODIFIED

Add under `"uncommon"`:

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

---

## Enemy (scenes/combat/enemies/Enemy.gd) — MODIFIED

### New method

```gdscript
## Returns current_health / max_health in range [0.0, 1.0].
## Returns 1.0 if max_health is 0 or negative (guard against invalid state).
func get_hp_ratio() -> float:
    if _stats.max_health <= 0.0:
        return 1.0
    return _stats.current_health / _stats.max_health
```

---

## RelicManagerImpl (scripts/managers/RelicManagerImpl.gd) — MODIFIED

### New method

```gdscript
## Returns the combined damage multiplier from all active conditional relics.
## target_hp_ratio:   target's current_hp / max_hp  (0.0–1.0)
## attacker_hp_ratio: attacker's current_hp / max_hp (0.0–1.0)
## Returns 1.0 if no conditional relics are active or no conditions are met.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
    var mult: float = 1.0
    if active_relic_ids.has("executioners_mark") and target_hp_ratio < 0.30:
        mult *= 1.35
    if active_relic_ids.has("berserker_stone") and attacker_hp_ratio < 0.50:
        mult *= 1.30
    return mult
```

---

## RelicManager (autoload/RelicManager.gd) — MODIFIED

### New delegation method

```gdscript
## Returns the combined hit-time damage multiplier from conditional relics.
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
    return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)
```

---

## CombatComponent (scenes/player/components/CombatComponent.gd) — MODIFIED

### New @onready field

```gdscript
@onready var _stats_component: StatsComponent = $"../StatsComponent"
```

Same sibling-path pattern as the existing `$"../AttackArea"` in `CombatComponent`. No Inspector assignment needed — `StatsComponent` is an architecturally fixed sibling in `Player.tscn`.

### Modified _physics_process

Replace the single `take_damage` call with:

```gdscript
var target: Enemy = _overlapping_enemies[0] as Enemy
var attacker_ratio: float = _stats_component.current_health / _stats_component.max_health
var dmg: float = attack_damage \
    * RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio)
target.take_damage(dmg)
```

`CombatComponent` is unaware of any specific relic ID or threshold — it only computes context ratios and applies the returned multiplier.

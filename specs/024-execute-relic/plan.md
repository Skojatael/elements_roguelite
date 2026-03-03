# Implementation Plan: Conditional Damage Relics

**Branch**: `024-execute-relic` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)

## Summary

Add two uncommon relics with conditional per-hit damage bonuses: Executioner's Mark (+35% damage to enemies below 30% HP) and Berserker Stone (+30% damage when player is below 50% HP). Both relics are data-driven for identity. All conditional relic logic lives in `RelicManagerImpl` via a new `get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)` method — keeping `CombatComponent` unaware of specific relic IDs. `Enemy` gains `get_hp_ratio()`. `CombatComponent` gains `@export var _stats_component` to supply attacker HP context at hit time.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: CombatComponent, Enemy, RelicManagerImpl, RelicManager (existing)
**Storage**: `data/relics.json` (existing)
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: One method call + two dictionary lookups + two float comparisons per attack tick — negligible
**Constraints**: No new files; no new autoloads; no new scenes
**Scale/Scope**: 4 files modified (relics.json, Enemy.gd, CombatComponent.gd, RelicManagerImpl.gd) + 1 autoload delegation

## Constitution Check

- **I. Single Responsibility**: All relic effect logic (flat and conditional) lives in `RelicManagerImpl`. `CombatComponent` only supplies context (target HP ratio, attacker HP ratio) and applies the returned multiplier — no relic ID knowledge leaks into it. `Enemy.get_hp_ratio()` is a query on Enemy's own state. ✅
- **II. Data-Driven Content**: Relic identities, names, descriptions in relics.json. Conditional thresholds (0.30, 0.50) and multipliers (1.35, 1.30) are mechanic constants in `RelicManagerImpl` — same place as `OFFER_INTERVAL`. Justified as mechanic-level behaviour, not tunable balance values. ✅ (with note)
- **III. Mobile-First**: One method call per attack tick with two has() checks and two float comparisons inside — negligible. ✅
- **IV. Editor-Centric**: No .tscn edits. `_stats_component` uses `@onready` with a direct sibling path (`$"../StatsComponent"`) — same pattern as `$"../AttackArea"` already in CombatComponent. Permitted by Principle IV for architecturally fixed component names inside `Player.tscn`. ✅
- **V. Simplicity & YAGNI**: One focused method added to RelicManagerImpl. No abstraction layer, no new base class, no generic conditional engine. ✅

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Threshold constants in GDScript (0.30, 0.50, 1.35, 1.30) | Conditional mechanics require code; no data-driven conditional evaluation engine exists | Building a generic conditional relic engine is over-engineering for two relics (Principle V) |

## Project Structure

```text
specs/024-execute-relic/
├── plan.md              ← this file
├── research.md          ✅
├── data-model.md        ✅
├── quickstart.md        ✅
├── contracts/
│   └── interfaces.md    ✅
└── tasks.md             ← /speckit.tasks output

Source changes:
data/relics.json                                   [MODIFIED] add executioners_mark, berserker_stone
scenes/combat/enemies/Enemy.gd                     [MODIFIED] add get_hp_ratio()
scripts/managers/RelicManagerImpl.gd               [MODIFIED] add get_hit_damage_mult()
autoload/RelicManager.gd                           [MODIFIED] expose get_hit_damage_mult() delegation
scenes/player/components/CombatComponent.gd        [MODIFIED] add _stats_component @onready; call get_hit_damage_mult() at hit time
```

## Implementation

### data/relics.json — add under "uncommon"

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

`effect_stat: ""` ensures `compute_stat_mult()` ignores these entries — their bonuses are applied via `get_hit_damage_mult()` instead.

### Enemy.gd — add method

```gdscript
func get_hp_ratio() -> float:
    if _stats.max_health <= 0.0:
        return 1.0
    return _stats.current_health / _stats.max_health
```

### RelicManagerImpl.gd — add method

```gdscript
## Returns the combined damage multiplier for conditional relics at hit time.
## target_hp_ratio: target's current_hp / max_hp (0.0–1.0)
## attacker_hp_ratio: attacker's current_hp / max_hp (0.0–1.0)
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
    var mult: float = 1.0
    if active_relic_ids.has("executioners_mark") and target_hp_ratio < 0.30:
        mult *= 1.35
    if active_relic_ids.has("berserker_stone") and attacker_hp_ratio < 0.50:
        mult *= 1.30
    return mult
```

### RelicManager.gd — add delegation

```gdscript
func get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float:
    return _impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)
```

### CombatComponent.gd — new @onready + modified _physics_process

```gdscript
@onready var _stats_component: StatsComponent = $"../StatsComponent"

# inside _physics_process, replace:
#   (_overlapping_enemies[0] as Enemy).take_damage(attack_damage)
# with:

var target: Enemy = _overlapping_enemies[0] as Enemy
var attacker_ratio: float = _stats_component.current_health / _stats_component.max_health
var dmg: float = attack_damage \
    * RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio)
target.take_damage(dmg)
```

Same sibling-path pattern as `$"../AttackArea"` already in use. No null-guard needed — `_stats_component` is architecturally guaranteed present in `Player.tscn`.

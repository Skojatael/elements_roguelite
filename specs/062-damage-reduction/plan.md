# Implementation Plan: Damage Reduction

**Branch**: `062-damage-reduction` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/062-damage-reduction/spec.md`

---

## Summary

Add a `damage_reduction` stat to `StatsComponent` that reduces incoming damage by a percentage before HP is deducted. Players gain reduction additively from relics (capped at 50%); enemies have a fixed base value from `enemies.json`. All damage pathways (melee contact, projectile, burn DoT) are covered by a single change to `StatsComponent.take_damage()`. No new files, autoloads, or scenes are required.

---

## Technical Context

**Language/Version**: GDScript 4.6 (static typing)
**Primary Dependencies**: RelicManager autoload (existing), ResourceManager autoload (existing)
**Storage**: `data/player.json` (cap value), `data/relics.json` (new relic), `data/enemies.json` (optional field per entry)
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Android mobile (portrait 1080×1920); Windows for development
**Project Type**: Single Godot project
**Performance Goals**: 60 fps — change is one float multiplication per `take_damage()` call; negligible overhead
**Constraints**: No new scenes, no new autoloads, no `.tscn` edits
**Scale/Scope**: 5 file edits across data + scripts; smallest possible surface area

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Single Responsibility | ✅ PASS | `damage_reduction` stat lives in `StatsComponent` (the existing stats authority). No autoload gains logic. `EnemyData` owns the data field. Each script retains a single reason to change. |
| II. Data-Driven Content | ✅ PASS | Cap value in `player.json`; relic entry in `relics.json`; enemy DR field in `enemies.json`. Zero balance constants in code. |
| III. Mobile-First | ✅ PASS | One float multiplication per `take_damage()` call. No shaders, no overdraw, no physics changes. Negligible performance impact. |
| IV. Editor-Centric | ✅ PASS | No `.tscn` edits required. No new node references. Existing `@export var` patterns unchanged. |
| V. Simplicity & YAGNI | ✅ PASS | Reuses `compute_stat_addend()` (already exists). No new abstractions, no new methods on autoloads, no intermediate services. |
| VI. Early Return | ✅ PASS | `take_damage()` remains flat. `_on_relic_applied()` uses the existing guard clause pattern (`is_equal_approx` early return for max_health; DR recompute runs unconditionally after). |

**Gate result**: PASS — proceed to Phase 0.

---

## Project Structure

### Documentation (this feature)

```text
specs/062-damage-reduction/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code — affected files only

```text
data/
├── player.json                              ← add damage_reduction_cap: 0.5 to stats
└── relics.json                              ← add iron_veil common relic

scripts/data_models/
└── EnemyData.gd                             ← add damage_reduction field

scenes/player/components/
└── StatsComponent.gd                        ← damage_reduction field + take_damage + relic recompute

scenes/combat/enemies/
└── Enemy.gd                                 ← initialize() sets _stats.damage_reduction
```

**Structure Decision**: Single Godot project. Changes touch the data layer first (Constitution II data-first rule), then data models, then the consuming scene scripts.

---

## Phase 0: Research

See [research.md](research.md) — all decisions resolved.

Key decisions:
- Apply reduction inside `StatsComponent.take_damage()` (single choke-point for all damage)
- Use existing `RelicManager.get_stat_addend("damage_reduction")` — no new methods
- Cap stored in `player.json` (not hardcoded in script)
- No `floor()` applied — float math consistent with existing `take_damage()` behaviour; flooring burn ticks to 0 would be a bug

---

## Phase 1: Design

See [data-model.md](data-model.md) and [quickstart.md](quickstart.md).

### Implementation steps (in order per Constitution II data-first rule)

#### Step 1 — `data/player.json`
Add `"damage_reduction_cap": 0.5` inside the `stats` object.

#### Step 2 — `data/relics.json`
Add to `relics.common`:
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

#### Step 3 — `scripts/data_models/EnemyData.gd`
- Add `var damage_reduction: float = 0.0`
- In `from_dict()`: `result.damage_reduction = float(data.get("damage_reduction", 0.0))`

#### Step 4 — `scenes/player/components/StatsComponent.gd`
Four changes:
1. Add fields:
   ```gdscript
   var damage_reduction: float = 0.0
   var _damage_reduction_cap: float = 0.5
   ```
2. In `_ready()` player branch, after reading `_base_max_health`:
   ```gdscript
   _damage_reduction_cap = float(stats.get("damage_reduction_cap", 0.5))
   ```
3. Replace `take_damage()` (mitigated path — melee, projectile):
   ```gdscript
   func take_damage(amount: float) -> void:
       var effective: float = amount * (1.0 - damage_reduction)
       current_health = maxf(current_health - effective, 0.0)
       health_changed.emit(current_health, max_health)
       if current_health == 0.0:
           died.emit()
   ```
   Add `take_damage_raw()` (unmitigated path — burn DoT):
   ```gdscript
   func take_damage_raw(amount: float) -> void:
       current_health = maxf(current_health - amount, 0.0)
       health_changed.emit(current_health, max_health)
       if current_health == 0.0:
           died.emit()
   ```
4. In `_on_relic_applied()`, append after the existing `health_changed.emit()` call:
   ```gdscript
   damage_reduction = minf(_damage_reduction_cap, RelicManager.get_stat_addend("damage_reduction"))
   ```

#### Step 5 — `scenes/combat/enemies/Enemy.gd`
In `initialize(data: EnemyData)`, after setting `_stats.max_health`:
```gdscript
_stats.damage_reduction = data.damage_reduction
```
In `_physics_process()`, replace `take_damage(burn_dmg)` with the raw path so burn ignores DR:
```gdscript
_stats.take_damage_raw(burn_dmg)
```

### No scene (.tscn) edits required
All changes are in `.gd` scripts and JSON data files. No Godot Editor work needed.

---

## Complexity Tracking

*(No Constitution violations — table omitted per template instruction.)*

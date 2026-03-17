# Implementation Plan: Magic Missile Charges

**Branch**: `048-projectile-charges` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/048-projectile-charges/spec.md`

## Summary

Add a charge pool (base 3, data-driven) to the Magic Missile skill. Each activation spends one charge; the skill is blocked at 0. Every successful melee hit restores one charge up to the maximum. The charge count is displayed on the ExplorationHUD. The skill is also renamed from `homing_projectile` to `magic_missile` throughout data and code.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Existing player components (`SkillComponent`, `CombatComponent`), `ExplorationHUD`, `data/skills.json`, `ResourceManager`
**Storage**: `data/skills.json` (adds `max_charges: 3`, renames `id`)
**Testing**: GUT unit tests (existing `tests/unit/` pattern)
**Target Platform**: Android mobile (portrait 1080×1920); Windows for development
**Performance Goals**: 60 fps on mid-range Android — charge logic is two integer ops per event, negligible cost
**Constraints**: Mobile renderer; Jolt physics; no Forward+ effects
**Scale/Scope**: Single player component + one HUD label; minimal surface area

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. Single Responsibility | ✅ Pass | Charge state in `SkillComponent`; melee-hit signal in `CombatComponent`; display in `ExplorationHUD`. No mixing. |
| II. Data-Driven Content | ✅ Pass | `max_charges: 3` in `skills.json`; no hardcoded balance constants in GDScript. |
| III. Mobile-First | ✅ Pass | Two integer ops + one signal emit per event. Zero frame-rate impact. |
| IV. Editor-Centric | ✅ Pass | New HUD label exported via `@export var _charge_label: Label`; no raw `.tscn` edits. |
| V. Simplicity / YAGNI | ✅ Pass | No new component, autoload, or abstraction. Charge state is two fields in `SkillComponent`. |
| VI. Early Return | ✅ Pass | Existing guard-clause pattern in `SkillComponent._on_skill_button_pressed` extended; charge block added as first guard. |

**No violations — plan may proceed.**

## Project Structure

### Documentation (this feature)

```text
specs/048-projectile-charges/
├── plan.md              ← this file
├── research.md          ← Phase 0 (complete)
├── data-model.md        ← Phase 1 (complete)
├── contracts/           ← N/A (game feature, no API endpoints)
└── tasks.md             ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (affected files)

```text
data/
└── skills.json                          # rename id + add max_charges

scenes/player/components/
├── SkillComponent.gd                    # charge state, spend guard, restore, signal, rename SKILL_ID
└── CombatComponent.gd                   # add signal melee_hit_landed, emit on hit

scenes/ui/hud/
├── ExplorationHUD.gd                    # add setup_skill(), connect charges_changed, update _charge_label
└── ExplorationHUD.tscn                  # Editor task: add Label node for charge display

scenes/core/
└── Main.gd                              # call _exploration_hud.setup_skill() after player ready

repo_map.md                              # update after implementation
```

**Structure Decision**: Single-project GDScript game — all changes are in-tree. No new directories created.

## Design Details

### 1. `data/skills.json` — rename + extend

```json
{
  "skills": [
    {
      "id": "magic_missile",
      "speed": 600.0,
      "max_distance": 2200.0,
      "max_charges": 3
    }
  ]
}
```

### 2. `SkillComponent.gd` — charge state

New additions:

```gdscript
signal charges_changed(current: int, maximum: int)

const SKILL_ID: String = "magic_missile"        # renamed from "homing_projectile"

var _max_charges: int = 0
var _current_charges: int = 0
```

`_load_skill_data()` — add after existing field reads:
```gdscript
_max_charges = int((entry as Dictionary).get("max_charges", 3))
assert(_max_charges > 0, "SkillComponent: 'max_charges' must be > 0 in skills.json")
```

`_ready()` — add connections:
```gdscript
RunManager.run_started.connect(func(_m: String) -> void: _reset_charges())
_combat_component.melee_hit_landed.connect(_on_melee_hit_landed)
```

New methods:
```gdscript
func _reset_charges() -> void:
    _current_charges = _max_charges
    charges_changed.emit(_current_charges, _max_charges)

func _on_melee_hit_landed() -> void:
    if _current_charges >= _max_charges:
        return
    _current_charges += 1
    charges_changed.emit(_current_charges, _max_charges)
```

`_on_skill_button_pressed()` — insert charge guard before all other guards:
```gdscript
func _on_skill_button_pressed() -> void:
    if _current_charges <= 0:
        return
    if not RunManager.is_run_active:
        return
    # ... existing guards and fire logic ...
    _current_charges -= 1
    charges_changed.emit(_current_charges, _max_charges)
```

### 3. `CombatComponent.gd` — melee hit signal

```gdscript
signal melee_hit_landed
```

In `_physics_process`, immediately after `target.take_damage(dmg)`:
```gdscript
melee_hit_landed.emit()
```

### 4. `ExplorationHUD.gd` — charge display

New export and method:
```gdscript
@export var _charge_label: Label

func setup_skill(skill: SkillComponent) -> void:
    skill.charges_changed.connect(_on_charges_changed)
    _on_charges_changed(skill._current_charges, skill._max_charges)

func _on_charges_changed(current: int, maximum: int) -> void:
    _charge_label.text = "{c}/{m}".format({"c": current, "m": maximum})
```

### 5. `Main.gd` — wire skill component

After player initialisation (same location as `setup_hp_bar` call), add:
```gdscript
_exploration_hud.setup_skill(_player.get_node("SkillComponent") as SkillComponent)
```

> Note: the exact node path depends on Player.tscn layout. Verify in editor — the pattern matches `setup_hp_bar` where `StatsComponent` is fetched from the player node.

### 6. `ExplorationHUD.tscn` — Editor task

Add a `Label` node as a sibling of `_skill_button`. Assign it to `_charge_label` export in the Inspector. Default text: `"3/3"`.

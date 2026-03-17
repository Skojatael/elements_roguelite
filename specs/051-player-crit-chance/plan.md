# Implementation Plan: Player Crit Chance

**Branch**: `051-player-crit-chance` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/051-player-crit-chance/spec.md`

## Summary

Add a per-hit critical strike system for all player damage (melee + magic missile). Crit chance (`0.0` default) and crit multiplier (`0.5` default) are added to `data/player.json` under a new `"crit"` section. Both `CombatComponent` and `SkillComponent` load these values once at startup and apply an inline crit roll at each damage event. No new files, no new autoloads, no scene edits — three files change.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `CombatComponent`, `SkillComponent`, `data/player.json`, `ResourceManager.get_player_config()`
**Storage**: `data/player.json` (extend existing file — add `"crit"` section)
**Testing**: Manual in-editor play per quickstart.md
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Performance Goals**: 60 fps mobile; `randf()` is O(1) — negligible impact
**Constraints**: No new `.tscn` edits; no new autoloads; no hardcoded balance values; crit not relic/meta-grantable in this feature
**Scale/Scope**: 3 file changes; self-contained within CombatComponent + SkillComponent

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Single Responsibility** | ✅ PASS | Crit roll stays within the component that owns damage output (CombatComponent for melee, SkillComponent for missile). No cross-component coupling introduced. Projectile remains unaware of crit. |
| **II. Data-Driven Content** | ✅ PASS | `"crit_chance": 0.0` and `"crit_multiplier": 0.5` in `player.json`. No balance constants in GDScript; defaults in code are code-safety fallbacks only. |
| **III. Mobile-First** | ✅ PASS | `randf()` and two float multiplications per hit. O(1), no allocations, no draw calls. |
| **IV. Editor-Centric** | ✅ PASS | No `.tscn` edits. No new nodes. All changes are pure GDScript. |
| **V. Simplicity & YAGNI** | ✅ PASS | Crit roll inlined in each component (2-3 lines). No shared utility for a trivially simple formula. Crit excluded from `_recompute_stats()` — no relic/meta integration in this feature. |
| **VI. Early Return** | ✅ PASS | Existing guard clause pattern preserved. Crit roll replaces a single `dmg` assignment — no new nesting introduced. |

No violations. No complexity tracking required.

## Project Structure

### Documentation (this feature)

```text
specs/051-player-crit-chance/
├── plan.md          ← this file
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md         ← created by /speckit.tasks
```

### Source Code (files changed)

```text
data/
└── player.json                                  ← add "crit": {"crit_chance": 0.0, "crit_multiplier": 0.5}

scenes/player/components/
├── CombatComponent.gd                           ← load crit vars + apply crit roll to melee
└── SkillComponent.gd                            ← load crit vars + apply crit roll to missile
```

**Structure Decision**: Single-project Godot layout. All changes in existing files/directories. No new scripts, scenes, or autoloads.

## Design Detail

### `data/player.json` addition

```json
"crit": {
  "crit_chance": 0.0,
  "crit_multiplier": 0.5
}
```

### `CombatComponent.gd` additions

**New vars** (after existing `_base_*` vars):
```gdscript
var _crit_chance: float = 0.0
var _crit_multiplier: float = 0.5
```

**In `_ready()`** (after existing combat/stats loads):
```gdscript
var crit: Dictionary = ResourceManager.get_player_config().get("crit", {})
_crit_chance = minf(1.0, float(crit.get("crit_chance", 0.0)))
_crit_multiplier = float(crit.get("crit_multiplier", 0.5))
```

**New private helper**:
```gdscript
func _apply_crit(damage: float) -> float:
    if randf() >= _crit_chance:
        return damage
    return floorf(damage * (1.0 + _crit_multiplier))
```

**In `_physics_process()`** — replace the `dmg` line:
```gdscript
# Before:
var dmg: float = attack_damage \
    * RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio)
target.take_damage(dmg)

# After:
var dmg: float = _apply_crit(attack_damage \
    * RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio))
target.take_damage(dmg)
```

### `SkillComponent.gd` additions

**New vars** (after existing `_cooldown_*` vars):
```gdscript
var _crit_chance: float = 0.0
var _crit_multiplier: float = 0.5
```

**In `_load_skill_data()`** (after the existing field loads, before the `break`):
```gdscript
var crit: Dictionary = ResourceManager.get_player_config().get("crit", {})
_crit_chance = minf(1.0, float(crit.get("crit_chance", 0.0)))
_crit_multiplier = float(crit.get("crit_multiplier", 0.5))
```

**New private helper** (same pattern as CombatComponent):
```gdscript
func _apply_crit(damage: float) -> float:
    if randf() >= _crit_chance:
        return damage
    return floorf(damage * (1.0 + _crit_multiplier))
```

**In `_on_skill_button_pressed()`** — wrap damage computation:
```gdscript
# Before:
var damage: float = floorf(_combat_component.attack_damage * 0.75)

# After:
var damage: float = _apply_crit(floorf(_combat_component.attack_damage * 0.75))
```

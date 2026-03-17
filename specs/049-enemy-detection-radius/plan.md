# Implementation Plan: Enemy Detection Radius

**Branch**: `049-enemy-detection-radius` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/049-enemy-detection-radius/spec.md`

## Summary

Apply `detection_range` from `enemies.json` to each enemy's `DetectionArea` collision shape at spawn time. `EnemyData` already parses the field; `Enemy.initialize()` already receives `EnemyData` — the entire change is adding radius assignment inside that one method.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `Enemy.gd`, `EnemyData.gd` (existing), `data/enemies.json` (existing)
**Storage**: No changes — `detection_range` already in `enemies.json`, already parsed by `EnemyData`
**Testing**: GUT unit tests not applicable (scene-dependent node access)
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: One `get_node` + one property assignment per enemy spawn — negligible
**Constraints**: Jolt physics; Mobile renderer; must not share shape resource across instances

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. Single Responsibility | ✅ Pass | Change is confined to `initialize()` — the existing method for applying data to an enemy instance |
| II. Data-Driven Content | ✅ Pass | This feature exists to enforce Constitution II — radius moves from hardcoded editor value to JSON |
| III. Mobile-First | ✅ Pass | One property write per spawn; zero per-frame cost |
| IV. Editor-Centric | ✅ Pass | No raw `.tscn` edits; shape node accessed by path at runtime |
| V. Simplicity / YAGNI | ✅ Pass | No new classes, signals, or abstractions. Single method change |
| VI. Early Return | ✅ Pass | Fallback guard added with early branch on invalid range |

**No violations — plan may proceed.**

## Project Structure

### Documentation (this feature)

```text
specs/049-enemy-detection-radius/
├── plan.md         ← this file
├── research.md     ← Phase 0 (complete)
├── data-model.md   ← Phase 1 (complete)
└── tasks.md        ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (affected files)

```text
scenes/combat/enemies/
└── Enemy.gd        # initialize() — apply detection_range to CollisionShape2D radius

repo_map.md         # update Enemy.gd entry
```

**No other files change.** `enemies.json` and `EnemyData.gd` already have the field.

## Design Details

### `Enemy.initialize()` — single addition

Current:
```gdscript
func initialize(data: EnemyData) -> void:
    _data = data
    _stats.max_health = data.max_health
    _stats.current_health = data.max_health
```

After:
```gdscript
const DETECTION_RANGE_FALLBACK: float = 300.0

func initialize(data: EnemyData) -> void:
    _data = data
    _stats.max_health = data.max_health
    _stats.current_health = data.max_health
    _apply_detection_range(data.detection_range)

func _apply_detection_range(range_px: float) -> void:
    var effective: float = range_px
    if effective <= 0.0:
        push_warning("Enemy: invalid detection_range={r} for id={id} — using fallback {f}".format({
            "r": range_px, "id": _data.id, "f": DETECTION_RANGE_FALLBACK,
        }))
        effective = DETECTION_RANGE_FALLBACK
    var shape_node := _detection_area.get_node("CollisionShape2D") as CollisionShape2D
    (shape_node.shape as CircleShape2D).radius = effective
```

Extracted to `_apply_detection_range()` to keep `initialize()` readable and to give the validation logic a clear home.

### Why a separate private method?

`initialize()` is called from `_ready()`, which means `_detection_area` is guaranteed non-null. The private helper keeps `initialize()` at a flat list of single-responsibility lines.

### Shape resource safety

`PackedScene.instantiate()` deep-copies resources flagged `local_to_scene = true` (Godot 4 default for collision shapes). Each enemy instance gets its own `CircleShape2D` object — mutating `radius` affects only that instance, not all enemies of the same type.

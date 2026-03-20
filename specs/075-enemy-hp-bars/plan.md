# Implementation Plan: Enemy HP Bars

**Branch**: `075-enemy-hp-bars` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/075-enemy-hp-bars/spec.md`

## Summary

Each enemy instance displays a health bar below its sprite that tracks current/max HP in real time and moves with the enemy. The existing `HPBar` scene and script (built for the player) is reused directly — no new UI class is needed.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `HPBar` (existing), `StatsComponent` (existing), `Enemy.tscn` (existing)
**Storage**: N/A
**Testing**: GUT unit tests (existing framework)
**Target Platform**: Android mobile, portrait 1080×1920
**Performance Goals**: 60 fps on mid-range mobile; one extra Control node per enemy is negligible
**Constraints**: Mobile renderer; no Forward+ effects
**Scale/Scope**: Up to ~10 enemies on screen simultaneously

## Constitution Check

- **I. Single Responsibility** ✅ — `HPBar` already owns HP display. `Enemy.gd` gains one export field and one setup call. No logic is mixed.
- **II. Data-Driven Content** ✅ — No balance constants introduced. Bar offset is a visual property set in the editor.
- **III. Mobile-First** ✅ — One `Control` + two `ColorRect` children per enemy. Negligible draw-call cost.
- **IV. Editor-Centric** ✅ — `HPBar` added to `Enemy.tscn` via the Godot Editor; reference assigned via `@export var`.
- **V. Simplicity & YAGNI** ✅ — Reuses `HPBar.tscn` directly; zero new scenes or classes.
- **VI. Early Return** ✅ — `HPBar._on_health_changed` already guards with `if max_hp <= 0.0: return`. No new nesting introduced.

## Decisions

1. **Reuse `HPBar.tscn` as-is** — The existing scene and script already handle the fill-fraction logic, signal connection, and label. No new class is needed (YAGNI).
2. **Attach as child node in editor** — An instanced `HPBar` added to `Enemy.tscn` inherits the enemy's world transform automatically; no `_process` position sync code is required.
3. **Emit `health_changed` in `apply_difficulty()`** — Currently `apply_difficulty()` writes `_stats.max_health` and `_stats.current_health` directly without emitting the signal, so the bar goes stale after difficulty scaling. The fix is to emit `health_changed` at the end of `apply_difficulty()`.

## Schema Changes

None. `StatsComponent` already emits `health_changed(new_health, max_health)`. `EnemyData` requires no new fields.

## Affected Files

### `scenes/combat/enemies/Enemy.tscn` *(editor task)*
Add an instanced `HPBar` node as a child of the root `Enemy` node. Position it at approximately `(−50, 30)` local offset so the bar appears centred below the enemy sprite. The width should match the bar size used in the player HUD (configurable in the editor). Assign the node to the `_hp_bar` export slot on the `Enemy` script.

### `scenes/combat/enemies/Enemy.gd` *(code)*
Add `@export var _hp_bar: HPBar` alongside the existing onready exports. At the end of `_ready()`, after `initialize()` has set up `_stats`, call `_hp_bar.setup(_stats)`. In `apply_difficulty()`, after updating `_stats.max_health` and `_stats.current_health`, emit `_stats.health_changed` so the bar reflects the scaled values immediately.

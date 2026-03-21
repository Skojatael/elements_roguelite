# Implementation Plan: Healer Follow Behavior

**Branch**: `078-healer-follow-behavior` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/078-healer-follow-behavior/spec.md`

## Summary

Healer enemies (any whose `id` ends in `_healer`) will follow the closest living ally enemy at a standoff distance of `heal_radius - 20` units instead of chasing the player. When no allies are alive, they revert to standard player chase. All logic lives in `Enemy.gd` as an additional movement branch in `_physics_process`; no new files or data fields are needed.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot built-in CharacterBody2D, Jolt physics
**Storage**: N/A (runtime only)
**Testing**: GUT unit tests
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps on mid-range Android; closest-ally scan runs every physics frame over a small room population (typically ≤8 enemies)
**Constraints**: No new nodes, no new JSON fields, no scene edits

## Constitution Check

- **I. Single Responsibility**: The movement branch is a conditional path inside the existing `_physics_process` movement block — no new script or class is created. Enemy.gd already owns all enemy-AI behavior. ✅
- **II. Data-Driven Content**: No new balance constant introduced in code. The standoff distance is derived from `heal_radius` (already in JSON) minus the literal `20`, which is architectural (heal_radius - contact_margin) — not a balance value. No JSON changes needed for existing behavior; if a designer wants to tune, they tune `heal_radius`. ✅
- **III. Mobile-First**: Closest-ally scan is O(n) over room population (~8 enemies max). Distance comparison costs are negligible at 60 fps. No allocation per frame (reuse local variable). ✅
- **IV. Editor-Centric**: No scene changes. `Enemy.gd` is a script-only change. ✅
- **V. Simplicity & YAGNI**: No new abstraction, no new class. Behavior is a two-branch guard in the existing movement section. ✅
- **VI. Early Return**: The healer branch returns early when follow distance is satisfied; the fallback to player-chase is the existing code path. ✅

All constitution gates pass.

## Decisions

1. **Where to implement**: Directly in `Enemy.gd`'s `_physics_process` movement block. The healer behavior is a movement variant on the existing `CharacterBody2D`; it does not warrant a separate component because Enemy.gd already owns all enemy AI. A component would be speculative abstraction (Principle V).

2. **How to detect healers**: `_data.id.ends_with("_healer")` checked once per frame in the movement section. The string suffix convention is defined by the spec and already established in the enemies.json data.

3. **How to find closest ally**: Iterate `get_parent().get_children()`, skip non-`Enemy` instances and `self`, compute `global_position.distance_to()`, track minimum. This is the same parent-scan pattern already used by `_do_heal_scan()`. No caching; the scan is cheap at room population sizes.

## Schema Changes

No new JSON fields. No new GDScript fields in `EnemyData`. The existing `heal_radius: float` field on `EnemyData` is the only data dependency, and it is already populated for `forest_healer`.

One new runtime variable added to `Enemy.gd`: `_follow_target: Enemy = null` — a frame-cache for the currently tracked ally. It is nulled at the start of each healer movement pass and re-resolved each frame, so it never becomes a stale reference.

## Affected Files

**`scenes/combat/enemies/Enemy.gd`** — The only modified file. Two changes:
1. Add `var _follow_target: Enemy = null` field declaration alongside existing runtime state fields.
2. Extend the movement section of `_physics_process`: before the existing player-chase logic, check if `_data.id.ends_with("_healer")`. If true, scan siblings for the closest living `Enemy` (excluding self), store it in `_follow_target`. If a follow target exists, move toward it stopping at `heal_radius - 20` distance and return early. If no follow target found (no living allies), fall through to the standard player-chase path below.

**`tests/unit/test_enemy_healer_follow.gd`** *(new file)* — GUT unit test covering: healer moves toward closest ally, healer stops at `heal_radius - 20`, healer updates target when a nearer ally appears, healer falls back to player-chase when no allies exist.

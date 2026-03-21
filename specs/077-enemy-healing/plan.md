# Implementation Plan: Enemy Healing Mechanics

**Branch**: `077-enemy-healing` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/077-enemy-healing/spec.md`

## Summary

Two independent enemy healing behaviours driven entirely by optional `enemies.json` fields: (1) continuous self-regen proportional to max HP per second; (2) a periodic ally-heal skill that restores a fixed HP amount to all living Enemy instances within a configurable radius, explicitly excluding the caster. Both mechanics reuse the existing `StatsComponent.heal()` and `StatsComponent.regen_tick_amount()` static helpers already in the codebase. No new scenes, autoloads, or systems are required.

## Technical Context

**Language/Version**: GDScript 4.6 (static typing)
**Primary Dependencies**: Godot 4.6 engine; Jolt physics; existing `EnemyData`, `StatsComponent`, `Enemy` scene/script
**Storage**: `data/enemies.json` (existing file, adding optional fields)
**Testing**: GUT 9.6 unit tests under `tests/unit/`
**Target Platform**: Android mobile / Windows dev; 60 fps constraint
**Performance Goals**: Regen tick runs every frame inside `_physics_process` — O(1) per regen enemy. Ally-heal scan runs on cooldown (default every 5 s) and iterates sibling nodes in the room — O(n) where n is enemy count per room (≤ ~10); negligible.
**Constraints**: All new fields optional and default to 0 — zero impact on existing enemies.

## Constitution Check

- **I. Single Responsibility** ✅ — Both behaviours live entirely in `Enemy.gd` (the script that already owns all enemy runtime logic) and `EnemyData.gd` (the typed data wrapper). No new scripts.
- **II. Data-Driven Content** ✅ — All four new values (`regen_rate`, `heal_amount`, `heal_radius`, `heal_cooldown`) come from `data/enemies.json`. No numeric constants in `.gd` files except the `heal_cooldown` default (5.0 s), which is a safe fallback when the field is absent in JSON.
- **III. Mobile-First Performance** ✅ — Regen is a single multiply-add per enemy per frame. Ally-heal scan fires at most once every 5 s and touches at most ~10 nodes.
- **IV. Editor-Centric Workflow** ✅ — No `.tscn` changes. All new logic is in scripts only.
- **V. Simplicity & YAGNI** ✅ — No new abstractions. Ally discovery reuses `get_parent().get_children()` with an `is Enemy` guard, the minimal pattern for sibling node access.
- **VI. Early Return** ✅ — New code follows the existing guard-clause pattern already established in `Enemy.gd`.

## Decisions

**Decision 1 — How does the healer find ally enemies?**
Walk `get_parent().get_children()`, cast each to `Enemy` with `is Enemy`, skip self, skip those outside `heal_radius`. No new signal or registry needed — enemies share the same `RoomSpawner` parent node and the approach is already used elsewhere in the codebase for sibling queries.

**Decision 2 — Public API for receiving heals**
Add a `receive_heal(amount: float) -> void` method to `Enemy` that calls `_stats.heal(amount)`. This keeps `_stats` private and gives the healer a clean call site that doesn't reach into another instance's internals.

**Decision 3 — Default heal_cooldown**
`heal_cooldown` defaults to 5.0 seconds in `EnemyData.from_dict` when the field is absent in JSON. This matches the spec assumption and avoids a zero-cooldown infinite-heal bug.

## Schema Changes

Four optional fields added to `EnemyData` (all default 0.0, except `heal_cooldown` which defaults to 5.0):

| Field | Type | Default | Meaning |
|---|---|---|---|
| `regen_rate` | `float` | `0.0` | Fraction of max HP recovered per second (0.02 = 2%/s) |
| `heal_amount` | `float` | `0.0` | Flat HP granted to each in-radius ally per skill use |
| `heal_radius` | `float` | `0.0` | Distance (px) within which allies are healed |
| `heal_cooldown` | `float` | `5.0` | Seconds between heal skill activations |

`data/enemies.json` — `forest_healer` already declares `heal_amount: 8` and `heal_radius: 80`. These will now be parsed. A `heal_cooldown` entry may optionally be added; otherwise the 5.0 s default applies.

## Affected Files

### Modified

**`scripts/data_models/EnemyData.gd`**
Add the four new `var` fields with their defaults. In `from_dict`, read each via `data.get(...)` with the appropriate default — matching the existing optional-field pattern used for `root_duration`, `poison_duration`, etc.

**`scenes/combat/enemies/Enemy.gd`**
Add two new private state variables: `_heal_cooldown_remaining: float` (countdown timer for the ally-heal skill, initialised to `_data.heal_cooldown` in `initialize()`) and nothing extra for regen (it uses `delta` directly). In `_physics_process`, after the existing burn/root/contact blocks, add two new guarded blocks: (a) a regen tick that calls `StatsComponent.regen_tick_amount` then `_stats.heal()` when `_data.regen_rate > 0.0`; (b) a heal-skill block that decrements `_heal_cooldown_remaining`, and when ≤ 0.0 iterates siblings to call `receive_heal()` on each in-radius `Enemy` excluding self, then resets the timer to `_data.heal_cooldown`. Also add the public `receive_heal(amount: float) -> void` method.

### New

**`tests/unit/test_enemy_data_healing.gd`**
GUT unit test for `EnemyData.from_dict` covering: all four new fields parsed correctly from a full dict; each field absent in dict falls back to its default; a zero `heal_cooldown` in JSON is stored as-is (caller behaviour, not clamped in the data model).

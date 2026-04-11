# Implementation Plan: Enemy Ranged Attack

**Branch**: `083-enemy-ranged-attack` | **Date**: 2026-03-23 | **Spec**: [spec.md](spec.md)

## Summary

Enemies whose `attack_range` exceeds a data-driven threshold fire a straight-line projectile toward the player instead of applying contact damage. The player's `Projectile.gd` cannot be reused (it tracks a moving enemy, collides with enemies only, and carries player-specific relic hooks). A dedicated `EnemyProjectile` scene handles direction-locked travel, player-only collision, and auto-despawn. `Enemy.gd` gains a one-time `_is_ranged` flag that redirects the existing contact-damage tick into projectile firing.

## Technical Context

**Language/Version**: GDScript (Godot 4.6, static typing)
**Storage**: `data/dungeon_config.json` — one new field in `enemy_spawn`
**Testing**: GUT unit tests in `tests/unit/`
**Target Platform**: Android mobile portrait; Windows dev
**Performance Goals**: 60 fps — one new moving node per active ranged enemy; no per-frame allocations

## Constitution Check

- **I. Single Responsibility** ✅ — `EnemyProjectile` owns only straight-line travel and player-hit. Enemy.gd continues to own attack timing; no logic bleeds between scripts.
- **II. Data-Driven Content** ✅ — ranged threshold in `dungeon_config.json`; no magic numbers in GDScript.
- **III. Mobile-First** ✅ — at most a handful of EnemyProjectile nodes alive simultaneously; simple `global_position +=` movement; no shaders.
- **IV. Editor-Centric** ✅ — `EnemyProjectile.tscn` created in Godot Editor; collision layer/mask set in Inspector; `_hit_area` assigned via `@export`.
- **V. Simplicity & YAGNI** ✅ — no new EnemyData fields; reuses existing `ContactArea` for range detection and `_damage_timer`/`_in_contact` for timing.
- **VI. Early Return** ✅ — ranged guard in the contact tick uses `if not _is_ranged:` early-continue pattern.

## Decisions

**D1 — New `EnemyProjectile` scene (not reusing `Projectile.gd`)**: Player's `Projectile.gd` tracks a moving enemy target each frame, collides with enemies only, and calls `RelicManager` for burn/chain effects. Enemy projectiles need the inverse: fixed direction, player-only collision, no relic hooks. A new script is the cleanest separation.

**D2 — Threshold in `dungeon_config.json → enemy_spawn`**: `enemy_ranged_threshold: 40` sits alongside the existing `spawn_delay` field in the `enemy_spawn` block. `Enemy.gd` reads this block already (line 79–80); adding one more `get` there keeps the read in one place.

**D3 — `_is_ranged: bool` computed in `Enemy.initialize()`**: The flag is set once when the enemy is configured — `_data.attack_range > threshold`. No new field on `EnemyData`; threshold is read from `dungeon_config` at init time and not stored. Guards the contact-damage branch in `_physics_process`.

**D4 — Reuse `_damage_timer` and `_in_contact` for projectile timing**: The existing contact-damage tick (Enemy.gd lines 210–215) already provides `damage_cooldown`-based timing and `_in_contact` range gating. For ranged enemies, the same tick fires a projectile instead of applying direct damage — no new timer variable needed.

## Schema Changes

`data/dungeon_config.json` — add `"enemy_ranged_threshold": 40` to the existing `"enemy_spawn"` object alongside `"spawn_delay"`. No other JSON changes.

## Affected Files

**`data/dungeon_config.json`** — Add `enemy_ranged_threshold: 40` inside the `enemy_spawn` block (currently line 6–8). One-line addition.

**`scenes/combat/enemies/EnemyProjectile.gd`** (new, co-located with `Enemy.gd`) — Script for the enemy's straight-line projectile. `setup(direction: Vector2, damage: float, speed: float)` locks the travel direction and damage at spawn time. `_physics_process` moves by `direction * speed * delta`, accumulates distance, and calls `queue_free()` when the projectile exits the room bounds (distance > max_range constant). `@export var _hit_area: Area2D` connected in `_ready()`; `_on_body_entered` checks for player group membership, applies damage via `StatsComponent.take_damage()`, then calls `queue_free()`. Passes through all other bodies.

**`scenes/combat/enemies/EnemyProjectile.tscn`** (new, Editor task) — Node2D root with `EnemyProjectile.gd` attached; child `Area2D` (`_hit_area`) with a small `CircleShape2D` collision; collision layer set to player-only (no enemy layer). A `ColorRect` or `Polygon2D` visual child. Created entirely in the Godot Editor.

**`scenes/combat/enemies/Enemy.gd`** — Three additions: (1) `var _is_ranged: bool = false` field (line ~34 alongside other state fields). (2) In `initialize()` (line ~99), after reading `enemy_spawn_cfg`, set `_is_ranged = _data.attack_range > float(enemy_spawn_cfg.get("enemy_ranged_threshold", 40.0))`. (3) In `_physics_process` contact-damage tick (lines 210–215): add a guard — if `_is_ranged`, call `_fire_projectile()` and reset `_damage_timer` instead of calling `take_damage`. Add private method `_fire_projectile()` that instantiates `EnemyProjectile.tscn`, calls `setup()` with direction to player and `_data.damage`, and adds it as a sibling of the enemy in the parent node.

**`tests/unit/test_enemy_ranged_attack.gd`** (new) — GUT unit tests covering the pure-logic parts: threshold comparison (at exactly 40, above 40, below 40), `EnemyProjectile` direction-lock (direction does not change after setup), distance-based despawn logic. Uses inline stub data; no autoloads.

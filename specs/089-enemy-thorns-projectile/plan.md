# Implementation Plan: Enemy Thorns Projectile

**Branch**: `089-enemy-thorns-projectile` | **Date**: 2026-03-31 | **Spec**: [spec.md](spec.md)

## Summary

Replace the `reflect_amount` damage-reflect mechanic on enemies with a projectile-based thorns burst. When a thorns-capable enemy is hit, it fires `EnemyProjectile` instances in fixed diagonal (4-way) or cardinal+diagonal (6-way) directions. Regular enemies use 4 directions; the forest boss fires 6 directions only while in `THORNS_ACTIVE`. All projectile parameters are read from `enemies.json`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6, static typing)
**Primary Dependencies**: Godot 4.6, Jolt physics, existing `EnemyProjectile.tscn`
**Storage**: `data/enemies.json` (JSON, read via ResourceManager)
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Android mobile portrait; Windows dev
**Performance Goals**: 60 fps on mid-range Android; thorn burst produces 4–6 short-lived projectiles per hit — negligible overhead

## Constitution Check

- **I. Single Responsibility** ✅ — Thorn-firing logic goes in `Enemy.gd`; `ForestBossThorns.gd` overrides only the state-gated variant. No new autoloads.
- **II. Data-Driven Content** ✅ — All thorn values (damage, speed, range, cooldown, direction count) live in `enemies.json`. No numeric constants in scripts.
- **III. Mobile-First** ✅ — Reuses `EnemyProjectile` (existing mobile-tested scene). 4–6 projectiles per burst, burst-only (not continuous). No new shaders or materials.
- **IV. Editor-Centric** ✅ — No `.tscn` raw edits. `EnemyProjectile.tscn` reused unchanged. `@export` pattern maintained throughout.
- **V. Simplicity & YAGNI** ✅ — Direction set encoded as a single integer (4 or 6); code maps to two constant arrays. Projectile scene reused as-is. No new base class or abstraction.
- **VI. Early Return** ✅ — `_try_fire_thorns()` exits immediately if `not _data.thorns_on_hit` or cooldown > 0.

No constitution violations.

## Decisions

**D1 — Direction encoding**: `thorns_directions: int` in data (4 or 6). In `Enemy._fire_thorns()`, value 4 maps to the four diagonal unit vectors (NE/NW/SE/SW) and value 6 adds N and S. Two constant arrays defined once in `Enemy.gd`; no other encoding needed.

**D2 — Boss thorn gating**: The forest boss has `thorns_on_hit: false` in its data entry, so the base `Enemy.take_damage()` guard never fires thorns for the boss. `ForestBossThorns` overrides `take_damage()` to call `_fire_thorns()` explicitly when `_boss_state == BossState.THORNS_ACTIVE` and the per-enemy fire-rate cooldown permits. This avoids adding boss-state logic to the base Enemy.

**D3 — Old reflect fields removed**: `thorns_reflect_amount_p2` and `thorns_reflect_amount_p3` are removed from `EnemyData.gd` and `enemies.json`. The `StatsComponent.reflect_amount` field and the reflect path in `StatsComponent.take_damage()` are kept unchanged — they remain in use for the player's Thorn Bark relic.

## Schema Changes

### `EnemyData.gd`

Remove fields: `thorns_reflect_amount_p2`, `thorns_reflect_amount_p3` (and their `from_dict()` mappings).

Add fields and defaults:

| Field | Type | Default | Purpose |
|---|---|---|---|
| `thorns_on_hit` | `bool` | `false` | Whether this enemy fires thorns when hit |
| `thorns_damage` | `float` | `0.0` | Damage per thorn projectile |
| `thorns_speed` | `float` | `400.0` | Projectile travel speed (px/s) |
| `thorns_range` | `float` | `600.0` | Max travel distance before despawn |
| `thorns_fire_cooldown` | `float` | `0.5` | Minimum seconds between thorn bursts |
| `thorns_directions` | `int` | `4` | Number of directions: 4 (diagonal) or 6 (+ cardinal N/S) |

### `enemies.json`

**Skeleton entry**: Set `reflect_amount` to `0.0` (or remove); add `"thorns_on_hit": true, "thorns_directions": 4, "thorns_damage": 5, "thorns_speed": 400, "thorns_range": 600, "thorns_fire_cooldown": 0.5`.

**forest_boss_thorns entry**: Remove `thorns_reflect_amount_p2` and `thorns_reflect_amount_p3`; add `"thorns_on_hit": false, "thorns_directions": 6, "thorns_damage": 8, "thorns_speed": 500, "thorns_range": 800, "thorns_fire_cooldown": 0.3`.

All other enemy entries: no change (they lack `thorns_on_hit` → defaults to `false`).

## Affected Files

### Source

**`data/enemies.json`** — Add the six new thorn projectile fields to the skeleton entry (`thorns_on_hit: true`, `thorns_directions: 4`, plus damage/speed/range/cooldown values). Add the same fields to the `forest_boss_thorns` entry with `thorns_on_hit: false` and `thorns_directions: 6`. Remove `thorns_reflect_amount_p2` and `thorns_reflect_amount_p3` from the boss entry. Set skeleton's `reflect_amount` to `0.0`.

**`scripts/data_models/EnemyData.gd`** — Remove the `thorns_reflect_amount_p2` and `thorns_reflect_amount_p3` field declarations and their `from_dict()` read lines. Add the six new field declarations with the defaults above, and their corresponding `from_dict()` read lines using `.get()` with the defaults.

**`scenes/combat/enemies/Enemy.gd`** — Add `_thorns_fire_cooldown_remaining: float = 0.0` as a class-level var. Add two class-level constant arrays for the 4-direction and 6-direction unit vector sets. Add `_try_fire_thorns()`: early-returns if `not _data.thorns_on_hit` or `_thorns_fire_cooldown_remaining > 0`; otherwise calls `_fire_thorns()` and sets `_thorns_fire_cooldown_remaining = _data.thorns_fire_cooldown`. Add `_fire_thorns()`: selects the correct direction array based on `_data.thorns_directions`, instantiates one `EnemyProjectile` per direction via `EnemyProjectile.setup(dir, _data.thorns_damage, _data.thorns_speed, _data.thorns_range)`, and adds each to the parent. Call `_try_fire_thorns()` at the end of `take_damage()` (after shield and HP damage resolution). Tick `_thorns_fire_cooldown_remaining` down in `_physics_process()` (guard: `if _thorns_fire_cooldown_remaining > 0.0: _thorns_fire_cooldown_remaining -= delta`). Note: `_fire_projectile()` already uses `load()` for the EnemyProjectile scene; adopt the same pattern or cache it.

**`scenes/combat/enemies/ForestBossThorns.gd`** — Remove all three `_stats.reflect_amount` assignments: in `_on_shield_broken()`, in `_on_died()`, and in `_exit_thorns_active()`. Remove the `_stats.reflect_amount = reflect` assignment inside the `BossState.THORNS_ACTIVE` match arm. Override `take_damage(amount, attacker)`: call `super.take_damage(amount, attacker)` first (handles shield and HP), then if `_boss_state == BossState.THORNS_ACTIVE` and `_thorns_fire_cooldown_remaining <= 0`, call `_fire_thorns()` (inherited from Enemy) and set `_thorns_fire_cooldown_remaining = _data.thorns_fire_cooldown`. Add `_thorns_fire_cooldown_remaining -= delta` near the top of `_physics_process()` (before the DEAD guard, so it always ticks; guard it with `if _thorns_fire_cooldown_remaining > 0.0`).

### Tests

**`tests/unit/test_forest_boss_thorns_active.gd`** — Replace the test fixture dict: remove `thorns_reflect_amount_p2/p3`, add the six new thorn projectile fields. Replace the four reflect-amount tests (`test_p2_reflect_is_point_three`, `test_p3_reflect_is_point_five`, `test_p3_reflect_higher_than_p2`, `test_reflect_amounts_between_zero_and_one`) and the `test_reflect_zero_after_exit` test with equivalents for the new fields: verify `thorns_on_hit` is false for the boss, `thorns_directions` is 6, `thorns_damage > 0`, `thorns_speed > 0`, `thorns_fire_cooldown > 0`. Keep the phase-gating logic tests unchanged (they test phase >= 2 integer logic, which is unaffected).

**`tests/unit/test_forest_boss_enemy_data.gd`** — Update the `_BOSS_FULL` fixture dict: remove `thorns_reflect_amount_p2/p3`, add the new fields. Replace tests `test_from_dict_reads_thorns_reflect_p2`, `test_from_dict_reads_thorns_reflect_p3`, `test_p3_reflect_higher_than_p2`, `test_thorns_reflect_p2_defaults_to_zero`, `test_thorns_reflect_p3_defaults_to_zero` with tests for the new fields: read `thorns_on_hit`, `thorns_directions`, `thorns_damage`, `thorns_speed`, `thorns_range`, `thorns_fire_cooldown` from `_BOSS_FULL`; verify defaults from a minimal dict.

**`tests/unit/test_forest_boss_charge.gd`** — Update the inline boss data dict: remove `thorns_reflect_amount_p2/p3`, add the six new thorn fields with their default values. No test assertion changes needed (charge tests do not exercise thorns logic).

**`tests/unit/test_forest_boss_phases.gd`** — Same fixture-only update as above: remove old reflect fields, add new thorn fields.

**`tests/unit/test_forest_boss_shield.gd`** — Same fixture-only update.

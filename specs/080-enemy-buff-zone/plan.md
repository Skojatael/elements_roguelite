# Implementation Plan: Enemy Buff Zone

**Branch**: `080-enemy-buff-zone` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/080-enemy-buff-zone/spec.md`

## Summary

Any enemy with `buff_zone_radius > 0` and `buff_cooldown > 0` in `enemies.json` periodically spawns a temporary circular zone centered on the enemy closest to the player at cast time. The zone detects overlapping enemies via an `Area2D`, applies regen and/or attack speed bonuses (whichever fields are non-zero on the caster), and removes those bonuses on exit or expiry. The player is excluded by type check. `forest_buffer` is the first enemy to use this mechanic.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot Area2D overlap callbacks, StatsComponent.heal(), existing EnemyData pattern
**Storage**: `data/enemies.json` (per-enemy fields)
**Testing**: GUT unit tests
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps on mid-range Android; buff zones are rare (elite enemy type), so ≤2 active zones per room is the expected maximum
**Constraints**: Mobile renderer (no Forward+ shaders); Jolt physics

## Constitution Check

- **I. Single Responsibility** ✅ — `EnemyBuffZone` is a new self-contained scene/script that owns only zone lifetime and buffing. `Enemy.gd` receives minimal additions (a timer and two public methods). No existing script absorbs zone logic.
- **II. Data-Driven Content** ✅ — All five new fields (`buff_zone_radius`, `buff_cooldown`, `buff_regen_rate`, `buff_attack_speed_bonus`, `buff_zone_duration`) live in `enemies.json`. No numeric constants in `.gd` files.
- **III. Mobile-First** ✅ — Area2D overlap detection is inexpensive; elite enemies appear at most once per room, so zone count is bounded at 1–2 at any time. No Forward+ effects; circle visual uses a `ColorRect` or shader compatible with the Mobile renderer.
- **IV. Editor-Centric** ✅ — `EnemyBuffZone.tscn` is created in the Godot Editor; all node references use `@export var`.
- **V. Simplicity & YAGNI** ✅ — No "BuffableEnemy" base class; two methods added directly to `Enemy`. No speculative hooks.
- **VI. Early Return** ✅ — All new methods guard on zero values and invalid state with early returns; loop bodies use `continue`.

## Decisions

**1. Zone spawning location** — The zone is spawned centered on the enemy sibling closest to the player at cast time, not at the caster's own position. The caster scans `get_parent().get_children()` (the same technique used by the healer follow scan) to find the nearest `Enemy` to `_player_ref`. If no player reference is active or no siblings exist, the caster falls back to its own position. The zone node is added as a sibling in the same parent container.

**2. Buff accumulation on Enemy** — `Enemy` tracks two float accumulators: `_zone_regen_rate` and `_zone_attack_speed_bonus`. Zones call public `apply_zone_buff(regen, speed)` on enter and `remove_zone_buff(regen, speed)` on exit/expiry. Additive stacking across overlapping zones is automatic via accumulation.

**3. Attack speed implementation** — Enemies attack via a `_damage_timer` that resets to `_data.damage_cooldown`. With an attack speed bonus, the effective interval becomes `_data.damage_cooldown / (1.0 + _zone_attack_speed_bonus)`. No new field on StatsComponent is needed.

**4. Zone duration** — Stored as `buff_zone_duration` per enemy in `enemies.json` (consistent with all other per-enemy tuning values; satisfies Constitution II). Defaults to `5.0` when absent.

## Schema Changes

**`data/enemies.json` — `forest_buffer` entry additions:**

| Field | Type | Default | Purpose |
|---|---|---|---|
| `buff_cooldown` | float | — (required for buffers) | Seconds between zone casts |
| `buff_zone_radius` | float | 0.0 | Zone radius in world units (already present) |
| `buff_zone_duration` | float | 5.0 | How long the zone persists |
| `buff_regen_rate` | float | 0.0 | HP regen as fraction of max HP per second |
| `buff_attack_speed_bonus` | float | 0.0 | Additive attack speed multiplier bonus |

**`scripts/data_models/EnemyData.gd` — new optional fields (all default to 0.0):**

`buff_zone_radius`, `buff_cooldown`, `buff_zone_duration`, `buff_regen_rate`, `buff_attack_speed_bonus` — all parsed via `data.get(field, 0.0)` in `from_dict`, consistent with existing optional fields.

## Affected Files

### New files

**`scenes/combat/enemies/EnemyBuffZone.gd`** (new script, co-located with Enemy.tscn per convention) — Owns the full lifecycle of one buff zone instance. Stores the buff values copied from the caster at spawn time (`regen_rate`, `attack_speed_bonus`, `radius`, `duration`). Positioned by the caster at spawn time (at the closest-to-player enemy's world position). In `_ready()`, sizes the `Area2D` collision shape and the visual to `radius`, and connects `body_entered`/`body_exited` to apply/remove buffs on overlapping enemies. Maintains a list of currently buffed enemies. Counts down duration in `_process`; on expiry, removes buffs from all tracked enemies and calls `queue_free()`.

**`scenes/combat/enemies/EnemyBuffZone.tscn`** *(editor task)* — Area2D root node with a `CollisionShape2D` (CircleShape2D) child and a `ColorRect` visual child. Script `EnemyBuffZone.gd` attached to root. Export vars: `_collision_shape: CollisionShape2D`, `_visual: ColorRect`. Created and wired in the Godot Editor.

### Modified files

**`data/enemies.json`** — No changes required; all buff fields are already present on `forest_buffer`.

**`scripts/data_models/EnemyData.gd`** — Add five optional float fields with 0.0 defaults and their corresponding `from_dict` parse lines, following the existing pattern for `root_duration`, `poison_modifier`, etc.

**`scenes/combat/enemies/Enemy.gd`** — Four additions:
1. Two accumulator fields: `_zone_regen_rate: float = 0.0` and `_zone_attack_speed_bonus: float = 0.0`.
2. One cooldown field: `_buff_cooldown_remaining: float = 0.0`, initialized in `initialize()` from `data.buff_cooldown`.
3. Two public methods: `apply_zone_buff(regen: float, speed: float)` and `remove_zone_buff(regen: float, speed: float)` that add/subtract from the accumulators.
4. In `_physics_process()`: a buff cast block (guarded by `_data.buff_cooldown > 0.0`) that ticks `_buff_cooldown_remaining` and, when it reaches zero, scans siblings to find the `Enemy` closest to `_player_ref` (falling back to self if no player ref or no siblings), then spawns `EnemyBuffZone` at that position; the existing regen tick now sums `_data.regen_rate + _zone_regen_rate`; the `_damage_timer` reset uses `_data.damage_cooldown / (1.0 + _zone_attack_speed_bonus)` when bonus is non-zero.

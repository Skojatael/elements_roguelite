# Implementation Plan: Enemy Charge Attack

**Branch**: `084-enemy-charge-attack` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)

## Summary

Extend `Enemy.gd` with a data-driven charge attack mechanic: enemy freezes on cooldown expiry, displays a telegraph rectangle in the player's direction, then lunges at 3× speed for `charge_attack_length` pixels, dealing `charge_attack_damage` on contact. Three new fields added to `EnemyData` and `enemies.json`; `forest_boss_thorns` is the first consumer.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot CharacterBody2D, existing `EnemyData`, `StatsComponent`
**Storage**: `data/enemies.json` (JSON, flat field additions)
**Testing**: GUT unit tests in `tests/unit/`
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Performance Goals**: 60 fps on mid-range Android; telegraph is a single `ColorRect` — negligible draw cost
**Constraints**: Mobile renderer; Jolt physics; no Forward+ shaders
**Scale/Scope**: One mechanic on one enemy type; mechanic opt-in via data (absent fields = no charge)

## Constitution Check

- **I. Single Responsibility** ✅ — All charge logic stays in `Enemy.gd` alongside existing AI behavior; no new autoloads or cross-scene coupling.
- **II. Data-Driven Content** ✅ — All three charge parameters live in `enemies.json`; no numeric constants in scripts.
- **III. Mobile-First** ✅ — A single semi-transparent `ColorRect` node per charge; no shaders, no atlas changes.
- **IV. Editor-Centric** ✅ — Telegraph node created programmatically (no new `.tscn`); no raw `.tscn` edits.
- **V. Simplicity & YAGNI** ✅ — State machine extended in place; no new base class introduced (only one consumer so far).
- **VI. Early Return** ✅ — New physics branches will use guard clauses; state blocks exit early when preconditions fail.

No constitution violations. Constitution deep-read skipped.

## Decisions

1. **Telegraph node parenting**: The telegraph `Node2D` + `ColorRect` is added to the enemy's parent (the room), not to the enemy itself. This keeps the rectangle static on screen while the enemy moves through it during the charge phase.

2. **Contact damage delivery during charge**: One-shot deal in `_physics_process` during the `CHARGING` state — if `_in_contact` is true and a `_charge_hit_delivered` guard flag is false, deal `_data.charge_attack_damage` via `_player_stats.take_damage(...)`. This reuses the existing contact detection signals without a new Area2D, and the flag prevents multiple hits per charge.

3. **Charge cancellation on player lost**: If `_on_lost` fires while in `TELEGRAPHING` or `CHARGING` state, free the telegraph visual, reset all charge state, and transition directly to `IDLE`. The cooldown does not reset — it will restart on next detection.

## Schema Changes

**`data/enemies.json` — `forest_boss_thorns` entry**: Add three new optional keys: `"charge_attack_damage": 10`, `"charge_attack_cooldown": 10`, `"charge_attack_length": 10`. All other enemy entries are unaffected (fields are optional).

**`scripts/data_models/EnemyData.gd`**: Add three `float` fields with 0.0 defaults: `charge_attack_damage`, `charge_attack_cooldown`, `charge_attack_length`. Parse them in `from_dict` via `data.get(...)` with 0.0 fallback (absence = no charge attack). No existing fields removed.

**`scenes/combat/enemies/Enemy.gd` — `EnemyState` enum**: Extend with two new values: `TELEGRAPHING` and `CHARGING`. State transition diagram: `IDLE → PURSUING` (on detect, charge cooldown starts) → `TELEGRAPHING` (cooldown hits 0, player valid) → `CHARGING` (2 s elapsed) → `PURSUING` (distance traveled). Player-lost short-circuits to `IDLE` from any state.

## Affected Files

### `data/enemies.json`
Add `charge_attack_damage`, `charge_attack_cooldown`, and `charge_attack_length` (each value `10`) to the `forest_boss_thorns` object inside the `"forest_boss"` category array. No other entries change.
Insertion point: inside the `forest_boss_thorns` object, after the existing `"size": 10.0` field.

### `scripts/data_models/EnemyData.gd`
Add three `var` declarations (`charge_attack_damage: float`, `charge_attack_cooldown: float`, `charge_attack_length: float`, all defaulting to `0.0`) after the existing `var size: float` on line 30. In `from_dict`, add three `d.<field> = float(data.get("<key>", 0.0))` assignments after the `size` parse on line 73.

### `scenes/combat/enemies/Enemy.gd`
Five localized changes:

1. **Enum** (line 40): Append `TELEGRAPHING` and `CHARGING` to `EnemyState`.

2. **New fields** (after `_state` declaration, ~line 42): Add `_charge_cooldown_remaining: float = 0.0`, `_telegraph_timer: float = 0.0`, `_charge_direction: Vector2 = Vector2.ZERO`, `_charge_distance_remaining: float = 0.0`, `_telegraph_node: Node2D = null`, `_charge_hit_delivered: bool = false`.

3. **`_on_detected` callback** (~line 386): After setting `_state = EnemyState.PURSUING`, if `_data.charge_attack_cooldown > 0.0`, set `_charge_cooldown_remaining = _data.charge_attack_cooldown`.

4. **`_on_lost` callback** (~line 391): Before nulling `_player_ref`, if state is `TELEGRAPHING` or `CHARGING`, call a new `_cancel_charge()` helper that frees `_telegraph_node`, resets all charge fields, and sets state to `IDLE`.

5. **`_physics_process`** (line 199): Insert charge-specific branches after the spawn-delay and root guards (so they short-circuit early if rooted):
   - **Cooldown tick (in PURSUING block)**: After the existing `_state == PURSUING` guard near line 270, if `_data.charge_attack_cooldown > 0.0` and `_player_ref` is valid, tick `_charge_cooldown_remaining`. When it reaches ≤ 0.0, call `_start_charge_telegraph()`.
   - **TELEGRAPHING branch**: Guard `if _state != TELEGRAPHING: …`, freeze velocity to `Vector2.ZERO`, tick `_telegraph_timer`. When ≥ 2.0 s, call `_begin_charge()`.
   - **CHARGING branch**: Guard `if _state != CHARGING: …`, move at `_charge_direction * _data.move_speed * 3.0`, subtract `velocity.length() * delta` from `_charge_distance_remaining`. Deliver one-shot charge damage when `_in_contact` and `not _charge_hit_delivered`. When `_charge_distance_remaining ≤ 0.0`, free `_telegraph_node`, reset charge fields, set state to `PURSUING`, reset `_charge_cooldown_remaining = _data.charge_attack_cooldown`.

   Three new private helpers:
   - `_start_charge_telegraph()`: locks `_charge_direction` to normalised vector toward `_player_ref`, creates the telegraph `Node2D` + `ColorRect` in enemy's parent, sets node position to `global_position`, sets rotation to `_charge_direction.angle()`, sizes the `ColorRect` to `Vector2(_data.charge_attack_length, px_size)` offset by `Vector2(0, -px_size * 0.5)` so it extends forward from the enemy's center. Sets `_telegraph_timer = 0.0`, `_state = TELEGRAPHING`.
   - `_begin_charge()`: frees nothing yet (telegraph stays visible during charge), sets `_charge_distance_remaining = _data.charge_attack_length`, `_charge_hit_delivered = false`, `_state = CHARGING`.
   - `_cancel_charge()`: frees `_telegraph_node` if valid, resets direction/timer/distance fields, `_charge_hit_delivered = false`, `_state = IDLE`.

### `tests/unit/test_enemy_charge_attack.gd` *(new file)*
GUT unit test covering: (a) `EnemyData.from_dict` correctly reads all three charge fields; (b) missing charge fields default to 0.0; (c) `forest_boss_thorns` JSON entry contains non-zero charge values; (d) state transitions PURSUING → TELEGRAPHING → CHARGING → PURSUING fire in the right sequence given mocked timers. Follow the pattern of one existing test file (e.g., `test_enemy_buff_zone.gd`).

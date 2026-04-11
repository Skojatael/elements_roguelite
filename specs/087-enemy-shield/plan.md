# Implementation Plan: Enemy Shield Mechanic

**Branch**: `087-enemy-shield` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/087-enemy-shield/spec.md`

## Summary

Add a shield HP layer to enemies that absorbs incoming damage before regular HP, with a stun on shield break. The first shield-capable enemy is `forest_boss_thorns`. The activation trigger will be implemented in a separate feature; this plan exposes the API only. All logic lives in `Enemy.gd` with data driven by two new fields in `EnemyData` and `enemies.json`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6, static typing)
**Primary Dependencies**: Godot engine; no new addons
**Storage**: `data/enemies.json` (new fields); no save-state impact
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Android mobile (portrait 1080×1920)
**Performance Goals**: 60 fps; zero per-frame allocations during shield/stun processing
**Constraints**: Mobile renderer; no new autoloads; no new scenes required

## Constitution Check

- **I. Single Responsibility** ✅ — Shield logic stays in `Enemy.gd` (enemy runtime concern); data definition stays in `EnemyData.gd`; no new autoloads.
- **II. Data-Driven Content** ✅ — `shield_hp` and `shield_stun_duration` in `enemies.json`; default fallback (0 / 3.0) in `EnemyData.from_dict`.
- **III. Mobile-First** ✅ — Shield visual is one programmatically created ColorRect; stun adds a single float countdown; no per-frame allocations.
- **IV. Editor-Centric** ✅ — Shield visual created in code (no new Inspector wiring needed); no `.tscn` raw edits.
- **V. Simplicity & YAGNI** ✅ — No trigger logic included (deferred to next feature); shield is a runtime value, not a new component.
- **VI. Early Return** ✅ — Stun guard will be an early-return block in `_physics_process`; shield interception in `take_damage` uses guard clauses.

No constitution violations.

## Decisions

**1. Where to intercept damage for shield?**
Enemy.gd's `take_damage()` method (line 146) is already a thin wrapper over `_stats.take_damage()`. Shield interception belongs here — before delegating to StatsComponent — because the shield is enemy-specific runtime state and StatsComponent is shared with the player. This avoids polluting StatsComponent with a mechanic that only applies to enemies.

**2. How to represent the STUNNED state?**
Enemy.gd already has an `EnemyState` enum (`IDLE`, `PURSUING`, `TELEGRAPHING`, `CHARGING`). Adding `STUNNED` to this enum is the natural fit. The stun guard goes at the top of `_physics_process`, right after the root guard, causing a full early return (suppressing all AI, movement, ranged fire, and contact damage).

**3. Shield visual placement?**
Other temporary visuals (charge telegraph) are already created programmatically as `ColorRect` nodes in `Enemy.gd`. The shield overlay follows the same pattern: a `ColorRect` added as a child of the enemy in `initialize()` (hidden by default), shown/hidden as shield activates/depletes. This avoids an Editor task for a placeholder visual.

**4. Overflow damage handling?**
A single hit that depletes the remaining shield HP must carry overflow to regular HP in the same call. `take_damage()` computes `overflow = amount - _current_shield_hp` before zeroing the shield, then calls `_stats.take_damage(overflow)` with that remainder. This keeps the two deduction steps in one method call with no observable gap.

## Schema Changes

Two optional fields added to `enemies.json` per enemy entry and `EnemyData.gd`:

| Field | Type | Default | Meaning |
|---|---|---|---|
| `shield_hp` | `int` | `0` | Maximum shield HP; `0` = no shield capability |
| `shield_stun_duration` | `float` | `3.0` | Seconds the enemy is stunned when shield breaks |

`forest_boss_thorns` will receive `"shield_hp": 200` and `"shield_stun_duration": 3.0`.

These are parsed in `EnemyData.from_dict` with `.get()` fallbacks — no breaking change for existing enemies.

## Affected Files

### `data/enemies.json` (modified)
Add `"shield_hp": 200` and `"shield_stun_duration": 3.0` to the `forest_boss_thorns` entry (lines ~114–118). All other enemies require no change; missing fields default to zero/3.0.

### `scripts/data_models/EnemyData.gd` (modified)
Add two new fields: `var shield_hp: int = 0` and `var shield_stun_duration: float = 3.0`. Add the corresponding `.get()` parse lines in `from_dict` after the existing `charge_speed_mult` parse (line 83). Insertion point: after line 83, before the `return d` statement.

### `scenes/combat/enemies/Enemy.gd` (modified — primary changes)

**EnemyState enum** (line 40): add `STUNNED` to the existing enum.

**New fields** (after existing state vars, ~line 51): add `_current_shield_hp: int = 0`, `_stun_remaining: float = 0.0`, `_shield_visual: ColorRect = null`.

**`initialize()` method** (after the existing visual setup, ~line 103): create a `ColorRect` child programmatically to serve as the shield overlay. It is sized and colored (semi-transparent blue) slightly larger than the enemy body, positioned centered, and hidden by default. Store reference in `_shield_visual`. This runs unconditionally so the node is always present; visibility is toggled separately.

**`take_damage()` method** (line 146): add shield interception logic before delegating to `_stats.take_damage()`. Guard: if `_current_shield_hp <= 0`, skip to normal damage path. Otherwise subtract incoming `amount` from `_current_shield_hp`: if `amount < _current_shield_hp`, deduct and return (no HP damage). If `amount >= _current_shield_hp`, compute overflow, zero `_current_shield_hp`, call `_on_shield_broken()`, and if overflow > 0 continue to `_stats.take_damage(overflow)`.

**New `_on_shield_broken()` private method**: hide `_shield_visual`, set `_stun_remaining = _data.shield_stun_duration`, set `_state = EnemyState.STUNNED`.

**New `activate_shield()` public method**: sets `_current_shield_hp = _data.shield_hp`, shows `_shield_visual`. Guard: if `_data.shield_hp <= 0`, returns immediately (no-op for non-shield enemies).

**`_physics_process()` method** (~line 187): add a stun guard block immediately after the existing root guard (lines 192–195). If `_state == EnemyState.STUNNED`: decrement `_stun_remaining` by delta, if it reaches zero set `_state = EnemyState.IDLE`, zero velocity, call `move_and_slide()`, and return early. This suppresses all AI behaviour (movement, ranged fire, contact damage, regen, buffs, heals) during the stun.

### `tests/unit/test_enemy_shield.gd` (new)
GUT unit test covering: shield absorption (damage depletes shield before HP), overflow carry-over, stun duration, stun expiry, heal-does-not-restore-shield, and no-op activation for enemies with `shield_hp = 0`. Follow the existing test pattern from `tests/unit/test_enemy_attack_standoff.gd` (one existing test file read is sufficient).

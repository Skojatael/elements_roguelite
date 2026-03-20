# Implementation Plan: Root Mechanic

**Branch**: `072-root-mechanic` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)

## Summary

Two-direction root mechanic. Enemy direction (already implemented): enemies with `root_duration > 0` in JSON apply a timed movement-lock to the player on melee contact; `RootComponent` (player child node) owns the timer; `MovementComponent` and `DodgeComponent` guard against it. Relic direction (new work): a new uncommon Root Relic gives the player's melee hits a data-driven probability to root the struck enemy; enemies gain their own `RootComponent` child node and an `apply_root()` method; `CombatComponent` rolls the chance after each hit and calls the method if the relic is active.

## Technical Context

**Language/Version**: GDScript 4.6, static typing
**Primary Dependencies**: Godot 4.6 engine, Jolt physics
**Storage**: `data/relics.json` (new relic entry), `scripts/data_models/RelicData.gd` (two new fields)
**Testing**: GUT unit tests
**Target Platform**: Android mobile (portrait); Windows dev
**Performance Goals**: 60 fps mobile — root is a single float countdown per frame; one `randf()` call per melee swing when relic is held
**Constraints**: No new autoloads; no new `.tscn` files; `RootComponent` already exists and must be reused on enemies to satisfy FR-013

## Constitution Check

- **I. Single Responsibility**: `RelicManagerImpl` gains two new pure-query methods (`has_root_relic`, `get_root_on_hit_duration`) — relic logic stays in the relic layer. Enemy root state is owned by a `RootComponent` child (same class reused) — Enemy is not the owner. `CombatComponent` merely queries and delegates. ✓
- **II. Data-Driven Content**: `root_chance` and `root_duration` live in `data/relics.json`. Two new fields added to `RelicData` model for type-safe access. No balance constants in code. ✓
- **III. Mobile-First**: One `randf()` call per melee interval when relic is held; one float decrement per rooted enemy per frame. Negligible. ✓
- **IV. Editor-Centric**: No `.tscn` edits. Enemy's `RootComponent` is added via `add_child()` in `_ready()` — consistent with how `BurnEffect` is instantiated dynamically. ✓
- **V. Simplicity & YAGNI**: `RootComponent` reused on enemies — no duplicate timer logic (FR-013). Two concrete call sites (player and enemy) already exist so the abstraction is earned. ✓
- **VI. Early Return**: All new guards use early-return / early-exit pattern. Enemy physics guard exits before movement assignment. ✓

## Decisions

**1. Enemy RootComponent added via `add_child()` in `_ready()`, not wired in the scene**

Enemies are instantiated dynamically by `RoomSpawner` — they have no static scene composition point for an Inspector-assigned export. Dynamic `add_child()` in `_ready()` matches the existing `BurnEffect` pattern (`_burn = BurnEffect.new()` — note: `BurnEffect` is a `RefCounted` not a `Node`, but the principle is the same). `RootComponent` is a `Node` that uses `_physics_process`, so it must be added as a child rather than held as a plain reference.

**2. `RelicManagerImpl.get_root_on_hit_duration()` encapsulates both check and roll**

`CombatComponent` calls one method that internally checks whether the root relic is held, rolls `randf()`, and returns the duration (or `0.0` on miss/no relic). This mirrors the existing `on_melee_hit()` pattern for the `melee_missile_charge` relic — a single call with a single boolean/float return, keeping `CombatComponent` unaware of specific relic IDs.

**3. Root relic uses new `root_chance` and `root_duration` fields on `RelicData`**

Rather than reusing `condition_threshold` (chance) and `condition_mult` (duration) with stretched semantics, two explicit named fields are added to `RelicData`. This satisfies FR-010 (data-driven, named params) and keeps the data model readable. The field cost is two floats that default to `0.0` — all existing relics are unaffected.

## Schema Changes

### `data/relics.json` — new entry in `"uncommon"`

New entry `"root_relic"`: `name`, `tags: ["melee"]`, `effect_stat: ""`, `effect_mult: 1.0`, `condition_type: "root_on_melee_hit"`, `root_chance: 0.20`, `root_duration: 0.6`, `description`, `deck_count: 1`.

### `scripts/data_models/RelicData.gd` — two new fields

`root_chance: float = 0.0` and `root_duration: float = 0.0` — both parsed in `from_dict()` via `.get()` with `0.0` defaults. Backward-compatible with all existing relic entries.

## Affected Files

### Modified

**`data/relics.json`**
Add `"root_relic"` entry inside the `"uncommon"` dictionary. Fields: `name: "Rootweave Band"`, `tags: ["melee"]`, `effect_stat: ""`, `effect_mult: 1.0`, `condition_type: "root_on_melee_hit"`, `root_chance: 0.20`, `root_duration: 0.6`, `description: "Melee hits have a 20% chance to root enemies for 0.6s."`, `deck_count: 1`.

**`scripts/data_models/RelicData.gd`**
Add `var root_chance: float = 0.0` and `var root_duration: float = 0.0` class fields. Parse both in `from_dict()` with `data.get("root_chance", 0.0)` and `data.get("root_duration", 0.0)`.

**`scripts/managers/RelicManagerImpl.gd`**
Add `has_root_relic() -> bool` — pure check, returns `active_relic_ids.has("root_relic")`. Add `get_root_on_hit_duration() -> float` — if `has_root_relic()` is false returns `0.0`; otherwise reads the relic's `root_chance` and `root_duration` from `_relics_by_id`, rolls `randf()`, and returns `root_duration` on success or `0.0` on miss.

**`autoload/RelicManager.gd`**
Add `has_root_relic() -> bool` delegating to `_impl.has_root_relic()`. Add `get_root_on_hit_duration() -> float` delegating to `_impl.get_root_on_hit_duration()`.

**`scenes/combat/enemies/Enemy.gd`**
Add `var _root: RootComponent = null`. In `_ready()`, instantiate `_root = RootComponent.new()` and call `add_child(_root)`. Add public `apply_root(duration: float) -> void` that calls `_root.apply_root(duration)`. In `_physics_process`, after the spawn-delay guard, add an early-return guard: if `_root != null and _root.is_rooted`, set `velocity = Vector2.ZERO`, call `move_and_slide()`, and return — preventing pursuit movement while rooted (contact damage still applies if already in range).

**`scenes/player/components/CombatComponent.gd`**
After `target.take_damage(dmg)`, call `var root_dur: float = RelicManager.get_root_on_hit_duration()` and, if `root_dur > 0.0`, call `target.apply_root(root_dur)`. The `target` is already typed as `Enemy` at this point, so `apply_root` resolves cleanly.

### New

**`tests/unit/test_relic_manager_impl_root_relic.gd`**
GUT unit tests for `RelicManagerImpl.get_root_on_hit_duration()`. Covers: relic absent → always returns `0.0`; relic held with `root_chance = 1.0` → always returns `root_duration`; relic held with `root_chance = 0.0` → always returns `0.0`. Instantiates `RelicManagerImpl` directly, calls `build_pool()` with synthetic relic data, and calls `pick_relic("root_relic")` to activate.

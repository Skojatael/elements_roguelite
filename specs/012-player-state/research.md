# Research Notes: Player State Snapshot

**Feature**: 012-player-state
**Date**: 2026-02-27
**Status**: Complete — all questions resolved

---

## Decision 1: File Location and Base Class

**Decision**: `scripts/data_models/PlayerState.gd`, extending `RefCounted`.

**Rationale**:
- Identical pattern to `RunState` (011) and `SpawnContext` — runtime-only data snapshots use `RefCounted`.
- `scripts/data_models/` is the established home for typed data model classes.
- Not persisted to disk in this feature → `Resource` would be overkill.
- Satisfies constitution SRP rule: the file is shared by RunManager (writer) and all future consumers.

**Alternatives considered**:
- `extends Resource`: Unnecessary serialization overhead for a runtime-only snapshot. Rejected.
- Inline in RunManager or RunState: Violates FR-010 ("dedicated data file"). Rejected.

---

## Decision 2: current_hp Sync Mechanism

**Decision**: RunManager connects to `StatsComponent.health_changed(new_health, max_health)` signal and writes `player_state.current_hp = new_health` in a dedicated `_on_player_health_changed()` method. Connection is made in `start_run()` with an `is_connected()` guard to prevent duplicates on repeated start_run() calls.

**Rationale**:
- `StatsComponent.health_changed` already fires on every health change (`take_damage()`, `heal()`, `reset()`). No new signal needed.
- RunManager is the correct place to bridge the player's component signal to the run state snapshot — it already owns both RunState and PlayerState.
- `is_connected()` guard: `start_run()` may be called multiple times (re-runs). Without the guard, each call would add a duplicate connection.
- The method is `_on_player_health_changed(new_health: float, _max_health: float)` — underscore-prefix on `_max_health` since only `new_health` is used.

**Alternatives considered**:
- StatsComponent directly updates PlayerState: Creates a dependency from a player component to RunManager's internal data. SRP violation. Rejected.
- Polling `stats.current_health` in `_process()`: Unnecessary per-frame cost for a value that changes rarely. Rejected.

---

## Decision 3: Stub Field Types

**Decision**:
- `items: Array = []` — untyped Array (item type doesn't exist yet)
- `modifiers: Array = []` — untyped Array (modifier type doesn't exist yet)
- `skill_changes: Array = []` — untyped Array (skill change type doesn't exist yet)
- `skill_cooldowns: Dictionary = {}` — Dictionary (keyed by skill ID string → cooldown float); more natural than Array for keyed lookup

**Rationale**:
- Arrays for collections without a defined element type: simplest safe default, clearly empty, no type errors on read.
- Dictionary for `skill_cooldowns`: cooldowns are logically keyed by skill ID. When the real implementation arrives, consumers will want `skill_cooldowns["fireball"]` not `skill_cooldowns[0]`. Dictionary is the correct future-proof type.
- Untyped arrays are acceptable for stubs — typing is deferred to when the element types are defined.

**Alternatives considered**:
- All four as Dictionaries: Works, but Array is more natural for unsorted collections (items, modifiers, skill_changes). Rejected for those three.
- Typed arrays (`Array[ItemData]`): Can't type them until the element classes exist. Rejected.

---

## Decision 4: Reset Timing — run END, not run START

**Decision**: PlayerState resets in `end_run()`. A fresh `PlayerState.new()` is created, `current_hp` is set to the player's `max_health` (read from `StatsComponent`), and `run_state.player_state` is updated to point to the new instance.

**Rationale**:
- Spec FR-007 and FR-008 explicitly require reset at run end, not run start. This is intentionally different from RunState's reset-at-start behavior.
- Rationale from spec: "player HP is not needed for post-run summaries" — RunState retains final currency/cleared rooms for the summary screen; PlayerState does not need to retain final HP.
- Creating a new `PlayerState.new()` (rather than resetting fields on the existing instance) guarantees all fields return to defaults — no risk of a forgotten field.
- Setting `run_state.player_state = player_state` after the reset keeps the RunState reference current.

**Finding player max_health at reset**: `get_tree().get_nodes_in_group("player")` → `get_node_or_null("StatsComponent")` → read `stats.max_health`. Same lookup used in `start_run()` for `stats.reset()`.

**Alternatives considered**:
- Reset at next `start_run()`: Contradicts FR-008. Rejected.
- Reset only `current_hp`, keep stubs as-is: All stubs are already empty, so there is no behavioral difference. Using `PlayerState.new()` is cleaner. Rejected.

---

## Decision 5: RunManager Ownership Pattern

**Decision**: RunManager declares `var player_state: PlayerState = PlayerState.new()`. In `start_run()`, it creates a fresh instance, connects the signal, sets initial `current_hp`, and assigns `run_state.player_state = player_state`. In `end_run()`, it creates a reset instance and updates both `player_state` and `run_state.player_state`.

**Rationale**:
- RunManager keeping its own `var player_state` reference (separate from `run_state.player_state`) allows clean direct writes: `player_state.current_hp = x` without going through `run_state.player_state.current_hp = x`.
- Since `run_state.player_state` and `player_state` point to the same object after `start_run()`, updates via either reference are equivalent.
- At `end_run()`, both must be updated to the new reset instance to keep them in sync.

**Alternatives considered**:
- Write only through `run_state.player_state.current_hp`: Works but requires run_state to always be non-null and initialized. The direct variable is simpler. Rejected.
- No separate RunManager.player_state — just run_state.player_state: Would require `if run_state != null` guards everywhere. Rejected.

---

## Decision 6: RunState Extension

**Decision**: Add `var player_state: PlayerState` field to `scripts/data_models/RunState.gd`. Initialized to `PlayerState.new()` at declaration (safe default before any run). Set to RunManager's `player_state` instance in `start_run()`.

**Rationale**:
- FR-011 requires RunState to include a reference to PlayerState.
- Initializing at declaration ensures reads before any run return a safe `PlayerState.new()` with full HP default and empty stubs.
- This is an additive change — no existing RunState fields are modified.

---

## Integration Summary

| Component | Change |
|---|---|
| `scripts/data_models/PlayerState.gd` | **New file** — `current_hp` + 4 stub fields |
| `scripts/data_models/RunState.gd` | Add `var player_state: PlayerState = PlayerState.new()` |
| `autoload/RunManager.gd` | Add `var player_state`; populate/connect in `start_run()`; reset in `end_run()`; sync in `_on_player_health_changed()` |
| New signals | None — reuses existing `StatsComponent.health_changed` |
| New scenes/resources | None |

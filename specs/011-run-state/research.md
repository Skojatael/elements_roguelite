# Research Notes: Run State Snapshot

**Feature**: 011-run-state
**Date**: 2026-02-27
**Status**: Complete — all questions resolved

---

## Decision 1: File Location and Base Class

**Decision**: `scripts/data_models/RunState.gd`, extending `RefCounted`.

**Rationale**:
- `scripts/data_models/` is the established home for typed data model classes (`EnemyData`, `SpawnContext`, `RoomData`).
- `RefCounted` is the correct base for a runtime-only data snapshot: lightweight, GC-managed, no serialization overhead. `SpawnContext` uses the same pattern.
- `Resource` (used by `EnemyData`, `RoomData`) is for JSON-backed or Editor-authored content that may be saved to disk. RunState is never persisted in this feature — `Resource` would be overkill.
- Placing it in `scripts/data_models/` satisfies the constitution's SRP rule: the file is shared by RunManager (writer) and all future consumers (HUD, save system, analytics).

**Alternatives considered**:
- `scenes/run/RunState.gd`: Mixes data models with scene-coupled scripts. RunState has no scene dependency. Rejected.
- `extends Resource`: Adds serialization machinery not needed here. Rejected.
- Inline class inside RunManager: Violates FR-012 ("dedicated data file"). Rejected.

---

## Decision 2: RunManager Ownership Pattern

**Decision**: RunManager declares `var run_state: RunState = RunState.new()` (initialized to safe defaults before any run). `start_run()` replaces it with a fresh `RunState.new()` instance with the new run's values.

**Rationale**:
- Initializing at declaration (not just in `start_run()`) means reads before any run ever started return safe default values (empty string, empty dict, 0.0) — satisfying the "no crash before a run starts" edge case (spec edge case 1).
- Creating a new instance in `start_run()` guarantees a clean reset — no risk of a forgotten field carrying over from the previous run. This is cleaner than manually resetting each field on the existing instance.
- The old RunState instance is garbage-collected automatically when RunManager replaces `run_state` (RefCounted).
- Consumers always read via `RunManager.run_state.field_name` — they get the new instance immediately after `start_run()`.

**Alternatives considered**:
- Reset individual fields on the existing RunState instance in `start_run()`: Works but risks forgetting a field. Creating a new instance is safer. Rejected.
- RunState creates itself and registers with RunManager: Inverts ownership. RunManager is the sole owner per spec. Rejected.

---

## Decision 3: cleared_rooms — Shared Reference

**Decision**: `run_state.cleared_rooms` is assigned the same Dictionary reference as `RunManager.cleared_rooms` in `start_run()`. No copy is made.

**Rationale**:
- Spec assumption: "cleared_rooms in RunState mirrors the existing cleared_rooms Dictionary already maintained by RunManager — they refer to the same data, not separate copies."
- GDScript Dictionaries are reference types. Assigning `run_state.cleared_rooms = cleared_rooms` shares the reference — mutations via `mark_room_cleared()` are reflected automatically in RunState without any additional sync code.
- The fresh `{}` created by `cleared_rooms = {}` in `start_run()` is then shared with the new RunState — both start empty and grow together.

**Alternatives considered**:
- Copy the dict on every read: O(N) per read, defeats the purpose of a live snapshot. Rejected.
- Duplicate update in `mark_room_cleared()`: Adds a second write to maintain; fragile (easy to forget). Rejected.

---

## Decision 4: run_currency Sync Point

**Decision**: `run_state.run_currency` is explicitly re-assigned in `add_currency()` after `run_currency` is updated: `run_state.run_currency = run_currency`.

**Rationale**:
- GDScript floats are value types — sharing a reference is not possible. An explicit assignment is required wherever `run_currency` changes.
- `add_currency()` is the only write path for `run_currency` in RunManager. One assignment covers all cases.

**Alternatives considered**:
- Property setter (`set(value)`) on `RunManager.run_currency`: Would work but adds boilerplate to a field that could later have other accessors. The explicit assignment in `add_currency()` is simpler. Rejected.

---

## Decision 5: current_room_id Sync Point

**Decision**: `run_state.current_room_id` is set in `RunManager._on_room_entered()`: `run_state.current_room_id = room_id`. It is reset to `""` when the new RunState is created in `start_run()`.

**Rationale**:
- `_on_room_entered()` fires every time the player enters a room — the correct and only update point.
- RunManager.current_room is a Node reference (not a String), so there is no existing `current_room_id` String to mirror.
- During transitions (after room is freed, before next room is entered), `current_room_id` retains the last entered room's ID. This is acceptable — the spec states transitions are momentary and consumers should handle an empty value gracefully. The field is reset to `""` only at run start.

**Alternatives considered**:
- Set `current_room_id = ""` when `RunManager.current_room = null` is called in RoomLoader: Would require RunManager to expose a method or RoomLoader to call into RunState — cross-boundary coupling. Not worth it for a momentary transition. Rejected.

---

## Decision 6: run_mode Sync Point

**Decision**: `run_state.run_mode` is set once in `start_run()` and never updated again during the run.

**Rationale**:
- Spec FR-005: "Set at run start and does not change during the run." Single assignment in `start_run()` is correct and sufficient.

---

## Decision 7: Read-Only Enforcement

**Decision**: Enforced by convention and documentation only — a `## Read-only for consumers` doc comment on the RunState fields and a note in CLAUDE.md. No language-level enforcement.

**Rationale**:
- GDScript 4 does not support true read-only properties without a setter pattern that would add complexity for no runtime benefit.
- The spec states consumers observe; they do not write. This is a contract established by documentation, not the compiler.
- If write protection is needed in the future, a property-with-setter pattern (setter does nothing or pushes an error) can be added without changing the data model structure.

**Alternatives considered**:
- Setter methods that assert/push_error if called outside RunManager: Adds significant boilerplate. Overkill for a single-developer project. Rejected.

---

## Integration Summary

| Component | Change |
|---|---|
| `scripts/data_models/RunState.gd` | **New file** — 6 fields + doc comments |
| `autoload/RunManager.gd` | Add `var run_state: RunState`; populate in `start_run()`; sync in `_on_room_entered()` and `add_currency()` |
| New scenes/resources | None |
| New signals | None |

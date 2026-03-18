# Tasks: Door Lock During Combat

**Input**: Design documents from `specs/058-door-lock/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, quickstart.md ✅

**Tests**: Both modified files (`Door.gd`, `RoomSpawner.gd`) are Node-based with no extractable pure logic. GUT unit tests not applicable. Manual in-editor validation only.

**Organization**: Single user story. `Door.gd` change is a prerequisite for `RoomSpawner.gd` changes.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Blocking Prerequisite)

**Purpose**: `Door.gd` must expose a `locked` field before `RoomSpawner` can set it.

- [x] T001 In `scenes/dungeon/doors/Door.gd`, add `var locked: bool = false`. In `_on_body_entered`, add `if locked: return` as the first line of the function body, before the `is_in_group("player")` check.

**Checkpoint**: `Door` now respects its lock state. `RoomSpawner` wiring can begin.

---

## Phase 2: User Story 1 — Doors Lock During Combat (Priority: P1) 🎯 MVP

**Goal**: Combat room doors block room transitions while enemies are alive; unlock immediately on room clear.

**Independent Test**: Enter CombatRoom01 → attempt door while enemies alive → verify no transition → kill all 6 enemies → verify door transitions normally.

### Implementation for User Story 1

- [x] T002 [US1] In `scripts/dungeon/RoomSpawner.gd`, add two private helpers:
  - `func _lock_doors() -> void` — iterates `get_parent().get_children()`, sets `locked = true` on every node that `is Door`
  - `func _unlock_doors() -> void` — same iteration, sets `locked = false`

- [x] T003 [US1] In `scripts/dungeon/RoomSpawner.gd`, call `_lock_doors()` at the very start of `_spawn_wave()` when `wave_idx == 0` (first wave only — add guard `if wave_idx == 0: _lock_doors()`), and at the very start of `_spawn_enemies_legacy()` before any other logic.

- [x] T004 [US1] In `scripts/dungeon/RoomSpawner.gd`, call `_unlock_doors()` inside `_on_enemy_defeated()` in both the wave-path and legacy-path `room_cleared` branches, immediately before `room_cleared.emit(room_id)` in each.

**Checkpoint**: Doors lock on first spawn, stay locked across waves, unlock on room clear. Non-combat rooms unaffected.

---

## Phase 3: Polish & Validation

- [ ] T005 Run all five quickstart.md validation scenarios: door locked during combat, unlock on clear, StartRoom01 never locks, cleared room stays unlocked on re-entry, wave room locks for full sequence.

- [x] T006 Update `repo_map.md`: add `locked: bool` field to the `Door` entry; add `_lock_doors()` and `_unlock_doors()` to the `RoomSpawner` entry.

---

## Dependencies & Execution Order

- T001 has no dependencies — start immediately.
- T002 depends on T001 (Door.locked must exist before RoomSpawner can reference it).
- T003 depends on T002 (_lock_doors helper must exist before it can be called).
- T004 depends on T002 (_unlock_doors helper must exist before it can be called).
- T003 and T004 can be done in a single editing pass on RoomSpawner.gd.
- T005 depends on T001–T004.
- T006 can run alongside T005.

---

## Implementation Strategy

1. T001 — update Door.gd
2. T002 → T003 → T004 — update RoomSpawner.gd (single pass)
3. **STOP and VALIDATE** via T005
4. T006 — repo_map update

---

## Notes

- `_lock_doors()` is idempotent — calling it on wave_idx == 0 only keeps the intent explicit; subsequent wave calls don't re-lock unnecessarily.
- The `is Door` check uses the `Door` class_name registered in `Door.gd` — same pattern as boss room door suppression in `Main.gd`.
- `_lock_doors()` and `_unlock_doors()` are private helpers (`_` prefix) — no repo_map public method entry needed, but the Door field entry is required.
- Rooms with empty spawn configs never reach `_spawn_wave` or `_spawn_enemies_legacy` execution (early return in `_load_config` returns an empty `RoomSpawnConfig`) — doors in those rooms are never locked.

# Quickstart: Enemy Spawning

**Feature**: 003-enemy-spawning
**Date**: 2026-02-20
**Purpose**: Manual validation scenarios to verify each user story independently after implementation.

---

## Prerequisites

- Godot 4.6 editor open with `project.godot`.
- `Enemy.tscn` present at `res://scenes/combat/enemies/Enemy.tscn` with a `StatsComponent` child (from `002-enemy-combat`).
- `data/enemies.json` contains at least `"slime"` and `"skeleton"` entries.

---

## Scenario 1 — Room populates on entry (US1, P1)

**Goal**: Verify FR-001, SC-001.

**Setup**:
1. In `data/dungeon_config.json`, ensure `CombatRoom01` has exactly two spawn points, both with `enemy_id: "slime"`.
2. Open `Main.tscn` (or a test scene containing `CombatRoom01`). Confirm `RoomSpawner` node is a child of `CombatRoom01` with `room_id = "CombatRoom01"`.
3. Run the game.

**Steps**:
1. Move the player into `CombatRoom01`'s `EntryArea`.

**Expected**:
- Two Slime enemies appear within 0.5 seconds of entry (SC-001).
- Both enemies are visible and active (they pursue the player).

**Pass criterion**: Two enemies visible immediately after entry.

---

## Scenario 2 — Empty room enters without error (US1 edge case)

**Goal**: Verify FR-002.

**Setup**:
1. Configure a room (e.g. `CombatRoom02`) with zero spawn points in `dungeon_config.json` (or omit its entry entirely).
2. Run the game.

**Steps**:
1. Move the player into the empty room.

**Expected**:
- No enemies appear.
- No error appears in the Godot output panel.

---

## Scenario 3 — Data-driven enemy composition (US2, P2)

**Goal**: Verify FR-004, SC-002.

**Setup**:
1. Configure `CombatRoom01` with 2× slimes and `CombatRoom02` with 1× skeleton in `dungeon_config.json`.
2. Run the game.

**Steps**:
1. Enter `CombatRoom01`. Confirm 2 slimes appear.
2. Restart the game. In `dungeon_config.json` change `CombatRoom01`'s `enemy_id` from `"slime"` to `"skeleton"` (no code changes).
3. Run again. Enter `CombatRoom01`.

**Expected**:
- Step 1: 2 × Slime enemies.
- Step 3: 2 × Skeleton enemies — no code changes required (SC-002).

---

## Scenario 4 — Room cleared state and no re-spawn (US3, P3)

**Goal**: Verify FR-005, FR-006, FR-007, SC-003.

**Setup**:
1. `CombatRoom01` configured with 2 slimes.
2. Run the game.

**Steps**:
1. Enter `CombatRoom01` — 2 enemies spawn.
2. Defeat one enemy. Confirm the room is NOT yet cleared (second enemy still active).
3. Defeat the second enemy. Confirm room transitions to cleared state the same frame (SC-003 — verify via `RoomSpawner.room_cleared` signal or debug print).
4. Leave the room and re-enter.

**Expected**:
- Step 2: One enemy remains active; room not cleared.
- Step 3: Room cleared immediately.
- Step 4: No enemies spawn on re-entry (FR-007).

---

## Scenario 5 — Randomised spawn positions (US4, P4)

**Goal**: Verify FR-008, SC-004.

**Setup**:
1. Configure one spawn point in `CombatRoom01` with `radius: 50`.
2. Add a temporary `print(enemy.global_position)` in `RoomSpawner._spawn_enemies()` to log enemy start position.

**Steps**:
1. Run the game. Enter `CombatRoom01`. Note the printed position (Run A).
2. Restart. Enter `CombatRoom01` again. Note the printed position (Run B).

**Expected**:
- Positions differ by ≥ 1 unit on at least one axis (SC-004).
- Both positions are within 50 units of the configured centre.

**Radius-zero check**:
1. Set `radius: 0` in the config.
2. Run twice.
3. Both positions must be identical.

---

## Scenario 6 — Invalid enemy ID error (edge case, FR-003)

**Setup**:
1. Set one spawn point's `enemy_id` to `"does_not_exist"`.
2. Run the game.

**Expected**:
- A clear error appears in the Godot output: e.g. `"RoomSpawner: unknown enemy_id 'does_not_exist'"`.
- No enemy spawns; game does not crash.

---

## Scenario 7 — Exceeding 10 enemies (edge case, FR-009)

**Setup**:
1. Add 11 spawn points to a room in `dungeon_config.json`.
2. Run the game.

**Expected**:
- A clear error appears: `"RoomSpawner: spawn_points count exceeds maximum of 10"`.
- No enemies spawn for that room.

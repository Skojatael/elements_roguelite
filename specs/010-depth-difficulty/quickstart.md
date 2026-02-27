# Quickstart Validation: Dungeon Depth & Difficulty Scaling

**Feature**: 010-depth-difficulty
**Date**: 2026-02-27

All scenarios are manual tests performed in the Godot Editor with Remote Inspector or print output.

---

## Scenario 1 — Start Room Has Depth 0

1. Start a run.
2. In the Output panel, observe DungeonGenerator print:
   `[DungeonGenerator] layout rooms=8 start=room_2_2 ...`
3. In the Remote Inspector or via a debug print, confirm `rooms_by_id["room_2_2"]["depth"] == 0`.
4. Confirm `rooms_by_id["room_2_2"]["difficulty_mult"] == 1.0`.

**Pass**: depth=0, mult=1.0 for start room.

---

## Scenario 2 — All Rooms Have Correct Depth

1. Start a run.
2. Print all entries in `rooms_by_id`.
3. For each room, verify: `depth == abs(grid_pos.x - 2) + abs(grid_pos.y - 2)`.
4. Confirm no room has a negative depth.

**Pass**: Every room's depth equals its grid Manhattan distance from center.

---

## Scenario 3 — difficulty_mult Formula

1. Start a run.
2. For each room in `rooms_by_id`, verify: `difficulty_mult == 1.0 + 0.12 * depth`.
   Examples to check:
   - depth 0 → 1.00
   - depth 1 → 1.12
   - depth 2 → 1.24
   - depth 3 → 1.36
   - depth 4 → 1.48

**Pass**: All multipliers match formula exactly.

---

## Scenario 4 — Elite Room Count (1–2 Per Run)

1. Start 10 runs.
2. In each run, count rooms where `room_type_id == "EliteRoom01"`.
3. Confirm count is 1 or 2 for every run. Never 0, never 3+.

**Pass**: Every run contains 1–2 elite rooms.

---

## Scenario 5 — Elite Rooms Are at Depth 2 or Depth 4 Only

1. Start a run.
2. Identify all rooms with `room_type_id == "EliteRoom01"`.
3. For each, confirm `depth == 2` or `depth == 4`.
4. Confirm no elite room at depth 0, 1, 3.

**Pass**: All elite rooms at depth 2 or 4 only.

---

## Scenario 6 — At Most One Elite Per Depth Slot

1. Start a run with 2 elite rooms.
2. Confirm one is at depth 2 and one is at depth 4 — not two at the same depth.

**Pass**: Depth slots are exclusive (at most one elite per slot).

---

## Scenario 7 — Elite Room Applies difficulty_mult

1. Start a run with an elite room at depth 2.
2. Enter the elite room. Observe the enemy (slime).
3. Check slime's max_health in Remote Inspector or via print.
4. Confirm: `max_health == base_slime_health * 1.24`.
   (Find base_slime_health in `data/enemies.json`.)

**Pass**: Elite room enemies have 1.24× health.

---

## Scenario 8 — Non-Elite Room at Depth 2 Has Same Multiplier

1. Start a run where a non-elite room is at depth 2 (if both exist at depth 2).
2. Enter it and check enemy health.
3. Confirm: `max_health == base_health * 1.24` — same as any depth-2 room.

**Pass**: Multiplier depends on depth, not on elite/non-elite status.

---

## Scenario 9 — Depth 1 Room Has 1.12× Health

1. Start a run.
2. Enter a room at depth 1 (adjacent to start room).
3. Check enemy max_health.
4. Confirm: `max_health == base_health * 1.12`.

**Pass**: Depth-1 room uses correct multiplier.

---

## Scenario 10 — StartRoom01 Has No Enemies (Multiplier Does Not Cause Error)

1. Start a run.
2. Observe start room. Confirm no enemies spawn.
3. Confirm no errors in output related to `apply_difficulty` or `difficulty_mult`.

**Pass**: StartRoom01 loads cleanly; mult=1.0 default causes no errors.

---

## Scenario 11 — Re-entering a Room Does Not Change Stats

1. Enter a room at depth 2 (enemies spawn with 1.24× health).
2. Clear the room.
3. Leave the room and re-enter.
4. Confirm: no enemies spawn (cleared), no errors, depth and mult unchanged in `rooms_by_id`.

**Pass**: Cleared room re-entry is stable; depth/mult do not change.

---

## Scenario 12 — No Depth 4 Room → Depth-4 Elite Slot Skipped

1. Start multiple runs.
2. In a run where no room has `depth == 4`, confirm:
   - No elite room with an unexpected depth appears.
   - No error in output.
   - Only 1 elite room exists (from depth-2 slot).

**Pass**: Missing depth slot is silently skipped.

---

## Scenario 13 — Fresh Run Recalculates Everything

1. Complete a run (or abandon it).
2. Start a new run.
3. Confirm `rooms_by_id` is fully rebuilt: depths are fresh, elite promotions are re-evaluated.
4. Confirm no stale depth or mult values from the previous run.

**Pass**: Each run generates a completely independent depth and elite assignment.

---

## Scenario 14 — No Errors or Warnings During Run

1. Start a run, visit all rooms.
2. Confirm the Output panel shows no errors or warnings related to:
   - `apply_difficulty`
   - `difficulty_mult`
   - `depth`
   - `_promote_elite_rooms`

**Pass**: Clean output throughout the run lifecycle.

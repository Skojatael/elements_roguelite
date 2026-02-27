# Quickstart Validation: Run State Snapshot

**Feature**: 011-run-state
**Date**: 2026-02-27

All scenarios are manual tests in the Godot Editor using Remote Inspector and Output panel.

---

## Scenario 1 — RunState Exists Before Any Run

1. Launch the game without starting a run.
2. In the Remote Inspector, navigate to the `RunManager` autoload node.
3. Confirm `run_state` property is visible and non-null.
4. Confirm `run_state.current_room_id == ""`.
5. Confirm `run_state.run_currency == 0.0`.
6. Confirm `run_state.cleared_rooms` is an empty Dictionary.
7. Confirm `run_state.run_mode == ""`.

**Pass**: RunState accessible with safe defaults before any run.

---

## Scenario 2 — run_mode Set at Run Start

1. Start a run in `"endless"` mode.
2. Immediately read `RunManager.run_state.run_mode`.
3. Confirm it equals `"endless"`.

**Pass**: run_mode reflects the chosen mode from the first frame.

---

## Scenario 3 — current_room_id Updates on Room Entry

1. Start a run.
2. Observe start room loads. Read `RunManager.run_state.current_room_id` — confirm it matches the start room ID (e.g. `"room_2_2"`).
3. Walk through a door to an adjacent room.
4. Read `current_room_id` again — confirm it matches the new room's ID.

**Pass**: current_room_id tracks the player's current room.

---

## Scenario 4 — cleared_rooms Updates After Room Cleared

1. Start a run. Enter a combat room.
2. Defeat all enemies.
3. Read `RunManager.run_state.cleared_rooms`.
4. Confirm the room's ID is a key in the dictionary.
5. Enter another room, clear it.
6. Confirm both room IDs appear in `cleared_rooms`.

**Pass**: cleared_rooms grows as rooms are cleared.

---

## Scenario 5 — run_currency Updates After Collection

1. Start a run with 0 currency.
2. Confirm `RunManager.run_state.run_currency == 0.0`.
3. Trigger a currency reward (via `RunManager.add_currency(10.0)`).
4. Confirm `run_state.run_currency == 10.0`.

**Pass**: run_currency stays in sync with RunManager.run_currency.

---

## Scenario 6 — Stub Fields Return 0, No Error

1. Start a run.
2. Read `RunManager.run_state.max_depth_reached` — confirm it returns `0`.
3. Read `RunManager.run_state.seed` — confirm it returns `0`.
4. Confirm no error or warning appears in the Output panel.

**Pass**: Stub fields return 0 safely.

---

## Scenario 7 — Clean Reset Between Runs

1. Play through a run: collect currency, clear rooms, reach several rooms.
2. End the run (or let the player die).
3. Start a new run.
4. Immediately confirm:
   - `run_state.run_currency == 0.0`
   - `run_state.cleared_rooms` is empty
   - `run_state.current_room_id == ""` (before first room entry)
   - `run_state.max_depth_reached == 0`
   - `run_state.seed == 0`

**Pass**: No data from the previous run appears in the new one.

---

## Scenario 8 — State Readable After Run Ends

1. Start a run. Collect currency and clear 2 rooms.
2. End the run via `RunManager.end_run()`.
3. Without starting a new run, read `RunManager.run_state`.
4. Confirm `run_state.run_currency` reflects the amount from the ended run.
5. Confirm `run_state.cleared_rooms` still contains the cleared room IDs.
6. Confirm `is_run_active == false` but run_state is still accessible.

**Pass**: Final run values survive end_run() for potential end-of-run summary use.

---

## Scenario 9 — cleared_rooms is Shared Reference (Not a Copy)

1. Start a run.
2. In Remote Inspector, verify that `RunManager.cleared_rooms` and `RunManager.run_state.cleared_rooms` are the same dictionary (same entries at all times).
3. Clear a room via gameplay.
4. Confirm the room ID appears in BOTH `RunManager.cleared_rooms` and `RunManager.run_state.cleared_rooms` simultaneously.

**Pass**: No duplication — both point to the same object.
                                                                                                                    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvbnvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
---

## Scenario 10 — No Errors Throughout Full Run Lifecycle

1. Start a run, play through several rooms, collect currency, end the run.
2. Start a second run immediately.
3. Confirm the Out

**Pass**: Clean output across the full lifecycle.

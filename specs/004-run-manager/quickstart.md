# Quickstart: Run Manager

**Feature**: 004-run-manager
**Date**: 2026-02-21
**Purpose**: Manual validation scenarios to verify each user story after implementation.

---

## Prerequisites

- Godot 4.6 editor open with `project.godot`
- `003-enemy-spawning` complete — RoomSpawner and CombatRoom01 functional
- `Main.tscn` contains Player and CombatRoom01

---

## Scenario 1 — Run Lifecycle (US1, P1)

**Goal**: Verify `start_run()` initialises all fields; `end_run()` fires signal and preserves state.

**Steps**:
1. Open `Main.gd`. In `_ready()`, add temporarily:
   ```gdscript
   RunManager.run_ended.connect(func(): print("[Test] run_ended signal received"))
   RunManager.start_run("endless")
   print("[Test] is_active=", RunManager.is_run_active)
   print("[Test] run_id=", RunManager.run_id)
   print("[Test] mode=", RunManager.run_mode)
   print("[Test] tier=", RunManager.current_tier)
   print("[Test] currency=", RunManager.run_currency)
   print("[Test] room_index=", RunManager.current_room_index)
   RunManager.end_run()
   print("[Test] is_active after end=", RunManager.is_run_active)
   print("[Test] run_id still readable=", RunManager.run_id)
   ```
2. Run the game.

**Expected Output**:
```
[Test] is_active=true
[Test] run_id=<non-empty string>
[Test] mode=endless
[Test] tier=1
[Test] currency=0.0
[Test] room_index=0
[Test] run_ended signal received
[Test] is_active after end=false
[Test] run_id still readable=<same non-empty string>
```

**Pass criterion**: All fields match expected values; `run_ended` fires once; `run_id` still readable after end.

---

## Scenario 2 — Room Navigation Tracking (US2, P2)

**Goal**: Verify `current_room` and `current_room_index` update on entry; `room_cleared` re-emitted.

**Setup**:
1. Call `RunManager.start_run("endless")` on game start (in Main.gd `_ready()`).
2. Connect `RunManager.room_cleared.connect(func(id): print("[Test] RunManager room_cleared: ", id))`.
3. Run the game.

**Steps**:
1. Move player into `CombatRoom01`'s EntryArea.
2. Check Output for `current_room_index` and `current_room`.
3. Defeat all enemies.

**Expected**:
- On entry: `[RoomSpawner] player entered room 'CombatRoom01'` appears.
- `RunManager.current_room_index` is 1.
- `RunManager.current_room` is non-null (the RoomSpawner node).
- On all enemies defeated: `[Test] RunManager room_cleared: CombatRoom01` appears.

**Pass criterion**: Index increments, room reference is set, room_cleared re-emitted.

---

## Scenario 3 — Currency Tracking (US3, P3)

**Goal**: Verify `add_currency` accumulates correctly and resets on new run.

**Steps** (add temporarily to Main.gd `_ready()` after `start_run()`):
```gdscript
RunManager.add_currency(10.0)
print("[Test] currency after +10: ", RunManager.run_currency)   # expect 10.0
RunManager.add_currency(5.0)
print("[Test] currency after +5: ", RunManager.run_currency)    # expect 15.0
RunManager.add_currency(-100.0)
print("[Test] currency after -100: ", RunManager.run_currency)  # expect 0.0 (floor)
RunManager.end_run()
RunManager.start_run("endless")
print("[Test] currency after new run: ", RunManager.run_currency)  # expect 0.0
```

**Expected Output**:
```
[Test] currency after +10: 10.0
[Test] currency after +5: 15.0
[Test] currency after -100: 0.0
[Test] currency after new run: 0.0
```

**Pass criterion**: Accumulation correct; floor at 0; resets on new run.

---

## Scenario 4 — Difficulty and Rewards Stubs (US4, P4)

**Goal**: Verify stubs return valid values without error in any run state.

**Steps** (add temporarily to Main.gd `_ready()`):
```gdscript
# Test outside run
print("[Test] multiplier (no run): ", RunManager.difficulty_service.get_multiplier())
print("[Test] reward (no run): ", RunManager.rewards_service.get_room_reward("CombatRoom01"))
# Test inside run
RunManager.start_run("boss")
print("[Test] multiplier (active): ", RunManager.difficulty_service.get_multiplier())
print("[Test] reward (active): ", RunManager.rewards_service.get_room_reward("CombatRoom01"))
```

**Expected Output**:
```
[Test] multiplier (no run): 1.0
[Test] reward (no run): {}
[Test] multiplier (active): 1.0
[Test] reward (active): {}
```

**Pass criterion**: No errors; returns 1.0 and {} in both states.

---

## Scenario 5 — end_run() no-op when inactive

**Goal**: Verify `end_run()` does not crash or double-emit when called with no active run.

**Steps**:
```gdscript
RunManager.end_run()   # called with no run active
RunManager.end_run()   # called twice — should be safe
```

**Expected**: No errors. `run_ended` not emitted (no active run). Game continues normally.

---

## Scenario 6 — Invalid run_mode warning

**Goal**: Verify invalid `run_mode` produces a warning but does not crash.

**Steps**:
```gdscript
RunManager.start_run("invalid_mode")
```

**Expected**: A `push_warning` message appears in Output or Debugger. `is_run_active` is still true. No crash.

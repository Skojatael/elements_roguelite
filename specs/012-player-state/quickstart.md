# Quickstart Validation: Player State Snapshot

**Feature**: 012-player-state
**Date**: 2026-02-27

All scenarios are manual tests in the Godot Editor using Remote Inspector and Output panel.

---

## Scenario 1 — PlayerState Exists Before Any Run

1. Launch the game without starting a run.
2. In the Remote Inspector, navigate to RunManager autoload.
3. Confirm `player_state` property exists and is non-null.
4. Confirm `run_state.player_state` also exists and is non-null.
5. Confirm `player_state.items`, `modifiers`, `skill_changes` are empty arrays.
6. Confirm `player_state.skill_cooldowns` is an empty Dictionary.

**Pass**: PlayerState accessible with safe defaults before any run.

---

## Scenario 2 — current_hp Set to Full at Run Start

1. Start a run.
2. Immediately read `RunManager.run_state.player_state.current_hp`.
3. Confirm it equals the player's `StatsComponent.max_health`.

**Pass**: current_hp starts at full health.

---

## Scenario 3 — current_hp Updates on Damage

1. Start a run. Note the starting `current_hp`.
2. Let the player take damage (walk into an enemy).
3. Read `RunManager.run_state.player_state.current_hp`.
4. Confirm it decreased by the damage amount.
5. Confirm it equals `RunManager.run_state.player_state.current_hp` == `StatsComponent.current_health`.

**Pass**: current_hp tracks damage in real time.

---

## Scenario 4 — current_hp Updates on Heal

1. Damage the player to reduce health below max.
2. Trigger a heal (via game mechanic or `RunManager.run_state.player_state` read after `stats.heal()`).
3. Read `current_hp` — confirm it increased.

**Pass**: current_hp tracks heals.

---

## Scenario 5 — Stub Fields Return Empty, No Error

1. Start a run.
2. Read `RunManager.run_state.player_state.items` — confirm `[]`, no error.
3. Read `RunManager.run_state.player_state.modifiers` — confirm `[]`, no error.
4. Read `RunManager.run_state.player_state.skill_changes` — confirm `[]`, no error.
5. Read `RunManager.run_state.player_state.skill_cooldowns` — confirm `{}`, no error.

**Pass**: All stubs safe and empty.

---

## Scenario 6 — PlayerState Resets at Run End (current_hp)

1. Start a run. Take damage — reduce `current_hp` below max.
2. Call `RunManager.end_run(RunManager.EndReason.DIED)`.
3. Immediately read `RunManager.run_state.player_state.current_hp`.
4. Confirm it equals `StatsComponent.max_health` (full health restored).

**Pass**: current_hp resets to full at run end.

---

## Scenario 7 — PlayerState Resets at Run End (stubs)

1. Start a run.
2. Call `end_run()`.
3. Read all stub fields — confirm each is still empty.
4. Confirm no errors.

**Pass**: Stub fields remain empty after reset.

---

## Scenario 8 — Reset is at Run END, Not Run Start

1. Start a run. Take damage.
2. End the run. Confirm `current_hp == max_health` (reset occurred).
3. Immediately check `current_hp` BEFORE starting a new run — confirm still `max_health`.
4. Start a new run — confirm `current_hp` is still `max_health`.

**Pass**: Reset happens at end_run(), not deferred to start_run(). State is clean from end_run() onward.

---

## Scenario 9 — RunState.player_state Matches RunManager.player_state

1. Start a run.
2. Confirm `RunManager.player_state` and `RunManager.run_state.player_state` refer to the same object (same `current_hp` value at all times).
3. Take damage — confirm both update simultaneously.

**Pass**: Single shared PlayerState instance accessible via two paths.

---

## Scenario 10 — No Duplicate Signal Connections on Second Run

1. Start a first run. End it.
2. Start a second run.
3. Take damage — confirm `current_hp` updates exactly once per damage event (no duplicate updates).
4. Confirm no errors about duplicate signal connections in the Output panel.

**Pass**: `is_connected()` guard prevents duplicate connections across runs.

---

## Scenario 11 — No Errors Throughout Full Run Lifecycle

1. Start a run, play through several rooms, take damage and heal, end the run.
2. Start a second run.
3. Confirm the Output panel shows zero errors or warnings related to `PlayerState`, `player_state`, `current_hp`, `health_changed`, `items`, `modifiers`, `skill_changes`, or `skill_cooldowns`.

**Pass**: Clean output across the full lifecycle.

# Quickstart: Run End Screen

## Manual Validation Scenarios

### Scenario 1 — Results screen appears on player death
1. Start a run. Enter a combat room. Let enemies kill the player.
2. **Expected**: ExplorationHUD disappears. A results screen appears with three labelled stats.
3. **Expected**: Dungeon room is gone (no room visible behind the screen).

### Scenario 2 — Results screen appears on DevPanel cash-out
1. Start a run. Kill some enemies (note the `[RunManager] currency +N` logs).
2. In DevPanel, press "Cash Out".
3. **Expected**: Results screen appears. Essence shown equals the full `run_currency` total (no penalty).
4. **Expected**: ExplorationHUD is not visible.

### Scenario 3 — Results screen appears on DevPanel end-run (DIED)
1. Start a run. Kill some enemies.
2. In DevPanel, press "End Run (Died)".
3. **Expected**: Results screen appears. Essence shown equals `floor(run_currency × 0.85)`.

### Scenario 4 — Essence value accuracy
1. Start a run. Kill exactly 3 slimes at depth 1 (each awards 10 essence).
2. End the run via cash-out.
3. **Expected**: Essence shown = 30. Compare against `[Essence] 30 essence cashed out` in Output log.

### Scenario 5 — Enemies slain accuracy
1. Start a run. Kill exactly 5 enemies (mix of slimes and skeletons).
2. End the run.
3. **Expected**: Enemies slain shown = 5.

### Scenario 6 — Rooms cleared accuracy
1. Start a run. Clear 2 rooms (the room_cleared signal fires twice).
2. End the run.
3. **Expected**: Rooms cleared shown = 2.

### Scenario 7 — Zero stats (end run immediately)
1. Start a run via DevPanel. Immediately end it before entering any room.
2. **Expected**: Results screen shows Essence = 0, Enemies = 0, Rooms = 0. No crash.

### Scenario 8 — Return button leads to hub
1. Reach the results screen by any method.
2. Tap "Return".
3. **Expected**: Results screen disappears. Hub room is shown (TeleportDoor visible).
4. **Expected**: No run is active (`RunManager.is_run_active == false`).

### Scenario 9 — New run starts cleanly after returning
1. Complete Scenario 8.
2. Tap the TeleportDoor in the hub.
3. **Expected**: A new run starts. Dungeon generates. ExplorationHUD reappears. No stale state from the previous run is visible.

### Scenario 10 — Double-tap Return guard
1. Reach the results screen.
2. Tap "Return" rapidly twice in quick succession.
3. **Expected**: Only one hub transition occurs. No duplicate hub rooms. No errors in Output.

### Scenario 11 — ExplorationHUD hidden during results
1. Reach the results screen.
2. Confirm ExplorationHUD (joystick, any HUD elements) is completely hidden.
3. Tap Return and start a new run.
4. **Expected**: ExplorationHUD reappears once the new run starts.

### Scenario 12 — Results screen does not read dungeon nodes
1. Reach the results screen after a normal run.
2. Check the Output log — confirm no errors about freed nodes or null references from ResultsScreen.
3. **Expected**: All stat values populated without errors.

# Quickstart & Validation Scenarios: Hub Shard Display

## Manual Validation Scenarios

### Scenario 1: Zero shards on first launch

1. Delete `user://meta_save.json` if it exists.
2. Launch the game. Hub loads.
3. **Expected**: Overlay displays `Shards: 0`.

---

### Scenario 2: Correct total after a run

1. Start a run, kill enemies, end run via DevPanel (CASH_OUT).
2. Note the `[MetaManager] N shards earned — total=M` log line.
3. Press Return on the results screen. Hub loads.
4. **Expected**: Overlay displays `Shards: M` matching the log.

---

### Scenario 3: Overlay absent during run

1. Exit hub via TeleportDoor (or DevPanel "Start Run").
2. Enter the dungeon.
3. **Expected**: No shard overlay visible on screen.

---

### Scenario 4: Overlay returns after run

1. Complete a run and press Return to hub.
2. **Expected**: Overlay reappears immediately on hub load.

---

### Scenario 5: Accumulation across 5 consecutive cycles

1. Run through 5 hub → run → return cycles.
2. After each return, verify the overlay total increases correctly.
3. **Expected**: After each return, `Shards: X` increases by the correct earned amount for that run.

---

### Scenario 6: Overlay does not block TeleportDoor

1. Enter hub. Verify shard overlay is visible.
2. Tap the TeleportDoor button.
3. **Expected**: Run starts normally — overlay did not intercept the tap.

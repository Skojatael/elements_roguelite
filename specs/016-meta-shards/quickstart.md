# Quickstart & Validation Scenarios: Meta Currency — Shards

## Manual Validation Scenarios

### Scenario 1: Basic shard earn on CASH_OUT

1. Launch the game.
2. Start a run via TeleportDoor or DevPanel.
3. Kill enemies until `run_currency` accumulates (check logs for `[RunManager] currency +`).
4. Trigger cash-out via DevPanel (`end_run(CASH_OUT)`).
5. **Check output log**:
   - `[Essence] X essence cashed out`
   - `[MetaManager] X shards earned — total=X`
6. **Expected**: `shards_earned == essence_cashed_out`. `meta_state.total_shards` equals the sum.

---

### Scenario 2: Shard earn on DIED (0.85 penalty)

1. Start a run, accumulate currency.
2. Trigger death via DevPanel (`end_run(DIED)`).
3. **Check logs**:
   - `[Essence] Y essence cashed out` (Y = floor(currency × 0.85))
   - `[MetaManager] Y shards earned — total=...`
4. **Expected**: Shards match the floored 85% amount, not the raw `run_currency`.

---

### Scenario 3: Zero essence → zero shards

1. Start a run. Do not kill any enemies.
2. End run via DevPanel.
3. **Check logs**:
   - `[Essence] 0 essence cashed out`
   - `[MetaManager] 0 shards earned — total=...` (total unchanged)
4. **Expected**: `total_shards` is unchanged.

---

### Scenario 4: Accumulation across multiple runs

1. Complete three runs earning N1, N2, N3 shards respectively.
2. After each run, check the log for the running total.
3. **Expected**: After run 3, `total_shards == N1 + N2 + N3`.

---

### Scenario 5: Persistence across sessions

1. Complete a run and note the `total_shards` value from logs.
2. Close the game (stop the Godot play session).
3. Reopen and start the game again.
4. Check logs at startup for MetaManager load output (if any), or trigger a run end.
5. **Expected**: After the next run end, total reflects the previously saved shards plus the new run's shards.

---

### Scenario 6: First launch (no save file)

1. Delete `user://meta_save.json` if it exists (find it via Godot → Project → Open User Data Folder).
2. Launch the game.
3. Complete a run.
4. **Expected**: Shards start at 0, earn correctly, save file is created at `user://meta_save.json`.

---

### Scenario 7: Save file integrity

1. After earning shards, open `user://meta_save.json` in a text editor.
2. **Expected** contents: `{"total_shards": <correct_integer>}`.
3. Confirm the value matches what was logged.

---

## Integration Check

- `RunManager.run_summary` must be non-null when `run_ended` fires. Verify in RunManager.end_run() that `run_summary = RunSummary.create(...)` precedes `run_ended.emit(reason)`.
- MetaManager must NOT require RunManager to call it directly — it is purely signal-driven.

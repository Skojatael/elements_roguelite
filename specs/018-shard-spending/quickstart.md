# Quickstart & Validation Scenarios: Shard Spending

All scenarios assume a fresh save (`user://meta_save.json` deleted) unless stated otherwise.

---

### Scenario 1: Successful spend

1. Complete a run to earn ≥ 20 shards (or set `total_shards` via DevPanel / save file directly).
2. Enter the hub. Open the GDScript REPL or DevPanel and call `MetaManager.spend(20)`.
3. **Expected**: Returns `true`. Shard display decreases by 20. Log shows updated total.

---

### Scenario 2: Failed spend — insufficient balance

1. Ensure total_shards = 5.
2. Call `MetaManager.spend(30)`.
3. **Expected**: Returns `false`. Balance remains 5. No save occurs. `shards_changed` not emitted.

---

### Scenario 3: can_spend — affordability check

1. Ensure total_shards = 50.
2. Call `MetaManager.can_spend(50)` → **Expected**: `true`.
3. Call `MetaManager.can_spend(51)` → **Expected**: `false`.
4. Call `MetaManager.can_spend(0)` → **Expected**: `true`.
5. Call `MetaManager.can_spend(-1)` → **Expected**: `false`.
6. Confirm total_shards is still 50 after all checks (can_spend never mutates).

---

### Scenario 4: add_shards from arbitrary source

1. Note current total_shards (e.g. 10).
2. Call `MetaManager.add_shards(15)`.
3. **Expected**: total_shards = 25. Save file reflects 25. `shards_changed` emitted with 25.

---

### Scenario 5: shards_changed signal fires on spend

1. In a script, connect to `MetaManager.shards_changed` with a lambda that prints `"signal: {n}"`.
2. Ensure total_shards = 30. Call `MetaManager.spend(10)`.
3. **Expected**: Print shows `"signal: 20"`. Signal fires exactly once.

---

### Scenario 6: shards_changed signal fires on run-end conversion

1. Connect a listener to `MetaManager.shards_changed` (print new_total).
2. Kill enemies during a run and cash out.
3. **Expected**: `shards_changed` fires once with the new post-conversion total. Same value as shown in the hub overlay.

---

### Scenario 7: spend(0) is a no-op success

1. Note current total_shards.
2. Call `MetaManager.spend(0)`.
3. **Expected**: Returns `true`. Balance unchanged. `shards_changed` NOT emitted. No save file write.

---

### Scenario 8: add_shards(0) is a silent no-op

1. Note current total_shards.
2. Call `MetaManager.add_shards(0)`.
3. **Expected**: Balance unchanged. `shards_changed` NOT emitted. No save file write.

---

### Scenario 9: Negative values rejected

1. Call `MetaManager.can_spend(-5)` → **Expected**: `false`.
2. Call `MetaManager.spend(-5)` → **Expected**: `false`. Balance unchanged.
3. Call `MetaManager.add_shards(-5)` → **Expected**: No-op. Balance unchanged. No signal.

---

### Scenario 10: Persistence after spend

1. Start game, earn 50 shards.
2. Call `MetaManager.spend(20)` → balance = 30.
3. Quit and relaunch the game.
4. **Expected**: Hub overlay shows 30. MetaManager.meta_state.total_shards = 30.

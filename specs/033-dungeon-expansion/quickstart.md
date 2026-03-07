# Quickstart: Dungeon Expansion (033)

Manual test scenarios for validating the full feature. Run in order.

---

## Scenario 1 — Upgrade Not Shown Before Boss Kill

**Setup**: Fresh save (or save with `first_boss_killed = false`). Enter hub.

**Steps**:
1. Launch game — hub loads.
2. Inspect hub for Adventuring Gear upgrade button.

**Expected**: No Adventuring Gear button visible. UpgradeShop only shows Damage Multiplier.

---

## Scenario 2 — Boss Kill Unlocks Upgrade Visibility

**Setup**: Fresh run started via DevPanel "Start Boss".

**Steps**:
1. DevPanel → Start Boss.
2. Kill boss.
3. Cash Out.
4. Results Screen → Return (returns to hub).
5. Inspect hub.

**Expected**: Adventuring Gear button is visible in hub, showing "Adventuring Gear — 300 shards". No crash.

---

## Scenario 3 — Button Does Nothing When Broke

**Setup**: Adventuring Gear visible, `total_shards < 300`.

**Steps**:
1. Confirm shard balance is shown in hub (< 300).
2. Tap "Adventuring Gear — 300 shards" button.

**Expected**: Nothing happens. Shard balance unchanged. Button still visible. No error in output.

---

## Scenario 4 — Purchase Succeeds

**Setup**: Adventuring Gear visible, `total_shards >= 300`. (Use multiple runs to accumulate shards, or edit save file to set `total_shards: 300`.)

**Steps**:
1. Verify shard balance ≥ 300.
2. Tap "Adventuring Gear — 300 shards" button.

**Expected**:
- Shard balance decreases by exactly 300.
- Adventuring Gear button disappears from hub.
- Output log: `[MetaManager] Adventuring Gear purchased` (or similar).

---

## Scenario 5 — Button Gone on Subsequent Hub Visits

**Setup**: Adventuring Gear already purchased (from Scenario 4, or set `adventuring_gear_owned: true` in save file).

**Steps**:
1. Start run → end run → return to hub.
2. Inspect hub.

**Expected**: Adventuring Gear button is NOT shown. Damage Multiplier button still shows normally.

---

## Scenario 6 — Expanded Dungeon Has 12 Rooms

**Setup**: Adventuring Gear owned.

**Steps**:
1. Start a new run (hub → TeleportDoor or DevPanel → Start Run).
2. Check output log for `[DungeonGenerator] layout rooms=12`.

**Expected**:
- Log shows `rooms=13`.
- Log shows `expansion seed=room_X_Y max_depth=N rooms_added=4`.

---

## Scenario 7 — Expansion Rooms Are Deeper Than Room A

**Setup**: Adventuring Gear owned. Run started.

**Steps**:
1. Read log: find expansion seed `room_X_Y` and its `max_depth=N`.
2. Check all rooms in `rooms_by_id` against depth.

**Expected**: All 4 expansion rooms have `depth > N` (strictly greater than Room A's depth). No expansion room at depth ≤ N.

---

## Scenario 8 — Expansion Rooms Reachable via Doors

**Setup**: Adventuring Gear owned. Run started.

**Steps**:
1. Navigate through dungeon to reach Room A (deepest room).
2. Clear Room A.
3. Confirm expansion doors appear after clearing Room A.
4. Enter an expansion room.

**Expected**: Expansion rooms accessible via standard doors from Room A. No dead ends. Player can enter and clear expansion rooms normally.

---

## Scenario 9 — No Expansion Without Gear

**Setup**: Adventuring Gear NOT purchased.

**Steps**:
1. Start a new run.
2. Check output log.

**Expected**: Log shows `rooms=9`. No expansion log line. Dungeon behaves as before.

---

## Scenario 10 — Persistence Across Sessions

**Setup**: Adventuring Gear purchased (Scenario 4).

**Steps**:
1. Close and relaunch the game.
2. Enter hub.
3. Start a run.

**Expected**:
- Adventuring Gear button NOT shown (still owned after relaunch).
- Run has 12 rooms (expansion persists).

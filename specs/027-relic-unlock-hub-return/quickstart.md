# Quickstart: Relic Offers Activate on Hub Return

**Feature**: 027-relic-unlock-hub-return
**Date**: 2026-03-03

Manual validation scenarios — run in Godot Editor play mode.

---

## Scenario 1: No relic offers in the unlock run

1. Fresh profile (`adventurer_bag_unlocked = false`, `relic_offers_active = false`).
2. Start a run. Navigate to and clear an elite room (Adventurer Bag unlocks).
3. Continue clearing 4 more rooms in the same run.
4. **Expected**: Zero relic offers appear. Output log shows `[MetaManager] Adventurer Bag unlocked` but NO `[RelicManager] offer triggered`.

---

## Scenario 2: No relic offers in runs before hub return

1. Fresh profile. Unlock the Adventurer Bag (clear an elite room). End the run.
2. On the ResultsScreen, press "Return" — this brings up the hub.
3. **Immediately** start a new run from the hub WITHOUT clearing offers on the hub screen — wait, that's not right. Actually: after returning to hub, relic offers should become active. But let's first test the negative case.
4. To test "run before hub return": fresh profile → unlock bag → immediately start another run via DevPanel "Start Run" button (bypasses the hub return flow) → clear 2+ rooms.
5. **Expected**: No relic offers in that run either.

---

## Scenario 3: Relic offers activate on first hub return

1. Fresh profile. Unlock the Adventurer Bag (clear an elite room). End the run normally.
2. On ResultsScreen, press "Return" → lands in hub.
3. Check Output: **Expected** log line `[MetaManager] relic offers activated — first hub return after Adventurer Bag unlock`.
4. Check `user://meta_save.json`: **Expected** `"relic_offers_active": true`.
5. Start a new run from hub. Clear 2 standard rooms.
6. **Expected**: Relic offer screen appears after the 2nd standard room clear.

---

## Scenario 4: Activation persists across sessions

1. Complete Scenario 3 (relic offers now active). Quit editor play mode.
2. Re-enter play mode. Start a run. Clear 2 standard rooms.
3. **Expected**: Relic offer appears — activation survived the restart.

---

## Scenario 5: Death counts as hub return

1. Fresh profile. Unlock the Adventurer Bag. Die (let player HP reach 0, or use DevPanel "End Run").
2. ResultsScreen appears. Press "Return" → lands in hub.
3. **Expected**: Same as Scenario 3 — `relic_offers_active` activates, relic offers appear on next run.

---

## Scenario 6: Backward compatibility — bag already unlocked

1. Manually edit `user://meta_save.json` to set `"adventurer_bag_unlocked": true`, `"relic_offers_active": false` (or omit the key).
2. Start editor play mode.
3. **Expected**: `[MetaManager] relic offers activated` fires immediately (game starts in hub). Relic offers appear in the first run.

---

## Scenario 7: Missing key in save file handled gracefully

1. Edit `user://meta_save.json` to remove `"relic_offers_active"` key (leave `"adventurer_bag_unlocked": false`).
2. Enter play mode. Start a run. Clear rooms.
3. **Expected**: No crash, no relic offers (defaults to both false).

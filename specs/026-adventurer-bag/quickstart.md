# Quickstart: Adventurer Bag

**Feature**: 026-adventurer-bag
**Date**: 2026-03-03

Manual validation scenarios — run in Godot Editor play mode.

---

## Scenario 1: No relic offers before unlock

1. Clear `user://meta_save.json` (or use a fresh profile) so `adventurer_bag_unlocked = false`.
2. Start a run via DevPanel.
3. Clear 10 standard rooms (use DevPanel "Clear Room" if available, or play normally).
4. **Expected**: No relic offer screen ever appears.

---

## Scenario 2: First elite clear triggers unlock

1. Fresh profile (`adventurer_bag_unlocked = false`).
2. Start a run. Navigate to an elite room and clear it.
3. **Expected**: No relic offer appears for that room (unlock is not retroactive).
4. Open `user://meta_save.json` (via Output or file explorer). **Expected**: `"adventurer_bag_unlocked": true`.

---

## Scenario 3: Relic offers appear after unlock

1. From the same session as Scenario 2 (Adventurer Bag now unlocked).
2. Clear 2 more standard rooms.
3. **Expected**: A relic offer appears after the 2nd standard room clear (normal `OFFER_INTERVAL = 2` behaviour).

---

## Scenario 4: Unlock persists across sessions

1. Complete Scenario 2 (unlock recorded). Quit the editor play mode.
2. Re-enter play mode. Start a new run. Clear 2 standard rooms.
3. **Expected**: Relic offer appears — unlock survived the restart.

---

## Scenario 5: Second elite clear is a no-op

1. Adventurer Bag already unlocked (from Scenario 2 or 4).
2. Clear a second elite room.
3. **Expected**: No duplicate log line about "Adventurer Bag unlocked". The offer gating unchanged (normal elite offer behaviour: always offer for elite rooms when unlocked).

---

## Scenario 6: Missing key in save file handled gracefully

1. Open `user://meta_save.json`. Remove the `"adventurer_bag_unlocked"` key manually. Save.
2. Start editor play mode.
3. **Expected**: No crash. Relic offers do not appear (defaults to `false`).

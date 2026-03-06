# Quickstart: Boss Victory Outcome (030)

Manual test scenarios to validate the feature end-to-end.

---

## Scenario 1 — No Doors in Boss Room

**Setup**: Start a run, clear 6 rooms, teleport to boss room.

**Steps**:
1. Observe all four walls of the boss room.

**Expected**: No door zones visible on any wall. Player can walk to any wall and nothing happens (no room transition, no door visual).

---

## Scenario 2 — Boss Button Does Not Reappear After Boss Death

**Setup**: Start a run, clear exactly 6 rooms (boss button appears), teleport to boss room, kill the boss.

**Steps**:
1. Note that the boss teleport button was hidden when you pressed it.
2. Kill the boss.
3. Observe the ExplorationHUD (or lack thereof).

**Expected**: The "Teleport to Boss" button does NOT reappear. The HUD becomes hidden entirely when the victory overlay shows.

---

## Scenario 3 — Victory Overlay Appears on Boss Death

**Setup**: Start a run, clear 6 rooms, teleport to boss room, kill the boss.

**Steps**:
1. Kill the boss enemy.

**Expected**: An overlay appears immediately with exactly two buttons: "Cash Out" and "Continue Further". The ExplorationHUD (including joystick and boss button) is hidden.

---

## Scenario 4 — Cash Out Ends Run Correctly

**Setup**: Victory overlay visible.

**Steps**:
1. Press "Cash Out".

**Expected**:
- The victory overlay disappears.
- The Results Screen appears (same as dying or DevPanel cash-out).
- Essence cashed out equals 100% of accumulated run currency.
- Pressing "Return" on the Results Screen returns to the hub.

---

## Scenario 5 — Continue Further Is a Stub

**Setup**: Victory overlay visible.

**Steps**:
1. Press "Continue Further".

**Expected**:
- The button text changes to "Coming Soon..." and the button becomes disabled (greyed out).
- No crash, no freeze, no room transition.
- "Cash Out" button remains available and functional.

---

## Scenario 6 — Double Press Cash Out Is Prevented

**Setup**: Victory overlay visible.

**Steps**:
1. Press "Cash Out" once.
2. Quickly attempt to press "Cash Out" again before the overlay is freed.

**Expected**: The run-end flow triggers exactly once. Results Screen appears once. No duplicate essence award.

---

## Scenario 7 — Victory Overlay Cleaned Up on DevPanel "Start Run"

**Setup**: Victory overlay visible (boss defeated, neither button pressed yet).

**Steps**:
1. Use DevPanel "Start Run" to bypass the overlay.

**Expected**: Victory overlay is freed. New run begins normally. Hub room or run start proceeds without leftover overlay nodes in the scene tree.

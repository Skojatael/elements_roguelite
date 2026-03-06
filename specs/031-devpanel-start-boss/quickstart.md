# Quickstart: DevPanel Start Boss (031)

Manual test scenarios.

---

## Scenario 1 — Start Boss from Hub (No Run Active)

**Setup**: Launch game, stay in hub (no run started).

**Steps**:
1. Press DevPanel "Start Boss".

**Expected**: Run starts automatically, player appears in boss room, one boss enemy spawns. ExplorationHUD is hidden (replaced by boss encounter). Boss HP ≈ 40 (base, 0 rooms cleared).

---

## Scenario 2 — Start Boss Mid-Run

**Setup**: Start a run via the hub teleport door or DevPanel "Start Run". Enter one or two dungeon rooms.

**Steps**:
1. Press DevPanel "Start Boss".

**Expected**: Current dungeon room is freed, player is placed in boss room, boss spawns. No orphaned room nodes. Boss HP may be scaled slightly if rooms were cleared (e.g., 1 room cleared → mult ≈ 1.06 → HP ≈ 42.4).

---

## Scenario 3 — Start Boss While Already in Boss Room (No-Op)

**Setup**: Reach the boss room via any path (DevPanel or normal play). Boss is still alive.

**Steps**:
1. Press DevPanel "Start Boss" again.

**Expected**: Nothing happens. No second boss spawns, no crash, no scene change.

---

## Scenario 4 — Start Boss While Victory Overlay Is Showing (No-Op)

**Setup**: Reach boss room, defeat boss, victory overlay ("Cash Out" / "Continue Further") is visible.

**Steps**:
1. Press DevPanel "Start Boss".

**Expected**: Nothing happens. Overlay remains. No crash.

---

## Scenario 5 — End-to-End Via DevPanel Path

**Setup**: Start from hub.

**Steps**:
1. Press DevPanel "Start Boss" → boss room loads.
2. Kill the boss.
3. Press "Cash Out" on the victory overlay.

**Expected**: Results Screen appears with correct essence payout. Pressing "Return" returns to hub.

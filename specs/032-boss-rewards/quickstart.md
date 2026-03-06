# Quickstart: Boss Rewards (032)

Manual test scenarios.

---

## Scenario 1 — Boss Reward at 0 Rooms Cleared

**Setup**: DevPanel "Start Boss" from hub (0 rooms cleared).

**Steps**:
1. Kill the boss.
2. Observe the relic offer screen (3 rare relics).
3. Pick a relic.
4. Press "Cash Out" on the victory overlay.
5. Note essence on the Results Screen.

**Expected**:
- Essence cashed out includes exactly 80 (boss reward; no scaling).
- Relic offer shows exactly 3 options, all rare tier.

---

## Scenario 2 — Boss Reward Scales with Rooms Cleared

**Setup**: Start a run normally, clear 6 rooms, then press "Teleport to Boss".

**Steps**:
1. Kill the boss.
2. Pick a relic.
3. Press "Cash Out".
4. Check Results Screen essence.

**Expected**:
- Boss reward = `floor(80 × 1.36)` = **108** essence (plus any essence earned from dungeon enemies).

---

## Scenario 3 — Relic Offer Has Exactly 3 Rare Relics

**Setup**: Fresh run, no relics collected yet (4 rare relics available in pool).

**Steps**:
1. Kill the boss.
2. Inspect the relic offer screen.

**Expected**:
- Exactly 3 cards shown.
- All 3 are rare tier (Rage Crystal, Vital Core, Berserker Stone, or Executioner's Mark).
- The 4th rare relic does not appear.

---

## Scenario 4 — Victory Overlay Appears After Relic Pick (Not Before)

**Setup**: Kill the boss.

**Steps**:
1. Relic offer appears — confirm victory overlay is NOT visible yet.
2. Pick a relic.
3. Confirm victory overlay appears.

**Expected**: Victory overlay (Cash Out / Continue Further) is absent until after the relic pick.

---

## Scenario 5 — Fallback When No Rare Relics Available

**Setup**: Collect all 4 rare relics during a run, then kill the boss.

**Steps**:
1. Kill the boss.

**Expected**:
- No relic offer screen appears (skipped).
- Victory overlay appears directly after boss death.
- Boss essence reward is still awarded.

---

## Scenario 6 — Regular Relic Offer Counter Not Corrupted

**Setup**: Start a run, clear 1 standard room (counter at 1 of 2 for next offer), then DevPanel "Start Boss".

**Steps**:
1. Kill the boss (boss relic offer → pick relic → victory overlay).
2. Press "Continue Further" (stub).
3. Start a new run, clear 1 room.

**Expected**: The regular relic offer counter starts fresh in the new run. Boss room clearing did NOT trigger a regular relic offer or corrupt the counter.

# Quickstart: Conditional Damage Relics

**Feature**: 024-execute-relic
**Date**: 2026-03-03

Manual validation scenarios — run in Godot Editor play mode.

---

## Scenario 1: Execute relic obtainable

1. Start a run via DevPanel.
2. Press "Get Relic" repeatedly until "Executioner's Mark" appears in an offer.
3. **Expected**: card shows name "Executioner's Mark" and description "+35% damage to enemies below 30% HP". Picking it registers it as active.

---

## Scenario 2: Execute bonus applies below threshold

1. Start a run with execute relic active (use DevPanel "Get Relic", pick Executioner's Mark).
2. Enter a combat room. Let an enemy reach approximately 50% HP — note the damage numbers.
3. Let the enemy reach below 30% HP — observe damage numbers.
4. **Expected**: hits below 30% HP deal ≈1.35× more damage than hits above 30% HP (check output log for `take_damage` if numbers aren't visible).

---

## Scenario 3: Execute bonus does not apply above threshold

1. Execute relic active. Attack an enemy at full HP.
2. **Expected**: no execute bonus — damage equals baseline.

---

## Scenario 4: Berserker relic obtainable

1. Start a run via DevPanel.
2. Press "Get Relic" repeatedly until "Berserker Stone" appears.
3. **Expected**: card shows name "Berserker Stone" and description "+30% damage when below 50% HP". Picking it registers it as active.

---

## Scenario 5: Berserker bonus applies when player is low HP

1. Start a run with berserker relic active.
2. Take damage from an enemy until player HP drops below 50% of max — note attack damage output.
3. **Expected**: attacks deal ≈1.30× more damage than at full HP.

---

## Scenario 6: Berserker bonus disappears when player heals above threshold

1. Berserker relic active, player below 50% HP (bonus active).
2. Heal above 50% HP (if a heal mechanic exists, or start a fresh run and don't take damage).
3. **Expected**: damage returns to baseline — no berserker bonus.

---

## Scenario 7: Both relics held — stacking

1. Acquire both execute and berserker relics in the same run.
2. Let player HP drop below 50%. Attack an enemy below 30% HP.
3. **Expected**: damage ≈ baseline × 1.35 × 1.30 (≈1.755×). Both bonuses apply simultaneously.

---

## Scenario 8: Neither bonus outside conditions

1. Both relics active. Player at full HP, enemy at full HP.
2. **Expected**: damage equals baseline — no bonuses.

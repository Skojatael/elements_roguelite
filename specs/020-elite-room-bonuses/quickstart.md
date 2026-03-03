# Quickstart & Validation Scenarios: Elite Room Bonuses

---

### Scenario 1: Standard room enemy count unchanged

1. Start a run. Enter a CombatRoom01 (2 configured enemies).
2. **Expected**: Exactly 2 enemies spawn. No change from pre-feature behaviour.

---

### Scenario 2: Elite room spawns 3 enemies from base of 2

1. Start a run. Enter an EliteRoom01.
2. **Expected**: 3 enemies spawn — 2 from base config (slime + skeleton) and 1 extra
   (slime, being index 2 % 2 = 0 → first entry).

---

### Scenario 3: Third enemy position is random within its configured radius

1. Enter an EliteRoom01 multiple times across runs.
2. Observe the third enemy (extra slime) position each time.
3. **Expected**: Third enemy spawns near the slime's configured position (-80, 0) with
   randomised offset within radius 20. Position varies between runs.

---

### Scenario 4: Standard room essence unchanged

1. Kill a slime at depth 1 in a CombatRoom01.
2. **Expected**: Essence earned = floor(10 × 1.0) = 10. No essence_mult applied.

---

### Scenario 5: Elite room essence multiplied per kill — slime at depth 1

1. Enter an EliteRoom01 at depth 2 (any depth where elite rooms appear).
   For a depth 1 elite scenario: kill a slime.
2. **Expected**: Essence = floor(10 × 1.0 × 1.8) = 18 (at depth 1 where depth factor = 1.0).

---

### Scenario 6: Elite room essence stacks with depth scaling

1. Reach an EliteRoom01 at depth 2.
2. Kill the skeleton.
3. **Expected**: Depth factor = 1 + 0.10 × (2 − 1) = 1.1.
   Essence = floor(15 × 1.1 × 1.8) = floor(29.7) = 29.

---

### Scenario 7: Elite room essence — slime at depth 2

1. Reach an EliteRoom01 at depth 2. Kill the slime.
2. **Expected**: Essence = floor(10 × 1.1 × 1.8) = floor(19.8) = 19.

---

### Scenario 8: Standard room at same depth earns less essence

1. Kill a slime at depth 2 in a standard CombatRoom01.
2. Kill a slime at depth 2 in an EliteRoom01.
3. **Expected**: Standard = floor(10 × 1.1) = 11. Elite = 19. Difference confirms
   the 1.8 multiplier is applied in elite rooms only.

---

### Scenario 9: All 3 elite enemies contribute to room_cleared

1. Enter an EliteRoom01. Defeat all 3 enemies.
2. **Expected**: `room_cleared` fires after the 3rd kill (not the 2nd). Run can proceed
   through the door after all 3 are defeated.

---

### Scenario 10: Multiplier values are config-driven

1. Change `enemy_count_mult` in dungeon_config.json to 2.0 for EliteRoom01.
2. Start a run and enter an EliteRoom01.
3. **Expected**: 4 enemies spawn (floor(2 × 2.0) = 4). Revert after test.

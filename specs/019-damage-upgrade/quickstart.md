# Quickstart & Validation Scenarios: Damage Multiplier Upgrade

---

### Scenario 1: Button visible and shows correct base cost

1. Delete `user://meta_save.json` if it exists (clean state).
2. Launch game. Enter hub.
3. **Expected**: Upgrade button visible, text reads `"Damage Multiplier — 50 shards"`.

---

### Scenario 2: Button disabled with insufficient shards

1. Ensure total_shards = 0 (first launch).
2. Observe upgrade button.
3. **Expected**: Button is disabled (non-interactive). Text still shows `"Damage Multiplier — 50 shards"`.

---

### Scenario 3: Successful purchase at level 0 → 1

1. Earn or set total_shards ≥ 50.
2. Tap the upgrade button.
3. **Expected**: Purchase succeeds. Shard balance decreases by 50. Button now reads `"Damage Multiplier — 60 shards"` (cost for level 1→2).

---

### Scenario 4: Button updates affordability reactively

1. Have shards just below the current cost (e.g., 59 shards, button at level 1 cost = 60).
2. Observe button is disabled.
3. Complete a run that earns ≥ 1 shard. Return to hub.
4. **Expected**: Once total_shards ≥ 60, button becomes enabled automatically without needing to reload the scene.

---

### Scenario 5: Max level reached

1. Purchase all 10 levels (costs: 50+60+72+86+103+123+147+176+211+253 = 1281 shards total).
2. Observe upgrade button after level 10.
3. **Expected**: Button reads `"Damage Multiplier — MAX"` and is non-interactive regardless of shard balance.

---

### Scenario 6: Upgrade level persists across sessions

1. Purchase 3 upgrade levels (costs 50+60+72 = 182 shards).
2. Quit the game completely.
3. Relaunch. Enter hub.
4. **Expected**: Upgrade button shows `"Damage Multiplier — 86 shards"` (cost for level 3→4). Level not reset.

---

### Scenario 7: Damage at level 0 unchanged

1. Start with level 0 (no upgrades). Start a run.
2. Note damage dealt to an enemy.
3. **Expected**: Damage equals the base attack_damage value (Inspector-assigned, e.g. 1.0). No bonus.

---

### Scenario 8: Damage at level 1 = base × 1.1

1. Purchase level 1 upgrade (50 shards). Start a run.
2. Attack an enemy and observe damage dealt.
3. **Expected**: Damage = base × 1.1. If base = 1.0, damage = 1.1 per hit.

---

### Scenario 9: Damage at level 3 = base × 1.3 (additive, not compounding)

1. Purchase 3 upgrade levels. Start a run.
2. Attack an enemy.
3. **Expected**: Damage = base × 1.3 (not 1.1 × 1.1 × 1.1 = 1.331).

---

### Scenario 10: Damage at level 10 = base × 2.0

1. Purchase all 10 levels. Start a run.
2. Attack an enemy.
3. **Expected**: Damage = base × 2.0. Confirm this is exactly double the base, not any other value.

---

### Scenario 11: Upgrade cost not deducted on failed purchase

1. Set total_shards to exactly 49 (one below the base cost of 50).
2. Attempt to tap the button (if enabled — it should be disabled, so try via DevPanel or force-enabling).
3. **Expected**: Purchase fails. Balance remains at 49. Level stays at 0.

---

### Scenario 12: Damage multiplier resets per run (not per session)

1. Purchase level 2. Start run 1. Confirm damage = base × 1.2.
2. End run (cash out). Return to hub.
3. Start run 2 without purchasing more upgrades.
4. **Expected**: Damage in run 2 is still base × 1.2 (multiplier re-applied from saved level, not reset to base).

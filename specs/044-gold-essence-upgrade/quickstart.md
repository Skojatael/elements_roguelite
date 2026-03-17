# Quickstart: Gold-Purchased Essence Gain Upgrade

**Feature**: 044-gold-essence-upgrade
**Date**: 2026-03-16

This is a script-only feature. No new scenes, no new editor work.

---

## Implementation order

1. **Config** (`data/meta_config.json`) — update `essence_gain` section first; all other changes depend on it.
2. **MetaManagerImpl** (`scripts/managers/MetaManagerImpl.gd`) — fix multiplier formula + add gold spend + purchase method.
3. **MetaManager autoload** (`autoload/MetaManager.gd`) — expose new wrappers.
4. **LabUpgradeScreen** (`scenes/hub/LabUpgradeScreen.gd`) — update essence button UI logic.

---

## Validation

1. Open game → Alchemy Lab (if unlocked) → Essence Gain button shows "50 gold" cost.
2. With < 50 gold: button disabled. With ≥ 50 gold: button enabled.
3. Purchase level 1 → gold deducted by 50, button now shows "100 gold", level increments.
4. Purchase all 5 levels → button shows "MAX".
5. Start a run → kill enemies → verify essence values match `floor(base × depth_mult × pow(1.05, level))`.
6. Close and reopen game → upgrade level persists.

---

## DevPanel shortcut

Use DevPanel to set gold directly (`MetaManager.meta_state.total_gold = 1000.0`) and the Alchemy Lab unlocked state if needed for faster testing.

---

## Key values at a glance

| Level | Cost (gold) | Cumulative cost | Multiplier |
|-------|------------|----------------|-----------|
| 1 | 50 | 50 | ×1.0500 |
| 2 | 100 | 150 | ×1.1025 |
| 3 | 150 | 300 | ×1.1576 |
| 4 | 200 | 500 | ×1.2155 |
| 5 | 250 | 750 | ×1.2763 |

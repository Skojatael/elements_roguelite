# Quickstart Validation: Alchemy Lab — Essence Condenser Upgrade

**Feature**: 045-shard-generator
**Date**: 2026-03-17

Use these scenarios to validate the feature end-to-end after implementation.

---

## Prerequisite State

- Alchemy Lab unlocked (`alchemy_lab_unlocked = true` in save)
- Transmuter owned (gold is generating)
- At least 600 gold accumulated

---

## Scenario 1: Purchase level 1

1. Open Alchemy Lab upgrade screen.
2. Confirm a new "Essence Condenser" button is visible.
3. Confirm button text shows `"Essence Condenser 2/hr (Lv1) — 600 gold"`.
4. Confirm button is **enabled** (player has ≥ 600 gold).
5. Tap purchase button.
6. Confirm gold reduced by 600.
7. Confirm button now shows `"Essence Condenser 3/hr (Lv2) — 1200 gold"`.
8. With < 1200 gold remaining, confirm button is **disabled**.

**Expected**: Purchase succeeds, button state updates, gold deducted.

---

## Scenario 2: Button disabled below cost

1. Edit save file: set `total_gold` to 599.
2. Open Alchemy Lab (level 0).
3. Confirm "Essence Condenser" button is **disabled**.
4. Edit save: set `total_gold` to 600.
5. Reopen screen; confirm button is now **enabled**.

**Expected**: Exact boundary behaviour — 599 = disabled, 600 = enabled.

---

## Scenario 3: Live gold-change re-evaluates button

1. Open Alchemy Lab with exactly 600 gold and level 0.
2. Wait for the gold balance to tick below 600 (or purchase another upgrade that costs gold).
3. Without closing the screen, confirm the Essence Condenser button becomes **disabled** automatically.

**Expected**: Button state responds to `gold_changed` signal without reopening the screen.

---

## Scenario 4: Passive shard accumulation (in-session)

1. Purchase level 1 (2 shards/hour).
2. Note current `total_shards` value.
3. Wait ~1800 real seconds (30 minutes) — or temporarily raise the rate in config to `[120, ...]` for fast testing.
4. Confirm `total_shards` has increased by 1 (at 2/hr rate) or by the expected scaled amount.

**Expected**: Shard balance increases at the configured rate.

---

## Scenario 5: Offline shard credit

1. Purchase level 2 (3 shards/hour).
2. Note `total_shards` and close the game.
3. Manually edit `meta_save.json`: subtract 3600 from `gold_last_saved_timestamp` (simulates 1 hour offline).
4. Reopen the game.
5. Confirm `total_shards` increased by 3 (1 hour × 3/hr).

**Expected**: Offline shards credited on startup using the shared timestamp.

---

## Scenario 6: Offline cap shared with gold

1. Ensure Gold Storage Cap is at level 0 (default 4-hour cap).
2. Purchase level 3 (5 shards/hour).
3. Edit save: subtract 36000 (10 hours) from `gold_last_saved_timestamp`.
4. Reopen the game.
5. Confirm shards credited = `floor(5 × 4)` = **20** (not 50), matching the 4-hour cap.
6. Confirm gold also credited only for 4 hours.

**Expected**: Both generators observe the same cap duration.

---

## Scenario 7: Upgrade through all 3 levels and reach MAX

1. Ensure player has 4200+ gold.
2. Purchase level 1 (600 gold deducted).
3. Purchase level 2 (1200 gold deducted).
4. Purchase level 3 (2400 gold deducted).
5. Confirm button shows `"Essence Condenser — MAX"` and is **disabled**.
6. Total gold deducted: 600 + 1200 + 2400 = **4200**.

**Expected**: All levels purchasable; correct cumulative cost; MAX state terminal.

---

## Scenario 8: Persistence across restart

1. Purchase level 2.
2. Close the game cleanly.
3. Reopen.
4. Open Alchemy Lab; confirm button shows level 2 state (`"Essence Condenser 5/hr (Lv3) — 2400 gold"`).
5. Confirm gold balance reflects the 1200 deduction from before restart.

**Expected**: Level and gold persist across sessions with zero regression.

---

## Scenario 9: Config-driven values

1. In `data/meta_config.json`, change `rates_per_hour` to `[10, 20, 30]`.
2. Reopen game (no code changes).
3. Confirm Alchemy Lab button text reflects new rates.
4. Change `base_cost` to `100`; confirm cost shown is 100.

**Expected**: UI fully driven by config — no code change required to update values.

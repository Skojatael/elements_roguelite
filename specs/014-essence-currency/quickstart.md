# Quickstart Validation: Essence Currency

**Feature**: 014-essence-currency
**Date**: 2026-02-28

Run these scenarios manually in the Godot Editor (Play). Check Output panel for
log messages. All scenarios assume DEV_MODE = true.

---

## Scenario 1 — Slime kill at depth 1 awards correct essence

1. Start run via DevPanel.
2. Move to a combat room at depth 1 (one step from start).
3. Kill a slime.
4. **Expected**: Output shows `[RunManager] currency +2 — total=2`
   (formula: `floori(2 × 1.1) = 2`).

---

## Scenario 2 — Skeleton kill at depth 2 awards correct essence

1. Start run, navigate to a room at depth 2.
2. Kill a skeleton.
3. **Expected**: `[RunManager] currency +3 — total=3`
   (formula: `floori(3 × 1.2) = 3`).

---

## Scenario 3 — Skeleton kill at depth 3 awards correct essence

1. Start run, navigate to a room at depth 3.
2. Kill a skeleton.
3. **Expected**: `[RunManager] currency +3 — total=3`
   (formula: `floori(3 × 1.3) = floor(3.9) = 3`).

---

## Scenario 4 — Multiple kills accumulate correctly

1. Start run, enter a room with multiple enemies.
2. Kill all enemies.
3. **Expected**: Each kill logs its own `[RunManager] currency +N` line.
   Final total matches sum of individual kills.

---

## Scenario 5 — No essence awarded when no run is active

1. Do NOT start a run (hub state, `is_run_active == false`).
2. Trigger an enemy defeat somehow (DevPanel / direct call).
3. **Expected**: Output shows `[RunManager] add_currency called with no active run`.
   `run_currency` remains 0.

---

## Scenario 6 — Cash-out on CASH_OUT: 100% awarded

1. Start run, kill enemies, accumulate some essence (e.g., 10).
2. Press "Cash Out" in DevPanel.
3. **Expected**: Output shows `[Essence] 10 essence cashed out`.

---

## Scenario 7 — Cash-out on DIED: 85% awarded

1. Start run, accumulate 100 essence.
2. Die (use DevPanel "End Run (Died)" or let enemy kill player).
3. **Expected**: Output shows `[Essence] 85 essence cashed out`
   (formula: `floori(100 × 0.85) = 85`).

---

## Scenario 8 — Cash-out with 0 essence

1. Start run, do not kill any enemies.
2. End run (either reason).
3. **Expected**: Output shows `[Essence] 0 essence cashed out`. No crash.

---

## Scenario 9 — Fractional essence rounds down at cash-out (DIED)

1. Start run, kill enemies to accumulate a total where 85% is fractional
   (e.g., accumulate 7 essence → `floori(7 × 0.85) = floori(5.95) = 5`).
2. Die.
3. **Expected**: Output shows `[Essence] 5 essence cashed out`.

---

## Scenario 10 — Essence resets between runs

1. Start run, accumulate some essence, end run.
2. Start a new run.
3. Kill one enemy.
4. **Expected**: The second run's first kill log shows only that kill's amount,
   not the first run's total. `run_currency` started from 0.

---

## Scenario 11 — Start room gives no essence (no enemies)

1. Start run.
2. Stay in StartRoom01.
3. **Expected**: No `[RunManager] currency +` messages. `run_currency` remains 0.

---

## Scenario 12 — Depth multiplier at depth 0 is 1.0 (no bonus)

1. If a combat room were somehow placed at depth 0 (edge case), a slime kill
   would yield `floori(2 × 1.0) = 2`.
2. **Expected formula holds**: multiplier = `1.0 + 0.10 × 0 = 1.0`.
   (Verifiable by reading formula — no setup needed unless a depth-0 combat room exists.)

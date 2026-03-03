# Quickstart: Unique Relic Offers

**Feature**: 025-unique-relic-offers
**Date**: 2026-03-03

Manual validation scenarios — run in Godot Editor play mode.

---

## Scenario 1: Two distinct relics every offer

1. Start a run via DevPanel.
2. Press "Get Relic" 20 times, picking any relic each time.
3. **Expected**: every offer shows two different relics — no offer has matching names or descriptions on both cards.

---

## Scenario 2: Uniqueness holds across many offers (statistical)

1. Start a run. Press "Get Relic" 30 times.
2. **Expected**: 0 offers show the same relic on both cards across all 30.

---

## Scenario 3: Tier distribution not visibly skewed

1. Start a run. Press "Get Relic" 20 times. Tally the tier of each left card.
2. **Expected**: roughly 12 common, 6 uncommon, 2 rare (±3 tolerance) — same as before uniqueness enforcement.

---

## Scenario 4: Empty pool fallback unchanged

1. Temporarily remove all entries from `relics.json`. Start a run, press "Get Relic".
2. **Expected**: no offer screen, no error.
3. Restore `relics.json`.

# Quickstart: Relic Weighted Draws

**Feature**: 023-relic-weighted-draws
**Date**: 2026-03-03

Manual validation scenarios — run in the Godot Editor play mode.

---

## Scenario 1: Weighted distribution over many draws

1. Start a run via DevPanel.
2. Press "Get Relic" 20 times (pick any relic each time to keep the offer coming).
3. Tally the tier of each left-card draw.
4. **Expected**: roughly 12 common, 6 uncommon, 2 rare (±3 tolerance).

---

## Scenario 2: Deck reshuffle — common

1. Start a run. There are 4 common relics.
2. Press "Get Relic" repeatedly. After 4 common draws the common deck should reshuffle.
3. **Expected**: all 4 common relics can appear again after the 5th common draw — no relic is permanently gone.

---

## Scenario 3: Uncommon relics appear

1. Start a run. Press "Get Relic" 10 times.
2. **Expected**: at least one uncommon relic appears across the 20 card slots (probability of zero uncommon in 20 draws is ~(0.7)^20 ≈ 0.08% — effectively never).

---

## Scenario 4: Weight change takes effect

1. Change `meta_config.json` → `relic_tier_weights.rare` to `0.9`, `common` to `0.05`, `uncommon` to `0.05`.
2. Start a run, press "Get Relic" 10 times.
3. **Expected**: rare relics dominate the offers.
4. Restore original values.

---

## Scenario 5: Run reset clears decks

1. Start a run, take several relics.
2. End the run, start a new run.
3. Press "Get Relic".
4. **Expected**: offer draws from a fresh full deck — previously picked relics can appear again.

---

## Scenario 6: Empty pool fallback

1. Remove all entries from `relics.json` temporarily (save a backup).
2. Start a run, press "Get Relic".
3. **Expected**: no offer screen appears, no error in output.
4. Restore `relics.json`.

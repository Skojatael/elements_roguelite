# Quickstart: Close Relic Offer on Run End

**Feature**: 028-close-offer-on-run-end
**Date**: 2026-03-03

Manual validation scenarios — run in Godot Editor play mode.

---

## Scenario 1: Relic offer dismissed on player death

1. Start a run. Use DevPanel "Get Relic" to open the relic offer screen.
2. While the offer is visible, reduce player HP to 0 (or use DevPanel "End Run").
3. **Expected**: The relic offer screen disappears immediately. The results screen appears cleanly with no overlapping UI.

---

## Scenario 2: Relic offer dismissed on cash-out

1. Start a run. Open a relic offer via DevPanel "Get Relic".
2. While the offer is visible, press DevPanel "Cash Out".
3. **Expected**: Relic offer disappears. Results screen appears with no orphaned UI.

---

## Scenario 3: No relic awarded after dismissal

1. Start a run. Note the count of active relics (should be 0 at run start).
2. Open a relic offer. End the run before picking.
3. On the results screen, confirm the run ended normally.
4. Start a new run. **Expected**: No relics are active — none were collected from the dismissed offer.

---

## Scenario 4: Normal run end without open offer — no regression

1. Start a run. Clear 2 rooms (no offer open at run end — or let the offer close normally by picking a relic first).
2. End the run.
3. **Expected**: Results screen appears exactly as before. No crash, no error in Output.

---

## Scenario 5: Double-free safety

1. Start a run. Open and close a relic offer normally (pick a relic). Then end the run.
2. **Expected**: No crash or error. `_relic_offer_layer` is already null at run end; the guard is a no-op.

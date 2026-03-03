# Quickstart: DevPanel Get Relic Button

**Feature**: 022-devpanel-get-relic
**Date**: 2026-03-03

Manual validation scenarios — run in the Godot Editor play mode.

---

## Scenario 1: Happy path — offer appears during run

1. Launch game, press "Start Run" in DevPanel.
2. Press "Get Relic".
3. **Expected**: Relic offer screen appears with 2 cards. ExplorationHUD is hidden.
4. Click one card's "Choose" button.
5. **Expected**: Offer screen closes, ExplorationHUD reappears, relic is applied (stat changes visible if inspecting component values).

---

## Scenario 2: Guard — no run active

1. Launch game (hub screen, no run started).
2. Press "Get Relic".
3. **Expected**: Nothing happens. No error in output.

---

## Scenario 3: Guard — duplicate offer prevention

1. Start a run. Press "Get Relic" — offer screen appears.
2. Without picking a relic, press "Get Relic" again.
3. **Expected**: Second press is ignored. Only one offer screen visible.

---

## Scenario 4: Relic applied correctly

1. Start a run. Note player move speed (or attack damage in debugger).
2. Press "Get Relic", pick a `move_speed` relic (e.g. Fleetfoot Feather).
3. **Expected**: Player visibly moves faster after picking.

---

## Scenario 5: Consistent with room-clear offer

1. Start a run. Clear 2 rooms (natural offer triggers).
2. Pick a relic from natural offer.
3. Press "Get Relic", pick another relic.
4. **Expected**: Both relics appear in `RelicManager.active_relic_ids`. Stats reflect both.

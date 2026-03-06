# Research: Close Relic Offer on Run End

**Feature**: 028-close-offer-on-run-end
**Date**: 2026-03-03

No NEEDS CLARIFICATION items. This is a targeted bug fix. Research consists of tracing the existing code path.

---

## Finding: Where the relic offer is tracked

`Main.gd` owns the relic offer lifecycle. Two fields track it:
- `_relic_offer_layer: CanvasLayer` — the canvas layer containing the offer UI
- `_relic_offer_screen: RelicOfferScreen` — the offer screen node

Both are set to `null` after `_relic_offer_layer.queue_free()` in `_on_relic_picked()`. The layer owns the screen; freeing the layer frees the screen.

---

## Finding: The gap

`Main._on_run_ended()` creates the results screen but does not check or free `_relic_offer_layer`. If a relic offer is open when a run ends, the layer persists as an orphaned node — the results screen appears behind or alongside the still-visible offer.

---

## Decision 1: Fix location

**Decision**: Add a null-guard free block for `_relic_offer_layer` at the top of `Main._on_run_ended()`, before the results screen is created. Mirrors the existing `_hub_room` guard pattern in the same method.

**Rationale**: `Main._on_run_ended()` is the single handler for all run-end paths (death, cash-out, DevPanel). Fixing it here handles all three cases in one place.

**Alternatives considered**:
- Fixing in `RelicManager._on_run_ended()` by emitting a signal — rejected: the relic offer layer is owned by Main.gd, not RelicManager. Signal indirection adds unnecessary coupling for a one-line guard.
- Fixing in each run-end call site (DevPanel, player death, cash-out) — rejected: all three flow through `RunManager.end_run()` → `RunManager.run_ended` → `Main._on_run_ended()`, so fixing the handler is DRY.

---

## Decision 2: No relic awarded on dismissal

**Decision**: Simply call `queue_free()` on the layer — no `RelicManager.pick_relic()` call. Same as if the player never saw the offer.

**Rationale**: FR-002. The offer is cancelled by the run ending. Awarding a relic would be incorrect (relics are run-scoped and the run is ending). The relic pool state is reset by `RelicManager._on_run_ended()` anyway.

---

## Decision 3: Exploration HUD

**Decision**: No special HUD restore needed. `Main._on_run_ended()` sets `_player.visible = false` and the results screen replaces the HUD. Whether or not the HUD was hidden by the offer, the results flow takes over.

**Rationale**: The HUD state is moot once the results screen is up. FR-003 is satisfied trivially.

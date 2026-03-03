# Research: DevPanel Get Relic Button

**Feature**: 022-devpanel-get-relic
**Date**: 2026-03-03

---

## Decision 1: Where does the offer get triggered?

**Decision**: `RelicManager` exposes a new `trigger_offer()` method. Main.gd calls it from the DevPanel handler after applying the run-active and no-duplicate-screen guards.

**Rationale**: `RelicManager` already owns `draw_offer()` logic via `_impl` and already emits `relic_offer_ready`. Routing through RelicManager reuses the exact same emission path as natural room-clear offers — the offer screen has no idea whether the trigger came from a room clear or a dev button.

**Alternatives considered**: Calling `_impl.draw_offer()` directly from Main.gd — rejected because it bypasses the autoload boundary and directly couples Main to the impl.

---

## Decision 2: Where do the guards live?

**Decision**: Two guards applied in Main.gd's handler before calling `RelicManager.trigger_offer()`:
1. `not RunManager.is_run_active` → return
2. `_relic_offer_screen != null` → return (offer already visible)

**Rationale**: The run-active guard is a UI/coordinator concern — Main.gd already has all the state needed (`is_run_active`, `_relic_offer_screen`). Putting both guards in one place keeps `RelicManager.trigger_offer()` a simple, unconditional draw-and-emit, consistent with how `_on_room_cleared` already filters before calling into `_impl`.

---

## Decision 3: DevPanel signal pattern

**Decision**: Follow the existing DevPanel pattern exactly — add `signal get_relic_pressed`, `@onready var _btn_get_relic`, connect in `_ready()`, wire in Main.gd.

**Rationale**: Identical to `start_run_pressed`, `end_run_pressed`, etc. No deviation needed.

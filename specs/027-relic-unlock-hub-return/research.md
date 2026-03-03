# Research: Relic Offers Activate on Hub Return

**Feature**: 027-relic-unlock-hub-return
**Date**: 2026-03-03

No NEEDS CLARIFICATION items were present in the spec. This document records architectural decisions derived from reading the codebase.

---

## Decision 1: How "hub return" is detected

**Decision**: Add `signal hub_entered` to `autoload/GlobalSignals.gd`. `Main.gd` emits it in two places: after instantiating HubRoom in `_ready()` (initial game start) and after instantiating HubRoom in `_on_results_return()` (post-run return). `MetaManager` connects to this signal in `_ready()` and calls `_impl.try_activate_relic_offers(SaveManager)`.

**Rationale**: GlobalSignals is the established autoload for cross-system events (already used for `gameplay_started` / `gameplay_ended`). Main.gd is the only place HubRoom is instantiated, making it the correct and complete emission site. MetaManager connecting to GlobalSignals follows the same pattern as RelicManager connecting to RunManager signals.

**Alternatives considered**:
- HubRoom emitting the signal itself — rejected: HubRoom is a scene script and can't reliably reference autoloads at instantiation time; also HubRoom doesn't know it's a "return" vs first visit.
- RunManager.run_ended as the hub trigger — rejected: run_ended fires before the hub is actually shown (ResultsScreen is displayed first; hub comes after the player taps "Return"). This would activate relic offers too early — before the player actually reaches the hub.
- Polling in MetaManager._process() — rejected: polling is wasteful and fragile.

---

## Decision 2: Separate `relic_offers_active` flag (not reuse `adventurer_bag_unlocked`)

**Decision**: Add `relic_offers_active: bool = false` to MetaState. This is the flag that gates relic offer generation in RelicManager. `adventurer_bag_unlocked` remains the flag set on first elite clear (feature 026, unchanged).

**Rationale**: The two events (first elite clear, first hub return post-unlock) are distinct. Reusing one flag for both would require tracking timing in MetaManager to know "did we unlock in this run?" — fragile and stateful. Two flags keeps each state transition independent and testable. US2 backward compatibility is also cleanly handled: existing saves with `adventurer_bag_unlocked = true` and `relic_offers_active = false` activate on the next hub visit automatically.

**Alternatives considered**:
- Single flag approach (set `adventurer_bag_unlocked = true` only on hub return) — rejected: this breaks the unlock flow of feature 026 where the elite clear is the canonical unlock event. It also makes the MetaManager elite-clear handler more complex (defer the save until hub return).

---

## Decision 3: Initial game-start hub counts as a qualifying visit

**Decision**: `Main._ready()` emits `GlobalSignals.hub_entered`. If `adventurer_bag_unlocked = true` at game start (loaded from save), MetaManager immediately activates `relic_offers_active = true` on that signal.

**Rationale**: This is the US2 backward compatibility path. A player launching the game with the bag already unlocked is "in the hub" the moment `_ready()` runs. This is the simplest and most immediate resolution — no extra visit required.

**Alternatives considered**:
- MetaManager._ready() activating directly on load if both conditions met — rejected: this would activate relic offers even if the player never returns to hub (e.g., save is loaded mid-run via some recovery path in future). Using the hub_entered signal is more precise.

---

## Decision 4: RelicManager gate swapped from `is_adventurer_bag_unlocked` to `is_relic_offers_active`

**Decision**: `RelicManager._on_room_cleared()` replaces the `MetaManager.is_adventurer_bag_unlocked` check with `MetaManager.is_relic_offers_active`.

**Rationale**: `relic_offers_active` is now the correct gate — it's set only after the hub return, which is what this feature requires. `is_adventurer_bag_unlocked` is no longer directly relevant to offer generation.

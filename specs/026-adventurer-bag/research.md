# Research: Adventurer Bag

**Feature**: 026-adventurer-bag
**Date**: 2026-03-03

No NEEDS CLARIFICATION items were present in the spec. This research document records the key technical decisions derived from reading the existing codebase.

---

## Decision 1: Where elite-clear detection lives

**Decision**: `MetaManager` (autoload) connects to `RunManager.room_cleared` and reads `RunManager.current_room.room_type_id` to detect elite clears — identical to the pattern already used by `RelicManager._on_room_cleared()`.

**Rationale**: MetaManager already owns all meta-progression logic and connects to `RunManager.run_ended`. Extending it to also respond to `room_cleared` is consistent with its domain. No new autoload or signal needed.

**Alternatives considered**:
- Adding `RunManager.elite_room_cleared` signal — rejected: no other system needs it; adds coupling for no gain (YAGNI).
- Detecting in `RelicManager` and forwarding — rejected: RelicManager should not modify MetaState (SRP violation).

---

## Decision 2: Where the gate check lives

**Decision**: Gate is a single boolean guard at the top of `RelicManager._on_room_cleared()`: `if not MetaManager.is_adventurer_bag_unlocked: return`. No changes to `RelicManagerImpl`.

**Rationale**: The gate is a coordination concern between two autoloads, not algorithmic relic logic. It belongs in the autoload layer, not in the impl. One line — minimal surface.

**Alternatives considered**:
- Gate inside `RelicManagerImpl.should_offer_for_room()` with an injected flag — rejected: impl should not know about MetaManager state (SRP).
- Gate inside `RelicManager._on_run_started()` by not building the pool — rejected: pool build is harmless; deferring gating to run start is too coarse (would not gate mid-run if somehow state changes).

---

## Decision 3: Persistence

**Decision**: `MetaState` gains one field `adventurer_bag_unlocked: bool = false`. `SaveManagerImpl.save_meta_state()` and `load_meta_state()` are updated to include it. Missing key defaults to `false` — backward compatible with existing saves.

**Rationale**: Follows the exact pattern already used for `total_shards` and `damage_upgrade_level`. No new file, no schema change beyond adding one key.

**Alternatives considered**:
- Separate save file for unlock flags — rejected: over-engineering for a single boolean (YAGNI).

---

## Decision 4: No new signal for unlock event

**Decision**: No `adventurer_bag_unlocked` signal added in this feature. The unlock is silent (FR-007 defers UI). Signal can be added in the UI feature.

**Rationale**: YAGNI. No current consumer of the signal exists.

---

## Decision 5: MetaManagerImpl owns the unlock logic

**Decision**: `MetaManagerImpl` gets `unlock_adventurer_bag(save_manager: Node) -> bool` — returns `true` if this call actually changed state (i.e., was first unlock), `false` if already unlocked. `MetaManager` autoload calls it and prints a log line.

**Rationale**: Follows the thin-wrapper rule (Constitution I). All algorithmic logic stays in the impl.

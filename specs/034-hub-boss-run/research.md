# Research: Hub Boss Run (034)

## Decision 1: Run mode detection for boss-mode gating

**Decision**: Read `RunManager.run_mode` directly at call sites (MetaManager, Main) to branch boss vs. endless behaviour.

**Rationale**: `run_mode` is set in `start_run()` and remains valid until the next call, so it is always readable during `_on_room_cleared()`, `_on_run_ended()`, and `_on_boss_room_cleared()`. No new signal or field is needed.

**Alternatives considered**: Adding `run_mode` to `RunSummary` — rejected (summary is read-only after creation; current callers already have RunManager in scope).

---

## Decision 2: Endless boss kill counter — separate field vs. reusing first_boss_killed

**Decision**: New `endless_boss_kill_count: int` field on MetaState. Existing `first_boss_killed: bool` is unchanged.

**Rationale**: The two track different things — `first_boss_killed` gates AdventuringGear (fires once, never resets), `endless_boss_kill_count` counts cumulative kills (fires many times, gates BossRunShop at ≥ 3). They are independent invariants.

**Alternatives considered**: Deriving count from `first_boss_killed` alone — impossible (bool carries no count). Combining into a single int and inferring `first_boss_killed` from count > 0 — rejected (risks breaking existing AdventuringGear logic that reads the bool directly from MetaManager).

---

## Decision 3: Shard award timing — on boss kill vs. on run end

**Decision**: 35 shards awarded in `MetaManager._on_run_ended()` when `run_mode == "boss"` and `reason == CASH_OUT`. Not awarded at the moment of boss kill.

**Rationale**: Keeps the shard award in the same place as the normal essence→shard conversion. The boss victory overlay Cash Out button triggers `RunManager.end_run(CASH_OUT)`, which fires `run_ended`, which MetaManager handles. No new signal path needed.

**Alternatives considered**: Awarding shards inside `Main._on_boss_cash_out_pressed()` directly — rejected (violates thin-wrapper rule; MetaManager owns shard mutation, not Main).

---

## Decision 4: Hub UI — two separate scenes (Shop + Button)

**Decision**: `BossRunShop` (unlock purchase control, visible when kill_count ≥ 5 AND !boss_run_unlocked) and `BossRunButton` (run trigger control, visible when boss_run_unlocked) are separate scripts and scenes.

**Rationale**: Mirrors the existing pattern of `AdventuringGearShop` (purchase) and `TeleportDoor` (gameplay trigger). Keeps each scene to one responsibility (Constitution I). Neither scene needs to know the other exists.

**Alternatives considered**: Single combined scene that shows either the unlock or the run button — rejected (two visibility states in one scene adds conditional logic that violates SRP).

---

## Decision 5: BossRunShop visibility refresh trigger

**Decision**: `BossRunShop._ready()` connects to both `MetaManager.shards_changed` and `GlobalSignals.hub_entered` to call `_update_visibility()`.

**Rationale**: `shards_changed` covers the purchase event (boss_run_unlocked set → shards reduced → visibility hides shop). `hub_entered` covers the return-to-hub case after an endless run that may have incremented `endless_boss_kill_count`. `BossRunButton` only needs `shards_changed` (visibility depends solely on `boss_run_unlocked`, which only changes on purchase).

**Alternatives considered**: Polling in `_process()` — rejected (unnecessary overhead). New MetaManager signal — rejected (YAGNI; two existing signals cover all transition points cleanly).

---

## Decision 6: BossRunButton wiring to Main

**Decision**: `BossRunButton` emits `boss_run_pressed`. `HubRoom` re-emits as `hub_boss_run_pressed`. `Main` connects to `hub_boss_run_pressed` after hub instantiation and calls `_on_hub_boss_run_pressed()`, which starts the run and delegates to `_on_boss_teleport_pressed()`.

**Rationale**: Mirrors the existing `TeleportDoor → hub_exited → Main._on_hub_exited()` chain exactly. HubRoom queues itself free when re-emitting (same as hub_exited), so Main's `_hub_room` reference is nulled immediately.

---

## Decision 7: Dev panel boss run — no change

**Decision**: Dev panel's `_on_dev_start_boss()` continues to call `start_run("endless")`. Only the new hub button uses `"boss"` mode.

**Rationale**: Dev panel is a debug tool; keeping it in endless mode allows testing the full endless-boss-reward path independently. This is intentional. The new feature adds "boss" mode as a separate hub entry point.

---

## Decision 8: Config values in meta_config.json

**Decision**: Add three keys to `data/meta_config.json`: `boss_run_kill_threshold: 3`, `boss_run_cost: 300`, `boss_run_shard_award: 35`.

**Rationale**: All balance values must be in JSON (Constitution II). MetaManager and hub scripts read from `ResourceManager.get_meta_config()` rather than hardcoding.

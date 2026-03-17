# Tasks: Alchemy Lab — Essence Condenser Upgrade

**Input**: Design documents from `/specs/045-shard-generator/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Config update that all subsequent tasks depend on.

- [X] T001 Update `data/meta_config.json` — add `shard_generator` block under `alchemy_lab.upgrades`: `{ "name": "Essence Condenser", "base_cost": 600, "cost_scale": 2.0, "max_levels": 3, "rates_per_hour": [2, 3, 5] }`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data model, persistence, and impl logic that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Write GUT unit tests for new `MetaManagerImpl` methods in `tests/unit/test_shard_generator.gd` — cover: `get_shard_rate_per_hour()` (returns 0.0 at level 0; returns `float(rates[0])` at level 1; returns `float(rates[2])` at level 3), `tick_shard_generator()` (returns 0 at level 0; accumulates fractional shards correctly; drains whole shards from accumulator and returns count; does not double-count remainder), `apply_offline_shards()` (returns 0 at level 0; returns 0 when timestamp is 0; credits correct shards for 1-hour elapsed; caps at cap_seconds; returns 0 for zero/negative elapsed), `purchase_shard_generator()` (deducts gold and increments level on success; returns false at max level 3; returns false when gold insufficient; returns false when gold exactly one below cost) — use inline MetaState + StubSaveManager, no autoloads
- [X] T003 [P] Add two fields to `scripts/data_models/MetaState.gd`: `var shard_generator_level: int = 0` and `var shard_accumulator: float = 0.0`
- [X] T004 Update `scripts/managers/SaveManager.gd` — in `save_meta_state()` add `"shard_generator_level": state.shard_generator_level` and `"shard_accumulator": state.shard_accumulator` to the dict; in `load_meta_state()` add `state.shard_generator_level = int(parsed.get("shard_generator_level", 0))` and `state.shard_accumulator = float(parsed.get("shard_accumulator", 0.0))` (depends on T003)
- [X] T005 Add four methods to `scripts/managers/MetaManager.gd` (MetaManagerImpl): `get_shard_rate_per_hour(rates: Array) -> float` (returns `float(rates[shard_generator_level - 1])` when level > 0 else 0.0); `tick_shard_generator(delta: float, rates: Array) -> int` (gates on level > 0, accumulates `delta × rate / 3600`, drains floor, returns whole shards earned); `apply_offline_shards(now_unix: int, rates: Array, cap_seconds: int, save_manager: Node) -> int` (gates on level > 0 and timestamp != 0 and elapsed > 0; computes `floori(float(mini(elapsed, cap_seconds)) × rate / 3600.0)`; calls `add_shards(earned, save_manager)` if earned > 0; returns earned); `purchase_shard_generator(cost: int, max_levels: int, save_manager: Node) -> bool` (guard level >= max_levels → false; `spend_gold(float(cost), save_manager)` → false on fail; increment level; `_save(save_manager)`; return true) — all methods use early-return guard clauses (depends on T001, T003)
- [X] T006 Update `autoload/MetaManager.gd` — add computed property `var shard_generator_rate: float` (reads `alchemy_lab.upgrades.shard_generator.rates_per_hour` from config, delegates to `_impl.get_shard_rate_per_hour(rates)`); add `get_next_shard_generator_cost() -> int` (reads `base_cost`/`cost_scale`/`max_levels`, returns `_impl.get_upgrade_cost(meta_state.shard_generator_level, base_cost, cost_scale)` or 0 if maxed); add `purchase_shard_generator() -> bool` (reads config, delegates to `_impl.purchase_shard_generator`, emits `gold_changed` and `shards_changed` on success); in `_ready()` insert `_impl.apply_offline_shards(now, rates, cap_seconds, SaveManager)` **before** the existing `apply_offline_gold` call, emit `shards_changed` if return > 0; in `_process()` add shard tick: read rates from config, call `_impl.tick_shard_generator(delta, rates)`, if earned > 0 call `_impl.add_shards(earned, SaveManager)` and emit `shards_changed(meta_state.total_shards)` (depends on T005)

**Checkpoint**: Foundation ready — GUT tests should pass; MetaManager exposes all new methods; offline and live ticks functional.

---

## Phase 3: User Story 1 — Purchase First Level of Essence Condenser (Priority: P1) 🎯 MVP

**Goal**: The Alchemy Lab upgrade screen shows the Essence Condenser entry with cost and rate; the button enables when the player can afford it; purchasing deducts gold and advances the level.

**Independent Test**: Open Alchemy Lab with ≥ 600 gold → button shows "Essence Condenser 2/hr (Lv1) — 600 gold" and is enabled → purchase → gold deducted by 600, button updates to show level 2 cost (1200 gold).

- [X] T007 [US1] Update `scenes/hub/LabUpgradeScreen.gd` — add `@export var _shard_gen_button: Button`; in `_ready()` connect `_shard_gen_button.pressed.connect(_on_shard_gen_pressed)`; add `_update_shard_gen_button()` call inside `_update_buttons()`; implement `_update_shard_gen_button()`: read `alchemy_lab.upgrades.shard_generator` from config; if `level >= max_levels` set text to `"{name} — MAX"` and disable; otherwise compute `cost = MetaManager.get_next_shard_generator_cost()`, `rate = rates_per_hour[level]`, set text to `"{name} {rate}/hr (Lv{lv}) — {cost} gold"`, disable if `not MetaManager.can_spend_gold(float(cost))`; implement `_on_shard_gen_pressed()`: call `MetaManager.purchase_shard_generator()` then `_update_buttons()` (depends on T006)

**Checkpoint**: User Story 1 fully functional. Purchase flow works end-to-end.

---

## Phase 4: User Story 2 — Passive Shard Accumulation While Playing (Priority: P2)

**Goal**: With the upgrade owned, the shard balance increases at the configured rate while the game is running.

**Independent Test**: Own level 1. For fast testing, temporarily set `rates_per_hour[0]` to `7200` in config (= 2 shards/second); observe shard balance incrementing on screen.

- [ ] T008 [US2] Validate in-session shard tick — no code changes expected; confirm `MetaManager._process()` tick (added in T006) credits shards at the rate specified in config by following quickstart.md scenario 4; if any discrepancy found, fix the `tick_shard_generator` call in `autoload/MetaManager.gd`

**Checkpoint**: User Story 2 confirmed. Live tick produces correct shard rate.

---

## Phase 5: User Story 3 — Offline Shard Accumulation (Priority: P3)

**Goal**: Shards earned while the game is closed are credited on startup using the shared Gold Storage cap.

**Independent Test**: Own level 2 (3/hr). Edit save: subtract 3600 from `gold_last_saved_timestamp`. Reopen game. Confirm +3 shards added.

- [ ] T009 [US3] Validate offline shard credit — no code changes expected; follow quickstart.md scenarios 5 and 6; confirm shards credited on startup equal `floor(rate × elapsed_hours)` up to Gold Storage cap; confirm both gold and shards share the same elapsed-time window; if any issue found, fix `apply_offline_shards` call ordering in `autoload/MetaManager.gd._ready()`

**Checkpoint**: User Story 3 confirmed. Offline credit correct and capped.

---

## Phase 6: User Story 4 — Upgrade to Level 2 and Level 3 (Priority: P4)

**Goal**: Players can purchase all three levels at the correct doubling costs; MAX state is terminal.

**Independent Test**: Start at level 1 with ≥ 2400 gold → purchase level 2 (−1200) → purchase level 3 (−2400) → button shows MAX.

- [ ] T010 [US4] Validate multi-level purchase — no code changes expected; follow quickstart.md scenario 7; confirm costs 600 / 1200 / 2400 and MAX state; total gold spent = 4200

**Checkpoint**: User Story 4 confirmed. All levels purchasable with correct doubling costs.

---

## Phase 7: User Story 5 — Persistence Across Sessions (Priority: P5)

**Goal**: Upgrade level and shard accumulator survive a game restart.

**Independent Test**: Purchase level 2, close game, reopen — Alchemy Lab shows level 2, next cost is 2400.

- [ ] T011 [US5] Validate persistence — no code changes expected; follow quickstart.md scenario 8; confirm `shard_generator_level` and gold deductions survive restart; also confirm `shard_accumulator` is preserved (open save file and check field exists after purchasing)

**Checkpoint**: User Story 5 confirmed. Zero persistence regressions.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T012 Run all quickstart.md validation scenarios end-to-end — follow each of the 9 scenarios in `specs/045-shard-generator/quickstart.md` in order; confirm all pass; run GUT test suite and confirm all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on T001 (config must exist before impl reads it) — blocks all user stories
- **Phase 3 (US1)**: Depends on Phase 2 complete (needs `purchase_shard_generator` on MetaManager and button wiring)
- **Phase 4 (US2)**: Depends on T006 (_process tick wired) — can validate once T006 done
- **Phase 5 (US3)**: Depends on T006 (_ready offline call wired)
- **Phase 6 (US4)**: Depends on Phase 3 (same purchase path, needs button)
- **Phase 7 (US5)**: Depends on T004 (SaveManager fields) and Phase 3
- **Phase 8 (Polish)**: Depends on all prior phases

### Within Phase 2

```text
T001 (config)  ─┐
T002 (tests)   ─┤ → T005 (impl) → T006 (autoload) → Phase 3
T003 (fields)  ─┘ → T004 (save)
```

T002 and T003 are parallel starts. T004 depends on T003. T005 depends on T001 and T003.

---

## Parallel Opportunities

```text
# Phase 2 parallel start:
T002 (tests)     ─┐
T003 (MetaState) ─┘ both startable immediately after T001

# T004 (SaveManager) after T003
# T005 (MetaManagerImpl) after T001 + T003
# T006 (autoload) after T005
# T007 (LabUpgradeScreen) after T006

# US2 / US3 / US4 / US5 are validation-only — no new files, no parallelism risk
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 — Config
2. T002, T003, T004, T005, T006 — Foundational
3. T007 — US1 button wiring
4. **STOP and VALIDATE**: Purchase flow works, gold deducted, button shows correct state

### Incremental Delivery

1. Phase 1 + 2 → backend ready (purchase API, tick, offline all live)
2. Phase 3 → US1 purchasable in UI → playable MVP
3. Phase 4 → US2 confirmed (tick already live, just validation)
4. Phase 5 → US3 confirmed (offline already live, just validation)
5. Phase 6–7 → US4/US5 confirmed (already live, just validation)

---

## Notes

- Total tasks: **12**
- Code tasks: 7 (T001–T007); validation tasks: 4 (T008–T011); polish: 1 (T012)
- GUT test task (T002) is MANDATORY — `MetaManagerImpl` gains 4 new testable methods
- `apply_offline_shards` MUST be called before `apply_offline_gold` in `_ready()` (shared timestamp dependency — see research.md Decision 2)
- `shard_accumulator` is persisted in save file to prevent sub-shard progress loss on restart

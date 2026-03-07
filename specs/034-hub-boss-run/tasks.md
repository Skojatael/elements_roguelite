# Tasks: Hub Boss Run (034)

**Input**: Design documents from `/specs/034-hub-boss-run/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: No automated tests — manual validation via quickstart.md checklist.

**Organization**: Tasks grouped by user story. US3 (death path) and US4 (flag isolation) have no unique implementation tasks — they are covered by tasks in US1 and US2 phases (noted explicitly).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story this task belongs to

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data layer must come first (Constitution II: data before code). All three tasks touch different files and can be done in parallel.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 [P] Add `boss_run_kill_threshold: 3`, `boss_run_cost: 300`, `boss_run_shard_award: 35` to `data/meta_config.json`
- [x] T002 [P] Add `endless_boss_kill_count: int = 0` and `boss_run_unlocked: bool = false` fields to `scripts/data_models/MetaState.gd`
- [x] T003 [P] Extend `scripts/managers/SaveManager.gd` — add `endless_boss_kill_count` and `boss_run_unlocked` to both `save_meta_state()` dict and `load_meta_state()` `.get()` calls (backward compatible, defaults 0/false)

**Checkpoint**: Data layer ready — user story implementation can begin.

---

## Phase 2: User Story 1 — Unlock Boss Run Feature (Priority: P1) 🎯

**Goal**: Players who have 3+ endless boss kills can spend 300 shards to permanently unlock the Boss Run button. The BossRunShop appears in the hub when gated conditions are met.

**Independent Test**: After manually setting `endless_boss_kill_count = 3` in save file, BossRunShop becomes visible on hub load. Pressing it deducts 300 shards and hides the shop permanently (persists after restart).

- [x] T004 [US1] Add `increment_endless_boss_kills(save_manager: Node) -> void` and `purchase_boss_run(cost: int, save_manager: Node) -> bool` methods to `scripts/managers/MetaManager.gd` (MetaManagerImpl). `purchase_boss_run` guards on `boss_run_unlocked` already true (returns false) and insufficient shards.
- [x] T005 [US1] Update `autoload/MetaManager.gd`: add `is_boss_run_unlocked: bool` property (getter), `endless_boss_kill_count: int` property (getter), `purchase_boss_run() -> bool` method (reads `boss_run_cost` from config, delegates to impl, emits `shards_changed` on success). Also modify `_on_room_cleared()`: in the `boss_room` branch, add early return `if RunManager.run_mode != "endless": return` before calling `record_boss_kill()` and add `_impl.increment_endless_boss_kills(SaveManager)` call after `record_boss_kill()`.
- [x] T006 [US1] Create `scenes/hub/BossRunShop.gd`: `class_name BossRunShop extends Control`. Export `_button: Button`. `_ready()` connects `_button.pressed` → `_on_buy_pressed()`, connects `MetaManager.shards_changed` lambda → `_update_visibility()`, connects `GlobalSignals.hub_entered` lambda → `_update_visibility()`, calls `_update_visibility()`. `_update_visibility()` reads `boss_run_kill_threshold` from `ResourceManager.get_meta_config()` and sets `visible = MetaManager.endless_boss_kill_count >= threshold and not MetaManager.is_boss_run_unlocked`. `_on_buy_pressed()` calls `MetaManager.purchase_boss_run()` then `_update_visibility()`.
- [ ] T007 [US1] **[Editor]** Create `scenes/hub/BossRunShop.tscn`: `Control` root node → attach `BossRunShop.gd` → add `Button` child → assign `_button` export to the Button in Inspector.
- [ ] T008 [US1] **[Editor]** Add `BossRunShop.tscn` as a child of `scenes/hub/HubRoom.tscn` in the Godot Editor. Position it appropriately in the hub layout.

**Checkpoint**: BossRunShop visible after 3 endless kills, purchase deducts 300 shards, shop hides permanently. Verify with save file edit.

---

## Phase 3: User Story 2 — Boss Run and Cash Out (Priority: P2)

**Goal**: Players with Boss Run unlocked see the Boss Run button in the hub. Pressing it starts a "boss" mode run directly in the boss room. Killing the boss shows only the Cash Out button. Cash Out awards exactly 35 shards.

**Independent Test**: With `boss_run_unlocked = true` in save, BossRunButton appears. Press it → placed in boss room. Kill boss → victory overlay with Cash Out only (Continue hidden). Press Cash Out → shard balance increases by 35. Results screen shows. Return to hub.

- [x] T009 [US2] Update `autoload/MetaManager.gd` — modify `_on_run_ended()`: add early branch at top: `if RunManager.run_mode == "boss": if reason == RunManager.EndReason.CASH_OUT: add_shards(boss_run_shard_award from config). print log. return.` This also covers US3 (DIED path returns without adding shards) and skips the essence→shard conversion for all boss mode endings.
- [x] T010 [P] [US2] Create `scenes/hub/BossRunButton.gd`: `class_name BossRunButton extends Control`. Signal `boss_run_pressed`. Export `_button: Button`. `_ready()` connects `_button.pressed` → `_on_pressed()`, connects `MetaManager.shards_changed` lambda → `_update_visibility()`, calls `_update_visibility()`. `_update_visibility()` sets `visible = MetaManager.is_boss_run_unlocked`. `_on_pressed()`: early return `if RunManager.is_run_active: return`, then `boss_run_pressed.emit()`.
- [x] T011 [P] [US2] Add `func setup(show_continue: bool) -> void` to `scenes/ui/boss_victory/BossVictoryOverlay.gd`. Body: `_continue_button.visible = show_continue`. No other changes to this file.
- [x] T012 [US2] Update `scenes/hub/HubRoom.gd`: add `signal hub_boss_run_pressed`, add `@export var _boss_run_button: BossRunButton`, add to `_ready()`: `_boss_run_button.boss_run_pressed.connect(_on_boss_run_pressed)`, add `func _on_boss_run_pressed() -> void: hub_boss_run_pressed.emit() \n queue_free()`.
- [x] T013 [US2] Update `scenes/core/main.gd`: (a) In both `_ready()` and `_on_results_return()`, after `add_child(_hub_room)`, add `_hub_room.hub_boss_run_pressed.connect(_on_hub_boss_run_pressed)`. (b) Add `func _on_hub_boss_run_pressed() -> void: _hub_room = null \n RunManager.start_run("boss") \n GlobalSignals.gameplay_started.emit() \n _on_boss_teleport_pressed()`. (c) In `_show_boss_victory_overlay()`, after `add_child(_boss_victory_overlay)`, add `_boss_victory_overlay.setup(RunManager.run_mode == "endless")` before connecting signals. (d) Modify `_on_boss_room_cleared()`: move `_exploration_hud.visible = false` before the mode check; wrap the essence reward + relic offer block in `if RunManager.run_mode == "endless":`, with `_show_boss_victory_overlay()` as the unconditional final call.
- [ ] T014 [US2] **[Editor]** Create `scenes/hub/BossRunButton.tscn`: `Control` root → attach `BossRunButton.gd` → add `Button` child → assign `_button` export in Inspector.
- [ ] T015 [US2] **[Editor]** Add `BossRunButton.tscn` as a child of `scenes/hub/HubRoom.tscn`. Assign the BossRunButton instance to the `_boss_run_button` export on HubRoom in the Inspector.

**Checkpoint**: Full boss run loop works. BossRunButton visible when unlocked. Boss room loads directly. Victory overlay shows Cash Out only. 35 shards awarded on cash-out.

---

## Phase 4: User Story 3 — Death in Boss Run (Priority: P3)

**No unique implementation tasks.** Covered by T009: `_on_run_ended()` boss mode branch returns without adding shards when reason is `DIED`.

**Verify**: Start boss run, take hits until dead. Run ends → results screen. Shard balance unchanged.

---

## Phase 5: User Story 4 — Isolation from Meta-Progression Flags (Priority: P4)

**No unique implementation tasks.** Covered by:
- T005: `_on_room_cleared()` mode guard — boss_room cleared in "boss" mode skips `record_boss_kill()` and `increment_endless_boss_kills()`.
- T009: `_on_run_ended()` boss mode branch — skips essence→shard conversion entirely.

**Verify**: Complete a boss run victory with `first_boss_killed = false` in save. After run: `first_boss_killed` still false, `endless_boss_kill_count` unchanged, Adventuring Gear shop not shown.

---

## Phase 6: Polish

- [x] T016 Update `repo_map.md`: add `endless_boss_kill_count`, `boss_run_unlocked` to MetaState fields; add `is_boss_run_unlocked`, `endless_boss_kill_count`, `purchase_boss_run()` to MetaManager autoload; add `increment_endless_boss_kills`, `purchase_boss_run` to MetaManagerImpl methods; add `hub_boss_run_pressed` signal and `_boss_run_button` export to HubRoom; add BossRunShop and BossRunButton entries under Scenes — Hub; add `setup(show_continue)` to BossVictoryOverlay.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately. All three tasks [P].
- **US1 (Phase 2)**: Depends on T001, T002, T003 complete.
- **US2 (Phase 3)**: Depends on T004, T005 complete (BossRunButton reads MetaManager API).
- **US3/US4 (Phases 4–5)**: No work — validated after US1+US2.
- **Polish (Phase 6)**: After all implementation tasks complete.

### User Story Dependencies

- **US1**: Depends on Foundational only.
- **US2**: Depends on US1 (T004, T005) — BossRunButton reads `is_boss_run_unlocked`; `_on_run_ended()` uses impl methods established in US1. T010, T011 can be written in parallel while T004/T005 are in progress (different files).
- **US3, US4**: No implementation — depend on US1+US2 being complete for verification.

### Within Each Phase

- T004 → T005 (autoload delegates to impl)
- T005 → T006 (BossRunShop reads MetaManager API)
- T006 → T007 → T008 (script before scene before adding to HubRoom)
- T010, T011 can be done in parallel during US2 (different files)
- T010 → T009 is independent (different methods)
- T012 → T013 (HubRoom signal before Main connects to it)
- T014 → T015 (scene before adding to HubRoom)

---

## Parallel Opportunities

```
Phase 1 — run together:
  T001 data/meta_config.json
  T002 scripts/data_models/MetaState.gd
  T003 scripts/managers/SaveManager.gd

Phase 3 US2 — run together (while T012/T013 are pending):
  T010 scenes/hub/BossRunButton.gd
  T011 scenes/ui/boss_victory/BossVictoryOverlay.gd
```

---

## Implementation Strategy

### MVP (US1 only — unlock gate)

1. Complete Phase 1 (T001–T003)
2. Complete Phase 2 (T004–T008)
3. Validate: BossRunShop appears after 3 kills, purchase works, persists

### Full Feature

4. Complete Phase 3 (T009–T015)
5. Validate: Full boss run loop, 35 shards cash-out, Continue button hidden
6. Verify US3 and US4 (manual play testing)
7. Complete T016 (repo_map)

---

## Notes

- Editor tasks (T007, T008, T014, T015) require the Godot Editor — they cannot be scripted.
- T013 touches `main.gd` in 4 places; read the full file before editing to avoid conflicts.
- T005 and T009 both modify `autoload/MetaManager.gd` — complete T005 before T009 to avoid merge conflicts.
- `[P]` tasks touch different files with no shared dependencies — safe to implement concurrently.

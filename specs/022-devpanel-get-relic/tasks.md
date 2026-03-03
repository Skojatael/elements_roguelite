# Tasks: DevPanel Get Relic Button

**Input**: Design documents from `specs/022-devpanel-get-relic/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: User Story 1 — Trigger Relic Offer from DevPanel (Priority: P1) 🎯 MVP

**Goal**: Developer can press "Get Relic" during an active run and see the relic offer screen.

**Independent Test**: Start run via DevPanel → press "Get Relic" → offer screen appears with 2 cards → pick one → relic applied.

- [X] T001 [P] [US1] Add `trigger_offer()` method to `autoload/RelicManager.gd` — draws from `_impl.draw_offer()` and emits `relic_offer_ready`; prints `[RelicManager] trigger_offer — pool empty, no offer` if pool is empty
- [X] T002 [P] [US1] Add `signal get_relic_pressed` and `@onready var _btn_get_relic: Button = $PanelContainer/VBoxContainer/GetRelic` to `scenes/ui/dev/DevPanel.gd`; connect `_btn_get_relic.pressed.connect(get_relic_pressed.emit)` in `_ready()`
- [X] T003 [US1] Add `panel.get_relic_pressed.connect(_on_dev_get_relic)` inside the `DEV_MODE` block in `scenes/core/Main.gd` `_ready()`, and add handler `_on_dev_get_relic()` with run-active and no-duplicate-screen guards before calling `RelicManager.trigger_offer()`
- [ ] T004 [US1] [EDITOR] Add `Button` node named `GetRelic` (text: "Get Relic") inside `PanelContainer/VBoxContainer` in `scenes/ui/dev/DevPanel.tscn`, after the existing buttons

**Checkpoint**: All 5 quickstart scenarios pass.

---

## Phase 2: Polish

- [ ] T005 Run all 5 quickstart scenarios from `specs/022-devpanel-get-relic/quickstart.md`

---

## Dependencies & Execution Order

- T001 and T002 are parallel (different files, no dependencies between them)
- T003 depends on T001 and T002 (connects the signal and calls the new method)
- T004 (editor task) can be done any time before running the game
- T005 requires T001–T004 complete

---

## Implementation Strategy

1. T001 + T002 in parallel
2. T003 after both complete
3. T004 in Godot Editor
4. T005 validate

# Tasks: Hub Shard Display

**Input**: Design documents from `specs/017-hub-shard-display/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup

No shared infrastructure required. `MetaManager` (autoload) and `HubRoom.tscn` are pre-existing.

---

## Phase 2: User Story 1 — See Shard Total in Hub (Priority: P1) 🎯 MVP

**Goal**: A shard counter overlay appears in the hub, reading `MetaManager.meta_state.total_shards` and displaying `"Shards: N"`.

**Independent Test**: Launch game → enter hub → confirm `"Shards: N"` label is visible. Complete a run → return to hub → confirm displayed value matches the `[MetaManager] N shards earned — total=M` log line.

### Implementation

- [X] T001 [US1] Create `scenes/hub/ShardDisplay.gd` — `extends Control`, `@export var _label: Label`, `_ready()` sets `_label.text = "Shards: {n}".format({"n": MetaManager.meta_state.total_shards})`
- [ ] T002 [US1] [EDITOR] In Godot Editor open `HubRoom.tscn`: add `ShardDisplayLayer` (CanvasLayer) child → add `ShardDisplay` (Control) child of layer and attach `ShardDisplay.gd` → add `Label` child of ShardDisplay → in Inspector assign `_label` export to the Label node → set Mouse Filter = Ignore on both ShardDisplay and Label nodes

**Checkpoint**: Hub displays shard total immediately on load. Overlay is absent during runs automatically (ShardDisplay is freed with HubRoom when the run starts).

---

## Phase 3: User Story 2 — Overlay Hidden During Runs (Priority: P2)

**Goal**: Shard overlay is not visible during dungeon exploration.

**Independent Test**: Start a run → confirm no shard overlay on screen. End run → return to hub → confirm overlay reappears with correct total.

**Note**: US2 is satisfied architecturally at zero implementation cost. `ShardDisplay` lives inside `HubRoom.tscn` and is freed automatically when HubRoom is freed at run start (see research.md Decision 1). No separate code task required — validated in Phase 4.

**Checkpoint**: Covered by T001 + T002 design; confirmed in T003 (Scenario 3).

---

## Phase 4: Polish & Validation

- [ ] T003 Manual validation — run all 6 scenarios in `specs/017-hub-shard-display/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **T001** (script): No dependencies — start immediately
- **T002** (editor): Requires T001 complete (script must exist to attach to Control node)
- **T003** (validation): Requires T001 and T002 complete

### Parallel Opportunities

None — tasks are strictly sequential: script → editor wiring → validation.

---

## Implementation Strategy

### MVP (US1 only — sufficient for both stories)

1. T001: Write `ShardDisplay.gd`
2. T002: Wire node hierarchy in Godot Editor
3. T003: Manual validation (covers US1 Scenarios 1–2, US2 Scenarios 3–6)

US2 requires no additional code. Scenario 3 (overlay absent during run) and Scenario 4 (overlay returns) in quickstart.md are the US2 acceptance tests.

---

## Notes

- T002 is a Godot Editor task — cannot be scripted; must be performed in the editor UI.
- Mouse Filter = Ignore on both `ShardDisplay` and `Label` prevents touch interception on TeleportDoor (FR-002 constraint).
- US2 is zero-cost: no signals, no visibility toggles, no manager wiring required.

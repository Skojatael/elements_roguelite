# Tasks: Enemy Detection Radius

**Input**: Design documents from `/specs/049-enemy-detection-radius/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks grouped by user story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

---

## Phase 1: Setup

No setup required — `detection_range` already exists in `enemies.json` and is already parsed by `EnemyData`. No new files, no schema changes.

---

## Phase 2: Foundational

No foundational work required — all prerequisites already exist.

---

## Phase 3: User Story 1 — Enemy Detects Player at Correct Range (Priority: P1) 🎯 MVP

**Goal**: Each enemy's `DetectionArea` collision shape radius is set from `EnemyData.detection_range` at spawn time. Invalid values log a warning and fall back to 300px.

**Independent Test**: Spawn a slime (detection_range 800). Stand 850px away — enemy stays idle. Move to 799px — enemy begins pursuing. Change detection_range to 400 in enemies.json, rerun — enemy now activates at 400px with no other files changed.

### Implementation for User Story 1

- [x] T001 [US1] Add `const DETECTION_RANGE_FALLBACK: float = 300.0` and `func _apply_detection_range(range_px: float) -> void` to `scenes/combat/enemies/Enemy.gd` — get `_detection_area.get_node("CollisionShape2D") as CollisionShape2D`, cast its `shape` to `CircleShape2D` and set `radius = effective`; if `range_px <= 0.0` push a warning using `"Enemy: invalid detection_range={r} for id={id} — using fallback {f}".format(...)` and set `effective = DETECTION_RANGE_FALLBACK`

- [x] T002 [US1] Call `_apply_detection_range(data.detection_range)` at the end of `func initialize(data: EnemyData)` in `scenes/combat/enemies/Enemy.gd`

**Checkpoint**: US1 and US2 are both satisfied — the detection radius is data-driven and changing the JSON value changes behaviour with no other edits.

---

## Phase 4: Polish & Cross-Cutting Concerns

- [x] T003 Update `repo_map.md` — in the `Enemy.gd` entry add `const DETECTION_RANGE_FALLBACK` and `_apply_detection_range(range_px: float)` to the methods list

---

## Dependencies & Execution Order

- T001 before T002 (method must exist before it is called)
- T003 after T001 and T002

---

## Implementation Strategy

### MVP (single increment)

1. T001 — add helper method
2. T002 — call it from `initialize()`
3. T003 — repo map

All three tasks are sequential and fast. No parallel opportunities (single file for T001+T002).

---

## Notes

- No unit tests generated: `Enemy.gd` is a scene script (not `*Impl.gd`), no `static func`, no pure-computation methods — none of the mandatory test triggers apply
- US2 (designer tunes data) is satisfied automatically by US1's implementation — no separate tasks needed
- Shape resource mutation is safe per-instance: `PackedScene.instantiate()` deep-copies `local_to_scene` resources (Godot 4 default for collision shapes)

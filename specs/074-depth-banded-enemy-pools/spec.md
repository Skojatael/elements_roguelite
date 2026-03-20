# Feature Specification: Depth-Banded Enemy Pools

**Feature Branch**: `074-depth-banded-enemy-pools`
**Created**: 2026-03-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Shallow Rooms Feel Easy and Readable (Priority: P1)

At depth 1, the player fights mostly the same enemy type (forest_tank) with only a rare chance of a different enemy appearing in the third slot. At depth 2, the fourth slot always contains a disruptor and the third slot has a 50/50 chance of a healer instead of a tank. The player perceives a clear, gradual escalation of threat as they push deeper.

**Why this priority**: Core gameplay feel — the depth-banded tables are the main deliverable of this feature. If shallow rooms spawn the right enemies, the feature is meaningfully validated.

**Independent Test**: Start a run; clear depth-1 rooms across multiple runs and observe that ~90% of third-slot enemies are forest_tank and ~10% are forest_disruptor. Clear depth-2 rooms and observe that the fourth slot is always forest_disruptor and the third slot is roughly half forest_tank / half forest_healer over many attempts.

**Acceptance Scenarios**:

1. **Given** a depth-1 combat room, **When** it spawns, **Then** slots 1 and 2 always contain forest_tank; slot 3 contains forest_tank with 90% probability and forest_disruptor with 10% probability.
2. **Given** a depth-2 combat room, **When** it spawns, **Then** slots 1–2 are always forest_tank; slot 3 is forest_tank (50%) or forest_healer (50%); slot 4 is always forest_disruptor.
3. **Given** a room at depth 1 or 2, **When** it spawns, **Then** enemies not in the correct depth band never appear.

---

### User Story 2 — Mid-Depth Rooms Add Wave Complexity (Priority: P2)

At depths 3–4, combat rooms introduce a two-wave structure. Wave 0 always spawns a fixed four-enemy group. Wave 1 adds one guaranteed tank plus one slot that randomly draws from a pool of four enemies (healer 10%, poisoner 10%, disruptor 10%, tank 70%).

**Why this priority**: Validates the wave-level depth banding, the more complex data structure, and that wave timing still works correctly with pooled enemy types.

**Independent Test**: Play through depth-3 and depth-4 rooms. Confirm wave 0 always has exactly forest_tank × 2, forest_healer × 1, forest_disruptor × 1. Confirm wave 1 always has forest_tank in slot 1; over many attempts the second slot distributes roughly 70/10/10/10.

**Acceptance Scenarios**:

1. **Given** a depth-3 or depth-4 combat room, **When** wave 0 spawns, **Then** exactly: forest_tank, forest_tank, forest_healer, forest_disruptor appear (always fixed).
2. **Given** a depth-3 or depth-4 combat room, **When** wave 1 spawns, **Then** slot 1 is always forest_tank; slot 2 is drawn from the pool: forest_tank 70%, forest_healer 10%, forest_poisoner 10%, forest_disruptor 10%.
3. **Given** a room at depth 3–4, **When** it spawns, **Then** enemies outside this band's defined pool never appear.

---

### User Story 3 — Deep Rooms Have Maximum Threat and Three Waves (Priority: P3)

At depth 5 and beyond, combat rooms add a third wave. Wave 0 and wave 1 match the depth 3–4 composition (except wave 0 replaces the second tank with a poisoner). Wave 2 is a single slot with a 50/50 draw between forest_tank and forest_poisoner.

**Why this priority**: Validates the three-wave case and the deepest depth band. Depends on waves 0–1 working correctly from P2.

**Independent Test**: Reach depth-5+ rooms. Confirm wave 0 always has forest_tank, forest_poisoner, forest_healer, forest_disruptor. Confirm wave 1 matches depth 3–4 wave 1 exactly. Confirm wave 2 always has exactly one enemy: forest_tank or forest_poisoner roughly 50/50.

**Acceptance Scenarios**:

1. **Given** a depth-5+ combat room, **When** wave 0 spawns, **Then** exactly: forest_tank, forest_poisoner, forest_healer, forest_disruptor appear (always fixed).
2. **Given** a depth-5+ combat room, **When** wave 1 spawns, **Then** slot 1 is always forest_tank; slot 2 is drawn from: forest_tank 70%, forest_healer 10%, forest_poisoner 10%, forest_disruptor 10%.
3. **Given** a depth-5+ combat room, **When** wave 2 spawns, **Then** exactly one enemy appears: forest_tank (50%) or forest_poisoner (50%).

---

### Edge Cases

- What if a depth band's weighted pool entries sum to less than 100%? → Treat the remainder as belonging to the highest-weight entry (or assert/warn in debug builds).
- What happens at depth 0 (start room)? → Depth 0 is the start room — it has no enemies regardless of banding; this system applies only to combat rooms.
- What if a referenced enemy id doesn't exist in enemies.json? → Existing validation (RoomSpawner) already asserts on unknown ids; this remains unchanged.
- What if a room depth falls between defined bands (e.g. depth 3 with bands defined as 1, 2, 3–4, 5+)? → The deepest band whose minimum depth ≤ room depth applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each combat room's enemy composition MUST be determined at spawn time by the depth band that matches the room's depth, not by the room's type id (ForestRoom01).
- **FR-002**: Each depth band MUST define one or more waves; each wave MUST define one or more enemy slots.
- **FR-003**: Each enemy slot MUST support a weighted pool of enemy ids. A pool entry with a single enemy at 100% weight is a fixed slot. Weights within a slot MUST sum to 100%.
- **FR-004**: At spawn time, each pooled slot MUST resolve to exactly one enemy id by sampling from its weighted pool using the defined probabilities.
- **FR-005**: Duration stacking MUST be consistent: if a band defines N slots in a wave, exactly N enemies spawn for that wave regardless of which enemy ids were drawn.
- **FR-006**: The depth-band configuration MUST be fully data-driven — all bands, waves, slots, enemy ids, and weights defined in `dungeon_config.json`; no band data hardcoded in scripts.
- **FR-007**: Spawn positions for each slot MUST be defined in the data (x, y coordinates and randomisation radius), co-located with the slot's pool definition.
- **FR-009**: The system MUST fall back gracefully when a room's depth exceeds all defined band maximums by using the highest band (i.e. depth 5+ band catches all depths ≥ 5).
- **FR-010**: The existing per-room-type spawn config (CombatRoom01, CombatRoom02 fixed compositions) MUST be replaced — ForestRoom01 is the sole combat room type in the pool and uses only the depth-banded table.

### Key Entities

- **Depth Band**: Defines a depth range (`min_depth`, `max_depth` or open-ended), containing one or more Wave Configs.
- **Wave Config** (within a band): An ordered list of enemy slots spawned together as one wave; wave index matches the existing wave system.
- **Enemy Slot**: A position (x, y, radius) plus a weighted pool of (enemy_id, weight) pairs. Resolves to one enemy id at spawn time.

## Assumptions

- Spawn positions (x, y, radius) are defined per slot in the depth band data. Since slot counts and positions change per depth, they cannot be inherited from the old per-room-type configs.
- ForestRoom01 is the sole combat room type in `combat_room_pool` (CombatRoom01 is renamed to ForestRoom01; CombatRoom02 is removed). Its enemy composition is driven entirely by depth bands; room type id continues to determine visual/scene choice only.
- Elite rooms are unaffected — EliteRoom01 retains its own fixed spawn config as today.
- Boss room is unaffected.
- Placeholder stats for new enemies (forest_tank, forest_healer, forest_disruptor) are sufficient for this feature; final tuning is a separate task.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Over 20 depth-1 room spawns, forest_disruptor appears in slot 3 between 0 and 5 times (consistent with ~10% probability; exact range uses a 3-sigma bound).
- **SC-002**: Over 20 depth-2 room spawns, slot 3 is approximately half forest_healer and half forest_tank (within a 3-sigma bound of 50%); slot 4 is forest_disruptor in 100% of spawns.
- **SC-003**: Depth-3 and depth-4 rooms always produce exactly 4 enemies in wave 0 and exactly 2 enemies in wave 1, with correct fixed/pooled distribution across 10 observed rooms.
- **SC-004**: Depth-5+ rooms always produce exactly 4 enemies in wave 0, 2 in wave 1, and 1 in wave 2.
- **SC-005**: No enemy type outside the defined depth band ever appears in a combat room at that depth in any observed run.
- **SC-006**: All band, wave, slot, and weight data can be changed in `dungeon_config.json` and takes effect on the next run with no code changes.

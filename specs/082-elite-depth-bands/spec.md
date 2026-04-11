# Feature Specification: Elite Room Depth Bands

**Feature Branch**: `082-elite-depth-bands`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "implement depth-banded elite room composition similar to common room composition"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Early Elite (Depth 1–2) Spawns Correct Composition (Priority: P1)

A player reaches the first elite room at depth 2. The encounter contains two forest tanks, one disruptor, and one slot that is either a zone buffer or a reflector (50/50). The encounter is noticeably different from common rooms and introduces the player to the elite threat level.

**Why this priority**: Establishes the foundational elite encounter pattern; all later bands build on this. Validates that the depth-band selection mechanism works at all.

**Independent Test**: Run the dungeon 10 times, always enter the depth-2 elite room, and verify every encounter has the exact composition (2× tank, 1× disruptor, 1× buffer or reflector).

**Acceptance Scenarios**:

1. **Given** a depth-2 elite room, **When** the player enters, **Then** exactly 4 enemies spawn: 2 forest_tank, 1 forest_disruptor, and 1 enemy that is either forest_buffer or forest_reflector.
2. **Given** the buffer/reflector slot, **When** observed across many runs, **Then** forest_buffer and forest_reflector each appear approximately 50% of the time.

---

### User Story 2 - Mid Elite (Depth 3–4) Spawns Weighted Composition (Priority: P1)

A player reaches an elite room at depth 4. The encounter is drawn from one of two weighted composition variants — a 5-enemy composition (70%) or a 5-enemy all-tank variant (30%). Both variants are more threatening than depth 1–2.

**Why this priority**: Introduces weighted variant selection — the mechanic that makes elite rooms less predictable at higher depths.

**Independent Test**: Enter a depth-4 elite room 20 times and observe that roughly 14 encounters have a healer and 6 do not (within statistical tolerance).

**Acceptance Scenarios**:

1. **Given** a depth 3–4 elite room, **When** the player enters, **Then** the composition is either: (A) 2× forest_tank, 1× forest_disruptor, 1× forest_healer, 1× buffer or reflector; or (B) 3× forest_tank, 1× forest_disruptor, 1× buffer or reflector. No other composition is valid.
2. **Given** variant A (70% weight) and variant B (30% weight), **When** observed across many encounters, **Then** variant A appears approximately twice as often as variant B.

---

### User Story 3 - Late Elite (Depth 5–6) Spawns Complex Weighted Composition (Priority: P2)

A player reaches an elite room at depth 6. Three composition variants are possible (60%, 30%, 10%). The common variants (60%, 30%) each include a forest_poisoner. The rarest variant (10%) swaps the poisoner for both a forest_buffer AND a forest_reflector simultaneously, making it the most dangerous encounter.

**Why this priority**: Delivers late-game variety and escalating danger; depends on the depth-band selection mechanism (P1) being proven.

**Independent Test**: Enter a depth-5 or depth-6 elite room and verify the encountered composition matches one of the three valid variants.

**Acceptance Scenarios**:

1. **Given** a depth 5–6 elite room, **When** the player enters, **Then** the composition matches exactly one of the three configured variants:
   - 60%: forest_tank×1, forest_disruptor×1, forest_healer×1, forest_poisoner×1, forest_buffer or forest_reflector×1 (5 enemies)
   - 30%: forest_tank×2, forest_disruptor×1, forest_poisoner×1, forest_buffer or forest_reflector×1 (5 enemies)
   - 10%: forest_tank×2, forest_disruptor×1, forest_healer×1, forest_buffer×1, forest_reflector×1 (5 enemies)
2. **Given** the 10%-weight rare variant, **When** it spawns, **Then** both forest_buffer and forest_reflector are present alongside forest_healer in the same encounter.

---

### User Story 4 - Deep Elite (Depth 7+) Spawns Max-Difficulty Composition (Priority: P2)

A player reaches an elite room at depth 7 or beyond (only possible with Adventuring Gear expansion). The encounter uses the same three-variant pool as depth 5–6, ensuring maximum challenge for expanded dungeon runs.

**Why this priority**: Completes the depth-band coverage; depends on the late-elite band (P2) being correct first.

**Independent Test**: With Adventuring Gear active, reach a depth-8 elite and verify the encounter matches a depth 5–6 variant.

**Acceptance Scenarios**:

1. **Given** a depth-7+ elite room, **When** the player enters, **Then** the composition is identical in structure and weights to the depth 5–6 band.

---

### Edge Cases

- What if `forest_buffer` or `forest_reflector` are not yet in enemies.json? → The spawn slot falls back gracefully (no enemy spawned for that slot) rather than crashing.
- What if a depth-1 elite room is ever generated (ELITE_START = 2 normally prevents this)? → The depth 1–2 band applies.
- What if the dungeon generator assigns an elite room at an unexpected depth? → The deepest band whose `min_depth` ≤ actual depth applies (open-ended last band).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new `elite_depth_bands` array MUST be added to `dungeon_config.json`, containing one entry per depth range (depth 1–2, depth 3–4, depth 5–6, depth 7+).
- **FR-002**: Each `elite_depth_bands` entry MUST have `min_depth`, `max_depth` (−1 for open-ended), and a `variants` array.
- **FR-003**: Each variant in `variants` MUST have a `weight` (integer) and a `wave` (array of enemy slots in the same pool/position/radius format used by `depth_bands`).
- **FR-004**: At elite room spawn time, the system MUST select the `elite_depth_bands` entry whose depth range contains the room's actual depth, then pick one variant by weighted random selection.
- **FR-005**: The selected variant's `wave` MUST be used as the first (and only) wave for the elite encounter, replacing the current static `spawn_configs.EliteRoom01.spawn_points`.
- **FR-006**: The buffer/reflector choice within a variant MUST be expressed as a pool with equal weights (50/50) on the relevant enemy slot, using the existing pool mechanism.
- **FR-007**: The existing `EliteRoom01` static `spawn_configs` entry MUST be removed or replaced so that old slime/skeleton data is no longer used for elite rooms.
- **FR-008**: The `ForestEliteRoom01` scene MUST be used as the elite room scene for the forest domain (already exists as an untracked file in the repository).
- **FR-009**: The system MUST NOT change the elite promotion logic in `DungeonGenerator` — only the spawn composition changes.
- **FR-010**: `essence_mult` and `enemy_count_mult` modifiers for elite rooms MUST continue to apply on top of the new depth-banded spawning.

### Key Entities

- **Elite Depth Band**: One entry in `elite_depth_bands` covering a contiguous depth range. Contains a list of weighted composition variants for that range.
- **Composition Variant**: One possible encounter template within a band. Has a `weight` (relative draw probability) and a `wave` (array of enemy slots). Selected at room-spawn time, not at dungeon-generation time.
- **Enemy Slot**: An existing construct — `{ pool, position, radius }` — where `pool` is an array of `{ enemy_id, weight }`. Unchanged from the common room system.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every elite room encounter at depths 1–2 contains exactly the depth-1–2 composition with no deviation.
- **SC-002**: Across 20 depth 3–4 elite encounters, the healer-inclusive variant appears between 10 and 18 times (70% ± reasonable variance), confirming weighted selection is functioning.
- **SC-003**: All three depth 5–6 variants are observable in play; the dual-special (10%) variant appears at roughly 1-in-10 frequency.
- **SC-004**: No runtime error occurs when entering any elite room at any supported depth.
- **SC-005**: Elite rooms continue to award elevated essence (via existing `essence_mult`) after the composition change.

## Assumptions

- **Depth 7+ band**: Uses the same three-variant pool and weights as depth 5–6. Only reachable with the Adventuring Gear expansion (max depth ~12). If a distinct composition is desired later, it can be added as a new band entry with no code changes.
- **Wave count**: Each elite room has exactly one wave (the selected variant). The existing multi-wave mechanism (depth_tiers trigger_threshold) does not apply to elite rooms.
- **Positions**: Enemy spawn positions within elite variants follow the same grid conventions as common room bands (positions in local room coordinates). Exact coordinates will be tuned during implementation.
- **forest_buffer and forest_reflector**: These enemy IDs are defined in specs 080 and 081 respectively and are assumed to exist in `enemies.json` at implementation time.
- **`ForestEliteRoom01`**: Scene and `.tres` already exist in the repository (untracked). The `.tres` `room_type_id` field will reference a key that maps to the new depth-banded logic (or shares a key with `EliteRoom01`).

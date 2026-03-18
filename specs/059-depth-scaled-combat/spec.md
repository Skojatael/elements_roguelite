# Feature Specification: Depth-Scaled Combat

**Feature Branch**: `059-depth-scaled-combat`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "for depth 1, spawn 3 enemies (minimum 2 slimes), disable waves. for depth 2, have 4 enemies spawn, still 0 waves. for depth 3 and 4, 4 enemies + 1 wave (2 additional enemies, when alive =< 2, spawn 2). from depth 5, 4 enemies + 2 waves (2 and 1 adds respectively, when alive =< 2, spawn)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Combat Scales With Dungeon Depth (Priority: P1)

Each combat room's enemy count and wave structure depends on how deep in the dungeon it is. Early rooms (depth 1–2) are flat encounters with no waves, easing the player in. Mid-depth rooms (3–4) introduce a single reinforcement wave. Deep rooms (depth 5+) add a second wave, making late-dungeon rooms a sustained combat challenge.

**Why this priority**: This is the core feature — a single user story covering the full depth-scaling table. All other content follows from it.

**Independent Test**: Run a dungeon. Enter a depth-1 room — verify 3 enemies spawn (at least 2 slimes), no further waves. Enter a depth-2 room — verify 4 enemies, no waves. Enter a depth-3 or depth-4 room — verify 4 initial enemies, then 2 more when ≤2 remain. Enter a depth-5+ room — verify 4 initial, then 2 more when ≤2 remain, then 1 final when ≤2 remain again.

**Acceptance Scenarios**:

1. **Given** a combat room at depth 1, **When** the player enters, **Then** exactly 3 enemies spawn, at least 2 of which are slimes, and no further enemies arrive regardless of how many are killed.
2. **Given** a combat room at depth 2, **When** the player enters, **Then** exactly 4 enemies spawn and no further enemies arrive.
3. **Given** a combat room at depth 3 or 4, **When** the player enters, **Then** 4 enemies spawn initially; when ≤2 enemies remain alive, 2 more spawn; the room clears after all 6 total kills.
4. **Given** a combat room at depth 5 or greater, **When** the player enters, **Then** 4 enemies spawn initially; when ≤2 remain, 2 more spawn; when ≤2 remain again, 1 final enemy spawns; the room clears after all 7 total kills.
5. **Given** any combat room, **When** the room is cleared, **Then** the total enemies defeated matches the expected count for that depth tier.

---

### Edge Cases

- Depth 0 (start room) — no enemies, depth scaling does not apply.
- Elite rooms — depth scaling does not apply to elite rooms; they use their own configuration.
- Boss room — depth scaling does not apply.
- A depth-5+ room with the alive_cap reached (4 enemies alive simultaneously) — subsequent wave enemies wait until the cap allows them.
- Room re-entry after clearing — no enemies respawn, no waves re-trigger.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Combat room enemy counts and wave structures MUST be determined by the room's depth, using the following table:

  | Depth | Initial spawn | Wave 1 (trigger: ≤2 alive) | Wave 2 (trigger: ≤2 alive) | Total kills |
  |-------|--------------|----------------------------|----------------------------|-------------|
  | 1     | 3            | none                       | none                       | 3           |
  | 2     | 4            | none                       | none                       | 4           |
  | 3–4   | 4            | +2                         | none                       | 6           |
  | 5+    | 4            | +2                         | +1                         | 7           |

- **FR-002**: At depth 1, at least 2 of the 3 spawned enemies MUST be slimes.
- **FR-003**: The wave trigger threshold MUST be ≤2 alive enemies for all wave tiers (depths 3+).
- **FR-004**: The alive cap (maximum simultaneous enemies) MUST remain 4 across all depth tiers.
- **FR-005**: Depth scaling MUST apply only to standard combat rooms. Elite rooms, boss rooms, and the start room MUST be unaffected.
- **FR-006**: All depth-scaling parameters MUST be stored in configuration data, not hardcoded.

### Key Entities

- **Depth-tier config**: Maps depth ranges to initial spawn count, wave definitions (size + trigger), and enemy composition constraints.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of depth-1 rooms spawn exactly 3 enemies with ≥2 slimes across all observed runs.
- **SC-002**: 100% of depth-2 rooms spawn exactly 4 enemies with no subsequent waves.
- **SC-003**: 100% of depth-3/4 rooms spawn exactly 6 total enemies across initial spawn + 1 wave.
- **SC-004**: 100% of depth-5+ rooms spawn exactly 7 total enemies across initial spawn + 2 waves.
- **SC-005**: No depth-scaling behaviour appears in elite, boss, or start rooms.

## Assumptions

- "Depth" refers to the room's grid Manhattan distance from the start room, as already tracked per room in the dungeon generator.
- Elite rooms retain their existing configuration and are unaffected by this feature.
- The alive cap of 4 and trigger threshold of ≤2 are consistent across all wave tiers.
- "Minimum 2 slimes" at depth 1 is satisfied by configuring depth-1 spawn points to include at least 2 slime entries. The third enemy at depth 1 is also a slime (3 slimes total) as the simplest compliant configuration.
- Depth tiers are defined as: tier A = depth 1, tier B = depth 2, tier C = depth 3–4, tier D = depth 5+. There is no upper bound on depth D.

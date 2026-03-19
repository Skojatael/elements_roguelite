# Feature Specification: HP Regeneration

**Feature Branch**: `060-hp-regen`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "introduce regeneration relic. it should be common, restore 1% of hp per second. introduce regeneration mechanic."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Passive HP Recovery During a Run (Priority: P1)

The player picks up the "Regeneration" relic from a post-room offer. From that point forward, their HP slowly ticks upward while they are alive and in a run. If the player entered combat with some HP missing, the regen will eventually restore them to full health — as long as they are not taking damage faster than they regenerate.

**Why this priority**: This is the core of the feature. Without regeneration working in-game, the relic is non-functional.

**Independent Test**: Start a run, pick up the regen relic (or trigger it via DevPanel), observe player HP increasing over time while below max HP.

**Acceptance Scenarios**:

1. **Given** the player holds the regen relic and is below max HP, **When** 1 second elapses, **Then** the player's HP increases by 1% of their max HP.
2. **Given** the player holds the regen relic and is at full HP, **When** time elapses, **Then** HP stays at max (no overheal).
3. **Given** the player does not hold the regen relic, **When** time elapses, **Then** HP does not change passively.

---

### User Story 2 - Regen Clears on Run End (Priority: P2)

When the run ends (death or cash-out), regeneration stops and does not bleed into the hub or the next run.

**Why this priority**: Prevents the mechanic from operating outside its intended scope and avoids interaction bugs in the hub.

**Independent Test**: Verify HP does not change passively while the player is in the hub or after a run ends, even if the regen relic was held in the previous run.

**Acceptance Scenarios**:

1. **Given** the player held the regen relic during a run, **When** the run ends, **Then** regeneration stops and HP does not tick in the hub.
2. **Given** a new run starts without the regen relic, **When** time elapses, **Then** HP does not regenerate.

---

### User Story 3 - Regen Rate Scales With Max HP (Priority: P3)

Because the regen rate is expressed as a percentage of max HP (not a flat amount), picking up other relics that increase max HP also increases the absolute HP healed per second.

**Why this priority**: Ensures the mechanic interacts correctly with max-health relics (e.g., Vital Core, Ironwood Branch) without special-casing.

**Independent Test**: Equip the regen relic and a max-health relic, then verify the per-second HP gain is 1% of the new, higher max HP value.

**Acceptance Scenarios**:

1. **Given** the player holds the regen relic and a max-health bonus relic, **When** max HP is recalculated, **Then** the regeneration amount per second updates to reflect 1% of the new max HP.

---

### Edge Cases

- What happens if the player's max HP changes mid-run (from a relic)? Regen rate should update immediately to track the new max.
- What happens if HP is exactly at max? Regeneration produces no change — no rounding should push HP above max.
- What if a future relic also provides regeneration? The regeneration amounts from all sources should accumulate (stacking).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST support a regeneration mechanic that increases player HP over time at a configurable rate expressed as a percentage of current max HP per second.
- **FR-002**: Regeneration MUST tick continuously while a run is active and the player is alive.
- **FR-003**: Regeneration MUST NOT increase player HP beyond their current max HP (no overheal).
- **FR-004**: Regeneration MUST stop when a run ends (any end reason).
- **FR-005**: A "Regeneration Stone" relic MUST exist in the common tier of the relic pool.
- **FR-006**: The Regeneration Stone relic MUST apply a regeneration rate of 1% of max HP per second.
- **FR-007**: Multiple regeneration sources MUST stack additively (e.g., two regen sources at 1% each produce 2% per second).
- **FR-008**: The regeneration rate MUST recalculate immediately when max HP changes (e.g., after picking up a max-health relic).

### Key Entities

- **Regeneration Effect**: An ongoing per-second heal rate expressed as a fraction of max HP. Has a rate field (e.g., 0.01 = 1%). Multiple effects accumulate additively.
- **Regeneration Relic**: A common-tier relic that grants a regeneration effect of 0.01 (1% per second) for the duration of the run. Cleared on run end like all other relics.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player holding the regen relic at 50% HP reaches full HP in exactly 50 seconds in the absence of incoming damage (±1 tick of tolerance).
- **SC-002**: Player HP never reads above max HP under any circumstances involving regeneration.
- **SC-003**: Regeneration is absent (zero passive HP change) when no regen source is held.
- **SC-004**: Two simultaneous regen sources produce exactly double the per-second HP gain of one source.

## Assumptions

- Regeneration applies to the player only (not enemies or other entities) in this iteration.
- The regeneration rate (1% per second) is data-driven and stored in `data/relics.json` alongside other relic entries.
- Regeneration is inactive in the hub (only ticks while `RunManager.is_run_active` is true).
- The relic description text is "+1% HP per second".
- The relic ID is `common_regen` and its name is "Regeneration Stone".

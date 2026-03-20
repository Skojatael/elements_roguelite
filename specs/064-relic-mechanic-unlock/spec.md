# Feature Specification: Relic Mechanic Unlock Tags

**Feature Branch**: `064-relic-mechanic-unlock`
**Created**: 2026-03-19
**Status**: Draft
**Input**: User description: "add the following feature to relics: a pair of tags, '<mechanic>' and '<mechanic>_unlocked'. when '<mechanic>' is picked by the player, '<mechanic>' will no longer be offered in relic pool until new run starts, and instead '<mechanic>_unlocked' relics will be added to the pool. example: burn and burn damage. if burn is picked, burn damage becomes available"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Picking a Mechanic Relic Unlocks Follow-up Relics (Priority: P1)

A player picks a relic tagged with a mechanic identifier (e.g. `burn`). On subsequent relic offer screens during the same run, relics that require `burn` to be active (`burn_unlocked` tag) become eligible to appear, while the original `burn` relic is excluded from future offers.

**Why this priority**: This is the core behaviour of the feature — without it, the unlocked relics can never appear and the tag pairing has no effect.

**Independent Test**: With a relic pool containing one `burn` relic and one `burn_unlocked` relic, picking the `burn` relic and then triggering another offer should surface the `burn_unlocked` relic and never offer `burn` again in that run.

**Acceptance Scenarios**:

1. **Given** a relic pool with a `burn`-tagged relic and a `burn_unlocked`-tagged relic, **When** the player picks the `burn` relic, **Then** the `burn_unlocked` relic becomes eligible for future offers in the current run.
2. **Given** the player has already picked the `burn` relic, **When** a new relic offer is drawn, **Then** no relic whose only pool membership is the `burn` mechanic tag is included in the offer candidates.

---

### User Story 2 - Mechanic Exclusion Resets on New Run (Priority: P2)

At the start of a new run, all mechanic unlock state is cleared. Every mechanic relic is eligible again and no unlocked relics carry over.

**Why this priority**: Without a reset, a player's meta-state bleeds across runs, which breaks the roguelite run-scoped design.

**Independent Test**: Complete a run where `burn` was picked; start a new run and verify `burn` appears in the offer pool and `burn_unlocked` relics do not.

**Acceptance Scenarios**:

1. **Given** the player picked the `burn` relic in the previous run, **When** a new run starts, **Then** `burn`-tagged relics are eligible offers again and `burn_unlocked`-tagged relics are not.
2. **Given** a new run is active with no relics picked yet, **When** an offer is drawn, **Then** no `*_unlocked` relic appears unless its prerequisite mechanic has already been picked in this run.

---

### User Story 3 - Multiple Independent Mechanic Pairs Coexist (Priority: P3)

Multiple mechanic pairs (e.g. `burn`/`burn_unlocked`, `chain`/`chain_unlocked`) operate independently. Picking `burn` does not affect `chain` availability, and vice versa.

**Why this priority**: The system must be data-driven and extensible; correctness for one pair must not break another.

**Independent Test**: With both `burn` and `chain` mechanic relics available, pick `burn` only; verify `chain_unlocked` relics do not appear and `chain` remains eligible.

**Acceptance Scenarios**:

1. **Given** the pool contains `burn`, `burn_unlocked`, `chain`, and `chain_unlocked` relics, **When** the player picks the `burn` relic, **Then** `chain` remains eligible and `chain_unlocked` does not appear.
2. **Given** the player has picked both `burn` and `chain`, **When** a new offer is drawn, **Then** both `burn_unlocked` and `chain_unlocked` relics are eligible.

---

### Edge Cases

- What happens if the player already holds the `burn` relic (e.g. via dev panel) and a `burn`-tagged relic is drawn — it should be excluded by the existing unique-relic logic, not the mechanic unlock logic.
- What happens if a relic carries both a `mechanic` tag and an `_unlocked` tag for a different mechanic (multi-tag relic)? Both rules apply independently.
- What happens if there are no `burn_unlocked` relics in `relics.json`? Nothing — the pool simply gains no new entries; `burn` is still excluded from future offers.
- What happens if the only relics remaining in the pool are mechanic-gated and none are eligible? The offer screen should fall back to whatever empty-pool behaviour already exists (no crash).
- Picking the same mechanic relic twice in one run is impossible (existing unique-relic rule applies); the mechanic unlock state does not need to handle re-triggering.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each relic entry in the data source MAY carry a `tags` field containing zero or more mechanic identifiers (e.g. `["burn"]`) and/or unlock identifiers (e.g. `["burn_unlocked"]`).
- **FR-002**: When the player picks a relic, the system MUST inspect that relic's tags for any tag that does **not** end in `_unlocked` and record each such tag as an "activated mechanic" for the current run.
- **FR-003**: After a mechanic is activated, relics whose tags include that mechanic identifier (without `_unlocked`) MUST be excluded from all subsequent offer draws in the same run.
- **FR-004**: After a mechanic is activated, relics whose tags include `<mechanic>_unlocked` MUST become eligible to appear in subsequent offer draws in the same run, subject to normal offer rules (tier, uniqueness, rarity).
- **FR-005**: Mechanic activation state (the set of activated mechanic identifiers) MUST be reset to empty at the start of each new run.
- **FR-006**: A relic MAY carry tags for multiple mechanic pairs simultaneously; each tag is evaluated independently.
- **FR-007**: Relics with an `_unlocked` tag whose prerequisite mechanic has NOT yet been activated in the current run MUST NOT appear in any offer draw.
- **FR-008**: The mechanic unlock logic MUST integrate with the existing offer draw and pool-filtering pipeline without altering boss offer or elite offer behaviour beyond the pool contents.

### Key Entities

- **Mechanic Tag**: A string identifier (e.g. `"burn"`) present in a relic's `tags` array that denotes a mechanic gatekeeper relic.
- **Unlock Tag**: A string formed as `"<mechanic>_unlocked"` in a relic's `tags` array that marks the relic as available only after the matching mechanic is activated.
- **Activated Mechanics Set**: A run-scoped collection tracking which mechanic tags have been triggered in the current run. Reset on `run_started`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After picking a mechanic relic, 0% of subsequent offers in the same run include relics gated solely by that mechanic tag.
- **SC-002**: After picking a mechanic relic, 100% of eligible `<mechanic>_unlocked` relics are included in the offer candidate pool for subsequent draws (subject to standard tier/uniqueness filtering).
- **SC-003**: At the start of a new run, 100% of mechanic-tagged relics are available in the candidate pool and 0% of `_unlocked`-tagged relics are available (if no mechanic has been picked yet).
- **SC-004**: Two independent mechanic pairs are not cross-contaminated: picking mechanic A does not alter the eligibility of mechanic B or `B_unlocked` relics.

## Assumptions

- `relics.json` already supports a `tags` array per relic entry; this feature adds meaningful values to that field but does not change its data structure.
- "Mechanic" vs. "unlock" distinction is purely by naming convention: any tag ending in `_unlocked` is treated as an unlock tag; all others are mechanic tags.
- Existing unique-relic exclusion (a relic already held is never offered again) still applies on top of mechanic unlock filtering.
- No UI changes are required for this feature; the offer screen already displays whatever relics the draw pipeline provides.
- Boss rare relic offers use the same filtering pipeline and will also respect mechanic unlock state.

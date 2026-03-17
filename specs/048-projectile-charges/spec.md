# Feature Specification: Magic Missile Charges

**Feature Branch**: `048-projectile-charges`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "add charge feature on Magic Missile skill. base should be 3 charges, upgradeable, upgrade out of scope. when the skill is pressed, a charge is spent. successful melee attacks restore 1 charge. if charges are full, melee attacks do nothing"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Spend Charge on Skill Use (Priority: P1)

The player has a limited pool of charges for the Magic Missile skill. Each time the skill button is pressed, one charge is consumed and a missile fires. If all charges are depleted, the skill cannot be activated until charges are restored.

**Why this priority**: Core gating mechanic — without this, the rest of the feature has no meaning.

**Independent Test**: Press the skill button repeatedly. After 3 presses the skill stops firing; this delivers the core resource-management loop.

**Acceptance Scenarios**:

1. **Given** the player has 1 or more charges, **When** the skill button is pressed, **Then** a missile fires and the charge count decreases by 1.
2. **Given** the player has 0 charges, **When** the skill button is pressed, **Then** no projectile fires and the charge count remains at 0.
3. **Given** the player starts a run, **When** the run begins, **Then** charges are initialised at the base maximum (3).

---

### User Story 2 - Restore Charge via Melee Attack (Priority: P2)

Landing a successful melee hit restores one charge to the player, incentivising alternating between melee and ranged play. If charges are already at maximum no change occurs.

**Why this priority**: This is the primary restore loop and gives the mechanic its gameplay identity.

**Independent Test**: Deplete charges to 0, perform a melee hit that connects with an enemy, confirm charge count increases to 1.

**Acceptance Scenarios**:

1. **Given** the player has fewer than maximum charges, **When** a melee attack successfully hits an enemy, **Then** the charge count increases by 1.
2. **Given** the player has maximum charges, **When** a melee attack successfully hits an enemy, **Then** the charge count stays at maximum (no overflow).
3. **Given** a melee attack misses (no hit detected), **When** the attack animation plays, **Then** no charge is restored.

---

### User Story 3 - HUD Charge Display (Priority: P3)

The current charge count is always visible to the player so they can make informed decisions about when to use the skill.

**Why this priority**: Without feedback the player cannot play around the charge mechanic.

**Independent Test**: Open the game HUD during a run; the charge display correctly reflects the current count after spending and restoring charges.

**Acceptance Scenarios**:

1. **Given** charges change for any reason, **When** the HUD updates, **Then** the displayed count matches the actual charge count.
2. **Given** the player is at 0 charges, **When** they view the HUD, **Then** the charge display clearly communicates the depleted state (e.g., empty pips).

---

### Edge Cases

- What happens when the player fires the skill and takes the last charge at the exact same frame a melee hit lands? Charge should be restored (net 0 change from that pair of events).
- How does the system handle the skill button being held down — continuous fire consuming multiple charges rapidly? Each press or discrete activation consumes exactly one charge; holding should not drain more than one charge per discrete activation.
- What happens to charges on run end? Charges reset at the start of each run; carry-over is not expected.
- What happens when the maximum charge count is changed by a future upgrade while mid-run? Out of scope; current charge count is capped at the new maximum without exceeding it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Magic Missile skill MUST maintain a charge count with a base maximum of 3.
- **FR-002**: Pressing the skill button MUST consume 1 charge and fire a projectile; if charge count is 0 the skill MUST be blocked entirely.
- **FR-003**: A successful melee attack hit MUST restore exactly 1 charge, up to the current maximum.
- **FR-004**: A melee attack that does not connect with an enemy MUST NOT restore any charge.
- **FR-005**: If the charge count is already at maximum, a successful melee hit MUST NOT change the charge count.
- **FR-006**: Charges MUST reset to the base maximum at the start of every run.
- **FR-007**: The HUD MUST display the current and maximum charge count at all times during a run.
- **FR-008**: The maximum charge count MUST be data-driven (readable from config/data) so a future upgrade path can modify it without code changes.

### Key Entities

- **Charge Pool**: Current count (0 to max) and maximum count (base 3). Lives on the player's skill state for the duration of a run.
- **Magic Missile**: Existing ranged skill (named `magic_missile`); extended with charge gating logic.
- **Melee Attack**: Existing attack; extended with charge-restore callback on successful hit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can fire the Magic Missile skill exactly 3 times in a row before it becomes unavailable with no upgrades applied.
- **SC-002**: Every successful melee hit increases the charge count by exactly 1 (up to maximum), measurable in 100% of test cases.
- **SC-003**: The skill is blocked 100% of the time when the charge count is 0 — no projectile is ever produced with 0 charges.
- **SC-004**: The charge display on the HUD is accurate within one frame of any charge change event.
- **SC-005**: Charges are fully restored to maximum within the first frame of a new run starting.

## Assumptions

- "Successful melee attack" means a melee hit that is registered on an enemy (i.e., the hit detection fires for a valid enemy target). Misses and attacks on non-enemy objects do not count.
- The upgrade path (increasing max charges) is explicitly out of scope; the max charge value of 3 is stored in data so it can be changed later without revisiting this feature.
- Charge state does not persist between runs; it resets on each `start_run()`.
- The skill being extended is the one implemented in `SkillComponent.gd` (feature 046-homing-projectile-skill); it will be named `magic_missile` in data and code.
- The HUD charge display integrates into the existing `ExplorationHUD` / skill button area rather than requiring a new standalone scene.

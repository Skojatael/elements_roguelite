# Feature Specification: Magic Missile Cooldown

**Feature Branch**: `050-magic-missile-cooldown`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "add cooldown on magic missile. make it 1 second (data-driven)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cooldown Prevents Rapid Re-fire (Priority: P1)

After firing a magic missile charge, a 3-second cooldown prevents the player from firing again until it expires. The skill button is blocked during cooldown regardless of available charges. The player must wait out the timer before the next shot is allowed.

**Why this priority**: Core mechanic — without the cooldown gate, the feature has no effect. All other stories depend on this foundation.

**Independent Test**: Fire one missile, immediately attempt to fire again — the second shot is blocked. Wait 1 second — the shot is now allowed.

**Acceptance Scenarios**:

1. **Given** the player has charges available, **When** they fire a magic missile, **Then** a 3-second cooldown begins and further skill activations are ignored until it expires.
2. **Given** the cooldown is active, **When** the cooldown timer expires, **Then** the player can fire the skill again on the next button press.
3. **Given** the player has zero charges, **When** the cooldown expires, **Then** pressing the skill button still does nothing (existing charge gate still applies).

---

### User Story 2 - Cooldown Duration from Config (Priority: P2)

The 3-second cooldown duration is read from `data/skills.json` for the `magic_missile` entry. Changing the value in the JSON file changes the in-game cooldown with no code modification required.

**Why this priority**: The user explicitly requested a data-driven value. Hardcoding defeats the purpose.

**Independent Test**: Change the cooldown value in `skills.json` to 1 second — in-game cooldown matches the new value on the next launch.

**Acceptance Scenarios**:

1. **Given** `skills.json` has `"cooldown": 3.0` for `magic_missile`, **When** the game loads, **Then** the cooldown duration is 1 second.
2. **Given** a developer changes `"cooldown"` to `5.0` in `skills.json`, **When** the game is relaunched, **Then** the cooldown duration is 5 seconds.

---

### User Story 3 - HUD Reflects Cooldown State (Priority: P3)

The player can see when the skill is on cooldown. The existing charges display (which already tracks charge count) provides implicit feedback; no additional UI element is strictly required unless the charge count does not convey cooldown state.

**Why this priority**: Quality-of-life feedback. The core mechanic works without it, but players need to know why the skill isn't firing.

**Independent Test**: Fire a missile — the UI changes to indicate the skill is unavailable. After 1 second — the UI returns to its ready state.

**Acceptance Scenarios**:

1. **Given** a missile is fired and cooldown begins, **When** the cooldown is active, **Then** the skill button/charge display shows a disabled or cooldown state.
2. **Given** the cooldown expires, **When** the timer completes, **Then** the skill button/charge display returns to the ready state.

---

### Edge Cases

- What happens if the player fires the last charge and the cooldown expires before a melee hit restores a charge? Skill remains blocked by zero charges — cooldown and charge system are independent gates.
- What happens if the run ends while cooldown is active? Cooldown state is discarded; charges reset to full on the next run start (existing `run_started` reset already handles this).
- What if `"cooldown"` is missing from `skills.json`? The system must default to 1.0 seconds and not crash.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST prevent firing a magic missile while the cooldown timer is active, regardless of current charge count.
- **FR-002**: The cooldown timer MUST start immediately after a magic missile is successfully fired (charge consumed and projectile spawned).
- **FR-003**: The cooldown duration MUST be read from `data/skills.json` under the `magic_missile` entry as a `"cooldown"` field (float, seconds).
- **FR-004**: If `"cooldown"` is absent from `skills.json`, the system MUST use a default value of 1.0 seconds.
- **FR-005**: The cooldown timer MUST reset to zero at the start of each run (consistent with the existing charge reset behaviour).
- **FR-006**: The existing charge system MUST remain fully intact — both the cooldown gate and the charge gate must be independently satisfied before a missile can fire.
- **FR-007**: The HUD MUST visually communicate whether the skill is on cooldown or ready (may reuse existing charge display or add a distinct indicator).

### Key Entities

- **Magic Missile Cooldown**: A per-run timer that begins on each successful skill activation. Duration is configured per-skill in `skills.json`. Independent of the charge count.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After firing a magic missile, a second activation within 1 second produces no projectile and no charge consumption.
- **SC-002**: Exactly 1 second after firing, the skill is available again (±0.1 s tolerance for frame timing).
- **SC-003**: Changing `"cooldown"` in `skills.json` to any positive float value correctly reflects that duration in-game without code changes.
- **SC-004**: A run start always resets the cooldown so the player begins with the skill ready.
- **SC-005**: The HUD clearly indicates cooldown vs. ready state so a player can determine skill availability at a glance.

## Assumptions

- The cooldown is per-use (one shot → 1 s wait), not a full-charge-depletion cooldown. This is the most common roguelite pattern and avoids ambiguity with the existing charge mechanic.
- The cooldown and charge system are additive restrictions: both must permit firing. The cooldown does not replace charges.
- No cooldown reduction stat or relic interaction is in scope for this feature.
- The `SkillComponent` owns the cooldown timer (a Godot `Timer` node or `_process` accumulator); no new autoload or service is needed.

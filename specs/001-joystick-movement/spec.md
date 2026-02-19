# Feature Specification: Player Movement Joystick Controls

**Feature Branch**: `001-joystick-movement`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "add player movement joystick controls"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate the Dungeon (Priority: P1)

A player presses their thumb in the joystick zone and drags in any direction.
The character immediately begins moving that way. Releasing the thumb stops
the character. The player uses this throughout every dungeon room — walking
toward enemies, dodging projectiles, and moving between rooms.

**Why this priority**: Core locomotion. Nothing else in the game is reachable
without reliable directional movement.

**Independent Test**: Launch the game into any dungeon room. Without any other
feature, the player must be able to steer the character to any point in the
room and stop precisely on demand.

**Acceptance Scenarios**:

1. **Given** the player is in a dungeon room, **When** they press and drag the
   joystick toward the top of the screen, **Then** the character moves toward
   the top of the room continuously until the finger is released.
2. **Given** the joystick is active, **When** the player releases their finger,
   **Then** the character stops moving within one visible frame.
3. **Given** the player drags in any diagonal direction, **Then** the character
   moves diagonally at the correct angle (not snapped to 4 or 8 directions).

---

### User Story 2 - Analog Speed Control (Priority: P2)

A player gently nudges the joystick a small distance to creep forward slowly,
and pushes it to the outer edge to sprint at full speed. Speed transitions feel
smooth as the joystick position changes.

**Why this priority**: Precise speed control is essential for roguelite
positioning — approaching enemies carefully, dodging in tight corridors.

**Independent Test**: In an empty room, confirm the character moves at
noticeably different speeds depending on how far the joystick knob is dragged
from centre. Midway drag = roughly half max speed; full drag = max speed.

**Acceptance Scenarios**:

1. **Given** the joystick is pressed, **When** the player drags the knob
   50% of maximum distance, **Then** the character moves at approximately
   50% of maximum movement speed.
2. **Given** the player makes a very small unintentional press inside the dead
   zone, **Then** the character does not move at all.

---

### User Story 3 - Visual Joystick Feedback (Priority: P3)

The player can always see where the joystick base is and where their thumb is
relative to it. An arrow or stretched knob clearly indicates the current
movement direction. When the finger is lifted the joystick knob snaps back to
centre and the indicator disappears.

**Why this priority**: Without feedback the player cannot judge their input
angle or know whether the control registered. Important for first-time players
and high-pressure combat situations.

**Independent Test**: While moving, the on-screen knob must visibly offset in
the drag direction and return to centre on release, without the player needing
to look at the character.

**Acceptance Scenarios**:

1. **Given** the joystick is active, **When** the player drags right, **Then**
   the knob visually offsets to the right and a direction indicator points right.
2. **Given** the player lifts their finger, **Then** the knob animates back to
   the centre position within 0.1 seconds.

---

### Edge Cases

- What happens when the player touches exactly on the joystick boundary edge?
  The input must still register as full-magnitude movement.
- How does the system handle two simultaneous touches (e.g., joystick + attack
  button)? The joystick must continue tracking its own touch independently.
- What happens if the device loses the touch event mid-drag (e.g., notification
  overlay)? Movement must stop; the knob must reset to centre.
- What happens on very small or very large screen sizes? The joystick must
  remain fully within the safe area of the screen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST display a virtual joystick in the bottom-left
  screen quadrant during all active gameplay (dungeon rooms and boss encounters).
- **FR-002**: The joystick MUST accept touch-drag input and translate it into a
  continuous directional movement vector for the player character.
- **FR-003**: Movement speed MUST scale linearly with the distance the joystick
  knob is dragged from its centre, from zero at the dead zone boundary to full
  speed at the outer rim.
- **FR-004**: The joystick MUST enforce a dead zone: inputs within 10% of the
  maximum drag radius MUST produce zero movement.
- **FR-005**: The joystick MUST support full 360-degree directional input with
  no angle snapping.
- **FR-006**: Movement MUST stop within one rendered frame of the player lifting
  their finger from the joystick.
- **FR-007**: The joystick MUST NOT interfere with other simultaneous touch
  inputs (e.g., skill buttons, dodge swipes) — each touch point is tracked
  independently.
- **FR-008**: The joystick base MUST remain in a fixed screen position and MUST
  NOT drift or reposition during a session.
- **FR-009**: The joystick MUST be hidden on non-gameplay screens (main menu,
  upgrade screen, pause menu).

### Key Entities *(include if feature involves data)*

- **Joystick Control**: The on-screen input widget. Has a fixed base position,
  a draggable knob, a maximum interaction radius, and a dead zone radius.
  Produces a normalised direction vector and a magnitude value (0.0 – 1.0).
- **Movement Input**: The directional signal output by the joystick (direction
  vector + magnitude). Consumed by the player's movement system each physics
  frame.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Players can navigate a character from a room's spawn point to its
  exit touching only the joystick, with no unintended stops or direction errors,
  in 100% of test runs on a physical device.
- **SC-002**: The character's on-screen movement direction matches the joystick
  drag direction within ±5 degrees across all tested angles.
- **SC-003**: Joystick touch events register and produce visible character
  movement within one rendered frame (≤ 16 ms at 60 fps) of the drag starting.
- **SC-004**: In blind user-testing, 90% of first-time players successfully
  move the character in the intended direction without instruction.
- **SC-005**: Simultaneous joystick + action-button input produces no dropped
  inputs in 100 consecutive test presses.

## Assumptions

- The joystick is **fixed-position** (bottom-left corner), not floating. A
  floating joystick (appearing where the player first touches) can be explored
  in a follow-up feature.
- Portrait orientation only (1080×1920); no landscape layout is required.
- The joystick feeds into the existing player movement system; no new locomotion
  logic is specified here — only the input layer.
- Joystick size and opacity are not user-configurable in this version; sensible
  defaults will be chosen during implementation.

# Feature Specification: Hub Room

**Feature Branch**: `013-hub-room`
**Created**: 2026-02-27
**Status**: Draft
**Input**: "create a hub room that has (for now only one) a door-like object which has a button with 'teleport' text on it. this 'door' will later be swapped out for some graphical asset. the run starts and player is teleported in start room when the teleport button is pressed. this hub is not part of the run, it will handle meta progression and upgrades and other things (not important right now)."
**Correction**: "teleport should have a button in that area that on press sends player to the run" — activation is via button press, not proximity walk-through.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Game Starts in the Hub (Priority: P1) 🎯 MVP

When the game is launched, the player is placed inside the hub room — not directly in a dungeon. The hub is the game's default starting state. The player exists in the hub world and can move around freely. A clearly labelled interactive object is visible: a door-like placeholder marked "Teleport".

**Why this priority**: The hub must exist before anything else in this feature can be tested. Without the hub scene and the player being placed in it at game start, there is nothing to interact with.

**Independent Test**: Launch the game. Confirm the player appears inside a hub scene (not a dungeon room). Confirm the Teleport object is visible and labelled "Teleport". Confirm the player can move around the hub freely.

**Acceptance Scenarios**:

1. **Given** the game is launched, **When** the initial scene loads, **Then** the player is placed inside the hub room.
2. **Given** the player is in the hub, **When** they look around, **Then** a Teleport object is visible and clearly labelled "Teleport".
3. **Given** the player is in the hub, **When** they move, **Then** movement works normally — the hub is a navigable 2D space.

---

### User Story 2 - Pressing the Teleport Button Starts the Run (Priority: P1) 🎯 MVP

The player approaches the Teleport object, which displays a pressable button labelled "Teleport". The player taps or presses the button. The run immediately begins and the player is placed inside the dungeon's starting room. From that point on, the game behaves exactly as if the run had been started by any other means — the dungeon generates, rooms are navigable, enemies spawn.

**Why this priority**: This is the primary purpose of the feature — connecting the hub to the run system. Without this, the hub is a dead end.

**Independent Test**: Launch the game. Walk the player to the Teleport object. Confirm the "Teleport" button is visible and pressable. Press the button. Confirm the run starts (not already in a run before button press). Confirm the player appears in the dungeon starting room. Confirm enemies and rooms behave normally.

**Acceptance Scenarios**:

1. **Given** the player is in the hub and no run is active, **When** the player presses the "Teleport" button on the Teleport object, **Then** a new run starts.
2. **Given** the Teleport button is pressed, **When** the transition occurs, **Then** the player appears in the dungeon's starting room (not in the hub).
3. **Given** the run has started via the Teleport button, **When** the player navigates the dungeon, **Then** all dungeon behaviour (rooms, enemies, doors) works identically to a run started by any other means.
4. **Given** the player presses the Teleport button, **When** the run starts, **Then** the hub room is no longer visible — the player is fully in the dungeon.

---

### Edge Cases

- What if the player presses the Teleport button while a run is already active? The press should be ignored — no second run starts, no error.
- What if the player is near the Teleport object but does not press the button? Nothing happens — proximity alone has no effect. The run only starts on explicit button press.
- What if the dungeon fails to generate? The player stays in the hub; an error is logged. No crash.
- Does the player return to the hub after a run ends? Out of scope for this feature — no return flow is defined here.
- Can the player leave the hub without pressing Teleport? No other exits are defined in this feature. The player stays in the hub until the Teleport button is pressed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST place the player in the hub room when the game is launched.
- **FR-002**: The hub room MUST contain exactly one Teleport object — a door-like interactive placeholder labelled "Teleport".
- **FR-003**: The Teleport object MUST contain a pressable button labelled "Teleport". The run starts when the player presses this button — proximity alone MUST NOT trigger activation.
- **FR-004**: When the Teleport object is activated, the system MUST start a new run.
- **FR-005**: When the Teleport object is activated, the player MUST be placed in the dungeon's starting room.
- **FR-006**: The Teleport object MUST be visually distinct and permanently labelled "Teleport" so the player can identify it at a glance.
- **FR-007**: The hub room MUST NOT be considered part of the run. No run state changes occur while the player is in the hub.
- **FR-008**: If the player activates the Teleport while a run is already active, the action MUST be ignored with no side effects.
- **FR-009**: The Teleport object is a placeholder. Its visual representation MUST be replaceable without changes to the interaction logic.

### Key Entities

- **Hub Room**: The persistent world-space room where the player exists between runs. Not part of any run. Contains at least one Teleport object.
- **Teleport Object**: An in-world interactive element positioned in the hub. Contains a pressable button labelled "Teleport". Activates when the player presses the button (not on proximity alone). Triggers run start + player placement in the starting room. Visual placeholder — will be replaced with a graphical asset in a future iteration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The game starts with the player in the hub room — verified on 5 consecutive game launches with no dungeon room appearing first.
- **SC-002**: The Teleport object is visible and labelled in 100% of hub visits — no missing label, no invisible object.
- **SC-003**: Pressing the Teleport button starts the run and places the player in the starting room within 1 second on every press — verified across 10 activations.
- **SC-004**: Zero run-state changes occur while the player is in the hub (before Teleport activation) — verified by reading run state before and after hub navigation.
- **SC-005**: The Teleport placeholder can be visually replaced without breaking the activation behaviour — verified by swapping the visual asset and confirming the interaction still starts the run.

## Assumptions

- The hub is a 2D world scene (same coordinate space as dungeon rooms) where the player physically moves — not a UI menu or separate screen.
- Button-press activation: the Teleport fires when the player presses the "Teleport" button on the object. Proximity alone does not trigger activation — an explicit press is required.
- The "Teleport" button is a tappable/clickable element placed on the Teleport object in the game world. It is always visible (not a proximity-revealed HUD button).
- Run mode defaults to `"endless"` when launched from the Teleport. If multiple run modes exist later, mode selection will be handled separately.
- The hub uses the existing player scene — the same player node and components used in the dungeon.
- "Door-like" means the Teleport object has a physical presence in the world (a shape/body) with a text label. It does not need to look exactly like a door.
- There is no transition animation in this feature — the teleport is instantaneous.
- The hub scene is the game's entry scene (Bootstrap/Main loads hub first), replacing any direct dungeon entry that may currently exist.
- No "return to hub" flow is defined in this feature. What happens after a run ends (death, cash-out) is left to a future feature.

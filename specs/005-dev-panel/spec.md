# Feature Specification: Dev Panel

**Feature Directory**: `005-dev-panel`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "add dev panel with three buttons: start run, end run, cash out, start boss. dev panel should be enabled in a variable DEV_MODE. if dev_mode is true, instantiate nodes with the buttons that emit corresponding signals. keep cash out and start boss as stubs right now."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Panel Visibility Controlled by DEV_MODE (Priority: P1)

A developer can toggle a single flag (`DEV_MODE`) to show or hide the dev panel. When the flag is enabled, the panel and all its buttons appear in the game view. When disabled, nothing is instantiated — the panel has zero impact on the shipping game.

**Why this priority**: The flag is the foundation. All other buttons are meaningless without controlled visibility. This also ensures the panel cannot accidentally appear in production builds.

**Independent Test**: Set `DEV_MODE = true` and run the game. Confirm the panel is visible with all four buttons. Set `DEV_MODE = false` and run again. Confirm no panel or buttons are present and no errors occur.

**Acceptance Scenarios**:

1. **Given** `DEV_MODE` is `true`, **When** the game starts, **Then** the dev panel is visible and all four buttons are interactable.
2. **Given** `DEV_MODE` is `false`, **When** the game starts, **Then** no dev panel exists in the scene and no button-related nodes are instantiated.
3. **Given** `DEV_MODE` is `false`, **When** the game runs normally, **Then** no errors or warnings related to the dev panel appear.

---

### User Story 2 - Start Run and End Run Buttons (Priority: P2)

A developer can click **Start Run** to trigger a new run and **End Run** to terminate the active run, without navigating menus or writing code. This lets them rapidly iterate on in-run behaviour during testing.

**Why this priority**: Start Run and End Run are the core debugging actions — they exercise the run lifecycle that was just built. Cash Out and Start Boss are stubs and provide no functional value yet.

**Independent Test**: With `DEV_MODE = true` and no active run, click **Start Run**. Confirm a run starts (Output shows run started log). Click **End Run**. Confirm the run ends (Output shows run ended log). Both work independently of any game flow.

**Acceptance Scenarios**:

1. **Given** the dev panel is visible and no run is active, **When** the developer clicks **Start Run**, **Then** a new run begins immediately.
2. **Given** the dev panel is visible and a run is active, **When** the developer clicks **End Run**, **Then** the active run ends immediately.
3. **Given** the dev panel is visible, **When** **End Run** is clicked with no active run, **Then** nothing happens and no error occurs.
4. **Given** the dev panel is visible, **When** **Start Run** is clicked while a run is already active, **Then** the run resets and a new run starts.

---

### User Story 3 - Cash Out and Start Boss Stub Buttons (Priority: P3)

The **Cash Out** and **Start Boss** buttons are visible and clickable in the dev panel but have no game effect. Each logs a message confirming the button was pressed. The interface is established now so the real behaviour can be wired in a future feature without changing the panel layout.

**Why this priority**: The stub buttons reserve the UI real estate and signal interface. Actual functionality is out of scope for this feature.

**Independent Test**: With `DEV_MODE = true`, click **Cash Out** and **Start Boss**. Confirm a log message appears for each. Confirm no game state changes, no errors, and no crashes.

**Acceptance Scenarios**:

1. **Given** the dev panel is visible, **When** **Cash Out** is clicked, **Then** a log message confirms the press and no game state changes.
2. **Given** the dev panel is visible, **When** **Start Boss** is clicked, **Then** a log message confirms the press and no game state changes.
3. **Given** stub buttons exist, **When** real implementations are added in a future feature, **Then** no panel layout changes are required.

---

### Edge Cases

- What happens if `DEV_MODE` is changed at runtime after the game has started?
- What happens if **Start Run** is pressed multiple times rapidly?
- What happens if the panel overlaps interactive game elements?
- What happens if **End Run** is pressed before any run has ever started?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A single `DEV_MODE` flag MUST control whether the dev panel is instantiated. When `false`, zero dev panel nodes exist in the scene.
- **FR-002**: When `DEV_MODE` is `true`, the dev panel MUST appear at game start without any additional action from the developer.
- **FR-003**: The dev panel MUST contain exactly four buttons: **Start Run**, **End Run**, **Cash Out**, **Start Boss**.
- **FR-004**: Clicking **Start Run** MUST immediately start a new run.
- **FR-005**: Clicking **End Run** MUST immediately end the active run. If no run is active, the action MUST be a no-op with no error.
- **FR-006**: Clicking **Cash Out** MUST log a message and produce no other game effect (stub).
- **FR-007**: Clicking **Start Boss** MUST log a message and produce no other game effect (stub).
- **FR-008**: The dev panel MUST always be visible above game content — it must not be hidden behind other UI or world elements.
- **FR-009**: When `DEV_MODE` is `false`, the game MUST run identically to how it runs without this feature — no performance cost, no hidden nodes.

### Key Entities

- **DevPanel**: The container holding all four dev buttons. Only exists in the scene when `DEV_MODE` is true.
- **DEV_MODE**: A single flag that gates all dev panel instantiation. Changing it to `false` must guarantee zero panel presence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With `DEV_MODE = true`, all four buttons are visible and clickable within the first frame of game start.
- **SC-002**: Clicking **Start Run** or **End Run** produces a visible effect (run state change + log) within one frame of the click.
- **SC-003**: With `DEV_MODE = false`, zero dev panel nodes exist at any point during a game session.
- **SC-004**: Clicking **Cash Out** or **Start Boss** produces a log message with no other observable game state change.
- **SC-005**: Enabling then disabling `DEV_MODE` between sessions produces no leftover nodes or errors.

## Assumptions

- `DEV_MODE` is a constant defined in a single script — not a project setting or environment variable. It is changed by editing the script directly.
- The dev panel uses the run mode `"endless"` when **Start Run** is pressed, as a sensible default for iteration.
- Panel position is fixed to a corner of the screen (e.g. top-left) so it does not obstruct the centre of the game view.
- The panel does not persist between runs or scenes — it is always alive as long as `DEV_MODE` is true and the main scene is loaded.
- No authentication or access control is needed; DEV_MODE is a code-level toggle only visible to developers with source access.
- Cash Out and Start Boss stubs will be wired to real implementations in future features; the signal interface defined here must not change.

# Feature Specification: Book of Skill

**Feature Branch**: `071-book-of-skill`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "add another building named 'book of skill'. cost 250 shards (data-driven), should not be visible until scripted gate happens (3 boss kills gate). when 3 bosses are killed, display a popup with custom text, and on next visit in hub show 'book of skill' (as with other buildings, two modes - but not created and created instead of ruined/restored). inside should be only 'close' button for now"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Gate Unlock Popup (Priority: P1)

After the player kills their 3rd boss across any runs, a popup appears congratulating them and hinting that something new awaits in the hub. This is the moment the Book of Skill becomes available.

**Why this priority**: The gate event is the prerequisite for everything else — without it, the building never appears.

**Independent Test**: Kill 3 bosses (may span multiple runs). On the 3rd kill, verify a popup with the unlock message appears before returning to the hub.

**Acceptance Scenarios**:

1. **Given** the player has killed 0, 1, or 2 bosses, **When** a boss room is cleared, **Then** no Book of Skill popup appears.
2. **Given** the player has killed exactly 2 bosses, **When** the 3rd boss is cleared, **Then** a popup with Book of Skill unlock text is displayed.
3. **Given** the player has already triggered the 3-kill gate, **When** subsequent bosses are killed, **Then** the popup does NOT appear again.

---

### User Story 2 — Building Appears in Hub (Priority: P2)

After the gate is triggered, the player returns to the hub and sees the Book of Skill building for the first time in its "not created" state.

**Why this priority**: The visual discovery moment depends entirely on the gate having fired.

**Independent Test**: After the gate triggers, return to hub — verify the Book of Skill node is visible in its "not created" state. Before the gate, verify it is hidden.

**Acceptance Scenarios**:

1. **Given** the gate has not yet triggered, **When** the player visits the hub, **Then** the Book of Skill building is not visible.
2. **Given** the gate has triggered (3rd boss killed), **When** the player next enters the hub, **Then** the Book of Skill building is visible in its "not created" visual state.
3. **Given** the building is already created (purchased), **When** the player enters the hub, **Then** the building displays in its "created" visual state.

---

### User Story 3 — Purchase to Create (Priority: P3)

The player taps the Book of Skill building in "not created" state and is shown a purchase prompt. Spending 250 shards transitions the building to its "created" state permanently.

**Why this priority**: Core meta-progression transaction — the building's identity depends on this state transition.

**Independent Test**: With 250+ shards available, tap building → confirm purchase → verify building switches to "created" state and shards are deducted. Verify state persists after returning to hub.

**Acceptance Scenarios**:

1. **Given** the player has ≥ 250 shards, **When** they confirm the purchase, **Then** 250 shards are deducted and the building transitions to "created" state.
2. **Given** the player has < 250 shards, **When** they view the purchase prompt, **Then** the confirm button is disabled or shows an insufficient funds indicator.
3. **Given** the building is already in "created" state, **When** the player taps it, **Then** the interior screen opens directly (no purchase prompt).
4. **Given** the purchase is completed, **When** the player leaves and re-enters the hub, **Then** the building remains in "created" state.

---

### User Story 4 — Interior Screen (Priority: P4)

Tapping a "created" Book of Skill building opens its interior screen. Currently the screen contains only a "Close" button that dismisses it.

**Why this priority**: Establishes the interior shell for future skill content — lowest priority since there is no functional content yet.

**Independent Test**: Tap a "created" Book of Skill → interior screen opens → tap Close → interior screen closes, hub is fully interactive again.

**Acceptance Scenarios**:

1. **Given** the Book of Skill is in "created" state, **When** the player taps it, **Then** the interior screen opens.
2. **Given** the interior screen is open, **When** the player taps "Close", **Then** the screen dismisses and the hub is accessible.

---

### Edge Cases

- What if the player quits mid-run on the kill that would trigger the gate? Boss kill count must be persisted before the popup fires to avoid repeated popups.
- What if the player has ≥ 250 shards at gate trigger time? Building appearance and affordability are independent — the purchase prompt handles the balance check on tap.
- Can the popup be dismissed before reading it? Yes — a single "OK" or dismiss tap closes it; the gate is still considered triggered.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Book of Skill building MUST be hidden in the hub until the player's cumulative boss kill count reaches 3.
- **FR-002**: On the run that reaches the 3rd boss kill, the game MUST display a popup with a Book of Skill unlock message before the player returns to the hub.
- **FR-003**: The popup MUST appear at most once across all runs (gate is one-time only).
- **FR-004**: The "book_of_skill_gate_reached" flag MUST be persisted so the popup and building appearance survive game restarts.
- **FR-005**: Once the gate is reached, the Book of Skill MUST be visible in the hub on every subsequent visit in its current state ("not created" or "created").
- **FR-006**: The building MUST have two distinct visual states: "not created" and "created".
- **FR-007**: Tapping the building in "not created" state MUST show a purchase confirmation with the shard cost (default: 250 shards, read from config).
- **FR-008**: The purchase MUST be disabled when the player cannot afford the cost.
- **FR-009**: A successful purchase MUST deduct the shard cost and permanently transition the building to "created" state.
- **FR-010**: The "created" state MUST be persisted across sessions.
- **FR-011**: Tapping a "created" building MUST open the interior screen.
- **FR-012**: The interior screen MUST contain a "Close" button that dismisses it.
- **FR-013**: All cost values MUST be read from a data config file — no hardcoded numbers in logic.

### Key Entities

- **Book of Skill Building**: Hub node with two visual states (not created / created); visible only after gate; purchasable for 250 shards.
- **Gate State**: Persistent boolean tracking whether the 3-boss threshold has been crossed; used to show/hide the building and suppress duplicate popups.
- **Boss Kill Count**: Cumulative integer across all runs (already tracked in meta state as `endless_boss_kill_count`).
- **Unlock Popup**: One-time modal shown at the moment the gate fires; contains flavour text and a dismiss action.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The Book of Skill building is invisible in the hub for players with fewer than 3 cumulative boss kills, in 100% of test cases.
- **SC-002**: The unlock popup appears exactly once — on the run where the 3rd boss is killed — and never again.
- **SC-003**: Purchasing the building with sufficient shards transitions it to "created" state within one tap confirmation, and the state persists after hub re-entry.
- **SC-004**: The purchase is blocked (button disabled or absent) when the player has fewer shards than the configured cost.
- **SC-005**: Changing the cost value in the config file changes the displayed and enforced price without code modifications.

## Assumptions

- `endless_boss_kill_count` in `MetaState` already increments on each boss clear and is persisted — the gate reads from this field.
- The gate-reached flag is stored as a new `book_of_skill_gate_reached: bool` field in `MetaState`.
- The building's "created" state is stored as a new `book_of_skill_owned: bool` field in `MetaState`.
- Cost is stored under a `book_of_skill` key in `data/meta_config.json`, nested under a `book_of_skill.cost` path, consistent with other buildings.
- The popup reuses the existing `BossKillPopup` scene pattern (or a close equivalent) with custom text.
- The interior screen is a new minimal scene (just a Close button) — no content yet.
- Visual states use `ColorRect` placeholders consistent with other hub buildings until art is added.
- The building is a child node of `HubRoom.tscn`, added via the Godot Editor.

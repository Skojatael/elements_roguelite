# Feature Specification: Dungeon Expansion (Adventuring Gear)

**Feature Branch**: `033-dungeon-expansion`
**Created**: 2026-03-06
**Status**: Draft
**Input**: User description: "on first boss kill, unlock 'adventuring gear'. this is an upgrade that is shown on return to hub after first boss kill, it allows for dungeon expansion. dungeon expansion should take the maximum depth room A (room A becomes new frontier), if there are several, it doesn't matter which, and add another 4 rooms so that depth of the newly created rooms is strictly more than the depth of room A. expansion upgrade is purchasable for 300 shards. adjust grid to accommodate new rooms."

---

## User Scenarios & Testing

### User Story 1 — First Boss Kill Makes Adventuring Gear Purchasable (Priority: P1)

The player kills the boss for the first time. On returning to hub, the Adventuring Gear upgrade appears in the hub UI as a purchasable item costing 300 shards. If the player cannot yet afford it, the upgrade remains visible and available on every subsequent hub visit until purchased. Once purchased, it no longer appears as an option.

**Why this priority**: The upgrade becoming visible is the entry point to the entire feature. Nothing else is possible without it.

**Independent Test**: Kill the boss for the first time → cash out → return to hub → Adventuring Gear upgrade is visible, showing cost of 300 shards. Return to hub before killing the boss → no upgrade visible.

**Acceptance Scenarios**:

1. **Given** the player has never killed the boss, **When** they return to hub, **Then** the Adventuring Gear upgrade is NOT shown.
2. **Given** the player has killed the boss for the first time, **When** they return to hub, **Then** the Adventuring Gear upgrade IS shown with a cost of 300 shards.
3. **Given** the upgrade is available but not yet purchased, **When** the player returns to hub on a subsequent visit, **Then** the upgrade is still visible.
4. **Given** the upgrade has been purchased, **When** the player returns to hub, **Then** the upgrade is no longer shown.

---

### User Story 2 — Player Purchases Adventuring Gear (Priority: P2)

The player spends 300 shards to purchase the Adventuring Gear upgrade. The purchase is confirmed, shards are deducted, and the upgrade is permanently owned. From that point forward, all dungeon runs include 4 expansion rooms.

**Why this priority**: The purchase is required before any expansion can occur. The upgrade display (US1) without the ability to buy it delivers no gameplay value.

**Independent Test**: Have 300+ shards and Adventuring Gear available → purchase → shard balance decreases by 300 → start a new run → dungeon has 12 rooms.

**Acceptance Scenarios**:

1. **Given** the upgrade is available and player has ≥ 300 shards, **When** the player purchases, **Then** 300 shards are deducted and the upgrade is marked as owned.
2. **Given** the upgrade is available and player has < 300 shards, **When** the player taps the purchase button, **Then** nothing happens — the button is present but inactive and shards are unchanged.
3. **Given** the upgrade has been purchased, **When** the player starts a run, **Then** the dungeon contains 12 rooms (8 base + 4 expansion).

---

### User Story 3 — Expanded Dungeon in All Runs After Purchase (Priority: P3)

Every dungeon run after purchasing Adventuring Gear includes 4 additional rooms. These rooms branch outward from Room A — the deepest room in the base layout — making them strictly deeper than any base room. The dungeon grid is sized to always accommodate the full expansion without running out of space.

**Why this priority**: This is the core gameplay reward for the purchase. Without it, the upgrade has no effect.

**Independent Test**: With Adventuring Gear owned, start a run → navigate to the deepest base room → confirm doors lead into expansion rooms. Confirm all 4 expansion rooms have greater depth than Room A.

**Acceptance Scenarios**:

1. **Given** Adventuring Gear is owned, **When** a new run starts, **Then** the dungeon contains exactly 12 rooms (8 base + 4 expansion).
2. **Given** a dungeon has been generated with expansion, **When** examining each expansion room, **Then** every expansion room has a depth strictly greater than Room A's depth.
3. **Given** multiple rooms share the maximum depth in the base layout, **When** expansion occurs, **Then** any one of them may be chosen as Room A — all choices are valid.
4. **Given** Adventuring Gear has not been purchased, **When** a run starts, **Then** the dungeon contains the standard 8 rooms with no expansion.

---

### Edge Cases

- What happens on the run where the boss is killed? Expansion applies only to subsequent runs — the boss-kill run itself uses the base 8-room layout.
- Does Room A remain a normal combat room? Yes — Room A is cleared like any other room; expansion doors are only accessible after Room A is cleared (standard door behavior).
- What if the player has exactly 300 shards? The purchase succeeds and the balance reaches 0.

---

## Requirements

### Functional Requirements

- **FR-001**: The system MUST record a permanent meta flag ("first_boss_killed") on the player's first boss kill.
- **FR-002**: On any hub visit while the flag is set and the upgrade is not yet purchased, the Adventuring Gear upgrade MUST be shown with a cost of 300 shards.
- **FR-003**: If the player has ≥ 300 shards and confirms the purchase, the system MUST deduct 300 shards, mark the upgrade as owned, and hide it from the hub UI.
- **FR-004**: The purchase button MUST always be visible when the upgrade is available. If the player has < 300 shards, tapping the button MUST do nothing (no state change, no error message).
- **FR-005**: Once owned, Adventuring Gear MUST apply to every subsequent dungeon run automatically.
- **FR-006**: The dungeon grid MUST be sized large enough to guarantee all 4 expansion rooms can always be placed.
- **FR-007**: Expansion rooms MUST be seeded from Room A — the deepest room in the base dungeon layout (any room at max depth if there are ties).
- **FR-008**: Room A becomes the new frontier: expansion rooms MUST branch outward from Room A using the same growth algorithm as base dungeon generation.
- **FR-009**: Every expansion room MUST have a depth strictly greater than Room A's depth.
- **FR-010**: Expansion rooms MUST be reachable via standard doors from Room A.
- **FR-011**: Both the "first_boss_killed" flag and the "adventuring gear owned" flag MUST persist across sessions.

### Key Entities

- **Adventuring Gear** — a purchasable meta upgrade costing 300 shards. Becomes available after first boss kill. Once purchased, enables dungeon expansion in all subsequent runs.
- **Expansion Seed (Room A)** — the deepest room in the base dungeon layout, selected as the frontier for expansion. If multiple rooms tie for max depth, any one is valid.
- **Expansion Rooms** — the 4 rooms grown outward from Room A. Each has depth strictly greater than Room A's depth.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Adventuring Gear upgrade becomes visible in hub after exactly one boss kill, and disappears permanently after purchase.
- **SC-002**: The purchase correctly deducts exactly 300 shards when affordable; the button does nothing when balance is insufficient.
- **SC-003**: Every run after purchase contains exactly 12 rooms (8 base + 4 expansion) — no runs are ever short of rooms due to grid constraints.
- **SC-004**: All 4 expansion rooms have a depth strictly greater than the deepest base room's depth.
- **SC-005**: Expansion rooms are reachable from Room A via standard doors without passing through any room not in the dungeon.

---

## Assumptions

- "First boss kill" is detected at the moment of boss room clear. The flag persists even if the run ends via death rather than cash-out.
- The boss-kill run itself always uses the base 8-room layout.
- The hub notification/purchase UI is a visible element in the hub scene (exact form is a planning detail).
- The dungeon grid is enlarged (e.g. from 5×5 to 7×7 or similar) so that Room A always has enough unoccupied adjacent cells to grow 4 expansion rooms; the exact size is determined during planning.
- The expansion uses the same frontier-growth algorithm as the base dungeon generator, anchored at Room A rather than the center.
- Adventuring Gear is a one-time purchase — it cannot be bought more than once and is never lost.

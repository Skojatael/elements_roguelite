# Feature Specification: Unit Test Suite

**Feature Branch**: `039-gut-unit-tests`
**Created**: 2026-03-12
**Status**: Draft
**Input**: User description: "write unit tests using GUT framework and place them in res://tests/unit/*. each category - separate file. tests should be concerning this: cost_n = base_cost * 1.2^level / Dungeon generation — always connected, exactly N rooms / Modifier deck — no duplicates before reshuffle / Boss unlock logic — teleport available after X rooms"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Upgrade Cost Formula Correctness (Priority: P1)

A developer needs confidence that the upgrade cost formula computes `floor(base_cost × 1.2^level)` correctly at each level. If the formula drifts, players pay wrong prices and the balance table in documentation becomes wrong.

**Why this priority**: The cost formula is the economic foundation of meta-progression. An incorrect formula silently corrupts player experience across every upgrade purchase.

**Independent Test**: Independently testable by loading `MetaManagerImpl` without autoloads and asserting `get_upgrade_cost` outputs against a known cost table.

**Acceptance Scenarios**:

1. **Given** `base_cost=50` and `level=0`, **When** cost is computed, **Then** result is `50`.
2. **Given** `base_cost=50` and `level=1`, **When** cost is computed, **Then** result is `60` (`floor(50 × 1.2)`).
3. **Given** `base_cost=50` and `level=2`, **When** cost is computed, **Then** result is `72` (`floor(60 × 1.2)`).
4. **Given** `base_cost=50` and `level=9`, **When** cost is computed, **Then** result matches the documented cost table entry for level 9 (`253`).
5. **Given** `level=0`, **When** cost is computed, **Then** result equals `base_cost` regardless of scale.

---

### User Story 2 - Dungeon Graph Connectivity (Priority: P1)

A developer needs confidence that every dungeon layout produced by `DungeonGenerator` is a fully connected graph — every room is reachable from the start room. A disconnected dungeon traps the player.

**Why this priority**: Connectivity is a hard correctness constraint. A single disconnected layout in production locks the player out of rooms with no recovery path.

**Independent Test**: Independently testable by instantiating `DungeonGenerator` in isolation, calling its generation logic, and running a BFS/DFS from `start_room_id` to verify all room IDs in `rooms_by_id` are visited.

**Acceptance Scenarios**:

1. **Given** a freshly generated dungeon, **When** a graph traversal starts from `start_room_id`, **Then** every room ID in `rooms_by_id` is reachable.
2. **Given** `neighbours_by_id`, **When** any room's neighbour list is inspected, **Then** the relationship is symmetric (if A lists B, B lists A).
3. **Given** generation runs multiple times with different seeds, **When** each result is checked, **Then** connectivity holds in every case.

---

### User Story 3 - Dungeon Room Count (Priority: P1)

A developer needs confidence that `DungeonGenerator` always produces exactly the configured number of rooms (`base_room_count` from config). Too few rooms means missing content; too many means out-of-bounds world positions or unintended room types.

**Why this priority**: Room count drives content volume per run. Off-by-one errors compound with other systems (boss gate, essence rewards, relic offer intervals).

**Independent Test**: Independently testable by instantiating `DungeonGenerator`, running generation, and asserting `rooms_by_id.size() == expected_count`.

**Acceptance Scenarios**:

1. **Given** `base_room_count=9` in config and adventuring gear not owned, **When** dungeon is generated, **Then** `rooms_by_id` contains exactly 9 entries.
2. **Given** `base_room_count=9` and adventuring gear owned (expansion enabled), **When** dungeon is generated, **Then** `rooms_by_id` contains exactly 13 entries.
3. **Given** generation is run multiple times, **When** room counts are collected, **Then** the count is the same every time (deterministic room count, not random).

---

### User Story 4 - Relic Deck No Duplicates Before Reshuffle (Priority: P2)

A developer needs confidence that the relic offer deck never serves the same relic twice within a single pass through the deck. Duplicates make offers feel repetitive and break the guarantee that players see variety before repeats.

**Why this priority**: The no-duplicate guarantee is a core design constraint of the relic system. Violating it degrades perceived offer quality.

**Independent Test**: Independently testable by building a pool with a small known set of relics, drawing repeatedly, and asserting no ID repeats until the deck is exhausted and reshuffled.

**Acceptance Scenarios**:

1. **Given** a pool with N relics of one tier, **When** N relics are drawn from that tier's deck, **Then** all N relic IDs are distinct.
2. **Given** a deck is fully exhausted, **When** the next draw triggers a reshuffle, **Then** all N relics are available again (reshuffle restores full pool).
3. **Given** `draw_offer()` is called, **When** the two offered relics are compared, **Then** they have different IDs (the pair itself contains no duplicate).
4. **Given** a player already holds relic X, **When** a boss offer is drawn, **Then** relic X does not appear in the offer.
5. **Given** a pool containing both common/uncommon and rare relics, **When** `draw_offer()` is called after a standard room clear, **Then** none of the returned relics have tier `"rare"`.
6. **Given** a pool containing rare relics, **When** `draw_boss_offer()` is called, **Then** every returned relic has tier `"rare"`.

---

### User Story 5 - Boss Teleport Unlock Threshold (Priority: P2)

A developer needs confidence that the boss teleport button becomes available at exactly the correct number of cleared rooms, and not before. Premature access allows skipping content; delayed access frustrates players who have earned the encounter.

**Why this priority**: The boss gate is a progression milestone. An off-by-one error either locks out earned content or bypasses the required rooms.

**Independent Test**: Independently testable by simulating `cleared_rooms.size()` values against the threshold check in isolation and asserting button visibility.

**Acceptance Scenarios**:

1. **Given** `rooms_required=6` for the boss enemy, **When** `cleared_rooms.size() == 5`, **Then** the teleport button is not shown.
2. **Given** `rooms_required=6`, **When** `cleared_rooms.size() == 6`, **Then** the teleport button is shown.
3. **Given** `rooms_required=6`, **When** `cleared_rooms.size() > 6`, **Then** the teleport button remains shown.
4. **Given** a new run starts, **When** the run begins, **Then** the teleport button is hidden regardless of previous run state.

---

### Edge Cases

- What happens when `base_cost` is 0 for the cost formula? (Expected: always 0)
- What happens when the dungeon config pool is empty? (Generator should error-out gracefully, not produce a partial layout)
- What happens when the relic pool has only 1 relic and `draw_offer()` is called? (Should return a single-element array or handle gracefully)
- What happens when all rare relics are already held by the player and a boss offer is requested? (Expected: empty array returned)
- What happens when `rooms_required=0` for a non-boss enemy? (Threshold check should never show the boss button for that ID)

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Test suite MUST be organised into four separate files under `res://tests/unit/`: one per category (upgrade cost, dungeon generation, relic deck, boss unlock).
- **FR-002**: Each test file MUST extend `GutTest` and follow the conventions established in `tests/unit/test_shard_conversion.gd`.
- **FR-003**: Upgrade cost tests MUST verify `get_upgrade_cost(level, base_cost, scale)` for `level` 0 through 9 against the documented cost table (`50, 60, 72, 86, 103, 123, 147, 176, 211, 253`).
- **FR-004**: Dungeon generation tests MUST verify connectivity by performing a graph traversal from `start_room_id` across `neighbours_by_id` and asserting all rooms in `rooms_by_id` are visited.
- **FR-005**: Dungeon generation tests MUST verify `rooms_by_id.size()` equals `base_room_count` (9) without adventuring gear.
- **FR-006**: Relic deck tests MUST verify that drawing all relics from a tier deck yields no duplicate IDs before the deck is exhausted.
- **FR-007**: Relic deck tests MUST verify that `draw_offer()` never returns two relics with the same ID.
- **FR-011**: Relic deck tests MUST verify that `draw_offer()` never returns a relic of tier `"rare"` — rare relics are excluded from the standard weight table and must not appear in regular room offers.
- **FR-012**: Relic deck tests MUST verify that `draw_boss_offer()` returns only relics of tier `"rare"` — boss offers draw exclusively from the rare pool.
- **FR-008**: Boss unlock tests MUST verify the threshold condition: unavailable at `cleared < rooms_required`, available at `cleared >= rooms_required`.
- **FR-009**: Tests MUST NOT depend on autoloaded singletons (`RunManager`, `MetaManager`, `ResourceManager`, `SaveManager`) — subject classes must be instantiated directly or via stub data.
- **FR-010**: Each test function name MUST describe the scenario it verifies (e.g. `test_cost_at_level_0_equals_base`).

### Key Entities

- **MetaManagerImpl**: Pure GDScript `RefCounted` holding upgrade cost logic. Testable without autoloads.
- **DungeonGenerator**: `Node` containing the frontier-expansion algorithm. Requires a stub dungeon config dictionary to run without `ResourceManager`.
- **RelicManagerImpl**: `RefCounted` holding deck draw logic. Requires a stub relics dictionary and config to build a pool.
- **Threshold Check**: The integer comparison `cleared_rooms.size() >= rooms_required` extracted from `ExplorationHUD` or `RunManager` — testable as a pure function.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All four test files execute without errors in GUT's test runner; 0 failures, 0 errors on a clean project.
- **SC-002**: Upgrade cost tests cover all 10 documented levels (0–9) — 100% of the specified cost table is asserted.
- **SC-003**: Dungeon connectivity tests run generation at least 5 times with different random seeds and pass every time, covering non-deterministic layout variance.
- **SC-004**: Relic deck tests draw the full deck contents at least twice (two complete passes) and confirm no intra-pass duplicates on each pass.
- **SC-005**: Boss unlock tests cover all three boundary cases (one below threshold, at threshold, one above threshold) and the run-reset case — 4 assertions minimum.
- **SC-006**: No test takes longer than 1 second to run individually, keeping the full suite fast enough for iteration during development.

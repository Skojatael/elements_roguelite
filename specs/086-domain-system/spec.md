# Feature Specification: Domain System

**Feature Branch**: `086-domain-system`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "organize enemies, rooms and bosses by domain. the structure for enemies should be {normal: {forest:{...}, desert:{...}, frost:{...}},elite: {same as normal}, boss: {same as normal}}. if forest in name, it is forest domain. teleport to dungeon should also differ by domain - essentially, there should be three buttons (defer non-forest buttons for now). if forest teleport button is pressed, rooms with Forest in name should be used to generate dungeon - suggest how to organize this."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start a Forest Domain Run (Priority: P1)

A player opens the hub and sees three domain teleport buttons: Forest, Desert, and Frost. Only the Forest button is active. They press Forest, and the dungeon is generated using only forest-themed rooms and populated with only forest enemies. The experience feels cohesive — all visual and mechanical elements belong to the same domain.

**Why this priority**: This is the entire new run entry point. Without it, no domain-specific content is accessible.

**Independent Test**: Press the Forest teleport button. Enter the dungeon. Verify every combat room is a Forest-prefixed room and every spawned enemy is a forest-domain enemy.

**Acceptance Scenarios**:

1. **Given** the hub is active, **When** the player views the teleport area, **Then** three domain buttons are displayed (Forest, Desert, Frost); Desert and Frost are non-interactive (disabled or labelled "Coming Soon").
2. **Given** the player presses the Forest button, **When** the dungeon generates, **Then** the combat room pool contains only rooms whose names include "Forest".
3. **Given** the dungeon is generated for the forest domain, **When** enemies spawn in any room, **Then** every enemy belongs to the forest domain.
4. **Given** a boss room is reached, **When** the boss spawns, **Then** the boss is the forest-domain boss.

---

### User Story 2 - Enemy Data Organised by Domain (Priority: P2)

Enemy data is restructured so that each tier (normal, elite, boss) groups enemies by domain. Finding or adding all forest enemies means navigating to `normal.forest`, `elite.forest`, and `boss.forest` — no cross-domain entries are mixed together.

**Why this priority**: Correct data organisation is the prerequisite for domain filtering at runtime. Without it, the game cannot reliably select "forest enemies only."

**Independent Test**: Open the enemy data file. Confirm the top-level keys are `normal`, `elite`, and `boss`. Confirm each tier contains a `forest` sub-key whose values are enemy definitions (no array — keyed by enemy ID). Confirm no enemy definition lives outside a domain sub-key.

**Acceptance Scenarios**:

1. **Given** the enemy data file is opened, **When** the top-level structure is inspected, **Then** only the keys `normal`, `elite`, and `boss` are present (not `common` or a flat array).
2. **Given** the `normal` tier, **When** the `forest` sub-key is inspected, **Then** all forest normal enemies are present, each keyed by their ID.
3. **Given** any enemy entry, **When** the entry is read, **Then** no redundant `"domain"` field is present — domain membership is conveyed by its position in the hierarchy.

---

### Edge Cases

- What if a room name contains "Forest" but belongs to a different game tier (e.g., start room, boss room)? Start and boss rooms are not part of the combat pool and are unaffected by domain filtering.
- What if the selected domain has no rooms in the pool? The dungeon generator falls back to a warning and uses the full unfiltered pool (defensive fallback).
- What happens when Desert or Frost buttons are pressed? Nothing — the buttons are non-interactive in this iteration. They are visible but disabled.
- What if a depth band references an enemy ID that no longer exists under the new structure? The spawner's existing unknown-ID guard catches it and logs an error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The enemy data file MUST be restructured so the top-level keys are `normal`, `elite`, and `boss` (replacing the current `enemies` wrapper and `common` category name).
- **FR-002**: Within each tier, enemies MUST be grouped by domain sub-key (`forest`, `desert`, `frost`). Each domain sub-key is a dictionary keyed by enemy ID, not an array.
- **FR-003**: The redundant per-entry `"domain"` field MUST be removed from every enemy definition; domain is conveyed solely by position in the hierarchy.
- **FR-004**: The hub teleport area MUST display three domain buttons: Forest, Desert, and Frost.
- **FR-005**: The Desert and Frost buttons MUST be non-interactive (visually present but disabled) in this iteration.
- **FR-006**: Pressing the Forest button MUST start a run with domain set to `"forest"`.
- **FR-007**: When domain is `"forest"`, the dungeon generator MUST build the combat room pool using only room type IDs whose names contain `"Forest"`.
- **FR-008**: The domain-specific combat room pool MUST be defined in the dungeon configuration data file, not derived by string-matching at runtime — the data file is the source of truth for which rooms belong to which domain.
- **FR-009**: The dungeon configuration MUST organise combat room pools by domain: `combat_room_pools.forest`, `combat_room_pools.desert`, `combat_room_pools.frost`.
- **FR-010**: Enemy spawners MUST select enemies only from the active run's domain. Depth-band wave slots MUST resolve to enemies within the current domain.
- **FR-011**: The active domain MUST be accessible to all systems that need it (dungeon generator, enemy spawner, boss spawner) for the duration of the run.
- **FR-012**: All existing consumers of enemy data (spawners, resource caches, test stubs) MUST continue to work correctly after the data restructure — no silent breakage.

### Key Entities

- **Domain**: A named content grouping (`forest`, `desert`, `frost`). Identifies which rooms and enemies belong together.
- **Combat Room Pool (per domain)**: The list of room type IDs eligible for random selection during dungeon generation for a given domain.
- **Enemy Tier**: One of `normal`, `elite`, or `boss`. Each tier is sub-divided by domain.
- **Active Run Domain**: The domain selected when the player presses a teleport button. Stored for the duration of the run.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every enemy entry in the restructured data file is reachable via `tier → domain → enemy_id` with zero entries outside this three-level hierarchy.
- **SC-002**: Starting a forest run and completing 5 rooms results in 0 non-forest enemies encountered and 0 non-forest rooms entered.
- **SC-003**: The hub displays exactly 3 domain buttons; exactly 1 is interactive (Forest); the other 2 are non-interactive.
- **SC-004**: All existing unit tests that reference enemy data continue to pass after the restructure (0 regressions).
- **SC-005**: The dungeon configuration file contains a `combat_room_pools` section with at minimum a `forest` key populated with at least one room type ID.

## Assumptions

- "Normal" replaces the existing "common" category — they are the same tier of enemies.
- Domain membership for rooms is determined by the data file (explicit list), not by runtime string matching. String matching ("if Forest in name") is the authoring convention used to initially populate the data, not the runtime mechanism.
- Desert and Frost domains have no content yet; their data stubs (`normal.desert`, `normal.frost`, etc.) may be empty dictionaries or omitted — the schema supports them but they need not be populated.
- The single existing TeleportDoor scene is replaced or extended to show three buttons; the underlying run-start flow is unchanged except that the selected domain is passed along.
- The active domain is stored on RunManager for the duration of the run (reset on run end).
- Depth-band enemy pools in dungeon_config.json reference enemy IDs directly; those IDs remain unchanged — only the file structure around them changes.
- Boss room domain filtering follows the same rule: the boss spawned is the one under `boss.forest` when domain is forest.

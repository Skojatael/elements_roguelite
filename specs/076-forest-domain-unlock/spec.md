# Feature Specification: Forest Domain Unlock

**Feature Branch**: `076-forest-domain-unlock`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "add a gate for domains: in book of skill, add upgrade that unlocks forest relics, data-driven cost 40 shards. when upgrade is not purchased, forest relics are not offered. ask for clarification if needed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Forest Relics Blocked Until Unlocked (Priority: P1)

Before purchasing the Forest Domain upgrade, no forest relics ever appear in relic offer screens. The player only sees neutral and desert relics. Once they purchase the upgrade, forest relics enter the offer pool for all future runs.

**Why this priority**: The gating behaviour is the core of the feature — everything else supports it.

**Independent Test**: Start a run without the upgrade purchased. Clear multiple rooms and verify no forest relics (Venom Fang, Rootweave Band) ever appear in offers. Then purchase the upgrade and repeat — verify forest relics can now appear.

**Acceptance Scenarios**:

1. **Given** the Forest Domain upgrade has not been purchased, **When** the player receives a relic offer, **Then** no forest-domain relics appear in the offer options.
2. **Given** the Forest Domain upgrade has been purchased, **When** the player receives a relic offer, **Then** forest-domain relics may appear alongside neutral and other unlocked relics.
3. **Given** the upgrade is purchased mid-session (in the hub between runs), **When** the player starts the next run, **Then** forest relics are included in that run's pool.

---

### User Story 2 — Purchase the Upgrade in Book of Skill (Priority: P2)

Inside the Book of Skill, the player sees a Forest Domain upgrade entry showing the name, description, cost (40 shards), and a buy button. If they can afford it, they tap the button to purchase. The button becomes permanently disabled (showing "Unlocked") after purchase.

**Why this priority**: The purchase UI is required for the gate to be functional.

**Independent Test**: Open Book of Skill with ≥ 40 shards — verify upgrade entry is visible with cost shown and button enabled. Purchase it — verify shards deducted, button disabled, state persists after closing and reopening.

**Acceptance Scenarios**:

1. **Given** the player has ≥ 40 shards and the upgrade is not yet purchased, **When** they view the Book of Skill interior, **Then** the Forest Domain entry shows an enabled buy button with the 40-shard cost.
2. **Given** the player has < 40 shards and the upgrade is not yet purchased, **When** they view the Book of Skill interior, **Then** the buy button is disabled (cannot afford).
3. **Given** the player purchases the upgrade, **When** the purchase is confirmed, **Then** 40 shards are deducted and the button changes to a permanent "Unlocked" state.
4. **Given** the upgrade has been purchased, **When** the player reopens the Book of Skill on a later hub visit, **Then** the entry shows "Unlocked" and no buy action is available.

---

### Edge Cases

- What if the player purchases the upgrade during a run? Not possible — the Book of Skill is a hub-only building; upgrades can only be purchased between runs.
- What if the pool has no forest relics eligible for the current mechanic state? Forest relics follow the same eligibility rules as all other relics (mechanic tag gates, already-held exclusions). The upgrade only controls domain inclusion — it does not bypass other eligibility checks.
- What if the cost in config is changed after the upgrade is already owned? The upgrade is a permanent one-time purchase; cost changes do not retroactively refund or re-charge.
- What if all forest relics are already held? Standard relic-pool exhaustion behaviour applies — no forest relics can be drawn, as with any tier when all are held.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Forest Domain upgrade MUST be displayed in the Book of Skill interior screen.
- **FR-002**: The upgrade cost MUST be read from the data config file (default: 40 shards). No hardcoded cost values in logic.
- **FR-003**: The buy button MUST be disabled when the player cannot afford the cost.
- **FR-004**: A successful purchase MUST deduct the configured shard cost and permanently record the upgrade as owned.
- **FR-005**: The owned state MUST persist across sessions (survive game restarts).
- **FR-006**: When the upgrade is NOT owned, relics with domain `"forest"` MUST be excluded from all relic offer draws.
- **FR-007**: When the upgrade IS owned, relics with domain `"forest"` MUST be included in the offer pool alongside all other eligible relics.
- **FR-008**: The forest domain gate MUST apply per-run — the pool is evaluated at run start based on the current ownership state.
- **FR-009**: After purchase the Book of Skill interior MUST show the upgrade in a permanent "Unlocked" state with no buy action available.

### Key Entities

- **Forest Domain Upgrade**: A purchasable upgrade entry in the Book of Skill interior. One-time, permanent. Cost configured in data. Ownership stored in meta state.
- **Domain Gate**: The filtering rule applied when building the relic offer pool — relics whose domain is `"forest"` are excluded unless the Forest Domain upgrade is owned.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of relic offers generated without the upgrade, zero forest-domain relics appear.
- **SC-002**: After purchasing the upgrade, forest-domain relics appear in offers within a reasonable number of rooms (probabilistic — verifiable across ≥ 10 offer draws).
- **SC-003**: Purchasing with sufficient shards deducts the correct amount in a single tap and shows "Unlocked" immediately.
- **SC-004**: Changing the cost value in the config file changes the displayed and enforced price without any code modifications.
- **SC-005**: The purchased state is retained after closing and relaunching the game.

## Assumptions

- The Book of Skill interior currently only has a Close button; this feature adds the first upgrade entry to that interior.
- `MetaState` gains a new `forest_domain_unlocked: bool` field (default `false`); stored and loaded via `SaveManager` alongside other meta fields.
- The cost lives under a new `book_of_skill.upgrades.forest_domain.cost` key in `data/meta_config.json`, consistent with the Mage Tower upgrade cost structure.
- Domain filtering is applied in `RelicManagerImpl` when building the relic pool at run start — relics with `domain == "forest"` are skipped unless `MetaManager.is_forest_domain_unlocked`.
- No new scene is required for the upgrade entry — the Book of Skill interior screen is updated to include it alongside the existing Close button.
- Visual state of the upgrade (enabled/disabled/unlocked) follows the same pattern as `MageTowerUpgradeScreen` buttons.

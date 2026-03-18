# Tasks: Enemy Spawn Delay

**Input**: Design documents from `specs/057-enemy-spawn-delay/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, quickstart.md ✅

**Tests**: All logic lives inside `Enemy._ready()` and `_physics_process()` — both require a live Node tree and autoload access. No extractable pure logic → GUT unit tests not applicable. Manual in-editor validation only.

**Organization**: Single user story, two modified files. Tasks are sequential.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Blocking Prerequisite)

**Purpose**: JSON data must exist before `Enemy.gd` can read it.

- [x] T001 Add `"enemy_spawn": { "spawn_delay": 1.0 }` as a top-level block in `data/dungeon_config.json`

**Checkpoint**: Data layer ready. `Enemy.gd` changes can now begin.

---

## Phase 2: User Story 1 — Enemies Pause Before Engaging (Priority: P1) 🎯 MVP

**Goal**: Every enemy is inactive for 1.0 second after spawning — no movement, no contact damage.

**Independent Test**: Enter CombatRoom01, stand still at room center. Observe enemies are stationary for ~1 second before pursuing. Receive no contact damage during that window.

### Implementation for User Story 1

- [x] T002 [US1] In `scenes/combat/enemies/Enemy.gd`, add `var _spawn_delay: float = 0.0`. In `_ready()`, after `initialize()`, read `ResourceManager.get_dungeon_config().get("enemy_spawn", {}).get("spawn_delay", 1.0)` and assign to `_spawn_delay`.

- [x] T003 [US1] In `scenes/combat/enemies/Enemy.gd`, add an early-return guard at the very top of `_physics_process()`: `if _spawn_delay > 0.0: _spawn_delay -= delta; return`. This must appear before the burn tick, contact damage tick, and pursuit movement blocks.

**Checkpoint**: Enemies freeze for 1 second on spawn. Damage and death still work normally during the delay.

---

## Phase 3: Polish & Validation

- [ ] T004 Run quickstart.md validation scenarios 1–4: stationary freeze, wave 2 freeze, damage during delay, all enemies pursuing within 1.5 s.

- [x] T005 Update `repo_map.md`: add `_spawn_delay: float` field to the `Enemy` entry under Scenes — Combat.

---

## Dependencies & Execution Order

- **T001** has no dependencies — start immediately.
- **T002** depends on T001 (JSON key must exist to read it).
- **T003** depends on T002 (`_spawn_delay` field must exist).
- **T004** depends on T002 + T003 (full feature must be implemented).
- **T005** can run alongside T004.

---

## Implementation Strategy

1. T001 — add JSON key
2. T002 → T003 — implement guard in Enemy.gd
3. **STOP and VALIDATE** via T004
4. T005 — repo_map update

---

## Notes

- `_spawn_delay` defaults to `1.0` in the `get()` fallback — safe even if `dungeon_config.json` is missing the key.
- Burn damage is intentionally **not** blocked during the delay (burn is player-initiated, not enemy-initiated; no spec requirement to suppress it).
- The guard uses a single early return — Constitution VI compliant, nesting depth 0 for the main logic.

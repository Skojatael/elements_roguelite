# Tasks: HP Regeneration

**Input**: Design documents from `/specs/060-hp-regen/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: 2 file changes total. US2 (regen stops on run end) and US3 (rate scales with max HP) are both satisfied automatically by the same implementation as US1 — no separate code tasks. Each has a dedicated validation task.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

*No project initialisation required — this feature modifies two existing files only.*

---

## Phase 2: Foundational (Constitution II — Data First)

**Purpose**: JSON schema must be defined before any GDScript implementation begins (Constitution II).

**⚠️ CRITICAL**: T001 must be complete before T002 begins.

- [x] T001 Add `common_regen` relic entry to `data/relics.json` under the `"common"` tier: `"common_regen": { "name": "Regeneration Stone", "tags": ["survival"], "effect_stat": "hp_regen", "effect_mult": 0.01, "description": "+1% HP per second" }`

**Checkpoint**: `data/relics.json` parses cleanly; `common_regen` appears in the common pool when a run starts (verify via DevPanel → Get Relic or print log).

---

## Phase 3: User Story 1 — Passive HP Recovery During a Run (Priority: P1) 🎯 MVP

**Goal**: Player HP ticks upward at 1% max HP/sec while a run is active and a regen relic is held.

**Independent Test**: Start a run, pick up `common_regen` via DevPanel, take damage, stand still — observe HP bar refilling. Verify HP stops at max.

### Implementation for User Story 1

- [x] T002 [US1] Add `_process(delta: float) -> void` to `scenes/player/components/StatsComponent.gd` with four guard clauses (`not is_player`, `not RunManager.is_run_active`, `rate <= 0.0`, `current_health >= max_health`) then `heal(RelicManager.get_stat_addend("hp_regen") * max_health * delta)`

**Checkpoint**: US1 fully functional. Player HP visibly recovers when `common_regen` is held; HP bar stops at max.

---

## Phase 4: User Story 2 — Regen Clears on Run End (Priority: P2)

**Goal**: Confirm regeneration does not tick in the hub or between runs.

**Independent Test**: End a run while holding `common_regen`; return to hub; HP bar must not change passively.

> **No additional code required.** The `RunManager.is_run_active` guard in T002 satisfies this story. This phase is a validation-only checkpoint.

### Validation for User Story 2

- [ ] T003 [US2] Validate run-end guard: complete a run while holding `common_regen`, return to hub, confirm HP does not tick in `scenes/player/components/StatsComponent.gd` (observe HP bar is static in hub and after run ends)

**Checkpoint**: HP bar is static in hub. Starting a new run without a regen relic produces no passive HP gain.

---

## Phase 5: User Story 3 — Regen Rate Scales With Max HP (Priority: P3)

**Goal**: Confirm that picking up a max-health relic increases the absolute HP healed per second proportionally.

**Independent Test**: Hold `common_regen` + `iron_hide` (+15% max HP); verify per-second HP gain is 1% of the boosted max HP, not the base max HP.

> **No additional code required.** The formula `rate * max_health * delta` in T002 reads the live `max_health` value, which `_on_relic_applied` already updates when health relics are picked up.

### Validation for User Story 3

- [ ] T004 [US3] Validate max-HP scaling: in a run, pick up `iron_hide` (or any max-health relic) after `common_regen`; confirm the per-second HP gain visibly increases — the regen tick in `scenes/player/components/StatsComponent.gd` reads `max_health` live so no code change is expected

**Checkpoint**: Regen heals a larger absolute amount after a max-health relic is acquired.

---

## Phase 6: Polish & Validation

**Purpose**: End-to-end playtest per quickstart.md.

- [ ] T005 Run all six verification steps in `specs/060-hp-regen/quickstart.md` and confirm SC-001 through SC-004 from spec.md are satisfied

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately.
- **US1 (Phase 3)**: Depends on T001 (data must exist before code reads it).
- **US2 (Phase 4)**: Depends on T002 (validates its guard clause).
- **US3 (Phase 5)**: Depends on T002 (validates its formula).
- **Polish (Phase 6)**: Depends on T002–T004 all passing.

### User Story Dependencies

- **US1**: Depends on Foundational only.
- **US2**: Depends on US1 implementation (same code, different test condition).
- **US3**: Depends on US1 implementation (same code, different test condition).

### Parallel Opportunities

T003 and T004 can be validated in parallel — they test different behaviours of the same `_process()` method and do not conflict.

---

## Parallel Example: US2 + US3 Validation

```
After T002 is complete:
  T003 [US2] — test run-end guard (hub session)
  T004 [US3] — test max-HP scaling (same run, pick up two relics)
```

Both validations can be done in the same play session in sequence.

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001 — Add JSON entry
2. T002 — Add `_process()` to StatsComponent
3. Validate HP refills in-run, stops at max
4. **STOP and DEMO** — regeneration is fully playable

### Full Delivery

1. T001 → T002 → T003 → T004 → T005 (linear; ~10 min total)

---

## Notes

- No new files, scenes, or editor work required.
- `heal()` already clamps HP to `max_health` and emits `health_changed` — no extra wiring needed for HP bar or RunManager player-state sync.
- GUT unit tests are not included: `StatsComponent` is a Node subclass with `RunManager` and `RelicManager` autoload dependencies and is not testable without autoloads. No new `*Impl.gd` files are introduced.

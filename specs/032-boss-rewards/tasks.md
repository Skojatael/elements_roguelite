# Tasks: Boss Rewards

**Input**: Design documents from `specs/032-boss-rewards/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: Foundational

**Purpose**: Data change + bug fix + new draw method. All three are independent of each other and block the user story phases.

- [x] T001 [P] Change `"base_essence"` from `0` to `80` in the boss entry of `data/enemies.json`
- [x] T002 [P] Add `if room_id == "boss_room": return` as the first guard clause in `_on_room_cleared(room_id: String)` in `autoload/RelicManager.gd` (prevents boss room clear from corrupting the regular relic offer counter — see contracts/interfaces.md)
- [x] T003 [P] Add `draw_boss_offer() -> Array[RelicData]` to `scripts/managers/RelicManagerImpl.gd`: iterate `_all_by_tier["rare"]`, skip ids in `active_relic_ids`, shuffle result, return `available.slice(0, mini(3, available.size()))` — return `[]` early if `"rare"` tier absent (see contracts/interfaces.md for full code)

**Checkpoint**: enemies.json has base_essence=80 for boss. RelicManager no longer corrupts offer counter on boss room clear. draw_boss_offer() compiles and returns up to 3 rare relics.

---

## Phase 2: User Story 1 — Boss Awards Scaled Essence (Priority: P1) 🎯 MVP

**Goal**: Killing the boss adds `floori(80 × (1 + 0.06 × max(0, rooms_cleared − 6)))` to run currency. Victory overlay appears after the relic offer (or directly if no rare relics remain).

**Independent Test**: DevPanel "Start Boss" from hub (0 rooms cleared) → kill boss → pick relic → press Cash Out → Results Screen shows 80 essence from boss (plus any dungeon kills). At 7 rooms cleared → 84 essence.

- [x] T004 [US1] Add `trigger_boss_offer() -> bool` to `autoload/RelicManager.gd`: calls `_impl.draw_boss_offer()`, returns `false` and prints if empty, otherwise emits `relic_offer_ready(options)` and returns `true` (depends T003 — uses draw_boss_offer)
- [x] T005 [P] [US1] Add `var _boss_relic_pending: bool = false` to `scenes/core/Main.gd` field declarations, and add `_boss_relic_pending = false` as the first line of `_on_run_started()`
- [x] T006 [US1] In `scenes/core/Main.gd`: (a) extract the CanvasLayer + overlay instantiation + signal connection code from the current `_on_boss_room_cleared()` into a new private method `_show_boss_victory_overlay()`; (b) rewrite `_on_boss_room_cleared()` to: null `_boss_room_spawner`, compute and award scaled essence via `RunManager.add_currency(floori(base * (1.0 + 0.06 * float(maxi(0, rooms_cleared - 6)))))` where `base = ResourceManager.get_enemy_base_essence("boss")`, hide ExplorationHUD, then call `RelicManager.trigger_boss_offer()` — if it returns `true` set `_boss_relic_pending = true`, else call `_show_boss_victory_overlay()` directly (depends T001, T004, T005 — see contracts/interfaces.md for full code)

**Checkpoint**: Boss killed → essence awarded → relic offer shows (3 rare cards) → picking a relic restores ExplorationHUD (wrong — US2 fixes this) → victory overlay does NOT appear yet after pick (regression to fix in US2).

---

## Phase 3: User Story 2 — Relic Offer Gates Victory Overlay (Priority: P2)

**Goal**: After the player picks a relic from the boss offer, the victory overlay appears instead of restoring ExplorationHUD.

**Independent Test**: Kill boss → 3 rare relics offered → pick one → confirm victory overlay appears (not HUD) → Cash Out → Results Screen shows correct essence.

- [x] T007 [US2] Modify `_on_relic_picked(relic_id: String)` in `scenes/core/Main.gd`: after freeing `_relic_offer_layer`, add `if _boss_relic_pending: _boss_relic_pending = false; _show_boss_victory_overlay()` branch before the existing `else: _exploration_hud.visible = true` (depends T005, T006)

**Checkpoint**: Full flow works — boss killed → essence awarded → 3 rare relics offered → pick one → victory overlay → Cash Out → Results Screen. Fallback (no rare relics): victory overlay appears immediately after boss death with essence still awarded.

---

## Phase 4: Polish

- [ ] T008 Run all 6 quickstart scenarios from `specs/032-boss-rewards/quickstart.md`

---

## Dependencies & Execution Order

- **T001, T002, T003**: No cross-dependencies — different files; run in parallel
- **T004**: Depends T003 (calls `draw_boss_offer`)
- **T005**: No dependencies on T003/T004 — different concern; can run in parallel with T003
- **T006**: Depends T001 (reads base_essence), T004 (calls trigger_boss_offer), T005 (uses _boss_relic_pending)
- **T007**: Depends T005 (reads _boss_relic_pending), T006 (_show_boss_victory_overlay must exist)
- **T008**: Depends all prior tasks

### Parallel Opportunities

```
Phase 1 (run together):
  T001  enemies.json base_essence
  T002  RelicManager._on_room_cleared() bug fix
  T003  RelicManagerImpl.draw_boss_offer()
  T005  Main.gd _boss_relic_pending field + run_started reset

  Then T004 (after T003)
  Then T006 (after T001 + T004 + T005)
  Then T007 (after T005 + T006)
```

---

## Implementation Strategy

### MVP (US1 only — essence reward)
1. Complete T001 + T002 + T003 (foundational)
2. Complete T004 + T005 + T006 (essence award + relic offer trigger)
3. Validate: kill boss → essence appears in Results Screen

### Full Feature
4. Complete T007 (victory overlay gated by relic pick)
5. Validate all 6 quickstart scenarios (T008)

### Notes
- T005 can be coded in parallel with T001–T004 since it only adds a field and a one-liner to Main.gd
- T006 is the most complex task — read contracts/interfaces.md carefully before editing Main.gd
- The fallback path (no rare relics available) must be manually tested via Scenario 5 in quickstart.md

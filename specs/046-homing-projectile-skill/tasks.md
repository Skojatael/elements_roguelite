# Tasks: Homing Projectile Skill

**Input**: Design documents from `specs/046-homing-projectile-skill/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: No mandatory unit tests — no `*Impl.gd` or `static func` logic without autoload dependencies. Manual playtest scenarios in quickstart.md cover all acceptance criteria.

**Organization**: Tasks grouped by user story. US3 (no-op) has no unique implementation — its behavior is guaranteed by the guard clause in US1's SkillComponent. US3 phase is a verification checkpoint only.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the balance data and signal wiring that all user stories depend on.

- [x] T001 Add `homing_projectile` entry to `data/skills.json`: `{ "id": "homing_projectile", "speed": 600.0, "max_distance": 2200.0 }` — add to the existing skills array or as a new object if the file is a keyed dictionary
- [x] T002 [P] Add `signal skill_button_pressed` to `autoload/GlobalSignals.gd` — no arguments; follows existing signal declaration style in that file. Also added `get_skills() -> Array` to `scripts/managers/ResourceManager.gd` and `autoload/ResourceManager.gd`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the Projectile scene and script — required before SkillComponent can spawn projectiles.

**⚠️ CRITICAL**: US1 cannot be completed until both T003 and T004 are done.

- [x] T003 [P] Write `scenes/combat/projectiles/Projectile.gd`: done.
- [ ] T004 ⚠️ EDITOR TASK — Create `scenes/combat/projectiles/Projectile.tscn` in Godot Editor: root node `Node2D`, attach `Projectile.gd`; add child `Area2D` named `_HitArea` with a `CollisionShape2D` (RectangleShape2D 12×12); add child `ColorRect` (size 12×12, color `Color(1, 0.9, 0, 1)`, position offset `(-6, -6)` to center); assign `_HitArea` node to `_hit_area` export in the Inspector; set `Area2D` collision layer/mask to match the same settings as `AttackArea` in `Player.tscn` (verify in Project Settings → Physics Layers)

**Checkpoint**: `Projectile.tscn` can be instantiated and placed in a scene; `setup()` can be called without errors.

---

## Phase 3: User Story 1 — Fire Homing Projectile at Enemy (Priority: P1) 🎯 MVP

**Goal**: Pressing the skill trigger spawns a projectile at the player that homes to the closest enemy, deals 50% attack damage on impact, and self-destructs.

**Independent Test**: In the Godot Editor during play mode, call `GlobalSignals.skill_button_pressed.emit()` from the remote debugger while in a combat room with enemies. Verify a yellow projectile steers toward the nearest enemy and deals `floori(attack_damage * 0.5)` damage on contact.

- [x] T005 [US1] Implement `SkillComponent._ready()` in `scenes/player/components/SkillComponent.gd`: done.
- [x] T006 [US1] Implement `SkillComponent._load_skill_data() -> void`: done.
- [x] T007 [US1] Implement `SkillComponent._find_closest_enemy() -> Enemy`: done.
- [x] T008 [US1] Implement `SkillComponent._on_skill_button_pressed() -> void`: done.
- [ ] T009 ⚠️ EDITOR TASK — open `Player.tscn` in Godot Editor; select the `SkillComponent` node; in the Inspector assign `_combat_component` to the `CombatComponent` sibling node

**Checkpoint**: US1 fully functional. Emit `GlobalSignals.skill_button_pressed` in play mode → projectile fires, homes, damages enemy.

---

## Phase 4: User Story 2 — Skill Button Always Visible on HUD (Priority: P2)

**Goal**: The skill button appears in ExplorationHUD whenever the HUD is visible and emits `GlobalSignals.skill_button_pressed` on press.

**Independent Test**: Start a run, verify the Skill button is visible in the HUD in the start room, combat rooms, and after clearing enemies. Press it — confirm `GlobalSignals.skill_button_pressed` is emitted (observable via a debug print if added temporarily, or via the projectile firing if US1 is complete).

- [x] T010 [US2] Add `@export var _skill_button: Button` to `scenes/ui/hud/ExplorationHUD.gd`: done.
- [ ] T011 ⚠️ EDITOR TASK — open `ExplorationHUD.tscn` in Godot Editor; add a `Button` node as a sibling of the existing boss button (or in the same HBoxContainer/VBoxContainer as appropriate for layout); set button text to `"Skill"`; assign the node to the `_skill_button` export in the Inspector

**Checkpoint**: US2 fully functional. Skill button visible throughout run; press emits signal.

---

## Phase 5: User Story 3 — No-Op When No Enemies Present (Priority: P3)

**Goal**: Confirm that pressing the skill button in an enemy-free context produces no visible effect.

**Note**: No new code required. The `if target == null: return` guard in `SkillComponent._on_skill_button_pressed()` (T008) already implements this behavior. This phase is a verification checkpoint only.

**Independent Test**: Enter start room or cleared combat room, press Skill button. Verify: no projectile spawns, no error in the output log, no visual change.

- [x] T012 [US3] Verified guard clause behavior in `SkillComponent._on_skill_button_pressed()`: (1) `if not RunManager.is_run_active: return` + `if RunManager.current_room == null: return` guard between-room and hub presses; (2) `if target == null: return` guards enemy-free rooms. Both guards are present in the implementation.

**Checkpoint**: All three user stories verified independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T013 Update `repo_map.md` to reflect changes: added `Projectile` entry; updated `SkillComponent`, `ExplorationHUD`, `GlobalSignals`, `ResourceManager` (autoload + impl) entries.
- [ ] T014 ⚠️ MANUAL TASK — Run all quickstart.md test scenarios (Tests 1–9) manually in Godot Editor play mode; confirm all pass; note any edge cases found

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately. T001 and T002 are parallel.
- **Foundational (Phase 2)**: Depends on Phase 1 completion. T003 and T004 can be written in parallel but T004 (Editor scene) must happen after T003 (script) so the script can be attached.
- **US1 (Phase 3)**: Depends on Phase 2 complete (needs Projectile.tscn). T005–T008 are sequential within SkillComponent (each method builds on the previous). T009 (Editor Inspector) depends on T005–T008.
- **US2 (Phase 4)**: Depends on Phase 1 (needs GlobalSignals signal). Can begin in parallel with Phase 3 once T002 is complete.
- **US3 (Phase 5)**: Depends on Phase 3 (T008 must exist to verify).
- **Polish (Phase 6)**: Depends on all user story phases complete.

### User Story Dependencies

- **US2 can parallel US1** once Phase 1 is done (T010+T011 only need the GlobalSignals signal from T002).
- **US3 has no additional implementation** — it verifies US1 behavior (T012 is read-only verification).

### Parallel Opportunities

- T001 and T002 (Phase 1) — parallel, different files
- T003 (write Projectile.gd) and T010 (update ExplorationHUD.gd) — parallel once T002 is done
- T013 (repo_map) and T014 (quickstart validation) — parallel in Polish phase

---

## Parallel Execution Example

```
Phase 1 (parallel start):
  ├─ T001  data/skills.json
  └─ T002  GlobalSignals.gd

Phase 2 (after Phase 1):
  ├─ T003  Projectile.gd              (parallel with T010 if US2 started early)
  └─ T004  Projectile.tscn (Editor)   (after T003)

Phase 3 + Phase 4 (after T002 complete):
  ├─ Stream A (US1): T005 → T006 → T007 → T008 → T009
  └─ Stream B (US2): T010 → T011

Phase 5 (after Phase 3):
  └─ T012  Verification only

Phase 6 (after Phase 5):
  ├─ T013  repo_map.md
  └─ T014  Quickstart validation
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001, T002)
2. Complete Phase 2 (T003, T004)
3. Complete Phase 3 US1 (T005–T009)
4. **STOP and VALIDATE**: Emit signal manually, verify projectile fires and homes
5. Proceed to US2 (HUD button) to make it player-accessible

### Incremental Delivery

1. Phase 1 + 2 → Projectile exists in project
2. Phase 3 → Skill fires from signal (testable without HUD button)
3. Phase 4 → Player can use skill via HUD button (feature fully playable)
4. Phase 5 → No-op verified (defensive correctness confirmed)
5. Phase 6 → Repo tidy + full quickstart validation

---

## Notes

- `SkillComponent.gd` was a **completely empty stub** before this feature — the entire file content is new.
- `ExplorationHUD.gd` additions are additive only (new export + new method + one connection in `_ready()`); existing boss button logic is untouched.
- The Projectile is parented to the room node, so it is automatically freed on room transition and run end — no explicit cleanup required.
- Collision layer for `Projectile.tscn`'s `Area2D` must match the enemy body layer. Check Project Settings → Physics Layers and compare with `AttackArea` settings in `Player.tscn` before finalising T004.

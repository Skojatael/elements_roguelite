# Tasks: Domain System

**Input**: Design documents from `/specs/086-domain-system/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks are grouped by user story. US2 (data structure) is implemented before US1 (domain run) because the restructured data is a prerequisite for domain filtering at runtime.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup

No new tooling or project structure required — all changes are in existing directories.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Restructure data files that all subsequent tasks depend on.

**⚠️ CRITICAL**: ResourceManagerImpl and DungeonGenerator tasks cannot begin until data files are updated.

- [x] T001 Restructure `data/enemies.json` — remove `"enemies"` wrapper key, rename `"common"` → `"normal"`, convert each category from array to `{ domain: { enemy_id: {...} } }` dict, remove per-entry `"domain"` field from all entries
- [x] T002 Update `data/dungeon_config.json` — replace `"combat_room_pool": [...]` with `"combat_room_pools": { "forest": [...], "desert": [], "frost": [] }`

**Checkpoint**: Data files reflect new schema. All downstream code changes can now proceed.

---

## Phase 3: User Story 2 — Enemy Data Organised by Domain (Priority: P2)

**Goal**: ResourceManagerImpl loads enemies from the new three-level (tier → domain → id) structure and exposes per-domain combat room pool lookup.

**Independent Test**: Instantiate `ResourceManagerImpl` with an inline stub dict matching the new structure; assert all enemy IDs are registered in flat caches, `get_enemy_base_essence` returns correct value, `get_enemy_rooms_required` returns boss threshold, and `get_combat_room_pool("forest")` returns the forest pool.

- [x] T003 [US2] Update `_load_enemy_data()` in `scripts/managers/ResourceManager.gd` to iterate tier keys (`normal`, `elite`, `boss`), then domain keys, then enemy-id keys; populate the existing flat `_enemy_ids_cache`, `_enemy_essence_cache`, `_enemy_rooms_required_cache` maps unchanged
- [x] T004 [US2] Add `get_combat_room_pool(domain: String) -> Array` to `scripts/managers/ResourceManager.gd` — reads `dungeon_config.combat_room_pools[domain]` with empty-array fallback and a `push_warning` if domain is unknown
- [x] T005 [P] [US2] Add delegating `get_combat_room_pool(domain: String) -> Array` to `autoload/ResourceManager.gd` that calls `_impl.get_combat_room_pool(domain)`
- [x] T006 [US2] Write `tests/unit/test_resource_manager_enemy_domain.gd` — inline stub dict with new three-level structure; cover: all IDs from all tiers/domains registered, `enemy_id_exists` returns true for a forest ID, `get_enemy_base_essence` returns correct value, `get_enemy_rooms_required` returns boss threshold, `get_combat_room_pool("forest")` returns the forest array

**Checkpoint**: `ResourceManagerImpl` correctly loads new enemy structure and exposes domain-pool lookup. Tests pass.

---

## Phase 4: User Story 1 — Start a Forest Domain Run (Priority: P1) 🎯 MVP

**Goal**: Hub shows three domain buttons (Forest active, Desert/Frost disabled). Pressing Forest starts a run with domain `"forest"` stored on RunManager. DungeonGenerator selects rooms from the forest pool.

**Independent Test**: Press the Forest teleport button → dungeon generates with only forest rooms and forest enemies. Desert/Frost buttons are visible but non-interactive.

- [x] T007 [US1] Add `run_domain: String = ""` field and update `start_run(mode: String, domain: String = "forest")` signature in `scripts/managers/RunManager.gd`; set `run_domain = domain` in `start_run()`, reset in `end_run()`
- [x] T008 [P] [US1] Update `scenes/hub/TeleportDoor.gd` — add `@export var domain: String = "forest"`, change signal to `teleport_activated(domain: String)`, update `_on_button_pressed()` to emit `teleport_activated.emit(domain)`
- [x] T009 [US1] Update `scenes/hub/HubRoom.gd` — change `signal hub_exited` to `hub_exited(domain: String)`, update `_on_teleport_activated(domain: String)` to emit `hub_exited.emit(domain)`
- [x] T010 [US1] Update `scenes/core/main.gd` — change `_on_hub_exited()` to `_on_hub_exited(domain: String)`, pass domain to `RunManager.start_run("endless", domain)`; update lambda connection if needed
- [x] T011 [US1] Update `scripts/dungeon/DungeonGenerator.gd` — add `domain: String = "forest"` parameter to `_generate_with()`; in `_generate()`, read `RunManager.run_domain` and pass to `_generate_with()`; replace `config.get("combat_room_pool", [])` with `ResourceManager.get_combat_room_pool(domain)`
- [x] T012 [US1] Update `tests/unit/test_dungeon_generation.gd` — change all `_generate_with(STUB_CONFIG, false, false)` and `_generate_with(STUB_CONFIG, false, true)` calls to the new 4-arg signature with `"forest"` as the fourth arg; replace `"combat_room_pool"` key in `STUB_CONFIG` with `"combat_room_pools": {"forest": [...]}` dict
- [ ] T013 [US1] **Editor task** — open `scenes/hub/HubRoom.tscn` in Godot Editor; add `DesertTeleportDoor` and `FrostTeleportDoor` as TeleportDoor instances; set `domain = "desert"` and `domain = "frost"` in Inspector; disable each door's inner Button (`disabled = true`); wire both `teleport_activated` signals to `_on_teleport_activated` in HubRoom

**Checkpoint**: Forest teleport starts a domain run, dungeon uses forest room pool, desert/frost buttons are disabled.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T014 Update `CLAUDE.md` — add Domain System subsection under Run session: `RunManager.run_domain: String` stores active domain set via `start_run(mode, domain)`; DungeonGenerator reads it to select `combat_room_pools[domain]`; HubRoom emits `hub_exited(domain)` when teleport pressed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
- **US2 (Phase 3)**: Depends on T001 and T002 (data files must be restructured first)
- **US1 (Phase 4)**: Depends on Phase 3 completion (ResourceManager must expose `get_combat_room_pool` before DungeonGenerator can call it)
- **Polish (Phase 5)**: Depends on all implementation phases complete

### User Story Dependencies

- **US2 (P2)**: Must precede US1 — data structure is a prerequisite for runtime domain filtering
- **US1 (P1)**: Depends on US2 — requires `ResourceManager.get_combat_room_pool()` and `RunManager.run_domain`

### Within Each Phase

- T003 before T004 (impl method before wrapper method)
- T004 before T005 (impl before autoload delegation)
- T003–T005 before T006 (implementation before tests)
- T007 before T010 (RunManager domain before Main wires it)
- T008 before T009 (TeleportDoor signal before HubRoom uses it)
- T009 before T010 (HubRoom signal before Main connects it)
- T011 before T012 (DungeonGenerator sig change before test update)
- T008–T012 can all start after T005 completes; T008 and T007 are parallel to each other

### Parallel Opportunities

- T001 and T002 can run in parallel (different data files)
- T003, T004, T005 are sequential within US2
- T007 and T008 are parallel (different files, no dependency)
- T009 and T011 are parallel (different files) after T008 and T005 respectively complete

---

## Parallel Example: User Story 1

```
# After Phase 3 completes, these can start in parallel:
T007: RunManager run_domain field       ← scripts/managers/RunManager.gd
T008: TeleportDoor domain export/signal ← scenes/hub/TeleportDoor.gd

# After T008:
T009: HubRoom signal update             ← scenes/hub/HubRoom.gd

# After T009 and T007:
T010: Main.gd _on_hub_exited update     ← scenes/core/main.gd

# After T005 (get_combat_room_pool available):
T011: DungeonGenerator domain threading ← scripts/dungeon/DungeonGenerator.gd
```

---

## Implementation Strategy

### MVP First (Forest Domain Run Working)

1. Complete Phase 2: Restructure data files
2. Complete Phase 3: ResourceManager loads new structure + pool lookup
3. Complete Phase 4: RunManager + TeleportDoor + HubRoom + Main + DungeonGenerator
4. **STOP and VALIDATE**: Start a forest run — rooms are forest-only, enemies are forest-only
5. Complete T013 (Editor task) to show disabled Desert/Frost buttons in hub

### Incremental Delivery

1. Data restructure (T001–T002) → foundation for everything
2. ResourceManager update (T003–T006) → domain pool lookup works, tests pass
3. Signal chain (T007–T010) → domain flows from button press to RunManager
4. DungeonGenerator (T011–T012) → room pool uses active domain
5. Editor task (T013) → three buttons visible in hub
6. CLAUDE.md (T014) → documentation complete

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- T013 is an Editor task — it cannot be automated and must be done manually in Godot Editor
- Enemy ID keys in the new structure retain their existing string IDs (e.g. `"forest_tank"`, `"forest_boss_thorns"`) — no ID changes
- Existing flat caches in ResourceManagerImpl (`_enemy_ids_cache`, `_enemy_essence_cache`, `_enemy_rooms_required_cache`) are unchanged in structure — only the loading traversal changes
- `start_run(mode)` callers that don't pass domain (DevPanel, boss run path) default to `"forest"` via the optional parameter — no changes needed to those callers

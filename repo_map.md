# Repo Map

> Reference this file for project structure and symbol locations. Last updated: 2026-03-13.

---

## Autoloads (`autoload/`)

### `autoload/GlobalSignals.gd`
- **signals**: `gameplay_started`, `gameplay_ended`, `hub_entered`

### `autoload/MetaManager.gd`
- **signals**: `shards_changed(new_total: int)`
- **properties**: `meta_state: MetaState`, `is_relic_offers_active: bool`, `is_first_boss_killed: bool`, `is_adventuring_gear_owned: bool`, `is_boss_run_unlocked: bool`, `is_magic_forge_unlocked: bool`, `is_mage_tower_unlocked: bool`, `is_alchemy_lab_unlocked: bool`, `endless_boss_kill_count: int`, `damage_multiplier: float`, `essence_gain_multiplier: float`
- **methods**: `can_spend(cost) -> bool`, `spend(cost) -> bool`, `add_shards(amount)`, `get_next_upgrade_cost() -> int`, `purchase_damage_upgrade() -> bool`, `purchase_adventuring_gear() -> bool`, `purchase_boss_run() -> bool`, `purchase_magic_forge() -> bool`, `purchase_mage_tower() -> bool`, `purchase_mage_tower_relic_system() -> bool`, `purchase_alchemy_lab() -> bool`

### `autoload/RelicManager.gd`
- **signals**: `relic_offer_ready(options: Array)`, `relic_applied(relic_id: String)`, `relics_cleared`
- **properties**: `active_relic_ids: Array[String]`
- **methods**: `pick_relic(id: String)`, `get_stat_mult(stat: String) -> float`, `get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio) -> float`, `trigger_boss_offer() -> bool`, `trigger_offer(room_type_id: String)`

### `autoload/ResourceManager.gd`
- Thin wrapper over `ResourceManagerImpl`
- **methods**: `get_dungeon_config() -> Dictionary`, `get_meta_config() -> Dictionary`, `get_relics() -> Dictionary`, `get_enemy_base_essence(id: String) -> float`, `get_enemy_rooms_required(id: String) -> int`, `enemy_id_exists(id: String) -> bool`

### `autoload/RunManager.gd`
- Extends `scripts/managers/RunManager.gd` (thin wrapper, no added logic)

### `autoload/SaveManager.gd`
- Thin wrapper over `SaveManagerImpl`
- **methods**: `save_meta_state(state: MetaState)`, `load_meta_state() -> MetaState`

---

## Scripts — Managers (`scripts/managers/`)

### `scripts/managers/MetaManager.gd` (`class_name MetaManagerImpl`)
- **methods**: `load(save_manager)`, `add_shards(amount, save_manager)`, `can_spend(cost) -> bool`, `spend(cost, save_manager) -> bool`, `get_upgrade_cost(level, base_cost, scale) -> int`, `purchase_damage_upgrade(cost, save_manager) -> bool`, `get_damage_multiplier(damage_per_level) -> float`, `get_essence_gain_multiplier(essence_per_level) -> float`, `record_boss_kill(save_manager) -> bool`, `increment_endless_boss_kills(save_manager) -> void`, `purchase_boss_run(cost, save_manager) -> bool`, `purchase_adventuring_gear(cost, save_manager) -> bool`, `purchase_magic_forge(cost, save_manager) -> bool`, `purchase_mage_tower(cost, save_manager) -> bool`, `purchase_mage_tower_relic_system(cost, save_manager) -> bool`, `purchase_alchemy_lab(cost, save_manager) -> bool`

### `scripts/managers/RelicManagerImpl.gd` (`class_name RelicManagerImpl`)
- **const**: `OFFER_INTERVAL = 2`
- **state**: `active_relic_ids: Array[String]`, `standard_rooms_cleared: int`
- **methods**: `reset()`, `build_pool(relics_dict) -> Array[RelicData]`, `draw_offer(pool) -> Array[RelicData]`, `draw_boss_offer() -> Array[RelicData]`, `pick_relic(id, pool)`, `should_offer_for_room(room_type_id) -> bool`, `compute_stat_mult(stat, pool) -> float`, `get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio) -> float`

### `scripts/managers/ResourceManager.gd` (`class_name ResourceManagerImpl`)
- **methods**: `get_dungeon_config() -> Dictionary`, `get_meta_config() -> Dictionary`, `get_relics() -> Dictionary`, `get_enemy_base_essence(id) -> float`, `get_enemy_rooms_required(id) -> int`, `enemy_id_exists(id) -> bool`

### `scripts/managers/RunManager.gd` (`class_name RunManager`)
- **enum**: `EndReason { DIED, CASH_OUT }`
- **signals**: `run_started(mode: String)`, `run_ended(reason: EndReason)`, `room_cleared(room_id: String)`
- **state**: `run_id: String`, `is_run_active: bool`, `run_mode: String`, `current_tier: int`, `run_start_time: float`, `run_currency: float`, `current_room: Node`, `cleared_rooms: Dictionary`, `enemies_slain: int`, `run_state: RunState`, `run_summary: RunSummary`, `player_state: PlayerState`
- **services** (stubs): `difficulty_service: DifficultyService`, `rewards_service: RewardsService`
- **methods**: `start_run(mode: String)`, `end_run(reason: EndReason)`, `spawn_room(room_data, room_id, context) -> RoomSpawner`, `register_room(spawner: RoomSpawner)`, `add_currency(amount: float)`, `mark_room_cleared(room_id: String)`, `is_room_cleared(room_id: String) -> bool`

### `scripts/managers/SaveManager.gd` (`class_name SaveManagerImpl`)
- **const**: `SAVE_PATH = "user://meta_save.json"`
- **methods**: `save_meta_state(state: MetaState)`, `load_meta_state() -> MetaState`

---

## Scripts — Data Models (`scripts/data_models/`)

### `scripts/data_models/EnemyData.gd` (`class_name EnemyData extends Resource`)
- **fields**: `id`, `display_name`, `max_health`, `damage`, `move_speed`, `detection_range`, `damage_cooldown`, `base_essence`, `rooms_required: int`
- **factory**: `static func from_dict(data) -> EnemyData`

### `scripts/data_models/MetaState.gd` (`class_name MetaState extends RefCounted`)
- **fields**: `total_shards: int`, `damage_upgrade_level: int`, `relic_offers_active: bool`, `first_boss_killed: bool`, `adventuring_gear_owned: bool`, `endless_boss_kill_count: int`, `boss_run_unlocked: bool`, `magic_forge_unlocked: bool`, `mage_tower_unlocked: bool`, `alchemy_lab_unlocked: bool`, `essence_gain_level: int`

### `scripts/data_models/PlayerState.gd` (`class_name PlayerState extends RefCounted`)
- **fields**: `current_hp: float`, `items: Array`, `active_modifiers: Array[String]`, `skill_changes: Array`, `skill_cooldowns: Dictionary`

### `scripts/data_models/RelicData.gd` (`class_name RelicData extends RefCounted`)
- **fields**: `id`, `name`, `tier`, `tags: Array[String]`, `effect_stat`, `effect_mult: float`, `description`
- **factory**: `static func from_dict(data) -> RelicData`

### `scripts/data_models/RoomData.gd` (`class_name RoomData extends Resource`)
- **exports**: `room_type_id: String`, `scene: PackedScene`

### `scripts/data_models/RoomSpawnConfig.gd` (`class_name RoomSpawnConfig extends Resource`)
- **fields**: `room_id: String`, `spawn_points: Array[SpawnPointData]`, `enemy_count_mult: float`, `essence_mult: float`
- **factory**: `static func from_dict(room_id, data) -> RoomSpawnConfig`

### `scripts/data_models/RunState.gd` (`class_name RunState extends RefCounted`)
- **fields**: `current_room_id: String`, `cleared_rooms: Dictionary`, `run_currency: float`, `run_mode: String`, `max_depth_reached: int`, `seed: int`, `player_state: PlayerState`

### `scripts/data_models/RunSummary.gd` (`class_name RunSummary extends RefCounted`)
- **fields**: `essence_cashed_out: int`, `enemies_slain: int`, `rooms_cleared: int`, `end_reason: RunManager.EndReason`
- **factory**: `static func create(essence, enemies, rooms, reason) -> RunSummary`

### `scripts/data_models/SpawnContext.gd` (`class_name SpawnContext extends RefCounted`)
- **fields**: `parent: Node`, `position: Vector2`
- **factory**: `static func create(parent, position) -> SpawnContext`

### `scripts/data_models/SpawnPointData.gd` (`class_name SpawnPointData extends Resource`)
- **fields**: `enemy_id: String`, `position: Vector2`, `radius: float`
- **factory**: `static func from_dict(data) -> SpawnPointData`

### `scripts/data_models/SkillData.gd` — stub (no class_name, no logic)

### `scripts/data_models/UpgradeData.gd` — stub (no class_name, no logic)

---

## Scripts — Dungeon (`scripts/dungeon/`)

### `scripts/dungeon/DungeonGenerator.gd` (`class_name DungeonGenerator extends Node`)
- **const**: `GRID_SIZE = 13`, `CENTER = Vector2i(6,6)`, `SPACING_X = 2000`, `SPACING_Y = 1200`, `ELITE_START = 2`, `ELITE_STEP = 2`
- **signals**: `dungeon_layout_ready`
- **properties**: `rooms_by_id: Dictionary`, `neighbours_by_id: Dictionary`, `start_room_id: String`
- **methods**: `_generate()`, `_generate_with(config: Dictionary, gear_owned: bool)`, `_record_room(cell, type_id, occupied, frontier, difficulty_scale)`, `_build_neighbours(occupied)`, `_promote_elite_rooms()`, `_expand_dungeon(occupied, pool, difficulty_scale)`, `_get_expansion_neighbours(cell, occupied, min_depth) -> Array[Vector2i]`, `_get_valid_neighbours(cell, occupied) -> Array[Vector2i]`, `_get_world_pos(cell) -> Vector2`

### `scripts/dungeon/RoomFactory.gd` (`class_name RoomFactory extends RefCounted`)
- **methods**: `spawn_room(room_data: RoomData, room_id: String, context: SpawnContext) -> RoomSpawner`

### `scripts/dungeon/RoomLoader.gd` (`class_name RoomLoader extends Node`)
- **const**: `ENTRY_OFFSET = 150.0`
- **methods**: `free_current_room()`, `_load_room(room_id)`, `_configure_doors(room_node, room_id)`

### `scripts/dungeon/RoomManager.gd` — stub (no class_name, no logic)

### `scripts/dungeon/RoomSpawner.gd` (`class_name RoomSpawner extends Node`)
- **exports**: `room_id: String`, `room_type_id: String`, `auto_register: bool`, `difficulty_mult: float`, `depth: int`
- **signals**: `room_cleared(room_id: String)`, `room_entered(room_id: String)`, `enemy_defeated(enemy_id: String, position: Vector2)`
- **property**: `essence_mult: float`

---

## Scripts — Services (`scripts/services/`)

### `scripts/services/DifficultyService.gd` (`class_name DifficultyService extends RefCounted`)
- **methods**: `get_multiplier() -> float` — stub, returns 1.0

### `scripts/services/RewardsService.gd` (`class_name RewardsService extends RefCounted`)
- **methods**: `get_room_reward(room_id) -> Dictionary` — stub, returns {}

---

## Scripts — Other (`scripts/`)

### `scripts/meta/PassiveIncomeSystem.gd` — stub
### `scripts/Utilities.gd` — stub
### `scripts/NumberFormatter.gd` — stub

---

## Scenes — Core (`scenes/core/`)

### `scenes/core/Main.gd`
- **const**: `BOSS_ROOM_WORLD_POS = Vector2(0, -3000)`
- **key node refs**: `_dungeon_gen: DungeonGenerator`, `_room_loader: RoomLoader`, `_player: Node`, `_exploration_hud: ExplorationHUD`, `_hub_room`, `_results_layer`, `_boss_room_spawner: RoomSpawner`, `_boss_victory_layer`, `_boss_relic_pending: bool`, `_boss_kill_popup_layer: CanvasLayer`, `_first_boss_popup_pending: bool`
- **methods**: `_on_run_started()`, `_on_run_ended(reason)`, `_on_boss_teleport_pressed()`, `_on_boss_room_cleared(room_id)`, `_show_boss_victory_overlay()`, `_show_boss_kill_popup()`, `_on_relic_offer_ready(options)`, `_on_relic_picked(relic_id)`, `_on_results_return()`

---

## Scenes — Player (`scenes/player/`)

### `scenes/player/components/CombatComponent.gd`
- **exports**: `attack_damage: float`, `attack_interval: float`, `_stats_component: StatsComponent`

### `scenes/player/components/DodgeComponent.gd` — stub

### `scenes/player/components/MovementComponent.gd`
- **exports**: `move_speed: float`
- **methods**: `set_joystick(joystick: JoystickControl)`

### `scenes/player/components/SkillComponent.gd` — stub

### `scenes/player/components/StatsComponent.gd`
- **exports**: `max_health: float`
- **signals**: `health_changed(new_health: float, max_health: float)`, `died`
- **methods**: `take_damage(amount: float)`, `heal(amount: float)`, `reset()`

---

## Scenes — Combat (`scenes/combat/`)

### `scenes/combat/enemies/Enemy.gd`
- **exports**: `enemy_type_id: String`
- **signals**: `defeated`
- **methods**: `initialize(data: EnemyData)`, `apply_difficulty(mult: float)`, `get_hp_ratio() -> float`, `take_damage(amount: float)`

---

## Scenes — Dungeon (`scenes/dungeon/`)

### `scenes/dungeon/doors/Door.gd` (`class_name Door`)
- **exports**: `direction: String`, `target_room_id: String`
- **signals**: `door_activated(direction: String, target_room_id: String)`

---

## Scenes — Hub (`scenes/hub/`)

### `scenes/hub/MageTower.gd` (`class_name MageTower extends Control`)
- **exports**: `_ruined_visual: ColorRect`, `_magic_visual: ColorRect`, `_label: Label`, `_button: Button`, `_restore_overlay_scene: PackedScene`, `_upgrade_screen_scene: PackedScene`
- **methods**: `_update_visuals()`, `_on_tower_pressed()`, `_show_restore_overlay()`, `_show_upgrade_screen()`, `_close_overlay()`, `_on_restore_pressed()`

### `scenes/hub/RestoreTowerOverlay.gd` (`class_name RestoreTowerOverlay extends Control`)
- **signals**: `restore_pressed`, `maybe_later_pressed`
- **exports**: `_restore_button: Button`, `_later_button: Button`

### `scenes/hub/MageTowerUpgradeScreen.gd` (`class_name MageTowerUpgradeScreen extends Control`)
- **signals**: `close_pressed`
- **exports**: `_de_button: Button`, `_rs_button: Button`, `_bc_button: Button`, `_close_button: Button`
- **state**: `_entries: Array[Dictionary]` — built in `_ready()` by merging JSON upgrade config with runtime refs (`button`, `owned_prop`, `purchase` Callable, optional `gate_prop`/`gate_text`)
- **methods**: `_update_entries()`, `_apply_entry(cfg: Dictionary)`

### `scenes/hub/AlchemyLab.gd` (`class_name AlchemyLab extends Control`)
- **exports**: `_ruined_visual: ColorRect`, `_magic_visual: ColorRect`, `_label: Label`, `_button: Button`, `_restore_overlay_scene: PackedScene`, `_upgrade_screen_scene: PackedScene`
- **methods**: `_update_visuals()`, `_on_lab_pressed()`, `_show_restore_overlay()`, `_show_upgrade_screen()`, `_close_overlay()`, `_on_restore_pressed()`

### `scenes/hub/RestoreLabOverlay.gd` (`class_name RestoreLabOverlay extends Control`)
- **signals**: `restore_pressed`, `maybe_later_pressed`
- **exports**: `_restore_button: Button`, `_later_button: Button`

### `scenes/hub/LabUpgradeScreen.gd` (`class_name LabUpgradeScreen extends Control`)
- **signals**: `close_pressed`
- **exports**: `_essence_button: Button`, `_close_button: Button`
- **methods**: `_update_buttons()`

### `scenes/hub/BossRunButton.gd` (`class_name BossRunButton extends Control`)
- **signals**: `boss_run_pressed`
- **exports**: `_button: Button`
- **methods**: `_update_visibility()`, `_on_pressed()`

### `scenes/hub/HubRoom.gd`
- **signals**: `hub_exited`, `hub_boss_run_pressed`
- **exports**: `teleport_door: TeleportDoor`, `_boss_run_button: BossRunButton`

### `scenes/hub/ShardDisplay.gd`
- **exports**: `_label: Label`

### `scenes/hub/TeleportDoor.gd` (`class_name TeleportDoor extends Node2D`)
- **signals**: `teleport_activated`
- **exports**: `button: Button`

### `scenes/hub/UpgradeShop.gd` (no class_name)
- **exports**: `_button: Button`
- Damage upgrade shop — reads cost from `MetaManager`, calls `purchase_damage_upgrade()`

---

## Scenes — UI (`scenes/ui/`)

### `scenes/ui/boss_kill_popup/BossKillPopup.gd` (`class_name BossKillPopup extends Control`)
- **signals**: `ok_pressed`
- **exports**: `_message_label: Label`, `_ok_button: Button`
- **methods**: `setup(message: String)`

### `scenes/ui/boss_victory/BossVictoryOverlay.gd` (`class_name BossVictoryOverlay extends Control`)
- **signals**: `cash_out_pressed`, `continue_pressed`
- **exports**: `_cash_out_button: Button`, `_continue_button: Button`
- **methods**: `setup(show_continue: bool)`

### `scenes/ui/dev/DevPanel.gd`
- **signals**: `start_run_pressed`, `end_run_pressed`, `cash_out_pressed`, `start_boss_pressed`, `get_relic_pressed`

### `scenes/ui/hud/ExplorationHUD.gd` (`class_name ExplorationHUD extends CanvasLayer`)
- **signals**: `boss_teleport_pressed`
- **exports**: `_boss_button: Button`
- **static methods**: `is_boss_available(cleared_count: int, required: int) -> bool`

### `scenes/ui/hud/Joystick.gd` (`class_name JoystickControl extends Control`)
- **exports**: `max_radius: float`, `dead_zone_percentage: float`
- **property**: `input_vector: Vector2`

### `scenes/ui/relic_offer/RelicCard.gd`
- **signals**: `relic_selected(relic_id: String)`
- **exports**: `_name_label: Label`, `_desc_label: Label`, `_button: Button`
- **methods**: `setup(relic: RelicData)`

### `scenes/ui/relic_offer/RelicOfferScreen.gd`
- **signals**: `relic_picked(relic_id: String)`
- **exports**: `_card_left: RelicCard`, `_card_middle: RelicCard`, `_card_right: RelicCard`
- **methods**: `setup(options: Array)`

### `scenes/ui/run_end/ResultsScreen.gd` (`class_name ResultsScreen extends Control`)
- **signals**: `return_pressed`
- **exports**: `_essence_row: StatRow`, `_enemies_row: StatRow`, `_rooms_row: StatRow`, `_return_button: Button`
- **methods**: `setup(summary: RunSummary)`

### `scenes/ui/run_end/StatRow.gd` (`class_name StatRow extends HBoxContainer`)
- **exports**: `_name_label: Label`, `_value_label: Label`
- **methods**: `set_value(n: int)`

---

## Data Files (`data/`)

| File | Key contents |
|------|-------------|
| `data/dungeon_config.json` | `combat_room_pool`, `spawn_configs` (per room type), `difficulty_scale`, `base_room_count: 9`, `expansion_room_count: 4` |
| `data/enemies.json` | `enemies` dict with categories `"common"` and `"boss"`, each an Array of enemy entries |
| `data/meta_config.json` | `shard_divisor: 3`, `boss_run_shard_award: 35`, `relic_tier_weights`, `magic_forge` (name, cost, upgrades → `damage_upgrade` {name, base_cost, cost_scale, max_levels, damage_per_level}), `mage_tower` (name, cost, upgrades → `dungeon_expansion` {name, cost}, `relic_system` {name, cost}, `boss_challenge` {name, cost}), `alchemy_lab` (name, cost: 500, upgrades → `essence_gain` {name, base_cost: 0, max_levels: 1, essence_per_level: 0.05}) |
| `data/relics.json` | `relics` array — 6 relics across 4 stat categories |
| `data/skills.json` | (stub/TBD) |
| `data/upgrades.json` | (stub/TBD) |
| `data/rooms/*.tres` | RoomData resources: `CombatRoom01`, `CombatRoom02`, `EliteRoom01`, `BossRoom01`, `StartRoom01` |

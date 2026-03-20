# Repo Map

> Reference this file for project structure and symbol locations. Last updated: 2026-03-16.

---

## Autoloads (`autoload/`)

### `autoload/GlobalSignals.gd`
- **signals**: `gameplay_started`, `gameplay_ended`, `hub_entered`, `skill_button_pressed`

### `autoload/MetaManager.gd`
- **signals**: `shards_changed(new_total: int)`, `gold_changed(new_floor: int)`
- **properties**: `meta_state: MetaState`, `total_gold: float`, `is_relic_offers_active: bool`, `is_first_boss_killed: bool`, `is_adventuring_gear_owned: bool`, `is_boss_run_unlocked: bool`, `is_magic_forge_unlocked: bool`, `is_mage_tower_unlocked: bool`, `is_alchemy_lab_unlocked: bool`, `is_gold_generator_owned: bool`, `is_missile_extra_charge_owned: bool`, `is_rarity_luck_owned: bool`, `is_book_of_skill_gate_reached: bool`, `is_book_of_skill_owned: bool`, `endless_boss_kill_count: int`, `damage_multiplier: float`, `essence_gain_multiplier: float`, `gold_storage_cap_hours: int`, `shard_generator_rate: float`
- **methods**: `can_spend(cost) -> bool`, `spend(cost) -> bool`, `add_shards(amount)`, `get_next_upgrade_cost() -> int`, `purchase_damage_upgrade() -> bool`, `purchase_missile_extra_charge() -> bool`, `purchase_rarity_luck() -> bool`, `purchase_adventuring_gear() -> bool`, `purchase_boss_run() -> bool`, `purchase_magic_forge() -> bool`, `purchase_mage_tower() -> bool`, `purchase_mage_tower_relic_system() -> bool`, `purchase_alchemy_lab() -> bool`, `purchase_gold_generator() -> bool`, `purchase_gold_storage_cap() -> bool`, `can_spend_gold(cost: float) -> bool`, `spend_gold(cost: float) -> bool`, `get_next_essence_gain_cost() -> int`, `purchase_essence_gain() -> bool`, `get_next_shard_generator_cost() -> int`, `purchase_shard_generator() -> bool`, `record_book_of_skill_gate() -> bool`, `purchase_book_of_skill() -> bool`

### `autoload/RelicManager.gd`
- **signals**: `relic_offer_ready(options: Array)`, `relic_applied(relic_id: String)`, `relics_cleared`
- **properties**: `active_relic_ids: Array[String]`
- **methods**: `pick_relic(id: String)`, `get_stat_mult(stat: String) -> float`, `get_stat_addend(stat: String) -> float`, `get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio, target_is_burning: bool) -> float`, `has_chain_relic() -> bool`, `has_burn_relic() -> bool`, `get_chain_damage_bonus() -> float`, `on_melee_hit() -> bool`, `trigger_boss_offer() -> bool`, `trigger_offer(room_type_id: String)`, `has_root_relic() -> bool`, `get_root_on_hit_duration() -> float`, `try_apply_poison(target: Enemy) -> void`

### `autoload/ResourceManager.gd`
- Thin wrapper over `ResourceManagerImpl`
- **methods**: `get_dungeon_config() -> Dictionary`, `get_meta_config() -> Dictionary`, `get_relics() -> Dictionary`, `get_skills() -> Array`, `get_enemy_base_essence(id: String) -> float`, `get_enemy_rooms_required(id: String) -> int`, `enemy_id_exists(id: String) -> bool`

### `autoload/RunManager.gd`
- Extends `scripts/managers/RunManager.gd` (thin wrapper, no added logic)

### `autoload/SaveManager.gd`
- Thin wrapper over `SaveManagerImpl`
- **methods**: `save_meta_state(state: MetaState)`, `load_meta_state() -> MetaState`

---

## Scripts — Managers (`scripts/managers/`)

### `scripts/managers/MetaManager.gd` (`class_name MetaManagerImpl`)
- **methods**: `load(save_manager)`, `add_shards(amount, save_manager)`, `can_spend(cost) -> bool`, `spend(cost, save_manager) -> bool`, `get_upgrade_cost(level, base_cost, scale) -> int`, `purchase_damage_upgrade(cost, save_manager) -> bool`, `purchase_missile_extra_charge(cost, save_manager) -> bool`, `purchase_rarity_luck(cost, save_manager) -> bool`, `get_damage_multiplier(damage_per_level) -> float`, `get_essence_gain_multiplier(essence_per_level) -> float`, `can_spend_gold(cost: float) -> bool`, `spend_gold(cost: float, save_manager: Node) -> bool`, `purchase_essence_gain(base_cost: int, cost_step: int, max_levels: int, save_manager: Node) -> bool`, `record_boss_kill(save_manager) -> bool`, `increment_endless_boss_kills(save_manager) -> void`, `purchase_boss_run(cost, save_manager) -> bool`, `purchase_adventuring_gear(cost, save_manager) -> bool`, `purchase_magic_forge(cost, save_manager) -> bool`, `purchase_mage_tower(cost, save_manager) -> bool`, `purchase_mage_tower_relic_system(cost, save_manager) -> bool`, `purchase_alchemy_lab(cost, save_manager) -> bool`, `purchase_gold_generator(cost, save_manager) -> bool`, `apply_offline_gold(now_unix: int, rate_per_hour: float, cap_seconds: int, save_manager: Node) -> void`, `tick_gold(delta: float, rate_per_hour: float) -> int`, `get_gold_storage_cap_seconds(base_hours: int, hours_per_level: int) -> int`, `purchase_gold_storage_cap(cost: int, max_levels: int, save_manager: Node) -> bool`, `get_shard_rate_per_hour(rates: Array) -> float`, `tick_shard_generator(delta: float, rates: Array) -> int`, `apply_offline_shards(now_unix: int, rates: Array, cap_seconds: int, save_manager: Node) -> int`, `purchase_shard_generator(cost: int, max_levels: int, save_manager: Node) -> bool`, `record_book_of_skill_gate(save_manager: Node) -> bool`, `purchase_book_of_skill(cost: int, save_manager: Node) -> bool`

### `scripts/managers/RelicManagerImpl.gd` (`class_name RelicManagerImpl`)
- **const**: `OFFER_INTERVAL = 1`, `MELEE_CHARGE_RELIC_ID = "melee_missile_charge"`, `POISON_RELIC_ID = "venomous_strike"`
- **state**: `active_relic_ids: Array[String]`, `standard_rooms_cleared: int`, `_melee_hit_count: int` *(per-run counter for melee_missile_charge relic; reset each run)*, `_activated_mechanics: Array[String]` *(mechanic tags activated this run; reset each run)*, `_mechanic_tag_names: Array[String]` *(tags that have `_unlocked` counterparts in the pool; computed in build_pool)*
- **methods**: `reset()`, `build_pool(relics_dict, config_dict)`, `draw_offer(tier: String, promotion_chance: float = 0.0) -> Array[RelicData]` *(promotion_chance: per-draw chance 0.0–1.0 to draw from next rarity tier; default 0.0 = no promotion)*, `draw_boss_offer() -> Array[RelicData]` *(bypasses draw_offer; rarity_luck does not apply)*, `pick_relic(relic_id)` *(activates mechanic tags from the picked relic)*, `should_offer_for_room(room_type_id) -> bool`, `compute_stat_mult(stat) -> float` *(additive within relic source: 1.0 + Σ(effect_mult − 1.0))*, `compute_stat_addend(stat) -> float`, `get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio, target_is_burning: bool) -> float` *(generic loop over active relics; evaluates condition_type/threshold/mult from RelicData; supports "target_hp_below", "attacker_hp_below", "target_is_burning")*, `has_chain_relic() -> bool`, `has_burn_relic() -> bool`, `get_chain_damage_bonus() -> float` *(sums condition_mult for active relics with condition_type == "chain_damage_bonus"; returns 0.0 if none held)*, `on_melee_hit() -> bool` *(increments _melee_hit_count when relic held; resets to 0 and returns true on every Nth hit where N = condition_threshold in JSON)*, `has_root_relic() -> bool`, `get_root_on_hit_duration() -> float` *(rolls randf() against root_chance; returns root_duration on success, 0.0 on miss or relic absent)*, `has_poison_relic() -> bool`, `try_apply_poison(target: Enemy) -> void` *(rolls randf() against poison_chance; calls target.apply_poison() on success; no-op when relic absent)*

### `scripts/managers/ResourceManager.gd` (`class_name ResourceManagerImpl`)
- **methods**: `get_dungeon_config() -> Dictionary`, `get_meta_config() -> Dictionary`, `get_relics() -> Dictionary`, `get_skills() -> Array`, `get_enemy_base_essence(id) -> float`, `get_enemy_rooms_required(id) -> int`, `enemy_id_exists(id) -> bool`

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
- **fields**: `id`, `display_name`, `max_health`, `damage`, `move_speed`, `detection_range`, `damage_cooldown`, `base_essence`, `rooms_required: int`, `damage_reduction: float`, `root_duration: float`, `root_cooldown: float`, `poison_duration: float` (0.0 default; > 0 means enemy can apply poison on contact), `poison_modifier: float` (0.0 default; fraction damage reduction applied to poisoned target)
- **factory**: `static func from_dict(data) -> EnemyData`

### `scripts/data_models/MetaState.gd` (`class_name MetaState extends RefCounted`)
- **fields**: `total_shards: int`, `damage_upgrade_level: int`, `relic_offers_active: bool`, `first_boss_killed: bool`, `adventuring_gear_owned: bool`, `endless_boss_kill_count: int`, `boss_run_unlocked: bool`, `magic_forge_unlocked: bool`, `mage_tower_unlocked: bool`, `alchemy_lab_unlocked: bool`, `essence_gain_level: int`, `gold_generator_owned: bool`, `gold_storage_cap_level: int`, `total_gold: float`, `gold_last_saved_timestamp: int`, `shard_generator_level: int`, `shard_accumulator: float`, `missile_extra_charge_owned: bool`, `rarity_luck_owned: bool`, `book_of_skill_gate_reached: bool`, `book_of_skill_owned: bool`

### `scripts/data_models/PlayerState.gd` (`class_name PlayerState extends RefCounted`)
- **fields**: `current_hp: float`, `items: Array`, `active_modifiers: Array[String]`, `skill_changes: Array`, `skill_cooldowns: Dictionary`

### `scripts/data_models/RelicData.gd` (`class_name RelicData extends RefCounted`)
- **fields**: `id`, `name`, `tier`, `tags: Array[String]`, `effect_stat`, `effect_mult: float`, `condition_type: String`, `condition_threshold: float`, `condition_mult: float`, `description`, `deck_count: int`, `root_chance: float` (0.0 default; probability of rooting on melee hit), `root_duration: float` (0.0 default; seconds of root applied on successful roll), `poison_chance: float` (0.0 default; probability of poisoning enemy on melee hit), `poison_duration: float` (0.0 default; seconds of poison applied on proc), `poison_modifier: float` (0.0 default; fraction damage reduction on poisoned entity)
- **factory**: `static func from_dict(data) -> RelicData`

### `scripts/data_models/RoomData.gd` (`class_name RoomData extends Resource`)
- **exports**: `room_type_id: String`, `scene: PackedScene`

### `scripts/data_models/RoomSpawnConfig.gd` (`class_name RoomSpawnConfig extends Resource`)
- **fields**: `room_id: String`, `spawn_points: Array[SpawnPointData]`, `enemy_count_mult: float`, `essence_mult: float`, `wave_config: WaveConfig`, `wave_spawn_points: Array` (array of `Array[SpawnPointData]` indexed by wave; populated by `RoomSpawner._load_depth_band_config()` for combat rooms)
- **factory**: `static func from_dict(room_id, data) -> RoomSpawnConfig`

### `scripts/data_models/WaveConfig.gd` (`class_name WaveConfig extends Resource`)
- **fields**: `waves: Array[int]`, `trigger_threshold: int`, `alive_cap: int`, `min_spawn_distance: float`
- **factory**: `static func from_dict(data: Dictionary) -> Resource`

### `scripts/data_models/DepthTierConfig.gd` (`class_name DepthTierConfig extends Resource`)
- **fields**: `depth_min: int`, `depth_max: int`, `waves: Array`, `trigger_threshold: int`, `alive_cap: int`, `min_spawn_distance: float`
- **factories**: `static func from_dict(data: Dictionary) -> Resource`, `static func find_for_depth(tiers: Array, depth: int) -> Resource`

### `scripts/data_models/RunState.gd` (`class_name RunState extends RefCounted`)
- **fields**: `current_room_id: String`, `cleared_rooms: Dictionary`, `run_currency: float`, `run_mode: String`, `max_depth_reached: int`, `seed: int`, `player_state: PlayerState`

### `scripts/data_models/RunSummary.gd` (`class_name RunSummary extends RefCounted`)
- **fields**: `essence_cashed_out: int`, `enemies_slain: int`, `rooms_cleared: int`, `end_reason: RunManager.EndReason`
- **factory**: `static func create(essence, enemies, rooms, reason) -> RunSummary`

### `scripts/data_models/SpawnContext.gd` (`class_name SpawnContext extends RefCounted`)
- **fields**: `parent: Node`, `position: Vector2`
- **factory**: `static func create(parent, position) -> SpawnContext`

### `scripts/data_models/SpawnPointData.gd` (`class_name SpawnPointData extends Resource`)
- **fields**: `enemy_id: String`, `position: Vector2`, `radius: float`, `enemy_pool: Array` (array of `{enemy_id, weight}` dicts; single-entry for legacy fixed slots)
- **factory**: `static func from_dict(data) -> SpawnPointData` — supports `"enemy_id"` key (legacy, wraps as 100% pool) and `"pool"` key (weighted array)
- **methods**: `pick_enemy_id() -> String` — weighted random sample from `enemy_pool`; fast path for single-entry pool; warns and returns `""` for empty pool

### `scripts/data_models/BurnEffect.gd` (`class_name BurnEffect extends RefCounted`)
- **fields**: `remaining_duration: float`, `tick_damage: float`, `_seconds_until_next_tick: float`
- **methods**: `apply(p_tick_damage: float, duration: float)`, `extend(seconds: float)`, `process(delta: float) -> float`, `is_active() -> bool`

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
- **methods**: `return_to_room(room_id: String)`, `free_current_room()`, `_load_room(room_id, entry_direction)`, `_configure_doors(room_node, room_id)`

### `scripts/dungeon/RoomManager.gd` — stub (no class_name, no logic)

### `scripts/dungeon/RoomSpawner.gd` (`class_name RoomSpawner extends Node`)
- **exports**: `room_id: String`, `room_type_id: String`, `auto_register: bool`, `difficulty_mult: float`, `depth: int`
- **signals**: `room_cleared(room_id: String)`, `room_entered(room_id: String)`, `enemy_defeated(enemy_type_id: String)`
- **property**: `essence_mult: float`
- **fields**: `_depth_tiers: Array` — loaded from `dungeon_config.json` depth_tiers; used in `_resolve_wave_config()`
- **wave state**: `_wave_index: int`, `_total_killed: int`, `_total_enemies: int`
- **depth-band routing**: `_load_config()` routes combat rooms (those in `combat_room_pool`) to `_load_depth_band_config()`; non-combat rooms use `spawn_configs` as before
- **methods**: `_load_depth_band_config(raw: Dictionary) -> RoomSpawnConfig` — finds matching depth band, builds `wave_spawn_points`, validates pool enemy IDs
- **methods**: `_resolve_wave_config()`, `_spawn_wave(wave_idx: int)`, `_spawn_enemies_legacy()`, `_lock_doors()`, `_unlock_doors()`

---

## Scripts — Services (`scripts/services/`)

### `scripts/services/DifficultyService.gd` (`class_name DifficultyService extends RefCounted`)
- **methods**: `get_multiplier() -> float` — stub, returns 1.0

### `scripts/services/RewardsService.gd` (`class_name RewardsService extends RefCounted`)
- **methods**: `get_room_reward(room_id) -> Dictionary` — stub, returns {}

---

## Scripts — Other (`scripts/`)

### `scenes/player/components/PoisonComponent.gd` (`class_name PoisonComponent extends Node`)
- **properties**: `is_poisoned: bool` (get: `_remaining_duration > 0.0`)
- **methods**: `apply(duration: float, modifier: float) -> void` — stacks duration additively on re-apply; sets modifier only on fresh application; no-op when duration ≤ 0; `get_damage_mult() -> float` — returns `1.0 - _damage_modifier` while poisoned, else `1.0`
- **notes**: self-ticking via `_physics_process`; permanent child node of `Player.tscn`; Enemy grabs it at runtime via `body.get_node_or_null("PoisonComponent")`

### `scripts/meta/PassiveIncomeSystem.gd` — stub
### `scripts/Utilities.gd` — stub
### `scripts/NumberFormatter.gd` — stub

---

## Scenes — Core (`scenes/core/`)

### `scenes/core/Main.gd`
- **const**: `BOSS_ROOM_WORLD_POS = Vector2(0, -3000)`
- **key node refs**: `_dungeon_gen: DungeonGenerator`, `_room_loader: RoomLoader`, `_player: Node`, `_movement: MovementComponent`, `_stats: StatsComponent`, `_skill_component: SkillComponent`, `_dodge_component: DodgeComponent`, `_exploration_hud: ExplorationHUD`, `_hub_room`, `_results_layer`, `_boss_room_spawner: RoomSpawner`, `_boss_victory_layer`, `_boss_relic_pending: bool`, `_boss_kill_popup_layer: CanvasLayer`, `_first_boss_popup_pending: bool`, `_book_of_skill_popup_pending: bool`, `_boss_return_room_id: String`
- **methods**: `_on_run_started()`, `_on_run_ended(reason)`, `_on_boss_teleport_pressed()`, `_on_boss_continue_pressed()`, `_on_boss_cash_out_pressed()`, `_on_boss_room_cleared(room_id)`, `_show_boss_victory_overlay()`, `_show_boss_kill_popup()`, `_show_book_of_skill_popup()`, `_on_relic_offer_ready(options)`, `_on_relic_picked(relic_id)`, `_on_results_return()`

---

## Scenes — Player (`scenes/player/`)

### `scenes/player/components/CombatComponent.gd`
- **signals**: `melee_hit_landed`
- **exports**: `attack_damage: float`, `attack_interval: float`, `_stats_component: StatsComponent`
- **properties**: `_base_crit_chance: float`, `_base_crit_multiplier: float`, `_crit_chance: float` (effective), `_crit_multiplier: float` (effective)
- **methods**: `_recompute_stats()` — recalculates `attack_damage`, `attack_interval`, `_crit_chance`, `_crit_multiplier` from base values and active relic addends/mults; called on `run_started`, `relic_applied`, `relics_cleared`

### `scenes/player/components/DodgeComponent.gd` (`class_name DodgeComponent extends Node`)
- **signals**: `cooldown_changed(remaining: float, total: float)`
- **const**: `DASH_DURATION_SEC = 0.1`
- **exports**: `_movement: MovementComponent`, `_stats: StatsComponent`, `_root: RootComponent`
- **methods**: `activate() -> void` — guarded by `RunManager.is_run_active`, `_cooldown_remaining`, `_is_dashing`, and `_root.is_rooted`; sets `_stats.is_invulnerable = true`, begins dash in `_movement.last_direction`; `_end_dash() -> void` — clears invulnerability, starts cooldown; reads config from `ResourceManager.get_skills()` in `_ready()`

### `scenes/player/components/MovementComponent.gd`
- **exports**: `move_speed: float`, `_root: RootComponent`
- **properties**: `last_direction: Vector2` — cached each `_physics_process` frame when joystick input is non-zero; default `Vector2.DOWN`
- **methods**: `set_joystick(joystick: JoystickControl)`

### `scenes/player/components/RootComponent.gd` (`class_name RootComponent extends Node`)
- **properties**: `is_rooted: bool` (computed; true when `_root_remaining > 0.0`)
- **methods**: `apply_root(duration: float) -> void` — sets `_root_remaining = maxf(_root_remaining, duration)`; refresh-to-longest, no stacking

### `scenes/player/components/SkillComponent.gd` (`class_name SkillComponent extends Node`)
- **signals**: `charges_changed(current: int, maximum: int)`, `cooldown_changed(remaining: float, total: float)`
- **const**: `SKILL_ID = "magic_missile"`
- **exports**: `_combat_component: CombatComponent`
- **properties**: `_max_charges: int`, `_current_charges: int`, `_chain_damage_mult: float`, `_burn_damage_per_tick: float`, `_burn_duration: float`, `_burn_extend_seconds: float`, `_cooldown_duration: float`, `_cooldown_remaining: float`, `_base_crit_chance: float`, `_base_crit_multiplier: float`, `_crit_chance: float` (effective), `_crit_multiplier: float` (effective)
- **methods**: `_recompute_crit_stats()` — recalculates `_crit_chance` and `_crit_multiplier` from base values and active relic addends; called on `run_started`, `relic_applied`, `relics_cleared`; `_on_skill_button_pressed()` — guarded by cooldown + charge gates; spends 1 charge, finds closest enemy, applies crit roll, spawns homing Projectile with `_chain_damage_mult`, starts cooldown; `_on_melee_hit_landed()` — unconditionally restores 1 charge (capped at max), then calls `RelicManager.on_melee_hit()` and if true grants 1 additional charge (capped); emits `charges_changed` for each grant; `_reset_charges()` — sets current to max, clears cooldown, emits both signals; `_process(delta)` — counts down cooldown, emits cooldown_changed each frame while active
- **meta-upgrade**: `_load_skill_data()` applies `+1` to `_max_charges` when `MetaManager.is_missile_extra_charge_owned` is true, before setting `_current_charges = _max_charges`

### `scenes/player/components/StatsComponent.gd`
- **exports**: `max_health: float`, `is_player: bool`
- **signals**: `health_changed(new_health: float, max_health: float)`, `died`
- **properties**: `damage_reduction: float` (0.0 default; recomputed from relics on `relic_applied`/`relics_cleared` for player; set from `EnemyData` for enemies); `is_invulnerable: bool` (set true by DodgeComponent at dash start; cleared at dash end; guards both `take_damage` and `take_damage_raw`)
- **methods**: `take_damage(amount: float)`, `take_damage_raw(amount: float)`, `heal(amount: float)`, `reset()`
- **static methods**: `compute_reduced_damage(amount: float, reduction: float) -> float`, `regen_tick_amount(rate: float, max_health: float, delta: float) -> float`, `apply_regen_clamp(current: float, amount: float, max_health: float) -> float`
- **notes**: `_process(delta)` ticks HP regen when `is_player`, `RunManager.is_run_active`, and `RelicManager.get_stat_addend("hp_regen") > 0`; `take_damage_raw()` bypasses DR (used for burn DoT); both damage methods return early when `is_invulnerable`

---

## Scenes — Combat (`scenes/combat/`)

### `scenes/combat/projectiles/Projectile.gd` (`class_name Projectile extends Node2D`)
- **exports**: `_hit_area: Area2D`
- **methods**: `setup(target: Enemy, damage: float, speed: float, max_distance: float, chain_damage_mult: float, burn_damage_per_tick: float, burn_duration: float, burn_extend_seconds: float)` — initialises homing target, damage, speed, max travel distance, chain multiplier, burn params and connects hit collision; `_try_chain(primary_target: Enemy)` — if `chaining_stone` relic held, applies `_damage * (_chain_damage_mult + RelicManager.get_chain_damage_bonus())` to closest other living enemy; if `burn` relic held, also calls `on_burn_hit()` on chain target

### `scenes/combat/enemies/Enemy.gd`
- **const**: `DETECTION_RANGE_FALLBACK = 300.0`
- **exports**: `enemy_type_id: String`, `_hp_bar: HPBar` — optional; assigned in Inspector after instancing HPBar.tscn inside Enemy.tscn; if null, no HP bar is shown
- **fields**: `_spawn_delay: float` — per-instance countdown read from `dungeon_config.json → enemy_spawn.spawn_delay`; blocks movement and contact damage until it reaches 0; `_root_cooldown_remaining: float` — per-instance cooldown between successive roots applied to the player; `_root: RootComponent` — child node instantiated in `_ready()`; tracks root status applied to this enemy by the player; `_poison: PoisonComponent` — child node instantiated in `_ready()`; tracks poison status applied to this enemy by the player relic
- **signals**: `defeated`
- **methods**: `initialize(data: EnemyData)`, `apply_difficulty(mult: float)` — scales max/current health and emits `health_changed` so connected HP bars update immediately, `get_hp_ratio() -> float`, `is_burning() -> bool`, `take_damage(amount: float)`, `on_burn_hit(tick_dmg: float, base_duration: float, extend_seconds: float)`, `apply_root(duration: float) -> void` — applies root to this enemy (refresh-to-longest); called by CombatComponent when root relic procs; `apply_poison(duration: float, modifier: float) -> void` — applies poison to this enemy (stacks duration); called by RelicManagerImpl.try_apply_poison via CombatComponent

---

## Scenes — Dungeon (`scenes/dungeon/`)

### `scenes/dungeon/doors/Door.gd` (`class_name Door`)
- **exports**: `direction: String`, `target_room_id: String`
- **fields**: `locked: bool` — when `true`, suppresses `door_activated`; set by `RoomSpawner` on enemy spawn / room clear
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

### `scenes/hub/ForgeUpgradeScreen.gd` (`class_name ForgeUpgradeScreen extends Control`)
- **signals**: `close_pressed`
- **exports**: `_damage_button: Button`, `_missile_charge_button: Button`, `_rarity_luck_button: Button`, `_close_button: Button`
- **methods**: `_update_buttons()`, `_update_damage_button()`, `_update_missile_charge_button()`, `_update_rarity_luck_button()`, `_on_damage_buy()`, `_on_missile_charge_buy()`, `_on_rarity_luck_buy()`

### `scenes/hub/LabUpgradeScreen.gd` (`class_name LabUpgradeScreen extends Control`)
- **signals**: `close_pressed`
- **exports**: `_essence_button: Button`, `_shard_gen_button: Button`, `_transmuter_button: Button`, `_storage_cap_button: Button`, `_close_button: Button`
- **methods**: `_update_buttons()`, `_update_essence_button()`, `_update_shard_gen_button()`, `_update_transmuter_button()`, `_update_storage_cap_button()`, `_on_essence_pressed()`, `_on_shard_gen_pressed()`, `_on_transmuter_pressed()`, `_on_storage_cap_pressed()`

### `scenes/hub/BookOfSkill.gd` (`class_name BookOfSkill extends Control`)
- **exports**: `_not_created_visual: ColorRect`, `_created_visual: ColorRect`, `_label: Label`, `_button: Button`, `_buy_overlay_scene: PackedScene`, `_interior_scene: PackedScene`
- **methods**: `_update_visuals()`, `_on_button_pressed()`, `_show_buy_overlay()`, `_on_buy_pressed()`, `_show_interior()`, `_close_overlay()`

### `scenes/hub/BookOfSkillBuyOverlay.gd` (`class_name BookOfSkillBuyOverlay extends Control`)
- **signals**: `buy_pressed`, `cancel_pressed`
- **exports**: `_buy_button: Button`, `_cancel_button: Button`, `_cost_label: Label`
- **methods**: `_update_button()`

### `scenes/hub/BookOfSkillInterior.gd` (`class_name BookOfSkillInterior extends Control`)
- **signals**: `close_pressed`
- **exports**: `_close_button: Button`

### `scenes/hub/BossRunButton.gd` (`class_name BossRunButton extends Control`)
- **signals**: `boss_run_pressed`
- **exports**: `_button: Button`
- **methods**: `_update_visibility()`, `_on_pressed()`

### `scenes/hub/HubRoom.gd`
- **signals**: `hub_exited`, `hub_boss_run_pressed`
- **exports**: `teleport_door: TeleportDoor`, `_boss_run_button: BossRunButton`

### `scenes/hub/GoldDisplay.gd`
- **exports**: `_label: Label`, `_cap_label: Label`
- Connects to `MetaManager.gold_changed` and `MetaManager.shards_changed`; displays gold and offline storage cap hours

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
- **signals**: `boss_teleport_pressed`, `dodge_button_pressed`
- **const**: `CHARGE_ACTIVE_COLOR`, `CHARGE_SPENT_COLOR`, `SKILL_READY_MODULATE`, `SKILL_COOLDOWN_MODULATE`
- **exports**: `_boss_button: Button`, `_skill_button: Button`, `_dodge_button: Button`, `_hp_bar: HPBar`, `_charge_pips_container: Control`
- **methods**: `setup_hp_bar(stats: StatsComponent) -> void`, `setup_skill(skill: SkillComponent) -> void`, `setup_dodge(dodge: DodgeComponent) -> void`, `_build_charge_pips(count: int) -> void`, `_on_cooldown_changed(remaining: float, _total: float) -> void`, `_on_dodge_cooldown_changed(remaining: float, _total: float) -> void`
- **static methods**: `is_boss_available(cleared_count: int, required: int) -> bool`

### `scenes/ui/hud/HPBar.gd` (`class_name HPBar extends Control`)
- **exports**: `_bg: ColorRect`, `_fill: ColorRect`, `_label: Label`
- **methods**: `setup(stats: StatsComponent) -> void`

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
| `data/meta_config.json` | `shard_divisor: 3`, `boss_run_shard_award: 35`, `relic_tier_weights`, `gold_rate_per_hour: 100`, `magic_forge` (name, cost, upgrades → `damage_upgrade` {name, base_cost, cost_scale, max_levels, damage_per_level}, `missile_charge_upgrade` {name: "Arcane Reservoir", cost: 150}, `rarity_luck_upgrade` {name: "Rarity Luck", cost: 350, promotion_chance: 0.1}), `mage_tower` (name, cost, upgrades → `dungeon_expansion` {name, cost}, `relic_system` {name, cost}, `boss_challenge` {name, cost}), `alchemy_lab` (name, cost: 500, upgrades → `essence_gain` {name, base_cost: 0, max_levels: 1, essence_per_level: 0.05}, `gold_generator` {name: "Transmuter", cost: 50}, `gold_storage_cap` {name: "Gold Storage", base_hours: 4, hours_per_level: 4, base_cost: 100, cost_scale: 1.5, max_levels: 2}) |
| `data/relics.json` | `relics` dict — 8 relics across 4 stat categories; uncommon includes `chaining_stone` and `burn` ("Living Ember") (both conditional, `effect_stat: ""`) |
| `data/skills.json` | `skills` array — `magic_missile` skill: `speed`, `max_distance`, `max_charges: 3`, `cooldown: 1.0`, `chain_damage_mult: 0.5`, `burn_damage_per_tick: 0.10`, `burn_duration: 2.0`, `burn_extend_seconds: 2.0` |
| `data/upgrades.json` | (stub/TBD) |
| `data/rooms/*.tres` | RoomData resources: `CombatRoom01`, `CombatRoom02`, `EliteRoom01`, `BossRoom01`, `StartRoom01` |

class_name Enemy
extends CharacterBody2D

const DETECTION_RANGE_FALLBACK: float = 300.0

## Thorn-burst direction sets — NE/NW/SE/SW (4-way) and + N/S (6-way).
const THORNS_DIRS_4: Array[Vector2] = [
	Vector2(0.707, -0.707),
	Vector2(-0.707, -0.707),
	Vector2(0.707, 0.707),
	Vector2(-0.707, 0.707),
]
const THORNS_DIRS_6: Array[Vector2] = [
	Vector2(0.707, -0.707),
	Vector2(-0.707, -0.707),
	Vector2(0.707, 0.707),
	Vector2(-0.707, 0.707),
	Vector2(0.0, -1.0),
	Vector2(0.0, 1.0),
]

## Enemy type to load from data/enemies.json. Set in the Inspector.
@export var enemy_type_id: String = "slime"

var _data: EnemyData

signal defeated

@onready var _stats: StatsComponent = $StatsComponent
@export var _hp_bar: HPBar

## --- Contact damage (US2) ---
@onready var _contact_area: Area2D = $ContactArea

var _spawn_delay: float = 0.0

var _burn: BurnEffect = null

var _root: RootComponent = null
var _poison: PoisonComponent = null

var _player_stats: StatsComponent = null
var _player_root: RootComponent = null
var _player_poison: PoisonComponent = null
var _in_contact: bool = false
var _damage_timer: float = 0.0
var _root_cooldown_remaining: float = 0.0
var _heal_cooldown_remaining: float = 0.0
var _follow_target: Enemy = null
var _buff_cooldown_remaining: float = 0.0
var _zone_regen_rate: float = 0.0
var _zone_attack_speed_bonus: float = 0.0
var _is_ranged: bool = false
var _thorns_fire_cooldown_remaining: float = 0.0

## --- Pursuit AI (US3) ---
enum EnemyState { IDLE, PURSUING, TELEGRAPHING, CHARGING, STUNNED }

var _state: EnemyState = EnemyState.IDLE
var _player_ref: Node2D = null

## --- Shield state ---
var _current_shield_hp: int = 0
var _stun_remaining: float = 0.0
var _shield_visual: ColorRect = null

## --- Charge attack state ---
var _charge_cooldown_remaining: float = 0.0
var _telegraph_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_distance_remaining: float = 0.0
var _telegraph_node: Node2D = null
var _charge_hit_delivered: bool = false

@onready var _detection_area: Area2D = $DetectionArea


func _ready() -> void:
	var entry: Dictionary = ResourceManager.get_enemy_data(enemy_type_id)
	assert(not entry.is_empty(),
		"Enemy: no entry found in enemies.json for id={id}".format({"id": enemy_type_id}))

	_root = RootComponent.new()
	add_child(_root)
	_poison = PoisonComponent.new()
	add_child(_poison)

	initialize(EnemyData.from_dict(entry))

	var enemy_spawn_cfg: Dictionary = ResourceManager.get_dungeon_config().get("enemy_spawn", {})
	_spawn_delay = float(enemy_spawn_cfg.get("spawn_delay", 1.0))
	var _ranged_threshold: float = float(enemy_spawn_cfg.get("enemy_ranged_threshold", 40.0))
	_is_ranged = EnemyData.is_ranged_attacker(_data.attack_range, _ranged_threshold)

	if _hp_bar != null:
		_hp_bar.setup(_stats)

	# Wire death signal.
	_stats.died.connect(_on_died)

	# Wire contact damage signals.
	_contact_area.body_entered.connect(_on_contact_entered)
	_contact_area.body_exited.connect(_on_contact_exited)

	# Wire detection signals.
	_detection_area.body_entered.connect(_on_detected)
	_detection_area.body_exited.connect(_on_lost)


@export var _visual: ColorRect

func initialize(data: EnemyData) -> void:
	_data = data
	_stats.max_health = data.max_health
	_stats.current_health = data.max_health
	_stats.damage_reduction = data.damage_reduction
	_stats.reflect_amount = data.reflect_amount
	_apply_detection_range(data.detection_range)
	_apply_attack_range(data.attack_range)
	_visual.color = data.color
	var spawn_cfg: Dictionary = ResourceManager.get_dungeon_config().get("enemy_spawn", {})
	var base_size: float = float(spawn_cfg.get("base_size", 32.0))
	var px: float = base_size * data.size
	_visual.size = Vector2(px, px)
	_visual.position = Vector2(-px * 0.5, -px * 0.5)
	var body_shape := get_node("CollisionShape2D") as CollisionShape2D
	(body_shape.shape as CircleShape2D).radius = px * 0.5
	_heal_cooldown_remaining = data.heal_cooldown
	_buff_cooldown_remaining = data.buff_cooldown
	# Shield visual — placeholder ColorRect; swap for sprite in a future feature.
	var shield_size: float = px * 1.1
	_shield_visual = ColorRect.new()
	_shield_visual.size = Vector2(shield_size, shield_size)
	_shield_visual.position = Vector2(-shield_size * 0.5, -shield_size * 0.5)
	_shield_visual.color = Color(0.3, 0.6, 1.0, 0.4)
	_shield_visual.visible = false
	add_child(_shield_visual)


func _apply_attack_range(range_px: float) -> void:
	var shape_node := _contact_area.get_node("CollisionShape2D") as CollisionShape2D
	(shape_node.shape as CircleShape2D).radius = maxf(range_px, 1.0)


func _apply_detection_range(range_px: float) -> void:
	var effective: float = range_px
	if effective <= 0.0:
		push_warning("Enemy: invalid detection_range={r} for id={id} — using fallback {f}".format({
			"r": range_px, "id": _data.id, "f": DETECTION_RANGE_FALLBACK,
		}))
		effective = DETECTION_RANGE_FALLBACK
	var shape_node := _detection_area.get_node("CollisionShape2D") as CollisionShape2D
	(shape_node.shape as CircleShape2D).radius = effective


func apply_difficulty(mult: float) -> void:
	_stats.max_health = floorf(_stats.max_health * mult)
	_stats.current_health = _stats.max_health
	_stats.health_changed.emit(_stats.current_health, _stats.max_health)


func get_hp_ratio() -> float:
	if _stats.max_health <= 0.0:
		return 1.0
	return _stats.current_health / _stats.max_health


## Returns true if the enemy currently has an active burn effect.
## Returns false if no burn has ever been applied or if the burn has expired.
func is_burning() -> bool:
	if _burn == null:
		return false
	return _burn.is_active()


## Activates the shield, setting current shield HP to the data-configured maximum.
## No-op for enemies whose data has shield_hp = 0.
func activate_shield() -> void:
	if _data.shield_hp <= 0:
		return
	_current_shield_hp = _data.shield_hp
	if _shield_visual != null:
		_shield_visual.visible = true


func take_damage(amount: float, attacker: StatsComponent = null) -> void:
	if _current_shield_hp <= 0:
		_stats.take_damage(amount, attacker)
		_try_fire_thorns()
		return
	var overflow: float = amount - float(_current_shield_hp)
	_current_shield_hp = maxi(0, _current_shield_hp - int(ceilf(amount)))
	if _current_shield_hp == 0:
		_on_shield_broken()
	if overflow > 0.0:
		_stats.take_damage(overflow, attacker)
	_try_fire_thorns()


func _on_shield_broken() -> void:
	_current_shield_hp = 0
	if _shield_visual != null:
		_shield_visual.visible = false
	_stun_remaining = _data.shield_stun_duration
	_state = EnemyState.STUNNED


## Heals regular HP only — shield HP is intentionally unaffected by healing.
func receive_heal(amount: float) -> void:
	_stats.heal(amount)


func apply_zone_buff(regen: float, speed: float) -> void:
	_zone_regen_rate += regen
	_zone_attack_speed_bonus += speed


func remove_zone_buff(regen: float, speed: float) -> void:
	_zone_regen_rate = maxf(0.0, _zone_regen_rate - regen)
	_zone_attack_speed_bonus = maxf(0.0, _zone_attack_speed_bonus - speed)


## Applies poison to this enemy. Stacks duration additively; modifier unchanged on re-apply.
func apply_poison(duration: float, modifier: float) -> void:
	if _poison == null:
		return
	_poison.apply(duration, modifier)


## Applies a root to this enemy for the given duration (refresh-to-longest).
func apply_root(duration: float) -> void:
	if _root == null:
		return
	_root.apply_root(duration)


## Applies burn if none active, or extends existing active burn duration.
func on_burn_hit(tick_dmg: float, base_duration: float, extend_seconds: float) -> void:
	if _burn != null and _burn.is_active():
		_burn.extend(extend_seconds)
		return
	_burn = BurnEffect.new()
	_burn.apply(tick_dmg, base_duration)


func _physics_process(delta: float) -> void:
	if _thorns_fire_cooldown_remaining > 0.0:
		_thorns_fire_cooldown_remaining = maxf(0.0, _thorns_fire_cooldown_remaining - delta)

	if _spawn_delay > 0.0:
		_spawn_delay -= delta
		return

	if _root != null and _root.is_rooted:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Stun guard — suppresses all AI until stun expires.
	if _state == EnemyState.STUNNED:
		_stun_remaining -= delta
		if _stun_remaining <= 0.0:
			_stun_remaining = 0.0
			_state = EnemyState.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Charge telegraph phase — enemy frozen while rectangle is displayed.
	if _state == EnemyState.TELEGRAPHING:
		velocity = Vector2.ZERO
		move_and_slide()
		_telegraph_timer += delta
		if _telegraph_timer >= _data.charge_telegraph_duration:
			_begin_charge()
		return

	# Charge movement phase — enemy lunges at 3× speed through the telegraph zone.
	if _state == EnemyState.CHARGING:
		velocity = _charge_direction * _data.move_speed * _data.charge_speed_mult
		move_and_slide()
		_charge_distance_remaining -= velocity.length() * delta
		if _in_contact and _player_stats != null and is_instance_valid(_player_stats) and not _charge_hit_delivered:
			_player_stats.take_damage(_data.charge_attack_damage, _stats)
			_charge_hit_delivered = true
		if _charge_distance_remaining <= 0.0:
			_cancel_charge()
			_state = EnemyState.PURSUING
			_charge_cooldown_remaining = _data.charge_attack_cooldown
		return

	# Burn damage tick — bypasses damage_reduction intentionally.
	if _burn != null and _burn.is_active():
		var burn_dmg: float = _burn.process(delta)
		if burn_dmg > 0.0:
			_stats.take_damage_raw(burn_dmg)

	# Root cooldown tick.
	if _root_cooldown_remaining > 0.0:
		_root_cooldown_remaining = maxf(0.0, _root_cooldown_remaining - delta)

	# Contact damage tick (US2).
	if _handle_contact_attack(delta):
		return

	# Regen tick (base + zone bonus).
	var effective_regen: float = _data.regen_rate + _zone_regen_rate
	if effective_regen > 0.0:
		_stats.heal(StatsComponent.regen_tick_amount(effective_regen, _stats.max_health, delta))

	# Buff cast tick.
	if _data.buff_cooldown > 0.0:
		_buff_cooldown_remaining -= delta
		if _buff_cooldown_remaining <= 0.0:
			_cast_buff_zone()
			_buff_cooldown_remaining = _data.buff_cooldown

	# Ally-heal skill.
	if _data.heal_amount > 0.0:
		_heal_cooldown_remaining -= delta
		if _heal_cooldown_remaining <= 0.0:
			_do_heal_scan()
			_heal_cooldown_remaining = _data.heal_cooldown

	# Healer follow movement — orbit closest ally at heal_radius - 20 standoff.
	if _data.id.ends_with("_healer"):
		_follow_target = null
		var closest_dist: float = INF
		for child: Node in get_parent().get_children():
			if not child is Enemy:
				continue
			if child == self:
				continue
			var d: float = global_position.distance_to((child as Enemy).global_position)
			if d >= closest_dist:
				continue
			closest_dist = d
			_follow_target = child as Enemy
		if _follow_target != null:
			_do_healer_follow_move()
			return

	# Pursuit movement (US3).
	if not (_state == EnemyState.PURSUING and is_instance_valid(_player_ref)):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Charge cooldown tick — triggers telegraph when it expires.
	if _data.charge_attack_cooldown > 0.0:
		_charge_cooldown_remaining -= delta
		if _charge_cooldown_remaining <= 0.0:
			_start_charge_telegraph()
			return

	var to_player := _player_ref.global_position - global_position
	var dist := to_player.length()

	if dist < maxf(0.0, _data.attack_range - 10.0):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = to_player.normalized() * _data.move_speed
	move_and_slide()

func _handle_contact_attack(delta: float) -> bool:
	if not (_in_contact and _player_stats != null and is_instance_valid(_player_stats)):
		return false
	_damage_timer -= delta
	if _damage_timer > 0.0:
		return false
	if _is_ranged:
		_fire_projectile()
		_damage_timer = _data.damage_cooldown
		return true
	_player_stats.take_damage(_data.damage * _poison.get_damage_mult(), _stats)
	_damage_timer = maxf(0.1, _data.damage_cooldown / (1.0 + _zone_attack_speed_bonus))
	_try_apply_root()
	_try_apply_poison()
	return false


func _fire_projectile() -> void:
	if not is_instance_valid(_player_ref):
		return
	var projectile_scene: PackedScene = load("res://scenes/combat/enemies/EnemyProjectile.tscn")
	if projectile_scene == null:
		return
	var spawn_cfg: Dictionary = ResourceManager.get_dungeon_config().get("enemy_spawn", {})
	var p_speed: float = float(spawn_cfg.get("projectile_speed", 400.0))
	var p_max_range: float = float(spawn_cfg.get("projectile_max_range", 1200.0))
	var projectile := projectile_scene.instantiate() as EnemyProjectile
	var direction: Vector2 = global_position.direction_to(_player_ref.global_position)
	projectile.setup(direction, _data.damage, p_speed, p_max_range)
	get_parent().add_child(projectile)
	projectile.global_position = global_position


func _try_fire_thorns() -> void:
	if not _data.thorns_on_hit:
		return
	if _thorns_fire_cooldown_remaining > 0.0:
		return
	_fire_thorns()
	_thorns_fire_cooldown_remaining = _data.thorns_fire_cooldown


func _fire_thorns() -> void:
	var projectile_scene: PackedScene = load("res://scenes/combat/enemies/EnemyProjectile.tscn")
	if projectile_scene == null:
		return
	var dirs: Array[Vector2] = THORNS_DIRS_4 if _data.thorns_directions <= 4 else THORNS_DIRS_6
	for dir: Vector2 in dirs:
		var projectile := projectile_scene.instantiate() as EnemyProjectile
		projectile.setup(dir, _data.thorns_damage, _data.thorns_speed, _data.thorns_range)
		get_parent().add_child(projectile)
		projectile.global_position = global_position


func _do_healer_follow_move() -> void:
	var standoff: float = maxf(0.0, _data.heal_radius - 20.0)
	var to_target: Vector2 = _follow_target.global_position - global_position
	if to_target.length() > standoff:
		velocity = to_target.normalized() * _data.move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _cast_buff_zone() -> void:
	var zone_scene: PackedScene = load("res://scenes/combat/enemies/EnemyBuffZone.tscn")
	if zone_scene == null:
		return
	var spawn_pos: Vector2 = global_position
	if is_instance_valid(_player_ref):
		var closest_dist: float = INF
		for child: Node in get_parent().get_children():
			if not child is Enemy:
				continue
			var d: float = _player_ref.global_position.distance_to((child as Enemy).global_position)
			if d >= closest_dist:
				continue
			closest_dist = d
			spawn_pos = (child as Enemy).global_position
	var zone := zone_scene.instantiate() as EnemyBuffZone
	get_parent().add_child(zone)
	zone.global_position = spawn_pos
	zone.setup(_data.buff_zone_radius, _data.buff_zone_duration, _data.buff_regen_rate, _data.buff_attack_speed_bonus)


func _do_heal_scan() -> void:
	for child: Node in get_parent().get_children():
		if not (child is Enemy) or child == self:
			continue
		if global_position.distance_to(child.global_position) > _data.heal_radius:
			continue
		child.receive_heal(_data.heal_amount)


func _try_apply_root() -> void:
	if _data.root_duration <= 0.0:
		return
	if _root_cooldown_remaining > 0.0:
		return
	if _player_root == null:
		return
	_player_root.apply_root(_data.root_duration)
	_root_cooldown_remaining = _data.root_cooldown


func _try_apply_poison() -> void:
	if _data.poison_duration <= 0.0:
		return
	if _player_poison == null:
		return
	_player_poison.apply(_data.poison_duration, _data.poison_modifier)


func _cancel_charge() -> void:
	if is_instance_valid(_telegraph_node):
		_telegraph_node.queue_free()
	_telegraph_node = null
	_charge_direction = Vector2.ZERO
	_telegraph_timer = 0.0
	_charge_distance_remaining = 0.0
	_charge_hit_delivered = false
	_state = EnemyState.IDLE


func _start_charge_telegraph() -> void:
	if not is_instance_valid(_player_ref):
		return
	_charge_direction = (_player_ref.global_position - global_position).normalized()
	var px: float = _visual.size.x
	var container := Node2D.new()
	get_parent().add_child(container)
	container.global_position = global_position
	container.rotation = _charge_direction.angle()
	var rect := ColorRect.new()
	rect.size = Vector2(_data.charge_attack_length, px)
	rect.position = Vector2(0.0, -px * 0.5)
	rect.color = Color(1.0, 0.3, 0.3, 0.4)
	container.add_child(rect)
	_telegraph_node = container
	_telegraph_timer = 0.0
	_state = EnemyState.TELEGRAPHING


func _begin_charge() -> void:
	_charge_distance_remaining = _data.charge_attack_length
	_charge_hit_delivered = false
	_state = EnemyState.CHARGING


func _on_died() -> void:
	if is_instance_valid(_telegraph_node):
		_telegraph_node.queue_free()
	_telegraph_node = null
	defeated.emit()
	queue_free()


# --- Contact damage callbacks (US2) ---

func _on_contact_entered(body: Node2D) -> void:
	if body.has_node("StatsComponent"):
		_player_stats = body.get_node("StatsComponent")
		_player_root = body.get_node_or_null("RootComponent")
		_player_poison = body.get_node_or_null("PoisonComponent")
		_in_contact = true
		_damage_timer = 0.0


func _on_contact_exited(_body: Node2D) -> void:
	_in_contact = false
	_player_root = null
	_player_poison = null


# --- Pursuit AI callbacks (US3) ---

func _on_detected(body: Node2D) -> void:
	if not body.has_node("StatsComponent"):
		return
	_player_ref = body
	_state = EnemyState.PURSUING
	if _data.charge_attack_cooldown > 0.0:
		_charge_cooldown_remaining = _data.charge_attack_cooldown


func _on_lost(body: Node2D) -> void:
	if body != _player_ref:
		return
	if _state == EnemyState.TELEGRAPHING or _state == EnemyState.CHARGING:
		_cancel_charge()
	_state = EnemyState.IDLE
	_player_ref = null

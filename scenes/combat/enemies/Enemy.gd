class_name Enemy
extends CharacterBody2D

const DETECTION_RANGE_FALLBACK: float = 300.0

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

## --- Pursuit AI (US3) ---
enum EnemyState { IDLE, PURSUING }

var _state: EnemyState = EnemyState.IDLE
var _player_ref: Node2D = null

@onready var _detection_area: Area2D = $DetectionArea


func _ready() -> void:
	# Load enemy data from JSON.
	var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	assert(file != null, "Enemy: failed to open res://data/enemies.json")
	var json_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	assert(parsed is Dictionary, "Enemy: enemies.json root must be a Dictionary")

	var enemies_root: Dictionary = parsed.get("enemies", {})
	var entry: Dictionary = {}
	for category: Variant in enemies_root.values():
		if not category is Array:
			continue
		for item: Variant in category:
			if not (item is Dictionary and item.get("id", "") == enemy_type_id):
				continue
			entry = item
			break
		if not entry.is_empty():
			break
	assert(not entry.is_empty(),
		"Enemy: no entry found in enemies.json for id={id}".format({"id": enemy_type_id}))

	_root = RootComponent.new()
	add_child(_root)
	_poison = PoisonComponent.new()
	add_child(_poison)

	initialize(EnemyData.from_dict(entry))

	var enemy_spawn_cfg: Dictionary = ResourceManager.get_dungeon_config().get("enemy_spawn", {})
	_spawn_delay = float(enemy_spawn_cfg.get("spawn_delay", 1.0))

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


@onready var _visual: ColorRect = $ColorRect

func initialize(data: EnemyData) -> void:
	_data = data
	_stats.max_health = data.max_health
	_stats.current_health = data.max_health
	_stats.damage_reduction = data.damage_reduction
	_apply_detection_range(data.detection_range)
	_apply_attack_range(data.attack_range)
	_visual.color = data.color


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


func take_damage(amount: float) -> void:
	_stats.take_damage(amount)


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
	if _spawn_delay > 0.0:
		_spawn_delay -= delta
		return

	if _root != null and _root.is_rooted:
		velocity = Vector2.ZERO
		move_and_slide()
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
	if _in_contact and _player_stats != null and is_instance_valid(_player_stats):
		_damage_timer -= delta
		if _damage_timer <= 0.0:
			_player_stats.take_damage(_data.damage * _poison.get_damage_mult())
			_damage_timer = _data.damage_cooldown
			_try_apply_root()
			_try_apply_poison()

	# Pursuit movement (US3).
	if not (_state == EnemyState.PURSUING and is_instance_valid(_player_ref)):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := _player_ref.global_position - global_position
	var dist := to_player.length()

	if dist < _data.attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = to_player.normalized() * _data.move_speed
	move_and_slide()

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


func _on_died() -> void:
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
	if body.has_node("StatsComponent"):
		_player_ref = body
		_state = EnemyState.PURSUING


func _on_lost(body: Node2D) -> void:
	if body == _player_ref:
		_state = EnemyState.IDLE
		_player_ref = null

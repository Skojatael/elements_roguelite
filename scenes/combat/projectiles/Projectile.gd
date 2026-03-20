class_name Projectile
extends Node2D

@export var _hit_area: Area2D

var _target: Enemy
var _damage: float
var _speed: float
var _max_distance: float
var _chain_damage_mult: float = 1.0
var _burn_damage_per_tick: float = 0.0
var _burn_duration: float = 2.0
var _burn_extend_seconds: float = 2.0
var _distance_traveled: float = 0.0


## Initialise the projectile after instantiation.
## Must be called before the projectile is added to the scene tree, or immediately after.
func setup(
	target: Enemy,
	damage: float,
	speed: float,
	max_distance: float,
	chain_damage_mult: float,
	burn_damage_per_tick: float,
	burn_duration: float,
	burn_extend_seconds: float
) -> void:
	_target = target
	_damage = damage
	_speed = speed
	_max_distance = max_distance
	_chain_damage_mult = chain_damage_mult
	_burn_damage_per_tick = burn_damage_per_tick
	_burn_duration = burn_duration
	_burn_extend_seconds = burn_extend_seconds
	_hit_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return

	var direction: Vector2 = global_position.direction_to(_target.global_position)
	var step: float = _speed * delta
	global_position += direction * step
	_distance_traveled += step

	if _distance_traveled >= _max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is Enemy:
		return
	var primary: Enemy = body as Enemy
	primary.take_damage(_damage)
	if RelicManager.has_burn_relic():
		primary.on_burn_hit(_damage * _burn_damage_per_tick * RelicManager.get_stat_mult("burn_damage"), _burn_duration, _burn_extend_seconds)
	_try_chain(primary)
	queue_free()


func _try_chain(primary_target: Enemy) -> void:
	if not RelicManager.has_chain_relic():
		return
	if RunManager.current_room == null:
		return
	var room_node: Node = RunManager.current_room.get_parent()
	var chain_target: Enemy = null
	var closest_dist: float = INF
	for child: Node in room_node.get_children():
		if not child is Enemy:
			continue
		if child == primary_target:
			continue
		if not is_instance_valid(child):
			continue
		var dist: float = global_position.distance_to((child as Enemy).global_position)
		if dist >= closest_dist:
			continue
		chain_target = child as Enemy
		closest_dist = dist
	if chain_target == null:
		return
	chain_target.take_damage(_damage * (_chain_damage_mult + RelicManager.get_chain_damage_bonus()))
	if RelicManager.has_burn_relic():
		chain_target.on_burn_hit(_damage * _burn_damage_per_tick * RelicManager.get_stat_mult("burn_damage"), _burn_duration, _burn_extend_seconds)

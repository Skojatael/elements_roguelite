class_name EnemyProjectile
extends Node2D

@export var _hit_area: Area2D

var _direction: Vector2 = Vector2.ZERO
var _damage: float = 0.0
var _speed: float = 0.0
var _max_range: float = 0.0
var _distance_traveled: float = 0.0


func setup(direction: Vector2, damage: float, speed: float, max_range: float) -> void:
	_direction = direction.normalized()
	_damage = damage
	_speed = speed
	_max_range = max_range
	_hit_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step: Vector2 = _direction * _speed * delta
	global_position += step
	_distance_traveled += step.length()
	if _distance_traveled >= _max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.get_node("StatsComponent").take_damage(_damage)
	queue_free()

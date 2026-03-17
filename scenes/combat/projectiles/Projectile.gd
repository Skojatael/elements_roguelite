class_name Projectile
extends Node2D

@export var _hit_area: Area2D

var _target: Enemy
var _damage: float
var _speed: float
var _max_distance: float
var _distance_traveled: float = 0.0


## Initialise the projectile after instantiation.
## Must be called before the projectile is added to the scene tree, or immediately after.
func setup(target: Enemy, damage: float, speed: float, max_distance: float) -> void:
	_target = target
	_damage = damage
	_speed = speed
	_max_distance = max_distance
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
	(body as Enemy).take_damage(_damage)
	queue_free()

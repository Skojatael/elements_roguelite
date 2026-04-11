class_name EnemyBuffZone
extends Area2D

const ZONE_COLOR := Color(0.4, 0.8, 1.0, 0.25)

@export var _collision_shape: CollisionShape2D
@export var _visual: ColorRect

var _regen_rate: float = 0.0
var _attack_speed_bonus: float = 0.0
var _duration_remaining: float = 0.0
var _buffed_enemies: Array[Enemy] = []


func setup(radius: float, duration: float, regen_rate: float, attack_speed_bonus: float) -> void:
	_regen_rate = regen_rate
	_attack_speed_bonus = attack_speed_bonus
	_duration_remaining = duration
	(_collision_shape.shape as CircleShape2D).radius = radius
	_visual.size = Vector2(radius * 2.0, radius * 2.0)
	_visual.position = Vector2(-radius, -radius)
	_visual.color = ZONE_COLOR


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_duration_remaining -= delta
	if _duration_remaining > 0.0:
		return
	_expire()


func _expire() -> void:
	for enemy: Enemy in _buffed_enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.remove_zone_buff(_regen_rate, _attack_speed_bonus)
	_buffed_enemies.clear()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is Enemy:
		return
	var enemy := body as Enemy
	enemy.apply_zone_buff(_regen_rate, _attack_speed_bonus)
	_buffed_enemies.append(enemy)


func _on_body_exited(body: Node2D) -> void:
	if not body is Enemy:
		return
	var enemy := body as Enemy
	_buffed_enemies.erase(enemy)
	enemy.remove_zone_buff(_regen_rate, _attack_speed_bonus)

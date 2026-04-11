class_name ForestBossThorns
extends Enemy

# ---------------------------------------------------------------------------
# Phase thresholds — fixed game-design constants, not tuning knobs.
# ---------------------------------------------------------------------------
const PHASE2_THRESHOLD := 0.667
const PHASE3_THRESHOLD := 0.333

# ---------------------------------------------------------------------------
# Boss state machine
# ---------------------------------------------------------------------------
enum BossState {
	IDLE,
	CHASE,
	WINDUP_CHARGE,
	CHARGING,
	RECOVER,
	THORNS_ACTIVE,
	PHASE_TRANSITION,
	STUNNED,
	DEAD,
}

var _boss_state: BossState = BossState.IDLE

# Phase tracking
var _phase: int = 1
var _phase2_triggered: bool = false
var _phase3_triggered: bool = false

# Per-state timers (_telegraph_timer, _charge_direction, _charge_distance_remaining,
# _charge_hit_delivered, _telegraph_node, _stun_remaining inherited from Enemy)
var _charge_cooldown: float = 0.0
var _recover_timer: float = 0.0
var _transition_timer: float = 0.0
var _thorns_timer: float = 0.0
var _thorns_cooldown_remaining: float = 0.0

# Cached player refs (populated by base Enemy detection area)
var _player_stats_boss: StatsComponent = null


func _ready() -> void:
	super._ready()
	activate_shield()
	_charge_cooldown = _data.charge_attack_cooldown


# ---------------------------------------------------------------------------
# Detection overrides
# ---------------------------------------------------------------------------

func _on_detected(body: Node2D) -> void:
	if not body.has_node("StatsComponent"):
		return
	_player_ref = body
	_player_stats_boss = body.get_node("StatsComponent") as StatsComponent
	if _boss_state == BossState.IDLE:
		_boss_state = BossState.CHASE
	_charge_cooldown = _data.charge_attack_cooldown


func _on_lost(body: Node2D) -> void:
	if body != _player_ref:
		return
	if _boss_state == BossState.WINDUP_CHARGE or _boss_state == BossState.CHARGING:
		_cancel_charge_boss()
	if _boss_state != BossState.STUNNED and _boss_state != BossState.DEAD:
		_boss_state = BossState.IDLE
	_player_ref = null
	_player_stats_boss = null


# ---------------------------------------------------------------------------
# Shield / stun overrides
# ---------------------------------------------------------------------------

func _on_shield_broken() -> void:
	_current_shield_hp = 0
	if _shield_visual != null:
		_shield_visual.visible = false
	_stun_remaining = _data.shield_stun_duration
	_boss_state = BossState.STUNNED


# ---------------------------------------------------------------------------
# Death override
# ---------------------------------------------------------------------------

func _on_died() -> void:
	_boss_state = BossState.DEAD
	if is_instance_valid(_telegraph_node):
		_telegraph_node.queue_free()
	_telegraph_node = null
	defeated.emit()
	queue_free()


# ---------------------------------------------------------------------------
# Phase transition helper
# ---------------------------------------------------------------------------

func _check_phase_transition() -> void:
	if _boss_state == BossState.DEAD:
		return
	if _stats.max_health <= 0.0:
		return
	var ratio: float = _stats.current_health / _stats.max_health
	if not _phase3_triggered and ratio <= PHASE3_THRESHOLD:
		_phase3_triggered = true
		_phase = 3
		_thorns_cooldown_remaining = _data.thorns_cooldown_p3
		_enter_phase_transition()
	elif not _phase2_triggered and ratio <= PHASE2_THRESHOLD:
		_phase2_triggered = true
		_phase = 2
		_thorns_cooldown_remaining = _data.thorns_cooldown_p2
		_enter_phase_transition()


func _enter_phase_transition() -> void:
	_transition_timer = _data.phase_transition_duration
	_boss_state = BossState.PHASE_TRANSITION
	# Visual flash: tint white to signal phase change.
	if _visual != null:
		_visual.color = Color.WHITE


# ---------------------------------------------------------------------------
# Charge helpers
# ---------------------------------------------------------------------------

func _start_windup_charge() -> void:
	if not is_instance_valid(_player_ref):
		return
	_charge_direction = (_player_ref.global_position - global_position).normalized()
	_telegraph_timer = 0.0
	_charge_hit_delivered = false
	# Spawn telegraph rectangle (same pattern as Enemy._start_charge_telegraph).
	var px: float = _visual.size.x if _visual != null else 32.0
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
	_boss_state = BossState.WINDUP_CHARGE


func _cancel_charge_boss() -> void:
	if is_instance_valid(_telegraph_node):
		_telegraph_node.queue_free()
	_telegraph_node = null
	_charge_direction = Vector2.ZERO
	_telegraph_timer = 0.0
	_charge_distance_remaining = 0.0
	_charge_hit_delivered = false


# ---------------------------------------------------------------------------
# Main physics loop
# ---------------------------------------------------------------------------

func take_damage(amount: float, attacker: StatsComponent = null) -> void:
	super.take_damage(amount, attacker)
	if _boss_state != BossState.THORNS_ACTIVE:
		return
	if _thorns_fire_cooldown_remaining > 0.0:
		return
	_fire_thorns()
	_thorns_fire_cooldown_remaining = _data.thorns_fire_cooldown


func _physics_process(delta: float) -> void:
	if _thorns_fire_cooldown_remaining > 0.0:
		_thorns_fire_cooldown_remaining = maxf(0.0, _thorns_fire_cooldown_remaining - delta)

	if _boss_state == BossState.DEAD:
		return

	match _boss_state:
		BossState.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()

		BossState.CHASE:
			_check_phase_transition()
			if _boss_state != BossState.CHASE:
				return
			_charge_cooldown -= delta
			if _data.charge_attack_cooldown > 0.0 and _charge_cooldown <= 0.0 and is_instance_valid(_player_ref):
				_start_windup_charge()
				return
			_thorns_cooldown_remaining -= delta
			if _phase >= 2 and _thorns_cooldown_remaining <= 0.0:
				_enter_thorns_active()
				return
			if is_instance_valid(_player_ref):
				velocity = (_player_ref.global_position - global_position).normalized() * _data.move_speed
			else:
				velocity = Vector2.ZERO
			move_and_slide()

		BossState.WINDUP_CHARGE:
			velocity = Vector2.ZERO
			move_and_slide()
			_telegraph_timer += delta
			if _telegraph_timer < _data.charge_telegraph_duration:
				return
			if is_instance_valid(_telegraph_node):
				_telegraph_node.queue_free()
			_telegraph_node = null
			_charge_distance_remaining = _data.charge_attack_length
			_boss_state = BossState.CHARGING

		BossState.CHARGING:
			velocity = _charge_direction * _data.move_speed * _data.charge_speed_mult
			move_and_slide()
			_charge_distance_remaining -= velocity.length() * delta
			# Deliver charge hit once.
			if _in_contact and _player_stats_boss != null and is_instance_valid(_player_stats_boss) \
					and not _charge_hit_delivered:
				_player_stats_boss.take_damage(_data.charge_attack_damage, _stats)
				_charge_hit_delivered = true
			# End charge on distance exhaustion or wall collision.
			var hit_wall: bool = get_last_slide_collision() != null and velocity.length() > 0.0
			if _charge_distance_remaining <= 0.0 or hit_wall:
				_cancel_charge_boss()
				_recover_timer = _data.recover_duration
				_boss_state = BossState.RECOVER

		BossState.RECOVER:
			velocity = Vector2.ZERO
			move_and_slide()
			_recover_timer -= delta
			if _recover_timer <= 0.0:
				_charge_cooldown = _data.charge_attack_cooldown
				_check_phase_transition()
				if _boss_state == BossState.RECOVER:
					_boss_state = BossState.CHASE

		BossState.THORNS_ACTIVE:
			if is_instance_valid(_player_ref):
				velocity = (_player_ref.global_position - global_position).normalized() \
						* _data.move_speed * _data.thorns_move_speed_mult
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			_thorns_timer -= delta
			if _thorns_timer <= 0.0:
				_exit_thorns_active()

		BossState.PHASE_TRANSITION:
			velocity = Vector2.ZERO
			move_and_slide()
			_transition_timer -= delta
			if _transition_timer > 0.0:
				return
			if _visual != null:
				_visual.color = _data.color
			_boss_state = BossState.CHASE

		BossState.STUNNED:
			_check_phase_transition()
			velocity = Vector2.ZERO
			move_and_slide()
			_stun_remaining -= delta
			if _stun_remaining <= 0.0:
				_stun_remaining = 0.0
				_boss_state = BossState.CHASE


# ---------------------------------------------------------------------------
# Thorns helpers
# ---------------------------------------------------------------------------

func _enter_thorns_active() -> void:
	_thorns_timer = _data.thorns_duration
	_boss_state = BossState.THORNS_ACTIVE
	if _visual != null:
		_visual.color = Color(0.0, 1.0, 0.0, 1.0)


func _exit_thorns_active() -> void:
	if _visual != null:
		_visual.color = _data.color
	_thorns_cooldown_remaining = _data.thorns_cooldown_p2 if _phase == 2 else _data.thorns_cooldown_p3
	_boss_state = BossState.CHASE

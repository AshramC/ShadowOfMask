

extends CharacterBody2D
class_name EnemyBase

enum EnemyType {
	NORMAL,
	ELITE,
	ASSASSIN,
	RIFT,
	SNARE,
	MINION
}

signal hit(damage: int, by_player: bool)

signal died(enemy: EnemyBase)

signal spawned()

signal contacted_player(player: Node2D)

@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var radius: float = GameConstants.ENEMY_RADIUS
@export var max_hp: int = 1
@export var speed_multiplier: float = 1.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var hp: int = 1

var base_speed: float = 0.0

var current_speed: float = 0.0

var velocity_dir: Vector2 = Vector2.ZERO

var is_spawned: bool = false

var spawn_at: int = 0

var flank_sign: int = 1

var wave_id: int = 0

var next_burst_at: int = 0
var burst_until: int = 0

var last_hit_dash_id: int = -1

var contact_cooldown_until: int = 0

var is_active: bool = true

func _ready() -> void:

	_setup_collision_shape()

	hp = max_hp

	base_speed = GameConstants.get_enemy_base_speed(GameManager.stage) * speed_multiplier
	current_speed = base_speed

	flank_sign = 1 if GameManager.randf() > 0.5 else -1

	_init_burst_timer()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return

	var now := Time.get_ticks_msec()

	if not is_spawned:
		if now >= spawn_at:
			is_spawned = true
			is_active = true
			spawned.emit()
		else:
			return

	_update_ai(delta, now)

	_apply_movement(delta)

func initialize(p_wave_id: int, p_spawn_delay_ms: int = 0) -> void:
	wave_id = p_wave_id

	if p_spawn_delay_ms > 0:
		spawn_at = Time.get_ticks_msec() + p_spawn_delay_ms
		is_spawned = false
		is_active = false
	else:
		spawn_at = Time.get_ticks_msec()
		is_spawned = true
		is_active = true

func take_damage(damage: int, dash_id: int = -1) -> bool:
	if not is_active:
		return false

	if dash_id >= 0 and dash_id == last_hit_dash_id:
		return false

	last_hit_dash_id = dash_id
	hp -= damage
	hit.emit(damage, true)

	if hp <= 0:
		die()
		return true

	return false

func die() -> void:
	is_active = false
	died.emit(self)

	_spawn_death_particles()

	queue_free()

func get_type_name() -> String:
	match enemy_type:
		EnemyType.NORMAL: return "normal"
		EnemyType.ELITE: return "elite"
		EnemyType.ASSASSIN: return "assassin"
		EnemyType.RIFT: return "rift"
		EnemyType.SNARE: return "snare"
		EnemyType.MINION: return "minion"
	return "unknown"

func get_color() -> Color:
	match enemy_type:
		EnemyType.NORMAL: return GameConstants.COLOR_NORMAL_ENEMY
		EnemyType.ELITE: return GameConstants.COLOR_ELITE_ENEMY
		EnemyType.MINION: return GameConstants.COLOR_MINION_ENEMY
		EnemyType.ASSASSIN: return GameConstants.ASSASSIN_COLOR
		EnemyType.RIFT: return GameConstants.RIFT_COLOR
		EnemyType.SNARE: return GameConstants.SNARE_COLOR
	return Color.RED

func can_contact_player() -> bool:
	if enemy_type == EnemyType.ELITE:
		return Time.get_ticks_msec() >= contact_cooldown_until
	return true

func set_contact_cooldown() -> void:
	if enemy_type == EnemyType.ELITE:
		contact_cooldown_until = Time.get_ticks_msec() + GameConstants.ELITE_CONTACT_COOLDOWN

func get_fever_value() -> float:
	match enemy_type:
		EnemyType.ELITE: return GameConstants.FEVER_GAIN_ELITE
		_: return GameConstants.FEVER_GAIN_NORMAL

func _update_ai(_delta: float, _now: int) -> void:
	_update_chase_behavior(_delta, _now)

func _get_chase_strength() -> float:
	return minf(0.06 + GameManager.stage * 0.008, 0.22)

func _get_lateral_strength() -> float:
	return minf(0.02 + GameManager.stage * 0.004, 0.08) * flank_sign

func _setup_collision_shape() -> void:
	if collision_shape:
		var shape := CircleShape2D.new()
		shape.radius = radius
		collision_shape.shape = shape

func _init_burst_timer() -> void:
	var now := Time.get_ticks_msec()
	var burst_base := GameConstants.get_burst_cooldown_base(GameManager.stage)
	next_burst_at = now + burst_base + GameManager.randi() % GameConstants.BURST_COOLDOWN_VARIANCE

func _update_chase_behavior(_delta: float, now: int) -> void:

	var player := _get_player()
	if player == null:
		return

	var player_pos: Vector2 = player.global_position
	var to_player := player_pos - global_position
	var distance := to_player.length()
	var base_angle := to_player.angle()

	if enemy_type != EnemyType.MINION:
		if now >= next_burst_at:
			burst_until = now + GameConstants.BURST_DURATION
			var burst_base := GameConstants.get_burst_cooldown_base(GameManager.stage)
			next_burst_at = now + burst_base + GameManager.randi() % GameConstants.BURST_COOLDOWN_VARIANCE

	var burst_mult := GameConstants.BURST_SPEED_MULT if now < burst_until else 1.0

	var chase_strength := _get_chase_strength()
	var lateral_strength := _get_lateral_strength()
	var target_speed := base_speed * burst_mult

	var target_vx := cos(base_angle) * target_speed + cos(base_angle + PI / 2) * target_speed * lateral_strength
	var target_vy := sin(base_angle) * target_speed + sin(base_angle + PI / 2) * target_speed * lateral_strength
	var target_velocity := Vector2(target_vx, target_vy)

	velocity = velocity.lerp(target_velocity, chase_strength)

func _apply_movement(_delta: float) -> void:
	move_and_slide()

func _get_player() -> Node2D:

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _spawn_death_particles() -> void:

	pass

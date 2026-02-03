

extends CharacterBody2D
class_name Player

signal dash_started(start_pos: Vector2, end_pos: Vector2)

signal dash_ended(kills_this_dash: int)

signal dash_pending_started(target: Vector2, delay_ms: float)

signal dash_pending_progress(progress: float)

signal dash_pending_cancelled()

signal player_hit(by_enemy: Node2D)

signal player_died()

signal enemy_killed(enemy: Node2D, kills_this_dash: int)

signal enemy_hit(enemy: Node2D)

@export var player_size: float = GameConstants.PLAYER_SIZE
@export var move_speed: float = GameConstants.PLAYER_SPEED

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dash_trail: Line2D = $DashTrail if has_node("DashTrail") else null

var _dash_active: bool = false
var _dash_start_time: int = 0
var _dash_start_pos: Vector2 = Vector2.ZERO
var _dash_end_pos: Vector2 = Vector2.ZERO
var _dash_id: int = 0
var _kills_this_dash: int = 0
var _hit_stop_used: bool = false

var _dash_pending: bool = false
var _dash_pending_start: int = 0
var _dash_pending_target: Vector2 = Vector2.ZERO
var _dash_pending_delay: float = GameConstants.MIN_DASH_DELAY
var _dash_moved_this_frame: bool = false

var _trail_points: Array[Dictionary] = []

var _invuln_until: int = 0

var _snare_until: int = 0

var _hit_enemies_this_dash: Dictionary = {}

var _prev_position: Vector2 = Vector2.ZERO

func _ready() -> void:

	set_process_input(true)
	if collision_shape:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(player_size, player_size)
		collision_shape.shape = shape
	collision_layer = 0
	collision_mask = 0

	_prev_position = global_position

	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)

func _physics_process(delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return

	var now := Time.get_ticks_msec()
	_prev_position = global_position
	_dash_moved_this_frame = false

	_update_trail(delta)

	if _dash_pending and not _dash_active:
		var elapsed := now - _dash_pending_start
		var progress := minf(elapsed / _dash_pending_delay, 1.0)
		dash_pending_progress.emit(progress)

		if elapsed >= _dash_pending_delay:
			_start_dash()

	if _dash_active:
		_process_dash(now)
	else:

		_process_movement(delta, now)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameManager.current_phase == GameManager.GamePhase.MENU:
			GameManager.start_game()
			return
		if GameManager.current_phase != GameManager.GamePhase.PLAYING:
			return
		if not _dash_active and not _dash_pending:
			_start_pending_dash(get_global_mouse_position())

func get_center() -> Vector2:
	return global_position

func get_collision_radius() -> float:
	return player_size / 2.0

func is_dashing() -> bool:
	return _dash_active

func is_pending_dash() -> bool:
	return _dash_pending

func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invuln_until

func set_invulnerable(duration_ms: int) -> void:
	_invuln_until = Time.get_ticks_msec() + duration_ms

func apply_snare(duration_ms: int) -> void:
	_snare_until = maxi(_snare_until, Time.get_ticks_msec() + duration_ms)

func is_snared() -> bool:
	return Time.get_ticks_msec() < _snare_until

func knockback(direction: Vector2, distance: float) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var half_size := player_size / 2.0

	global_position += direction.normalized() * distance
	global_position.x = clampf(global_position.x, half_size, viewport_rect.size.x - half_size)
	global_position.y = clampf(global_position.y, half_size, viewport_rect.size.y - half_size)

func reset_state() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	global_position = viewport_rect.size / 2.0
	_prev_position = global_position

	_dash_active = false
	_dash_pending = false
	_dash_id = 0
	_kills_this_dash = 0
	_hit_stop_used = false
	_invuln_until = 0
	_snare_until = 0
	_hit_enemies_this_dash.clear()
	_trail_points.clear()

func get_dash_id() -> int:
	return _dash_id

func notify_enemy_killed(enemy: Node2D) -> void:
	if _dash_active:
		_kills_this_dash += 1
		enemy_killed.emit(enemy, _kills_this_dash)

func notify_enemy_hit(enemy: Node2D) -> void:
	enemy_hit.emit(enemy)

func was_enemy_hit_this_dash(enemy_id: int) -> bool:
	return _hit_enemies_this_dash.has(enemy_id)

func mark_enemy_hit_this_dash(enemy_id: int) -> void:
	_hit_enemies_this_dash[enemy_id] = true

func get_pending_progress() -> float:
	if not _dash_pending:
		return 0.0
	var elapsed := Time.get_ticks_msec() - _dash_pending_start
	return minf(elapsed / _dash_pending_delay, 1.0)

func get_pending_target() -> Vector2:
	return _dash_pending_target

func get_dash_progress() -> float:
	if not _dash_active:
		return 0.0
	var elapsed := Time.get_ticks_msec() - _dash_start_time
	return minf(float(elapsed) / GameConstants.DASH_DURATION, 1.0)

func get_trail_points() -> Array[Dictionary]:
	return _trail_points

func _process_movement(delta: float, now: int) -> void:
	var move_dir := Vector2.ZERO

	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		move_dir.y += 1
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		move_dir.x += 1

	if move_dir.length_squared() > 0:
		move_dir = move_dir.normalized()

		var speed_mult := 1.0
		if GameManager.fever_active:
			speed_mult = GameConstants.FEVER_SPEED_MULT
		if is_snared():
			speed_mult *= GameConstants.SNARE_SLOW_MULT

		var final_speed := move_speed * speed_mult
		var movement := move_dir * final_speed

		var viewport_rect := get_viewport().get_visible_rect()
		var half_size := player_size / 2.0

		global_position += movement
		global_position.x = clampf(global_position.x, half_size, viewport_rect.size.x - half_size)
		global_position.y = clampf(global_position.y, half_size, viewport_rect.size.y - half_size)

func _start_pending_dash(target: Vector2) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var max_distance := viewport_rect.size.length()

	var dx := target.x - global_position.x
	var dy := target.y - global_position.y
	var distance := Vector2(dx, dy).length()
	var ratio := minf(distance / max_distance, 1.0)

	var base_delay := GameConstants.MIN_DASH_DELAY + (GameConstants.MAX_DASH_DELAY - GameConstants.MIN_DASH_DELAY) * ratio

	var delay_mult := 1.0
	if GameManager.fever_active:
		delay_mult *= GameConstants.FEVER_DASH_DELAY_MULT
	if is_snared():
		delay_mult *= GameConstants.SNARE_DASH_DELAY_MULT

	_dash_pending = true
	_dash_pending_start = Time.get_ticks_msec()
	_dash_pending_target = target
	_dash_pending_delay = base_delay * delay_mult
	_kills_this_dash = 0

	dash_pending_started.emit(target, _dash_pending_delay)

func _start_dash() -> void:
	_dash_active = true
	_dash_pending = false
	_dash_start_time = Time.get_ticks_msec()
	_dash_start_pos = global_position
	_dash_end_pos = _dash_pending_target
	_dash_id += 1
	_kills_this_dash = 0
	_hit_stop_used = false
	_hit_enemies_this_dash.clear()
	_trail_points.clear()

	dash_started.emit(_dash_start_pos, _dash_end_pos)

	AudioManager.play_dash()

func _process_dash(now: int) -> void:
	var elapsed := now - _dash_start_time
	var progress := minf(float(elapsed) / GameConstants.DASH_DURATION, 1.0)

	var new_pos := _dash_start_pos.lerp(_dash_end_pos, progress)
	_dash_moved_this_frame = true

	_trail_points.append({
		"position": new_pos,
		"life": 1.0
	})

	global_position = new_pos

	if progress >= 1.0:
		_dash_active = false
		dash_ended.emit(_kills_this_dash)

func _update_trail(delta: float) -> void:
	var decay_rate := 0.03 / delta * (1.0 / 60.0)

	for i in range(_trail_points.size() - 1, -1, -1):
		_trail_points[i]["life"] -= decay_rate * delta
		if _trail_points[i]["life"] <= 0:
			_trail_points.remove_at(i)

func check_line_circle_collision(line_start: Vector2, line_end: Vector2, circle_center: Vector2, circle_radius: float) -> bool:
	var dx := line_end.x - line_start.x
	var dy := line_end.y - line_start.y
	var len_sq := dx * dx + dy * dy

	if len_sq == 0:
		return line_start.distance_to(circle_center) <= circle_radius

	var t := ((circle_center.x - line_start.x) * dx + (circle_center.y - line_start.y) * dy) / len_sq
	t = clampf(t, 0.0, 1.0)

	var closest := Vector2(line_start.x + t * dx, line_start.y + t * dy)
	return closest.distance_to(circle_center) <= circle_radius

func get_previous_position() -> Vector2:
	return _prev_position

func did_dash_this_frame() -> bool:
	return _dash_moved_this_frame

func _on_game_started(_seed: String) -> void:
	reset_state()

func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:

		if _dash_pending:
			_dash_pending = false
			dash_pending_cancelled.emit()
		_dash_active = false

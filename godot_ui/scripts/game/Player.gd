## Player.gd
## 鐜╁鎺у埗鍣?## 璐熻矗鐜╁绉诲姩銆佸啿鍒恒€佺鎾炴娴
##
## 浣跨敤鏂瑰紡锛
## 1. 鍒涘缓 CharacterBody2D 鑺傜偣
## 2. 闄勫姞姝よ剼鏈
## 3. 娣诲姞 CollisionShape2D 瀛愯妭鐐?
extends CharacterBody2D
class_name Player

# ============================================================
# 淇″彿
# ============================================================

## 鍐插埡寮€濮
signal dash_started(start_pos: Vector2, end_pos: Vector2)

## 鍐插埡缁撴潫
signal dash_ended(kills_this_dash: int)

## 鍐插埡钃勫姏寮€濮
signal dash_pending_started(target: Vector2, delay_ms: float)

## 鍐插埡钃勫姏鏇存柊
signal dash_pending_progress(progress: float)

## 鍐插埡钃勫姏鍙栨秷
signal dash_pending_cancelled()

## 鐜╁琚嚮涓紙闈㈠叿鐮寸锛
signal player_hit(by_enemy: Node2D)

## 鐜╁姝讳骸
signal player_died()

## 鍑绘潃鏁屼汉
signal enemy_killed(enemy: Node2D, kills_this_dash: int)

## 鍑讳腑鏁屼汉锛堟湭鍑绘潃锛
signal enemy_hit(enemy: Node2D)

# ============================================================
# 瀵煎嚭鍙橀噺
# ============================================================

@export var player_size: float = GameConstants.PLAYER_SIZE
@export var move_speed: float = GameConstants.PLAYER_SPEED

# ============================================================
# 鑺傜偣寮曠敤
# ============================================================

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dash_trail: Line2D = $DashTrail if has_node("DashTrail") else null

# ============================================================
# 鍐呴儴鐘舵€
# ============================================================

## 鍐插埡鐘舵€
var _dash_active: bool = false
var _dash_start_time: int = 0
var _dash_start_pos: Vector2 = Vector2.ZERO
var _dash_end_pos: Vector2 = Vector2.ZERO
var _dash_id: int = 0
var _kills_this_dash: int = 0
var _hit_stop_used: bool = false

## 钃勫姏鐘舵€
var _dash_pending: bool = false
var _dash_pending_start: int = 0
var _dash_pending_target: Vector2 = Vector2.ZERO
var _dash_pending_delay: float = GameConstants.MIN_DASH_DELAY

## 鍐插埡杞ㄨ抗
var _trail_points: Array[Dictionary] = []  # {position: Vector2, life: float}

## 鏃犳晫鐘舵€
var _invuln_until: int = 0

## 鏉熺細鍑忛€熺姸鎬
var _snare_until: int = 0

## 宸插嚮涓殑鏁屼汉锛堝綋鍓嶅啿鍒猴級
var _hit_enemies_this_dash: Dictionary = {}  # enemy_id -> bool

## 涓婁竴甯т綅缃紙鐢ㄤ簬绾挎纰版挒妫€娴嬶級
var _prev_position: Vector2 = Vector2.ZERO

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 璁剧疆纰版挒褰㈢姸
	if collision_shape:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(player_size, player_size)
		collision_shape.shape = shape
	
	_prev_position = global_position
	
	# 杩炴帴 GameManager 淇″彿
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)


func _physics_process(delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	var now := Time.get_ticks_msec()
	
	# 妫€鏌
	hit stop
	# (hit stop 鍦
	ComboSystem 涓鐞嗭紝杩欓噷璺宠繃绉诲姩)
	
	# 鏇存柊杞ㄨ抗
	_update_trail(delta)
	
	# 澶勭悊钃勫姏鍐插埡
	if _dash_pending and not _dash_active:
		var elapsed := now - _dash_pending_start
		var progress := minf(elapsed / _dash_pending_delay, 1.0)
		dash_pending_progress.emit(progress)
		
		if elapsed >= _dash_pending_delay:
			_start_dash()
	
	# 澶勭悊娲昏穬鍐插埡
	if _dash_active:
		_process_dash(now)
	else:
		# WASD 绉诲姩
		_process_movement(delta, now)
	
	_prev_position = global_position


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	# 榧犳爣鐐瑰嚮寮€濮嬭搫鍔
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not _dash_active and not _dash_pending:
				_start_pending_dash(get_global_mouse_position())


				# ============================================================
				# 鍏叡鏂规硶
				# ============================================================

## 鑾峰彇鐜╁涓績浣嶇疆
func get_center() -> Vector2:
	return global_position


## 鑾峰彇鐜╁纰版挒鍗婂緞
func get_collision_radius() -> float:
	return player_size / 2.0


## 鏄惁姝ｅ湪鍐插埡
func is_dashing() -> bool:
	return _dash_active


## 鏄惁姝ｅ湪钃勫姏
func is_pending_dash() -> bool:
	return _dash_pending


## 鏄惁鏃犳晫
func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invuln_until


## 璁剧疆鏃犳晫鏃堕棿
func set_invulnerable(duration_ms: int) -> void:
	_invuln_until = Time.get_ticks_msec() + duration_ms


## 搴旂敤鏉熺細鍑忛€
func apply_snare(duration_ms: int) -> void:
	_snare_until = maxi(_snare_until, Time.get_ticks_msec() + duration_ms)


## 鏄惁琚潫缂
func is_snared() -> bool:
	return Time.get_ticks_msec() < _snare_until


## 鍑婚€€鐜╁
func knockback(direction: Vector2, distance: float) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var half_size := player_size / 2.0
	
	global_position += direction.normalized() * distance
	global_position.x = clampf(global_position.x, half_size, viewport_rect.size.x - half_size)
	global_position.y = clampf(global_position.y, half_size, viewport_rect.size.y - half_size)


## 閲嶇疆鐜╁鐘舵€侊紙鏂版父鎴忔椂锛
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


## 鑾峰彇褰撳墠鍐插埡 ID
func get_dash_id() -> int:
	return _dash_id


## 閫氱煡鍑绘潃鏁屼汉
func notify_enemy_killed(enemy: Node2D) -> void:
	if _dash_active:
		_kills_this_dash += 1
		enemy_killed.emit(enemy, _kills_this_dash)


## 閫氱煡鍑讳腑鏁屼汉
func notify_enemy_hit(enemy: Node2D) -> void:
	enemy_hit.emit(enemy)


## 妫€鏌ユ晫浜烘槸鍚﹀凡琚湰娆″啿鍒哄嚮涓
func was_enemy_hit_this_dash(enemy_id: int) -> bool:
	return _hit_enemies_this_dash.has(enemy_id)


## 鏍囪鏁屼汉宸茶鏈鍐插埡鍑讳腑
func mark_enemy_hit_this_dash(enemy_id: int) -> void:
	_hit_enemies_this_dash[enemy_id] = true


## 鑾峰彇钃勫姏杩涘害 (0-1)
func get_pending_progress() -> float:
	if not _dash_pending:
		return 0.0
	var elapsed := Time.get_ticks_msec() - _dash_pending_start
	return minf(elapsed / _dash_pending_delay, 1.0)


## 鑾峰彇钃勫姏鐩爣浣嶇疆
func get_pending_target() -> Vector2:
	return _dash_pending_target


## 鑾峰彇鍐插埡杩涘害 (0-1)
func get_dash_progress() -> float:
	if not _dash_active:
		return 0.0
	var elapsed := Time.get_ticks_msec() - _dash_start_time
	return minf(float(elapsed) / GameConstants.DASH_DURATION, 1.0)


## 鑾峰彇杞ㄨ抗鐐癸紙鐢ㄤ簬娓叉煋锛
func get_trail_points() -> Array[Dictionary]:
	return _trail_points


	# ============================================================
	# 绉佹湁鏂规硶 - 绉诲姩
	# ============================================================

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
		
		# 璁＄畻閫熷害鍊嶇巼
		var speed_mult := 1.0
		if GameManager.fever_active:
			speed_mult = GameConstants.FEVER_SPEED_MULT
		if is_snared():
			speed_mult *= GameConstants.SNARE_SLOW_MULT
		
		var final_speed := move_speed * speed_mult
		var movement := move_dir * final_speed
		
		# 闄愬埗鍦ㄨ鍙ｅ唴
		var viewport_rect := get_viewport().get_visible_rect()
		var half_size := player_size / 2.0
		
		global_position += movement
		global_position.x = clampf(global_position.x, half_size, viewport_rect.size.x - half_size)
		global_position.y = clampf(global_position.y, half_size, viewport_rect.size.y - half_size)


		# ============================================================
		# 绉佹湁鏂规硶 - 鍐插埡
		# ============================================================

func _start_pending_dash(target: Vector2) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var max_distance := viewport_rect.size.length()
	
	var dx := target.x - global_position.x
	var dy := target.y - global_position.y
	var distance := Vector2(dx, dy).length()
	var ratio := minf(distance / max_distance, 1.0)
	
	var base_delay := GameConstants.MIN_DASH_DELAY + (GameConstants.MAX_DASH_DELAY - GameConstants.MIN_DASH_DELAY) * ratio
	
	# 搴旂敤 Fever 鍜
	# Snare 鍊嶇巼
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
	
	# 鎾斁鍐插埡闊虫晥
	AudioManager.play_dash()


func _process_dash(now: int) -> void:
	var elapsed := now - _dash_start_time
	var progress := minf(float(elapsed) / GameConstants.DASH_DURATION, 1.0)
	
	# 鎻掑€间綅缃
	var new_pos := _dash_start_pos.lerp(_dash_end_pos, progress)
	
	# 娣诲姞杞ㄨ抗鐐
	_trail_points.append({
		"position": new_pos,
		"life": 1.0
	})
	
	global_position = new_pos
	
	# 鍐插埡缁撴潫
	if progress >= 1.0:
		_dash_active = false
		dash_ended.emit(_kills_this_dash)


func _update_trail(delta: float) -> void:
	var decay_rate := 0.03 / delta * (1.0 / 60.0)  # 鏍囧噯鍖栧埌 60fps
	
	for i in range(_trail_points.size() - 1, -1, -1):
		_trail_points[i]["life"] -= decay_rate * delta
		if _trail_points[i]["life"] <= 0:
			_trail_points.remove_at(i)


			# ============================================================
			# 纰版挒妫€娴嬭緟鍔
			# ============================================================

## 妫€鏌ョ嚎娈典笌鍦嗙殑纰版挒锛堢敤浜庡啿鍒虹鎾炴娴嬶級
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


## 鑾峰彇涓婁竴甯т綅缃紙鐢ㄤ簬鍐插埡纰版挒锛
func get_previous_position() -> Vector2:
	return _prev_position


	# ============================================================
	# 淇″彿鍥炶皟
	# ============================================================

func _on_game_started(_seed: String) -> void:
	reset_state()


func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		# 鍙栨秷鎵€鏈夊啿鍒虹姸鎬
		if _dash_pending:
			_dash_pending = false
			dash_pending_cancelled.emit()
		_dash_active = false




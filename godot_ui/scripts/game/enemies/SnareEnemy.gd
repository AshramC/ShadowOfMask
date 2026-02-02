## SnareEnemy.gd
## 鏉熺細鏁屼汉
## 杩借釜鐜╁锛屽湪鑼冨洿鍐呴噴鏀鹃攣閾惧噺閫熺帺瀹?
extends EnemyBase
class_name SnareEnemy

# ============================================================
# 鏋氫妇
# ============================================================

enum SnareState {
	SEEK,     ## 瀵绘壘鐩爣
	WINDUP,   ## 钃勫姏
	FIRE,     ## 閲婃斁閿侀摼
	RECOVER   ## Recovering   ## 鎭㈠
}

# ============================================================
# 淇″彿
# ============================================================

## 寮€濮嬭搫鍔
signal windup_started(direction: Vector2)

## 閲婃斁閿侀摼
signal chain_fired(start_pos: Vector2, end_pos: Vector2, hit_player: bool)

# ============================================================
# 鐘舵€
# ============================================================

var current_state: SnareState = SnareState.SEEK
var state_until: int = 0
var snare_direction: Vector2 = Vector2.ZERO

# ============================================================
# 鍒濆鍖
# ============================================================

func _ready() -> void:
	enemy_type = EnemyType.SNARE
	radius = GameConstants.SNARE_RADIUS
	max_hp = GameConstants.SNARE_MAX_HP
	speed_multiplier = GameConstants.SNARE_SPEED_MULT
	
	super._ready()
	
	# 鍒濆鍖栫姸鎬佽鏃跺櫒
	state_until = Time.get_ticks_msec() + GameManager.randi() % 500


	# ============================================================
	# AI 琛屼负
	# ============================================================

func _update_ai(_delta: float, now: int) -> void:
	var player := _get_player()
	if player == null:
		return
	
	var player_pos: Vector2 = player.global_position
	var to_player := player_pos - global_position
	var distance := to_player.length()
	var base_angle := to_player.angle()
	
	match current_state:
		SnareState.SEEK:
			_update_seek(now, to_player, distance, base_angle)
		SnareState.WINDUP:
			_update_windup(now, player, to_player, distance)
		SnareState.FIRE:
			_update_fire(now)
		SnareState.RECOVER:
			_update_recover(now)


func _update_seek(now: int, to_player: Vector2, distance: float, base_angle: float) -> void:
	var chase_strength := 0.07
	var lateral_strength := 0.03 * flank_sign
	
	var target_vx := cos(base_angle) * base_speed + cos(base_angle + PI / 2) * base_speed * lateral_strength
	var target_vy := sin(base_angle) * base_speed + sin(base_angle + PI / 2) * base_speed * lateral_strength
	var target_velocity := Vector2(target_vx, target_vy)
	
	velocity = velocity.lerp(target_velocity, chase_strength)
	
	# 妫€鏌ユ槸鍚﹁繘鍏ユ敾鍑昏寖鍥
	if distance < GameConstants.SNARE_RANGE and now >= state_until:
		_enter_windup(to_player, distance)


func _update_windup(now: int, player: Node2D, to_player: Vector2, distance: float) -> void:
	velocity *= 0.5
	
	if now >= state_until:
		_fire_chain(player, to_player, distance)


func _update_fire(now: int) -> void:
	velocity *= 0.7
	
	if now >= state_until:
		_enter_recover()


func _update_recover(now: int) -> void:
	velocity *= 0.85
	
	if now >= state_until:
		_enter_seek()


		# ============================================================
		# 鐘舵€佽浆鎹
		# ============================================================

func _enter_windup(to_player: Vector2, distance: float) -> void:
	current_state = SnareState.WINDUP
	state_until = Time.get_ticks_msec() + GameConstants.SNARE_WINDUP_MS
	
	var len := distance if distance > 0 else 1.0
	snare_direction = to_player / len
	
	windup_started.emit(snare_direction)


func _fire_chain(player: Node2D, to_player: Vector2, distance: float) -> void:
	var chain_end := global_position + snare_direction * GameConstants.SNARE_RANGE
	
	# 妫€鏌ユ槸鍚﹀懡涓帺瀹
	var hit_player := false
	
	# 璁＄畻鐜╁鏄惁鍦ㄩ攣閾捐寖鍥村唴
	var dot := to_player.dot(snare_direction)
	var in_range := dot >= 0 and dot <= GameConstants.SNARE_RANGE
	
	if in_range:
		var line_distance := _distance_point_to_segment(global_position, chain_end, player.global_position)
		var player_radius: float = player.get_collision_radius() if player.has_method("get_collision_radius") else GameConstants.PLAYER_SIZE / 2.0
		
		# 妫€鏌ョ帺瀹舵槸鍚︽鍦ㄥ啿鍒
		var player_dashing: bool = player.is_dashing() if player.has_method("is_dashing") else false
		
		if not player_dashing and line_distance <= GameConstants.SNARE_CHAIN_WIDTH + player_radius:
			hit_player = true
			# 搴旂敤鍑忛€
			if player.has_method("apply_snare"):
				player.apply_snare(GameConstants.SNARE_SLOW_MS)
	
	chain_fired.emit(global_position, chain_end, hit_player)
	
	current_state = SnareState.FIRE
	state_until = Time.get_ticks_msec() + GameConstants.SNARE_FIRE_MS


func _enter_recover() -> void:
	current_state = SnareState.RECOVER
	state_until = Time.get_ticks_msec() + GameConstants.SNARE_RECOVER_MS


func _enter_seek() -> void:
	current_state = SnareState.SEEK
	state_until = Time.get_ticks_msec() + GameConstants.SNARE_COOLDOWN_MS


	# ============================================================
	# 杈呭姪鏂规硶
	# ============================================================

func _distance_point_to_segment(seg_start: Vector2, seg_end: Vector2, point: Vector2) -> float:
	var dx := seg_end.x - seg_start.x
	var dy := seg_end.y - seg_start.y
	var len_sq := dx * dx + dy * dy
	
	if len_sq == 0:
		return seg_start.distance_to(point)
	
	var t := ((point.x - seg_start.x) * dx + (point.y - seg_start.y) * dy) / len_sq
	t = clampf(t, 0.0, 1.0)
	
	var closest := Vector2(seg_start.x + t * dx, seg_start.y + t * dy)
	return closest.distance_to(point)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鑾峰彇褰撳墠鐘舵€佸悕绉
func get_state_name() -> String:
	match current_state:
		SnareState.SEEK: return "seek"
		SnareState.WINDUP: return "windup"
		SnareState.FIRE: return "fire"
		SnareState.RECOVER: return "recover"
	return "unknown"


## 鏄惁姝ｅ湪閲婃斁閿侀摼
func is_firing() -> bool:
	return current_state == SnareState.FIRE


## 鏄惁姝ｅ湪钃勫姏
func is_winding_up() -> bool:
	return current_state == SnareState.WINDUP


## 鑾峰彇閿侀摼鏂瑰悜
func get_snare_direction() -> Vector2:
	return snare_direction


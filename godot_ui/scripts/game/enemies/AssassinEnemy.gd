## AssassinEnemy.gd
## 鍒哄鏁屼汉
## 闅愯韩鎺ヨ繎锛岃搫鍔涘悗绐佽繘鏀诲嚮锛屽彲浼犻€?
extends EnemyBase
class_name AssassinEnemy

# ============================================================
# 鏋氫妇
# ============================================================

enum AssassinState {
	APPROACH,
	WINDUP,
	DASH,
	RECOVER
}

# ============================================================
# 淇″彿
# ============================================================

## 寮€濮嬭搫鍔
signal windup_started(direction: Vector2)

## 寮€濮嬬獊杩
signal dash_started(direction: Vector2)

## 浼犻€
signal teleported(new_position: Vector2)

# ============================================================
# 鐘舵€
# ============================================================

var current_state: AssassinState = AssassinState.APPROACH
var state_until: int = 0
var dash_direction: Vector2 = Vector2.ZERO
var last_attack_at: int = 0
var next_teleport_at: int = 0

# ============================================================
# 鍒濆鍖
# ============================================================

func _ready() -> void:
	enemy_type = EnemyType.ASSASSIN
	radius = GameConstants.ASSASSIN_RADIUS
	max_hp = 1
	speed_multiplier = GameConstants.ASSASSIN_SPEED_MULT
	
	super._ready()
	
	# 鍒濆鍖栦紶閫佽鏃跺櫒
	var now := Time.get_ticks_msec()
	next_teleport_at = now + int(GameConstants.ASSASSIN_TELEPORT_COOLDOWN_MS * (0.7 + GameManager.randf() * 0.6))
	state_until = now + GameManager.randi() % 400


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
		AssassinState.APPROACH:
			_update_approach(now, to_player, distance, base_angle)
		AssassinState.WINDUP:
			_update_windup(now, to_player, distance)
		AssassinState.DASH:
			_update_dash(now)
		AssassinState.RECOVER:
			_update_recover(now, distance, player_pos)


func _update_approach(now: int, to_player: Vector2, distance: float, base_angle: float) -> void:
	var chase_strength := 0.08
	var lateral_strength := 0.04 * flank_sign
	
	var target_vx := cos(base_angle) * base_speed + cos(base_angle + PI / 2) * base_speed * lateral_strength
	var target_vy := sin(base_angle) * base_speed + sin(base_angle + PI / 2) * base_speed * lateral_strength
	var target_velocity := Vector2(target_vx, target_vy)
	
	velocity = velocity.lerp(target_velocity, chase_strength)
	
	# 妫€鏌ユ槸鍚﹁繘鍏ユ敾鍑昏寖鍥
	if distance < GameConstants.ASSASSIN_TRIGGER_RANGE and now >= state_until:
		_enter_windup(to_player, distance)


func _update_windup(now: int, to_player: Vector2, distance: float) -> void:
	# 鍑忛€
	velocity *= 0.5
	
	if now >= state_until:
		# 鏇存柊绐佽繘鏂瑰悜锛堢瀯鍑嗗綋鍓嶇帺瀹朵綅缃級
		var len := distance if distance > 0 else 1.0
		dash_direction = to_player / len
		_enter_dash()


func _update_dash(now: int) -> void:
	# 楂橀€熺獊杩
	velocity = dash_direction * base_speed * GameConstants.ASSASSIN_DASH_SPEED_MULT
	
	if now >= state_until:
		_enter_recover()


func _update_recover(now: int, distance: float, player_pos: Vector2) -> void:
	# 鍑忛€熸仮澶
	velocity *= 0.85
	
	if now >= state_until:
		# 妫€鏌ユ槸鍚﹂渶瑕佷紶閫
		var should_teleport := (
			last_attack_at > 0 and
			now >= next_teleport_at and
			distance > GameConstants.ASSASSIN_TELEPORT_TRIGGER_DISTANCE
		)
		
		if should_teleport:
			_perform_teleport(player_pos)
		else:
			_enter_approach()


			# ============================================================
			# 鐘舵€佽浆鎹
			# ============================================================

func _enter_windup(to_player: Vector2, distance: float) -> void:
	current_state = AssassinState.WINDUP
	state_until = Time.get_ticks_msec() + GameConstants.ASSASSIN_WINDUP_MS
	
	var len := distance if distance > 0 else 1.0
	dash_direction = to_player / len
	
	windup_started.emit(dash_direction)


func _enter_dash() -> void:
	current_state = AssassinState.DASH
	state_until = Time.get_ticks_msec() + GameConstants.ASSASSIN_DASH_MS
	
	dash_started.emit(dash_direction)


func _enter_recover() -> void:
	current_state = AssassinState.RECOVER
	state_until = Time.get_ticks_msec() + GameConstants.ASSASSIN_RECOVER_MS
	last_attack_at = Time.get_ticks_msec()


func _enter_approach() -> void:
	current_state = AssassinState.APPROACH
	state_until = Time.get_ticks_msec() + GameConstants.ASSASSIN_COOLDOWN_MS


func _perform_teleport(player_pos: Vector2) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var teleport_angle: float = GameManager.randf() * TAU
	var teleport_radius: float = GameConstants.ASSASSIN_TELEPORT_MIN_RADIUS + \
		GameManager.randf() * (GameConstants.ASSASSIN_TELEPORT_MAX_RADIUS - GameConstants.ASSASSIN_TELEPORT_MIN_RADIUS)
	
	var target_x: float = player_pos.x + cos(teleport_angle) * teleport_radius
	var target_y: float = player_pos.y + sin(teleport_angle) * teleport_radius
	
	global_position.x = clampf(target_x, radius, viewport_rect.size.x - radius)
	global_position.y = clampf(target_y, radius, viewport_rect.size.y - radius)
	
	velocity = Vector2.ZERO
	
	# 绔嬪嵆鍑嗗涓嬩竴娆℃敾鍑
	var to_player := player_pos - global_position
	var distance := to_player.length()
	var len := distance if distance > 0 else 1.0
	dash_direction = to_player / len
	
	current_state = AssassinState.WINDUP
	state_until = Time.get_ticks_msec() + GameConstants.ASSASSIN_WINDUP_MS
	next_teleport_at = Time.get_ticks_msec() + GameConstants.ASSASSIN_TELEPORT_COOLDOWN_MS
	
	teleported.emit(global_position)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鑾峰彇褰撳墠閫忔槑搴
func get_alpha() -> float:
	match current_state:
		AssassinState.APPROACH:
			return GameConstants.ASSASSIN_ALPHA_STEALTH
		AssassinState.RECOVER:
			return 0.7
		_:
			return GameConstants.ASSASSIN_ALPHA_ACTIVE


## 鑾峰彇褰撳墠鐘舵€佸悕绉
func get_state_name() -> String:
	match current_state:
		AssassinState.APPROACH: return "approach"
		AssassinState.WINDUP: return "windup"
		AssassinState.DASH: return "dash"
		AssassinState.RECOVER: return "recover"
	return "unknown"


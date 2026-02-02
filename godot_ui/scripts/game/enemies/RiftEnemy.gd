## RiftEnemy.gd
## 瑁傞殭鏁屼汉
## 绉诲姩缂撴參锛屽懆鏈熸€у湪鐜╁闄勮繎鍙敜瑁傞殭闂紝瑁傞殭闂ㄤ細鎸佺画鐢熸垚灏忔€?
extends EnemyBase
class_name RiftEnemy

# ============================================================
# 淇″彿
# ============================================================

## 鍙敜瑁傞殭
signal rift_spawned(position: Vector2)

# ============================================================
# 鐘舵€
# ============================================================

var next_rift_at: int = 0

# ============================================================
# 鍒濆鍖
# ============================================================

func _ready() -> void:
	enemy_type = EnemyType.RIFT
	radius = GameConstants.RIFT_RADIUS
	max_hp = GameConstants.RIFT_MAX_HP
	speed_multiplier = GameConstants.RIFT_SPEED_MULT
	
	super._ready()
	
	# 鍒濆鍖栬闅欏彫鍞よ鏃跺櫒
	var now := Time.get_ticks_msec()
	next_rift_at = now + int(GameConstants.RIFT_CAST_COOLDOWN_MS * (0.7 + GameManager.randf() * 0.6))


	# ============================================================
	# AI 琛屼负
	# ============================================================

func _update_ai(_delta: float, now: int) -> void:
	var player := _get_player()
	if player == null:
		return
	
	var player_pos: Vector2 = player.global_position
	var to_player := player_pos - global_position
	var base_angle := to_player.angle()
	
	# 缂撴參杩借釜
	var chase_strength := 0.05
	var lateral_strength := 0.02 * flank_sign
	
	var target_vx := cos(base_angle) * base_speed + cos(base_angle + PI / 2) * base_speed * lateral_strength
	var target_vy := sin(base_angle) * base_speed + sin(base_angle + PI / 2) * base_speed * lateral_strength
	var target_velocity := Vector2(target_vx, target_vy)
	
	velocity = velocity.lerp(target_velocity, chase_strength)
	
	# 妫€鏌ユ槸鍚﹀彲浠ュ彫鍞よ闅
	if now >= next_rift_at:
		_spawn_rift(player_pos)
		next_rift_at = now + GameConstants.RIFT_CAST_COOLDOWN_MS


func _spawn_rift(player_pos: Vector2) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var angle: float = GameManager.randf() * TAU
	var rift_radius: float = GameConstants.RIFT_SPAWN_MIN_RADIUS + \
		GameManager.randf() * (GameConstants.RIFT_SPAWN_MAX_RADIUS - GameConstants.RIFT_SPAWN_MIN_RADIUS)
	
	var target_x: float = player_pos.x + cos(angle) * rift_radius
	var target_y: float = player_pos.y + sin(angle) * rift_radius
	
	var spawn_pos := Vector2(
		clampf(target_x, GameConstants.RIFT_RADIUS, viewport_rect.size.x - GameConstants.RIFT_RADIUS),
		clampf(target_y, GameConstants.RIFT_RADIUS, viewport_rect.size.y - GameConstants.RIFT_RADIUS)
	)
	
	rift_spawned.emit(spawn_pos)


	# ============================================================
	# 閲嶅啓鏂规硶
	# ============================================================

func _get_chase_strength() -> float:
	return 0.05


func _get_lateral_strength() -> float:
	return 0.02 * flank_sign


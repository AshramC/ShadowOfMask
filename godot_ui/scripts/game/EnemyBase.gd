## EnemyBase.gd
## 鏁屼汉鍩虹被
## 鎵€鏈夋晫浜虹被鍨嬬殑鐖剁被锛屽畾涔夐€氱敤灞炴€у拰琛屼负
##
## 鏁屼汉绫诲瀷锛?## - normal: 鏅€氭晫浜
## - elite: 绮捐嫳鏁屼汉 (楂樿閲忥紝鍑婚€€鐜╁)
## - assassin: 鍒哄鏁屼汉 (闅愯韩锛岀獊杩?
## - rift: 瑁傞殭鏁屼汉 (鍙敜灏忔€?
## - snare: 鏉熺細鏁屼汉 (鍑忛€熺帺瀹?
## - minion: 灏忔€
# (琚闅欏彫鍞?

extends CharacterBody2D
class_name EnemyBase

# ============================================================
# 鏋氫妇
# ============================================================

enum EnemyType {
	NORMAL,
	ELITE,
	ASSASSIN,
	RIFT,
	SNARE,
	MINION
}

# ============================================================
# 淇″彿
# ============================================================

## 鏁屼汉琚嚮涓
signal hit(damage: int, by_player: bool)

## 鏁屼汉姝讳骸
signal died(enemy: EnemyBase)

## 鏁屼汉鐢熸垚瀹屾垚锛堝欢杩熺敓鎴愬悗锛
signal spawned()

## 鏁屼汉鎺ヨЕ鐜╁
signal contacted_player(player: Node2D)

# ============================================================
# 瀵煎嚭鍙橀噺
# ============================================================

@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var radius: float = GameConstants.ENEMY_RADIUS
@export var max_hp: int = 1
@export var speed_multiplier: float = 1.0

# ============================================================
# 鑺傜偣寮曠敤
# ============================================================

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ============================================================
# 鍐呴儴鐘舵€
# ============================================================

## 褰撳墠鐢熷懡鍊
var hp: int = 1

## 鍩虹閫熷害
var base_speed: float = 0.0

## 褰撳墠閫熷害
var current_speed: float = 0.0

## 閫熷害鍚戦噺
var velocity_dir: Vector2 = Vector2.ZERO

## 鏄惁宸茬敓鎴愶紙寤惰繜鐢熸垚瀹屾垚锛
var is_spawned: bool = false

## 寤惰繜鐢熸垚鏃堕棿鐐
var spawn_at: int = 0

## 渚у悜绉诲姩鏍囪 (-1 鎴
var flank_sign: int = 1

## 鎵€灞炴尝娆
var wave_id: int = 0

## Burst 绐佽繘鐩稿叧
var next_burst_at: int = 0
var burst_until: int = 0

## 琚摢涓啿鍒哄嚮涓繃
var last_hit_dash_id: int = -1

## 绮捐嫳鎺ヨЕ鍐峰嵈
var contact_cooldown_until: int = 0

## 鏄惁婵€娲
var is_active: bool = true

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 璁剧疆纰版挒褰㈢姸
	_setup_collision_shape()
	
	# 鍒濆鍖栫敓鍛藉€
	hp = max_hp
	
	# 璁＄畻鍩虹閫熷害
	base_speed = GameConstants.get_enemy_base_speed(GameManager.stage) * speed_multiplier
	current_speed = base_speed
	
	# 闅忔満渚у悜绉诲姩鏂瑰悜
	flank_sign = 1 if GameManager.randf() > 0.5 else -1
	
	# 鍒濆鍖
	# Burst 璁℃椂鍣
	_init_burst_timer()


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	var now := Time.get_ticks_msec()
	
	# 妫€鏌ュ欢杩熺敓鎴
	if not is_spawned:
		if now >= spawn_at:
			is_spawned = true
			is_active = true
			spawned.emit()
		else:
			return
	
	# 鏇存柊 AI 琛屼负
	_update_ai(delta, now)
	
	# 搴旂敤绉诲姩
	_apply_movement(delta)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鍒濆鍖栨晫浜
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


## 鍙楀埌浼ゅ
func take_damage(damage: int, dash_id: int = -1) -> bool:
	if not is_active:
		return false
	
	# 妫€鏌ユ槸鍚﹀凡琚悓涓€鍐插埡鍑讳腑
	if dash_id >= 0 and dash_id == last_hit_dash_id:
		return false
	
	last_hit_dash_id = dash_id
	hp -= damage
	hit.emit(damage, true)
	
	if hp <= 0:
		die()
		return true
	
	return false


## 鏁屼汉姝讳骸
func die() -> void:
	is_active = false
	died.emit(self)
	
	# 鐢熸垚绮掑瓙鏁堟灉
	_spawn_death_particles()
	
	# 寤惰繜閿€姣
	queue_free()


## 鑾峰彇鏁屼汉绫诲瀷鍚嶇О
func get_type_name() -> String:
	match enemy_type:
		EnemyType.NORMAL: return "normal"
		EnemyType.ELITE: return "elite"
		EnemyType.ASSASSIN: return "assassin"
		EnemyType.RIFT: return "rift"
		EnemyType.SNARE: return "snare"
		EnemyType.MINION: return "minion"
	return "unknown"


## 鑾峰彇鏁屼汉棰滆壊
func get_color() -> Color:
	match enemy_type:
		EnemyType.NORMAL: return GameConstants.COLOR_NORMAL_ENEMY
		EnemyType.ELITE: return GameConstants.COLOR_ELITE_ENEMY
		EnemyType.MINION: return GameConstants.COLOR_MINION_ENEMY
		EnemyType.ASSASSIN: return GameConstants.ASSASSIN_COLOR
		EnemyType.RIFT: return GameConstants.RIFT_COLOR
		EnemyType.SNARE: return GameConstants.SNARE_COLOR
	return Color.RED


## 妫€鏌ユ槸鍚﹀彲浠ユ帴瑙︾帺瀹讹紙绮捐嫳鍐峰嵈锛
func can_contact_player() -> bool:
	if enemy_type == EnemyType.ELITE:
		return Time.get_ticks_msec() >= contact_cooldown_until
	return true


## 璁剧疆鎺ヨЕ鍐峰嵈锛堢簿鑻辨晫浜猴級
func set_contact_cooldown() -> void:
	if enemy_type == EnemyType.ELITE:
		contact_cooldown_until = Time.get_ticks_msec() + GameConstants.ELITE_CONTACT_COOLDOWN


## 鑾峰彇 Fever 鑳介噺鍊
func get_fever_value() -> float:
	match enemy_type:
		EnemyType.ELITE: return GameConstants.FEVER_GAIN_ELITE
		_: return GameConstants.FEVER_GAIN_NORMAL


		# ============================================================
		# 铏氭柟娉
		# - 瀛愮被閲嶅啓
		# ============================================================

## 鏇存柊 AI 琛屼负锛堝瓙绫婚噸鍐欙級
func _update_ai(_delta: float, _now: int) -> void:
	_update_chase_behavior(_delta, _now)


## 鑾峰彇杩借釜寮哄害锛堝瓙绫诲彲閲嶅啓锛
func _get_chase_strength() -> float:
	return minf(0.06 + GameManager.stage * 0.008, 0.22)


## 鑾峰彇渚у悜寮哄害锛堝瓙绫诲彲閲嶅啓锛
func _get_lateral_strength() -> float:
	return minf(0.02 + GameManager.stage * 0.004, 0.08) * flank_sign


	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

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
	# 鑾峰彇鐜╁浣嶇疆
	var player := _get_player()
	if player == null:
		return
	
	var player_pos: Vector2 = player.global_position
	var to_player := player_pos - global_position
	var distance := to_player.length()
	var base_angle := to_player.angle()
	
	# 妫€鏌
	# Burst 鐘舵€
	if enemy_type != EnemyType.MINION:
		if now >= next_burst_at:
			burst_until = now + GameConstants.BURST_DURATION
			var burst_base := GameConstants.get_burst_cooldown_base(GameManager.stage)
			next_burst_at = now + burst_base + GameManager.randi() % GameConstants.BURST_COOLDOWN_VARIANCE
	
	var burst_mult := GameConstants.BURST_SPEED_MULT if now < burst_until else 1.0
	
	# 璁＄畻鐩爣閫熷害
	var chase_strength := _get_chase_strength()
	var lateral_strength := _get_lateral_strength()
	var target_speed := base_speed * burst_mult
	
	var target_vx := cos(base_angle) * target_speed + cos(base_angle + PI / 2) * target_speed * lateral_strength
	var target_vy := sin(base_angle) * target_speed + sin(base_angle + PI / 2) * target_speed * lateral_strength
	var target_velocity := Vector2(target_vx, target_vy)
	
	# 骞虫粦鎻掑€
	velocity = velocity.lerp(target_velocity, chase_strength)


func _apply_movement(_delta: float) -> void:
	move_and_slide()


func _get_player() -> Node2D:
	# 灏濊瘯閫氳繃缁勮幏鍙栫帺瀹
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _spawn_death_particles() -> void:
	# 杩欓噷鍙互瀹炰緥鍖栫矑瀛愬満鏅?	# 鏆傛椂鐢
	# GameWorld 澶勭悊
	pass



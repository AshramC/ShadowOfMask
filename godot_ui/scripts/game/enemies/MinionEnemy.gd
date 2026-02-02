## MinionEnemy.gd
## 灏忔€晫浜
## 鐢辫闅欓棬鍙敜锛岃拷韪帺瀹讹紝閫熷害杈冨揩浣嗘棤 Burst

extends EnemyBase
class_name MinionEnemy

# ============================================================
# 鍒濆鍖
# ============================================================

func _ready() -> void:
	enemy_type = EnemyType.MINION
	radius = GameConstants.MINION_RADIUS
	max_hp = 1
	speed_multiplier = GameConstants.MINION_SPEED_MULT * GameConstants.RIFT_MINION_BONUS_SPEED
	
	super._ready()


	# ============================================================
	# 閲嶅啓鏂规硶
	# ============================================================

func _update_ai(_delta: float, _now: int) -> void:
	var player := _get_player()
	if player == null:
		return
	
	var player_pos: Vector2 = player.global_position
	var to_player := player_pos - global_position
	var base_angle := to_player.angle()
	
	# 灏忔€拷韪洿绉瀬锛屼絾娌℃湁 Burst
	var chase_strength := 0.1
	var lateral_strength := 0.015 * flank_sign
	
	var target_vx := cos(base_angle) * base_speed + cos(base_angle + PI / 2) * base_speed * lateral_strength
	var target_vy := sin(base_angle) * base_speed + sin(base_angle + PI / 2) * base_speed * lateral_strength
	var target_velocity := Vector2(target_vx, target_vy)
	
	velocity = velocity.lerp(target_velocity, chase_strength)


func _get_chase_strength() -> float:
	return 0.1


func _get_lateral_strength() -> float:
	return 0.015 * flank_sign

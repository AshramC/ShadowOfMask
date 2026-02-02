## EliteEnemy.gd
## 绮捐嫳鏁屼汉
## 楂樿閲忥紝绉诲姩杈冩參锛屾帴瑙︾帺瀹舵椂鍑婚€€骞舵湁鍐峰嵈

extends EnemyBase
class_name EliteEnemy

# ============================================================
# 鍒濆鍖
# ============================================================

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	radius = GameConstants.ELITE_ENEMY_RADIUS
	max_hp = GameConstants.ELITE_MAX_HP
	speed_multiplier = GameConstants.ELITE_SPEED_MULT
	
	super._ready()


	# ============================================================
	# 閲嶅啓鏂规硶
	# ============================================================

func _get_chase_strength() -> float:
	return minf(0.05 + GameManager.stage * 0.006, 0.18)


func _get_lateral_strength() -> float:
	return minf(0.015 + GameManager.stage * 0.003, 0.06) * flank_sign

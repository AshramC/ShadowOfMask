## NormalEnemy.gd
## 鏅€氭晫浜
## 鍩虹杩借釜琛屼负锛屼細鍛ㄦ湡鎬х獊杩?
extends EnemyBase
class_name NormalEnemy

# ============================================================
# 鍒濆鍖
# ============================================================

func _ready() -> void:
	enemy_type = EnemyType.NORMAL
	radius = GameConstants.ENEMY_RADIUS
	max_hp = 1
	speed_multiplier = 1.0
	
	super._ready()

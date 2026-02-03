

extends EnemyBase
class_name NormalEnemy

func _ready() -> void:
	enemy_type = EnemyType.NORMAL
	radius = GameConstants.ENEMY_RADIUS
	max_hp = 1
	speed_multiplier = 1.0

	super._ready()

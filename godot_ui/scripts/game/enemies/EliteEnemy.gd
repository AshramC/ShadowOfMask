

extends EnemyBase
class_name EliteEnemy

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	radius = GameConstants.ELITE_ENEMY_RADIUS
	max_hp = GameConstants.ELITE_MAX_HP
	speed_multiplier = GameConstants.ELITE_SPEED_MULT

	super._ready()

func _get_chase_strength() -> float:
	return minf(0.05 + GameManager.stage * 0.006, 0.18)

func _get_lateral_strength() -> float:
	return minf(0.015 + GameManager.stage * 0.003, 0.06) * flank_sign

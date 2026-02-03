extends Node
class_name CollisionManager

signal dash_hit_enemy(enemy: EnemyBase, player: Player, kills_this_dash: int)

signal player_touched_enemy(enemy: EnemyBase, player: Player)

var player: Player
var wave_manager: WaveManager

func _physics_process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return

	if player == null or wave_manager == null:
		return

	_check_collisions()

func setup(p_player: Player, p_wave_manager: WaveManager) -> void:
	player = p_player
	wave_manager = p_wave_manager

func _check_collisions() -> void:
	var player_pos := player.global_position
	var player_radius := player.get_collision_radius()
	var is_dashing := player.is_dashing()
	var did_dash := player.did_dash_this_frame() if player.has_method("did_dash_this_frame") else false
	var is_invuln := player.is_invulnerable()

	var prev_pos := player.get_previous_position()
	var dash_id := player.get_dash_id()

	for enemy in wave_manager.current_wave_enemies:
		if not is_instance_valid(enemy) or not enemy.is_active or not enemy.is_spawned:
			continue

		var enemy_pos: Vector2 = enemy.global_position
		var enemy_radius: float = enemy.radius
		var combined_radius := player_radius + enemy_radius

		var dash_hit := false
		if is_dashing or did_dash:
			if player.check_line_circle_collision(prev_pos, player_pos, enemy_pos, combined_radius):
				dash_hit = true
				if not player.was_enemy_hit_this_dash(enemy.get_instance_id()):
					player.mark_enemy_hit_this_dash(enemy.get_instance_id())

					var killed: bool = enemy.take_damage(1, dash_id)

					if killed:
						player.notify_enemy_killed(enemy)
					else:
						player.notify_enemy_hit(enemy)

		if dash_hit:
			continue

		var distance := player_pos.distance_to(enemy_pos)
		if distance < combined_radius:
			if not is_invuln:
				if enemy.can_contact_player():
					player_touched_enemy.emit(enemy, player)

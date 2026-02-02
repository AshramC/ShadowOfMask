## CollisionManager.gd
## 纰版挒绠＄悊鍣
## 璐熻矗妫€娴嬬帺瀹朵笌鏁屼汉鐨勭鎾烇紙鍐插埡纰版挒鍜屾帴瑙︾鎾烇級

extends Node
class_name CollisionManager

# ============================================================
# 淇″彿
# ============================================================

## 鍐插埡鍑讳腑鏁屼汉
signal dash_hit_enemy(enemy: EnemyBase, player: Player, kills_this_dash: int)

## 鐜╁鎺ヨЕ鏁屼汉锛堥潪鍐插埡锛
signal player_touched_enemy(enemy: EnemyBase, player: Player)

# ============================================================
# 寮曠敤
# ============================================================

var player: Player
var wave_manager: WaveManager

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _physics_process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	if player == null or wave_manager == null:
		return
	
	_check_collisions()


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 璁剧疆寮曠敤
func setup(p_player: Player, p_wave_manager: WaveManager) -> void:
	player = p_player
	wave_manager = p_wave_manager


	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

func _check_collisions() -> void:
	var player_pos := player.global_position
	var player_radius := player.get_collision_radius()
	var is_dashing := player.is_dashing()
	var is_invuln := player.is_invulnerable()
	
	# 鑾峰彇涓婁竴甯т綅缃紙鐢ㄤ簬鍐插埡纰版挒锛
	var prev_pos := player.get_previous_position()
	var dash_id := player.get_dash_id()
	
	for enemy in wave_manager.current_wave_enemies:
		if not is_instance_valid(enemy) or not enemy.is_active or not enemy.is_spawned:
			continue
		
		var enemy_pos: Vector2 = enemy.global_position
		var enemy_radius: float = enemy.radius
		var combined_radius := player_radius + enemy_radius
		
		if is_dashing:
			# 鍐插埡纰版挒妫€娴嬶紙绾挎涓庡渾锛
			if player.check_line_circle_collision(prev_pos, player_pos, enemy_pos, combined_radius):
				# 妫€鏌ユ槸鍚﹀凡琚湰娆″啿鍒哄嚮涓
				if not player.was_enemy_hit_this_dash(enemy.get_instance_id()):
					player.mark_enemy_hit_this_dash(enemy.get_instance_id())
					
					# 閫犳垚浼ゅ
					var killed: bool = enemy.take_damage(1, dash_id)
					
					if killed:
						player.notify_enemy_killed(enemy)
					else:
						player.notify_enemy_hit(enemy)
					
					# 鑾峰彇褰撳墠鍐插埡鍑绘潃鏁帮紙浠
					# Player 鍐呴儴鐘舵€侊級
					# 杩欓噷閫氳繃 enemy_killed 淇″彿浼犻€
					else:
			# 鏅€氭帴瑙︾鎾
			if not is_invuln:
				var distance := player_pos.distance_to(enemy_pos)
				if distance < combined_radius:
					if enemy.can_contact_player():
						player_touched_enemy.emit(enemy, player)

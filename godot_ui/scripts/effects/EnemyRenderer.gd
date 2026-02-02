## EnemyRenderer.gd
## 鏁屼汉娓叉煋鍣
## 璐熻矗娓叉煋鎵€鏈夌被鍨嬫晫浜虹殑瑙嗚鏁堟灉

extends Node2D
class_name EnemyRenderer

# ============================================================
# 寮曠敤
# ============================================================

var enemy: EnemyBase

# ============================================================
# 缂撳瓨
# ============================================================

var _cached_color: Color = Color.RED
var _cached_radius: float = 10.0
var _glow_color: Color = Color.TRANSPARENT
var _outline_color: Color = Color.TRANSPARENT

# ============================================================
# 鐘舵€
# ============================================================

var _flash_until: int = 0
var _flash_color: Color = Color.WHITE

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 灏濊瘯鑾峰彇鐖惰妭鐐逛綔涓烘晫浜
	var parent := get_parent()
	if parent is EnemyBase:
		enemy = parent
		_update_cached_values()


func _process(_delta: float) -> void:
	if enemy:
		_update_cached_values()
	queue_redraw()


func _draw() -> void:
	if enemy == null or not enemy.is_active:
		return
	
	# 鏈敓鎴愭椂鐨勯瑙堟晥鏋
	if not enemy.is_spawned:
		_draw_spawn_preview()
		return
	
	var now := Time.get_ticks_msec()
	
	# 鏍规嵁鏁屼汉绫诲瀷缁樺埗
	match enemy.enemy_type:
		EnemyBase.EnemyType.NORMAL:
			_draw_normal_enemy()
		EnemyBase.EnemyType.ELITE:
			_draw_elite_enemy()
		EnemyBase.EnemyType.ASSASSIN:
			_draw_assassin_enemy()
		EnemyBase.EnemyType.RIFT:
			_draw_rift_enemy()
		EnemyBase.EnemyType.SNARE:
			_draw_snare_enemy()
		EnemyBase.EnemyType.MINION:
			_draw_minion_enemy()
	
	# 鍙楀嚮闂厜
	if now < _flash_until:
		var flash_alpha := 0.6 * (float(_flash_until - now) / 100.0)
		draw_circle(Vector2.ZERO, _cached_radius + 2, Color(_flash_color.r, _flash_color.g, _flash_color.b, flash_alpha))


		# ============================================================
		# 缁樺埗鏂规硶
		# ============================================================

func _draw_spawn_preview() -> void:
	var now := Time.get_ticks_msec()
	var spawn_progress := 1.0 - maxf(0, float(enemy.spawn_at - now) / 500.0)
	var alpha := 0.3 * spawn_progress
	var preview_color := Color(_cached_color.r, _cached_color.g, _cached_color.b, alpha)
	draw_circle(Vector2.ZERO, _cached_radius * spawn_progress, preview_color)


func _draw_normal_enemy() -> void:
	var now := Time.get_ticks_msec()
	
	# Burst 鐘舵€佹鏌
	var is_bursting := now < enemy.burst_until
	var pulse := 1.0 + sin(float(now) / 80.0) * 0.15 if is_bursting else 1.0
	var r := _cached_radius * pulse
	
	# 缁樺埗涓讳綋
	draw_circle(Vector2.ZERO, r, _cached_color)
	
	# Burst 鍏夋檿
	if is_bursting:
		var glow := Color(1, 0.6, 0.3, 0.4)
		draw_arc(Vector2.ZERO, r + 3, 0, TAU, 24, glow, 2.0)


func _draw_elite_enemy() -> void:
	var now := Time.get_ticks_msec()
	var pulse := 1.0 + sin(float(now) / 200.0) * 0.08
	var r := _cached_radius * pulse
	
	# 缁樺埗鍏夋檿
	var glow := Color(1, 0.6, 0.2, 0.3)
	draw_circle(Vector2.ZERO, r + 5, glow)
	
	# 缁樺埗涓讳綋
	draw_circle(Vector2.ZERO, r, _cached_color)
	
	# 缁樺埗琛€閲忔寚绀哄櫒
	_draw_hp_indicator(r + 8)
	
	# 鎺ヨЕ鍐峰嵈鎸囩ず
	if enemy.contact_cooldown_until > now:
		var cd_progress := float(enemy.contact_cooldown_until - now) / GameConstants.ELITE_CONTACT_COOLDOWN
		draw_arc(Vector2.ZERO, r + 3, 0, TAU * cd_progress, 16, Color(1, 1, 1, 0.3), 2.0)


func _draw_assassin_enemy() -> void:
	if not enemy is AssassinEnemy:
		_draw_normal_enemy()
		return
	
	var assassin := enemy as AssassinEnemy
	var alpha := assassin.get_alpha()
	var now := Time.get_ticks_msec()
	
	var color := Color(_cached_color.r, _cached_color.g, _cached_color.b, alpha)
	var r := _cached_radius
	
	match assassin.current_state:
		AssassinEnemy.AssassinState.APPROACH:
			# 鍗婇€忔槑杩借釜鐘舵€
			draw_circle(Vector2.ZERO, r, color)
		
		AssassinEnemy.AssassinState.WINDUP:
			# 钃勫姏鐘舵€
			# - 鍙戝厜 + 鏂瑰悜鎸囩ず
			var pulse := 0.8 + sin(float(now) / 60.0) * 0.2
			var glow := Color(GameConstants.ASSASSIN_GLOW.r, GameConstants.ASSASSIN_GLOW.g, GameConstants.ASSASSIN_GLOW.b, 0.6 * pulse)
			draw_circle(Vector2.ZERO, r + 4, glow)
			draw_circle(Vector2.ZERO, r, _cached_color)
			
			# 鏂瑰悜绾
			var dir := assassin.dash_direction * (r + 15)
			draw_line(Vector2.ZERO, dir, Color(1, 1, 1, 0.7), 2.0)
		
		AssassinEnemy.AssassinState.DASH:
			# 绐佽繘鐘舵€
			# - 鎷栧熬鏁堟灉
			var glow := Color(GameConstants.ASSASSIN_GLOW.r, GameConstants.ASSASSIN_GLOW.g, GameConstants.ASSASSIN_GLOW.b, 0.8)
			draw_circle(Vector2.ZERO, r + 3, glow)
			draw_circle(Vector2.ZERO, r, _cached_color)
			
			# 缁樺埗鎷栧熬
			var trail_dir := -assassin.dash_direction
			for i in range(3):
				var t := float(i + 1) / 4.0
				var trail_pos := trail_dir * (10 + i * 8)
				var trail_alpha := 0.4 * (1.0 - t)
				var trail_r := r * (1.0 - t * 0.3)
				draw_circle(trail_pos, trail_r, Color(_cached_color.r, _cached_color.g, _cached_color.b, trail_alpha))
		
		AssassinEnemy.AssassinState.RECOVER:
			# 鎭㈠鐘舵€
			draw_circle(Vector2.ZERO, r, color)


func _draw_rift_enemy() -> void:
	var now := Time.get_ticks_msec()
	var pulse := 1.0 + sin(float(now) / 180.0) * 0.1
	var r := _cached_radius * pulse
	
	# 缁樺埗鍏夋檿
	var glow := Color(GameConstants.RIFT_GLOW.r, GameConstants.RIFT_GLOW.g, GameConstants.RIFT_GLOW.b, 0.4)
	draw_circle(Vector2.ZERO, r + 6, glow)
	
	# 缁樺埗涓讳綋
	draw_circle(Vector2.ZERO, r, _cached_color)
	
	# 缁樺埗琛€閲忔寚绀哄櫒
	_draw_hp_indicator(r + 10)
	
	# 缁樺埗鏃嬭浆鐨勭鏂
	var angle := float(now) / 500.0
	for i in range(3):
		var a := angle + i * TAU / 3.0
		var pos := Vector2(cos(a), sin(a)) * (r + 4)
		draw_circle(pos, 2, Color(1, 1, 1, 0.5))


func _draw_snare_enemy() -> void:
	if not enemy is SnareEnemy:
		_draw_normal_enemy()
		return
	
	var snare := enemy as SnareEnemy
	var now := Time.get_ticks_msec()
	var r := _cached_radius
	
	# 缁樺埗鍏夋檿
	var glow := Color(GameConstants.SNARE_GLOW.r, GameConstants.SNARE_GLOW.g, GameConstants.SNARE_GLOW.b, 0.35)
	draw_circle(Vector2.ZERO, r + 5, glow)
	
	# 缁樺埗涓讳綋
	draw_circle(Vector2.ZERO, r, _cached_color)
	
	# 缁樺埗琛€閲忔寚绀哄櫒
	_draw_hp_indicator(r + 8)
	
	# 钃勫姏/閲婃斁鐘舵€
	if snare.is_winding_up() or snare.is_firing():
		var dir := snare.get_snare_direction()
		var chain_end := dir * GameConstants.SNARE_RANGE
		
		if snare.is_winding_up():
			# 钃勫姏璀﹀憡绾
			var warn_alpha := 0.4 + sin(float(now) / 50.0) * 0.2
			draw_line(Vector2.ZERO, chain_end, Color(1, 0.8, 0.3, warn_alpha), 3.0)
		else:
			# 閿侀摼
			draw_line(Vector2.ZERO, chain_end, Color(0.8, 0.7, 0.5, 0.9), GameConstants.SNARE_CHAIN_WIDTH / 3.0)


func _draw_minion_enemy() -> void:
	var now := Time.get_ticks_msec()
	var pulse := 1.0 + sin(float(now) / 100.0) * 0.1
	var r := _cached_radius * pulse
	
	# 缁樺埗涓讳綋锛堣緝灏忥級
	draw_circle(Vector2.ZERO, r, _cached_color)
	
	# 寰急鍏夋檿
	var glow := Color(GameConstants.RIFT_GLOW.r, GameConstants.RIFT_GLOW.g, GameConstants.RIFT_GLOW.b, 0.2)
	draw_circle(Vector2.ZERO, r + 2, glow)


func _draw_hp_indicator(offset_r: float) -> void:
	if enemy.max_hp <= 1:
		return
	
	var hp_ratio := float(enemy.hp) / enemy.max_hp
	var arc_angle := TAU * hp_ratio
	var hp_color := Color(0.3, 1, 0.3, 0.7) if hp_ratio > 0.5 else Color(1, 0.5, 0.3, 0.7)
	
	draw_arc(Vector2.ZERO, offset_r, -PI / 2, -PI / 2 + arc_angle, 16, hp_color, 2.0)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 瑙﹀彂鍙楀嚮闂厜
func flash_hit() -> void:
	_flash_until = Time.get_ticks_msec() + 100
	_flash_color = Color.WHITE


## 璁剧疆鏁屼汉寮曠敤
func set_enemy(e: EnemyBase) -> void:
	enemy = e
	_update_cached_values()


	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

func _update_cached_values() -> void:
	if enemy == null:
		return
	
	_cached_color = enemy.get_color()
	_cached_radius = enemy.radius
	
	match enemy.enemy_type:
		EnemyBase.EnemyType.ASSASSIN:
			_glow_color = GameConstants.ASSASSIN_GLOW
			_outline_color = GameConstants.ASSASSIN_OUTLINE
		EnemyBase.EnemyType.RIFT:
			_glow_color = GameConstants.RIFT_GLOW
		EnemyBase.EnemyType.SNARE:
			_glow_color = GameConstants.SNARE_GLOW
		_:
			_glow_color = Color.TRANSPARENT
			_outline_color = Color.TRANSPARENT

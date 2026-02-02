## GameWorld.gd
## 娓告垙涓栫晫绠＄悊鍣
## 鏁村悎 Player銆乄aveManager銆丆omboSystem銆丗everSystem銆丆ollisionManager
## 浠ュ強鎵€鏈夎瑙夋晥鏋滅粍浠?
extends Node2D
class_name GameWorld

# ============================================================
# 鑺傜偣寮曠敤
# ============================================================

@export var player_scene: PackedScene

@onready var enemy_container: Node2D = $Enemies
@onready var rift_container: Node2D = $Rifts
@onready var effects_container: Node2D = $Effects
@onready var particle_emitter: ParticleEmitter = $Effects/ParticleEmitter
@onready var dash_indicator: DashIndicator = $Effects/DashIndicator
@onready var combo_announcement: ComboAnnouncement = $UI/ComboAnnouncement

# ============================================================
# 瀛愮郴缁
# ============================================================

var player: Player
var wave_manager: WaveManager
var combo_system: ComboSystem
var fever_system: FeverSystem
var collision_manager: CollisionManager
var screen_effects: ScreenEffects

# ============================================================
# 棰勫姞杞藉満鏅
# ============================================================

var KillTextScene: PackedScene

# ============================================================
# 鐘舵€
# ============================================================

var _hit_stop_this_dash: bool = false

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 纭繚瀹瑰櫒鑺傜偣瀛樺湪
	_ensure_containers()
	
	# 鍒濆鍖栧瓙绯荤粺
	_init_subsystems()
	
	# 杩炴帴淇″彿
	_connect_signals()
	
	# 杩炴帴 GameManager 淇″彿
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)
	
	# 棰勫姞杞藉満鏅
	_preload_scenes()


func _physics_process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	# Hit Stop 鏈熼棿鏆傚仠鐗╃悊
	if combo_system and combo_system.is_hit_stopped():
		return
	
	# 鏇存柊鍐插埡鎸囩ず鍣
	_update_dash_indicator()
	
	# 鍚屾杞ㄨ抗娓叉煋
	_sync_trail_renderer()
	
	# 鏇存柊 Fever UI
	_update_fever_ui()


	# ============================================================
	# 绉佹湁鏂规硶 - 鍒濆鍖
	# ============================================================

func _ensure_containers() -> void:
	if enemy_container == null:
		enemy_container = Node2D.new()
		enemy_container.name = "Enemies"
		add_child(enemy_container)
	
	if rift_container == null:
		rift_container = Node2D.new()
		rift_container.name = "Rifts"
		add_child(rift_container)
	
	if effects_container == null:
		effects_container = Node2D.new()
		effects_container.name = "Effects"
		add_child(effects_container)


func _init_subsystems() -> void:
	# 鍒涘缓 WaveManager
	wave_manager = WaveManager.new()
	wave_manager.name = "WaveManager"
	wave_manager.enemy_container = enemy_container
	wave_manager.rift_container = rift_container
	add_child(wave_manager)
	
	# 鍒涘缓 ComboSystem
	combo_system = ComboSystem.new()
	combo_system.name = "ComboSystem"
	add_child(combo_system)
	
	# 鍒涘缓 FeverSystem
	fever_system = FeverSystem.new()
	fever_system.name = "FeverSystem"
	add_child(fever_system)
	
	# 鍒涘缓 CollisionManager
	collision_manager = CollisionManager.new()
	collision_manager.name = "CollisionManager"
	add_child(collision_manager)
	
	# 鏌ユ壘鎴栧垱寤
	ScreenEffects
	screen_effects = get_node_or_null("/root/Main/ScreenEffects") as ScreenEffects
	if screen_effects == null:
		# 灏濊瘯鍔犺浇鍦烘櫙
		var effects_scene := load("res://godot_ui/scenes/ScreenEffects.tscn")
		if effects_scene:
			screen_effects = effects_scene.instantiate() as ScreenEffects
			get_tree().root.call_deferred("add_child", screen_effects)


func _preload_scenes() -> void:
	# 棰勫姞杞藉嚮鏉€鏂囧瓧鍦烘櫙锛堝鏋滃瓨鍦級
	if ResourceLoader.exists("res://godot_ui/scenes/KillText.tscn"):
		KillTextScene = load("res://godot_ui/scenes/KillText.tscn")


func _spawn_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	
	# 鍒涘缓鐜╁
	if player_scene:
		player = player_scene.instantiate() as Player
	else:
		# 灏濊瘯鍔犺浇榛樿鍦烘櫙
		var default_scene := load("res://godot_ui/scenes/Player.tscn")
		if default_scene:
			player = default_scene.instantiate() as Player
		else:
			# 鍒涘缓鍩虹鐜╁
			player = Player.new()
			var collision := CollisionShape2D.new()
			collision.name = "CollisionShape2D"
			player.add_child(collision)
			
			var renderer := PlayerRenderer.new()
			renderer.name = "PlayerRenderer"
			player.add_child(renderer)
	
	player.name = "Player"
	player.add_to_group("player")
	
	# 鏀剧疆鍦ㄥ睆骞曚腑蹇
	var viewport_rect := get_viewport().get_visible_rect()
	player.global_position = viewport_rect.size / 2.0
	
	add_child(player)
	
	# 璁剧疆 CollisionManager
	collision_manager.setup(player, wave_manager)
	
	# 杩炴帴鐜╁淇″彿
	player.dash_started.connect(_on_player_dash_started)
	player.dash_ended.connect(_on_player_dash_ended)
	player.dash_pending_started.connect(_on_player_dash_pending_started)
	player.dash_pending_progress.connect(_on_player_dash_pending_progress)
	player.dash_pending_cancelled.connect(_on_player_dash_pending_cancelled)
	player.enemy_killed.connect(_on_player_enemy_killed)
	player.enemy_hit.connect(_on_player_enemy_hit)


func _connect_signals() -> void:
	# WaveManager 淇″彿
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	wave_manager.penalty_enemies_spawned.connect(_on_penalty_enemies_spawned)
	
	# ComboSystem 淇″彿
	combo_system.combo_updated.connect(_on_combo_updated)
	combo_system.mark_intensity_updated.connect(_on_mark_intensity_updated)
	combo_system.screen_shake_requested.connect(_on_screen_shake_requested)
	combo_system.kill_text_requested.connect(_on_kill_text_requested)
	combo_system.impact_flash_requested.connect(_on_impact_flash_requested)
	combo_system.combo_announcement_requested.connect(_on_combo_announcement_requested)
	
	# FeverSystem 淇″彿
	fever_system.fever_activated.connect(_on_fever_activated)
	fever_system.fever_deactivated.connect(_on_fever_deactivated)
	fever_system.fever_flash_requested.connect(_on_fever_flash_requested)
	
	# CollisionManager 淇″彿
	collision_manager.player_touched_enemy.connect(_on_player_touched_enemy)


	# ============================================================
	# 绉佹湁鏂规硶 - 鏇存柊
	# ============================================================

func _update_dash_indicator() -> void:
	if dash_indicator == null or player == null:
		return
	
	if player.is_pending_dash():
		var target := player.get_pending_target()
		var progress := player.get_pending_progress()
		dash_indicator.update_progress(progress)
	elif dash_indicator.is_active:
		dash_indicator.hide_indicator()


func _sync_trail_renderer() -> void:
	if player == null:
		return
	
	# 鏌ユ壘鐜╁涓嬬殑杞ㄨ抗娓叉煋鍣
	var trail := player.get_node_or_null("DashTrailRenderer") as DashTrailRenderer
	if trail:
		trail.sync_from_player(player)


func _update_fever_ui() -> void:
	# Fever UI 鏇存柊鐢
	# FeverBarUI 鑷繁澶勭悊
	pass


	# ============================================================
	# 淇″彿鍥炶皟 - GameManager
	# ============================================================

func _on_game_started(_seed: String) -> void:
	_spawn_player()
	_hit_stop_this_dash = false
	
	# 娓呴櫎绮掑瓙
	if particle_emitter:
		particle_emitter.clear()


func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		# 娓呯悊鐜╁
		if player and is_instance_valid(player):
			player.queue_free()
			player = null
		
		# 闅愯棌鍐插埡鎸囩ず鍣
		if dash_indicator:
			dash_indicator.hide_indicator()


			# ============================================================
			# 淇″彿鍥炶皟 - Player
			# ============================================================

func _on_player_dash_pending_started(target_pos: Vector2, delay_ms: float) -> void:
	if dash_indicator and player:
		dash_indicator.show_indicator(player.global_position, target_pos, delay_ms)


func _on_player_dash_pending_progress(progress: float) -> void:
	if dash_indicator:
		dash_indicator.update_progress(progress)


func _on_player_dash_pending_cancelled() -> void:
	if dash_indicator:
		dash_indicator.hide_indicator()


func _on_player_dash_started(_start_pos: Vector2, _end_pos: Vector2) -> void:
	_hit_stop_this_dash = false
	
	if dash_indicator:
		dash_indicator.hide_indicator()


func _on_player_dash_ended(_kills_this_dash: int) -> void:
	_hit_stop_this_dash = false


func _on_player_enemy_killed(enemy: EnemyBase, kills_this_dash: int) -> void:
	var combo_level := combo_system.get_combo_level()
	
	# 娣诲姞鍒
	# Add to Combo
	combo_system.add_kills(1, enemy.global_position, kills_this_dash)
	
	# 鏇存柊 Combo 绛夌骇
	combo_level = combo_system.get_combo_level()
	
	# Hit Stop锛堟瘡娆″啿鍒哄彧瑙﹀彂涓€娆★級
	if not _hit_stop_this_dash:
		combo_system.trigger_hit_stop(combo_level)
		_hit_stop_this_dash = true
	
	# Fever 鑳介噺
	var fever_gain := enemy.get_fever_value()
	fever_system.add_fever(fever_gain, combo_level)
	
	# 绮掑瓙鏁堟灉
	if particle_emitter:
		var is_elite := enemy.enemy_type == EnemyBase.EnemyType.ELITE
		particle_emitter.emit_kill(enemy.global_position, is_elite)
		
		if combo_level >= 3:
			particle_emitter.emit_combo_burst(enemy.global_position, combo_level)
	
	# 闈㈠叿鐮寸鍚庡嚮鏉€璁℃暟
	if not GameManager.is_masked:
		GameManager.add_shattered_kill()
		
		# 妫€鏌ユ槸鍚︽仮澶嶉潰鍏
		if GameManager.shattered_kills >= 3:
			_restore_mask()
	
	# 鏇存柊鍒嗘暟
	GameManager.add_score(1)
	
	# 鎾斁鍑绘潃闊虫晥
	var is_elite := enemy.enemy_type == EnemyBase.EnemyType.ELITE
	AudioManager.play_kill_sfx(combo_level, is_elite)


func _on_player_enemy_hit(enemy: EnemyBase) -> void:
	# 绮掑瓙鏁堟灉
	if particle_emitter:
		particle_emitter.emit_hit(enemy.global_position, enemy.get_type_name())
	
	# 鎾斁鍑讳腑闊虫晥锛堟湭鍑绘潃锛
	AudioManager.play_hit()


	# ============================================================
	# 淇″彿鍥炶皟 - WaveManager
	# ============================================================

func _on_wave_started(wave_id: int, enemy_count: int) -> void:
	print("[GameWorld] Wave %d started with %d enemies" % [wave_id, enemy_count])


func _on_wave_completed(wave_id: int) -> void:
	print("[GameWorld] Wave %d completed" % wave_id)
	AudioManager.play_stage_clear()
	
	# 寤堕暱 Fever 鏃堕棿
	if fever_system.is_fever_active():
		fever_system.extend_fever(GameConstants.WAVE_TRANSITION_DELAY)


func _on_enemy_spawned(_enemy: EnemyBase) -> void:
	pass


func _on_penalty_enemies_spawned(count: int) -> void:
	print("[GameWorld] Penalty: %d enemies spawned" % count)


	# ============================================================
	# 淇″彿鍥炶皟 - ComboSystem
	# ============================================================

func _on_combo_updated(_count: int, _level: int) -> void:
	pass


func _on_mark_intensity_updated(intensity: float) -> void:
	if screen_effects:
		screen_effects.set_mark_intensity(intensity)


func _on_screen_shake_requested(magnitude: float, duration_ms: int) -> void:
	if screen_effects:
		screen_effects.shake(magnitude, duration_ms)


func _on_kill_text_requested(pos: Vector2, kills: int, combo_level: int) -> void:
	# 鍒涘缓鍑绘潃鏂囧瓧
	var kill_text: KillText
	
	if KillTextScene:
		kill_text = KillTextScene.instantiate() as KillText
	else:
		kill_text = KillText.new()
	
	kill_text.global_position = pos
	kill_text.setup(kills, combo_level)
	effects_container.add_child(kill_text)


func _on_impact_flash_requested(color: Color, alpha: float, duration_ms: int) -> void:
	if screen_effects:
		screen_effects.flash(color, alpha, duration_ms)


func _on_combo_announcement_requested(text: String, scale: float, color: Color) -> void:
	if combo_announcement:
		combo_announcement.show_announcement(text, scale, color)


		# ============================================================
		# 淇″彿鍥炶皟 - FeverSystem
		# ============================================================

func _on_fever_activated() -> void:
	print("[GameWorld] Fever activated!")
	
	if screen_effects:
		screen_effects.flash_fever_in()


func _on_fever_deactivated() -> void:
	print("[GameWorld] Fever ended")
	
	if screen_effects:
		screen_effects.flash_fever_out()


func _on_fever_flash_requested(type: String) -> void:
	if screen_effects:
		if type == "in":
			screen_effects.flash_fever_in()
		else:
			screen_effects.flash_fever_out()


			# ============================================================
			# 淇″彿鍥炶皟 - CollisionManager
			# ============================================================

func _on_player_touched_enemy(enemy: EnemyBase, _player: Player) -> void:
	# 鐜╁琚晫浜烘帴瑙
	if GameManager.is_masked:
		# 闈㈠叿鐮寸
		_break_mask(enemy)
	else:
		# 娓告垙缁撴潫
		_game_over()


		# ============================================================
		# 绉佹湁鏂规硶 - 闈㈠叿绯荤粺
		# ============================================================

func _break_mask(enemy: EnemyBase) -> void:
	GameManager.shatter_mask()
	
	# 璁剧疆鐜╁鏃犳晫
	player.set_invulnerable(GameConstants.PLAYER_INVULN_MS)
	
	# 娓呯┖ Fever
	fever_system.on_mask_broken()
	
	# 灞忓箷闂厜
	if screen_effects:
		screen_effects.flash_mask_break()
	
	# 绮掑瓙鏁堟灉
	if particle_emitter:
		particle_emitter.emit_mask_break(player.global_position)
	
	var killed := false
	
	# 绮捐嫳鏁屼汉鍑婚€€鐜╁
	if enemy.enemy_type == EnemyBase.EnemyType.ELITE:
		enemy.set_contact_cooldown()
		var knockback_dir := (player.global_position - enemy.global_position).normalized()
		player.knockback(knockback_dir, GameConstants.ELITE_KNOCKBACK_DISTANCE)
		
		# 绮捐嫳鍙楀埌 1 鐐逛激瀹
		killed = enemy.take_damage(1)
	else:
		# 鏅€氭晫浜虹洿鎺ユ浜
		enemy.die()
		killed = true
	
	# 涓
	# Web 鐗堜竴鑷达細闈㈠叿鐮寸鎺ヨЕ瀵艰嚧鐨勫嚮鏉€涔熻鍒
	if killed:
		GameManager.add_score(1)
	
	# 鎾斁闊虫晥
	AudioManager.play_mask_shatter()


func _restore_mask() -> void:
	GameManager.is_masked = true
	GameManager.shattered_kills = 0
	GameManager.mask_state_changed.emit(true, 0)
	
	# 灞忓箷闂厜
	if screen_effects:
		screen_effects.flash_mask_restore()
	
	# 绮掑瓙鏁堟灉
	if particle_emitter:
		particle_emitter.emit_mask_restore(player.global_position)
	
	# 鎾斁闊虫晥
	AudioManager.play_mask_restore()


func _game_over() -> void:
	GameManager.trigger_game_over()
	AudioManager.play_game_over()

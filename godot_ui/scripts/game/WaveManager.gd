## WaveManager.gd
## 娉㈡绠＄悊鍣
## 璐熻矗鐢熸垚鏁屼汉娉㈡銆佺鐞嗘儵缃氭満鍒躲€佸鐞嗘尝娆″畬鎴?
extends Node
class_name WaveManager

# ============================================================
# 淇″彿
# ============================================================

## 娉㈡寮€濮
signal wave_started(wave_id: int, enemy_count: int)

## 娉㈡瀹屾垚
signal wave_completed(wave_id: int)

## 鏁屼汉鐢熸垚
signal enemy_spawned(enemy: EnemyBase)

## 瑁傞殭鐢熸垚
signal rift_spawned(rift: Node2D)

## 鎯╃綒鏁屼汉鐢熸垚
signal penalty_enemies_spawned(count: int)

## 鏃犲嚮鏉€璀﹀憡
signal no_kill_warning(strikes: int)

# ============================================================
# 瀵煎嚭鍙橀噺
# ============================================================

@export var enemy_container: Node2D  ## 鏁屼汉瀹瑰櫒鑺傜偣
@export var rift_container: Node2D   ## 瑁傞殭瀹瑰櫒鑺傜偣

# ============================================================
# 棰勫姞杞藉満鏅
# ============================================================

var NormalEnemyScene: PackedScene
var EliteEnemyScene: PackedScene
var AssassinEnemyScene: PackedScene
var RiftEnemyScene: PackedScene
var SnareEnemyScene: PackedScene
var MinionEnemyScene: PackedScene
var RiftPortalScene: PackedScene

# ============================================================
# 鐘舵€
# ============================================================

var current_wave_id: int = 0
var enemies_in_wave: int = 0
var enemies_killed_in_wave: int = 0
var wave_complete: bool = true
var wave_start_at: int = 0

## 鏃犲嚮鏉€鎯╃綒
var last_kill_at: int = 0
var no_kill_strikes: int = 0

## 娲昏穬鐨勮闅欓棬
var active_rifts: Array[Node2D] = []

## 褰撳墠娉㈡鏁屼汉
var current_wave_enemies: Array[EnemyBase] = []

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 杩炴帴 GameManager 淇″彿
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)
	
	# 棰勫姞杞藉満鏅紙濡傛灉瀛樺湪锛
	_preload_scenes()


func _process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	if wave_complete:
		return
	
	var now := Time.get_ticks_msec()
	
	# 妫€鏌ユ尝娆″畬鎴
	_check_wave_completion(now)
	
	# 妫€鏌ユ棤鍑绘潃鎯╃綒
	_check_no_kill_penalty(now)
	
	# 鏇存柊瑁傞殭闂
	_update_rifts(now)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 寮€濮嬫柊娉㈡
func start_wave() -> void:
	current_wave_id = GameManager.stage
	wave_complete = false
	wave_start_at = Time.get_ticks_msec()
	last_kill_at = wave_start_at
	no_kill_strikes = 0
	current_wave_enemies.clear()
	
	_spawn_wave_enemies()
	
	wave_started.emit(current_wave_id, enemies_in_wave)


## 閫氱煡鏁屼汉琚嚮鏉€
func on_enemy_killed(enemy: EnemyBase) -> void:
	enemies_killed_in_wave += 1
	last_kill_at = Time.get_ticks_msec()
	no_kill_strikes = 0
	
	# 浠庡綋鍓嶆尝娆＄Щ闄
	var idx := current_wave_enemies.find(enemy)
	if idx >= 0:
		current_wave_enemies.remove_at(idx)


## 鑾峰彇褰撳墠娉㈡瀛樻椿鏁屼汉鏁
func get_alive_enemy_count() -> int:
	var count := 0
	for enemy in current_wave_enemies:
		if is_instance_valid(enemy) and enemy.is_active:
			count += 1
	return count


## 鐢熸垚灏忔€紙鐢辫闅欓棬璋冪敤锛
func spawn_minion(spawn_pos: Vector2) -> void:
	var minion := _create_enemy(EnemyBase.EnemyType.MINION)
	if minion:
		minion.global_position = spawn_pos
		minion.initialize(current_wave_id, 0)
		
		if enemy_container:
			enemy_container.add_child(minion)
		
		current_wave_enemies.append(minion)
		enemies_in_wave += 1
		
		enemy_spawned.emit(minion)


		# ============================================================
		# 绉佹湁鏂规硶 - 娉㈡鐢熸垚
		# ============================================================

func _spawn_wave_enemies() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var w := viewport_rect.size.x
	var h := viewport_rect.size.y
	
	var stage := GameManager.stage
	var wave_index := (stage - 1) % 5
	
	# 璁＄畻鏁屼汉鏁伴噺
	var base_count := roundi(4 + stage * 1.2)
	var normal_count := base_count
	var elite_count := 0
	var assassin_count := 0
	var rift_count := 0
	var snare_count := 0
	
	# 鏍规嵁娉㈡绫诲瀷璋冩暣
	if wave_index == 2:
		elite_count = 1
	elif wave_index == 3:
		normal_count = roundi(base_count * 1.4)
	elif wave_index == 4:
		elite_count = mini(3, 1 + stage / 5)
		normal_count = maxi(2, roundi(base_count * 0.6))
	
	# 鍒哄锛圫tage 4+锛
	if stage >= 4:
		assassin_count = mini(3, 1 + (stage - 4) / 5)
		if wave_index == 3 and assassin_count > 1:
			assassin_count = 1
	
	# 瑁傞殭锛圫tage 6+锛
	if stage >= 6:
		rift_count = mini(2, 1 + (stage - 6) / 5)
	
	# 鏉熺細锛圫tage 8+锛
	if stage >= 8:
		snare_count = mini(2, 1 + (stage - 8) / 5)
	
	enemies_in_wave = normal_count + elite_count + assassin_count + rift_count + snare_count
	enemies_killed_in_wave = 0
	
	# 鐢熸垚鏁屼汉
	var burst_split := normal_count / 2 if wave_index == 3 else normal_count
	
	for i in range(normal_count):
		var delay := GameConstants.BURST_WAVE_DELAY if (wave_index == 3 and i >= burst_split) else 0
		_spawn_enemy(EnemyBase.EnemyType.NORMAL, w, h, delay)
	
	for i in range(elite_count):
		_spawn_enemy(EnemyBase.EnemyType.ELITE, w, h, 0)
	
	for i in range(assassin_count):
		_spawn_enemy(EnemyBase.EnemyType.ASSASSIN, w, h, 0)
	
	for i in range(rift_count):
		_spawn_enemy(EnemyBase.EnemyType.RIFT, w, h, 0)
	
	for i in range(snare_count):
		_spawn_enemy(EnemyBase.EnemyType.SNARE, w, h, 0)


func _spawn_enemy(type: EnemyBase.EnemyType, w: float, h: float, delay_ms: int) -> void:
	var enemy := _create_enemy(type)
	if enemy == null:
		return
	
	# 鍦ㄥ睆骞曡竟缂樼敓鎴
	var spawn_pos := _get_edge_spawn_position(w, h)
	enemy.global_position = spawn_pos
	
	# 鍒濆鍖
	enemy.initialize(current_wave_id, delay_ms)
	
	# 璁剧疆鍒濆閫熷害鏂瑰悜锛堟湞鍚戜腑蹇冿級
	var center := Vector2(w / 2, h / 2)
	var angle := (center - spawn_pos).angle() + (GameManager.randf() - 0.5) * 0.5
	enemy.velocity = Vector2(cos(angle), sin(angle)) * enemy.base_speed
	
	# 娣诲姞鍒板鍣
	if enemy_container:
		enemy_container.add_child(enemy)
	
	# 杩炴帴淇″彿
	enemy.died.connect(_on_enemy_died)
	
	# 瑁傞殭鏁屼汉鐗规畩澶勭悊
	if type == EnemyBase.EnemyType.RIFT and enemy is RiftEnemy:
		(enemy as RiftEnemy).rift_spawned.connect(_on_rift_enemy_spawn_rift)
	
	current_wave_enemies.append(enemy)
	enemy_spawned.emit(enemy)


func _get_edge_spawn_position(w: float, h: float) -> Vector2:
	var spawn_pos := Vector2.ZERO
	
	if GameManager.randf() > 0.5:
		spawn_pos.x = -20 if GameManager.randf() > 0.5 else w + 20
		spawn_pos.y = GameManager.randf() * h
	else:
		spawn_pos.x = GameManager.randf() * w
		spawn_pos.y = -20 if GameManager.randf() > 0.5 else h + 20
	
	return spawn_pos


func _create_enemy(type: EnemyBase.EnemyType) -> EnemyBase:
	# 濡傛灉鏈夐鍔犺浇鐨勫満鏅紝浣跨敤鍦烘櫙瀹炰緥鍖
	# 鍚﹀垯鍒涘缓鍩虹鑺傜偣锛堥渶瑕佹墜鍔ㄩ厤缃級
	
	match type:
		EnemyBase.EnemyType.NORMAL:
			if NormalEnemyScene:
				return NormalEnemyScene.instantiate() as EnemyBase
			return _create_basic_enemy(type)
		EnemyBase.EnemyType.ELITE:
			if EliteEnemyScene:
				return EliteEnemyScene.instantiate() as EnemyBase
			return _create_basic_enemy(type)
		EnemyBase.EnemyType.ASSASSIN:
			if AssassinEnemyScene:
				return AssassinEnemyScene.instantiate() as EnemyBase
			return _create_basic_enemy(type)
		EnemyBase.EnemyType.RIFT:
			if RiftEnemyScene:
				return RiftEnemyScene.instantiate() as EnemyBase
			return _create_basic_enemy(type)
		EnemyBase.EnemyType.SNARE:
			if SnareEnemyScene:
				return SnareEnemyScene.instantiate() as EnemyBase
			return _create_basic_enemy(type)
		EnemyBase.EnemyType.MINION:
			if MinionEnemyScene:
				return MinionEnemyScene.instantiate() as EnemyBase
			return _create_basic_enemy(type)
	
	return null


func _create_basic_enemy(type: EnemyBase.EnemyType) -> EnemyBase:
	# 鍒涘缓鍩虹鏁屼汉鑺傜偣锛堢敤浜庢病鏈夊満鏅殑鎯呭喌锛
	var enemy: EnemyBase
	
	match type:
		EnemyBase.EnemyType.NORMAL:
			enemy = NormalEnemy.new()
		EnemyBase.EnemyType.ELITE:
			enemy = EliteEnemy.new()
		EnemyBase.EnemyType.ASSASSIN:
			enemy = AssassinEnemy.new()
		EnemyBase.EnemyType.RIFT:
			enemy = RiftEnemy.new()
		EnemyBase.EnemyType.SNARE:
			enemy = SnareEnemy.new()
		EnemyBase.EnemyType.MINION:
			enemy = MinionEnemy.new()
		_:
			enemy = NormalEnemy.new()
	
	# 娣诲姞纰版挒褰㈢姸
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	enemy.add_child(collision)
	
	return enemy


	# ============================================================
	# 绉佹湁鏂规硶 - 娉㈡妫€鏌
	# ============================================================

func _check_wave_completion(now: int) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	
	# 妫€鏌ユ墍鏈夊綋鍓嶆尝娆℃晫浜
	var all_spawned := true
	var all_dead := true
	var all_on_screen := true
	
	for enemy in current_wave_enemies:
		if not is_instance_valid(enemy):
			continue
		
		if not enemy.is_spawned:
			all_spawned = false
		
		if enemy.is_active:
			all_dead = false
			
			# 妫€鏌ユ槸鍚﹀湪灞忓箷鍐
			var pos := enemy.global_position
			if pos.x < 0 or pos.x > viewport_rect.size.x or pos.y < 0 or pos.y > viewport_rect.size.y:
				all_on_screen = false
	
	# 绉婚櫎鏃犳晥鏁屼汉
	current_wave_enemies = current_wave_enemies.filter(func(e): return is_instance_valid(e))
	
	if all_dead and current_wave_enemies.size() == 0:
		_complete_wave()


func _complete_wave() -> void:
	wave_complete = true
	no_kill_strikes = 0
	
	# 娓呯悊瑁傞殭闂
	for rift in active_rifts:
		if is_instance_valid(rift):
			rift.queue_free()
	active_rifts.clear()
	
	wave_completed.emit(current_wave_id)
	
	# 閫氱煡 GameManager 杩涘叆涓嬩竴鍏
	GameManager.advance_stage()
	
	# 寤惰繜寮€濮嬩笅涓€娉
	get_tree().create_timer(GameConstants.WAVE_TRANSITION_DELAY / 1000.0).timeout.connect(_on_wave_transition_complete)


func _on_wave_transition_complete() -> void:
	if GameManager.current_phase == GameManager.GamePhase.PLAYING:
		start_wave()


		# ============================================================
		# 绉佹湁鏂规硶 - 鎯╃綒鏈哄埗
		# ============================================================

func _check_no_kill_penalty(now: int) -> void:
	# 妫€鏌ユ墍鏈夋晫浜烘槸鍚﹀凡鐢熸垚
	var all_spawned := true
	for enemy in current_wave_enemies:
		if is_instance_valid(enemy) and not enemy.is_spawned:
			all_spawned = false
			break
	
	if not all_spawned:
		return
	
	var no_kill_limit := GameConstants.get_no_kill_limit(GameManager.stage)
	var time_since_kill := now - last_kill_at
	
	if time_since_kill >= no_kill_limit:
		no_kill_strikes += 1
		no_kill_warning.emit(no_kill_strikes)
		
		if no_kill_strikes < GameConstants.NO_KILL_ESCALATE_THRESHOLD:
			# 鐢熸垚鎯╃綒鏁屼汉
			_spawn_penalty_enemies()
			last_kill_at = now
		else:
			# 寮哄埗瀹屾垚娉㈡
			_complete_wave()


func _spawn_penalty_enemies() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var w := viewport_rect.size.x
	var h := viewport_rect.size.y
	
	for i in range(GameConstants.NO_KILL_EXTRA_SPAWN_COUNT):
		_spawn_enemy(EnemyBase.EnemyType.NORMAL, w, h, 0)
	
	penalty_enemies_spawned.emit(GameConstants.NO_KILL_EXTRA_SPAWN_COUNT)


	# ============================================================
	# 绉佹湁鏂规硶 - 瑁傞殭闂
	# ============================================================

func _update_rifts(now: int) -> void:
	for i in range(active_rifts.size() - 1, -1, -1):
		var rift = active_rifts[i]
		if not is_instance_valid(rift):
			active_rifts.remove_at(i)
			continue
		
		# 瑁傞殭闂ㄩ€昏緫鍦?RiftPortal 鍦烘櫙涓鐞
		# 杩欓噷鍙仛娓呯悊


func _on_rift_enemy_spawn_rift(spawn_pos: Vector2) -> void:
	# 鍒涘缓瑁傞殭闂
	if RiftPortalScene:
		var rift := RiftPortalScene.instantiate()
		rift.global_position = spawn_pos
		
		if rift_container:
			rift_container.add_child(rift)
		
		# 杩炴帴瑁傞殭闂ㄧ殑灏忔€敓鎴愪俊鍙
		if rift.has_signal("minion_spawn_requested"):
			rift.minion_spawn_requested.connect(spawn_minion)
		
		active_rifts.append(rift)
		rift_spawned.emit(rift)
	else:
		# 娌℃湁瑁傞殭闂ㄥ満鏅紝鐩存帴鐢熸垚灏忔€
		spawn_minion(spawn_pos)


		# ============================================================
		# 绉佹湁鏂规硶 - 鍦烘櫙棰勫姞杞
		# ============================================================

func _preload_scenes() -> void:
	# 灏濊瘯鍔犺浇鏁屼汉鍦烘櫙锛堝鏋滃瓨鍦級
	var base_path := "res://godot_ui/scenes/enemies/"
	
	if ResourceLoader.exists(base_path + "NormalEnemy.tscn"):
		NormalEnemyScene = load(base_path + "NormalEnemy.tscn")
	if ResourceLoader.exists(base_path + "EliteEnemy.tscn"):
		EliteEnemyScene = load(base_path + "EliteEnemy.tscn")
	if ResourceLoader.exists(base_path + "AssassinEnemy.tscn"):
		AssassinEnemyScene = load(base_path + "AssassinEnemy.tscn")
	if ResourceLoader.exists(base_path + "RiftEnemy.tscn"):
		RiftEnemyScene = load(base_path + "RiftEnemy.tscn")
	if ResourceLoader.exists(base_path + "SnareEnemy.tscn"):
		SnareEnemyScene = load(base_path + "SnareEnemy.tscn")
	if ResourceLoader.exists(base_path + "MinionEnemy.tscn"):
		MinionEnemyScene = load(base_path + "MinionEnemy.tscn")
	if ResourceLoader.exists(base_path + "RiftPortal.tscn"):
		RiftPortalScene = load(base_path + "RiftPortal.tscn")


		# ============================================================
		# 淇″彿鍥炶皟
		# ============================================================

func _on_game_started(_seed: String) -> void:
	# 閲嶇疆鐘舵€
	current_wave_id = 0
	enemies_in_wave = 0
	enemies_killed_in_wave = 0
	wave_complete = true
	no_kill_strikes = 0
	current_wave_enemies.clear()
	
	# 娓呯悊瑁傞殭闂
	for rift in active_rifts:
		if is_instance_valid(rift):
			rift.queue_free()
	active_rifts.clear()
	
	# 寮€濮嬬涓€娉
	start_wave()


func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		# 娓呯悊鎵€鏈夋晫浜
		for enemy in current_wave_enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
		current_wave_enemies.clear()
		
		# 娓呯悊瑁傞殭闂
		for rift in active_rifts:
			if is_instance_valid(rift):
				rift.queue_free()
		active_rifts.clear()


func _on_enemy_died(enemy: EnemyBase) -> void:
	on_enemy_killed(enemy)


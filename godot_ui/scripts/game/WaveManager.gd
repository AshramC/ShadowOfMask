

extends Node
class_name WaveManager

signal wave_started(wave_id: int, enemy_count: int)

signal wave_completed(wave_id: int)

signal enemy_spawned(enemy: EnemyBase)

signal rift_spawned(rift: Node2D)

signal penalty_enemies_spawned(count: int)

signal no_kill_warning(strikes: int)

@export var enemy_container: Node2D
@export var rift_container: Node2D

var NormalEnemyScene: PackedScene
var EliteEnemyScene: PackedScene
var AssassinEnemyScene: PackedScene
var RiftEnemyScene: PackedScene
var SnareEnemyScene: PackedScene
var MinionEnemyScene: PackedScene
var RiftPortalScene: PackedScene

var current_wave_id: int = 0
var enemies_in_wave: int = 0
var enemies_killed_in_wave: int = 0
var wave_complete: bool = true
var wave_start_at: int = 0

var last_kill_at: int = 0
var no_kill_strikes: int = 0

var active_rifts: Array[Node2D] = []

var current_wave_enemies: Array[EnemyBase] = []

func _ready() -> void:

	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)

	_preload_scenes()

func _process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return

	if wave_complete:
		return

	var now := Time.get_ticks_msec()

	_check_wave_completion(now)

	_check_no_kill_penalty(now)

	_update_rifts(now)

func start_wave() -> void:
	current_wave_id = GameManager.stage
	wave_complete = false
	wave_start_at = Time.get_ticks_msec()
	last_kill_at = wave_start_at
	no_kill_strikes = 0
	current_wave_enemies.clear()

	_spawn_wave_enemies()

	wave_started.emit(current_wave_id, enemies_in_wave)

func on_enemy_killed(enemy: EnemyBase) -> void:
	enemies_killed_in_wave += 1
	last_kill_at = Time.get_ticks_msec()
	no_kill_strikes = 0

	var idx := current_wave_enemies.find(enemy)
	if idx >= 0:
		current_wave_enemies.remove_at(idx)

func get_alive_enemy_count() -> int:
	var count := 0
	for enemy in current_wave_enemies:
		if is_instance_valid(enemy) and enemy.is_active:
			count += 1
	return count

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

func _spawn_wave_enemies() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var w := viewport_rect.size.x
	var h := viewport_rect.size.y

	var stage := GameManager.stage
	var wave_index := (stage - 1) % 5

	var base_count := roundi(4 + stage * 1.2)
	var normal_count := base_count
	var elite_count := 0
	var assassin_count := 0
	var rift_count := 0
	var snare_count := 0

	if wave_index == 2:
		elite_count = 1
	elif wave_index == 3:
		normal_count = roundi(base_count * 1.4)
	elif wave_index == 4:
		elite_count = mini(3, 1 + stage / 5)
		normal_count = maxi(2, roundi(base_count * 0.6))

	if stage >= 4:
		assassin_count = mini(3, 1 + (stage - 4) / 5)
		if wave_index == 3 and assassin_count > 1:
			assassin_count = 1

	if stage >= 6:
		rift_count = mini(2, 1 + (stage - 6) / 5)

	if stage >= 8:
		snare_count = mini(2, 1 + (stage - 8) / 5)

	enemies_in_wave = normal_count + elite_count + assassin_count + rift_count + snare_count
	enemies_killed_in_wave = 0

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

	var spawn_pos := _get_edge_spawn_position(w, h)
	enemy.global_position = spawn_pos

	enemy.initialize(current_wave_id, delay_ms)

	var center := Vector2(w / 2, h / 2)
	var angle := (center - spawn_pos).angle() + (GameManager.randf() - 0.5) * 0.5
	enemy.velocity = Vector2(cos(angle), sin(angle)) * enemy.base_speed

	if enemy_container:
		enemy_container.add_child(enemy)

	enemy.died.connect(_on_enemy_died)

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

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	enemy.add_child(collision)

	return enemy

func _check_wave_completion(now: int) -> void:
	var viewport_rect := get_viewport().get_visible_rect()

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

			var pos := enemy.global_position
			if pos.x < 0 or pos.x > viewport_rect.size.x or pos.y < 0 or pos.y > viewport_rect.size.y:
				all_on_screen = false

	current_wave_enemies = current_wave_enemies.filter(func(e): return is_instance_valid(e))

	if all_dead and current_wave_enemies.size() == 0:
		_complete_wave()

func _complete_wave() -> void:
	wave_complete = true
	no_kill_strikes = 0

	for rift in active_rifts:
		if is_instance_valid(rift):
			rift.queue_free()
	active_rifts.clear()

	wave_completed.emit(current_wave_id)

	GameManager.advance_stage()

	get_tree().create_timer(GameConstants.WAVE_TRANSITION_DELAY / 1000.0).timeout.connect(_on_wave_transition_complete)

func _on_wave_transition_complete() -> void:
	if GameManager.current_phase == GameManager.GamePhase.PLAYING:
		start_wave()

func _check_no_kill_penalty(now: int) -> void:

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

			_spawn_penalty_enemies()
			last_kill_at = now
		else:

			_complete_wave()

func _spawn_penalty_enemies() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var w := viewport_rect.size.x
	var h := viewport_rect.size.y

	for i in range(GameConstants.NO_KILL_EXTRA_SPAWN_COUNT):
		_spawn_enemy(EnemyBase.EnemyType.NORMAL, w, h, 0)

	penalty_enemies_spawned.emit(GameConstants.NO_KILL_EXTRA_SPAWN_COUNT)

func _update_rifts(now: int) -> void:
	for i in range(active_rifts.size() - 1, -1, -1):
		var rift = active_rifts[i]
		if not is_instance_valid(rift):
			active_rifts.remove_at(i)
			continue

func _on_rift_enemy_spawn_rift(spawn_pos: Vector2) -> void:

	if RiftPortalScene:
		var rift := RiftPortalScene.instantiate()
		rift.global_position = spawn_pos

		if rift_container:
			rift_container.add_child(rift)

		if rift.has_signal("minion_spawn_requested"):
			rift.minion_spawn_requested.connect(spawn_minion)

		active_rifts.append(rift)
		rift_spawned.emit(rift)
	else:

		spawn_minion(spawn_pos)

func _preload_scenes() -> void:

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

func _on_game_started(_seed: String) -> void:

	current_wave_id = 0
	enemies_in_wave = 0
	enemies_killed_in_wave = 0
	wave_complete = true
	no_kill_strikes = 0
	current_wave_enemies.clear()

	for rift in active_rifts:
		if is_instance_valid(rift):
			rift.queue_free()
	active_rifts.clear()

	start_wave()

func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:

		for enemy in current_wave_enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
		current_wave_enemies.clear()

		for rift in active_rifts:
			if is_instance_valid(rift):
				rift.queue_free()
		active_rifts.clear()

func _on_enemy_died(enemy: EnemyBase) -> void:
	on_enemy_killed(enemy)

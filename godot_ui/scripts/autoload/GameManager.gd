## GameManager.gd
## (comment removed due to encoding issues)
## (comment removed due to encoding issues)
##
## (comment removed due to encoding issues)
# (comment removed due to encoding issues)
## (comment removed due to encoding issues)
## (comment removed due to encoding issues)

extends Node

# ============================================================
# (comment removed due to encoding issues)
# ============================================================

## (comment removed due to encoding issues)
enum GamePhase {
	MENU,
	PLAYING,
	GAMEOVER
}

# ============================================================
# (comment removed due to encoding issues)
# ============================================================

## (comment removed due to encoding issues)
signal phase_changed(new_phase: GamePhase)

## (comment removed due to encoding issues)
signal score_updated(new_score: int)

## (comment removed due to encoding issues)
signal stage_updated(new_stage: int)

## (comment removed due to encoding issues)
signal mask_state_changed(is_masked: bool, shattered_kills: int)

## (comment removed due to encoding issues)
signal fever_updated(meter: float, is_active: bool)

## (comment removed due to encoding issues)
signal game_over(final_score: int, final_stage: int)

## (comment removed due to encoding issues)
signal game_started(seed_value: String)

## (comment removed due to encoding issues)
signal leaderboard_refresh_requested()

# ============================================================
# (comment removed due to encoding issues)
# ============================================================

const DEFAULT_PLAYER_NAME := "鏃犲悕鍒哄"
const FEVER_METER_MAX := 100.0
const SHATTERED_KILLS_TO_RESTORE := 3
const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"  ## 闈㈠叿鐮寸鍚庢仮澶嶆墍闇€鍑绘潃鏁?
# ============================================================
# (comment removed due to encoding issues)
# ============================================================

var game_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ============================================================
# (comment removed due to encoding issues)
# ============================================================

## (comment removed due to encoding issues)
var _current_phase: GamePhase = GamePhase.MENU
var current_phase: GamePhase:
	get: return _current_phase
	set(value):
		if _current_phase != value:
			_current_phase = value
			phase_changed.emit(value)

## (comment removed due to encoding issues)
var _score: int = 0
var score: int:
	get: return _score
	set(value):
		if _score != value:
			_score = value
			score_updated.emit(value)

## (comment removed due to encoding issues)
var _stage: int = 1
var stage: int:
	get: return _stage
	set(value):
		if _stage != value:
			_stage = value
			stage_updated.emit(value)

## (comment removed due to encoding issues)
var _is_masked: bool = true
var is_masked: bool:
	get: return _is_masked
	set(value):
		if _is_masked != value:
			_is_masked = value
			mask_state_changed.emit(_is_masked, _shattered_kills)

## (comment removed due to encoding issues)
var _shattered_kills: int = 0
var shattered_kills: int:
	get: return _shattered_kills
	set(value):
		if _shattered_kills != value:
			_shattered_kills = value
			mask_state_changed.emit(_is_masked, _shattered_kills)

## (comment removed due to encoding issues)
var _fever_meter: float = 0.0
var fever_meter: float:
	get: return _fever_meter
	set(value):
		var clamped := clampf(value, 0.0, FEVER_METER_MAX)
		if not is_equal_approx(_fever_meter, clamped):
			_fever_meter = clamped
			fever_updated.emit(_fever_meter, _fever_active)

## (comment removed due to encoding issues)
var _fever_active: bool = false
var fever_active: bool:
	get: return _fever_active
	set(value):
		if _fever_active != value:
			_fever_active = value
			fever_updated.emit(_fever_meter, _fever_active)

## Final score (recorded on game over)
var final_score: int = 0

## Final stage (recorded on game over)
var final_stage: int = 1

## Player name
var player_name: String = DEFAULT_PLAYER_NAME

## Whether current result is saved
var result_saved: bool = false

## Last saved player name (for highlight)
var last_saved_name: String = ""

## Current run seed
var current_seed: String = ""

# ============================================================
# (comment removed due to encoding issues)
# ============================================================

func _ready() -> void:
	# 鍒濆鍖栨椂閲嶇疆鐘舵€
	_reset_to_menu_state()
	print("[GameManager] Initialized")


	# ============================================================
	# 鍏叡鏂规硶 - 娓告垙娴佺▼鎺у埗
	# ============================================================

## (comment removed due to encoding issues)
func start_game() -> void:
	# 鐢熸垚鏂扮殑闅忔満绉嶅瓙
	current_seed = "%d-%s" % [Time.get_unix_time_from_system(), _generate_random_string(6)]
	_init_game_rng(current_seed)
	
	# 閲嶇疆娓告垙鐘舵€
	score = 0
	stage = 1
	is_masked = true
	shattered_kills = 0
	fever_meter = 0.0
	fever_active = false
	result_saved = false
	
	# 鍒囨崲鍒版父鎴忛樁娈
	current_phase = GamePhase.PLAYING
	
	# 鍙戦€佹父鎴忓紑濮嬩俊鍙
	game_started.emit(current_seed)
	
	print("[GameManager] Game started with seed: ", current_seed)


## (comment removed due to encoding issues)
func trigger_game_over() -> void:
	# 璁板綍鏈€缁堟垚缁
	final_score = score
	final_stage = stage
	result_saved = false
	
	# 鍒囨崲鍒扮粨绠楅樁娈
	current_phase = GamePhase.GAMEOVER
	
	# 鍙戦€佹父鎴忕粨鏉熶俊鍙
	game_over.emit(final_score, final_stage)
	
	print("[GameManager] Game over - Stage: %d, Score: %d" % [final_stage, final_score])


## (comment removed due to encoding issues)
func go_to_menu() -> void:
	_reset_to_menu_state()
	current_phase = GamePhase.MENU
	leaderboard_refresh_requested.emit()


## (comment removed due to encoding issues)
func mark_result_saved(saved_name: String) -> void:
	result_saved = true
	last_saved_name = saved_name


	# ============================================================
	# 鍏叡鏂规硶 - 娓告垙鐘舵€佹洿鏂
	# ============================================================

## (comment removed due to encoding issues)
func update_game_state(
	new_score: int,
	new_stage: int,
	new_is_masked: bool,
	new_shattered_kills: int,
	new_fever_meter: float,
	new_fever_active: bool
) -> void:
	score = new_score
	stage = new_stage
	is_masked = new_is_masked
	shattered_kills = new_shattered_kills
	fever_meter = new_fever_meter
	fever_active = new_fever_active


## (comment removed due to encoding issues)
func update_mask_state(new_is_masked: bool, new_shattered_kills: int) -> void:
	var changed := (is_masked != new_is_masked) or (shattered_kills != new_shattered_kills)
	is_masked = new_is_masked
	shattered_kills = new_shattered_kills
	if changed:
		mask_state_changed.emit(is_masked, shattered_kills)


## (comment removed due to encoding issues)
func update_fever_state(new_meter: float, new_active: bool) -> void:
	var changed := not is_equal_approx(fever_meter, new_meter) or (fever_active != new_active)
	fever_meter = clampf(new_meter, 0.0, FEVER_METER_MAX)
	fever_active = new_active
	if changed:
		fever_updated.emit(fever_meter, fever_active)


## (comment removed due to encoding issues)
func add_score(amount: int = 1) -> void:
	score += amount


## (comment removed due to encoding issues)
func advance_stage() -> void:
	stage += 1


## (comment removed due to encoding issues)
func shatter_mask() -> void:
	if is_masked:
		is_masked = false
		shattered_kills = 0
		fever_meter = 0.0
		fever_active = false


## (comment removed due to encoding issues)
func add_shattered_kill() -> void:
	if not is_masked:
		shattered_kills += 1
		if shattered_kills >= SHATTERED_KILLS_TO_RESTORE:
			# 鎭㈠闈㈠叿
			is_masked = true
			shattered_kills = 0


## (comment removed due to encoding issues)
func add_fever(amount: float) -> void:
	if is_masked and not fever_active:
		fever_meter = minf(fever_meter + amount, FEVER_METER_MAX)


## Activate Fever mode
func activate_fever() -> void:
	if is_masked and fever_meter >= FEVER_METER_MAX:
		fever_active = true


## (comment removed due to encoding issues)
func deactivate_fever() -> void:
	fever_active = false
	fever_meter = 0.0


	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

## (comment removed due to encoding issues)
func _reset_to_menu_state() -> void:
	score = 0
	stage = 1
	is_masked = true
	shattered_kills = 0
	fever_meter = 0.0
	fever_active = false
	final_score = 0
	final_stage = 1
	result_saved = false
	current_seed = ""


## (comment removed due to encoding issues)
func _init_game_rng(seed_value: String) -> void:
	var hashed := _hash_seed(seed_value)
	game_rng.seed = hashed


func _generate_random_string(length: int) -> String:
	var result := ""
	var temp_rng := RandomNumberGenerator.new()
	temp_rng.randomize()
	for i in range(length):
		result += CHARS[temp_rng.randi() % CHARS.length()]
	return result



## (comment removed due to encoding issues)
func _hash_seed(seed_value: String) -> int:
	if seed_value.is_empty():
		return int(Time.get_unix_time_from_system())
	return abs(seed_value.hash())


	# ============================================================
	# 鍏叡 RNG 鎺ュ彛锛堢敤浜庣帺娉曚竴鑷存€э級
	# ============================================================

func randf() -> float:
	return game_rng.randf()


func randf_range(min_value: float, max_value: float) -> float:
	return game_rng.randf_range(min_value, max_value)


func randi() -> int:
	return game_rng.randi()


func randi_range(min_value: int, max_value: int) -> int:
	return game_rng.randi_range(min_value, max_value)

extends Node

enum GamePhase {
	MENU,
	PLAYING,
	GAMEOVER
}

signal phase_changed(new_phase: GamePhase)

signal score_updated(new_score: int)

signal stage_updated(new_stage: int)

signal mask_state_changed(is_masked: bool, shattered_kills: int)

signal fever_updated(meter: float, is_active: bool)

signal game_over(final_score: int, final_stage: int)

signal game_started(seed_value: String)

signal leaderboard_refresh_requested()

const DEFAULT_PLAYER_NAME := "无名刺客"
const FEVER_METER_MAX := 100.0
const SHATTERED_KILLS_TO_RESTORE := 3
const CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

var game_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _current_phase: GamePhase = GamePhase.MENU
var current_phase: GamePhase:
	get: return _current_phase
	set(value):
		if _current_phase != value:
			_current_phase = value
			phase_changed.emit(value)

var _score: int = 0
var score: int:
	get: return _score
	set(value):
		if _score != value:
			_score = value
			score_updated.emit(value)

var _stage: int = 1
var stage: int:
	get: return _stage
	set(value):
		if _stage != value:
			_stage = value
			stage_updated.emit(value)

var _is_masked: bool = true
var is_masked: bool:
	get: return _is_masked
	set(value):
		if _is_masked != value:
			_is_masked = value
			mask_state_changed.emit(_is_masked, _shattered_kills)

var _shattered_kills: int = 0
var shattered_kills: int:
	get: return _shattered_kills
	set(value):
		if _shattered_kills != value:
			_shattered_kills = value
			mask_state_changed.emit(_is_masked, _shattered_kills)

var _fever_meter: float = 0.0
var fever_meter: float:
	get: return _fever_meter
	set(value):
		var clamped := clampf(value, 0.0, FEVER_METER_MAX)
		if not is_equal_approx(_fever_meter, clamped):
			_fever_meter = clamped
			fever_updated.emit(_fever_meter, _fever_active)

var _fever_active: bool = false
var fever_active: bool:
	get: return _fever_active
	set(value):
		if _fever_active != value:
			_fever_active = value
			fever_updated.emit(_fever_meter, _fever_active)

var final_score: int = 0

var final_stage: int = 1

var player_name: String = DEFAULT_PLAYER_NAME

var result_saved: bool = false

var last_saved_name: String = ""

var current_seed: String = ""

func _ready() -> void:

	_ensure_input_map()
	_reset_to_menu_state()
	print("[GameManager] Initialized")

func start_game() -> void:

	current_seed = "%d-%s" % [Time.get_unix_time_from_system(), _generate_random_string(6)]
	_init_game_rng(current_seed)

	score = 0
	stage = 1
	is_masked = true
	shattered_kills = 0
	fever_meter = 0.0
	fever_active = false
	result_saved = false

	current_phase = GamePhase.PLAYING

	game_started.emit(current_seed)

	print("[GameManager] Game started with seed: ", current_seed)

func trigger_game_over() -> void:

	final_score = score
	final_stage = stage
	result_saved = false

	current_phase = GamePhase.GAMEOVER

	game_over.emit(final_score, final_stage)

	print("[GameManager] Game over - Stage: %d, Score: %d" % [final_stage, final_score])

func go_to_menu() -> void:
	_reset_to_menu_state()
	current_phase = GamePhase.MENU
	leaderboard_refresh_requested.emit()

func mark_result_saved(saved_name: String) -> void:
	result_saved = true
	last_saved_name = saved_name

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

func update_mask_state(new_is_masked: bool, new_shattered_kills: int) -> void:
	var changed := (is_masked != new_is_masked) or (shattered_kills != new_shattered_kills)
	is_masked = new_is_masked
	shattered_kills = new_shattered_kills
	if changed:
		mask_state_changed.emit(is_masked, shattered_kills)

func update_fever_state(new_meter: float, new_active: bool) -> void:
	var changed := not is_equal_approx(fever_meter, new_meter) or (fever_active != new_active)
	fever_meter = clampf(new_meter, 0.0, FEVER_METER_MAX)
	fever_active = new_active
	if changed:
		fever_updated.emit(fever_meter, fever_active)

func add_score(amount: int = 1) -> void:
	score += amount

func advance_stage() -> void:
	stage += 1

func shatter_mask() -> void:
	if is_masked:
		is_masked = false
		shattered_kills = 0
		fever_meter = 0.0
		fever_active = false

func add_shattered_kill() -> void:
	if not is_masked:
		shattered_kills += 1
		if shattered_kills >= SHATTERED_KILLS_TO_RESTORE:

			is_masked = true
			shattered_kills = 0

func add_fever(amount: float) -> void:
	if is_masked and not fever_active:
		fever_meter = minf(fever_meter + amount, FEVER_METER_MAX)

func activate_fever() -> void:
	if is_masked and fever_meter >= FEVER_METER_MAX:
		fever_active = true

func deactivate_fever() -> void:
	fever_active = false
	fever_meter = 0.0

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

func _init_game_rng(seed_value: String) -> void:
	var hashed := _hash_seed(seed_value)
	game_rng.seed = hashed

func _ensure_input_map() -> void:
	_ensure_action("move_up", [KEY_W, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])

func _ensure_action(action: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action, event)

func _generate_random_string(length: int) -> String:
	var result := ""
	var temp_rng := RandomNumberGenerator.new()
	temp_rng.randomize()
	for i in range(length):
		result += CHARS[temp_rng.randi() % CHARS.length()]
	return result

func _hash_seed(seed_value: String) -> int:
	if seed_value.is_empty():
		return int(Time.get_unix_time_from_system())
	return abs(seed_value.hash())

func randf() -> float:
	return game_rng.randf()

func randf_range(min_value: float, max_value: float) -> float:
	return game_rng.randf_range(min_value, max_value)

func randi() -> int:
	return game_rng.randi()

func randi_range(min_value: int, max_value: int) -> int:
	return game_rng.randi_range(min_value, max_value)

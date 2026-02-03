

extends Node
class_name FeverSystem

signal fever_meter_updated(meter: float, max_meter: float)

signal fever_activated()

signal fever_deactivated()

signal fever_flash_requested(type: String)

var fever_meter: float = 0.0

var fever_active: bool = false

var fever_until: int = 0

var _last_wave_complete: bool = false

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)

func _process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return

	var now := Time.get_ticks_msec()

	if fever_active:

		if now >= fever_until:
			_deactivate_fever()

func add_fever(amount: float, combo_level: int = 0) -> void:

	if not GameManager.is_masked or fever_active:
		return

	var combo_bonus := 1.0 + combo_level * GameConstants.FEVER_GAIN_COMBO_BONUS
	var final_amount := amount * combo_bonus

	fever_meter = minf(fever_meter + final_amount, GameConstants.FEVER_METER_MAX)
	fever_meter_updated.emit(fever_meter, GameConstants.FEVER_METER_MAX)

	GameManager
	GameManager.fever_meter = fever_meter
	GameManager.fever_updated.emit(fever_meter, fever_active)

	if fever_meter >= GameConstants.FEVER_METER_MAX:
		_activate_fever()

func get_fever_percent() -> float:
	return fever_meter / GameConstants.FEVER_METER_MAX * 100.0

func get_fever_remaining_ms() -> int:
	if not fever_active:
		return 0
	return maxi(0, fever_until - Time.get_ticks_msec())

func get_fever_remaining_ratio() -> float:
	if not fever_active:
		return 0.0
	var remaining := float(get_fever_remaining_ms())
	return remaining / GameConstants.FEVER_DURATION_MS

func is_fever_active() -> bool:
	return fever_active

func force_activate() -> void:
	fever_meter = GameConstants.FEVER_METER_MAX
	_activate_fever()

func force_deactivate() -> void:
	if fever_active:
		_deactivate_fever()

func reset() -> void:
	fever_meter = 0.0
	fever_active = false
	fever_until = 0

	GameManager
	GameManager.fever_meter = 0.0
	GameManager.fever_active = false

func on_mask_broken() -> void:
	if fever_active or fever_meter > 0:
		fever_meter = 0.0
		fever_active = false
		fever_until = 0

		fever_flash_requested.emit("out")
		fever_deactivated.emit()

		GameManager
		GameManager.fever_meter = 0.0
		GameManager.fever_active = false
		GameManager.fever_updated.emit(0.0, false)

func extend_fever(extra_ms: int) -> void:
	if fever_active:
		fever_until += extra_ms

func _activate_fever() -> void:
	var now := Time.get_ticks_msec()

	fever_active = true
	fever_until = now + GameConstants.FEVER_DURATION_MS

	fever_activated.emit()
	fever_flash_requested.emit("in")

	GameManager
	GameManager.fever_active = true
	GameManager.activate_fever()

	AudioManager.play_fever_start()

func _deactivate_fever() -> void:
	fever_active = false
	fever_meter = 0.0
	fever_until = 0

	fever_deactivated.emit()
	fever_flash_requested.emit("out")
	fever_meter_updated.emit(0.0, GameConstants.FEVER_METER_MAX)

	GameManager
	GameManager.fever_active = false
	GameManager.fever_meter = 0.0
	GameManager.deactivate_fever()

	AudioManager.play_fever_end()

func _on_game_started(_seed: String) -> void:
	reset()

func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		reset()



extends Node
class_name ComboSystem

signal combo_updated(count: int, level: int)

signal combo_reset()

signal mark_intensity_updated(intensity: float)

signal hit_stop_started(duration_ms: int)

signal hit_stop_ended()

signal screen_shake_requested(magnitude: float, duration_ms: int)

signal kill_text_requested(position: Vector2, kills: int, combo_level: int)

signal impact_flash_requested(color: Color, alpha: float, duration_ms: int)

signal combo_announcement_requested(text: String, scale: float, color: Color)

var combo_count: int = 0

var combo_until: int = 0

var mark_count: int = 0

var mark_intensity: float = 0.0

var hit_stop_until: int = 0

var _in_hit_stop: bool = false

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)

func _process(delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return

	var now := Time.get_ticks_msec()

	if combo_count > 0 and now > combo_until:
		_reset_combo()

	_update_mark_intensity(delta)

	if _in_hit_stop and now >= hit_stop_until:
		_in_hit_stop = false
		hit_stop_ended.emit()

func add_kills(kill_count: int, position: Vector2, kills_this_dash: int) -> void:
	if kill_count <= 0:
		return

	var now := Time.get_ticks_msec()

	if now > combo_until:
		combo_count = kill_count
	else:
		combo_count += kill_count

	combo_until = now + GameConstants.COMBO_WINDOW_MS

	mark_count = mini(GameConstants.MARK_MAX, mark_count + kill_count)

	var combo_level := GameConstants.get_combo_level(combo_count)

	combo_updated.emit(combo_count, combo_level)

	var shake_magnitude: float = GameConstants.COMBO_SHAKE_MAGNITUDE[combo_level]
	screen_shake_requested.emit(shake_magnitude, GameConstants.SCREEN_SHAKE_DURATION)

	kill_text_requested.emit(position, kills_this_dash, combo_level)

	if combo_level >= 3:
		var flash_color := Color(1.0, 0.47, 0.35) if combo_level >= 5 else Color(1.0, 0.78, 0.55)
		impact_flash_requested.emit(flash_color, GameConstants.KILL_IMPACT_FLASH_ALPHA, GameConstants.KILL_IMPACT_FLASH_DURATION)

	_show_combo_announcement(combo_level)

func trigger_hit_stop(combo_level: int) -> void:
	var now := Time.get_ticks_msec()
	var duration: int = GameConstants.COMBO_HIT_STOP_MS[combo_level]

	hit_stop_until = maxi(hit_stop_until, now + duration)

	if not _in_hit_stop:
		_in_hit_stop = true
		hit_stop_started.emit(duration)

func is_hit_stopped() -> bool:
	return _in_hit_stop

func get_combo_level() -> int:
	return GameConstants.get_combo_level(combo_count)

func get_combo_count() -> int:
	return combo_count

func get_mark_count() -> int:
	return mark_count

func get_mark_intensity() -> float:
	return mark_intensity

func reset() -> void:
	combo_count = 0
	combo_until = 0
	mark_count = 0
	mark_intensity = 0.0
	hit_stop_until = 0
	_in_hit_stop = false

func _reset_combo() -> void:
	combo_count = 0
	mark_count = 0
	combo_reset.emit()

func _update_mark_intensity(delta: float) -> void:
	var target := float(mark_count) / GameConstants.MARK_MAX
	target = clampf(target, 0.0, 1.0)

	var lerp_speed := 0.12 if target > mark_intensity else 0.2
	mark_intensity = lerpf(mark_intensity, target, lerp_speed)

	if mark_intensity < 0.002:
		mark_intensity = 0.0

	mark_intensity_updated.emit(mark_intensity)

func _show_combo_announcement(combo_level: int) -> void:
	var combo_text: String
	if combo_count >= 8:
		combo_text = "COMBO x8+"
	else:
		combo_text = "COMBO x%d" % combo_count

	var mark_text := ""
	if mark_count >= GameConstants.MARK_MAX:
		mark_text = "MARK MAX"
	elif mark_count > 0:
		mark_text = "MARK %d" % mark_count

	var display := combo_text
	if mark_text != "":
		display = "%s | %s" % [combo_text, mark_text]

	var scale: float = GameConstants.COMBO_BADGE_SCALE[combo_level]
	var color: Color = GameConstants.COMBO_BADGE_COLOR[combo_level]

	combo_announcement_requested.emit(display, scale, color)

func _on_game_started(_seed: String) -> void:
	reset()

func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		reset()

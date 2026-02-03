

extends Node2D
class_name RiftPortal

signal minion_spawn_requested(position: Vector2)

signal rift_closed()

@export var radius: float = GameConstants.RIFT_RADIUS + 6

var _created_at: int = 0
var _open_at: int = 0
var _end_at: int = 0
var _next_spawn_at: int = 0
var _is_active: bool = true

func _ready() -> void:
	var now := Time.get_ticks_msec()
	_created_at = now
	_open_at = now + GameConstants.RIFT_WARNING_MS
	_end_at = now + GameConstants.RIFT_WARNING_MS + GameConstants.RIFT_DURATION_MS
	_next_spawn_at = _open_at

func _process(_delta: float) -> void:
	if not _is_active:
		return

	var now := Time.get_ticks_msec()

	if now >= _end_at:
		_is_active = false
		rift_closed.emit()
		queue_free()
		return

	if now >= _open_at and now >= _next_spawn_at:
		minion_spawn_requested.emit(global_position)
		_next_spawn_at = now + GameConstants.RIFT_SPAWN_INTERVAL_MS

	queue_redraw()

func _draw() -> void:
	if not _is_active:
		return

	var now := Time.get_ticks_msec()
	var is_open := now >= _open_at

	var warning_t: float
	if is_open:
		warning_t = 1.0
	else:
		warning_t = 1.0 - maxf(0, float(_open_at - now) / GameConstants.RIFT_WARNING_MS)

	var pulse := 0.6 + sin(float(now) / 140.0) * 0.4
	var current_radius := radius + 6 * pulse

	var glow_alpha := 0.75 if is_open else 0.45 * warning_t
	var glow_color := Color(GameConstants.RIFT_COLOR.r, GameConstants.RIFT_COLOR.g, GameConstants.RIFT_COLOR.b, glow_alpha)

	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, glow_color, 3.0)

	if is_open:
		var inner_color := Color(GameConstants.RIFT_COLOR.r, GameConstants.RIFT_COLOR.g, GameConstants.RIFT_COLOR.b, 0.25)
		draw_circle(Vector2.ZERO, current_radius * 0.6, inner_color)

func is_open() -> bool:
	return Time.get_ticks_msec() >= _open_at

func get_remaining_ratio() -> float:
	var now := Time.get_ticks_msec()
	if now < _open_at:
		return 1.0
	var total := _end_at - _open_at
	var remaining := _end_at - now
	return maxf(0, float(remaining) / total)

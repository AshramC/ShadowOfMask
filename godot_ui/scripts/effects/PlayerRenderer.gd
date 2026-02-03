

extends Node2D
class_name PlayerRenderer

var player: Player

@export var player_size: float = GameConstants.PLAYER_SIZE
@export var normal_color: Color = GameConstants.COLOR_PLAYER
@export var fever_color: Color = Color(1, 0.85, 0.5)
@export var shattered_color: Color = Color(0.6, 0.6, 0.6)

func _ready() -> void:
	var parent := get_parent()
	if parent is Player:
		player = parent

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if player == null:
		_draw_placeholder()
		return

	var now := Time.get_ticks_msec()
	var half := player_size / 2.0

	var color := _get_current_color()
	var alpha := _get_current_alpha(now)
	color.a = alpha

	var rect := Rect2(-half, -half, player_size, player_size)

	if player.is_dashing():
		_draw_dash_effect(rect, color, now)
	else:
		_draw_normal(rect, color, now)

	_draw_mask_indicator(half, now)

func _draw_placeholder() -> void:
	var half := player_size / 2.0
	var rect := Rect2(-half, -half, player_size, player_size)
	draw_rect(rect, normal_color)

func _draw_normal(rect: Rect2, color: Color, now: int) -> void:

	draw_rect(rect, color)

	if GameManager.fever_active:
		var pulse := 0.5 + sin(float(now) / 100.0) * 0.3
		var glow_size := player_size + 8 * pulse
		var glow_half := glow_size / 2.0
		var glow_rect := Rect2(-glow_half, -glow_half, glow_size, glow_size)
		var glow_color := Color(fever_color.r, fever_color.g, fever_color.b, 0.3 * pulse)
		draw_rect(glow_rect, glow_color, false, 3.0)

	if player.is_pending_dash():
		var progress := player.get_pending_progress()
		var indicator_size := player_size * (1.0 + progress * 0.3)
		var indicator_half := indicator_size / 2.0
		var indicator_rect := Rect2(-indicator_half, -indicator_half, indicator_size, indicator_size)
		var indicator_alpha := 0.3 + progress * 0.4
		draw_rect(indicator_rect, Color(1, 1, 1, indicator_alpha), false, 2.0)

func _draw_dash_effect(rect: Rect2, color: Color, now: int) -> void:

	var glow_size := player_size + 6
	var glow_half := glow_size / 2.0
	var glow_rect := Rect2(-glow_half, -glow_half, glow_size, glow_size)
	var glow_color := Color(1, 1, 1, 0.5)
	draw_rect(glow_rect, glow_color, false, 2.0)

	draw_rect(rect, color)

func _draw_mask_indicator(half: float, now: int) -> void:
	if GameManager.is_masked:

		var mark_size := 4.0
		var mark_pos := Vector2(-half - 2, -half - 2)
		draw_rect(Rect2(mark_pos.x, mark_pos.y, mark_size, mark_size), Color.WHITE)
	else:

		var kills: int = GameManager.shattered_kills
		var max_kills := 3

		for i in range(max_kills):
			var indicator_x := -half + i * 8
			var indicator_y := -half - 8
			var filled: float = i < kills
			var indicator_color := Color.WHITE if filled else Color(1, 1, 1, 0.3)
			draw_rect(Rect2(indicator_x, indicator_y, 6, 4), indicator_color)

func _get_current_color() -> Color:
	if GameManager.fever_active:
		return fever_color
	elif not GameManager.is_masked:
		return shattered_color
	else:
		return normal_color

func _get_current_alpha(now: int) -> float:
	if player == null:
		return 1.0

	if player.is_invulnerable():
		var flash := sin(float(now) / 50.0)
		return 0.4 + flash * 0.3

	return 1.0

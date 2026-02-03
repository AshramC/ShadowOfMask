

extends Node2D
class_name DashIndicator

@export var line_color: Color = Color(1, 1, 1, 0.5)
@export var circle_color: Color = Color(1, 1, 1, 0.8)
@export var circle_radius: float = 15.0
@export var line_dash_length: float = 5.0

var is_active: bool = false
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var progress: float = 0.0
var delay_seconds: float = 0.0

func _process(_delta: float) -> void:
	if is_active:
		queue_redraw()

func _draw() -> void:
	if not is_active:
		return

	var alpha := 0.3 + progress * 0.5

	var dir := (target_pos - start_pos).normalized()
	var dist := start_pos.distance_to(target_pos)
	var dash_color := Color(line_color.r, line_color.g, line_color.b, alpha)

	var pos := start_pos
	var drawn := 0.0
	var is_dash := true

	while drawn < dist:
		var segment_len := minf(line_dash_length, dist - drawn)
		if is_dash:
			var end_pos := pos + dir * segment_len
			draw_line(pos, end_pos, dash_color, 2.0)
		pos += dir * segment_len
		drawn += segment_len
		is_dash = not is_dash

	var circle_r := circle_radius * progress
	var c_color := Color(circle_color.r, circle_color.g, circle_color.b, alpha)
	draw_arc(target_pos, circle_r, 0, TAU, 32, c_color, 2.0)

	var remain := maxf(delay_seconds * (1.0 - progress), 0)
	var text := "%.1fs" % remain
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	var text_pos := target_pos - Vector2(text_size.x / 2, 25)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)

func show_indicator(from: Vector2, to: Vector2, delay_ms: float) -> void:
	is_active = true
	start_pos = from
	target_pos = to
	progress = 0.0
	delay_seconds = delay_ms / 1000.0
	queue_redraw()

func update_progress(p: float) -> void:
	progress = clampf(p, 0.0, 1.0)
	queue_redraw()

func hide_indicator() -> void:
	is_active = false
	queue_redraw()

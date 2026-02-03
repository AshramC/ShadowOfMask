

extends Control
class_name ComboAnnouncement

var _text: String = ""
var _scale: float = 1.0
var _color: Color = Color.WHITE
var _life: float = 0.0

const MARGIN := 22
const PADDING_X := 10
const BADGE_HEIGHT := 24
const FONT_SIZE := 14
const CORNER_RADIUS := 8

func _ready() -> void:

	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _life > 0:
		_life -= 0.01
		if _life <= 0:
			_text = ""
		queue_redraw()

func _draw() -> void:
	if _life <= 0 or _text.is_empty():
		return

	var life := minf(_life, 1.0)
	var progress := minf(1.0 - life, 1.0)
	var enter := minf(progress * 4, 1.0)
	var ease_out := 1.0 - pow(1.0 - minf(progress, 1.0), 2)
	var alpha := life * enter

	var font := ThemeDB.fallback_font
	var font_size_scaled := int(FONT_SIZE * _scale)
	var text_upper := _text.to_upper()
	var text_width := font.get_string_size(text_upper, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_scaled).x
	var badge_width := text_width + PADDING_X * 2 * _scale
	var badge_height := BADGE_HEIGHT * _scale

	var rise := ease_out * 8
	var slide := (1.0 - enter) * 12
	var viewport_size := get_viewport().get_visible_rect().size
	var x := viewport_size.x - MARGIN - badge_width + slide
	var y := MARGIN + rise

	var bg_color := Color(0, 0, 0, 0.55 * alpha)
	var bg_rect := Rect2(x, y, badge_width, badge_height)
	draw_rect(bg_rect, bg_color, true)

	var border_color := Color(1, 1, 1, 0.18 * alpha)
	draw_rect(bg_rect, border_color, false, 1.0)

	var text_color := Color(_color.r, _color.g, _color.b, alpha)
	var text_pos := Vector2(x + PADDING_X * _scale, y + badge_height / 2 + font_size_scaled / 3)
	draw_string(font, text_pos, text_upper, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_scaled, text_color)

func show_announcement(text: String, scale: float, color: Color) -> void:
	_text = text
	_scale = scale
	_color = color
	_life = 1.0
	queue_redraw()

func hide_announcement() -> void:
	_life = 0
	_text = ""
	queue_redraw()

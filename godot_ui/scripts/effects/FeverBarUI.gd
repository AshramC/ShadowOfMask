## FeverBarUI.gd
## Fever 杩涘害鏉
# UI
## 鏄剧ず Fever 鑳介噺鍜屾縺娲荤姸鎬?
extends Control
class_name FeverBarUI

# ============================================================
# 閰嶇疆
# ============================================================

const MARGIN := 22
const BADGE_WIDTH := 150
const BADGE_HEIGHT := 24
const CORNER_RADIUS := 8
const BAR_HEIGHT := 8

# ============================================================
# 鐘舵€
# ============================================================

var _meter: float = 0.0
var _max_meter: float = GameConstants.FEVER_METER_MAX
var _is_active: bool = false
var _remaining_ratio: float = 0.0

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 杩炴帴 GameManager 淇″彿
	GameManager.fever_updated.connect(_on_fever_updated)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# 濡傛灉娌℃湁 Fever 鑳介噺涓旀湭婵€娲伙紝涓嶆樉绀
	if _meter <= 0 and not _is_active:
		return
	
	var x := float(MARGIN)
	var y := float(MARGIN)
	var now := Time.get_ticks_msec()
	var pulse := 0.5 + sin(float(now) / 140.0) * 0.5
	
	# 缁樺埗鑳屾櫙
	var bg_color := Color(0.047, 0.031, 0, 0.55)
	var bg_rect := Rect2(x, y, BADGE_WIDTH, BADGE_HEIGHT)
	draw_rect(bg_rect, bg_color, true)
	
	# 缁樺埗杈规
	var border_color := Color(1, 0.84, 0.55, 0.55)
	draw_rect(bg_rect, border_color, false, 1.0)
	
	# 缁樺埗 "FEVER" 鏂囧瓧
	var font := ThemeDB.fallback_font
	var text_color := Color(1, 0.84, 0.55, 0.95)
	var text_pos := Vector2(x + 10, y + BADGE_HEIGHT / 2 + 4)
	draw_string(font, text_pos, "FEVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_color)
	
	# 缁樺埗杩涘害鏉
	var bar_x := x + 64
	var bar_y := y + BADGE_HEIGHT / 2 - BAR_HEIGHT / 2
	var bar_w := BADGE_WIDTH - 74
	
	# 鑳屾櫙鏉
	var bar_bg_color := Color(1, 0.84, 0.55, 0.2)
	var bar_bg_rect := Rect2(bar_x, bar_y, bar_w, BAR_HEIGHT)
	draw_rect(bar_bg_rect, bar_bg_color, true)
	
	# 濉厖鏉
	var ratio: float
	if _is_active:
		ratio = _remaining_ratio
	else:
		ratio = _meter / _max_meter
	
	var fill_w := maxf(2, bar_w * ratio)
	var fill_alpha := 0.65 + pulse * 0.2 if _is_active else 0.8
	var fill_color := Color(1, 0.78, 0.35, fill_alpha)
	var fill_rect := Rect2(bar_x, bar_y, fill_w, BAR_HEIGHT)
	draw_rect(fill_rect, fill_color, true)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鏇存柊 Fever 鐘舵€
func update_fever(meter: float, active: bool, remaining_ratio: float = 1.0) -> void:
	_meter = meter
	_is_active = active
	_remaining_ratio = remaining_ratio
	queue_redraw()


	# ============================================================
	# 淇″彿鍥炶皟
	# ============================================================

func _on_fever_updated(meter: float, active: bool) -> void:
	_meter = meter
	_is_active = active
	queue_redraw()


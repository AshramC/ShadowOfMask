## KillText.gd
## 鍑绘潃鏂囧瓧鏁堟灉
## 鏄剧ず "X kills" 鏂囧瓧锛屽甫寮瑰嚭鍜屼笂鍗囧姩鐢?
extends Node2D
class_name KillText

# ============================================================
# 閰嶇疆
# ============================================================

var text: String = "1 kill"
var font_size: int = 14
var text_color: Color = Color.WHITE
var pop_scale: float = 1.05
var rise_speed: float = 0.9

# ============================================================
# 鐘舵€
# ============================================================

var _life: float = 1.0
var _pop_life: float = 1.0
var _y_offset: float = 0.0

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	# 鏇存柊鐢熷懡鍛ㄦ湡
	_life -= 0.02
	_pop_life = maxf(0, _pop_life - 0.08)
	_y_offset += rise_speed
	
	if _life <= 0:
		queue_free()
		return
	
	queue_redraw()


func _draw() -> void:
	if _life <= 0:
		return
	
	# 璁＄畻缂╂斁
	var current_scale := 1.0 + _pop_life * (pop_scale - 1.0)
	
	# 璁剧疆瀛椾綋
	var font := ThemeDB.fallback_font
	var font_size_scaled := int(font_size * current_scale)
	
	# 璁＄畻浣嶇疆锛堝眳涓級
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_scaled)
	var draw_pos := Vector2(-text_size.x / 2, -_y_offset)
	
	# 缁樺埗鎻忚竟
	var outline_color := Color(0, 0, 0, 0.6 * _life)
	for offset in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		draw_string(font, draw_pos + offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_scaled, outline_color)
	
	# 缁樺埗鏂囧瓧
	var final_color := Color(text_color.r, text_color.g, text_color.b, _life)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_scaled, final_color)


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鍒濆鍖栧嚮鏉€鏂囧瓧
func setup(kills: int, combo_level: int) -> void:
	text = "1 kill" if kills == 1 else "%d kills" % kills
	font_size = GameConstants.KILL_TEXT_SIZES[combo_level]
	text_color = GameConstants.KILL_TEXT_COLORS[combo_level]
	pop_scale = GameConstants.KILL_TEXT_POP_SCALE[combo_level]
	rise_speed = GameConstants.KILL_TEXT_RISE[combo_level]

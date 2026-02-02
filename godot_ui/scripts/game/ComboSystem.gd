## ComboSystem.gd
## Combo 绯荤粺
## 璐熻矗绠＄悊杩炲嚮璁℃暟銆丮ark 寮哄害銆丠it Stop銆佸睆骞曢渿鍔?
extends Node
class_name ComboSystem

# ============================================================
# 淇″彿
# ============================================================

## Combo 鏇存柊
signal combo_updated(count: int, level: int)

## Combo 閲嶇疆
signal combo_reset()

## Mark 寮哄害鏇存柊
signal mark_intensity_updated(intensity: float)

## Hit Stop 寮€濮
signal hit_stop_started(duration_ms: int)

## Hit Stop 缁撴潫
signal hit_stop_ended()

## 灞忓箷闇囧姩
signal screen_shake_requested(magnitude: float, duration_ms: int)

## 鍑绘潃鏂囧瓧
signal kill_text_requested(position: Vector2, kills: int, combo_level: int)

## 鍐插嚮闂厜
signal impact_flash_requested(color: Color, alpha: float, duration_ms: int)

## Combo 鍏憡
signal combo_announcement_requested(text: String, scale: float, color: Color)

# ============================================================
# 鐘舵€
# ============================================================

## 褰撳墠 Combo 鏁
var combo_count: int = 0

## Combo 鎴鏃堕棿
var combo_until: int = 0

## Mark 鏁伴噺
var mark_count: int = 0

## Mark 寮哄害锛堢敤浜庤瑙夋晥鏋滐級
var mark_intensity: float = 0.0

## Hit Stop 鎴鏃堕棿
var hit_stop_until: int = 0

## 鏄惁鍦
# Hit Stop 涓
var _in_hit_stop: bool = false

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)


func _process(delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	var now := Time.get_ticks_msec()
	
	# 妫€鏌
	# Combo 瓒呮椂
	if combo_count > 0 and now > combo_until:
		_reset_combo()
	
	# 鏇存柊 Mark 寮哄害锛堝钩婊戞彃鍊硷級
	_update_mark_intensity(delta)
	
	# 妫€鏌
	# Hit Stop 缁撴潫
	if _in_hit_stop and now >= hit_stop_until:
		_in_hit_stop = false
		hit_stop_ended.emit()


		# ============================================================
		# 鍏叡鏂规硶
		# ============================================================

## 娣诲姞鍑绘潃锛堜竴娆″啿鍒轰腑鐨勫嚮鏉€锛
func add_kills(kill_count: int, position: Vector2, kills_this_dash: int) -> void:
	if kill_count <= 0:
		return
	
	var now := Time.get_ticks_msec()
	
	# 鏇存柊 Combo
	if now > combo_until:
		combo_count = kill_count
	else:
		combo_count += kill_count
	
	combo_until = now + GameConstants.COMBO_WINDOW_MS
	
	# 鏇存柊 Mark
	mark_count = mini(GameConstants.MARK_MAX, mark_count + kill_count)
	
	var combo_level := GameConstants.get_combo_level(combo_count)
	
	# 鍙戝嚭淇″彿
	combo_updated.emit(combo_count, combo_level)
	
	# 灞忓箷闇囧姩
	var shake_magnitude: float = GameConstants.COMBO_SHAKE_MAGNITUDE[combo_level]
	screen_shake_requested.emit(shake_magnitude, GameConstants.SCREEN_SHAKE_DURATION)
	
	# 鍑绘潃鏂囧瓧
	kill_text_requested.emit(position, kills_this_dash, combo_level)
	
	# 楂樼瓑绾
	# Combo 鏁堟灉
	if combo_level >= 3:
		var flash_color := Color(1.0, 0.47, 0.35) if combo_level >= 5 else Color(1.0, 0.78, 0.55)
		impact_flash_requested.emit(flash_color, GameConstants.KILL_IMPACT_FLASH_ALPHA, GameConstants.KILL_IMPACT_FLASH_DURATION)
	
	# Combo 鍏憡
	_show_combo_announcement(combo_level)
	
	# Hit Stop锛堟瘡娆″啿鍒哄彧瑙﹀彂涓€娆★級
	# 鐢辫皟鐢ㄨ€呮帶鍒舵槸鍚﹁Е鍙?

## 瑙﹀彂 Hit Stop
func trigger_hit_stop(combo_level: int) -> void:
	var now := Time.get_ticks_msec()
	var duration: int = GameConstants.COMBO_HIT_STOP_MS[combo_level]
	
	hit_stop_until = maxi(hit_stop_until, now + duration)
	
	if not _in_hit_stop:
		_in_hit_stop = true
		hit_stop_started.emit(duration)


## 鏄惁鍦
# Hit Stop 涓
func is_hit_stopped() -> bool:
	return _in_hit_stop


## 鑾峰彇褰撳墠 Combo 绛夌骇
func get_combo_level() -> int:
	return GameConstants.get_combo_level(combo_count)


## 鑾峰彇褰撳墠 Combo 鏁
func get_combo_count() -> int:
	return combo_count


## 鑾峰彇 Mark 鏁伴噺
func get_mark_count() -> int:
	return mark_count


## 鑾峰彇 Mark 寮哄害
func get_mark_intensity() -> float:
	return mark_intensity


## 閲嶇疆绯荤粺
func reset() -> void:
	combo_count = 0
	combo_until = 0
	mark_count = 0
	mark_intensity = 0.0
	hit_stop_until = 0
	_in_hit_stop = false


	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

func _reset_combo() -> void:
	combo_count = 0
	mark_count = 0
	combo_reset.emit()


func _update_mark_intensity(delta: float) -> void:
	var target := float(mark_count) / GameConstants.MARK_MAX
	target = clampf(target, 0.0, 1.0)
	
	# 涓婂崌蹇紝涓嬮檷鎱
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


	# ============================================================
	# 淇″彿鍥炶皟
	# ============================================================

func _on_game_started(_seed: String) -> void:
	reset()


func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		reset()



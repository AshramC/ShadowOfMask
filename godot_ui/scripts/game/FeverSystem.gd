## FeverSystem.gd
## Fever 绯荤粺
## 璐熻矗绠＄悊 Fever 鑳介噺绉疮銆佹縺娲荤姸鎬併€佹寔缁椂闂?
extends Node
class_name FeverSystem

# ============================================================
# 淇″彿
# ============================================================

## Fever 鑳介噺鏇存柊
signal fever_meter_updated(meter: float, max_meter: float)

## Fever 婵€娲
signal fever_activated()

## Fever 缁撴潫
signal fever_deactivated()

## Fever 闂厜鏁堟灉
signal fever_flash_requested(type: String)  ## "in" 鎴?"out"

# ============================================================
# 鐘舵€
# ============================================================

## 褰撳墠 Fever 鑳介噺
var fever_meter: float = 0.0

## Fever 鏄惁婵€娲
var fever_active: bool = false

## Fever 缁撴潫鏃堕棿
var fever_until: int = 0

## 涓婁竴甯х殑娉㈡瀹屾垚鐘舵€侊紙鐢ㄤ簬鏆傚仠璁℃椂锛
var _last_wave_complete: bool = false

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)


func _process(_delta: float) -> void:
	if GameManager.current_phase != GameManager.GamePhase.PLAYING:
		return
	
	var now := Time.get_ticks_msec()
	
	# 妫€鏌
	# Fever 缁撴潫
	if fever_active:
		# 娉㈡瀹屾垚鏃舵殏鍋
		# Fever 璁℃椂
		# (鍦ㄥ師鐗堜腑锛屾尝娆″畬鎴愭湡闂
		# Fever 鏃堕棿浼氬欢闀?
		
		if now >= fever_until:
			_deactivate_fever()


			# ============================================================
			# 鍏叡鏂规硶
			# ============================================================

## 娣诲姞 Fever 鑳介噺锛堝嚮鏉€鏁屼汉鏃惰皟鐢級
func add_fever(amount: float, combo_level: int = 0) -> void:
	# 鍙湁鎴撮潰鍏蜂笖闈
	# Fever 鐘舵€佹墠鑳界Н绱
	if not GameManager.is_masked or fever_active:
		return
	
	# Combo 鍔犳垚
	var combo_bonus := 1.0 + combo_level * GameConstants.FEVER_GAIN_COMBO_BONUS
	var final_amount := amount * combo_bonus
	
	fever_meter = minf(fever_meter + final_amount, GameConstants.FEVER_METER_MAX)
	fever_meter_updated.emit(fever_meter, GameConstants.FEVER_METER_MAX)
	
	# 鍚屾鍒
	GameManager
	GameManager.fever_meter = fever_meter
	GameManager.fever_updated.emit(fever_meter, fever_active)
	
	# 妫€鏌ユ槸鍚﹀彲浠ユ縺娲
	if fever_meter >= GameConstants.FEVER_METER_MAX:
		_activate_fever()


## 鑾峰彇褰撳墠 Fever 鐧惧垎姣
func get_fever_percent() -> float:
	return fever_meter / GameConstants.FEVER_METER_MAX * 100.0


## 鑾峰彇 Fever 鍓╀綑鏃堕棿锛堟绉掞級
func get_fever_remaining_ms() -> int:
	if not fever_active:
		return 0
	return maxi(0, fever_until - Time.get_ticks_msec())


## 鑾峰彇 Fever 鍓╀綑姣斾緥
func get_fever_remaining_ratio() -> float:
	if not fever_active:
		return 0.0
	var remaining := float(get_fever_remaining_ms())
	return remaining / GameConstants.FEVER_DURATION_MS


## 鏄惁澶勪簬 Fever 鐘舵€
func is_fever_active() -> bool:
	return fever_active


## 寮哄埗婵€娲
# Fever锛堣皟璇曠敤锛
func force_activate() -> void:
	fever_meter = GameConstants.FEVER_METER_MAX
	_activate_fever()


## 寮哄埗缁撴潫 Fever锛堣皟璇曠敤锛
func force_deactivate() -> void:
	if fever_active:
		_deactivate_fever()


## 閲嶇疆绯荤粺
func reset() -> void:
	fever_meter = 0.0
	fever_active = false
	fever_until = 0
	
	# 鍚屾鍒
	GameManager
	GameManager.fever_meter = 0.0
	GameManager.fever_active = false


## 闈㈠叿鐮寸鏃惰皟鐢紙娓呯┖ Fever锛
func on_mask_broken() -> void:
	if fever_active or fever_meter > 0:
		fever_meter = 0.0
		fever_active = false
		fever_until = 0
		
		fever_flash_requested.emit("out")
		fever_deactivated.emit()
		
		# 鍚屾鍒
		GameManager
		GameManager.fever_meter = 0.0
		GameManager.fever_active = false
		GameManager.fever_updated.emit(0.0, false)


## 寤堕暱 Fever 鏃堕棿锛堟尝娆″畬鎴愭椂璋冪敤锛
func extend_fever(extra_ms: int) -> void:
	if fever_active:
		fever_until += extra_ms


		# ============================================================
		# 绉佹湁鏂规硶
		# ============================================================

func _activate_fever() -> void:
	var now := Time.get_ticks_msec()
	
	fever_active = true
	fever_until = now + GameConstants.FEVER_DURATION_MS
	
	fever_activated.emit()
	fever_flash_requested.emit("in")
	
	# 鍚屾鍒
	GameManager
	GameManager.fever_active = true
	GameManager.activate_fever()
	
	# 鎾斁闊虫晥
	AudioManager.play_fever_start()


func _deactivate_fever() -> void:
	fever_active = false
	fever_meter = 0.0
	fever_until = 0
	
	fever_deactivated.emit()
	fever_flash_requested.emit("out")
	fever_meter_updated.emit(0.0, GameConstants.FEVER_METER_MAX)
	
	# 鍚屾鍒
	GameManager
	GameManager.fever_active = false
	GameManager.fever_meter = 0.0
	GameManager.deactivate_fever()
	
	# 鎾斁闊虫晥
	AudioManager.play_fever_end()


	# ============================================================
	# 淇″彿鍥炶皟
	# ============================================================

func _on_game_started(_seed: String) -> void:
	reset()


func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	if new_phase == GameManager.GamePhase.MENU:
		reset()



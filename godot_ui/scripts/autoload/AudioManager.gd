## AudioManager.gd
## 闊抽绠＄悊鍣
# (Autoload)
## 璐熻矗 BGM 鍜岄煶鏁堢殑鎾斁鎺у埗
##
## 閰嶇疆鏂瑰紡锛?## 1. 鍦
# Godot 缂栬緫鍣ㄤ腑锛歅roject -> Project Settings -> Autoload
## 2. 娣诲姞姝よ剼鏈紝鍚嶇О璁句负 "AudioManager"
## 3. 纭繚闊抽鏂囦欢瀛樺湪浜
# res://assets/audio/ 鐩綍

extends Node

# ============================================================
# 甯搁噺
# ============================================================

## 闊抽鏂囦欢璺緞
const AUDIO_PATH := "res://assets/audio/"

## BGM 鏂囦欢鍚
const BGM_FILE := "BGM.mp3"

## 闊虫晥鏂囦欢鏄犲皠
const SFX_FILES := {
	"dash": "dash.wav",
	"kill": "kill.wav",
	"kill_elite": "kill_elite.wav",
	"combo": "combo.wav",
	"fever_start": "fever_start.wav",
	"fever_end": "fever_end.wav",
	"mask_shatter": "mask_shatter.wav",
	"mask_restore": "mask_restore.wav",
	"hit": "hit.wav",
	"stage_clear": "stage_clear.wav",
	"game_over": "game_over.wav",
	"button_click": "button_click.wav",
	"button_hover": "button_hover.wav",
}

## 榛樿闊抽噺 (dB)
const DEFAULT_BGM_VOLUME := 0.0
const DEFAULT_SFX_VOLUME := 0.0

## 娣″叆娣″嚭鏃堕棿锛堢锛
const FADE_DURATION := 0.5

## 闊虫晥鎾斁鍣ㄦ睜澶у皬
const SFX_POOL_SIZE := 8

# ============================================================
# 鑺傜偣寮曠敤
# ============================================================

var _bgm_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _fade_tween: Tween = null

# ============================================================
# 缂撳瓨
# ============================================================

## 宸插姞杞界殑闊虫晥璧勬簮
var _sfx_cache: Dictionary = {}

## BGM 鏄惁宸插姞杞
var _bgm_loaded: bool = false

## 褰撳墠 BGM 闊抽噺
var _bgm_volume: float = DEFAULT_BGM_VOLUME

## 褰撳墠闊虫晥闊抽噺
var _sfx_volume: float = DEFAULT_SFX_VOLUME

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 鍒涘缓 BGM 鎾斁鍣
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = &"Master"
	add_child(_bgm_player)
	
	# 鍒涘缓闊虫晥鎾斁鍣ㄦ睜
	for i in range(SFX_POOL_SIZE):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_%d" % i
		sfx_player.bus = &"Master"
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)
	
	# 鍔犺浇 BGM
	_load_bgm()
	
	# 棰勫姞杞藉父鐢ㄩ煶鏁
	_preload_sfx()
	
	# 杩炴帴 GameManager 淇″彿
	if GameManager:
		GameManager.phase_changed.connect(_on_phase_changed)
		GameManager.game_started.connect(_on_game_started)
		GameManager.game_over.connect(_on_game_over)
		GameManager.mask_state_changed.connect(_on_mask_state_changed)
		GameManager.fever_updated.connect(_on_fever_updated)
	
	print("[AudioManager] Initialized with %d SFX players" % SFX_POOL_SIZE)


	# ============================================================
	# 鍏叡鏂规硶 - BGM
	# ============================================================

## 鎾斁 BGM锛堝甫娣″叆锛
func play_bgm(fade_in: bool = true) -> void:
	if not _bgm_loaded:
		push_warning("[AudioManager] BGM not loaded, cannot play")
		return
	
	if _bgm_player.playing:
		return
	
	if fade_in:
		_bgm_player.volume_db = -80.0
		_bgm_player.play()
		_fade_to_volume(_bgm_volume)
	else:
		_bgm_player.volume_db = _bgm_volume
		_bgm_player.play()
	
	print("[AudioManager] BGM started")


## 鍋滄 BGM锛堝甫娣″嚭锛
func stop_bgm(fade_out: bool = true) -> void:
	if not _bgm_player.playing:
		return
	
	if fade_out:
		_fade_to_volume(-80.0, true)
	else:
		_bgm_player.stop()
		print("[AudioManager] BGM stopped")


## 鏆傚仠 BGM
func pause_bgm() -> void:
	_bgm_player.stream_paused = true


## 鎭㈠ BGM
func resume_bgm() -> void:
	_bgm_player.stream_paused = false


## 璁剧疆 BGM 闊抽噺 (dB)
func set_bgm_volume(volume_db: float) -> void:
	_bgm_volume = volume_db
	if _bgm_player and _bgm_player.playing and (_fade_tween == null or not _fade_tween.is_valid()):
		_bgm_player.volume_db = volume_db


## 鑾峰彇 BGM 闊抽噺 (dB)
func get_bgm_volume() -> float:
	return _bgm_volume


## BGM 鏄惁姝ｅ湪鎾斁
func is_bgm_playing() -> bool:
	return _bgm_player.playing and not _bgm_player.stream_paused


	# ============================================================
	# 鍏叡鏂规硶 - 闊虫晥
	# ============================================================

## 鎾斁闊虫晥
## @param sfx_name: 闊虫晥鍚嶇О锛堣 SFX_FILES锛
## @param pitch_variation: 闊抽珮鍙樺寲鑼冨洿 (0.0 = 鏃犲彉鍖?
## @param volume_offset_db: 闊抽噺鍋忕Щ (dB)
func play_sfx(sfx_name: String, pitch_variation: float = 0.0, volume_offset_db: float = 0.0) -> void:
	var stream := _get_sfx_stream(sfx_name)
	if stream == null:
		return
	
	# 鑾峰彇涓嬩竴涓彲鐢ㄧ殑鎾斁鍣
	var player := _get_next_sfx_player()
	
	# 璁剧疆闊抽娴
	player.stream = stream
	
	# 璁剧疆闊抽噺
	player.volume_db = _sfx_volume + volume_offset_db
	
	# 璁剧疆闊抽珮锛堟坊鍔犻殢鏈哄彉鍖栵級
	if pitch_variation > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	# 鎾斁
	player.play()


## Play kill SFX (adjust by combo level)
# Combo 绛夌骇璋冩暣锛
func play_kill_sfx(combo_level: int = 0, is_elite: bool = false) -> void:
	if is_elite:
		play_sfx("kill_elite", 0.05)
	else:
		# 鏍规嵁 Combo 绛夌骇璋冩暣闊抽珮
		var pitch_offset := combo_level * 0.05
		var player := _get_next_sfx_player()
		var stream := _get_sfx_stream("kill")
		if stream:
			player.stream = stream
			player.volume_db = _sfx_volume
			player.pitch_scale = 1.0 + pitch_offset
			player.play()


## Play kill SFX (adjust by combo level)
func play_combo_sfx(combo_level: int) -> void:
	# Combo 绛夌骇瓒婇珮锛岄煶楂樿秺楂
	var pitch := 1.0 + (combo_level - 1) * 0.1
	var player := _get_next_sfx_player()
	var stream := _get_sfx_stream("combo")
	if stream:
		player.stream = stream
		player.volume_db = _sfx_volume
		player.pitch_scale = clampf(pitch, 1.0, 2.0)
		player.play()


## 鎾斁 UI 闊虫晥
func play_ui_sfx(sfx_name: String) -> void:
	play_sfx(sfx_name, 0.0, -5.0)  # UI 闊虫晥绋嶅井灏忓０涓€鐐?

## 璁剧疆闊虫晥闊抽噺 (dB)
func set_sfx_volume(volume_db: float) -> void:
	_sfx_volume = volume_db


## 鑾峰彇闊虫晥闊抽噺 (dB)
func get_sfx_volume() -> float:
	return _sfx_volume


## 鍋滄鎵€鏈夐煶鏁
func stop_all_sfx() -> void:
	for player in _sfx_pool:
		player.stop()


		# ============================================================
		# 鍏叡鏂规硶 - 渚挎嵎鎾斁
		# ============================================================

## 鎾斁鍐插埡闊虫晥
func play_dash() -> void:
	play_sfx("dash", 0.1)


## 鎾斁鍙楀嚮闊虫晥
func play_hit() -> void:
	play_sfx("hit", 0.1)


## 鎾斁闈㈠叿鐮寸闊虫晥
func play_mask_shatter() -> void:
	play_sfx("mask_shatter")


## 鎾斁闈㈠叿鎭㈠闊虫晥
func play_mask_restore() -> void:
	play_sfx("mask_restore")


## 鎾斁 Fever 寮€濮嬮煶鏁
func play_fever_start() -> void:
	play_sfx("fever_start")


## 鎾斁 Fever 缁撴潫闊虫晥
func play_fever_end() -> void:
	play_sfx("fever_end")


## 鎾斁鍏冲崱閫氳繃闊虫晥
func play_stage_clear() -> void:
	play_sfx("stage_clear")


## 鎾斁娓告垙缁撴潫闊虫晥
func play_game_over() -> void:
	play_sfx("game_over")


	# ============================================================
	# 绉佹湁鏂规硶 - 璧勬簮鍔犺浇
	# ============================================================

## 鍔犺浇 BGM 鏂囦欢
func _load_bgm() -> void:
	var bgm_path := AUDIO_PATH + BGM_FILE
	
	if not ResourceLoader.exists(bgm_path):
		push_warning("[AudioManager] BGM file not found: %s" % bgm_path)
		_bgm_loaded = false
		return
	
	var stream = load(bgm_path)
	if stream == null:
		push_warning("[AudioManager] Failed to load BGM: %s" % bgm_path)
		_bgm_loaded = false
		return
	
	_bgm_player.stream = stream
	_bgm_player.finished.connect(_on_bgm_finished)
	
	_bgm_loaded = true
	print("[AudioManager] BGM loaded: %s" % bgm_path)


## 棰勫姞杞介煶鏁
func _preload_sfx() -> void:
	for sfx_name in SFX_FILES:
		var sfx_path: String = AUDIO_PATH + String(SFX_FILES[sfx_name])
		
		if ResourceLoader.exists(sfx_path):
			var stream = load(sfx_path)
			if stream:
				_sfx_cache[sfx_name] = stream
				print("[AudioManager] SFX loaded: %s" % sfx_name)
		else:
			# 闊虫晥鏂囦欢涓嶅瓨鍦ㄤ笉鎶ラ敊锛屽彧鏄潤榛樿烦杩
			pass
	
	print("[AudioManager] Preloaded %d SFX files" % _sfx_cache.size())


## 鑾峰彇闊虫晥娴侊紙甯︾紦瀛橈級
func _get_sfx_stream(sfx_name: String) -> AudioStream:
	# 妫€鏌ョ紦瀛
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	
	# 灏濊瘯鍔犺浇
	if not SFX_FILES.has(sfx_name):
		push_warning("[AudioManager] Unknown SFX: %s" % sfx_name)
		return null
	
	var sfx_path: String = AUDIO_PATH + String(SFX_FILES[sfx_name])
	if not ResourceLoader.exists(sfx_path):
		return null
	
	var stream = load(sfx_path)
	if stream:
		_sfx_cache[sfx_name] = stream
	
	return stream


## 鑾峰彇涓嬩竴涓彲鐢ㄧ殑闊虫晥鎾斁鍣
func _get_next_sfx_player() -> AudioStreamPlayer:
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	return player


	# ============================================================
	# 绉佹湁鏂规硶 - 娣″叆娣″嚭
	# ============================================================

## 娣″叆娣″嚭鍒扮洰鏍囬煶閲
func _fade_to_volume(target_db: float, stop_after: bool = false) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.tween_property(_bgm_player, "volume_db", target_db, FADE_DURATION)
	
	if stop_after:
		_fade_tween.tween_callback(_bgm_player.stop)


		# ============================================================
		# 淇″彿鍥炶皟
		# ============================================================

## BGM 鎾斁瀹屾垚鏃讹紙鎵嬪姩寰幆锛
func _on_bgm_finished() -> void:
	if GameManager and GameManager.current_phase == GameManager.GamePhase.PLAYING:
		_bgm_player.play()


## 娓告垙闃舵鍙樺寲鍥炶皟
func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	match new_phase:
		GameManager.GamePhase.MENU, GameManager.GamePhase.GAMEOVER:
			stop_bgm(true)


## 娓告垙寮€濮嬪洖璋
func _on_game_started(_seed: String) -> void:
	_bgm_player.stop()
	_bgm_player.seek(0.0)
	play_bgm(true)


## 娓告垙缁撴潫鍥炶皟
func _on_game_over(_final_score: int, _final_stage: int) -> void:
	play_game_over()


## 闈㈠叿鐘舵€佸彉鍖栧洖璋
func _on_mask_state_changed(is_masked: bool, _shattered_kills: int) -> void:
	# 杩欓噷鍙互娣诲姞闈㈠叿鐘舵€佸彉鍖栫殑闊虫晥
	# 鐢变簬闇€瑕佸尯鍒嗙牬纰庡拰鎭㈠锛屽缓璁敱娓告垙閫昏緫鏄惧紡璋冪敤
	pass


## Fever 鐘舵€佸彉鍖栧洖璋
var _last_fever_active: bool = false

func _on_fever_updated(_meter: float, is_active: bool) -> void:
	if is_active and not _last_fever_active:
		play_fever_start()
	elif not is_active and _last_fever_active:
		play_fever_end()
	
	_last_fever_active = is_active

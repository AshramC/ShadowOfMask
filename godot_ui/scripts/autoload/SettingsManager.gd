## SettingsManager.gd
## 娓告垙璁剧疆绠＄悊鍣
# (Autoload)
## 璐熻矗淇濆瓨鍜屽姞杞芥父鎴忚缃紙闊抽噺銆佸叏灞忋€佹寜閿槧灏勭瓑锛
##
## 閰嶇疆鏂瑰紡锛?## 1. 鍦
# Godot 缂栬緫鍣ㄤ腑锛歅roject -> Project Settings -> Autoload
## 2. 娣诲姞姝よ剼鏈紝鍚嶇О璁句负 "SettingsManager"
## 3. 鍦ㄤ换鎰忚剼鏈腑閫氳繃 SettingsManager.xxx 璁块棶

extends Node

# ============================================================
# 甯搁噺
# ============================================================

const SAVE_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_VIDEO := "video"
const SECTION_GAMEPLAY := "gameplay"

# ============================================================
# 淇″彿
# ============================================================

## 璁剧疆鏇存敼鏃惰Е鍙
signal settings_changed(section: String, key: String, value: Variant)

## 鎵€鏈夎缃噸缃椂瑙﹀彂
signal settings_reset()

# ============================================================
# 榛樿鍊
# ============================================================

const DEFAULTS := {
	SECTION_AUDIO: {
		"master_volume": 1.0,      # 涓婚煶閲?(0.0 - 1.0)
		"bgm_volume": 0.8,         # BGM 闊抽噺 (0.0 - 1.0)
		"sfx_volume": 1.0,         # 闊虫晥闊抽噺 (0.0 - 1.0)
		"muted": false,            # 鏄惁闈欓煶
	},
	SECTION_VIDEO: {
		"fullscreen": false,       # 鏄惁鍏ㄥ睆
		"vsync": true,             # 鏄惁鍨傜洿鍚屾
		"screen_shake": true,      # 鏄惁鍚敤灞忓箷闇囧姩
	},
	SECTION_GAMEPLAY: {
		"show_tutorial": true,     # 鏄惁鏄剧ず鏁欑▼
		"show_damage_numbers": true, # 鏄惁鏄剧ず浼ゅ鏁板瓧
		"auto_save_score": true,   # 鏄惁鑷姩淇濆瓨鎴愮哗
	}
}

# ============================================================
# 杩愯鏃惰缃紦瀛
# ============================================================

var _settings: Dictionary = {}
var _config_file: ConfigFile = null

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	_config_file = ConfigFile.new()
	_load_settings()
	_apply_settings()
	print("[SettingsManager] Initialized")


	# ============================================================
	# 鍏叡鏂规硶 - 閫氱敤
	# ============================================================

## 鑾峰彇璁剧疆鍊
func get_setting(section: String, key: String) -> Variant:
	if _settings.has(section) and _settings[section].has(key):
		return _settings[section][key]
	
	# 杩斿洖榛樿鍊
	if DEFAULTS.has(section) and DEFAULTS[section].has(key):
		return DEFAULTS[section][key]
	
	return null


## 璁剧疆鍊
func set_setting(section: String, key: String, value: Variant) -> void:
	if not _settings.has(section):
		_settings[section] = {}
	
	var old_value = _settings[section].get(key)
	if old_value != value:
		_settings[section][key] = value
		settings_changed.emit(section, key, value)
		_apply_single_setting(section, key, value)


## 淇濆瓨璁剧疆鍒版枃浠
func save_settings() -> void:
	for section in _settings:
		for key in _settings[section]:
			_config_file.set_value(section, key, _settings[section][key])
	
	var error := _config_file.save(SAVE_PATH)
	if error != OK:
		push_error("[SettingsManager] Failed to save settings: %s" % error)
	else:
		print("[SettingsManager] Settings saved")


## 閲嶇疆涓洪粯璁よ缃
func reset_to_defaults() -> void:
	_settings = DEFAULTS.duplicate(true)
	_apply_settings()
	save_settings()
	settings_reset.emit()
	print("[SettingsManager] Settings reset to defaults")


	# ============================================================
	# 鍏叡鏂规硶 - 闊抽蹇嵎鏂规硶
	# ============================================================

## 鑾峰彇涓婚煶閲
func get_master_volume() -> float:
	return get_setting(SECTION_AUDIO, "master_volume")


## 璁剧疆涓婚煶閲
func set_master_volume(value: float) -> void:
	set_setting(SECTION_AUDIO, "master_volume", clampf(value, 0.0, 1.0))


## 鑾峰彇 BGM 闊抽噺
func get_bgm_volume() -> float:
	return get_setting(SECTION_AUDIO, "bgm_volume")


## 璁剧疆 BGM 闊抽噺
func set_bgm_volume(value: float) -> void:
	set_setting(SECTION_AUDIO, "bgm_volume", clampf(value, 0.0, 1.0))


## 鑾峰彇闊虫晥闊抽噺
func get_sfx_volume() -> float:
	return get_setting(SECTION_AUDIO, "sfx_volume")


## 璁剧疆闊虫晥闊抽噺
func set_sfx_volume(value: float) -> void:
	set_setting(SECTION_AUDIO, "sfx_volume", clampf(value, 0.0, 1.0))


## 鏄惁闈欓煶
func is_muted() -> bool:
	return get_setting(SECTION_AUDIO, "muted")


## 璁剧疆闈欓煶
func set_muted(value: bool) -> void:
	set_setting(SECTION_AUDIO, "muted", value)


## 鍒囨崲闈欓煶
func toggle_mute() -> void:
	set_muted(not is_muted())


	# ============================================================
	# 鍏叡鏂规硶 - 瑙嗛蹇嵎鏂规硶
	# ============================================================

## 鏄惁鍏ㄥ睆
func is_fullscreen() -> bool:
	return get_setting(SECTION_VIDEO, "fullscreen")


## 璁剧疆鍏ㄥ睆
func set_fullscreen(value: bool) -> void:
	set_setting(SECTION_VIDEO, "fullscreen", value)


## 鍒囨崲鍏ㄥ睆
func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())


## 鏄惁鍚敤灞忓箷闇囧姩
func is_screen_shake_enabled() -> bool:
	return get_setting(SECTION_VIDEO, "screen_shake")


## 璁剧疆灞忓箷闇囧姩
func set_screen_shake_enabled(value: bool) -> void:
	set_setting(SECTION_VIDEO, "screen_shake", value)


	# ============================================================
	# 鍏叡鏂规硶 - 娓告垙鎬у揩鎹锋柟娉
	# ============================================================

## 鏄惁鏄剧ず鏁欑▼
func should_show_tutorial() -> bool:
	return get_setting(SECTION_GAMEPLAY, "show_tutorial")


## 璁剧疆鏄惁鏄剧ず鏁欑▼
func set_show_tutorial(value: bool) -> void:
	set_setting(SECTION_GAMEPLAY, "show_tutorial", value)


## 鏄惁鑷姩淇濆瓨鎴愮哗
func should_auto_save_score() -> bool:
	return get_setting(SECTION_GAMEPLAY, "auto_save_score")


	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

## 浠庢枃浠跺姞杞借缃
func _load_settings() -> void:
	# 棣栧厛浣跨敤榛樿鍊煎垵濮嬪寲
	_settings = DEFAULTS.duplicate(true)
	
	# 灏濊瘯鍔犺浇淇濆瓨鐨勮缃
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SettingsManager] No saved settings found, using defaults")
		return
	
	var error := _config_file.load(SAVE_PATH)
	if error != OK:
		push_warning("[SettingsManager] Failed to load settings: %s" % error)
		return
	
	# 鍚堝苟鍔犺浇鐨勮缃
	for section in _config_file.get_sections():
		if not _settings.has(section):
			_settings[section] = {}
		
		for key in _config_file.get_section_keys(section):
			_settings[section][key] = _config_file.get_value(section, key)
	
	print("[SettingsManager] Settings loaded from file")


## 搴旂敤鎵€鏈夎缃
func _apply_settings() -> void:
	for section in _settings:
		for key in _settings[section]:
			_apply_single_setting(section, key, _settings[section][key])


## 搴旂敤鍗曚釜璁剧疆
func _apply_single_setting(section: String, key: String, value: Variant) -> void:
	match section:
		SECTION_AUDIO:
			_apply_audio_setting(key, value)
		SECTION_VIDEO:
			_apply_video_setting(key, value)
		SECTION_GAMEPLAY:
			pass  # 娓告垙鎬ц缃€氬父鐢卞叾浠栫郴缁熻鍙?

## 搴旂敤闊抽璁剧疆
func _apply_audio_setting(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			var db := linear_to_db(value as float)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
		"bgm_volume":
			# If bus exists
			var bus_idx := AudioServer.get_bus_index("Music")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value as float))
			# 鍚屾椂閫氱煡 AudioManager
			if AudioManager:
				AudioManager.set_bgm_volume(linear_to_db(value as float * get_master_volume()))
		"sfx_volume":
			# If bus exists
			var bus_idx := AudioServer.get_bus_index("SFX")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value as float))
		"muted":
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value as bool)


## 搴旂敤瑙嗛璁剧疆
func _apply_video_setting(key: String, value: Variant) -> void:
	match key:
		"fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			if value:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


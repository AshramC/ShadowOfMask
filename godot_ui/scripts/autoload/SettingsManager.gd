

extends Node

const SAVE_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_VIDEO := "video"
const SECTION_GAMEPLAY := "gameplay"

signal settings_changed(section: String, key: String, value: Variant)

signal settings_reset()

const DEFAULTS := {
	SECTION_AUDIO: {
		"master_volume": 1.0,
		"bgm_volume": 0.8,
		"sfx_volume": 1.0,
		"muted": false,
	},
	SECTION_VIDEO: {
		"fullscreen": false,
		"vsync": true,
		"screen_shake": true,
	},
	SECTION_GAMEPLAY: {
		"show_tutorial": true,
		"show_damage_numbers": true,
		"auto_save_score": true,
	}
}

var _settings: Dictionary = {}
var _config_file: ConfigFile = null

func _ready() -> void:
	_config_file = ConfigFile.new()
	_load_settings()
	_apply_settings()
	print("[SettingsManager] Initialized")

func get_setting(section: String, key: String) -> Variant:
	if _settings.has(section) and _settings[section].has(key):
		return _settings[section][key]

	if DEFAULTS.has(section) and DEFAULTS[section].has(key):
		return DEFAULTS[section][key]

	return null

func set_setting(section: String, key: String, value: Variant) -> void:
	if not _settings.has(section):
		_settings[section] = {}

	var old_value = _settings[section].get(key)
	if old_value != value:
		_settings[section][key] = value
		settings_changed.emit(section, key, value)
		_apply_single_setting(section, key, value)

func save_settings() -> void:
	for section in _settings:
		for key in _settings[section]:
			_config_file.set_value(section, key, _settings[section][key])

	var error := _config_file.save(SAVE_PATH)
	if error != OK:
		push_error("[SettingsManager] Failed to save settings: %s" % error)
	else:
		print("[SettingsManager] Settings saved")

func reset_to_defaults() -> void:
	_settings = DEFAULTS.duplicate(true)
	_apply_settings()
	save_settings()
	settings_reset.emit()
	print("[SettingsManager] Settings reset to defaults")

func get_master_volume() -> float:
	return get_setting(SECTION_AUDIO, "master_volume")

func set_master_volume(value: float) -> void:
	set_setting(SECTION_AUDIO, "master_volume", clampf(value, 0.0, 1.0))

func get_bgm_volume() -> float:
	return get_setting(SECTION_AUDIO, "bgm_volume")

func set_bgm_volume(value: float) -> void:
	set_setting(SECTION_AUDIO, "bgm_volume", clampf(value, 0.0, 1.0))

func get_sfx_volume() -> float:
	return get_setting(SECTION_AUDIO, "sfx_volume")

func set_sfx_volume(value: float) -> void:
	set_setting(SECTION_AUDIO, "sfx_volume", clampf(value, 0.0, 1.0))

func is_muted() -> bool:
	return get_setting(SECTION_AUDIO, "muted")

func set_muted(value: bool) -> void:
	set_setting(SECTION_AUDIO, "muted", value)

func toggle_mute() -> void:
	set_muted(not is_muted())

func is_fullscreen() -> bool:
	return get_setting(SECTION_VIDEO, "fullscreen")

func set_fullscreen(value: bool) -> void:
	set_setting(SECTION_VIDEO, "fullscreen", value)

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())

func is_screen_shake_enabled() -> bool:
	return get_setting(SECTION_VIDEO, "screen_shake")

func set_screen_shake_enabled(value: bool) -> void:
	set_setting(SECTION_VIDEO, "screen_shake", value)

func should_show_tutorial() -> bool:
	return get_setting(SECTION_GAMEPLAY, "show_tutorial")

func set_show_tutorial(value: bool) -> void:
	set_setting(SECTION_GAMEPLAY, "show_tutorial", value)

func should_auto_save_score() -> bool:
	return get_setting(SECTION_GAMEPLAY, "auto_save_score")

func _load_settings() -> void:

	_settings = DEFAULTS.duplicate(true)

	if not FileAccess.file_exists(SAVE_PATH):
		print("[SettingsManager] No saved settings found, using defaults")
		return

	var error := _config_file.load(SAVE_PATH)
	if error != OK:
		push_warning("[SettingsManager] Failed to load settings: %s" % error)
		return

	for section in _config_file.get_sections():
		if not _settings.has(section):
			_settings[section] = {}

		for key in _config_file.get_section_keys(section):
			_settings[section][key] = _config_file.get_value(section, key)

	print("[SettingsManager] Settings loaded from file")

func _apply_settings() -> void:
	for section in _settings:
		for key in _settings[section]:
			_apply_single_setting(section, key, _settings[section][key])

func _apply_single_setting(section: String, key: String, value: Variant) -> void:
	match section:
		SECTION_AUDIO:
			_apply_audio_setting(key, value)
		SECTION_VIDEO:
			_apply_video_setting(key, value)
		SECTION_GAMEPLAY:
			pass

func _apply_audio_setting(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			var db := linear_to_db(value as float)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
		"bgm_volume":

			var bus_idx := AudioServer.get_bus_index("Music")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value as float))

			if AudioManager:
				AudioManager.set_bgm_volume(linear_to_db(value as float * get_master_volume()))
		"sfx_volume":

			var bus_idx := AudioServer.get_bus_index("SFX")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value as float))
		"muted":
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value as bool)

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

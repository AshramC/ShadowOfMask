extends Node

const AUDIO_PATH := "res://assets/audio/"
const FALLBACK_AUDIO_PATH := "res://"

const BGM_FILE := "BGM.mp3"

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

const DEFAULT_BGM_VOLUME := 0.0
const DEFAULT_SFX_VOLUME := 0.0

const FADE_DURATION := 0.5

const SFX_POOL_SIZE := 8

var _bgm_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _fade_tween: Tween = null

var _sfx_cache: Dictionary = {}

var _bgm_loaded: bool = false

var _bgm_volume: float = DEFAULT_BGM_VOLUME

var _sfx_volume: float = DEFAULT_SFX_VOLUME

func _ready() -> void:

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = &"Master"
	add_child(_bgm_player)

	for i in range(SFX_POOL_SIZE):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_%d" % i
		sfx_player.bus = &"Master"
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)

	_load_bgm()

	_preload_sfx()

	if GameManager:
		GameManager.phase_changed.connect(_on_phase_changed)
		GameManager.game_started.connect(_on_game_started)
		GameManager.game_over.connect(_on_game_over)
		GameManager.mask_state_changed.connect(_on_mask_state_changed)
		GameManager.fever_updated.connect(_on_fever_updated)

	print("[AudioManager] Initialized with %d SFX players" % SFX_POOL_SIZE)

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

func stop_bgm(fade_out: bool = true) -> void:
	if not _bgm_player.playing:
		return

	if fade_out:
		_fade_to_volume(-80.0, true)
	else:
		_bgm_player.stop()
		print("[AudioManager] BGM stopped")

func pause_bgm() -> void:
	_bgm_player.stream_paused = true

func resume_bgm() -> void:
	_bgm_player.stream_paused = false

func set_bgm_volume(volume_db: float) -> void:
	_bgm_volume = volume_db
	if _bgm_player and _bgm_player.playing and (_fade_tween == null or not _fade_tween.is_valid()):
		_bgm_player.volume_db = volume_db

func get_bgm_volume() -> float:
	return _bgm_volume

func is_bgm_playing() -> bool:
	return _bgm_player.playing and not _bgm_player.stream_paused

func play_sfx(sfx_name: String, pitch_variation: float = 0.0, volume_offset_db: float = 0.0) -> void:
	var stream := _get_sfx_stream(sfx_name)
	if stream == null:
		return

	var player := _get_next_sfx_player()

	player.stream = stream

	player.volume_db = _sfx_volume + volume_offset_db

	if pitch_variation > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0

	player.play()

func play_kill_sfx(combo_level: int = 0, is_elite: bool = false) -> void:
	if is_elite:
		play_sfx("kill_elite", 0.05)
	else:

		var pitch_offset := combo_level * 0.05
		var player := _get_next_sfx_player()
		var stream := _get_sfx_stream("kill")
		if stream:
			player.stream = stream
			player.volume_db = _sfx_volume
			player.pitch_scale = 1.0 + pitch_offset
			player.play()

func play_combo_sfx(combo_level: int) -> void:

	var pitch := 1.0 + (combo_level - 1) * 0.1
	var player := _get_next_sfx_player()
	var stream := _get_sfx_stream("combo")
	if stream:
		player.stream = stream
		player.volume_db = _sfx_volume
		player.pitch_scale = clampf(pitch, 1.0, 2.0)
		player.play()

func play_ui_sfx(sfx_name: String) -> void:
	play_sfx(sfx_name, 0.0, -5.0)

func set_sfx_volume(volume_db: float) -> void:
	_sfx_volume = volume_db

func get_sfx_volume() -> float:
	return _sfx_volume

func stop_all_sfx() -> void:
	for player in _sfx_pool:
		player.stop()

func play_dash() -> void:
	play_sfx("dash", 0.1)

func play_hit() -> void:
	play_sfx("hit", 0.1)

func play_mask_shatter() -> void:
	play_sfx("mask_shatter")

func play_mask_restore() -> void:
	play_sfx("mask_restore")

func play_fever_start() -> void:
	play_sfx("fever_start")

func play_fever_end() -> void:
	play_sfx("fever_end")

func play_stage_clear() -> void:
	play_sfx("stage_clear")

func play_game_over() -> void:
	play_sfx("game_over")

func _load_bgm() -> void:
	var bgm_path := _resolve_audio_path(BGM_FILE)

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

func _preload_sfx() -> void:
	for sfx_name in SFX_FILES:
		var sfx_path: String = _resolve_audio_path(String(SFX_FILES[sfx_name]))

		if ResourceLoader.exists(sfx_path):
			var stream = load(sfx_path)
			if stream:
				_sfx_cache[sfx_name] = stream
				print("[AudioManager] SFX loaded: %s" % sfx_name)
		else:

			pass

	print("[AudioManager] Preloaded %d SFX files" % _sfx_cache.size())

func _get_sfx_stream(sfx_name: String) -> AudioStream:

	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]

	if not SFX_FILES.has(sfx_name):
		push_warning("[AudioManager] Unknown SFX: %s" % sfx_name)
		return null

	var sfx_path: String = _resolve_audio_path(String(SFX_FILES[sfx_name]))
	if not ResourceLoader.exists(sfx_path):
		return null

	var stream = load(sfx_path)
	if stream:
		_sfx_cache[sfx_name] = stream

	return stream

func _get_next_sfx_player() -> AudioStreamPlayer:
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	return player

func _fade_to_volume(target_db: float, stop_after: bool = false) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_bgm_player, "volume_db", target_db, FADE_DURATION)

	if stop_after:
		_fade_tween.tween_callback(_bgm_player.stop)

func _on_bgm_finished() -> void:
	if GameManager and GameManager.current_phase == GameManager.GamePhase.PLAYING:
		_bgm_player.play()

func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	match new_phase:
		GameManager.GamePhase.MENU, GameManager.GamePhase.GAMEOVER:
			stop_bgm(true)

func _on_game_started(_seed: String) -> void:
	_bgm_player.stop()
	_bgm_player.seek(0.0)
	play_bgm(true)

func _on_game_over(_final_score: int, _final_stage: int) -> void:
	play_game_over()

func _on_mask_state_changed(is_masked: bool, _shattered_kills: int) -> void:

	pass

func _resolve_audio_path(filename: String) -> String:
	var primary := AUDIO_PATH + filename
	if ResourceLoader.exists(primary):
		return primary
	return FALLBACK_AUDIO_PATH + filename

var _last_fever_active: bool = false

func _on_fever_updated(_meter: float, is_active: bool) -> void:
	if is_active and not _last_fever_active:
		play_fever_start()
	elif not is_active and _last_fever_active:
		play_fever_end()

	_last_fever_active = is_active

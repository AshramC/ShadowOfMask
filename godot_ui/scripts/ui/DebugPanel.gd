

extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var status_label: Label = $Panel/MarginContainer/VBox/StatusSection/StatusLabel
@onready var phase_label: Label = $Panel/MarginContainer/VBox/StatusSection/PhaseLabel

@onready var master_volume_slider: HSlider = $Panel/MarginContainer/VBox/VolumeSection/MasterVolumeSlider
@onready var bgm_volume_slider: HSlider = $Panel/MarginContainer/VBox/VolumeSection/BGMVolumeSlider
@onready var sfx_volume_slider: HSlider = $Panel/MarginContainer/VBox/VolumeSection/SFXVolumeSlider

var _visible: bool = false

func _ready() -> void:

	panel.visible = false

	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.stage_updated.connect(_on_stage_updated)
	GameManager.mask_state_changed.connect(_on_mask_state_changed)
	GameManager.fever_updated.connect(_on_fever_updated)

	_init_volume_sliders()

	_update_status()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F12:
				_toggle_visibility()
			KEY_F1:
				if _visible:
					_on_add_score_pressed()
			KEY_F2:
				if _visible:
					_on_advance_stage_pressed()
			KEY_F3:
				if _visible:
					_on_shatter_mask_pressed()
			KEY_F4:
				if _visible:
					_on_add_shattered_kill_pressed()
			KEY_F5:
				if _visible:
					_on_add_fever_pressed()
			KEY_F6:
				if _visible:
					_on_game_over_pressed()

func _process(_delta: float) -> void:
	if _visible:
		_update_status()

func show_panel() -> void:
	_visible = true
	panel.visible = true

func hide_panel() -> void:
	_visible = false
	panel.visible = false

func _toggle_visibility() -> void:
	_visible = not _visible
	panel.visible = _visible

func _init_volume_sliders() -> void:
	if SettingsManager:
		if master_volume_slider:
			master_volume_slider.value = SettingsManager.get_master_volume()
			master_volume_slider.value_changed.connect(_on_master_volume_changed)

		if bgm_volume_slider:
			bgm_volume_slider.value = SettingsManager.get_bgm_volume()
			bgm_volume_slider.value_changed.connect(_on_bgm_volume_changed)

		if sfx_volume_slider:
			sfx_volume_slider.value = SettingsManager.get_sfx_volume()
			sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

func _update_status() -> void:
	if status_label:
		var status_text := """Score: %d | Stage: %d
Masked: %s | Shattered Kills: %d
Fever: %.1f%% | Active: %s""" % [
			GameManager.score,
			GameManager.stage,
			"Yes" if GameManager.is_masked else "No",
			GameManager.shattered_kills,
			GameManager.fever_meter,
			"Yes" if GameManager.fever_active else "No"
		]
		status_label.text = status_text

	if phase_label:
		phase_label.text = "Phase: %s" % GameManager.GamePhase.keys()[GameManager.current_phase]

func _on_start_game_pressed() -> void:
	GameManager.start_game()

func _on_game_over_pressed() -> void:
	GameManager.trigger_game_over()

func _on_go_to_menu_pressed() -> void:
	GameManager.go_to_menu()

func _on_add_score_pressed() -> void:
	GameManager.add_score(1)

func _on_advance_stage_pressed() -> void:
	GameManager.advance_stage()

func _on_shatter_mask_pressed() -> void:
	GameManager.shatter_mask()
	AudioManager.play_mask_shatter()

func _on_add_shattered_kill_pressed() -> void:
	GameManager.add_shattered_kill()
	if GameManager.is_masked:
		AudioManager.play_mask_restore()

func _on_add_fever_pressed() -> void:
	GameManager.add_fever(20.0)

func _on_activate_fever_pressed() -> void:
	GameManager.fever_meter = GameManager.FEVER_METER_MAX
	GameManager.activate_fever()

func _on_deactivate_fever_pressed() -> void:
	GameManager.deactivate_fever()

func _on_play_bgm_pressed() -> void:
	AudioManager.play_bgm()

func _on_stop_bgm_pressed() -> void:
	AudioManager.stop_bgm()

func _on_play_kill_sfx_pressed() -> void:
	AudioManager.play_kill_sfx(0, false)

func _on_play_combo_sfx_pressed() -> void:
	AudioManager.play_combo_sfx(3)

func _on_play_dash_sfx_pressed() -> void:
	AudioManager.play_dash()

func _on_clear_leaderboard_pressed() -> void:
	LeaderboardManager.clear_leaderboard()
	print("[DebugPanel] Leaderboard cleared")

func _on_add_test_score_pressed() -> void:
	var test_names := ["TestPlayer", "DebugUser", "Ninja", "Shadow", "Ghost"]
	var random_name: String = test_names[randi() % test_names.size()]
	var random_stage := randi_range(1, 5)
	var random_score := randi_range(10, 100)

	LeaderboardManager.save_result(random_name, random_stage, random_score)
	print("[DebugPanel] Added test score: %s - Stage %d, %d kills" % [random_name, random_stage, random_score])

func _on_master_volume_changed(value: float) -> void:
	if SettingsManager:
		SettingsManager.set_master_volume(value)

func _on_bgm_volume_changed(value: float) -> void:
	if SettingsManager:
		SettingsManager.set_bgm_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	if SettingsManager:
		SettingsManager.set_sfx_volume(value)

func _on_save_settings_pressed() -> void:
	if SettingsManager:
		SettingsManager.save_settings()
		print("[DebugPanel] Settings saved")

func _on_reset_settings_pressed() -> void:
	if SettingsManager:
		SettingsManager.reset_to_defaults()
		_init_volume_sliders()
		print("[DebugPanel] Settings reset")

func _on_toggle_fullscreen_pressed() -> void:
	if SettingsManager:
		SettingsManager.toggle_fullscreen()

func _on_phase_changed(_new_phase: GameManager.GamePhase) -> void:
	_update_status()

func _on_score_updated(_new_score: int) -> void:
	_update_status()

func _on_stage_updated(_new_stage: int) -> void:
	_update_status()

func _on_mask_state_changed(_is_masked: bool, _shattered_kills: int) -> void:
	_update_status()

func _on_fever_updated(_meter: float, _is_active: bool) -> void:
	_update_status()

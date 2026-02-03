extends Control

@onready var score_value: Label = %ScoreValue

@onready var stage_label: Label = %StageLabel

@onready var mask_section: VBoxContainer = %MaskSection
@onready var mask_status: Label = %MaskStatus
@onready var mask_icon: TextureRect = %MaskIcon
@onready var shattered_kills_label: Label = %ShatteredKills
@onready var fever_label: Label = %FeverLabel

@onready var fever_bar_container: Control = %FeverBarContainer
@onready var fever_bar_fill: Panel = %FeverBarFill

var _stage_toast_container: CenterContainer
var _stage_toast_label: Label
var _stage_toast_started_at: int = -1

@onready var tutorial_hint: CenterContainer = %TutorialHint

const FEVER_BAR_MAX_WIDTH := 150.0

const COLOR_MASK_INTACT := Color(1, 1, 1, 1)

const COLOR_MASK_BROKEN := Color(1, 0.3, 0.3, 1)

const COLOR_FEVER_NORMAL := Color(0.4, 0.4, 0.4, 1)

const COLOR_FEVER_ACTIVE := Color(1, 0.67, 0.35, 0.95)

var _show_tutorial: bool = true

var _fever_pulse_tween: Tween = null

func _ready() -> void:

	GameManager.score_updated.connect(_on_score_updated)
	GameManager.stage_updated.connect(_on_stage_updated)
	GameManager.mask_state_changed.connect(_on_mask_state_changed)
	GameManager.fever_updated.connect(_on_fever_updated)
	GameManager.game_started.connect(_on_game_started)

	_create_stage_toast()

	_update_score(0)
	_update_stage(1)
	_update_mask_state(true, 0)
	_update_fever(0.0, false)
	_update_tutorial_hint(0, 1)

	print("[HUD] Initialized")

func _process(_delta: float) -> void:

	if _show_tutorial and visible:
		_update_tutorial_hint(GameManager.score, GameManager.stage)

	_update_stage_toast()

func _on_score_updated(new_score: int) -> void:
	_update_score(new_score)
	_update_tutorial_hint(new_score, GameManager.stage)

func _on_stage_updated(new_stage: int) -> void:
	_update_stage(new_stage)
	_update_tutorial_hint(GameManager.score, new_stage)
	_show_stage_toast(new_stage)

func _on_mask_state_changed(is_masked: bool, shattered_kills: int) -> void:
	_update_mask_state(is_masked, shattered_kills)

func _on_fever_updated(meter: float, is_active: bool) -> void:
	_update_fever(meter, is_active)

func _on_game_started(_seed: String) -> void:

	_show_tutorial = true
	_update_score(0)
	_update_stage(1)
	_update_mask_state(true, 0)
	_update_fever(0.0, false)
	_update_tutorial_hint(0, 1)

func _update_score(value: int) -> void:
	if score_value:
		score_value.text = "%04d" % value

func _update_stage(value: int) -> void:
	if stage_label:
		stage_label.text = "STAGE %d" % value

func _update_mask_state(is_masked: bool, shattered_kills: int) -> void:
	if not mask_status:
		return

	if is_masked:

		mask_status.text = "闈㈠叿瀹屾暣"
		mask_status.modulate = COLOR_MASK_INTACT

		if shattered_kills_label:
			shattered_kills_label.visible = false

		if fever_label:
			fever_label.visible = true
	else:

		mask_status.text = "闈㈠叿鐮寸"
		mask_status.modulate = COLOR_MASK_BROKEN

		if shattered_kills_label:
			shattered_kills_label.visible = true
			shattered_kills_label.text = "閲嶅鎵€闇€: %d/3" % shattered_kills

		if fever_label:
			fever_label.visible = false

	if mask_icon:
		mask_icon.modulate = COLOR_MASK_INTACT if is_masked else COLOR_MASK_BROKEN

func _update_fever(meter: float, is_active: bool) -> void:

	if fever_label:
		fever_label.modulate = COLOR_FEVER_ACTIVE if is_active else COLOR_FEVER_NORMAL

	if fever_bar_container:

		var should_show: bool = GameManager.is_masked and (meter > 0 or is_active)
		fever_bar_container.visible = should_show

	if fever_bar_fill:
		var fill_ratio: float = meter / GameManager.FEVER_METER_MAX
		var target_width: float = fill_ratio * FEVER_BAR_MAX_WIDTH

		var tween := create_tween()
		tween.tween_property(fever_bar_fill, "size:x", target_width, 0.1)

		if is_active:
			_start_fever_pulse()
		else:
			_stop_fever_pulse()

func _update_tutorial_hint(score: int, stage: int) -> void:
	if tutorial_hint:

		var should_show: bool = score < 3 and stage == 1
		tutorial_hint.visible = should_show

		if not should_show:
			_show_tutorial = false

func _create_stage_toast() -> void:
	_stage_toast_container = CenterContainer.new()
	_stage_toast_container.name = "StageToast"
	_stage_toast_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_stage_toast_container.offset_top = 70
	_stage_toast_container.offset_bottom = 130
	_stage_toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_toast_container)

	_stage_toast_label = Label.new()
	_stage_toast_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stage_toast_label.add_theme_font_size_override("font_size", 32)
	_stage_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_stage_toast_label.modulate.a = 0.0
	_stage_toast_container.add_child(_stage_toast_label)

func _show_stage_toast(stage: int) -> void:
	if stage <= 1 or _stage_toast_label == null:
		return

	_stage_toast_label.text = "STAGE %d" % stage
	_stage_toast_started_at = Time.get_ticks_msec()
	_stage_toast_container.visible = true

func _update_stage_toast() -> void:
	if _stage_toast_started_at < 0 or _stage_toast_label == null:
		return

	var now := Time.get_ticks_msec()
	var elapsed := now - _stage_toast_started_at
	var fade_in := GameConstants.STAGE_TOAST_FADE_IN
	var hold := GameConstants.STAGE_TOAST_HOLD
	var fade_out := GameConstants.STAGE_TOAST_FADE_OUT
	var total := fade_in + hold + fade_out

	if elapsed >= total:
		_stage_toast_label.modulate.a = 0.0
		_stage_toast_container.visible = false
		_stage_toast_started_at = -1
		return

	var alpha := 1.0
	if elapsed < fade_in:
		alpha = float(elapsed) / float(fade_in)
	elif elapsed < fade_in + hold:
		alpha = 1.0
	else:
		alpha = 1.0 - float(elapsed - fade_in - hold) / float(fade_out)

	_stage_toast_label.modulate.a = clampf(alpha, 0.0, 1.0)

func _start_fever_pulse() -> void:
	if _fever_pulse_tween and _fever_pulse_tween.is_valid():
		return
	if not fever_bar_fill:
		return

	_fever_pulse_tween = create_tween()
	_fever_pulse_tween.set_loops()
	_fever_pulse_tween.tween_property(fever_bar_fill, "modulate:a", 0.6, 0.3)
	_fever_pulse_tween.tween_property(fever_bar_fill, "modulate:a", 1.0, 0.3)

func _stop_fever_pulse() -> void:
	if _fever_pulse_tween and _fever_pulse_tween.is_valid():
		_fever_pulse_tween.kill()
		_fever_pulse_tween = null

	if fever_bar_fill:
		fever_bar_fill.modulate.a = 1.0

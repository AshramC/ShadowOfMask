

extends CanvasLayer
class_name ScreenEffects

@onready var shake_container: Node2D = $ShakeContainer
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var vignette_overlay: ColorRect = $VignetteOverlay
@onready var fever_tint: ColorRect = $FeverTint
@onready var mark_overlay: ColorRect = get_node_or_null("MarkOverlay")
@onready var mask_bg: TextureRect = get_node_or_null("MaskBG")
@onready var mask_emblem: TextureRect = get_node_or_null("MaskEmblem")

var _shake_until: int = 0
var _shake_magnitude: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO

var _flash_until: int = 0
var _flash_duration: int = 0
var _flash_color: Color = Color.WHITE
var _flash_max_alpha: float = 0.5

var _vignette_until: int = 0
var _vignette_duration: int = 0
var _vignette_color: Color = Color.WHITE
var _vignette_max_alpha: float = 0.5

var _fever_tint_target: float = 0.0
var _fever_tint_current: float = 0.0

var _mark_intensity: float = 0.0

var _mask_texture: Texture2D
var _mask_broken_texture: Texture2D
var _mask_emblem_until: int = 0
var _mask_emblem_duration: int = 0
var _mask_emblem_type: String = ""

const MASK_BG_PATH := "res://godot_ui/assets/BG.png"
const MASK_BROKEN_PATH := "res://godot_ui/assets/BG_BROKEN.png"
const MASK_BG_FALLBACK := "res://client/src/BG.png"
const MASK_BROKEN_FALLBACK := "res://client/src/BG_BROKEN.png"

func _ready() -> void:

	_ensure_nodes()

	if flash_overlay:
		flash_overlay.color = Color(1, 1, 1, 0)
	if vignette_overlay:
		vignette_overlay.color = Color(1, 1, 1, 0)
	if fever_tint:
		fever_tint.color = Color(1, 0.85, 0.5, 0)
	if mark_overlay:
		mark_overlay.color = Color(GameConstants.MARK_BG_TINT.r, GameConstants.MARK_BG_TINT.g, GameConstants.MARK_BG_TINT.b, 0)

	_load_mask_textures()

	GameManager.fever_updated.connect(_on_fever_updated)

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()

	_update_shake(now)

	_update_flash(now)

	_update_vignette(now)

	_update_fever_tint(delta)

	_update_mark_background()
	_update_mask_emblem(now)

func shake(magnitude: float, duration_ms: int) -> void:
	var now := Time.get_ticks_msec()
	_shake_magnitude = magnitude
	_shake_until = now + duration_ms

func stop_shake() -> void:
	_shake_until = 0
	if shake_container:
		shake_container.position = _original_offset

func flash(color: Color, max_alpha: float, duration_ms: int) -> void:
	var now := Time.get_ticks_msec()
	_flash_color = color
	_flash_max_alpha = max_alpha
	_flash_duration = duration_ms
	_flash_until = now + duration_ms

func flash_mask_break() -> void:
	flash(Color(1, 0.31, 0.31), GameConstants.MASK_FLASH_ALPHA, GameConstants.MASK_FLASH_DURATION)
	_start_mask_emblem("break")

func flash_mask_restore() -> void:
	flash(Color.WHITE, GameConstants.MASK_FLASH_ALPHA, GameConstants.MASK_FLASH_DURATION)
	_start_mask_emblem("restore")

func flash_kill_impact(combo_level: int) -> void:
	var color := Color(1.0, 0.47, 0.35) if combo_level >= 5 else Color(1.0, 0.78, 0.55)
	flash(color, GameConstants.KILL_IMPACT_FLASH_ALPHA, GameConstants.KILL_IMPACT_FLASH_DURATION)

func vignette(color: Color, max_alpha: float, duration_ms: int) -> void:
	var now := Time.get_ticks_msec()
	_vignette_color = color
	_vignette_max_alpha = max_alpha
	_vignette_duration = duration_ms
	_vignette_until = now + duration_ms

func flash_fever_in() -> void:
	vignette(Color(1, 0.78, 0.47), GameConstants.FEVER_FLASH_ALPHA, GameConstants.FEVER_FLASH_DURATION)

func flash_fever_out() -> void:
	vignette(Color(0.47, 0.55, 0.63), GameConstants.FEVER_FLASH_ALPHA, GameConstants.FEVER_FLASH_DURATION)

func set_mark_intensity(intensity: float) -> void:
	_mark_intensity = clampf(intensity, 0.0, 1.0)

func _ensure_nodes() -> void:

	if not has_node("ShakeContainer"):
		shake_container = Node2D.new()
		shake_container.name = "ShakeContainer"
		add_child(shake_container)

	if not has_node("FlashOverlay"):
		flash_overlay = ColorRect.new()
		flash_overlay.name = "FlashOverlay"
		flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash_overlay.color = Color(1, 1, 1, 0)
		add_child(flash_overlay)

	if not has_node("VignetteOverlay"):
		vignette_overlay = ColorRect.new()
		vignette_overlay.name = "VignetteOverlay"
		vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vignette_overlay.color = Color(1, 1, 1, 0)
		add_child(vignette_overlay)

	if not has_node("FeverTint"):
		fever_tint = ColorRect.new()
		fever_tint.name = "FeverTint"
		fever_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
		fever_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fever_tint.color = Color(1, 0.85, 0.5, 0)
		add_child(fever_tint)

	if not has_node("MarkOverlay"):
		mark_overlay = ColorRect.new()
		mark_overlay.name = "MarkOverlay"
		mark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		mark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark_overlay.color = Color(GameConstants.MARK_BG_TINT.r, GameConstants.MARK_BG_TINT.g, GameConstants.MARK_BG_TINT.b, 0)
		mark_overlay.z_index = -10
		add_child(mark_overlay)
		if flash_overlay:
			var flash_index := get_children().find(flash_overlay)
			if flash_index >= 0:
				move_child(mark_overlay, flash_index)

	if not has_node("MaskBG"):
		mask_bg = TextureRect.new()
		mask_bg.name = "MaskBG"
		mask_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mask_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mask_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mask_bg.modulate = Color(1, 1, 1, 0)
		mask_bg.z_index = -20
		add_child(mask_bg)

	if not has_node("MaskEmblem"):
		mask_emblem = TextureRect.new()
		mask_emblem.name = "MaskEmblem"
		mask_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mask_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mask_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mask_emblem.modulate = Color(1, 1, 1, 0)
		mask_emblem.visible = false
		mask_emblem.z_index = 5
		add_child(mask_emblem)

func _update_shake(now: int) -> void:
	if not shake_container:
		return

	if now < _shake_until:
		var progress := float(_shake_until - now) / GameConstants.SCREEN_SHAKE_DURATION
		var magnitude := _shake_magnitude * maxf(progress, 0.1)
		var offset_x := (randf() * 2 - 1) * magnitude
		var offset_y := (randf() * 2 - 1) * magnitude
		shake_container.position = _original_offset + Vector2(offset_x, offset_y)
	else:
		shake_container.position = _original_offset

func _update_flash(now: int) -> void:
	if not flash_overlay:
		return

	if now < _flash_until and _flash_duration > 0:
		var remaining := float(_flash_until - now)
		var t := remaining / _flash_duration
		var alpha := _flash_max_alpha * t
		flash_overlay.color = Color(_flash_color.r, _flash_color.g, _flash_color.b, alpha)
	else:
		flash_overlay.color.a = 0

func _update_vignette(now: int) -> void:
	if not vignette_overlay:
		return

	if now < _vignette_until and _vignette_duration > 0:
		var remaining := float(_vignette_until - now)
		var t := remaining / _vignette_duration
		var alpha := _vignette_max_alpha * t
		vignette_overlay.color = Color(_vignette_color.r, _vignette_color.g, _vignette_color.b, alpha)
	else:
		vignette_overlay.color.a = 0

func _update_fever_tint(delta: float) -> void:
	if not fever_tint:
		return

	_fever_tint_current = lerpf(_fever_tint_current, _fever_tint_target, 0.1)

	if _fever_tint_current < 0.01:
		_fever_tint_current = 0

	fever_tint.color.a = _fever_tint_current

func _update_mark_background() -> void:
	if not mark_overlay:
		return

	if _mark_intensity <= 0.0:
		mark_overlay.color.a = 0.0
		if mask_bg:
			mask_bg.modulate.a = 0.0
		return

	var alpha := lerpf(GameConstants.MARK_BG_ALPHA_MIN, GameConstants.MARK_BG_ALPHA_MAX, _mark_intensity)
	mark_overlay.color = Color(GameConstants.MARK_BG_TINT.r, GameConstants.MARK_BG_TINT.g, GameConstants.MARK_BG_TINT.b, alpha)
	_update_mask_layout()

	if mask_bg:
		mask_bg.modulate = Color(1, 1, 1, alpha * 0.7)

func _on_fever_updated(meter: float, active: bool) -> void:
	_fever_tint_target = GameConstants.FEVER_TINT_ALPHA if active else 0.0

func _load_mask_textures() -> void:
	_mask_texture = _load_texture_with_fallback(MASK_BG_PATH, MASK_BG_FALLBACK)
	_mask_broken_texture = _load_texture_with_fallback(MASK_BROKEN_PATH, MASK_BROKEN_FALLBACK)

	if mask_bg and _mask_texture:
		mask_bg.texture = _mask_texture

func _load_texture_with_fallback(primary: String, fallback: String) -> Texture2D:
	if ResourceLoader.exists(primary):
		return load(primary) as Texture2D
	if ResourceLoader.exists(fallback):
		return load(fallback) as Texture2D
	return null

func _update_mask_layout() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var size := minf(viewport_rect.size.x, viewport_rect.size.y) * GameConstants.MASK_EMBLEM_SIZE_RATIO
	var pos := (viewport_rect.size - Vector2(size, size)) * 0.5

	if mask_bg:
		mask_bg.size = Vector2(size, size)
		mask_bg.position = pos

	if mask_emblem and mask_emblem.visible:
		mask_emblem.position = pos

func _start_mask_emblem(kind: String) -> void:
	_mask_emblem_type = kind
	_mask_emblem_duration = GameConstants.MASK_EMBLEM_BREAK_DURATION if kind == "break" else GameConstants.MASK_EMBLEM_RESTORE_DURATION
	_mask_emblem_until = Time.get_ticks_msec() + _mask_emblem_duration

	if mask_emblem:
		mask_emblem.texture = _mask_broken_texture if kind == "break" else _mask_texture
		mask_emblem.visible = true
		_update_mask_layout()

func _update_mask_emblem(now: int) -> void:
	if not mask_emblem or _mask_emblem_duration <= 0:
		return

	if now >= _mask_emblem_until:
		mask_emblem.visible = false
		mask_emblem.modulate.a = 0.0
		return

	var elapsed := float(_mask_emblem_until - now)
	var t := 1.0 - (elapsed / float(_mask_emblem_duration))
	var max_alpha := GameConstants.MASK_EMBLEM_ALPHA_BREAK if _mask_emblem_type == "break" else GameConstants.MASK_EMBLEM_ALPHA_RESTORE
	var alpha := max_alpha * (1.0 - t)
	var base_size := minf(get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y) * GameConstants.MASK_EMBLEM_SIZE_RATIO
	var start_scale := 1.2 if _mask_emblem_type == "break" else 0.9
	var end_scale := 1.0
	var size := base_size * lerpf(start_scale, end_scale, t)
	var pos := (get_viewport().get_visible_rect().size - Vector2(size, size)) * 0.5

	mask_emblem.size = Vector2(size, size)
	mask_emblem.position = pos
	mask_emblem.modulate = Color(1, 1, 1, alpha)

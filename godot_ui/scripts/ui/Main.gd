

extends Control

const GameWorldScene := preload("res://godot_ui/scenes/GameWorld.tscn")
const ScreenEffectsScene := preload("res://godot_ui/scenes/ScreenEffects.tscn")
const FeverBarUIScene := preload("res://godot_ui/scenes/FeverBarUI.tscn")

@onready var hud: Control = %HUD

@onready var menu_overlay: Control = %MenuOverlay

@onready var game_area: Node2D = $GameArea

@onready var game_background: ColorRect = $GameBackground

var game_world: GameWorld
var screen_effects: ScreenEffects
var fever_bar_ui: FeverBarUI

const COLOR_BG_NORMAL := Color(0.08, 0.08, 0.12, 1)
const COLOR_BG_BROKEN := Color(0.15, 0.05, 0.05, 1)
const COLOR_BG_FEVER := Color(0.12, 0.1, 0.06, 1)

func _ready() -> void:
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.mask_state_changed.connect(_on_mask_state_changed)
	GameManager.fever_updated.connect(_on_fever_updated)

	_init_game_world()
	_init_screen_effects()
	_init_fever_ui()
	_update_ui_for_phase(GameManager.current_phase)

	print("[Main] Initialized")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameManager.current_phase == GameManager.GamePhase.MENU:
			GameManager.start_game()
			return

func _init_game_world() -> void:
	if game_area == null:
		game_area = Node2D.new()
		game_area.name = "GameArea"
		add_child(game_area)
		move_child(game_area, 1)

	if GameWorldScene:
		game_world = GameWorldScene.instantiate() as GameWorld
	else:
		game_world = GameWorld.new()

	game_world.name = "GameWorld"
	game_area.add_child(game_world)

func _init_screen_effects() -> void:
	if ScreenEffectsScene:
		screen_effects = ScreenEffectsScene.instantiate() as ScreenEffects
	else:
		screen_effects = ScreenEffects.new()

	screen_effects.name = "ScreenEffects"
	add_child(screen_effects)

func _init_fever_ui() -> void:
	if FeverBarUIScene:
		fever_bar_ui = FeverBarUIScene.instantiate() as FeverBarUI
	else:
		fever_bar_ui = FeverBarUI.new()

	fever_bar_ui.name = "FeverBarUI"

	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 15
	ui_layer.name = "FeverUILayer"
	add_child(ui_layer)
	ui_layer.add_child(fever_bar_ui)

func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	_update_ui_for_phase(new_phase)

func _on_mask_state_changed(is_masked: bool, _shattered_kills: int) -> void:
	if GameManager.current_phase == GameManager.GamePhase.PLAYING:
		_update_background_color()

func _on_fever_updated(meter: float, active: bool) -> void:
	if GameManager.current_phase == GameManager.GamePhase.PLAYING:
		_update_background_color()

	if fever_bar_ui:
		var remaining_ratio := 1.0
		if game_world and game_world.fever_system:
			remaining_ratio = game_world.fever_system.get_fever_remaining_ratio()
		fever_bar_ui.update_fever(meter, active, remaining_ratio)

func _update_ui_for_phase(phase: GameManager.GamePhase) -> void:
	match phase:
		GameManager.GamePhase.MENU:
			hud.visible = false
			menu_overlay.visible = true
			menu_overlay.show_menu_card()
			if fever_bar_ui:
				fever_bar_ui.visible = false
			_set_background_color(COLOR_BG_NORMAL)

		GameManager.GamePhase.PLAYING:
			hud.visible = true
			menu_overlay.visible = false
			if fever_bar_ui:
				fever_bar_ui.visible = true
			_update_background_color()

		GameManager.GamePhase.GAMEOVER:
			hud.visible = false
			menu_overlay.visible = true
			menu_overlay.show_gameover_card()
			if fever_bar_ui:
				fever_bar_ui.visible = false
			_set_background_color(COLOR_BG_NORMAL)

	print("[Main] Phase changed to: ", GameManager.GamePhase.keys()[phase])

func _update_background_color() -> void:
	var target_color: Color

	if GameManager.fever_active:
		target_color = COLOR_BG_FEVER
	elif not GameManager.is_masked:
		target_color = COLOR_BG_BROKEN
	else:
		target_color = COLOR_BG_NORMAL

	_tween_background_color(target_color)

func _set_background_color(color: Color) -> void:
	if game_background:
		game_background.color = color

func _tween_background_color(target_color: Color) -> void:
	if game_background:
		var tween := create_tween()
		tween.tween_property(game_background, "color", target_color, 0.3)

func get_game_area() -> Node2D:
	return game_area

func get_game_world() -> GameWorld:
	return game_world

func get_screen_effects() -> ScreenEffects:
	return screen_effects

func shake_screen(magnitude: float, duration_ms: int) -> void:
	if screen_effects:
		screen_effects.shake(magnitude, duration_ms)

func flash_screen(color: Color, alpha: float, duration_ms: int) -> void:
	if screen_effects:
		screen_effects.flash(color, alpha, duration_ms)


## Main.gd
## 涓诲満鏅帶鍒惰剼鏈?## 璐熻矗鏍规嵁娓告垙闃舵鍒囨崲 HUD 鍜?MenuOverlay 鐨勬樉绀虹姸鎬?## 绠＄悊 GameWorld 鍜
# ScreenEffects

extends Control

# ============================================================
# 棰勫姞杞
# ============================================================

const GameWorldScene := preload("res://godot_ui/scenes/GameWorld.tscn")
const ScreenEffectsScene := preload("res://godot_ui/scenes/ScreenEffects.tscn")
const FeverBarUIScene := preload("res://godot_ui/scenes/FeverBarUI.tscn")

# ============================================================
# 鑺傜偣寮曠敤
# ============================================================

## HUD 鑺傜偣
@onready var hud: Control = %HUD

## 鑿滃崟閬僵鑺傜偣
@onready var menu_overlay: Control = %MenuOverlay

## 娓告垙鍖哄煙锛堥鐣欑粰娓告垙閫昏緫锛
@onready var game_area: Node2D = $GameArea

## 娓告垙鑳屾櫙
@onready var game_background: ColorRect = $GameBackground

# ============================================================
# 鍔ㄦ€佸垱寤虹殑鑺傜偣
# ============================================================

var game_world: GameWorld
var screen_effects: ScreenEffects
var fever_bar_ui: FeverBarUI

# ============================================================
# 棰滆壊甯搁噺
# ============================================================

const COLOR_BG_NORMAL := Color(0.08, 0.08, 0.12, 1)
const COLOR_BG_BROKEN := Color(0.15, 0.05, 0.05, 1)
const COLOR_BG_FEVER := Color(0.12, 0.1, 0.06, 1)
# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 杩炴帴 GameManager 淇″彿
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.mask_state_changed.connect(_on_mask_state_changed)
	GameManager.fever_updated.connect(_on_fever_updated)
	
	# 鍒濆鍖栨父鎴忎笘鐣
	_init_game_world()
	
	# 鍒濆鍖栧睆骞曟晥鏋
	_init_screen_effects()
	
	# 鍒濆鍖
	# Initialize Fever UI
	_init_fever_ui()
	
	# 鍒濆鍖
	# Initialize UI state
	_update_ui_for_phase(GameManager.current_phase)
	
	print("[Main] Initialized")


	# ============================================================
	# 鍒濆鍖栨柟娉
	# ============================================================

func _init_game_world() -> void:
	if game_area == null:
		game_area = Node2D.new()
		game_area.name = "GameArea"
		add_child(game_area)
		move_child(game_area, 1)  # 鍦ㄨ儗鏅箣鍚?	
	# 鍒涘缓 GameWorld
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
	
	# 娣诲姞鍒
	# HUD 灞
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 15
	ui_layer.name = "FeverUILayer"
	add_child(ui_layer)
	ui_layer.add_child(fever_bar_ui)


	# ============================================================
	# 淇″彿鍥炶皟
	# ============================================================

## 娓告垙闃舵鍙樺寲鍥炶皟
func _on_phase_changed(new_phase: GameManager.GamePhase) -> void:
	_update_ui_for_phase(new_phase)


## 闈㈠叿鐘舵€佸彉鍖栧洖璋冿紙鏇存柊鑳屾櫙鑹诧級
func _on_mask_state_changed(is_masked: bool, _shattered_kills: int) -> void:
	if GameManager.current_phase == GameManager.GamePhase.PLAYING:
		_update_background_color()


## Fever 鐘舵€佹洿鏂
func _on_fever_updated(meter: float, active: bool) -> void:
	if GameManager.current_phase == GameManager.GamePhase.PLAYING:
		_update_background_color()
	
	# 鏇存柊 Fever UI
	if fever_bar_ui:
		var remaining_ratio := 1.0
		if game_world and game_world.fever_system:
			remaining_ratio = game_world.fever_system.get_fever_remaining_ratio()
		fever_bar_ui.update_fever(meter, active, remaining_ratio)


		# ============================================================
		# 绉佹湁鏂规硶
		# ============================================================

## 鏍规嵁娓告垙闃舵鏇存柊 UI 鏄剧ず
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


## 鏇存柊鑳屾櫙棰滆壊锛堟牴鎹綋鍓嶆父鎴忕姸鎬侊級
func _update_background_color() -> void:
	var target_color: Color
	
	if GameManager.fever_active:
		target_color = COLOR_BG_FEVER
	elif not GameManager.is_masked:
		target_color = COLOR_BG_BROKEN
	else:
		target_color = COLOR_BG_NORMAL
	
	_tween_background_color(target_color)


## 璁剧疆鑳屾櫙棰滆壊锛堟棤杩囨浮锛
func _set_background_color(color: Color) -> void:
	if game_background:
		game_background.color = color


## Tween 鑳屾櫙棰滆壊
func _tween_background_color(target_color: Color) -> void:
	if game_background:
		var tween := create_tween()
		tween.tween_property(game_background, "color", target_color, 0.3)


		# ============================================================
		# 鍏叡鏂规硶锛堜緵娓告垙閫昏緫璋冪敤锛
		# ============================================================

## 鑾峰彇娓告垙鍖哄煙鑺傜偣锛堢敤浜庢坊鍔犳父鎴忓璞★級
func get_game_area() -> Node2D:
	return game_area


## 鑾峰彇 GameWorld 瀹炰緥
func get_game_world() -> GameWorld:
	return game_world


## 鑾峰彇 ScreenEffects 瀹炰緥
func get_screen_effects() -> ScreenEffects:
	return screen_effects


## 瑙﹀彂灞忓箷闇囧姩
func shake_screen(magnitude: float, duration_ms: int) -> void:
	if screen_effects:
		screen_effects.shake(magnitude, duration_ms)


## 瑙﹀彂灞忓箷闂厜
func flash_screen(color: Color, alpha: float, duration_ms: int) -> void:
	if screen_effects:
		screen_effects.flash(color, alpha, duration_ms)


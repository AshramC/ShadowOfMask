## MenuOverlay.gd
## 鑿滃崟閬僵鎺у埗鑴氭湰
## 璐熻矗涓昏彍鍗曞拰娓告垙缁撴潫鐣岄潰鐨勬樉绀轰笌浜や簰
##
## 浣跨敤鏂瑰紡锛?## 灏嗘鑴氭湰闄勫姞鍒
# MenuOverlay.tscn 鐨勬牴鑺傜偣 (MenuOverlay)

extends Control

# ============================================================
# 鑺傜偣寮曠敤
# ============================================================

# 涓昏彍鍗曞崱鐗
@onready var menu_card: PanelContainer = %MenuCard
@onready var start_button: Button = %StartButton
@onready var leaderboard_list: VBoxContainer = %LeaderboardList
@onready var empty_text: Label = %EmptyText

# 娓告垙缁撴潫鍗＄墖
@onready var game_over_card: PanelContainer = %GameOverCard
@onready var final_stage_value: Label = %FinalStageValue
@onready var final_kills_value: Label = %FinalKillsValue
@onready var game_over_leaderboard_list: VBoxContainer = %GameOverLeaderboardList
@onready var name_input: LineEdit = %NameInput
@onready var save_button: Button = %SaveButton
@onready var back_to_menu_button: Button = %BackToMenuButton
@onready var retry_button: Button = %RetryButton

# ============================================================
# 甯搁噺
# ============================================================

## 鎺掑悕寰界珷棰滆壊
const RANK_COLORS := {
	1: Color(1.0, 0.84, 0.0),      # 閲戣壊
	2: Color(0.75, 0.75, 0.75),    # 閾惰壊
	3: Color(0.8, 0.5, 0.2),       # 閾滆壊
}
const RANK_COLOR_DEFAULT := Color(0.4, 0.4, 0.4)  # 鍏朵粬鎺掑悕

## 楂樹寒鏍峰紡锛堝綋鍓嶇帺瀹讹級
const HIGHLIGHT_BG_COLOR := Color(0.25, 0.2, 0.05, 0.3)
const HIGHLIGHT_BORDER_COLOR := Color(0.6, 0.5, 0.2, 0.5)

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 杩炴帴鎸夐挳淇″彿
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_button_pressed)
	if back_to_menu_button:
		back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_button_pressed)
	if name_input:
		name_input.text_changed.connect(_on_name_input_changed)
		name_input.text_submitted.connect(_on_name_input_submitted)
	
	# 杩炴帴 GameManager 淇″彿
	GameManager.game_over.connect(_on_game_over)
	GameManager.leaderboard_refresh_requested.connect(_on_leaderboard_refresh_requested)
	
	# 杩炴帴 LeaderboardManager 淇″彿
	LeaderboardManager.leaderboard_updated.connect(_on_leaderboard_updated)
	
	# 鍒濆鍖栨樉绀
	_initialize_ui()
	
	print("[MenuOverlay] Initialized")


	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鏄剧ず涓昏彍鍗曞崱鐗
func show_menu_card() -> void:
	if menu_card:
		menu_card.visible = true
	if game_over_card:
		game_over_card.visible = false
	_refresh_leaderboard(leaderboard_list, false)


## 鏄剧ず娓告垙缁撴潫鍗＄墖
func show_gameover_card() -> void:
	if menu_card:
		menu_card.visible = false
	if game_over_card:
		game_over_card.visible = true
	
	# 鏇存柊鏈€缁堟垚缁
	if final_stage_value:
		final_stage_value.text = str(GameManager.final_stage)
	if final_kills_value:
		final_kills_value.text = str(GameManager.final_score)
	
	# 閲嶇疆淇濆瓨鐘舵€
	_reset_save_state()
	
	# 璁剧疆榛樿鐜╁鍚
	if name_input:
		name_input.text = GameManager.player_name
	
	# 鍒锋柊缁撶畻鎺掕姒
	_refresh_leaderboard(game_over_leaderboard_list, true)


	# ============================================================
	# 淇″彿鍥炶皟 - 鎸夐挳
	# ============================================================

func _on_start_button_pressed() -> void:
	print("[MenuOverlay] Start button pressed")
	GameManager.start_game()


func _on_save_button_pressed() -> void:
	if GameManager.result_saved:
		return
	
	var player_name := name_input.text.strip_edges() if name_input else ""
	if player_name.is_empty():
		player_name = GameManager.DEFAULT_PLAYER_NAME
	
	# 淇濆瓨鍒版帓琛屾
	LeaderboardManager.save_result(
		player_name,
		GameManager.final_stage,
		GameManager.final_score
	)
	
	# 鏇存柊 GameManager 鐘舵€
	GameManager.player_name = player_name
	GameManager.mark_result_saved(player_name)
	
	# 鏇存柊鎸夐挳鐘舵€
	if save_button:
		save_button.text = "Saved"
		save_button.disabled = true
	
	# 鍒锋柊鎺掕姒滄樉绀猴紙浼氳嚜鍔ㄩ珮浜綋鍓嶇帺瀹讹級
	_refresh_leaderboard(game_over_leaderboard_list, true)
	
	print("[MenuOverlay] Result saved for: ", player_name)


func _on_back_to_menu_pressed() -> void:
	_ensure_result_saved()
	GameManager.go_to_menu()


func _on_retry_button_pressed() -> void:
	_ensure_result_saved()
	GameManager.start_game()


func _on_name_input_changed(new_text: String) -> void:
	# 鏇存柊 GameManager 涓殑鐜╁鍚
	GameManager.player_name = new_text.strip_edges()


func _on_name_input_submitted(_new_text: String) -> void:
	# 鎸夊洖杞︽椂鑷姩淇濆瓨
	if not GameManager.result_saved:
		_on_save_button_pressed()


		# ============================================================
		# 淇″彿鍥炶皟 - GameManager
		# ============================================================

func _on_game_over(final_score: int, final_stage: int) -> void:
	print("[MenuOverlay] Game over received - Stage: %d, Score: %d" % [final_stage, final_score])


func _on_leaderboard_refresh_requested() -> void:
	if menu_card and menu_card.visible:
		_refresh_leaderboard(leaderboard_list, false)


		# ============================================================
		# 淇″彿鍥炶皟 - LeaderboardManager
		# ============================================================

func _on_leaderboard_updated(_entries: Array) -> void:
	# 鎺掕姒滄暟鎹洿鏂版椂鍒锋柊鏄剧ず
	if menu_card and menu_card.visible:
		_refresh_leaderboard(leaderboard_list, false)
	elif game_over_card and game_over_card.visible:
		_refresh_leaderboard(game_over_leaderboard_list, true)


		# ============================================================
		# 绉佹湁鏂规硶
		# ============================================================

## 鍒濆鍖
## Initialize UI
func _initialize_ui() -> void:
	# 榛樿鏄剧ず涓昏彍鍗
	if menu_card:
		menu_card.visible = true
	if game_over_card:
		game_over_card.visible = false
	
	# 鍒锋柊鎺掕姒
	_refresh_leaderboard(leaderboard_list, false)


## 閲嶇疆淇濆瓨鐘舵€
func _reset_save_state() -> void:
	if save_button:
		save_button.text = "Saved"
		save_button.disabled = false


## 纭繚鎴愮哗宸蹭繚瀛
func _ensure_result_saved() -> void:
	if not GameManager.result_saved and GameManager.current_phase == GameManager.GamePhase.GAMEOVER:
		_on_save_button_pressed()


## 鍒锋柊鎺掕姒滄樉绀
func _refresh_leaderboard(list_container: VBoxContainer, highlight_current: bool) -> void:
	if not list_container:
		return
	
	var entries := LeaderboardManager.get_leaderboard()
	
	# 鑾峰彇鎵€鏈夋帓琛屾鏉＄洰鑺傜偣
	var item_nodes := _get_leaderboard_item_nodes(list_container)
	
	# 鏇存柊鎴栭殣钘忔潯鐩
	for i in range(item_nodes.size()):
		var item_node: PanelContainer = item_nodes[i]
		
		if i < entries.size():
			var entry: LeaderboardManager.LeaderboardEntry = entries[i]
			_update_leaderboard_item(item_node, i + 1, entry, highlight_current)
			item_node.visible = true
		else:
			item_node.visible = false
	
	# 鏄剧ず/闅愯棌绌哄垪琛ㄦ彁绀
	if list_container == leaderboard_list and empty_text:
		empty_text.visible = entries.is_empty()


## 鑾峰彇鎺掕姒滄潯鐩妭鐐瑰垪琛
func _get_leaderboard_item_nodes(list_container: VBoxContainer) -> Array[PanelContainer]:
	var result: Array[PanelContainer] = []
	
	for child in list_container.get_children():
		if child is PanelContainer:
			# 鍖归厤 LeaderboardItem 鎴
			# GOLeaderboardItem 鍓嶇紑
			if child.name.begins_with("LeaderboardItem") or child.name.begins_with("GOLeaderboardItem"):
				result.append(child)
	
	return result


## 鏇存柊鍗曚釜鎺掕姒滄潯鐩
func _update_leaderboard_item(
	item_node: PanelContainer,
	rank: int,
	entry: LeaderboardManager.LeaderboardEntry,
	highlight_current: bool
) -> void:
	# 鏌ユ壘瀛愯妭鐐癸紙鍏煎涓嶅悓鍛藉悕鏂瑰紡锛
	var rank_badge: Label = _find_child_label(item_node, "RankBadge")
	var player_name_label: Label = _find_child_label(item_node, "PlayerName")
	var stage_value: Label = _find_child_label(item_node, "StageValue")
	var kills_value: Label = _find_child_label(item_node, "KillsValue")
	
	# 鏇存柊鎺掑悕
	if rank_badge:
		rank_badge.text = str(rank)
		rank_badge.modulate = RANK_COLORS.get(rank, RANK_COLOR_DEFAULT)
	
	# 鏇存柊鐜╁鍚
	if player_name_label:
		player_name_label.text = entry.player_name
	
	# 鏇存柊 Stage
	if stage_value:
		stage_value.text = "Stage %d" % entry.stage
	
	# 鏇存柊鍑绘潃鏁
	if kills_value:
		kills_value.text = "%d kills" % entry.score
	
	# 楂樹寒褰撳墠鐜╁锛堝鏋滈渶瑕侊級
	if highlight_current:
		var is_current := LeaderboardManager.is_entry_match(
			entry,
			GameManager.last_saved_name,
			GameManager.final_stage,
			GameManager.final_score
		)
		_set_item_highlight(item_node, is_current)
	else:
		_set_item_highlight(item_node, false)


## 鏌ユ壘瀛愯妭鐐逛腑鐨
# Label锛堥€掑綊锛
func _find_child_label(node: Node, name_contains: String) -> Label:
	for child in node.get_children():
		if child is Label and name_contains in child.name:
			return child
		
		var result := _find_child_label(child, name_contains)
		if result:
			return result
	
	return null


## 璁剧疆鏉＄洰楂樹寒鐘舵€
func _set_item_highlight(item_node: PanelContainer, is_highlighted: bool) -> void:
	if is_highlighted:
		# 鍒涘缓楂樹寒鏍峰紡
		var style := StyleBoxFlat.new()
		style.bg_color = HIGHLIGHT_BG_COLOR
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = HIGHLIGHT_BORDER_COLOR
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		
		item_node.add_theme_stylebox_override("panel", style)
	else:
		# 绉婚櫎楂樹寒鏍峰紡锛屾仮澶嶉粯璁
		item_node.remove_theme_stylebox_override("panel")




extends Control

@onready var menu_card: PanelContainer = %MenuCard
@onready var start_button: Button = %StartButton
@onready var leaderboard_list: VBoxContainer = %LeaderboardList
@onready var empty_text: Label = %EmptyText

@onready var game_over_card: PanelContainer = %GameOverCard
@onready var final_stage_value: Label = %FinalStageValue
@onready var final_kills_value: Label = %FinalKillsValue
@onready var game_over_leaderboard_list: VBoxContainer = %GameOverLeaderboardList
@onready var name_input: LineEdit = %NameInput
@onready var save_button: Button = %SaveButton
@onready var back_to_menu_button: Button = %BackToMenuButton
@onready var retry_button: Button = %RetryButton

const RANK_COLORS := {
	1: Color(1.0, 0.84, 0.0),
	2: Color(0.75, 0.75, 0.75),
	3: Color(0.8, 0.5, 0.2),
}
const RANK_COLOR_DEFAULT := Color(0.4, 0.4, 0.4)

const HIGHLIGHT_BG_COLOR := Color(0.25, 0.2, 0.05, 0.3)
const HIGHLIGHT_BORDER_COLOR := Color(0.6, 0.5, 0.2, 0.5)

func _ready() -> void:

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

	GameManager.game_over.connect(_on_game_over)
	GameManager.leaderboard_refresh_requested.connect(_on_leaderboard_refresh_requested)

	LeaderboardManager.leaderboard_updated.connect(_on_leaderboard_updated)

	_initialize_ui()

	print("[MenuOverlay] Initialized")

func show_menu_card() -> void:
	if menu_card:
		menu_card.visible = true
	if game_over_card:
		game_over_card.visible = false
	_refresh_leaderboard(leaderboard_list, false)

func show_gameover_card() -> void:
	if menu_card:
		menu_card.visible = false
	if game_over_card:
		game_over_card.visible = true

	if final_stage_value:
		final_stage_value.text = str(GameManager.final_stage)
	if final_kills_value:
		final_kills_value.text = str(GameManager.final_score)

	_reset_save_state()

	if name_input:
		name_input.text = GameManager.player_name

	_refresh_leaderboard(game_over_leaderboard_list, true)

func _on_start_button_pressed() -> void:
	print("[MenuOverlay] Start button pressed")
	GameManager.start_game()

func _on_save_button_pressed() -> void:
	if GameManager.result_saved:
		return

	var player_name := name_input.text.strip_edges() if name_input else ""
	if player_name.is_empty():
		player_name = GameManager.DEFAULT_PLAYER_NAME

	LeaderboardManager.save_result(
		player_name,
		GameManager.final_stage,
		GameManager.final_score
	)

	GameManager.player_name = player_name
	GameManager.mark_result_saved(player_name)

	if save_button:
		save_button.text = "Saved"
		save_button.disabled = true

	_refresh_leaderboard(game_over_leaderboard_list, true)

	print("[MenuOverlay] Result saved for: ", player_name)

func _on_back_to_menu_pressed() -> void:
	_ensure_result_saved()
	GameManager.go_to_menu()

func _on_retry_button_pressed() -> void:
	_ensure_result_saved()
	GameManager.start_game()

func _on_name_input_changed(new_text: String) -> void:

	GameManager.player_name = new_text.strip_edges()

func _on_name_input_submitted(_new_text: String) -> void:

	if not GameManager.result_saved:
		_on_save_button_pressed()

func _on_game_over(final_score: int, final_stage: int) -> void:
	print("[MenuOverlay] Game over received - Stage: %d, Score: %d" % [final_stage, final_score])

func _on_leaderboard_refresh_requested() -> void:
	if menu_card and menu_card.visible:
		_refresh_leaderboard(leaderboard_list, false)

func _on_leaderboard_updated(_entries: Array) -> void:

	if menu_card and menu_card.visible:
		_refresh_leaderboard(leaderboard_list, false)
	elif game_over_card and game_over_card.visible:
		_refresh_leaderboard(game_over_leaderboard_list, true)

func _initialize_ui() -> void:

	if menu_card:
		menu_card.visible = true
	if game_over_card:
		game_over_card.visible = false

	_refresh_leaderboard(leaderboard_list, false)

func _reset_save_state() -> void:
	if save_button:
		save_button.text = "Saved"
		save_button.disabled = false

func _ensure_result_saved() -> void:
	if not GameManager.result_saved and GameManager.current_phase == GameManager.GamePhase.GAMEOVER:
		_on_save_button_pressed()

func _refresh_leaderboard(list_container: VBoxContainer, highlight_current: bool) -> void:
	if not list_container:
		return

	var entries := LeaderboardManager.get_leaderboard()

	var item_nodes := _get_leaderboard_item_nodes(list_container)

	for i in range(item_nodes.size()):
		var item_node: PanelContainer = item_nodes[i]

		if i < entries.size():
			var entry: LeaderboardManager.LeaderboardEntry = entries[i]
			_update_leaderboard_item(item_node, i + 1, entry, highlight_current)
			item_node.visible = true
		else:
			item_node.visible = false

	if list_container == leaderboard_list and empty_text:
		empty_text.visible = entries.is_empty()

func _get_leaderboard_item_nodes(list_container: VBoxContainer) -> Array[PanelContainer]:
	var result: Array[PanelContainer] = []

	for child in list_container.get_children():
		if child is PanelContainer:

			if child.name.begins_with("LeaderboardItem") or child.name.begins_with("GOLeaderboardItem"):
				result.append(child)

	return result

func _update_leaderboard_item(
	item_node: PanelContainer,
	rank: int,
	entry: LeaderboardManager.LeaderboardEntry,
	highlight_current: bool
) -> void:

	var rank_badge: Label = _find_child_label(item_node, "RankBadge")
	var player_name_label: Label = _find_child_label(item_node, "PlayerName")
	var stage_value: Label = _find_child_label(item_node, "StageValue")
	var kills_value: Label = _find_child_label(item_node, "KillsValue")

	if rank_badge:
		rank_badge.text = str(rank)
		rank_badge.modulate = RANK_COLORS.get(rank, RANK_COLOR_DEFAULT)

	if player_name_label:
		player_name_label.text = entry.player_name

	if stage_value:
		stage_value.text = "Stage %d" % entry.stage

	if kills_value:
		kills_value.text = "%d kills" % entry.score

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

func _find_child_label(node: Node, name_contains: String) -> Label:
	for child in node.get_children():
		if child is Label and name_contains in child.name:
			return child

		var result := _find_child_label(child, name_contains)
		if result:
			return result

	return null

func _set_item_highlight(item_node: PanelContainer, is_highlighted: bool) -> void:
	if is_highlighted:

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

		item_node.remove_theme_stylebox_override("panel")



extends Node

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

signal leaderboard_updated(entries: Array)

class LeaderboardEntry:
	var player_name: String
	var stage: int
	var score: int
	var date: String

	func _init(p_name: String = "", p_stage: int = 0, p_score: int = 0, p_date: String = "") -> void:
		player_name = p_name
		stage = p_stage
		score = p_score
		date = p_date

	func to_dict() -> Dictionary:
		return {
			"player_name": player_name,
			"stage": stage,
			"score": score,
			"date": date
		}

	static func from_dict(data: Dictionary) -> LeaderboardEntry:
		return LeaderboardEntry.new(
			data.get("player_name", ""),
			data.get("stage", 0),
			data.get("score", 0),
			data.get("date", "")
		)

var _cached_entries: Array[LeaderboardEntry] = []

var _cache_valid: bool = false

func _ready() -> void:

	_load_from_file()
	print("[LeaderboardManager] Initialized with %d entries" % _cached_entries.size())

func get_leaderboard() -> Array[LeaderboardEntry]:
	if not _cache_valid:
		_load_from_file()

	var result: Array[LeaderboardEntry] = []
	for entry in _cached_entries:
		result.append(entry)
	return result

func save_result(player_name: String, stage: int, score: int) -> void:

	var entry := LeaderboardEntry.new(
		player_name if player_name.strip_edges() != "" else GameManager.DEFAULT_PLAYER_NAME,
		stage,
		score,
		_get_current_date_string()
	)

	_cached_entries.append(entry)

	_cached_entries.sort_custom(_compare_entries)

	if _cached_entries.size() > MAX_ENTRIES:
		_cached_entries.resize(MAX_ENTRIES)

	_save_to_file()

	leaderboard_updated.emit(_cached_entries)

	print("[LeaderboardManager] Saved: %s - Stage %d, %d kills" % [entry.player_name, stage, score])

func clear_leaderboard() -> void:
	_cached_entries.clear()
	_save_to_file()
	leaderboard_updated.emit(_cached_entries)
	print("[LeaderboardManager] Leaderboard cleared")

func is_entry_match(entry: LeaderboardEntry, player_name: String, stage: int, score: int) -> bool:
	return entry.player_name == player_name and entry.stage == stage and entry.score == score

func get_player_rank(player_name: String, stage: int, score: int) -> int:
	for i in range(_cached_entries.size()):
		if is_entry_match(_cached_entries[i], player_name, stage, score):
			return i + 1
	return -1

func get_entry_count() -> int:
	return _cached_entries.size()

func _load_from_file() -> void:
	_cached_entries.clear()

	if not FileAccess.file_exists(SAVE_PATH):
		_cache_valid = true
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[LeaderboardManager] Failed to open leaderboard file: %s" % FileAccess.get_open_error())
		_cache_valid = true
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_warning("[LeaderboardManager] Failed to parse leaderboard JSON: %s" % json.get_error_message())
		_cache_valid = true
		return

	var data = json.get_data()
	if data is Array:
		for item in data:
			if item is Dictionary:
				_cached_entries.append(LeaderboardEntry.from_dict(item))

	_cached_entries.sort_custom(_compare_entries)

	_cache_valid = true

func _save_to_file() -> void:
	var data: Array = []
	for entry in _cached_entries:
		data.append(entry.to_dict())

	var json_string := JSON.stringify(data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[LeaderboardManager] Failed to save leaderboard: %s" % FileAccess.get_open_error())
		return

	file.store_string(json_string)
	file.close()

func _compare_entries(a: LeaderboardEntry, b: LeaderboardEntry) -> bool:
	if a.stage != b.stage:
		return a.stage > b.stage
	return a.score > b.score

func _get_current_date_string() -> String:
	var datetime := Time.get_datetime_dict_from_system()
	return "%d/%d/%d" % [datetime.year, datetime.month, datetime.day]

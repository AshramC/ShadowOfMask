## LeaderboardManager.gd
## 鎺掕姒滄暟鎹鐞嗗櫒 (Autoload)
## 璐熻矗鎺掕姒滅殑璇诲彇銆佷繚瀛樸€佹帓搴
##
## 閰嶇疆鏂瑰紡锛?## 1. 鍦
# Godot 缂栬緫鍣ㄤ腑锛歅roject -> Project Settings -> Autoload
## 2. 娣诲姞姝よ剼鏈紝鍚嶇О璁句负 "LeaderboardManager"
## 3. 鍦ㄤ换鎰忚剼鏈腑閫氳繃 LeaderboardManager.xxx 璁块棶

extends Node

# ============================================================
# 甯搁噺
# ============================================================

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

# ============================================================
# 淇″彿
# ============================================================

## 鎺掕姒滄暟鎹洿鏂版椂瑙﹀彂
signal leaderboard_updated(entries: Array)

# ============================================================
# 鏁版嵁绫
# ============================================================

## 鎺掕姒滄潯鐩暟鎹被
class LeaderboardEntry:
	var player_name: String
	var stage: int
	var score: int  # Kills
	var date: String
	
	func _init(p_name: String = "", p_stage: int = 0, p_score: int = 0, p_date: String = "") -> void:
		player_name = p_name
		stage = p_stage
		score = p_score
		date = p_date
	
	## 杞崲涓哄瓧鍏革紙鐢ㄤ簬 JSON 搴忓垪鍖栵級
	func to_dict() -> Dictionary:
		return {
			"player_name": player_name,
			"stage": stage,
			"score": score,
			"date": date
		}
	
	## 浠庡瓧鍏稿垱寤猴紙鐢ㄤ簬 JSON 鍙嶅簭鍒楀寲锛
	static func from_dict(data: Dictionary) -> LeaderboardEntry:
		return LeaderboardEntry.new(
			data.get("player_name", ""),
			data.get("stage", 0),
			data.get("score", 0),
			data.get("date", "")
		)

		# ============================================================
		# 缂撳瓨鏁版嵁
		# ============================================================

## 缂撳瓨鐨勬帓琛屾鏁版嵁
var _cached_entries: Array[LeaderboardEntry] = []

## 缂撳瓨鏄惁鏈夋晥
var _cache_valid: bool = false

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _ready() -> void:
	# 鍒濆鍖栨椂鍔犺浇鎺掕姒
	_load_from_file()
	print("[LeaderboardManager] Initialized with %d entries" % _cached_entries.size())

	# ============================================================
	# 鍏叡鏂规硶
	# ============================================================

## 鑾峰彇鎺掕姒滄暟鎹紙杩斿洖鍓湰锛
func get_leaderboard() -> Array[LeaderboardEntry]:
	if not _cache_valid:
		_load_from_file()
	
	# 杩斿洖鍓湰锛岄槻姝㈠閮ㄤ慨鏀
	var result: Array[LeaderboardEntry] = []
	for entry in _cached_entries:
		result.append(entry)
	return result


## 淇濆瓨鎴愮哗鍒版帓琛屾
func save_result(player_name: String, stage: int, score: int) -> void:
	# 鍒涘缓鏂版潯鐩
	var entry := LeaderboardEntry.new(
		player_name if player_name.strip_edges() != "" else GameManager.DEFAULT_PLAYER_NAME,
		stage,
		score,
		_get_current_date_string()
	)
	
	# 娣诲姞鍒扮紦瀛
	_cached_entries.append(entry)
	
	# 鎺掑簭锛歋tage 闄嶅簭锛孲core 闄嶅簭
	_cached_entries.sort_custom(_compare_entries)
	
	# 鎴彇鍓
	if _cached_entries.size() > MAX_ENTRIES:
		_cached_entries.resize(MAX_ENTRIES)
	
	# 淇濆瓨鍒版枃浠
	_save_to_file()
	
	# 鍙戦€佹洿鏂颁俊鍙
	leaderboard_updated.emit(_cached_entries)
	
	print("[LeaderboardManager] Saved: %s - Stage %d, %d kills" % [entry.player_name, stage, score])


## 娓呯┖鎺掕姒滐紙璋冭瘯鐢級
func clear_leaderboard() -> void:
	_cached_entries.clear()
	_save_to_file()
	leaderboard_updated.emit(_cached_entries)
	print("[LeaderboardManager] Leaderboard cleared")


## 妫€鏌ユ煇鏉＄洰鏄惁鍖归厤锛堢敤浜庨珮浜樉绀猴級
func is_entry_match(entry: LeaderboardEntry, player_name: String, stage: int, score: int) -> bool:
	return entry.player_name == player_name and entry.stage == stage and entry.score == score


## 鑾峰彇鐜╁鍦ㄦ帓琛屾涓殑鎺掑悕锛
# Returns 1 if on leaderboard
func get_player_rank(player_name: String, stage: int, score: int) -> int:
	for i in range(_cached_entries.size()):
		if is_entry_match(_cached_entries[i], player_name, stage, score):
		return i + 1  # Rank starts at 1
	return -1


## 鑾峰彇鎺掕姒滄潯鐩暟閲
func get_entry_count() -> int:
	return _cached_entries.size()

	# ============================================================
	# 绉佹湁鏂规硶
	# ============================================================

## 浠庢枃浠跺姞杞芥帓琛屾
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
	
	# 纭繚鎺掑簭姝ｇ‘
	_cached_entries.sort_custom(_compare_entries)
	
	_cache_valid = true


## 淇濆瓨鎺掕姒滃埌鏂囦欢
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


## 鎺掑簭姣旇緝鍑芥暟锛歋tage 闄嶅簭 -> Score 闄嶅簭
func _compare_entries(a: LeaderboardEntry, b: LeaderboardEntry) -> bool:
	if a.stage != b.stage:
		return a.stage > b.stage  # Higher stage first
	return a.score > b.score  # Higher score first

## 鑾峰彇褰撳墠鏃ユ湡瀛楃涓
func _get_current_date_string() -> String:
	var datetime := Time.get_datetime_dict_from_system()
	return "%d/%d/%d" % [datetime.year, datetime.month, datetime.day]


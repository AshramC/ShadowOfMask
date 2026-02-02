## DashTrailRenderer.gd
## 鍐插埡杞ㄨ抗娓叉煋鍣
## 娓叉煋鐜╁鍐插埡鏃剁殑娈嬪奖鏁堟灉

extends Node2D
class_name DashTrailRenderer

# ============================================================
# 閰嶇疆
# ============================================================

@export var player_size: float = GameConstants.PLAYER_SIZE
@export var trail_color: Color = Color(1, 1, 1, 0.5)
@export var max_trail_points: int = 50

# ============================================================
# 鐘舵€
# ============================================================

var _trail_points: Array[Dictionary] = []  # {position: Vector2, life: float}

# ============================================================
# 寮曠敤
# ============================================================

var player: Node2D

# ============================================================
# 鐢熷懡鍛ㄦ湡
# ============================================================

func _process(delta: float) -> void:
	# 鏇存柊杞ㄨ抗鐐圭敓鍛
	for i in range(_trail_points.size() - 1, -1, -1):
		_trail_points[i]["life"] -= 0.03
		if _trail_points[i]["life"] <= 0:
			_trail_points.remove_at(i)
	
	queue_redraw()


func _draw() -> void:
	var half_size := player_size / 2.0
	
	for point in _trail_points:
		var pos: Vector2 = point["position"]
		var life: float = point["life"]
		var alpha := life * trail_color.a
		var color := Color(trail_color.r, trail_color.g, trail_color.b, alpha)
		
		# 缁樺埗娈嬪奖鏂瑰潡锛堢┖蹇冿級
		var rect := Rect2(pos.x - half_size, pos.y - half_size, player_size, player_size)
		draw_rect(rect, color, false, 2.0)


		# ============================================================
		# 鍏叡鏂规硶
		# ============================================================

## 娣诲姞杞ㄨ抗鐐
func add_point(pos: Vector2) -> void:
	if _trail_points.size() >= max_trail_points:
		_trail_points.pop_front()
	
	_trail_points.append({
		"position": pos,
		"life": 1.0
	})


## 浠
# Player 鑾峰彇杞ㄨ抗鐐
func sync_from_player(p: Node2D) -> void:
	player = p
	if player and player.has_method("get_trail_points"):
		var player_trail: Array = player.get_trail_points()
		_trail_points.clear()
		for point in player_trail:
			_trail_points.append(point.duplicate())


## 娓呴櫎杞ㄨ抗
func clear() -> void:
	_trail_points.clear()
	queue_redraw()


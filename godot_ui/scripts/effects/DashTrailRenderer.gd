

extends Node2D
class_name DashTrailRenderer

@export var player_size: float = GameConstants.PLAYER_SIZE
@export var trail_color: Color = Color(1, 1, 1, 0.5)
@export var max_trail_points: int = 50

var _trail_points: Array[Dictionary] = []

var player: Node2D

func _process(delta: float) -> void:

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

		var rect := Rect2(pos.x - half_size, pos.y - half_size, player_size, player_size)
		draw_rect(rect, color, false, 2.0)

func add_point(pos: Vector2) -> void:
	if _trail_points.size() >= max_trail_points:
		_trail_points.pop_front()

	_trail_points.append({
		"position": pos,
		"life": 1.0
	})

func sync_from_player(p: Node2D) -> void:
	player = p
	if player and player.has_method("get_trail_points"):
		var player_trail: Array = player.get_trail_points()
		_trail_points.clear()
		for point in player_trail:
			_trail_points.append(point.duplicate())

func clear() -> void:
	_trail_points.clear()
	queue_redraw()

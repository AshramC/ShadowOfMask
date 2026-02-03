

extends Node2D
class_name ParticleEmitter

class Particle:
	var position: Vector2
	var velocity: Vector2
	var life: float
	var color: Color
	var size: float

	func _init(pos: Vector2, vel: Vector2, col: Color, sz: float = 4.0):
		position = pos
		velocity = vel
		life = 1.0
		color = col
		size = sz

@export var max_particles: int = 500
@export var particle_size: float = 4.0
@export var decay_rate: float = 0.02
@export var gravity: Vector2 = Vector2.ZERO

var _particles: Array[Particle] = []

func _process(delta: float) -> void:

	for i in range(_particles.size() - 1, -1, -1):
		var p := _particles[i]
		p.position += p.velocity
		p.velocity += gravity * delta
		p.life -= decay_rate

		if p.life <= 0:
			_particles.remove_at(i)

	queue_redraw()

func _draw() -> void:
	for p in _particles:
		var alpha := p.life
		var color := Color(p.color.r, p.color.g, p.color.b, alpha)
		var half := p.size / 2.0
		draw_rect(Rect2(p.position.x - half, p.position.y - half, p.size, p.size), color)

func emit(pos: Vector2, color: Color, count: int, speed_min: float = 1.0, speed_max: float = 3.0) -> void:
	for i in range(count):
		if _particles.size() >= max_particles:
			break

		var angle := randf() * TAU
		var speed := speed_min + randf() * (speed_max - speed_min)
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		var particle := Particle.new(pos, velocity, color, particle_size)
		_particles.append(particle)

func emit_kill(pos: Vector2, is_elite: bool = false) -> void:
	var color := Color("#ff9933") if is_elite else Color("#ff0000")
	emit(pos, color, 15 if is_elite else 10, 1.0, 4.0)

func emit_hit(pos: Vector2, enemy_type: String) -> void:
	var color: Color
	match enemy_type:
		"elite": color = Color("#ff9933")
		"assassin": color = GameConstants.ASSASSIN_COLOR
		"rift": color = GameConstants.RIFT_COLOR
		"snare": color = GameConstants.SNARE_COLOR
		"minion": color = Color("#ff5c5c")
		_: color = Color("#ff0000")

	emit(pos, color, 10, 1.0, 3.0)

func emit_mask_break(pos: Vector2) -> void:
	emit(pos, Color.WHITE, 15, 2.0, 5.0)

func emit_mask_restore(pos: Vector2) -> void:
	emit(pos, Color.WHITE, 20, 2.0, 4.0)

func emit_combo_burst(pos: Vector2, combo_level: int) -> void:
	var color := Color("#ff6b4a") if combo_level >= 5 else Color("#ffd166")
	var count := 6 + combo_level * 4
	emit(pos, color, count, 2.0, 5.0)

func clear() -> void:
	_particles.clear()
	queue_redraw()

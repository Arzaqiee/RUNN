extends Area2D
## Coin kartun yang bisa diambil pemain. Bergerak ke kiri mengikuti
## world speed, berputar & mengambang idle, dan mendukung mode
## "magnet" yang menariknya ke arah pemain.

signal collected(value: int, world_pos: Vector2)

@export var value: int = 1

var speed: float = 500.0
var magnet_target: Node2D = null
const MAGNET_SPEED := 900.0

@onready var visual: Node2D = $Visual

var _bob_time := 0.0
var _base_y := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = position.y
	scale = Vector2(0.3, 0.3)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1, 1), 0.2)

func _physics_process(delta: float) -> void:
	if magnet_target:
		var dir: Vector2 = (magnet_target.global_position - global_position)
		if dir.length() < 12.0:
			_collect()
			return
		position += dir.normalized() * MAGNET_SPEED * delta
	else:
		position.x -= speed * delta
		_bob_time += delta * 4.0
		position.y = _base_y + sin(_bob_time) * 6.0

	visual.rotation += delta * 3.0

	if position.x < -200:
		queue_free()

func set_magnet_target(target: Node2D) -> void:
	magnet_target = target

func _on_body_entered(_body: Node) -> void:
	_collect()

func _collect() -> void:
	emit_signal("collected", value, global_position)
	queue_free()

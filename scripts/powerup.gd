extends Area2D
## Power-up yang melayang di jalur pemain.
## type: "magnet", "shield", "coin2x", "slowmo"

signal collected(power_type: String)

@export var power_type: String = "magnet"

var speed: float = 500.0

const COLORS := {
	"magnet": Color(0.9, 0.2, 0.9),
	"shield": Color(0.2, 0.7, 1.0),
	"coin2x": Color(1.0, 0.85, 0.1),
	"slowmo": Color(0.3, 1.0, 0.6),
}

@onready var visual: Panel = $Visual
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var box := StyleBoxFlat.new()
	box.bg_color = COLORS.get(power_type, Color.WHITE)
	box.set_corner_radius_all(30)
	box.set_border_width_all(5)
	box.border_color = Color(0.106, 0.122, 0.231, 1)
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 6
	visual.add_theme_stylebox_override("panel", box)
	label.text = {
		"magnet": "M",
		"shield": "S",
		"coin2x": "2x",
		"slowmo": "SL",
	}.get(power_type, "?")

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	position.y += sin(Time.get_ticks_msec() / 200.0) * 0.6
	if position.x < -200:
		queue_free()

func _on_body_entered(_body: Node) -> void:
	emit_signal("collected", power_type)
	queue_free()

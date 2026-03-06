extends Node2D
class_name ImpSummonPentagramEffect

@export var duration: float = 0.85
@export var outer_radius: float = 30.0
@export var inner_radius: float = 12.0
@export var rune_radius: float = 22.0
@export var line_width: float = 2.1
@export var pulse_amount: float = 0.08
@export var pulse_speed: float = 8.4
@export var rise_distance: float = 3.5
@export var base_color: Color = Color(0.9, 0.16, 0.12, 0.92)
@export var glow_color: Color = Color(1.0, 0.48, 0.24, 0.48)

var elapsed: float = 0.0
var anchor_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	top_level = true
	z_index = -1
	anchor_position = global_position
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += maxf(0.0, delta)
	var life := maxf(0.01, duration)
	var t := clampf(elapsed / life, 0.0, 1.0)
	if t >= 1.0:
		queue_free()
		return
	var pulse := 1.0 + (sin(elapsed * pulse_speed) * pulse_amount)
	scale = Vector2.ONE * pulse
	global_position = anchor_position + Vector2(0.0, -rise_distance * t)
	queue_redraw()


func _draw() -> void:
	var life := maxf(0.01, duration)
	var t := clampf(elapsed / life, 0.0, 1.0)
	var fade := 1.0 - t
	var pulse := 0.7 + (sin(elapsed * pulse_speed) * 0.3)

	var fill_color := base_color
	fill_color.a = clampf(0.12 * fade, 0.0, 1.0)
	draw_circle(Vector2.ZERO, outer_radius, fill_color)

	var outer_color := base_color
	outer_color.a = clampf(base_color.a * fade, 0.0, 1.0)
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 44, outer_color, line_width, true)

	var inner_color := glow_color
	inner_color.a = clampf(glow_color.a * fade * (0.75 + (0.25 * pulse)), 0.0, 1.0)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 30, inner_color, maxf(1.2, line_width * 0.72), true)

	var points := PackedVector2Array()
	for i in range(5):
		var angle := (-PI * 0.5) + (TAU * float(i) / 5.0)
		points.append(Vector2(cos(angle), sin(angle)) * rune_radius)
	var star_order := PackedInt32Array([0, 2, 4, 1, 3, 0])
	for i in range(star_order.size() - 1):
		var a := points[star_order[i]]
		var b := points[star_order[i + 1]]
		draw_line(a, b, outer_color, maxf(1.4, line_width * 0.9), true)

	var spoke_color := glow_color
	spoke_color.a = clampf(glow_color.a * fade * 0.8, 0.0, 1.0)
	for p in points:
		draw_line(Vector2.ZERO, p * 0.62, spoke_color, 1.2, true)

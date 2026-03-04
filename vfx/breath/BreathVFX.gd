extends Node2D
class_name BreathVFX

const BREATH_STREAM_SCRIPT := preload("res://scripts/effects/cacodemon_breath_stream.gd")
const BREATH_ROLLING_CELLS_SCRIPT := preload("res://scripts/effects/cacodemon_breath_rolling_cells.gd")
const BREATH_RIBBON_SHEETS_SCRIPT := preload("res://scripts/effects/cacodemon_breath_ribbon_sheets.gd")
const BREATH_XYEZAWR_FLIPBOOK_SCRIPT := preload("res://scripts/effects/cacodemon_breath_xyezawr_flipbook.gd")

enum Mode {
	PARTICLE_SPLIT,
	ROLLING_CELLS,
	ROLLING_CELLS_DENSE_SMALL,
	RIBBON_SHEETS,
	XYEZAWR_FLIPBOOK
}

var source_enemy: Node2D = null
var tank: Node2D = null
var mode: Mode = Mode.XYEZAWR_FLIPBOOK
var active_snapshot: Dictionary = {}
var breath_stream: Node2D = null
var fade_alpha: float = 0.0
var safe_overlay_pulse_time: float = 0.0
var redraw_accumulator: float = 0.0
var redraw_interval: float = 1.0 / 30.0


func configure(source_enemy_node: Node2D, tank_target: Node2D) -> void:
	source_enemy = source_enemy_node
	tank = tank_target
	top_level = true
	global_position = Vector2.ZERO
	z_index = 242
	queue_redraw()


func set_mode(_mode_index: int) -> void:
	var clamped_mode := clampi(_mode_index, 0, Mode.size() - 1)
	if mode != clamped_mode:
		mode = clamped_mode
		if is_instance_valid(breath_stream):
			breath_stream.queue_free()
			breath_stream = null
	_sync_breath_stream()
	queue_redraw()


func update_state(snapshot: Dictionary) -> void:
	active_snapshot = snapshot.duplicate(true)
	if bool(active_snapshot.get("active", false)):
		fade_alpha = 1.0
	else:
		fade_alpha = maxf(fade_alpha, 0.18)
	_sync_breath_stream()
	queue_redraw()


func _process(delta: float) -> void:
	if source_enemy == null or not is_instance_valid(source_enemy):
		queue_free()
		return
	safe_overlay_pulse_time += maxf(0.0, delta)
	if not bool(active_snapshot.get("active", false)):
		fade_alpha = move_toward(fade_alpha, 0.0, maxf(0.0, delta) * 2.6)
	if fade_alpha <= 0.01 and not bool(active_snapshot.get("active", false)):
		return
	redraw_accumulator += maxf(0.0, delta)
	if redraw_accumulator >= redraw_interval:
		redraw_accumulator = fmod(redraw_accumulator, redraw_interval)
		queue_redraw()


func _draw() -> void:
	if active_snapshot.is_empty() and fade_alpha <= 0.01:
		return
	var snapshot := active_snapshot
	var active := bool(snapshot.get("active", false))
	var charge_active := bool(snapshot.get("charge_active", false))
	var fire_active := bool(snapshot.get("fire_active", false))
	var state_alpha := fade_alpha if not active else 1.0
	if state_alpha <= 0.01:
		return
	var origin: Vector2 = snapshot.get("origin", Vector2.ZERO)
	var direction: Vector2 = snapshot.get("dir", Vector2.RIGHT)
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	var range := maxf(48.0, float(snapshot.get("range", 220.0)))
	var telegraph_half_width := maxf(16.0, float(snapshot.get("telegraph_half_width", 96.0)))
	var end_point := origin + (direction * (range + 920.0))
	var pulse := 0.5 + (0.5 * sin(safe_overlay_pulse_time * 8.0))
	if charge_active:
		_draw_telegraph(origin, end_point, telegraph_half_width, state_alpha, pulse)
	if bool(snapshot.get("safe_pocket_valid", false)):
		_draw_safe_pocket_overlay(snapshot, state_alpha, pulse)


func _sync_breath_stream() -> void:
	if not bool(active_snapshot.get("fire_active", false)):
		if is_instance_valid(breath_stream) and breath_stream.has_method("set_emitting"):
			breath_stream.call("set_emitting", false)
		return
	var stream := _ensure_breath_stream()
	if not is_instance_valid(stream):
		return
	var direction: Vector2 = active_snapshot.get("dir", Vector2.RIGHT)
	var direction_sign := -1.0 if direction.x < 0.0 else 1.0
	var range := maxf(48.0, float(active_snapshot.get("range", 220.0)))
	var half_width := maxf(10.0, float(active_snapshot.get("half_width", 24.0)))
	if stream.has_method("set_stream"):
		stream.call("set_stream", direction_sign, range, half_width)
	if stream.has_method("set_visual_style"):
		stream.call("set_visual_style", _get_stream_style_for_mode())
	if stream.has_method("set_emitting"):
		stream.call("set_emitting", true)


func _ensure_breath_stream() -> Node2D:
	var expected_script: Script = _get_effect_script_for_mode()
	if is_instance_valid(breath_stream):
		if breath_stream.get_script() == expected_script:
			return breath_stream
		breath_stream.queue_free()
		breath_stream = null
	if expected_script == null:
		return null
	var stream: Node2D = expected_script.new() as Node2D
	if stream == null:
		return null
	add_child(stream)
	breath_stream = stream
	if breath_stream.has_method("configure"):
		var direction: Vector2 = active_snapshot.get("dir", Vector2.RIGHT)
		var direction_sign := -1.0 if direction.x < 0.0 else 1.0
		var range := maxf(48.0, float(active_snapshot.get("range", 220.0)))
		var half_width := maxf(10.0, float(active_snapshot.get("half_width", 24.0)))
		breath_stream.call("configure", source_enemy, tank, direction_sign, range, half_width)
	return breath_stream


func _get_stream_style_for_mode() -> int:
	return int(mode)


func _get_effect_script_for_mode() -> Script:
	if mode == Mode.XYEZAWR_FLIPBOOK:
		return BREATH_XYEZAWR_FLIPBOOK_SCRIPT
	if mode == Mode.RIBBON_SHEETS:
		return BREATH_RIBBON_SHEETS_SCRIPT
	if mode == Mode.ROLLING_CELLS or mode == Mode.ROLLING_CELLS_DENSE_SMALL:
		return BREATH_ROLLING_CELLS_SCRIPT
	return BREATH_STREAM_SCRIPT


func _draw_telegraph(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.92,
		half_width * 1.8,
		Color(1.0, 0.24, 0.08, (0.18 + (pulse * 0.08)) * alpha_scale),
		Color(0.85, 0.06, 0.02, 0.04 * alpha_scale)
	)
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.42,
		half_width * 0.78,
		Color(1.0, 0.86, 0.28, (0.14 + (pulse * 0.08)) * alpha_scale),
		Color(1.0, 0.3, 0.04, 0.02 * alpha_scale)
	)
	draw_circle(origin, maxf(16.0, half_width * 0.22), Color(1.0, 0.7, 0.24, (0.24 + (pulse * 0.08)) * alpha_scale))


func _draw_particle_split_overlay(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.16,
		half_width * 0.24,
		Color(1.0, 0.9, 0.34, (0.1 + (pulse * 0.04)) * alpha_scale),
		Color(1.0, 0.46, 0.04, 0.02 * alpha_scale)
	)
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.08,
		half_width * 0.08,
		Color(1.0, 0.98, 0.72, (0.11 + (pulse * 0.05)) * alpha_scale),
		Color(1.0, 0.82, 0.14, 0.02 * alpha_scale)
	)


func _draw_pressure_jet_overlay(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.6,
		half_width * 1.18,
		Color(0.22, 0.02, 0.01, 0.1 * alpha_scale),
		Color(0.02, 0.0, 0.0, 0.01)
	)
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.34,
		half_width * 0.62,
		Color(1.0, 0.34, 0.05, 0.24 * alpha_scale),
		Color(0.9, 0.08, 0.02, 0.05 * alpha_scale)
	)
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.12,
		half_width * 0.12,
		Color(1.0, 0.96, 0.62, (0.18 + (pulse * 0.06)) * alpha_scale),
		Color(1.0, 0.72, 0.08, 0.04 * alpha_scale)
	)


func _draw_coanda_wrap_overlay(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.96,
		half_width * 1.8,
		Color(1.0, 0.18, 0.04, 0.16 * alpha_scale),
		Color(0.74, 0.04, 0.02, 0.03 * alpha_scale)
	)
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.24,
		half_width * 0.38,
		Color(1.0, 0.9, 0.42, (0.14 + (pulse * 0.05)) * alpha_scale),
		Color(1.0, 0.36, 0.04, 0.03 * alpha_scale)
	)
	if bool(active_snapshot.get("safe_pocket_valid", false)):
		var center: Vector2 = active_snapshot.get("tank_position", origin)
		var dir := (end_point - origin).normalized()
		if dir.length_squared() <= 0.0001:
			dir = Vector2.RIGHT
		var side := Vector2(-dir.y, dir.x)
		draw_arc(center + (side * half_width * 0.74), maxf(14.0, half_width * 0.44), PI * 0.72, PI * 1.46, 16, Color(1.0, 0.74, 0.22, 0.16 * alpha_scale), 2.0, true)
		draw_arc(center - (side * half_width * 0.74), maxf(14.0, half_width * 0.44), -PI * 0.46, PI * 0.28, 16, Color(1.0, 0.74, 0.22, 0.16 * alpha_scale), 2.0, true)


func _draw_ribbon_overlay(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	var side := Vector2(-end_point.y + origin.y, end_point.x - origin.x).normalized()
	if side.length_squared() <= 0.0001:
		side = Vector2.UP
	for ribbon_index in range(3):
		var ribbon_value := float(ribbon_index)
		var base_offset := (ribbon_value - 1.0) * (half_width * 0.22)
		var previous_point := origin + (side * base_offset)
		for segment in range(1, 9):
			var t := float(segment) / 8.0
			var width_here := lerpf(half_width * 0.08, half_width * 0.22, t)
			var wave := sin((t * TAU * 1.2) + (ribbon_value * 1.7) + (pulse * 0.6)) * half_width * (0.11 + (ribbon_value * 0.02))
			var point := origin.lerp(end_point, t) + (side * (base_offset + wave))
			_draw_tapered_band(
				previous_point,
				point,
				width_here,
				width_here * 1.18,
				Color(1.0, 0.74, 0.18, (0.12 + (0.03 * ribbon_value)) * alpha_scale),
				Color(1.0, 0.18, 0.02, 0.01 * alpha_scale)
			)
			previous_point = point


func _draw_rolling_cells_overlay(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.14,
		half_width * 0.2,
		Color(1.0, 0.88, 0.3, (0.09 + (pulse * 0.04)) * alpha_scale),
		Color(1.0, 0.38, 0.04, 0.02 * alpha_scale)
	)
	for puff_index in range(6):
		var t := 0.12 + (float(puff_index) * 0.12)
		var center := origin.lerp(end_point, t)
		var puff_radius := lerpf(half_width * 0.18, half_width * 0.46, t)
		var jitter_y := sin((t * TAU * 1.2) + (pulse * 1.6)) * half_width * 0.12
		draw_circle(center + Vector2(0.0, jitter_y), maxf(10.0, puff_radius * 0.72), Color(1.0, 0.64, 0.16, 0.04 * alpha_scale))
		draw_circle(center + Vector2(0.0, jitter_y * 0.5), maxf(6.0, puff_radius * 0.36), Color(1.0, 0.9, 0.3, 0.05 * alpha_scale))


func _draw_vortex_shear_overlay(origin: Vector2, end_point: Vector2, half_width: float, alpha_scale: float, pulse: float) -> void:
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 1.08,
		half_width * 1.94,
		Color(0.58, 0.06, 0.03, 0.14 * alpha_scale),
		Color(0.18, 0.01, 0.01, 0.03 * alpha_scale)
	)
	_draw_tapered_band(
		origin,
		end_point,
		half_width * 0.42,
		half_width * 0.64,
		Color(1.0, 0.88, 0.34, (0.12 + (pulse * 0.05)) * alpha_scale),
		Color(1.0, 0.22, 0.03, 0.04 * alpha_scale)
	)
	var side := Vector2(-end_point.y + origin.y, end_point.x - origin.x).normalized()
	if side.length_squared() <= 0.0001:
		side = Vector2.UP
	for swirl_index in range(3):
		var swirl_t := float(swirl_index) / 2.0
		var swirl_center := origin.lerp(end_point, 0.18 + (swirl_t * 0.14)) + (side * sin((swirl_t * TAU) + pulse) * half_width * 0.18)
		draw_arc(swirl_center, maxf(12.0, half_width * 0.22), PI * 0.2, PI * 1.7, 14, Color(1.0, 0.78, 0.18, 0.12 * alpha_scale), 1.8, true)


func _draw_safe_pocket_overlay(snapshot: Dictionary, alpha_scale: float, pulse: float) -> void:
	var center: Vector2 = snapshot.get("safe_pocket_center", Vector2.ZERO)
	var dir: Vector2 = snapshot.get("dir", Vector2.RIGHT)
	var half_width := maxf(10.0, float(snapshot.get("safe_pocket_half_width", 38.0)))
	var half_depth := maxf(10.0, float(snapshot.get("safe_pocket_half_depth", 28.0)))
	_draw_ellipse(center, dir, half_depth * 1.1, half_width * 1.08, Color(0.08, 0.18, 0.28, (0.22 + (pulse * 0.05)) * alpha_scale))
	_draw_ellipse_outline(center, dir, half_depth * 1.16, half_width * 1.14, 2.4, Color(0.42, 0.9, 1.0, (0.42 + (pulse * 0.12)) * alpha_scale))
	var shield_center: Vector2 = snapshot.get("tank_position", center)
	draw_arc(shield_center, maxf(18.0, half_width * 0.68), PI * 0.7, PI * 1.3, 18, Color(0.46, 0.86, 1.0, (0.28 + (pulse * 0.08)) * alpha_scale), 2.2, true)


func _draw_tapered_band(start_point: Vector2, end_point: Vector2, start_half_width: float, end_half_width: float, start_color: Color, end_color: Color) -> void:
	var dir := end_point - start_point
	var normal := Vector2(-dir.y, dir.x).normalized()
	if normal.length_squared() <= 0.0001:
		normal = Vector2.UP
	var points := PackedVector2Array([
		start_point - (normal * start_half_width),
		start_point + (normal * start_half_width),
		end_point + (normal * end_half_width),
		end_point - (normal * end_half_width)
	])
	var colors := PackedColorArray([start_color, start_color, end_color, end_color])
	draw_polygon(points, colors)


func _draw_ellipse(center: Vector2, forward: Vector2, half_depth: float, half_width: float, color: Color) -> void:
	var points := _build_oriented_ellipse(center, forward, half_depth, half_width)
	if points.is_empty():
		return
	var colors := PackedColorArray()
	for _i in points.size():
		colors.append(color)
	draw_polygon(points, colors)


func _draw_ellipse_outline(center: Vector2, forward: Vector2, half_depth: float, half_width: float, width: float, color: Color) -> void:
	var points := _build_oriented_ellipse(center, forward, half_depth, half_width)
	if points.size() <= 1:
		return
	var line := PackedVector2Array(points)
	line.append(points[0])
	draw_polyline(line, color, maxf(1.0, width), true)


func _build_oriented_ellipse(center: Vector2, forward: Vector2, half_depth: float, half_width: float) -> PackedVector2Array:
	var dir := forward.normalized()
	if dir.length_squared() <= 0.0001:
		dir = Vector2.RIGHT
	var side := Vector2(-dir.y, dir.x)
	var points := PackedVector2Array()
	for step in range(20):
		var angle := (TAU * float(step)) / 20.0
		var offset := (-dir * cos(angle) * half_depth) + (side * sin(angle) * half_width)
		points.append(center + offset)
	return points

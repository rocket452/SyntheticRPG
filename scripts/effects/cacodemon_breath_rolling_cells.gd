extends Node2D
class_name CacodemonBreathRollingCells

enum CellStyle {
	STANDARD,
	DENSE_SMALL
}

@export var spawn_rate: float = 42.0
@export var max_cells: int = 72
@export var cell_lifetime: float = 1.8
@export var visual_length_padding: float = 220.0
@export var lane_count: int = 5
@export var visual_refresh_rate: float = 30.0
@export var max_visual_steps_per_frame: int = 3

var source_enemy: EnemyBase = null
var target_player: Player = null
var stream_direction_x: float = 1.0
var stream_length: float = 220.0
var stream_half_width: float = 24.0
var is_emitting: bool = false
var spawn_accumulator: float = 0.0
var cells: Array[Dictionary] = []
var elapsed: float = 0.0
var cell_style: CellStyle = CellStyle.STANDARD
var visual_step_accumulator: float = 0.0
var rng := RandomNumberGenerator.new()


func configure(source_enemy_node: EnemyBase, player_target: Player, direction_sign: float, length: float, half_width: float) -> void:
	source_enemy = source_enemy_node
	target_player = player_target
	stream_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	stream_length = maxf(48.0, length)
	stream_half_width = maxf(10.0, half_width)
	top_level = true
	global_position = Vector2.ZERO
	z_index = 241
	rng.randomize()
	is_emitting = true
	queue_redraw()


func set_stream(direction_sign: float, length: float, half_width: float) -> void:
	stream_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	stream_length = maxf(48.0, length)
	stream_half_width = maxf(10.0, half_width)


func set_emitting(enabled: bool) -> void:
	is_emitting = enabled


func set_visual_style(style_index: int) -> void:
	cell_style = CellStyle.DENSE_SMALL if style_index >= 2 else CellStyle.STANDARD
	queue_redraw()


func _process(delta: float) -> void:
	if source_enemy == null or not is_instance_valid(source_enemy) or source_enemy.dead:
		queue_free()
		return
	elapsed += maxf(0.0, delta)
	var step_rate := maxf(1.0, visual_refresh_rate)
	var step_delta := 1.0 / step_rate
	visual_step_accumulator += maxf(0.0, delta)
	var steps := 0
	while visual_step_accumulator >= step_delta and steps < maxi(1, max_visual_steps_per_frame):
		visual_step_accumulator -= step_delta
		_spawn_cells(step_delta)
		_tick_cells(step_delta)
		steps += 1
	if steps > 0:
		queue_redraw()
	if not is_emitting and cells.is_empty():
		queue_free()


func _spawn_cells(delta: float) -> void:
	if not is_emitting:
		return
	var style_profile := _get_style_profile()
	spawn_accumulator += maxf(0.0, delta) * maxf(1.0, spawn_rate * float(style_profile.get("spawn_rate_scale", 1.0)))
	var total_lanes := maxi(3, lane_count)
	var style_max_cells := maxi(8, int(round(float(max_cells) * float(style_profile.get("max_cells_scale", 1.0)))))
	while spawn_accumulator >= 1.0 and cells.size() < style_max_cells:
		spawn_accumulator -= 1.0
		var lane_index := rng.randi_range(0, total_lanes - 1)
		var lane_ratio := 0.0 if total_lanes <= 1 else float(lane_index) / float(total_lanes - 1)
		var lane_value := lerpf(-1.0, 1.0, lane_ratio)
		var speed := rng.randf_range(300.0, 440.0)
		cells.append({
			"progress": rng.randf_range(-36.0, 18.0),
			"age": 0.0,
			"life": rng.randf_range(cell_lifetime * 0.74, cell_lifetime * 1.18),
			"lane": lane_value,
			"speed": speed,
			"radius": rng.randf_range(12.0, 26.0) * float(style_profile.get("radius_scale", 1.0)),
			"heat": rng.randf_range(0.0, 1.0),
			"branch_sign": 0.0,
			"spin": rng.randf_range(-1.0, 1.0)
		})


func _tick_cells(delta: float) -> void:
	if cells.is_empty():
		return
	var visual_length := _get_visual_stream_length(_get_emitter_origin())
	var next_cells: Array[Dictionary] = []
	for cell in cells:
		var age := float(cell.get("age", 0.0)) + maxf(0.0, delta)
		var life := maxf(0.01, float(cell.get("life", cell_lifetime)))
		if age >= life:
			continue
		var progress := float(cell.get("progress", 0.0)) + (float(cell.get("speed", 320.0)) * maxf(0.0, delta))
		if progress > visual_length + 160.0:
			continue
		cell["age"] = age
		cell["progress"] = progress
		next_cells.append(cell)
	cells = next_cells


func _draw() -> void:
	if cells.is_empty():
		return
	var style_profile := _get_style_profile()
	var origin := _get_emitter_origin()
	var visual_length := _get_visual_stream_length(origin)
	var split_state := _get_split_state(origin, visual_length)
	var draw_stride := maxi(1, int(style_profile.get("draw_stride", 1)))
	var draw_outer := bool(style_profile.get("draw_outer", true))
	for cell_index in range(0, cells.size(), draw_stride):
		var cell := cells[cell_index]
		var center := _get_cell_position(cell, origin, visual_length, split_state)
		var radius := maxf(4.0, float(cell.get("radius", 14.0)))
		var life := maxf(0.01, float(cell.get("life", cell_lifetime)))
		var age := clampf(float(cell.get("age", 0.0)), 0.0, life)
		var age_ratio := age / life
		var life_ratio := 1.0 - age_ratio
		var heat := clampf(float(cell.get("heat", 0.5)), 0.0, 1.0)
		var forward_glow := Vector2(stream_direction_x * radius * 0.8, 0.0)
		var alpha_scale := float(style_profile.get("alpha_scale", 1.0))
		var tail_scale := float(style_profile.get("tail_scale", 1.0))
		var outer := Color(1.0, lerpf(0.22, 0.48, heat), 0.04, (0.1 + (life_ratio * 0.08)) * alpha_scale)
		var mid := Color(1.0, lerpf(0.44, 0.74, heat), lerpf(0.04, 0.12, 1.0 - heat), (0.16 + (life_ratio * 0.12)) * alpha_scale)
		var core := Color(1.0, lerpf(0.82, 0.96, heat), lerpf(0.16, 0.28, 1.0 - heat), (0.2 + (life_ratio * 0.22)) * alpha_scale)
		if draw_outer:
			draw_circle(center, radius * 1.42, outer)
		draw_circle(center - forward_glow * 0.3, radius * 1.06, mid)
		draw_circle(center + (forward_glow * 0.18), radius * 0.62, core)
		draw_line(center - (forward_glow * 1.1 * tail_scale), center + (forward_glow * 0.25), Color(1.0, 0.72, 0.1, (0.12 + (life_ratio * 0.06)) * alpha_scale), maxf(1.2, radius * 0.24), true)


func _get_cell_position(cell: Dictionary, origin: Vector2, visual_length: float, split_state: Dictionary) -> Vector2:
	var progress := float(cell.get("progress", 0.0))
	var lane := float(cell.get("lane", 0.0))
	var base_width := lerpf(maxf(44.0, stream_half_width * 2.6), maxf(132.0, stream_half_width * 6.4), clampf(progress / maxf(1.0, visual_length), 0.0, 1.0))
	var spin := float(cell.get("spin", 0.0))
	var age := float(cell.get("age", 0.0))
	var wobble := sin((progress * 0.022) + (elapsed * 4.4) + (spin * PI)) * base_width * 0.1
	wobble += cos((progress * 0.013) - (elapsed * 3.1) + (lane * 2.2)) * base_width * 0.06
	var y_pos := origin.y + (lane * base_width * 0.38) + wobble
	var x_pos := origin.x + (progress * stream_direction_x)
	if bool(split_state.get("active", false)):
		y_pos = _apply_split_to_y(split_state, x_pos, y_pos, lane, base_width)
	return Vector2(x_pos, y_pos)


func _apply_split_to_y(split_state: Dictionary, x_pos: float, y_pos: float, lane: float, width_here: float) -> float:
	var split_start_x := float(split_state.get("split_start_x", x_pos))
	var split_mid_x := float(split_state.get("split_mid_x", x_pos))
	var split_end_x := float(split_state.get("split_end_x", x_pos))
	var shield_center: Vector2 = split_state.get("shield_center", Vector2(x_pos, y_pos))
	var gap_half := float(split_state.get("gap_half", 32.0))
	if (x_pos - split_start_x) * stream_direction_x < 0.0:
		return y_pos
	var branch_sign := -1.0 if lane <= 0.0 else 1.0
	if (x_pos - split_mid_x) * stream_direction_x <= 0.0:
		var first_span := split_mid_x - split_start_x
		var first_denominator := first_span if absf(first_span) > 0.01 else stream_direction_x
		var first_progress := clampf((x_pos - split_start_x) / first_denominator, 0.0, 1.0)
		var target_y := shield_center.y + (branch_sign * (gap_half + (width_here * 0.1)))
		return lerpf(y_pos, target_y, sin(first_progress * PI * 0.5))
	if (x_pos - split_end_x) * stream_direction_x <= 0.0:
		var second_span := split_end_x - split_mid_x
		var second_denominator := second_span if absf(second_span) > 0.01 else stream_direction_x
		var second_progress := clampf((x_pos - split_mid_x) / second_denominator, 0.0, 1.0)
		var branch_y := shield_center.y + (branch_sign * (gap_half + (width_here * 0.08)))
		var rejoin_y := shield_center.y + (branch_sign * gap_half * 0.24)
		return lerpf(branch_y, rejoin_y, second_progress)
	return lerpf(y_pos, shield_center.y + (branch_sign * gap_half * 0.18), 0.52)


func _get_split_state(origin: Vector2, visual_length: float) -> Dictionary:
	if not _is_player_blocking():
		return {"active": false}
	var shield_center := _get_player_shield_center()
	var shield_radius := _get_player_shield_radius()
	var forward_to_shield := (shield_center.x - origin.x) * stream_direction_x
	if forward_to_shield < 24.0 or forward_to_shield > visual_length - 24.0:
		return {"active": false}
	var split_start_x := shield_center.x - (stream_direction_x * maxf(64.0, shield_radius * 2.4))
	var split_mid_x := shield_center.x + (stream_direction_x * maxf(36.0, shield_radius * 1.4))
	var split_end_x := shield_center.x + (stream_direction_x * maxf(152.0, shield_radius * 4.4))
	return {
		"active": true,
		"shield_center": shield_center,
		"split_start_x": split_start_x,
		"split_mid_x": split_mid_x,
		"split_end_x": split_end_x,
		"gap_half": shield_radius + 38.0
	}


func _get_visual_stream_length(origin: Vector2) -> float:
	var visual_length := stream_length + maxf(96.0, visual_length_padding)
	var viewport := get_viewport()
	if viewport == null:
		return visual_length
	var visible_rect := viewport.get_visible_rect()
	if visible_rect.size.x <= 0.0:
		return visual_length
	if stream_direction_x > 0.0:
		var to_right_edge := (visible_rect.position.x + visible_rect.size.x) - origin.x
		visual_length = maxf(visual_length, to_right_edge + visual_length_padding)
	else:
		var to_left_edge := origin.x - visible_rect.position.x
		visual_length = maxf(visual_length, to_left_edge + visual_length_padding)
	return visual_length


func _get_emitter_origin() -> Vector2:
	if source_enemy == null or not is_instance_valid(source_enemy):
		return Vector2.ZERO
	if source_enemy.has_method("_get_cacodemon_breath_origin"):
		return source_enemy.call("_get_cacodemon_breath_origin") as Vector2
	return source_enemy.global_position + Vector2(36.0 * stream_direction_x, -14.0)


func _is_player_blocking() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	if target_player.has_method("is_block_shield_active"):
		return bool(target_player.call("is_block_shield_active"))
	return target_player.is_blocking


func _get_player_shield_center() -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return Vector2.ZERO
	if target_player.has_method("get_block_shield_center_global"):
		var center_variant: Variant = target_player.call("get_block_shield_center_global")
		if center_variant is Vector2:
			return center_variant
	return target_player.global_position


func _get_player_shield_radius() -> float:
	if target_player == null or not is_instance_valid(target_player):
		return 0.0
	return maxf(8.0, target_player.block_shield_radius)


func _get_style_profile() -> Dictionary:
	if cell_style == CellStyle.DENSE_SMALL:
		return {
			"spawn_rate_scale": 2.0,
			"max_cells_scale": 2.0,
			"radius_scale": 0.5,
			"alpha_scale": 0.92,
			"tail_scale": 0.78,
			"draw_stride": 2,
			"draw_outer": false
		}
	return {
		"spawn_rate_scale": 1.0,
		"max_cells_scale": 1.0,
		"radius_scale": 1.0,
		"alpha_scale": 1.0,
		"tail_scale": 1.0,
		"draw_stride": 1,
		"draw_outer": true
	}

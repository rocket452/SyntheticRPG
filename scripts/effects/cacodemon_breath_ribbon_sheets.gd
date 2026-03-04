extends Node2D
class_name CacodemonBreathRibbonSheets

# Ribbon Sheets technique:
# - Renders the breath as several wide, animated flame sheets instead of particles or blob cells.
# - Shield interaction is faked by bending each ribbon centerline around the shield ellipse, adding curl at the split,
#   then easing the ribbons back together downstream so the flow reads like liquid wrapping around a rock.
# - Main tuning knobs: ribbon_count, ribbon_segments, near/far width scales, curl_strength, split_push_scale,
#   rejoin_blend, hotspot_frequency, and visual_refresh_rate.

@export var ribbon_count: int = 7
@export var ribbon_segments: int = 20
@export var visual_length_padding: float = 260.0
@export var near_half_width_scale: float = 4.6
@export var far_half_width_scale: float = 8.2
@export var ribbon_thickness_scale: float = 0.34
@export var core_thickness_scale: float = 0.48
@export var curl_strength: float = 0.95
@export var split_push_scale: float = 1.0
@export var rejoin_blend: float = 0.34
@export var hotspot_frequency: float = 1.9
@export var visual_refresh_rate: float = 30.0
@export var max_visual_steps_per_frame: int = 3

var source_enemy: EnemyBase = null
var target_player: Player = null
var stream_direction_x: float = 1.0
var stream_length: float = 220.0
var stream_half_width: float = 24.0
var is_emitting: bool = false
var elapsed: float = 0.0
var fade_alpha: float = 0.0
var visual_step_accumulator: float = 0.0
var additive_material := CanvasItemMaterial.new()


func configure(source_enemy_node: EnemyBase, player_target: Player, direction_sign: float, length: float, half_width: float) -> void:
	source_enemy = source_enemy_node
	target_player = player_target
	stream_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	stream_length = maxf(48.0, length)
	stream_half_width = maxf(10.0, half_width)
	top_level = true
	global_position = Vector2.ZERO
	z_index = 241
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive_material
	is_emitting = true
	fade_alpha = 1.0
	queue_redraw()


func set_stream(direction_sign: float, length: float, half_width: float) -> void:
	stream_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	stream_length = maxf(48.0, length)
	stream_half_width = maxf(10.0, half_width)


func set_emitting(enabled: bool) -> void:
	is_emitting = enabled
	if enabled:
		fade_alpha = 1.0


func set_visual_style(_style_index: int) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if source_enemy == null or not is_instance_valid(source_enemy) or source_enemy.dead:
		queue_free()
		return
	var safe_delta := maxf(0.0, delta)
	elapsed += safe_delta
	if not is_emitting:
		fade_alpha = move_toward(fade_alpha, 0.0, safe_delta * 3.2)
	else:
		fade_alpha = move_toward(fade_alpha, 1.0, safe_delta * 5.0)
	if fade_alpha <= 0.01 and not is_emitting:
		queue_free()
		return
	var step_rate := maxf(1.0, visual_refresh_rate)
	var step_delta := 1.0 / step_rate
	visual_step_accumulator += safe_delta
	var steps := 0
	while visual_step_accumulator >= step_delta and steps < maxi(1, max_visual_steps_per_frame):
		visual_step_accumulator -= step_delta
		steps += 1
	if steps > 0:
		queue_redraw()


func _draw() -> void:
	if fade_alpha <= 0.01:
		return
	var origin := _get_emitter_origin()
	var visual_length := _get_visual_stream_length(origin)
	var forward := Vector2(stream_direction_x, 0.0)
	var end_point := origin + (forward * visual_length)
	var near_width := maxf(56.0, stream_half_width * near_half_width_scale)
	var far_width := maxf(160.0, stream_half_width * far_half_width_scale)
	_draw_core_glow(origin, end_point, near_width, far_width)
	var split_state := _get_split_state(origin, visual_length)
	var total_ribbons := maxi(4, ribbon_count)
	for ribbon_index in range(total_ribbons):
		var lane_ratio := 0.0 if total_ribbons <= 1 else float(ribbon_index) / float(total_ribbons - 1)
		var lane_value := lerpf(-1.0, 1.0, lane_ratio)
		_draw_ribbon(origin, visual_length, near_width, far_width, split_state, lane_value, ribbon_index)


func _draw_core_glow(origin: Vector2, end_point: Vector2, near_width: float, far_width: float) -> void:
	var outer_alpha := 0.09 * fade_alpha
	var inner_alpha := 0.08 * fade_alpha
	_draw_segment_quad(
		origin,
		end_point,
		near_width * 0.42,
		far_width * 0.38,
		Color(1.0, 0.22, 0.03, outer_alpha)
	)
	_draw_segment_quad(
		origin,
		end_point,
		near_width * 0.18,
		far_width * 0.14,
		Color(1.0, 0.78, 0.2, inner_alpha)
	)


func _draw_ribbon(origin: Vector2, visual_length: float, near_width: float, far_width: float, split_state: Dictionary, lane_value: float, ribbon_index: int) -> void:
	var segments := maxi(8, ribbon_segments)
	var points: Array[Vector2] = []
	var widths: Array[float] = []
	var alphas: Array[float] = []
	for step in range(segments + 1):
		var t := float(step) / float(segments)
		var progress := t * visual_length
		var point := _get_ribbon_point(origin, progress, visual_length, lane_value, near_width, far_width, split_state, ribbon_index)
		var width_here := lerpf(near_width, far_width, pow(t, 0.72))
		width_here *= maxf(0.18, ribbon_thickness_scale - (absf(lane_value) * 0.04))
		var alpha_here := _get_ribbon_alpha(point, t, lane_value)
		points.append(point)
		widths.append(width_here)
		alphas.append(alpha_here)
	for step in range(segments):
		var point_a := points[step]
		var point_b := points[step + 1]
		var width_a := widths[step]
		var width_b := widths[step + 1]
		var alpha_a := alphas[step]
		var alpha_b := alphas[step + 1]
		var alpha_mid := (alpha_a + alpha_b) * 0.5 * fade_alpha
		if alpha_mid <= 0.01:
			continue
		var outer_color := Color(1.0, 0.34 + (absf(lane_value) * 0.08), 0.04, alpha_mid * 0.16)
		var inner_color := Color(1.0, 0.7 + (0.08 * sin((float(step) * 0.7) + elapsed + float(ribbon_index))), 0.14, alpha_mid * 0.2)
		_draw_segment_quad(point_a, point_b, width_a, width_b, outer_color)
		_draw_segment_quad(point_a, point_b, width_a * core_thickness_scale, width_b * core_thickness_scale, inner_color)
		if _should_draw_hotspot(step, ribbon_index):
			var hotspot_center := point_a.lerp(point_b, 0.5)
			var hotspot_radius := lerpf(width_a, width_b, 0.5) * 0.34
			draw_circle(hotspot_center, hotspot_radius, Color(1.0, 0.94, 0.46, alpha_mid * 0.22))


func _get_ribbon_point(origin: Vector2, progress: float, visual_length: float, lane_value: float, near_width: float, far_width: float, split_state: Dictionary, ribbon_index: int) -> Vector2:
	var t := clampf(progress / maxf(1.0, visual_length), 0.0, 1.0)
	var width_here := lerpf(near_width, far_width, pow(t, 0.72))
	var x_pos := origin.x + (progress * stream_direction_x)
	var y_pos := origin.y + (lane_value * width_here * 0.36)
	var phase := (elapsed * 2.8) + (float(ribbon_index) * 0.91)
	var wave_a := sin((progress * 0.022) + phase) * width_here * (0.06 + (0.015 * absf(lane_value)))
	var wave_b := cos((progress * 0.014) - (elapsed * 1.6) + (float(ribbon_index) * 0.47)) * width_here * 0.032
	y_pos += wave_a + wave_b
	if bool(split_state.get("active", false)):
		y_pos = _apply_split_wrap(split_state, x_pos, y_pos, lane_value, width_here, progress, ribbon_index)
	return Vector2(x_pos, y_pos)


func _apply_split_wrap(split_state: Dictionary, x_pos: float, base_y: float, lane_value: float, width_here: float, progress: float, ribbon_index: int) -> float:
	var split_start_x := float(split_state.get("split_start_x", x_pos))
	var wrap_peak_x := float(split_state.get("wrap_peak_x", x_pos))
	var wake_end_x := float(split_state.get("wake_end_x", x_pos))
	var shield_center: Vector2 = split_state.get("shield_center", Vector2(x_pos, base_y))
	var gap_half := float(split_state.get("gap_half", 24.0))
	var shield_half_extents: Vector2 = split_state.get("shield_half_extents", Vector2.ONE * 12.0)
	var before_start := (x_pos - split_start_x) * stream_direction_x < 0.0
	if before_start:
		return base_y
	var branch_sign := -1.0 if lane_value <= 0.0 else 1.0
	if absf(lane_value) <= 0.08:
		branch_sign = -1.0 if sin((float(ribbon_index) * 1.7) + progress * 0.01) < 0.0 else 1.0
	var branch_target_y := shield_center.y + (branch_sign * (gap_half + (width_here * 0.1 * split_push_scale)))
	var curl_phase := sin((progress * 0.028) + (elapsed * 5.4) + (float(ribbon_index) * 0.6))
	if (x_pos - wrap_peak_x) * stream_direction_x <= 0.0:
		var span := wrap_peak_x - split_start_x
		var denom := span if absf(span) > 0.01 else stream_direction_x
		var blend := clampf((x_pos - split_start_x) / denom, 0.0, 1.0)
		var curved := sin(blend * PI * 0.5)
		var pull := lerpf(base_y, branch_target_y, curved)
		var curl_offset := branch_sign * curl_phase * shield_half_extents.y * 0.34 * curl_strength * blend
		return pull + curl_offset
	if (x_pos - wake_end_x) * stream_direction_x <= 0.0:
		var span := wake_end_x - wrap_peak_x
		var denom := span if absf(span) > 0.01 else stream_direction_x
		var wake_progress := clampf((x_pos - wrap_peak_x) / denom, 0.0, 1.0)
		var held_y := shield_center.y + (branch_sign * (gap_half * 0.62))
		var rejoin_y := lerpf(held_y, shield_center.y + (branch_sign * gap_half * 0.16), wake_progress)
		var wake_wave := sin((wake_progress * PI * 1.4) + (float(ribbon_index) * 0.8) - (elapsed * 3.0)) * shield_half_extents.y * 0.18
		return lerpf(branch_target_y, rejoin_y, wake_progress * (1.0 - rejoin_blend)) + (branch_sign * wake_wave)
	return lerpf(base_y, shield_center.y + (branch_sign * gap_half * 0.12), 0.46)


func _get_ribbon_alpha(point: Vector2, t: float, lane_value: float) -> float:
	var edge_softening := clampf(1.0 - (absf(lane_value) * 0.18), 0.42, 1.0)
	var front_ramp := clampf(0.32 + (t * 0.9), 0.0, 1.0)
	var alpha := edge_softening * front_ramp
	if _is_in_safe_pocket(point):
		alpha *= 0.28
	return alpha


func _should_draw_hotspot(step: int, ribbon_index: int) -> bool:
	var freq := maxf(0.5, hotspot_frequency)
	var phase_value := step + (ribbon_index * 2) + int(floor(elapsed * freq))
	return posmod(phase_value, 4) == 0


func _draw_segment_quad(start_point: Vector2, end_point: Vector2, start_width: float, end_width: float, color: Color) -> void:
	var segment := end_point - start_point
	if segment.length_squared() <= 0.0001:
		return
	var normal := Vector2(-segment.y, segment.x).normalized()
	var points := PackedVector2Array([
		start_point + (normal * start_width),
		end_point + (normal * end_width),
		end_point - (normal * end_width),
		start_point - (normal * start_width)
	])
	var colors := PackedColorArray([color, color, color, color])
	draw_polygon(points, colors)


func _get_split_state(origin: Vector2, visual_length: float) -> Dictionary:
	if not _is_player_blocking():
		return {"active": false}
	var shield_center := _get_player_shield_center()
	var shield_half_extents := _get_player_shield_half_extents()
	var shield_forward_distance := (shield_center.x - origin.x) * stream_direction_x
	if shield_forward_distance < 18.0 or shield_forward_distance > visual_length - 36.0:
		return {"active": false}
	var split_start_x := shield_center.x - (stream_direction_x * maxf(56.0, shield_half_extents.x * 2.8))
	var wrap_peak_x := shield_center.x + (stream_direction_x * maxf(18.0, shield_half_extents.x * 0.9))
	var wake_end_x := shield_center.x + (stream_direction_x * maxf(220.0, shield_half_extents.x * 8.4))
	return {
		"active": true,
		"shield_center": shield_center,
		"shield_half_extents": shield_half_extents,
		"split_start_x": split_start_x,
		"wrap_peak_x": wrap_peak_x,
		"wake_end_x": wake_end_x,
		"gap_half": shield_half_extents.y + maxf(22.0, stream_half_width * 2.0)
	}


func _get_emitter_origin() -> Vector2:
	if source_enemy == null or not is_instance_valid(source_enemy):
		return Vector2.ZERO
	if source_enemy.has_method("_get_cacodemon_breath_origin"):
		var origin_variant: Variant = source_enemy.call("_get_cacodemon_breath_origin")
		if origin_variant is Vector2:
			return origin_variant
	return source_enemy.global_position + Vector2(36.0 * stream_direction_x, -14.0)


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


func _is_player_blocking() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	if target_player.has_method("is_block_shield_active"):
		return bool(target_player.call("is_block_shield_active"))
	return bool(target_player.get("is_blocking"))


func _get_player_shield_center() -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return Vector2.ZERO
	if target_player.has_method("get_block_shield_center_global"):
		var center_variant: Variant = target_player.call("get_block_shield_center_global")
		if center_variant is Vector2:
			return center_variant
	return target_player.global_position


func _get_player_shield_half_extents() -> Vector2:
	if target_player == null or not is_instance_valid(target_player):
		return Vector2(12.0, 12.0)
	if target_player.has_method("get_block_shield_half_extents"):
		var extents_variant: Variant = target_player.call("get_block_shield_half_extents")
		if extents_variant is Vector2:
			return extents_variant
	var radius := maxf(8.0, float(target_player.get("block_shield_radius")))
	return Vector2(radius * 0.8, radius * 1.1)


func _is_in_safe_pocket(world_position: Vector2) -> bool:
	if source_enemy == null or not is_instance_valid(source_enemy):
		return false
	if source_enemy.has_method("is_position_in_breath_safe_pocket"):
		return bool(source_enemy.call("is_position_in_breath_safe_pocket", world_position))
	return false

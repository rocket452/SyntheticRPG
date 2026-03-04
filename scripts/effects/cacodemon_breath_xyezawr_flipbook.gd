extends Node2D
class_name CacodemonBreathXyezawrFlipbook

# XYEzawr Flipbook technique:
# - Uses the free pack's preview flame animation as repeated, layered flipbook bands instead of particles or cell blobs.
# - The breath is built from overlapping animated texture stamps that march forward in rows and are curved around the shield.
# - Shield interaction is achieved by splitting each band into upper/lower lanes near the shield, adding curl at the edge,
#   then easing the bands back together downstream while dimming inside the existing safe pocket.

const STRIP_PATH := "res://assets/external/xyezawr/free_pixel_effects_pack_preview2_strip_rot180.png"
const STRIP_FLIPPED_PATH := "res://assets/external/xyezawr/free_pixel_effects_pack_preview2_strip_flipped_rot180.png"
const FRAME_COUNT := 8
const FRAME_SIZE := Vector2i(200, 200)

static var _cached_forward_strip: Texture2D = null
static var _cached_flipped_strip: Texture2D = null

@export var band_count: int = 8
@export var band_segments: int = 12
@export var visual_length_padding: float = 260.0
@export var animation_fps: float = 15.0
@export var visual_refresh_rate: float = 30.0
@export var max_visual_steps_per_frame: int = 3
@export var front_ramp_speed: float = 1100.0
@export var front_min_length_scale: float = 0.75
@export var emitter_pullback_distance: float = 18.0
@export var stamp_forward_anchor_ratio: float = 0.2
@export var mouth_forward_offset_ratio: float = 0.38
@export var mouth_vertical_offset: float = 7.0
@export var origin_width_scale: float = 0.45
@export var near_sprite_scale: float = 8.6
@export var far_sprite_scale: float = 13.8
@export var curl_strength: float = 0.9
@export var split_push_scale: float = 1.08
@export var wake_hold_scale: float = 1.06
@export var rejoin_blend: float = 0.24

var source_enemy: EnemyBase = null
var target_player: Player = null
var stream_direction_x: float = 1.0
var stream_length: float = 220.0
var stream_half_width: float = 24.0
var is_emitting: bool = false
var elapsed: float = 0.0
var fade_alpha: float = 0.0
var visual_step_accumulator: float = 0.0
var front_distance: float = 0.0
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
	front_distance = 0.0
	queue_redraw()


func set_stream(direction_sign: float, length: float, half_width: float) -> void:
	stream_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	stream_length = maxf(48.0, length)
	stream_half_width = maxf(10.0, half_width)


func set_emitting(enabled: bool) -> void:
	var was_emitting := is_emitting
	is_emitting = enabled
	if enabled:
		fade_alpha = 1.0
		if not was_emitting:
			front_distance = 0.0


func set_visual_style(_style_index: int) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if source_enemy == null or not is_instance_valid(source_enemy) or source_enemy.dead:
		queue_free()
		return
	var safe_delta := maxf(0.0, delta)
	elapsed += safe_delta
	if not is_emitting:
		fade_alpha = move_toward(fade_alpha, 0.0, safe_delta * 3.0)
	else:
		fade_alpha = move_toward(fade_alpha, 1.0, safe_delta * 4.8)
		var min_front_length := maxf(48.0, stream_half_width * front_min_length_scale)
		front_distance = maxf(min_front_length, front_distance + (safe_delta * maxf(1.0, front_ramp_speed)))
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
	var texture := _get_active_strip_texture()
	if texture == null:
		return
	var origin := _get_emitter_origin()
	var full_visual_length := _get_visual_stream_length(origin)
	var active_visual_length := minf(full_visual_length, _get_active_visual_length(full_visual_length))
	var near_size := _get_sprite_size(0.0)
	var far_t := clampf(active_visual_length / maxf(1.0, full_visual_length), 0.0, 1.0)
	var far_size := _get_sprite_size(far_t)
	_draw_support_glow(origin, active_visual_length, near_size.y * 0.26, far_size.y * 0.18)
	var split_state := _get_split_state(origin, full_visual_length)
	var frame_index := int(floor(elapsed * maxf(1.0, animation_fps))) % FRAME_COUNT
	var source_rect := Rect2(frame_index * FRAME_SIZE.x, 0.0, FRAME_SIZE.x, FRAME_SIZE.y)
	var total_bands := maxi(4, band_count)
	for band_index in range(total_bands):
		var lane_ratio := 0.0 if total_bands <= 1 else float(band_index) / float(total_bands - 1)
		var lane_value := lerpf(-1.0, 1.0, lane_ratio)
		_draw_band(texture, source_rect, origin, active_visual_length, full_visual_length, split_state, lane_value, band_index)


func _draw_support_glow(origin: Vector2, visual_length: float, near_half_height: float, far_half_height: float) -> void:
	var mid_point := origin + Vector2(stream_direction_x * visual_length * 0.34, 0.0)
	var end_point := origin + Vector2(stream_direction_x * visual_length, 0.0)
	_draw_segment_quad(
		origin,
		mid_point,
		near_half_height * 1.42,
		lerpf(near_half_height, far_half_height, 0.34) * 1.08,
		Color(1.0, 0.22, 0.05, 0.02375 * fade_alpha)
	)
	_draw_segment_quad(
		mid_point,
		end_point,
		lerpf(near_half_height, far_half_height, 0.34) * 1.08,
		far_half_height * 1.04,
		Color(1.0, 0.12, 0.03, 0.01 * fade_alpha)
	)
	_draw_segment_quad(
		origin,
		mid_point,
		near_half_height * 0.78,
		lerpf(near_half_height, far_half_height, 0.34) * 0.58,
		Color(1.0, 0.56, 0.12, 0.0175 * fade_alpha)
	)
	_draw_segment_quad(
		mid_point,
		end_point,
		lerpf(near_half_height, far_half_height, 0.34) * 0.58,
		far_half_height * 0.5,
		Color(1.0, 0.28, 0.08, 0.0065 * fade_alpha)
	)


func _draw_band(texture: Texture2D, source_rect: Rect2, origin: Vector2, active_visual_length: float, full_visual_length: float, split_state: Dictionary, lane_value: float, band_index: int) -> void:
	var segments := maxi(6, band_segments)
	var spacing := full_visual_length / float(maxi(4, segments - 1))
	var travel_speed := 180.0 + (float(band_index) * 18.0)
	var offset := fmod(elapsed * travel_speed, spacing)
	for stamp_index in range(segments + 3):
		var progress := (float(stamp_index) * spacing) + offset - spacing
		if progress < -spacing or progress > active_visual_length + spacing:
			continue
		var t := clampf(progress / maxf(1.0, full_visual_length), 0.0, 1.0)
		var size := _get_sprite_size(t)
		var center := _get_stamp_center(origin, progress, full_visual_length, lane_value, size, split_state, band_index)
		var alpha_scale := _get_stamp_alpha(center, t, lane_value)
		alpha_scale *= clampf((active_visual_length - progress + (spacing * 0.65)) / maxf(1.0, spacing * 0.65), 0.0, 1.0)
		if alpha_scale <= 0.01:
			continue
		var brightness := _get_distance_brightness(t)
		var dest_rect := Rect2(center.x - (size.x * 0.5), center.y - (size.y * 0.5), size.x, size.y)
		var outer_modulate := Color(
			1.0,
			lerpf(0.76, 0.96, brightness),
			lerpf(0.62, 0.88, brightness),
			alpha_scale * lerpf(0.03, 0.08, brightness) * fade_alpha
		)
		var mid_modulate := Color(
			1.0,
			lerpf(0.82, 1.0, brightness),
			lerpf(0.7, 0.94, brightness),
			alpha_scale * lerpf(0.025, 0.06, brightness) * fade_alpha
		)
		var inner_modulate := Color(
			1.0,
			1.0,
			lerpf(0.82, 1.0, brightness),
			alpha_scale * lerpf(0.02, 0.045, brightness) * fade_alpha
		)
		_draw_rotated_stamp(texture, dest_rect, source_rect, outer_modulate)
		var mid_scale := 0.86
		var mid_size := size * mid_scale
		var mid_rect := Rect2(center.x - (mid_size.x * 0.5), center.y - (mid_size.y * 0.5), mid_size.x, mid_size.y)
		_draw_rotated_stamp(texture, mid_rect, source_rect, mid_modulate)
		var core_scale := 0.72
		var core_size := size * core_scale
		var core_rect := Rect2(center.x - (core_size.x * 0.5), center.y - (core_size.y * 0.5), core_size.x, core_size.y)
		_draw_rotated_stamp(texture, core_rect, source_rect, inner_modulate)


func _draw_rotated_stamp(texture: Texture2D, dest_rect: Rect2, source_rect: Rect2, modulate: Color) -> void:
	var center := dest_rect.position + (dest_rect.size * 0.5)
	draw_set_transform(center, PI, Vector2.ONE)
	var local_rect := Rect2(-dest_rect.size * 0.5, dest_rect.size)
	draw_texture_rect_region(texture, local_rect, source_rect, modulate, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _get_sprite_size(t: float) -> Vector2:
	var emitter_burst_scale := lerpf(0.22, 1.0, clampf((t - 0.02) / 0.18, 0.0, 1.0))
	var origin_width_blend := lerpf(origin_width_scale, 1.0, clampf((t - 0.01) / 0.16, 0.0, 1.0))
	var width := maxf(44.0 * origin_width_blend, stream_half_width * lerpf(near_sprite_scale, far_sprite_scale, pow(t, 0.68)) * emitter_burst_scale * origin_width_blend)
	var height := width * lerpf(0.92, 1.26, t)
	return Vector2(width, height)


func _get_stamp_center(origin: Vector2, progress: float, visual_length: float, lane_value: float, sprite_size: Vector2, split_state: Dictionary, band_index: int) -> Vector2:
	var t := clampf(progress / maxf(1.0, visual_length), 0.0, 1.0)
	var forward_anchor := sprite_size.x * clampf(stamp_forward_anchor_ratio, 0.0, 0.5)
	var x_pos := origin.x + (progress * stream_direction_x) + (stream_direction_x * forward_anchor)
	var width_here := lerpf(maxf(52.0, stream_half_width * 4.2), maxf(168.0, stream_half_width * 8.6), pow(t, 0.72))
	var y_pos := origin.y + (lane_value * width_here * 0.32)
	var phase := (elapsed * 2.9) + (float(band_index) * 0.83)
	y_pos += sin((progress * 0.02) + phase) * width_here * (0.04 + (0.01 * absf(lane_value)))
	y_pos += cos((progress * 0.011) - (elapsed * 1.7) + (float(band_index) * 0.53)) * width_here * 0.022
	if bool(split_state.get("active", false)):
		y_pos = _apply_split_flow(split_state, x_pos, y_pos, lane_value, sprite_size.y, progress, band_index)
	return Vector2(x_pos, y_pos)


func _apply_split_flow(split_state: Dictionary, x_pos: float, base_y: float, lane_value: float, sprite_height: float, progress: float, band_index: int) -> float:
	var split_start_x := float(split_state.get("split_start_x", x_pos))
	var wrap_peak_x := float(split_state.get("wrap_peak_x", x_pos))
	var wake_hold_x := float(split_state.get("wake_hold_x", x_pos))
	var rejoin_end_x := float(split_state.get("rejoin_end_x", x_pos))
	var shield_center: Vector2 = split_state.get("shield_center", Vector2(x_pos, base_y))
	var shield_half_extents: Vector2 = split_state.get("shield_half_extents", Vector2(12.0, 12.0))
	var gap_half := float(split_state.get("gap_half", 24.0))
	if (x_pos - split_start_x) * stream_direction_x < 0.0:
		return base_y
	var branch_sign := -1.0 if lane_value <= 0.0 else 1.0
	if absf(lane_value) <= 0.08:
		branch_sign = -1.0 if (band_index % 2) == 0 else 1.0
	var branch_y := shield_center.y + (branch_sign * (gap_half + (sprite_height * 0.08 * split_push_scale)))
	var curl_wave := sin((progress * 0.028) + (elapsed * 5.2) + (float(band_index) * 0.7)) * shield_half_extents.y * 0.26 * curl_strength
	if (x_pos - wrap_peak_x) * stream_direction_x <= 0.0:
		var span := wrap_peak_x - split_start_x
		var denom := span if absf(span) > 0.01 else stream_direction_x
		var blend := clampf((x_pos - split_start_x) / denom, 0.0, 1.0)
		var curved := sin(blend * PI * 0.5)
		return lerpf(base_y, branch_y, curved) + (branch_sign * curl_wave * blend)
	if (x_pos - wake_hold_x) * stream_direction_x <= 0.0:
		var held_wave := sin((progress * 0.02) - (elapsed * 3.3) + float(band_index)) * shield_half_extents.y * 0.18
		return branch_y + (branch_sign * held_wave * wake_hold_scale)
	if (x_pos - rejoin_end_x) * stream_direction_x <= 0.0:
		var span := rejoin_end_x - wake_hold_x
		var denom := span if absf(span) > 0.01 else stream_direction_x
		var blend := clampf((x_pos - wake_hold_x) / denom, 0.0, 1.0)
		var rejoin_target := shield_center.y + (branch_sign * gap_half * 0.14)
		var rejoin_wave := sin((1.0 - blend) * PI + (float(band_index) * 0.4)) * shield_half_extents.y * 0.08
		return lerpf(branch_y, rejoin_target, blend * (1.0 - rejoin_blend)) + (branch_sign * rejoin_wave)
	return lerpf(base_y, shield_center.y + (branch_sign * gap_half * 0.1), 0.34)


func _get_stamp_alpha(world_pos: Vector2, t: float, lane_value: float) -> float:
	var edge_falloff := clampf(1.0 - (absf(lane_value) * 0.12), 0.48, 1.0)
	var forward_falloff := clampf(1.18 - (t * 0.84), 0.22, 1.0)
	var alpha := edge_falloff * forward_falloff
	if _is_in_safe_pocket(world_pos):
		alpha *= 0.24
	return alpha


func _get_distance_brightness(t: float) -> float:
	return clampf(1.12 - (t * 0.82), 0.18, 1.0)


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


func _get_active_visual_length(full_visual_length: float) -> float:
	var min_front_length := maxf(48.0, stream_half_width * front_min_length_scale)
	if is_emitting:
		return clampf(maxf(min_front_length, front_distance), min_front_length, full_visual_length)
	return full_visual_length


func _get_split_state(origin: Vector2, visual_length: float) -> Dictionary:
	if not _is_player_blocking():
		return {"active": false}
	var shield_center := _get_player_shield_center()
	var shield_half_extents := _get_player_shield_half_extents()
	var forward_to_shield := (shield_center.x - origin.x) * stream_direction_x
	if forward_to_shield < 18.0 or forward_to_shield > visual_length - 36.0:
		return {"active": false}
	var split_start_x := shield_center.x - (stream_direction_x * maxf(56.0, shield_half_extents.x * 3.1))
	var wrap_peak_x := shield_center.x + (stream_direction_x * maxf(24.0, shield_half_extents.x * 1.3))
	var wake_hold_x := shield_center.x + (stream_direction_x * maxf(164.0, shield_half_extents.x * 6.2))
	var rejoin_end_x := shield_center.x + (stream_direction_x * maxf(320.0, shield_half_extents.x * 11.2))
	return {
		"active": true,
		"shield_center": shield_center,
		"shield_half_extents": shield_half_extents,
		"split_start_x": split_start_x,
		"wrap_peak_x": wrap_peak_x,
		"wake_hold_x": wake_hold_x,
		"rejoin_end_x": rejoin_end_x,
		"gap_half": shield_half_extents.y + maxf(24.0, stream_half_width * 2.0)
	}


func _get_active_strip_texture() -> Texture2D:
	return _load_strip_texture(stream_direction_x < 0.0)


static func _load_strip_texture(use_flipped: bool) -> Texture2D:
	if use_flipped:
		if _cached_flipped_strip != null:
			return _cached_flipped_strip
		_cached_flipped_strip = _load_texture_from_path(STRIP_FLIPPED_PATH)
		return _cached_flipped_strip
	if _cached_forward_strip != null:
		return _cached_forward_strip
	_cached_forward_strip = _load_texture_from_path(STRIP_PATH)
	return _cached_forward_strip


static func _load_texture_from_path(resource_path: String) -> Texture2D:
	var global_path := ProjectSettings.globalize_path(resource_path)
	var image := Image.new()
	var error := image.load(global_path)
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _get_emitter_origin() -> Vector2:
	if source_enemy == null or not is_instance_valid(source_enemy):
		return Vector2.ZERO
	if source_enemy.using_external_monster_sprite and source_enemy.monster_sprite != null and is_instance_valid(source_enemy.monster_sprite):
		var sprite := source_enemy.monster_sprite
		var frame_width := 64.0
		if sprite.texture != null:
			frame_width = float(sprite.texture.get_width()) / float(maxi(1, sprite.hframes))
		var scaled_frame_width := frame_width * absf(sprite.scale.x)
		var forward_offset := maxf(18.0, scaled_frame_width * clampf(mouth_forward_offset_ratio, 0.2, 0.5))
		return sprite.global_position + Vector2(stream_direction_x * forward_offset, mouth_vertical_offset)
	if source_enemy.has_method("_get_cacodemon_breath_origin"):
		var origin_variant: Variant = source_enemy.call("_get_cacodemon_breath_origin")
		if origin_variant is Vector2:
			return origin_variant - Vector2(stream_direction_x * maxf(0.0, emitter_pullback_distance), 0.0)
	return source_enemy.global_position + Vector2((36.0 - maxf(0.0, emitter_pullback_distance)) * stream_direction_x, -14.0)


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

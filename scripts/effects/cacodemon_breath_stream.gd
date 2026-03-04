extends Node2D
class_name CacodemonBreathStream

enum BreathVisualStyle {
	TORRENT_SPLIT
}

@export var particle_spawn_rate: float = 120.0
@export var max_particles: int = 180
@export var particle_speed: float = 315.0
@export var particle_lifetime: float = 2.1
@export var visual_length_padding: float = 180.0
@export var visual_half_width_floor: float = 92.0
@export var visual_far_width_multiplier: float = 2.8
@export var visual_style: BreathVisualStyle = BreathVisualStyle.TORRENT_SPLIT
@export var visual_refresh_rate: float = 30.0
@export var max_visual_steps_per_frame: int = 3

var source_enemy: EnemyBase = null
var target_player: Player = null
var stream_direction_x: float = 1.0
var stream_length: float = 220.0
var stream_half_width: float = 24.0
var is_emitting: bool = false
var spawn_accumulator: float = 0.0
var particles: Array[Dictionary] = []
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


func set_visual_style(_style_index: int) -> void:
	if visual_style != BreathVisualStyle.TORRENT_SPLIT:
		visual_style = BreathVisualStyle.TORRENT_SPLIT
	queue_redraw()


func _process(delta: float) -> void:
	if source_enemy == null or not is_instance_valid(source_enemy) or source_enemy.dead:
		queue_free()
		return
	var step_rate := maxf(1.0, visual_refresh_rate)
	var step_delta := 1.0 / step_rate
	visual_step_accumulator += maxf(0.0, delta)
	var steps := 0
	while visual_step_accumulator >= step_delta and steps < maxi(1, max_visual_steps_per_frame):
		visual_step_accumulator -= step_delta
		_spawn_particles(step_delta)
		_tick_particles(step_delta)
		steps += 1
	if steps > 0:
		queue_redraw()
	if not is_emitting and particles.is_empty():
		queue_free()


func _spawn_particles(delta: float) -> void:
	if not is_emitting:
		return
	var profile := _get_style_profile()
	var safe_spawn_rate := maxf(1.0, particle_spawn_rate * float(profile.get("spawn_rate_scale", 1.0)))
	spawn_accumulator += maxf(0.0, delta) * safe_spawn_rate
	var origin := _get_emitter_origin()
	var spawn_band := maxf(stream_half_width * float(profile.get("spawn_band_scale", 1.35)), 28.0)
	var style_max_particles := maxi(8, int(round(float(max_particles) * float(profile.get("max_particles_scale", 1.0)))))
	while spawn_accumulator >= 1.0 and particles.size() < style_max_particles:
		spawn_accumulator -= 1.0
		var lateral_offset := rng.randf_range(-spawn_band, spawn_band)
		var particle_position := origin + Vector2(0.0, lateral_offset)
		var lateral_jitter := rng.randf_range(-float(profile.get("spawn_jitter", 0.28)), float(profile.get("spawn_jitter", 0.28)))
		var travel_vector := Vector2(stream_direction_x, lateral_jitter).normalized()
		var travel_speed := rng.randf_range(
			particle_speed * float(profile.get("spawn_speed_min", 0.76)),
			particle_speed * float(profile.get("spawn_speed_max", 1.22))
		)
		var heat := rng.randf_range(0.0, 1.0)
		particles.append({
			"position": particle_position,
			"velocity": travel_vector * travel_speed,
			"age": 0.0,
			"life": rng.randf_range(particle_lifetime * 0.72, particle_lifetime * 1.18),
			"radius": rng.randf_range(4.0, 9.5),
			"deflected": false,
			"heat": heat,
			"branch_sign": 0.0,
			"spin": rng.randf_range(-1.0, 1.0)
		})


func _tick_particles(delta: float) -> void:
	if particles.is_empty():
		return
	var profile := _get_style_profile()
	var alive_particles: Array[Dictionary] = []
	var stream_origin := _get_emitter_origin()
	var visual_length := _get_visual_stream_length(stream_origin)
	var forward_direction := Vector2(stream_direction_x, 0.0)
	var blocking := _is_player_blocking()
	var shield_center := _get_player_shield_center()
	var shield_radius := _get_player_shield_radius()
	for particle in particles:
		var age := float(particle.get("age", 0.0)) + maxf(0.0, delta)
		var life := maxf(0.01, float(particle.get("life", particle_lifetime)))
		if age >= life:
			continue
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", forward_direction * particle_speed)
		var radius := maxf(1.0, float(particle.get("radius", 2.0)))
		var deflected := bool(particle.get("deflected", false))
		var branch_sign := float(particle.get("branch_sign", 0.0))
		var spin := float(particle.get("spin", 0.0))
		if blocking:
			var to_particle := position - shield_center
			var forward_to_shield := (position.x - shield_center.x) * stream_direction_x
			var wall_influence_x := shield_radius + float(profile.get("lead_distance", 64.0))
			if forward_to_shield >= -wall_influence_x and forward_to_shield <= shield_radius * 3.2:
				if absf(branch_sign) <= 0.01:
					branch_sign = -1.0 if position.y <= shield_center.y else 1.0
				var branch_gap := shield_radius + maxf(32.0, stream_half_width * float(profile.get("branch_offset_scale", 2.8)))
				var branch_target_y := shield_center.y + (branch_sign * branch_gap)
				position.y = move_toward(position.y, branch_target_y, maxf(0.0, delta) * maxf(150.0, particle_speed * float(profile.get("branch_track_speed_scale", 0.88))))
				var target_velocity := (
					forward_direction * maxf(180.0, particle_speed * float(profile.get("branch_forward_scale", 0.86)))
				) + Vector2(0.0, branch_sign * maxf(220.0, particle_speed * float(profile.get("branch_vertical_scale", 0.92))))
				velocity = velocity.lerp(target_velocity, clampf(delta * float(profile.get("branch_blend_speed", 7.5)), 0.0, 1.0))
				deflected = true
			var influence_radius := shield_radius + radius + 10.0
			if to_particle.length_squared() <= influence_radius * influence_radius:
				var normal := to_particle.normalized()
				if normal.length_squared() <= 0.0001:
					normal = Vector2.UP
				branch_sign = -1.0 if normal.y <= 0.0 else 1.0
				var tangent := Vector2(-normal.y, normal.x)
				if tangent.dot(forward_direction) < 0.0:
					tangent = -tangent
				position = shield_center + (normal * (shield_radius + radius + 2.0))
				var speed := maxf(80.0, velocity.length())
				var tangent_weight := float(profile.get("obstacle_tangent_weight", 0.54))
				var forward_weight := float(profile.get("obstacle_forward_weight", 0.42))
				var side_weight := float(profile.get("obstacle_side_weight", 0.84))
				velocity = ((tangent * tangent_weight) + (forward_direction * forward_weight) + Vector2(0.0, branch_sign * side_weight)).normalized() * speed
				deflected = true
			elif not deflected:
				velocity = velocity.lerp(
					forward_direction * maxf(80.0, particle_speed * float(profile.get("rejoin_speed_scale", 1.0))),
					clampf(delta * float(profile.get("rejoin_lerp_speed", 3.6)), 0.0, 1.0)
				)
			elif absf(branch_sign) > 0.01:
				var held_branch_y := shield_center.y + (branch_sign * (shield_radius + maxf(32.0, stream_half_width * float(profile.get("branch_offset_scale", 2.8)))))
				velocity.y += clampf((held_branch_y - position.y) * float(profile.get("hold_pull_scale", 2.2)), -210.0, 210.0) * delta
				velocity = _apply_post_shield_flow(profile, shield_center, position, velocity, forward_direction, delta, age, spin, branch_sign)
		elif not deflected:
			var center_pull := clampf((stream_origin.y - position.y) / maxf(12.0, stream_half_width * float(profile.get("center_pull_span_scale", 2.0))), -1.0, 1.0)
			velocity.y += center_pull * float(profile.get("center_pull_force", 72.0)) * delta
		position += velocity * maxf(0.0, delta)
		var forward_travel := (position.x - stream_origin.x) * stream_direction_x
		if forward_travel < -64.0 or forward_travel > visual_length + 140.0:
			continue
		particle["position"] = position
		particle["velocity"] = velocity
		particle["age"] = age
		particle["deflected"] = deflected
		particle["branch_sign"] = branch_sign
		particle["spin"] = spin
		alive_particles.append(particle)
	particles = alive_particles


func _draw() -> void:
	var origin := _get_emitter_origin()
	var visual_length := _get_visual_stream_length(origin)
	var forward_direction := Vector2(stream_direction_x, 0.0)
	var end_point := origin + (forward_direction * visual_length)
	var pulse := 0.5 + (0.5 * sin(Time.get_ticks_msec() * 0.012))
	var near_half_width := maxf(visual_half_width_floor, stream_half_width * 3.6)
	var far_half_width := near_half_width * visual_far_width_multiplier
	var split_state := _get_block_split_state(origin, visual_length, near_half_width, far_half_width)
	_draw_torrent_body(origin, end_point, near_half_width, far_half_width, split_state, pulse)
	if particles.is_empty():
		return
	var profile := _get_style_profile()
	var draw_stride := 1
	if particles.size() >= 120:
		draw_stride = 2
	if particles.size() >= 180:
		draw_stride = 3
	for particle_index in range(0, particles.size(), draw_stride):
		var particle := particles[particle_index]
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", Vector2.RIGHT)
		var radius := maxf(1.0, float(particle.get("radius", 2.0)))
		var life := maxf(0.01, float(particle.get("life", particle_lifetime)))
		var age := clampf(float(particle.get("age", 0.0)), 0.0, life)
		var life_ratio := 1.0 - (age / life)
		var deflected := bool(particle.get("deflected", false))
		var heat := clampf(float(particle.get("heat", 0.5)), 0.0, 1.0)
		var draw_radius := radius * float(profile.get("draw_radius_scale", 1.0))
		var draw_alpha := float(profile.get("draw_alpha_scale", 1.0))
		var tail_scale := float(profile.get("tail_scale", 1.0))
		var green_bias := float(profile.get("green_bias", 0.0))
		var blue_bias := float(profile.get("blue_bias", 0.0))
		var color := Color(
			1.0,
			clampf(lerpf(0.22, 0.66, heat) + green_bias, 0.0, 1.0),
			clampf(lerpf(0.02, 0.14, 1.0 - heat) + blue_bias, 0.0, 1.0),
			clampf(lerpf(0.14, 0.82, life_ratio) * draw_alpha, 0.0, 1.0)
		)
		if deflected:
			color = Color(1.0, clampf(0.88 + (green_bias * 0.5), 0.0, 1.0), clampf(0.42 + (blue_bias * 0.3), 0.0, 1.0), clampf(lerpf(0.16, 0.8, life_ratio) * draw_alpha, 0.0, 1.0))
		var tail_direction := velocity.normalized()
		if tail_direction.length_squared() <= 0.0001:
			tail_direction = Vector2(stream_direction_x, 0.0)
		var tail_length := draw_radius * (5.8 if not deflected else 4.2) * tail_scale
		draw_line(position - (tail_direction * tail_length), position, color, maxf(2.0, draw_radius * 1.12), true)
		draw_circle(position, draw_radius * 1.08, Color(1.0, lerpf(color.g, 0.92, 0.35), lerpf(color.b, 0.18, 0.25), color.a))


func _draw_torrent_body(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, split_state: Dictionary, pulse: float) -> void:
	if bool(split_state.get("active", false)):
		_draw_split_torrent(origin, end_point, near_half_width, far_half_width, split_state, pulse)
	else:
		_draw_base_cone(origin, end_point, near_half_width, far_half_width, pulse)


func _draw_pressure_jet(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, split_state: Dictionary, pulse: float) -> void:
	var wall_near := near_half_width * 0.8
	var wall_far := far_half_width * 0.64
	if bool(split_state.get("active", false)):
		var boosted_split := split_state.duplicate()
		var shield_center: Vector2 = split_state.get("shield_center", origin)
		boosted_split["gap_half"] = float(split_state.get("gap_half", 32.0)) + maxf(10.0, stream_half_width * 1.1)
		_draw_split_torrent(origin, end_point, wall_near, wall_far, boosted_split, pulse)
		_draw_split_branch_pair(
			float(boosted_split.get("split_start_x", origin.x)),
			float(boosted_split.get("split_mid_x", origin.x)),
			end_point.x,
			origin.y,
			(shield_center if "shield_center" in boosted_split else origin).y,
			float(boosted_split.get("gap_half", 32.0)) * 1.18,
			wall_near * 0.42,
			wall_far * 0.46,
			Color(0.24, 0.02, 0.02, 0.18),
			Color(0.08, 0.0, 0.0, 0.04)
		)
	else:
		_draw_base_cone(origin, end_point, wall_near, far_half_width * 0.58, pulse)
	_draw_stream_quad(
		origin.x,
		end_point.x,
		origin.y,
		end_point.y,
		wall_near * 0.24,
		wall_far * 0.2,
		Color(1.0, 1.0, 0.9, 0.58 + (pulse * 0.06)),
		Color(1.0, 0.9, 0.18, 0.14)
	)


func _draw_coanda_wrap(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, split_state: Dictionary, pulse: float) -> void:
	if not bool(split_state.get("active", false)):
		_draw_torrent_body(origin, end_point, near_half_width * 0.92, far_half_width * 0.86, split_state, pulse)
		return
	var extended_split := split_state.duplicate()
	extended_split["gap_half"] = float(split_state.get("gap_half", 32.0)) + maxf(22.0, stream_half_width * 2.0)
	extended_split["split_mid_x"] = float(split_state.get("split_mid_x", origin.x)) + (stream_direction_x * maxf(48.0, stream_half_width * 4.2))
	_draw_split_torrent(origin, end_point, near_half_width * 0.96, far_half_width * 0.9, extended_split, pulse)
	var shield_center: Vector2 = extended_split.get("shield_center", origin)
	_draw_split_branch_pair(
		float(extended_split.get("split_start_x", origin.x)),
		float(extended_split.get("split_mid_x", origin.x)),
		end_point.x,
		origin.y,
		shield_center.y,
		float(extended_split.get("gap_half", 32.0)) * 1.1,
		near_half_width * 0.28,
		far_half_width * 0.32,
		Color(1.0, 0.96, 0.58, 0.28 + (pulse * 0.05)),
		Color(1.0, 0.46, 0.08, 0.08)
	)


func _draw_braided_ribbons(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, split_state: Dictionary, pulse: float) -> void:
	_draw_torrent_body(origin, end_point, near_half_width * 0.72, far_half_width * 0.68, split_state, pulse)
	var split_active := bool(split_state.get("active", false))
	var shield_center: Vector2 = split_state.get("shield_center", origin)
	var split_start_x := float(split_state.get("split_start_x", origin.x))
	var split_mid_x := float(split_state.get("split_mid_x", origin.x))
	var shield_gap := float(split_state.get("gap_half", 32.0))
	for ribbon_index in range(3):
		var ribbon_value := float(ribbon_index)
		var phase := ribbon_value * 1.7
		var base_offset := (ribbon_value - 1.0) * (near_half_width * 0.2)
		var previous_point := origin + Vector2(0.0, base_offset)
		var previous_half := maxf(8.0, near_half_width * 0.08)
		for segment in range(1, 11):
			var t := float(segment) / 10.0
			var x_pos := lerpf(origin.x, end_point.x, t)
			var width_here := lerpf(near_half_width, far_half_width, t)
			var wave_amplitude := width_here * (0.12 + (ribbon_value * 0.025))
			var y_pos := lerpf(origin.y, end_point.y, t) + base_offset + (sin((t * TAU * 1.35) + phase + (pulse * 0.8)) * wave_amplitude)
			if split_active and (x_pos - split_start_x) * stream_direction_x >= 0.0:
				var branch_sign := -1.0 if ribbon_index < 2 else 1.0
				var split_delta := split_mid_x - split_start_x
				var split_denominator := split_delta if absf(split_delta) > 0.01 else (stream_direction_x * 1.0)
				var branch_progress := clampf((x_pos - split_start_x) / split_denominator, 0.0, 1.0)
				var branch_center := shield_center.y + (branch_sign * (shield_gap + (width_here * 0.22)))
				y_pos = lerpf(y_pos, branch_center, clampf(branch_progress * 0.85, 0.0, 0.85))
			var current_point := Vector2(x_pos, y_pos)
			var current_half := maxf(8.0, lerpf(previous_half, width_here * 0.1, 0.55))
			var color_start := Color(1.0, 0.82, 0.22, 0.28 + (0.06 * ribbon_value))
			var color_end := Color(1.0, 0.32, 0.04, 0.1)
			_draw_stream_quad(previous_point.x, current_point.x, previous_point.y, current_point.y, previous_half, current_half, color_start, color_end)
			previous_point = current_point
			previous_half = current_half


func _draw_vortex_shear(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, split_state: Dictionary, pulse: float) -> void:
	if bool(split_state.get("active", false)):
		_draw_split_torrent(origin, end_point, near_half_width * 0.84, far_half_width * 0.82, split_state, pulse)
	else:
		_draw_stream_quad(
			origin.x,
			end_point.x,
			origin.y,
			end_point.y,
			near_half_width * 0.9,
			far_half_width * 0.88,
			Color(0.48, 0.06, 0.02, 0.16),
			Color(0.14, 0.02, 0.02, 0.04)
		)
		_draw_stream_quad(
			origin.x,
			end_point.x,
			origin.y,
			end_point.y,
			near_half_width * 0.34,
			far_half_width * 0.28,
			Color(1.0, 0.96, 0.44, 0.22 + (pulse * 0.06)),
			Color(1.0, 0.36, 0.04, 0.06)
		)
	var swirl_center_x := lerpf(origin.x, end_point.x, 0.22)
	for swirl_index in range(4):
		var swirl_t := float(swirl_index) / 3.0
		var swirl_center := Vector2(swirl_center_x + (swirl_t * stream_direction_x * 96.0), origin.y + (sin((swirl_t * TAU) + pulse) * near_half_width * 0.22))
		draw_arc(swirl_center, maxf(14.0, near_half_width * (0.16 + (swirl_t * 0.04))), PI * 0.15, PI * 1.65, 14, Color(1.0, 0.72, 0.12, 0.14), 2.0, true)


func _draw_base_cone(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, pulse: float) -> void:
	_draw_stream_quad(
		origin.x,
		end_point.x,
		origin.y,
		end_point.y,
		near_half_width,
		far_half_width,
		Color(1.0, 0.52, 0.12, 0.36),
		Color(0.92, 0.12, 0.02, 0.12)
	)
	_draw_stream_quad(
		origin.x,
		end_point.x,
		origin.y,
		end_point.y,
		near_half_width * 0.58,
		far_half_width * 0.62,
		Color(1.0, 0.86, 0.24, 0.5 + (pulse * 0.08)),
		Color(1.0, 0.24, 0.02, 0.18)
	)
	_draw_stream_quad(
		origin.x,
		end_point.x,
		origin.y,
		end_point.y,
		near_half_width * 0.18,
		far_half_width * 0.18,
		Color(1.0, 0.98, 0.72, 0.72),
		Color(1.0, 0.82, 0.12, 0.14)
	)


func _draw_split_torrent(origin: Vector2, end_point: Vector2, near_half_width: float, far_half_width: float, split_state: Dictionary, pulse: float) -> void:
	var split_start_x := float(split_state.get("split_start_x", origin.x))
	var split_mid_x := float(split_state.get("split_mid_x", origin.x))
	var shield_center: Vector2 = split_state.get("shield_center", origin)
	var gap_half := float(split_state.get("gap_half", 32.0))
	var upstream_ratio := clampf(absf(split_start_x - origin.x) / maxf(1.0, absf(end_point.x - origin.x)), 0.0, 1.0)
	var upstream_end_half := lerpf(near_half_width, far_half_width, upstream_ratio)
	_draw_stream_quad(
		origin.x,
		split_start_x,
		origin.y,
		origin.y,
		near_half_width,
		upstream_end_half,
		Color(1.0, 0.52, 0.12, 0.38),
		Color(0.98, 0.22, 0.04, 0.3)
	)
	_draw_stream_quad(
		origin.x,
		split_start_x,
		origin.y,
		origin.y,
		near_half_width * 0.58,
		upstream_end_half * 0.58,
		Color(1.0, 0.88, 0.24, 0.54 + (pulse * 0.08)),
		Color(1.0, 0.44, 0.06, 0.26)
	)
	_draw_stream_quad(
		origin.x,
		split_start_x,
		origin.y,
		origin.y,
		near_half_width * 0.18,
		upstream_end_half * 0.18,
		Color(1.0, 0.98, 0.76, 0.74),
		Color(1.0, 0.88, 0.24, 0.22)
	)
	_draw_split_branch_pair(
		split_start_x,
		split_mid_x,
		end_point.x,
		origin.y,
		shield_center.y,
		gap_half,
		upstream_end_half,
		far_half_width,
		Color(1.0, 0.52, 0.12, 0.38),
		Color(0.96, 0.12, 0.02, 0.14)
	)
	_draw_split_branch_pair(
		split_start_x,
		split_mid_x,
		end_point.x,
		origin.y,
		shield_center.y,
		gap_half * 0.9,
		upstream_end_half * 0.58,
		far_half_width * 0.62,
		Color(1.0, 0.86, 0.22, 0.54 + (pulse * 0.08)),
		Color(1.0, 0.26, 0.02, 0.22)
	)
	_draw_split_branch_pair(
		split_start_x,
		split_mid_x,
		end_point.x,
		origin.y,
		shield_center.y,
		gap_half * 0.72,
		maxf(8.0, upstream_end_half * 0.18),
		maxf(12.0, far_half_width * 0.18),
		Color(1.0, 0.98, 0.76, 0.76),
		Color(1.0, 0.84, 0.16, 0.16)
	)
	draw_circle(shield_center + Vector2(0.0, -gap_half * 0.92), maxf(8.0, gap_half * 0.28), Color(1.0, 0.72, 0.18, 0.22 + (pulse * 0.06)))
	draw_circle(shield_center + Vector2(0.0, gap_half * 0.92), maxf(8.0, gap_half * 0.28), Color(1.0, 0.72, 0.18, 0.22 + (pulse * 0.06)))


func _draw_split_branch_pair(split_start_x: float, split_mid_x: float, end_x: float, origin_y: float, shield_y: float, gap_half: float, branch_start_half: float, branch_end_half: float, start_color: Color, end_color: Color) -> void:
	var branch_mid_half: float = lerpf(branch_start_half, branch_end_half, 0.44)
	for branch_sign_variant in [-1.0, 1.0]:
		var branch_sign: float = float(branch_sign_variant)
		var start_center_y: float = lerpf(origin_y, shield_y + (branch_sign * gap_half), 0.42)
		var mid_center_y: float = shield_y + (branch_sign * (gap_half + (branch_mid_half * 0.58)))
		var end_center_y: float = shield_y + (branch_sign * (gap_half + (branch_end_half * 0.5)))
		_draw_stream_quad(
			split_start_x,
			split_mid_x,
			start_center_y,
			mid_center_y,
			maxf(10.0, branch_start_half * 0.42),
			branch_mid_half,
			start_color,
			end_color
		)
		_draw_stream_quad(
			split_mid_x,
			end_x,
			mid_center_y,
			end_center_y,
			branch_mid_half,
			branch_end_half,
			start_color,
			end_color
		)


func _draw_stream_quad(start_x: float, end_x: float, start_center_y: float, end_center_y: float, start_half_width: float, end_half_width: float, start_color: Color, end_color: Color) -> void:
	var points := PackedVector2Array([
		Vector2(start_x, start_center_y - start_half_width),
		Vector2(start_x, start_center_y + start_half_width),
		Vector2(end_x, end_center_y + end_half_width),
		Vector2(end_x, end_center_y - end_half_width)
	])
	var colors := PackedColorArray([start_color, start_color, end_color, end_color])
	draw_polygon(points, colors)


func _get_block_split_state(origin: Vector2, visual_length: float, near_half_width: float, far_half_width: float) -> Dictionary:
	if not _is_player_blocking():
		return {"active": false}
	var shield_center := _get_player_shield_center()
	var shield_radius := _get_player_shield_radius()
	var forward_to_shield := (shield_center.x - origin.x) * stream_direction_x
	if forward_to_shield < 36.0 or forward_to_shield > visual_length - 36.0:
		return {"active": false}
	var shield_ratio := clampf(forward_to_shield / maxf(1.0, visual_length), 0.0, 1.0)
	var stream_half_at_shield := lerpf(near_half_width, far_half_width, shield_ratio)
	if absf(shield_center.y - origin.y) > stream_half_at_shield + (shield_radius * 0.85):
		return {"active": false}
	var split_start_x := shield_center.x - (stream_direction_x * maxf(52.0, shield_radius * 2.4))
	var split_mid_x := shield_center.x + (stream_direction_x * maxf(30.0, shield_radius * 1.1))
	var split_end_x := shield_center.x + (stream_direction_x * maxf(96.0, shield_radius * 3.9))
	var gap_half := shield_radius + 26.0
	return {
		"active": true,
		"shield_center": shield_center,
		"split_start_x": split_start_x,
		"split_mid_x": split_mid_x,
		"split_end_x": split_end_x,
		"gap_half": gap_half
	}


func _get_style_profile() -> Dictionary:
	return {
		"spawn_rate_scale": 1.0,
		"max_particles_scale": 1.0,
		"spawn_band_scale": 1.35,
		"spawn_jitter": 0.28,
		"spawn_speed_min": 0.76,
		"spawn_speed_max": 1.22,
		"lead_distance": 64.0,
		"branch_offset_scale": 2.8,
		"branch_track_speed_scale": 0.88,
		"branch_forward_scale": 0.86,
		"branch_vertical_scale": 0.92,
		"branch_blend_speed": 7.5,
		"obstacle_tangent_weight": 0.54,
		"obstacle_forward_weight": 0.42,
		"obstacle_side_weight": 0.84,
		"rejoin_speed_scale": 1.0,
		"rejoin_lerp_speed": 3.6,
		"hold_pull_scale": 2.2,
		"center_pull_span_scale": 2.0,
		"center_pull_force": 72.0,
		"post_wave_amplitude": 22.0,
		"post_wave_frequency": 0.02,
		"post_wave_speed": 6.6,
		"post_wave_force": 46.0,
		"draw_radius_scale": 1.0,
		"draw_alpha_scale": 1.0,
		"tail_scale": 1.0,
		"green_bias": 0.0,
		"blue_bias": 0.0
	}


func _apply_post_shield_flow(profile: Dictionary, shield_center: Vector2, position: Vector2, velocity: Vector2, forward_direction: Vector2, delta: float, age: float, spin: float, branch_sign: float) -> Vector2:
	var downstream := (position.x - shield_center.x) * stream_direction_x
	if downstream <= 0.0:
		return velocity
	var wave_amplitude := float(profile.get("post_wave_amplitude", 22.0))
	var wave_frequency := float(profile.get("post_wave_frequency", 0.02))
	var wave_speed := float(profile.get("post_wave_speed", 6.6))
	var wave_force := float(profile.get("post_wave_force", 46.0))
	var downstream_wave := sin((downstream * wave_frequency) + (age * wave_speed) + (spin * PI)) * wave_amplitude
	velocity.y += ((downstream_wave + (branch_sign * wave_amplitude * 0.4)) - (position.y - shield_center.y)) * wave_force * delta * 0.01
	var rejoin_target := forward_direction * maxf(80.0, particle_speed * float(profile.get("rejoin_speed_scale", 1.0)))
	velocity.x = lerpf(velocity.x, rejoin_target.x, clampf(delta * float(profile.get("rejoin_lerp_speed", 3.6)), 0.0, 1.0))
	return velocity


func _get_visual_stream_length(origin: Vector2) -> float:
	var visual_length := stream_length + maxf(64.0, visual_length_padding)
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

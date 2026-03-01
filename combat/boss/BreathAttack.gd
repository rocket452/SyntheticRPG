extends RefCounted
class_name BreathAttack

enum State {
	IDLE,
	CHARGE,
	FIRE,
	COOLDOWN
}

const STATE_NAMES: Dictionary = {
	State.IDLE: "Idle",
	State.CHARGE: "Charge",
	State.FIRE: "Fire",
	State.COOLDOWN: "Cooldown"
}

var charge_duration: float = 1.1
var fire_duration: float = 2.7
var cooldown_duration: float = 4.8
var damage_tick_interval: float = 0.16
var range: float = 248.0
var half_width: float = 24.0
var telegraph_half_width_scale: float = 3.8
var pocket_back_offset: float = 58.0
var pocket_half_width: float = 42.0
var pocket_half_depth: float = 32.0

var state: State = State.IDLE
var state_time_left: float = 0.0
var damage_tick_left: float = 0.0
var boss_position: Vector2 = Vector2.ZERO
var tank_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var tank_blocking: bool = false


func configure(values: Dictionary) -> void:
	charge_duration = maxf(0.05, float(values.get("charge_duration", charge_duration)))
	fire_duration = maxf(0.1, float(values.get("fire_duration", fire_duration)))
	cooldown_duration = maxf(0.05, float(values.get("cooldown_duration", cooldown_duration)))
	damage_tick_interval = maxf(0.04, float(values.get("damage_tick_interval", damage_tick_interval)))
	range = maxf(48.0, float(values.get("range", range)))
	half_width = maxf(10.0, float(values.get("half_width", half_width)))
	telegraph_half_width_scale = maxf(1.0, float(values.get("telegraph_half_width_scale", telegraph_half_width_scale)))
	pocket_back_offset = maxf(12.0, float(values.get("pocket_back_offset", pocket_back_offset)))
	pocket_half_width = maxf(8.0, float(values.get("pocket_half_width", pocket_half_width)))
	pocket_half_depth = maxf(8.0, float(values.get("pocket_half_depth", pocket_half_depth)))


func can_begin() -> bool:
	return state == State.IDLE


func force_start(boss_pos: Vector2, tank_pos: Vector2, aim_direction: Vector2) -> void:
	boss_position = boss_pos
	tank_position = tank_pos
	direction = _sanitize_direction(aim_direction)
	state = State.CHARGE
	state_time_left = charge_duration
	damage_tick_left = 0.0


func cancel() -> void:
	state = State.IDLE
	state_time_left = 0.0
	damage_tick_left = 0.0


func update(delta: float, boss_pos: Vector2, tank_pos: Vector2, aim_direction: Vector2, tank_is_blocking: bool) -> Dictionary:
	boss_position = boss_pos
	tank_position = tank_pos
	direction = _sanitize_direction(aim_direction if state == State.IDLE or state == State.CHARGE else direction)
	tank_blocking = tank_is_blocking
	var result := {
		"state_changed": false,
		"entered_charge": false,
		"entered_fire": false,
		"entered_cooldown": false,
		"ended": false,
		"fire_tick": false
	}
	if state == State.IDLE:
		return result

	state_time_left = maxf(0.0, state_time_left - maxf(0.0, delta))
	if state == State.CHARGE:
		if state_time_left <= 0.0:
			state = State.FIRE
			state_time_left = fire_duration
			damage_tick_left = 0.0
			result["state_changed"] = true
			result["entered_fire"] = true
		return result

	if state == State.FIRE:
		damage_tick_left = maxf(0.0, damage_tick_left - maxf(0.0, delta))
		if damage_tick_left <= 0.0:
			damage_tick_left = damage_tick_interval
			result["fire_tick"] = true
		if state_time_left <= 0.0:
			state = State.COOLDOWN
			state_time_left = cooldown_duration
			damage_tick_left = 0.0
			result["state_changed"] = true
			result["entered_cooldown"] = true
		return result

	if state == State.COOLDOWN and state_time_left <= 0.0:
		state = State.IDLE
		state_time_left = 0.0
		result["state_changed"] = true
		result["ended"] = true
	return result


func is_charge_active() -> bool:
	return state == State.CHARGE


func is_fire_active() -> bool:
	return state == State.FIRE


func is_cooldown_active() -> bool:
	return state == State.COOLDOWN


func is_threat_active() -> bool:
	return state == State.CHARGE or state == State.FIRE


func get_state_name() -> String:
	return String(STATE_NAMES.get(state, "Idle"))


func get_time_remaining() -> float:
	return maxf(0.0, state_time_left)


func get_direction() -> Vector2:
	return _sanitize_direction(direction)


func get_telegraph_half_width() -> float:
	return maxf(half_width * telegraph_half_width_scale, half_width + 36.0)


func get_safe_pocket_center() -> Vector2:
	return tank_position + (get_direction() * pocket_back_offset)


func is_safe_pocket_valid() -> bool:
	if not tank_blocking:
		return false
	var dir := get_direction()
	var pocket_center := get_safe_pocket_center()
	var boss_to_tank := tank_position - boss_position
	var boss_to_pocket := pocket_center - boss_position
	if boss_to_pocket.dot(dir) <= 0.0:
		return false
	return boss_to_tank.dot(dir) < boss_to_pocket.dot(dir)


func is_in_safe_pocket(world_position: Vector2) -> bool:
	if not is_safe_pocket_valid():
		return false
	var dir := get_direction()
	var local_x := (world_position - get_safe_pocket_center()).dot(-dir)
	var local_y := (world_position - get_safe_pocket_center()).dot(Vector2(-dir.y, dir.x))
	var normalized_x := local_x / maxf(1.0, pocket_half_depth)
	var normalized_y := local_y / maxf(1.0, pocket_half_width)
	return (normalized_x * normalized_x) + (normalized_y * normalized_y) <= 1.0


func is_in_damage_lane(world_position: Vector2, origin: Vector2) -> bool:
	var end_point := origin + (get_direction() * range)
	return _distance_to_segment(world_position, origin, end_point) <= maxf(10.0, half_width)


func build_threat_snapshot(origin: Vector2) -> Dictionary:
	return {
		"active": is_threat_active(),
		"charge_active": is_charge_active(),
		"fire_active": is_fire_active(),
		"cooldown_active": is_cooldown_active(),
		"state": int(state),
		"state_name": get_state_name(),
		"time_remaining": get_time_remaining(),
		"dir": get_direction(),
		"boss_position": boss_position,
		"tank_position": tank_position,
		"origin": origin,
		"range": range,
		"half_width": half_width,
		"telegraph_half_width": get_telegraph_half_width(),
		"safe_pocket_valid": is_safe_pocket_valid(),
		"safe_pocket_center": get_safe_pocket_center(),
		"safe_pocket_half_width": pocket_half_width,
		"safe_pocket_half_depth": pocket_half_depth,
		"tank_blocking": tank_blocking
	}


func _sanitize_direction(raw_direction: Vector2) -> Vector2:
	var next_direction := raw_direction
	if next_direction.length_squared() <= 0.0001:
		next_direction = tank_position - boss_position
	if next_direction.length_squared() <= 0.0001:
		next_direction = Vector2.RIGHT
	next_direction = next_direction.normalized()
	if absf(next_direction.x) < 0.001:
		next_direction.x = 1.0 if direction.x >= 0.0 else -1.0
		next_direction.y = 0.0
	return next_direction.normalized()


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return point.distance_to(segment_start)
	var t := clampf((point - segment_start).dot(segment) / segment_length_sq, 0.0, 1.0)
	var projected := segment_start + (segment * t)
	return point.distance_to(projected)

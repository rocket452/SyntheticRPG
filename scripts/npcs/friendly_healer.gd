extends Node2D
class_name FriendlyHealer

@export var heal_amount: float = 20.0
@export var heal_interval: float = 4.2
@export var heal_interval_variance: float = 0.7
@export var heal_threshold_ratio: float = 0.98
@export var heal_effect_duration: float = 0.24
@export var cast_frame_to_heal: int = 4
@export var reacquire_retry_interval: float = 0.3
@export var react_heal_delay: float = 0.18
@export var emergency_cast_on_damage: bool = true

const HEALER_SHEET: Texture2D = preload("res://assets/external/ElthenAssets/fishfolk/Fishfolk Archpriest Sprite Sheet.png")
const HEALER_HFRAMES: int = 9
const HEALER_VFRAMES: int = 6
const FRAME_ALPHA_THRESHOLD: float = 0.08
const INVALID_FRAME_ANCHOR: Vector2 = Vector2(-1.0, -1.0)
const ANIM_ROWS: Dictionary = {
	"idle": 0,
	"cast": 2
}
const ANIM_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"cast": [0, 1, 2, 3, 4, 5, 6]
}
const ANIM_FPS: Dictionary = {
	"idle": 6.0,
	"cast": 12.0
}

var player: Player = null
var heal_timer_left: float = 0.0
var idle_anim_time: float = 0.0
var cast_anim_time: float = 0.0
var is_casting: bool = false
var heal_applied_this_cast: bool = false
var reacquire_left: float = 0.0
var tracked_player_health: float = -1.0
var sprite_base_position: Vector2 = Vector2.ZERO
var frame_pixel_size: Vector2 = Vector2.ZERO
var frame_anchor_points: Dictionary = {}
var alignment_anchor_point: Vector2 = Vector2.ZERO
var rng := RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	rng.randomize()
	heal_timer_left = _next_heal_interval() * 0.45
	reacquire_left = 0.0
	_acquire_player()
	_configure_sprite()
	if is_instance_valid(sprite):
		sprite_base_position = sprite.position
	_prepare_frame_alignment()
	_set_anim_frame("idle", 0)


func _exit_tree() -> void:
	_unbind_player_signal()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		reacquire_left = maxf(0.0, reacquire_left - delta)
		if reacquire_left <= 0.0:
			_acquire_player()
			reacquire_left = reacquire_retry_interval
	_update_facing()

	if is_casting:
		_tick_cast(delta)
		return

	_tick_idle(delta)
	heal_timer_left = maxf(0.0, heal_timer_left - delta)
	if heal_timer_left > 0.0:
		return

	if _player_needs_healing():
		_begin_cast()
	else:
		heal_timer_left = _next_heal_interval() * 0.4


func _acquire_player() -> void:
	_bind_player(get_tree().get_first_node_in_group("player") as Player)


func set_player(target_player: Player) -> void:
	_bind_player(target_player)
	if _player_needs_healing():
		heal_timer_left = minf(heal_timer_left, react_heal_delay)


func _bind_player(target_player: Player) -> void:
	if player == target_player and is_instance_valid(player):
		return
	_unbind_player_signal()
	player = target_player
	if not is_instance_valid(player):
		tracked_player_health = -1.0
		return
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	tracked_player_health = player.current_health
	_on_player_health_changed(player.current_health, player.max_health)


func _unbind_player_signal() -> void:
	if not is_instance_valid(player):
		return
	if player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.disconnect(_on_player_health_changed)


func _on_player_health_changed(current: float, maximum: float) -> void:
	var was_higher := tracked_player_health > current + 0.001
	tracked_player_health = current
	if maximum <= 0.0:
		return
	if current >= (maximum * heal_threshold_ratio):
		return
	if is_casting:
		return
	if emergency_cast_on_damage and was_higher:
		heal_timer_left = 0.0
		return
	if heal_timer_left > react_heal_delay or was_higher:
		heal_timer_left = minf(heal_timer_left, react_heal_delay)


func _configure_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = HEALER_SHEET
	sprite.hframes = HEALER_HFRAMES
	sprite.vframes = HEALER_VFRAMES


func _tick_idle(delta: float) -> void:
	var fps := float(ANIM_FPS.get("idle", 6.0))
	var frame_count := _anim_frame_count("idle")
	idle_anim_time += delta * fps
	var frame_index := int(floor(idle_anim_time)) % frame_count
	_set_anim_frame("idle", frame_index)


func _begin_cast() -> void:
	is_casting = true
	cast_anim_time = 0.0
	heal_applied_this_cast = false
	_set_anim_frame("cast", 0)
	_spawn_cast_flash(global_position + Vector2(0.0, -18.0))


func _tick_cast(delta: float) -> void:
	var fps := float(ANIM_FPS.get("cast", 12.0))
	var frame_count := _anim_frame_count("cast")
	cast_anim_time += delta * fps

	var frame_index := mini(int(floor(cast_anim_time)), frame_count - 1)
	_set_anim_frame("cast", frame_index)

	if not heal_applied_this_cast and frame_index >= cast_frame_to_heal:
		heal_applied_this_cast = true
		_apply_heal()

	if cast_anim_time < float(frame_count):
		return

	is_casting = false
	cast_anim_time = 0.0
	heal_timer_left = _next_heal_interval()
	_set_anim_frame("idle", 0)


func _player_needs_healing() -> bool:
	if not is_instance_valid(player):
		return false
	return player.needs_healing(heal_threshold_ratio)


func _apply_heal() -> void:
	if not is_instance_valid(player):
		return

	var player_target := player.global_position + Vector2(0.0, -16.0)
	var healed := player.receive_heal(heal_amount)
	_spawn_heal_beam(global_position + Vector2(0.0, -18.0), player_target, healed)
	_spawn_heal_burst(player_target, healed)


func _update_facing() -> void:
	if not is_instance_valid(sprite):
		return
	if not is_instance_valid(player):
		return
	sprite.flip_h = player.global_position.x < global_position.x


func _set_anim_frame(anim_name: String, frame_index: int) -> void:
	if not is_instance_valid(sprite):
		return
	var row := int(ANIM_ROWS.get(anim_name, 0))
	var anim_columns := _anim_columns(anim_name)
	if anim_columns.is_empty():
		return
	var clamped_frame := clampi(frame_index, 0, anim_columns.size() - 1)
	var source_column := int(anim_columns[clamped_frame])
	sprite.frame_coords = Vector2i(source_column, row)
	_apply_frame_alignment(row, source_column)


func _next_heal_interval() -> float:
	var interval := heal_interval + rng.randf_range(-heal_interval_variance, heal_interval_variance)
	return maxf(0.9, interval)


func _anim_columns(anim_name: String) -> Array:
	var values: Array = ANIM_FRAME_COLUMNS.get(anim_name, [])
	return values


func _anim_frame_count(anim_name: String) -> int:
	var values := _anim_columns(anim_name)
	return maxi(1, values.size())


func _prepare_frame_alignment() -> void:
	frame_anchor_points.clear()
	if HEALER_SHEET == null:
		return
	var image := HEALER_SHEET.get_image()
	if image == null:
		return

	var frame_w := image.get_width() / HEALER_HFRAMES
	var frame_h := image.get_height() / HEALER_VFRAMES
	frame_pixel_size = Vector2(frame_w, frame_h)

	var idle_row := int(ANIM_ROWS.get("idle", 0))
	var idle_columns := _anim_columns("idle")
	var idle_reference_col := int(idle_columns[0]) if not idle_columns.is_empty() else 0
	var reference_anchor := _extract_frame_foot_anchor(image, idle_row, idle_reference_col, frame_w, frame_h)
	if reference_anchor == INVALID_FRAME_ANCHOR:
		reference_anchor = Vector2(float(frame_w) * 0.5, float(frame_h - 1))
	alignment_anchor_point = reference_anchor

	for anim_name_variant in ANIM_ROWS.keys():
		var anim_name := String(anim_name_variant)
		var row := int(ANIM_ROWS.get(anim_name, 0))
		var columns := _anim_columns(anim_name)
		for source_col_variant in columns:
			var source_col := int(source_col_variant)
			var frame_anchor := _extract_frame_foot_anchor(image, row, source_col, frame_w, frame_h)
			if frame_anchor == INVALID_FRAME_ANCHOR:
				frame_anchor = alignment_anchor_point
			frame_anchor_points[_frame_key(row, source_col)] = frame_anchor


func _frame_key(row: int, col: int) -> int:
	return (row << 8) | col


func _extract_frame_foot_anchor(image: Image, row: int, col: int, frame_w: int, frame_h: int) -> Vector2:
	if frame_w <= 0 or frame_h <= 0:
		return INVALID_FRAME_ANCHOR
	var start_x := col * frame_w
	var start_y := row * frame_h
	if start_x < 0 or start_y < 0:
		return INVALID_FRAME_ANCHOR
	if start_x + frame_w > image.get_width():
		return INVALID_FRAME_ANCHOR
	if start_y + frame_h > image.get_height():
		return INVALID_FRAME_ANCHOR

	for local_y in range(frame_h - 1, -1, -1):
		var pixel_y := start_y + local_y
		var foot_x_sum := 0.0
		var foot_count := 0
		for local_x in range(frame_w):
			var pixel_x := start_x + local_x
			if image.get_pixel(pixel_x, pixel_y).a <= FRAME_ALPHA_THRESHOLD:
				continue
			foot_x_sum += float(local_x)
			foot_count += 1
		if foot_count > 0:
			return Vector2(foot_x_sum / float(foot_count), float(local_y))
	return INVALID_FRAME_ANCHOR


func _apply_frame_alignment(row: int, col: int) -> void:
	if not is_instance_valid(sprite):
		return
	if frame_anchor_points.is_empty():
		sprite.position = sprite_base_position
		return

	var frame_anchor: Vector2 = alignment_anchor_point
	var key := _frame_key(row, col)
	if frame_anchor_points.has(key):
		frame_anchor = frame_anchor_points[key]

	var aligned_foot_x := frame_anchor.x
	if sprite.flip_h:
		aligned_foot_x = (frame_pixel_size.x - 1.0) - aligned_foot_x
	var delta_pixels := Vector2(alignment_anchor_point.x - aligned_foot_x, alignment_anchor_point.y - frame_anchor.y)
	var sprite_scale := Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
	sprite.position = sprite_base_position + Vector2(delta_pixels.x * sprite_scale.x, delta_pixels.y * sprite_scale.y)


func _spawn_cast_flash(world_position: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var flash := Polygon2D.new()
	flash.top_level = true
	flash.global_position = world_position
	flash.z_index = 235
	flash.color = Color(0.54, 0.9, 1.0, 0.9)
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(5.0, 0.0),
		Vector2(0.0, 10.0),
		Vector2(-5.0, 0.0)
	])
	scene_root.add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector2(1.7, 1.7), heal_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, heal_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)


func _spawn_heal_beam(from_world: Vector2, to_world: Vector2, healed: bool) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var beam := Line2D.new()
	beam.top_level = true
	beam.global_position = Vector2.ZERO
	beam.z_index = 236
	beam.default_color = Color(0.44, 0.98, 0.62, 0.86) if healed else Color(0.62, 0.74, 0.8, 0.72)
	beam.width = 3.0
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam.points = PackedVector2Array([from_world, to_world])
	scene_root.add_child(beam)

	var tween := create_tween()
	tween.tween_property(beam, "width", 0.9, heal_effect_duration)
	tween.parallel().tween_property(beam, "modulate:a", 0.0, heal_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
	)


func _spawn_heal_burst(world_position: Vector2, healed: bool) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var burst := Node2D.new()
	burst.top_level = true
	burst.global_position = world_position
	burst.z_index = 237
	scene_root.add_child(burst)

	var ring := Line2D.new()
	ring.default_color = Color(0.42, 1.0, 0.56, 0.92) if healed else Color(0.54, 0.68, 0.78, 0.85)
	ring.width = 2.4
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = _build_ring_points(11.0, 16)
	burst.add_child(ring)

	var vertical := Line2D.new()
	vertical.default_color = ring.default_color.lightened(0.16)
	vertical.width = 2.2
	vertical.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vertical.end_cap_mode = Line2D.LINE_CAP_ROUND
	vertical.points = PackedVector2Array([Vector2(0.0, -5.0), Vector2(0.0, 5.0)])
	burst.add_child(vertical)

	var horizontal := Line2D.new()
	horizontal.default_color = ring.default_color.lightened(0.16)
	horizontal.width = 2.2
	horizontal.begin_cap_mode = Line2D.LINE_CAP_ROUND
	horizontal.end_cap_mode = Line2D.LINE_CAP_ROUND
	horizontal.points = PackedVector2Array([Vector2(-5.0, 0.0), Vector2(5.0, 0.0)])
	burst.add_child(horizontal)

	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2(1.65, 1.65), heal_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, heal_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


func _build_ring_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(maxi(3, segments)):
		var angle := (TAU * float(i)) / float(maxi(3, segments))
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points

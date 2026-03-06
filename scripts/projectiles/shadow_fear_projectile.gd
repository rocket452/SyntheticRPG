extends Node2D
class_name ShadowFearProjectile

const PROJECTILE_TEXTURE_PATH: String = "res://assets/external/DarkEffects/Dark VFX 1 (40x32).png"
const PROJECTILE_FRAME_SIZE: Vector2i = Vector2i(40, 32)
const PROJECTILE_FRAME_COUNT: int = 10
const PROJECTILE_TRAVEL_ROW: int = 0

static var projectile_texture_cache: Texture2D = null
static var projectile_frames_cache: SpriteFrames = null

@export var hit_radius: float = 18.0
@export var pulse_speed: float = 10.0
@export var launch_hold_duration: float = 0.05

var owner_rat: FriendlyRatfolk = null
var intended_target: EnemyBase = null
var travel_direction_x: float = 1.0
var move_speed: float = 340.0
var max_travel_distance: float = 420.0
var fear_duration: float = 5.0
var traveled_distance: float = 0.0
var visual_time: float = 0.0
var launch_hold_left: float = 0.0
var projectile_sprite_base_scale: Vector2 = Vector2.ONE
var projectile_sprite_base_modulate: Color = Color.WHITE
var projectile_glow_base_scale: Vector2 = Vector2.ONE
var projectile_glow_base_modulate: Color = Color.WHITE
var hitbox_debug_enabled: bool = false

@onready var trail: Line2D = $Trail
@onready var halo: Polygon2D = $Halo
@onready var core: Polygon2D = $Core
@onready var projectile_sprite: AnimatedSprite2D = get_node_or_null("ProjectileSprite") as AnimatedSprite2D
@onready var projectile_glow: AnimatedSprite2D = get_node_or_null("ProjectileGlow") as AnimatedSprite2D


func setup(source_rat: FriendlyRatfolk, start_position: Vector2, direction_sign: float, speed: float, max_distance: float, duration: float, target_enemy: EnemyBase = null) -> void:
	owner_rat = source_rat
	intended_target = target_enemy
	global_position = start_position
	travel_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	move_speed = maxf(1.0, speed)
	max_travel_distance = maxf(24.0, max_distance)
	fear_duration = maxf(0.1, duration)
	launch_hold_left = maxf(0.0, launch_hold_duration)
	if is_inside_tree():
		_refresh_visual_orientation()


func _ready() -> void:
	add_to_group("shadow_fear_projectiles")
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	var projectile_frames := _get_projectile_frames()
	if projectile_sprite != null:
		if projectile_sprite.sprite_frames == null:
			projectile_sprite.sprite_frames = projectile_frames
		if projectile_sprite.sprite_frames != null and projectile_sprite.sprite_frames.has_animation("fly"):
			projectile_sprite.animation = "fly"
			projectile_sprite.play("fly")
		projectile_sprite_base_scale = Vector2(absf(projectile_sprite.scale.x), absf(projectile_sprite.scale.y))
		projectile_sprite_base_modulate = projectile_sprite.modulate
	if projectile_glow != null:
		if projectile_glow.sprite_frames == null:
			projectile_glow.sprite_frames = projectile_frames
		if projectile_glow.sprite_frames != null and projectile_glow.sprite_frames.has_animation("fly"):
			projectile_glow.animation = "fly"
			projectile_glow.play("fly")
		projectile_glow_base_scale = Vector2(absf(projectile_glow.scale.x), absf(projectile_glow.scale.y))
		projectile_glow_base_modulate = projectile_glow.modulate
	_refresh_visual_orientation()


func _physics_process(delta: float) -> void:
	if hitbox_debug_enabled:
		queue_redraw()
	if launch_hold_left > 0.0:
		launch_hold_left = maxf(0.0, launch_hold_left - maxf(0.0, delta))
		_update_visuals(delta)
		return
	var previous_position := global_position
	var step := maxf(0.0, move_speed) * maxf(0.0, delta)
	global_position.x += travel_direction_x * step
	traveled_distance += step
	_update_visuals(delta)
	if _try_hit_enemy(previous_position, global_position):
		queue_free()
		return
	if traveled_distance >= max_travel_distance:
		queue_free()


func set_hitbox_debug_enabled(enabled: bool) -> void:
	var next_enabled := bool(enabled)
	if hitbox_debug_enabled == next_enabled:
		return
	hitbox_debug_enabled = next_enabled
	queue_redraw()


func _draw() -> void:
	if not hitbox_debug_enabled:
		return
	var radius := maxf(6.0, hit_radius)
	draw_circle(Vector2.ZERO, radius, Color(0.62, 0.4, 1.0, 0.15))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.78, 0.54, 1.0, 0.96), 2.0, true)


func _refresh_visual_orientation() -> void:
	var facing_sign := 1.0 if travel_direction_x >= 0.0 else -1.0
	if trail != null:
		trail.scale.x = facing_sign
	if halo != null:
		halo.scale.x = facing_sign
	if core != null:
		core.scale.x = facing_sign
	if projectile_sprite != null:
		projectile_sprite.scale = Vector2(projectile_sprite_base_scale.x * facing_sign, projectile_sprite_base_scale.y)
	if projectile_glow != null:
		projectile_glow.scale = Vector2(projectile_glow_base_scale.x * facing_sign, projectile_glow_base_scale.y)


func _update_visuals(delta: float) -> void:
	visual_time += maxf(0.0, delta)
	var pulse := 0.5 + (sin(visual_time * pulse_speed) * 0.5)
	var facing_sign := 1.0 if travel_direction_x >= 0.0 else -1.0
	if trail != null:
		trail.default_color.a = lerpf(0.42, 0.82, pulse)
	if halo != null:
		halo.position.y = sin(visual_time * 7.0) * 1.6
		halo.scale = Vector2(lerpf(0.92, 1.08, pulse), lerpf(0.9, 1.14, pulse))
		halo.color.a = lerpf(0.24, 0.52, pulse)
	if core != null:
		core.position.y = cos(visual_time * 8.6) * 1.2
		core.scale = Vector2.ONE * lerpf(0.92, 1.1, 1.0 - pulse)
		core.color.a = lerpf(0.58, 0.9, 1.0 - pulse)
	if projectile_sprite != null:
		projectile_sprite.scale = Vector2(projectile_sprite_base_scale.x * facing_sign, projectile_sprite_base_scale.y)
		projectile_sprite.modulate = projectile_sprite_base_modulate
	if projectile_glow != null:
		projectile_glow.scale = Vector2(projectile_glow_base_scale.x * facing_sign, projectile_glow_base_scale.y)
		projectile_glow.modulate = projectile_glow_base_modulate


func _try_hit_enemy(segment_start: Vector2, segment_end: Vector2) -> bool:
	if intended_target != null and is_instance_valid(intended_target) and not intended_target.dead:
		return _try_hit_specific_enemy(intended_target, segment_start, segment_end)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _try_hit_specific_enemy(enemy, segment_start, segment_end):
			return true
	return false


func _try_hit_specific_enemy(enemy: EnemyBase, segment_start: Vector2, segment_end: Vector2) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return false
	var target_point := enemy.global_position + Vector2(0.0, -12.0)
	var collision_radius := maxf(8.0, hit_radius)
	if not _segment_hits_target(segment_start, segment_end, target_point, collision_radius):
		var is_locked_target := intended_target != null and enemy == intended_target
		var crossed_target_x := false
		if travel_direction_x >= 0.0:
			crossed_target_x = segment_start.x <= target_point.x and segment_end.x >= target_point.x
		else:
			crossed_target_x = segment_start.x >= target_point.x and segment_end.x <= target_point.x
		var close_enough := global_position.distance_squared_to(target_point) <= pow(maxf(collision_radius * 2.2, 42.0), 2.0)
		if not is_locked_target or (not crossed_target_x and not close_enough):
			return false
	var applied := false
	if enemy.has_method("apply_shadow_fear"):
		applied = bool(enemy.call("apply_shadow_fear", fear_duration))
	print("[SHADOW_FEAR] HIT target=%s applied=%s" % [enemy.name, str(applied)])
	return true


func _segment_hits_target(segment_start: Vector2, segment_end: Vector2, target: Vector2, radius: float) -> bool:
	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return segment_start.distance_squared_to(target) <= radius * radius
	var travel_t := clampf((target - segment_start).dot(segment) / segment_length_sq, 0.0, 1.0)
	var nearest_point := segment_start + (segment * travel_t)
	return nearest_point.distance_squared_to(target) <= radius * radius


func _get_projectile_frames() -> SpriteFrames:
	if projectile_frames_cache != null:
		return projectile_frames_cache
	var sheet_texture := _get_projectile_texture()
	if sheet_texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", 18.0)
	frames.set_animation_loop("fly", true)
	var frame_width := maxi(1, PROJECTILE_FRAME_SIZE.x)
	var frame_height := maxi(1, PROJECTILE_FRAME_SIZE.y)
	var frame_row_y := maxi(0, PROJECTILE_TRAVEL_ROW) * frame_height
	for frame_index in range(PROJECTILE_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_texture
		atlas.region = Rect2i(frame_index * frame_width, frame_row_y, frame_width, frame_height)
		frames.add_frame("fly", atlas)
	projectile_frames_cache = frames
	return projectile_frames_cache


func _get_projectile_texture() -> Texture2D:
	if projectile_texture_cache != null:
		return projectile_texture_cache
	var image := Image.load_from_file(ProjectSettings.globalize_path(PROJECTILE_TEXTURE_PATH))
	if image == null or image.is_empty():
		return null
	projectile_texture_cache = ImageTexture.create_from_image(image)
	return projectile_texture_cache

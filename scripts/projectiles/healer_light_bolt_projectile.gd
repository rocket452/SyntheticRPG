extends Node2D
class_name HealerLightBoltProjectile

const START_ANIM: StringName = &"start"
const FLY_ANIM: StringName = &"fly"
const IMPACT_ANIM: StringName = &"impact"
const START_FRAME_PATHS: Array[String] = [
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Initial1.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Initial2.png"
]
const FLY_FRAME_PATHS: Array[String] = [
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable1.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable2.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable3.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable4.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable5.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable6.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable7.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Repeatable8.png"
]
const IMPACT_FRAME_PATHS: Array[String] = [
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact1.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact2.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact3.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact4.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact5.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact6.png",
	"res://assets/external/Holy VFX 01/Separated Frames/Holy VFX 01 Impact7.png"
]

static var _cached_texture_by_path: Dictionary = {}
static var _cached_sprite_frames: SpriteFrames = null

@export var default_speed: float = 520.0
@export var default_max_distance: float = 208.0
@export var default_hit_radius: float = 12.0
@export var default_max_lifetime: float = 1.2
@export var visual_scale: Vector2 = Vector2(2.35, 2.35)
@export var visual_size_multiplier: float = 0.5
@export var impact_scale_multiplier: float = 1.24
@export var glow_scale_multiplier: float = 1.5
@export var trail_length: float = 26.0
@export var trail_width: float = 3.4

var owner_actor: Node2D = null
var locked_target: EnemyBase = null
var travel_direction_x: float = 1.0
var move_speed: float = 520.0
var max_distance: float = 208.0
var hit_radius: float = 12.0
var max_lifetime: float = 1.2
var damage_amount: float = 7.5
var stun_on_hit: float = 0.1
var knockback_scale: float = 0.88
var hitstop_on_hit: float = 0.045
var traveled_distance: float = 0.0
var alive_time: float = 0.0
var visual_time: float = 0.0
var hitbox_debug_enabled: bool = false
var lane_min_x: float = -INF
var lane_max_x: float = INF
var lane_bounds_enabled: bool = false
var impact_started: bool = false
var projectile_sprite: AnimatedSprite2D = null
var glow_sprite: AnimatedSprite2D = null
var projectile_trail: Line2D = null
var projectile_core: Polygon2D = null
var projectile_core_glow: Polygon2D = null


func setup(
	source_actor: Node2D,
	start_position: Vector2,
	direction_sign: float,
	speed: float,
	distance: float,
	damage: float,
	stun_duration: float,
	knockback: float,
	hitstop: float,
	projectile_hit_radius: float,
	lifetime: float,
	arena_min_x: float = -INF,
	arena_max_x: float = INF,
	target_enemy: EnemyBase = null
) -> void:
	owner_actor = source_actor
	locked_target = target_enemy
	global_position = start_position
	impact_started = false
	travel_direction_x = -1.0 if direction_sign < 0.0 else 1.0
	move_speed = maxf(1.0, speed)
	max_distance = maxf(24.0, distance)
	damage_amount = maxf(0.1, damage)
	stun_on_hit = maxf(0.0, stun_duration)
	knockback_scale = maxf(0.1, knockback)
	hitstop_on_hit = maxf(0.0, hitstop)
	hit_radius = maxf(6.0, projectile_hit_radius)
	max_lifetime = maxf(0.1, lifetime)
	lane_min_x = arena_min_x
	lane_max_x = arena_max_x
	lane_bounds_enabled = lane_min_x < lane_max_x
	if is_inside_tree():
		_refresh_visual_orientation()


func _ready() -> void:
	top_level = true
	z_index = 242
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	_create_trail_node()
	_create_visual_nodes()
	_refresh_visual_orientation()
	_play_start_or_fly_animation()


func _physics_process(delta: float) -> void:
	if hitbox_debug_enabled:
		queue_redraw()
	if impact_started:
		return
	var safe_delta := maxf(0.0, delta)
	alive_time += safe_delta
	if alive_time >= max_lifetime:
		queue_free()
		return
	var previous_position := global_position
	var step_x := travel_direction_x * move_speed * safe_delta
	var segment_end := global_position + Vector2(step_x, 0.0)
	var reached_edge := false
	if lane_bounds_enabled:
		if travel_direction_x > 0.0 and segment_end.x >= lane_max_x:
			segment_end.x = lane_max_x
			reached_edge = true
		elif travel_direction_x < 0.0 and segment_end.x <= lane_min_x:
			segment_end.x = lane_min_x
			reached_edge = true
	traveled_distance += previous_position.distance_to(segment_end)
	_update_visual_pulse(safe_delta)
	if _try_hit_enemy(previous_position, segment_end):
		return
	global_position = segment_end
	if reached_edge:
		_begin_impact(global_position)
		return
	if not lane_bounds_enabled and traveled_distance >= max_distance:
		_begin_impact(global_position)


func set_hitbox_debug_enabled(enabled: bool) -> void:
	var next_enabled := bool(enabled)
	if hitbox_debug_enabled == next_enabled:
		return
	hitbox_debug_enabled = next_enabled
	queue_redraw()


func _draw() -> void:
	if not hitbox_debug_enabled:
		return
	draw_circle(Vector2.ZERO, hit_radius, Color(0.46, 0.9, 1.0, 0.16))
	draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 24, Color(0.56, 0.96, 1.0, 0.98), 2.0, true)


func _create_visual_nodes() -> void:
	if projectile_sprite != null and is_instance_valid(projectile_sprite):
		return
	var frames := _get_projectile_sprite_frames()
	var sprite := AnimatedSprite2D.new()
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = Color(1.0, 0.98, 0.88, 0.98)
	if frames != null:
		sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_projectile_animation_finished)
	add_child(sprite)
	projectile_sprite = sprite
	var glow := AnimatedSprite2D.new()
	glow.centered = true
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.modulate = Color(1.0, 0.9, 0.5, 0.58)
	if frames != null:
		glow.sprite_frames = frames
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = glow_material
	add_child(glow)
	glow_sprite = glow
	_create_core_visuals()
	_update_visual_pulse(0.0)


func _refresh_visual_orientation() -> void:
	var facing_left := travel_direction_x < 0.0
	if projectile_sprite != null and is_instance_valid(projectile_sprite):
		projectile_sprite.flip_h = facing_left
	if glow_sprite != null and is_instance_valid(glow_sprite):
		glow_sprite.flip_h = facing_left
	if projectile_core != null and is_instance_valid(projectile_core):
		projectile_core.scale.x = -1.0 if facing_left else 1.0
	if projectile_core_glow != null and is_instance_valid(projectile_core_glow):
		projectile_core_glow.scale.x = -1.0 if facing_left else 1.0
	if projectile_trail != null and is_instance_valid(projectile_trail):
		var size_multiplier := maxf(0.05, visual_size_multiplier)
		var resolved_length := maxf(8.0, trail_length * size_multiplier)
		projectile_trail.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(-travel_direction_x * resolved_length, 0.0)
		])


func _update_visual_pulse(delta: float) -> void:
	visual_time += delta
	var pulse := 0.5 + (sin(visual_time * 16.0) * 0.5)
	var size_multiplier := maxf(0.05, visual_size_multiplier)
	var base_scale := Vector2(absf(visual_scale.x), absf(visual_scale.y)) * size_multiplier
	if impact_started:
		base_scale *= maxf(1.0, impact_scale_multiplier)
	var pulse_scale := lerpf(0.96, 1.18, pulse)
	if projectile_sprite != null and is_instance_valid(projectile_sprite):
		projectile_sprite.scale = base_scale * pulse_scale
		projectile_sprite.modulate.a = lerpf(0.94, 1.0, pulse)
	if glow_sprite != null and is_instance_valid(glow_sprite):
		glow_sprite.scale = (base_scale * maxf(1.08, glow_scale_multiplier)) * lerpf(1.02, 1.22, pulse)
		glow_sprite.modulate.a = lerpf(0.32, 0.54, pulse)
	if projectile_core != null and is_instance_valid(projectile_core):
		projectile_core.scale = Vector2(( -1.0 if travel_direction_x < 0.0 else 1.0) * lerpf(1.08, 1.3, pulse), lerpf(1.02, 1.18, pulse))
		projectile_core.scale *= size_multiplier
		projectile_core.modulate.a = lerpf(0.88, 0.98, pulse)
	if projectile_core_glow != null and is_instance_valid(projectile_core_glow):
		projectile_core_glow.scale = Vector2(( -1.0 if travel_direction_x < 0.0 else 1.0) * lerpf(1.22, 1.42, pulse), lerpf(1.12, 1.32, pulse))
		projectile_core_glow.scale *= size_multiplier
		projectile_core_glow.modulate.a = lerpf(0.28, 0.46, pulse)
	if projectile_trail != null and is_instance_valid(projectile_trail):
		projectile_trail.width = maxf(1.0, trail_width * size_multiplier) * lerpf(0.92, 1.18, pulse)
		projectile_trail.default_color = Color(1.0, 0.9, 0.54, lerpf(0.22, 0.42, pulse))


func _try_hit_enemy(segment_start: Vector2, segment_end: Vector2) -> bool:
	if impact_started:
		return false
	if locked_target != null and is_instance_valid(locked_target) and not locked_target.dead:
		if _try_hit_specific_enemy(locked_target, segment_start, segment_end):
			return true
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
	var target_center := _get_enemy_target_point(enemy)
	var target_radius := _get_enemy_collision_radius(enemy)
	var hit_distance := hit_radius + target_radius
	if not _segment_hits_target(segment_start, segment_end, target_center, hit_distance):
		return false
	if not enemy.has_method("receive_hit"):
		return false
	var hit_world_position := _project_point_to_segment(target_center, segment_start, segment_end)
	var source_position := global_position
	if owner_actor != null and is_instance_valid(owner_actor):
		source_position = owner_actor.global_position
	var health_before := _get_enemy_health(enemy)
	var landed := bool(enemy.call("receive_hit", damage_amount, source_position, stun_on_hit, true, knockback_scale, owner_actor if owner_actor != null else self))
	if not landed:
		return false
	if enemy.has_method("apply_hitstop"):
		enemy.call("apply_hitstop", hitstop_on_hit)
	var health_after := _get_enemy_health(enemy)
	var damage_dealt := maxf(0.0, health_before - health_after)
	_begin_impact(hit_world_position)
	if owner_actor != null and is_instance_valid(owner_actor) and owner_actor.has_method("_on_healer_light_bolt_projectile_hit"):
		owner_actor.call("_on_healer_light_bolt_projectile_hit", enemy, damage_dealt, hit_world_position)
	return true


func _segment_hits_target(segment_start: Vector2, segment_end: Vector2, target: Vector2, radius: float) -> bool:
	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return segment_start.distance_squared_to(target) <= radius * radius
	var t := clampf((target - segment_start).dot(segment) / segment_length_sq, 0.0, 1.0)
	var closest := segment_start + (segment * t)
	return closest.distance_squared_to(target) <= radius * radius


func _project_point_to_segment(target: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return segment_start
	var t := clampf((target - segment_start).dot(segment) / segment_length_sq, 0.0, 1.0)
	return segment_start + (segment * t)


func _play_start_or_fly_animation() -> void:
	if projectile_sprite == null or not is_instance_valid(projectile_sprite):
		return
	var frames := projectile_sprite.sprite_frames
	if frames == null:
		return
	if frames.has_animation(START_ANIM) and frames.get_frame_count(START_ANIM) > 0:
		projectile_sprite.play(START_ANIM)
		if glow_sprite != null and is_instance_valid(glow_sprite):
			glow_sprite.play(START_ANIM)
		return
	if frames.has_animation(FLY_ANIM) and frames.get_frame_count(FLY_ANIM) > 0:
		projectile_sprite.play(FLY_ANIM)
		if glow_sprite != null and is_instance_valid(glow_sprite):
			glow_sprite.play(FLY_ANIM)


func _begin_impact(world_position: Vector2) -> void:
	if impact_started:
		return
	impact_started = true
	global_position = world_position
	if projectile_sprite == null or not is_instance_valid(projectile_sprite):
		queue_free()
		return
	var frames := projectile_sprite.sprite_frames
	if frames == null or not frames.has_animation(IMPACT_ANIM) or frames.get_frame_count(IMPACT_ANIM) <= 0:
		queue_free()
		return
	projectile_sprite.play(IMPACT_ANIM)
	if glow_sprite != null and is_instance_valid(glow_sprite):
		glow_sprite.play(IMPACT_ANIM)
	if projectile_core != null and is_instance_valid(projectile_core):
		projectile_core.visible = false
	if projectile_core_glow != null and is_instance_valid(projectile_core_glow):
		projectile_core_glow.visible = false
	if projectile_trail != null and is_instance_valid(projectile_trail):
		projectile_trail.visible = false


func _on_projectile_animation_finished() -> void:
	if projectile_sprite == null or not is_instance_valid(projectile_sprite):
		queue_free()
		return
	if projectile_sprite.animation == START_ANIM:
		var frames := projectile_sprite.sprite_frames
		if frames != null and frames.has_animation(FLY_ANIM) and frames.get_frame_count(FLY_ANIM) > 0:
			projectile_sprite.play(FLY_ANIM)
			if glow_sprite != null and is_instance_valid(glow_sprite):
				glow_sprite.play(FLY_ANIM)
		return
	if projectile_sprite.animation == IMPACT_ANIM:
		queue_free()


static func _get_projectile_sprite_frames() -> SpriteFrames:
	if _cached_sprite_frames != null:
		return _cached_sprite_frames
	var frames := SpriteFrames.new()
	frames.add_animation(START_ANIM)
	frames.set_animation_speed(START_ANIM, 20.0)
	frames.set_animation_loop(START_ANIM, false)
	for frame_path in START_FRAME_PATHS:
		var texture := _load_texture(frame_path)
		if texture != null:
			frames.add_frame(START_ANIM, texture)
	frames.add_animation(FLY_ANIM)
	frames.set_animation_speed(FLY_ANIM, 19.0)
	frames.set_animation_loop(FLY_ANIM, true)
	for frame_path in FLY_FRAME_PATHS:
		var texture := _load_texture(frame_path)
		if texture != null:
			frames.add_frame(FLY_ANIM, texture)
	frames.add_animation(IMPACT_ANIM)
	frames.set_animation_speed(IMPACT_ANIM, 20.0)
	frames.set_animation_loop(IMPACT_ANIM, false)
	for frame_path in IMPACT_FRAME_PATHS:
		var texture := _load_texture(frame_path)
		if texture != null:
			frames.add_frame(IMPACT_ANIM, texture)
	_cached_sprite_frames = frames
	return _cached_sprite_frames


static func _load_texture(resource_path: String) -> Texture2D:
	if _cached_texture_by_path.has(resource_path):
		return _cached_texture_by_path.get(resource_path) as Texture2D
	var texture := load(resource_path) as Texture2D
	if texture == null:
		var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
		if image == null or image.is_empty():
			return null
		texture = ImageTexture.create_from_image(image)
	_cached_texture_by_path[resource_path] = texture
	return texture


func _create_trail_node() -> void:
	if projectile_trail != null and is_instance_valid(projectile_trail):
		return
	var trail := Line2D.new()
	trail.width = maxf(1.0, trail_width)
	trail.default_color = Color(1.0, 0.9, 0.56, 0.32)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.antialiased = true
	add_child(trail)
	projectile_trail = trail


func _create_core_visuals() -> void:
	if projectile_core != null and is_instance_valid(projectile_core):
		return
	var core_glow := Polygon2D.new()
	core_glow.color = Color(1.0, 0.86, 0.42, 0.34)
	core_glow.polygon = PackedVector2Array([
		Vector2(22.0, 0.0),
		Vector2(8.0, -8.0),
		Vector2(-10.0, -6.0),
		Vector2(-18.0, 0.0),
		Vector2(-10.0, 6.0),
		Vector2(8.0, 8.0)
	])
	var core_glow_material := CanvasItemMaterial.new()
	core_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	core_glow.material = core_glow_material
	add_child(core_glow)
	projectile_core_glow = core_glow

	var core := Polygon2D.new()
	core.color = Color(1.0, 0.96, 0.72, 0.96)
	core.polygon = PackedVector2Array([
		Vector2(16.0, 0.0),
		Vector2(4.0, -4.0),
		Vector2(-10.0, -2.2),
		Vector2(-14.0, 0.0),
		Vector2(-10.0, 2.2),
		Vector2(4.0, 4.0)
	])
	add_child(core)
	projectile_core = core


func _get_enemy_target_point(enemy: EnemyBase) -> Vector2:
	return enemy.global_position + Vector2(0.0, -12.0)


func _get_enemy_collision_radius(enemy: EnemyBase) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 12.0
	if enemy.collision_shape == null or enemy.collision_shape.shape == null:
		return 12.0
	var shape := enemy.collision_shape.shape
	if shape is CircleShape2D:
		return maxf(6.0, (shape as CircleShape2D).radius)
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return maxf(6.0, capsule.radius + (capsule.height * 0.25))
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		return maxf(6.0, maxf(rectangle.size.x, rectangle.size.y) * 0.5)
	return 12.0


func _get_enemy_health(enemy: EnemyBase) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	return clampf(enemy.current_health, 0.0, maxf(1.0, enemy.max_health))

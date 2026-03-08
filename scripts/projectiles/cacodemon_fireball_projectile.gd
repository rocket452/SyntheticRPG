extends Node2D
class_name CacodemonFireballProjectile

const TRAVEL_FRAME_PATHS: Array[String] = [
	"res://assets/external/fireball/FB500-1.png",
	"res://assets/external/fireball/FB500-2.png",
	"res://assets/external/fireball/FB500-3.png",
	"res://assets/external/fireball/FB500-4.png",
	"res://assets/external/fireball/FB500-5.png"
]
const IMPACT_FRAME_PATHS: Array[String] = [
	"res://assets/external/fireball/B500-2.PNG",
	"res://assets/external/fireball/B500-3.PNG",
	"res://assets/external/fireball/B500-4.PNG"
]
const TRAVEL_ANIM: StringName = &"travel"
const IMPACT_ANIM: StringName = &"impact"
const IMPACT_LOCAL_AWAY_DIR: Vector2 = Vector2.LEFT

static var _cached_texture_by_path: Dictionary = {}
static var _cached_texture_vflip_by_path: Dictionary = {}
static var _cached_travel_frames: SpriteFrames = null
static var _cached_impact_frames: SpriteFrames = null

@export var visual_scale: Vector2 = Vector2(0.17, 0.17)
@export var impact_scale_multiplier: float = 1.32
@export var collision_radius: float = 16.0
@export var blocked_stamina_cost: float = 7.0
@export var visual_hit_radius_scale: float = 0.30
@export var player_hit_radius_scale: float = 1.0
@export var impact_outward_offset: float = 10.0

var source_enemy: Node2D = null
var target_actor: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var stun_duration: float = 0.08
var knockback_scale: float = 0.35
var remaining_distance: float = 0.0
var impact_finished: bool = false
var live_collision_radius: float = 16.0
var hitbox_debug_enabled: bool = false

var fireball_sprite: AnimatedSprite2D = null


func configure(
	source_enemy_node: Node2D,
	primary_target: Node2D,
	spawn_position: Vector2,
	direction: Vector2,
	speed: float,
	max_distance: float,
	hit_damage: float,
	hit_stun: float,
	hit_knockback: float
) -> void:
	source_enemy = source_enemy_node
	target_actor = primary_target
	global_position = spawn_position
	var normalized_direction := direction.normalized()
	if normalized_direction.length_squared() <= 0.0001:
		normalized_direction = Vector2.RIGHT
	velocity = normalized_direction * maxf(0.0, speed)
	remaining_distance = maxf(8.0, max_distance)
	damage = maxf(0.0, hit_damage)
	stun_duration = maxf(0.0, hit_stun)
	knockback_scale = maxf(0.1, hit_knockback)
	top_level = true
	z_index = 244


func _ready() -> void:
	add_to_group("cacodemon_fireballs")
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	_ensure_sprite()
	if fireball_sprite == null:
		queue_free()
		return
	fireball_sprite.sprite_frames = _get_fireball_frames()
	fireball_sprite.play(TRAVEL_ANIM)
	fireball_sprite.scale = Vector2(absf(visual_scale.x), absf(visual_scale.y))
	fireball_sprite.flip_v = false
	fireball_sprite.rotation = 0.0
	_refresh_live_collision_radius()
	if absf(velocity.x) > 0.01:
		fireball_sprite.flip_h = velocity.x < 0.0


func _process(delta: float) -> void:
	if hitbox_debug_enabled:
		queue_redraw()
	if impact_finished:
		return
	if fireball_sprite == null or not is_instance_valid(fireball_sprite):
		queue_free()
		return
	if fireball_sprite.animation == IMPACT_ANIM:
		return
	var move_delta := velocity * maxf(0.0, delta)
	var next_position := global_position + move_delta
	if _try_block_on_player(global_position, next_position):
		return
	if _try_hit_friendly_target(next_position):
		return
	global_position = next_position
	remaining_distance = maxf(0.0, remaining_distance - move_delta.length())
	if remaining_distance <= 0.0:
		_begin_impact(global_position, -_get_travel_direction())


func set_hitbox_debug_enabled(enabled: bool) -> void:
	var next_enabled := bool(enabled)
	if hitbox_debug_enabled == next_enabled:
		return
	hitbox_debug_enabled = next_enabled
	queue_redraw()


func _draw() -> void:
	if not hitbox_debug_enabled:
		return
	var radius := live_collision_radius
	if fireball_sprite != null and is_instance_valid(fireball_sprite) and fireball_sprite.animation == IMPACT_ANIM:
		radius = maxf(8.0, radius * maxf(1.0, impact_scale_multiplier))
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.26, 0.18, 0.16))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 30, Color(1.0, 0.44, 0.32, 0.96), 2.0, true)


func _ensure_sprite() -> void:
	if fireball_sprite != null and is_instance_valid(fireball_sprite):
		return
	var sprite := AnimatedSprite2D.new()
	sprite.centered = true
	add_child(sprite)
	fireball_sprite = sprite


func _try_block_on_player(world_start: Vector2, world_end: Vector2) -> bool:
	var block_player := _get_live_tank_player()
	if block_player == null:
		return false
	var shield_active := block_player.is_blocking
	if block_player.has_method("is_block_shield_active"):
		shield_active = bool(block_player.call("is_block_shield_active"))
	if not shield_active:
		return false
	if block_player.has_method("is_segment_intersecting_block_shield") and bool(block_player.call("is_segment_intersecting_block_shield", world_start, world_end, live_collision_radius)):
		if block_player.has_method("drain_block_stamina"):
			block_player.call("drain_block_stamina", blocked_stamina_cost)
		var impact_position := block_player.global_position
		if block_player.has_method("get_block_shield_center_global"):
			var center_variant: Variant = block_player.call("get_block_shield_center_global")
			if center_variant is Vector2:
				impact_position = center_variant
		var player_center := _get_player_collision_center(block_player)
		var away_direction := impact_position - player_center
		if away_direction.length_squared() <= 0.0001:
			away_direction = -_get_travel_direction()
		_begin_impact(impact_position, away_direction)
		return true
	return false


func _try_hit_friendly_target(next_position: Vector2) -> bool:
	var projectile_radius := maxf(6.0, live_collision_radius)
	var hit_direction := velocity.normalized()
	if hit_direction.length_squared() <= 0.0001:
		hit_direction = Vector2.RIGHT
	var nearest_target: Node2D = null
	var nearest_progress := INF
	var nearest_center := Vector2.ZERO
	var nearest_radius := 0.0
	var segment := next_position - global_position
	var segment_len_sq := segment.length_squared()
	for candidate in _get_friendly_hit_candidates():
		var target_center := _get_target_collision_center(candidate)
		var target_radius := _get_target_collision_radius(candidate)
		var total_radius := projectile_radius + target_radius
		var progress := 0.0
		if segment_len_sq > 0.0001:
			progress = clampf((target_center - global_position).dot(segment) / segment_len_sq, 0.0, 1.0)
		var closest := global_position + (segment * progress)
		if target_center.distance_to(closest) > total_radius:
			continue
		if nearest_target == null or progress < nearest_progress:
			nearest_target = candidate
			nearest_progress = progress
			nearest_center = target_center
			nearest_radius = target_radius
	if nearest_target == null:
		return false
	var impact_position := nearest_center - (hit_direction * nearest_radius)
	global_position = impact_position
	if nearest_target.has_method("receive_hit"):
		var source_position := source_enemy.global_position if source_enemy != null and is_instance_valid(source_enemy) else global_position
		nearest_target.call("receive_hit", damage, source_position, false, stun_duration, knockback_scale)
	var away_direction := impact_position - nearest_center
	if away_direction.length_squared() <= 0.0001:
		away_direction = -hit_direction
	_begin_impact(global_position, away_direction)
	return true


func _get_live_tank_player() -> Player:
	var tank := get_tree().get_first_node_in_group("player") as Player
	if tank == null or not is_instance_valid(tank) or tank.is_dead:
		return null
	return tank


func _get_friendly_hit_candidates() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	var seen_ids: Dictionary = {}
	var tank := _get_live_tank_player()
	if _is_valid_hit_target(tank):
		var tank_id := tank.get_instance_id()
		seen_ids[tank_id] = true
		targets.append(tank)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate.is_in_group("shadow_clones"):
			continue
		if candidate.has_method("is_shadow_clone_actor") and bool(candidate.call("is_shadow_clone_actor")):
			continue
		if not _is_valid_hit_target(candidate):
			continue
		var candidate_id := candidate.get_instance_id()
		if seen_ids.has(candidate_id):
			continue
		seen_ids[candidate_id] = true
		targets.append(candidate)
	if _is_valid_hit_target(target_actor):
		var target_id := target_actor.get_instance_id()
		if not seen_ids.has(target_id):
			targets.append(target_actor)
	return targets


func _is_valid_hit_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("receive_hit"):
		return false
	var target_player := target as Player
	if target_player != null:
		return not target_player.is_dead
	var target_healer := target as FriendlyHealer
	if target_healer != null:
		return not target_healer.dead
	var target_rat := target as FriendlyRatfolk
	if target_rat != null:
		return not target_rat.dead
	return true


func _get_target_collision_radius(target: Node2D) -> float:
	var target_player := target as Player
	if target_player != null:
		return _get_player_collision_radius(target_player)
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return 12.0
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return 12.0
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	return maxf(4.0, circle.radius * maxf(0.01, radius_scale))


func _get_target_collision_center(target: Node2D) -> Vector2:
	var target_player := target as Player
	if target_player != null:
		return _get_player_collision_center(target_player)
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and is_instance_valid(collision_shape):
		return collision_shape.global_position
	return target.global_position


func _begin_impact(world_position: Vector2, away_direction: Vector2 = Vector2.ZERO) -> void:
	var away := away_direction
	if away.length_squared() <= 0.0001:
		away = -_get_travel_direction()
	if away.length_squared() <= 0.0001:
		away = Vector2.RIGHT
	away = away.normalized()
	global_position = world_position + (away * maxf(0.0, impact_outward_offset))
	velocity = Vector2.ZERO
	fireball_sprite.sprite_frames = _get_impact_frames()
	var impact_scale := visual_scale * maxf(1.0, impact_scale_multiplier)
	fireball_sprite.scale = Vector2(absf(impact_scale.x), absf(impact_scale.y))
	var away_horizontal := Vector2(signf(away.x), 0.0)
	if absf(away_horizontal.x) <= 0.0001:
		away_horizontal = Vector2.RIGHT
	# Orient the impact using the art-authored "away" axis instead of relying on flip quirks.
	fireball_sprite.flip_h = false
	fireball_sprite.flip_v = false
	fireball_sprite.rotation = away_horizontal.angle() - IMPACT_LOCAL_AWAY_DIR.angle()
	fireball_sprite.play(IMPACT_ANIM)
	fireball_sprite.animation_finished.connect(_on_impact_finished, CONNECT_ONE_SHOT)


func _get_travel_direction() -> Vector2:
	var direction := velocity.normalized()
	if direction.length_squared() <= 0.0001 and source_enemy != null and is_instance_valid(source_enemy):
		direction = (global_position - source_enemy.global_position).normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	return direction


func _refresh_live_collision_radius() -> void:
	var computed_radius := collision_radius
	if fireball_sprite == null or not is_instance_valid(fireball_sprite) or fireball_sprite.sprite_frames == null:
		live_collision_radius = maxf(6.0, computed_radius)
		return
	var frame_texture := fireball_sprite.sprite_frames.get_frame_texture(TRAVEL_ANIM, 0)
	if frame_texture != null:
		var frame_size := minf(float(frame_texture.get_width()), float(frame_texture.get_height()))
		var sprite_scale := maxf(absf(fireball_sprite.scale.x), absf(fireball_sprite.scale.y))
		var visual_radius := frame_size * sprite_scale * maxf(0.01, visual_hit_radius_scale)
		computed_radius = maxf(computed_radius, visual_radius)
	live_collision_radius = maxf(6.0, computed_radius)


func _get_player_collision_radius(player_node: Player) -> float:
	if player_node == null or not is_instance_valid(player_node):
		return 0.0
	var collision_shape := player_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return 12.0
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return 12.0
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	return maxf(4.0, circle.radius * maxf(0.01, radius_scale) * maxf(0.1, player_hit_radius_scale))


func _get_player_collision_center(player_node: Player) -> Vector2:
	if player_node == null or not is_instance_valid(player_node):
		return Vector2.ZERO
	var collision_shape := player_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and is_instance_valid(collision_shape):
		return collision_shape.global_position
	return player_node.global_position


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	var closest := a + (segment * t)
	return point.distance_to(closest)


func _on_impact_finished() -> void:
	impact_finished = true
	queue_free()


static func _get_fireball_frames() -> SpriteFrames:
	if _cached_travel_frames != null:
		return _cached_travel_frames
	var frames := SpriteFrames.new()
	frames.add_animation(TRAVEL_ANIM)
	frames.set_animation_speed(TRAVEL_ANIM, 14.0)
	frames.set_animation_loop(TRAVEL_ANIM, true)
	for frame_path in TRAVEL_FRAME_PATHS:
		var texture := _load_texture(frame_path)
		if texture != null:
			frames.add_frame(TRAVEL_ANIM, texture)
	_cached_travel_frames = frames
	return _cached_travel_frames


static func _get_impact_frames() -> SpriteFrames:
	if _cached_impact_frames != null:
		return _cached_impact_frames
	var frames := SpriteFrames.new()
	frames.add_animation(IMPACT_ANIM)
	frames.set_animation_speed(IMPACT_ANIM, 16.0)
	frames.set_animation_loop(IMPACT_ANIM, false)
	for frame_path in IMPACT_FRAME_PATHS:
		var texture := _load_texture_vflip(frame_path)
		if texture != null:
			frames.add_frame(IMPACT_ANIM, texture)
	_cached_impact_frames = frames
	return _cached_impact_frames


static func _load_texture(resource_path: String) -> Texture2D:
	if _cached_texture_by_path.has(resource_path):
		return _cached_texture_by_path.get(resource_path) as Texture2D
	var global_path := ProjectSettings.globalize_path(resource_path)
	var image := Image.new()
	if image.load(global_path) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_cached_texture_by_path[resource_path] = texture
	return texture


static func _load_texture_vflip(resource_path: String) -> Texture2D:
	if _cached_texture_vflip_by_path.has(resource_path):
		return _cached_texture_vflip_by_path.get(resource_path) as Texture2D
	var global_path := ProjectSettings.globalize_path(resource_path)
	var image := Image.new()
	if image.load(global_path) != OK:
		return null
	image.flip_y()
	var texture := ImageTexture.create_from_image(image)
	_cached_texture_vflip_by_path[resource_path] = texture
	return texture

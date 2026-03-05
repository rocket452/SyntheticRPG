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

static var _cached_texture_by_path: Dictionary = {}
static var _cached_travel_frames: SpriteFrames = null
static var _cached_impact_frames: SpriteFrames = null

@export var visual_scale: Vector2 = Vector2(0.17, 0.17)
@export var impact_scale_multiplier: float = 1.32
@export var collision_radius: float = 16.0
@export var blocked_stamina_cost: float = 7.0
@export var visual_hit_radius_scale: float = 0.30
@export var player_hit_radius_scale: float = 1.0

var source_enemy: Node2D = null
var target_player: Player = null
var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var stun_duration: float = 0.08
var knockback_scale: float = 0.35
var remaining_distance: float = 0.0
var impact_finished: bool = false
var live_collision_radius: float = 16.0

var fireball_sprite: AnimatedSprite2D = null


func configure(
	source_enemy_node: Node2D,
	player_target: Player,
	spawn_position: Vector2,
	direction: Vector2,
	speed: float,
	max_distance: float,
	hit_damage: float,
	hit_stun: float,
	hit_knockback: float
) -> void:
	source_enemy = source_enemy_node
	target_player = player_target
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
	_ensure_sprite()
	if fireball_sprite == null:
		queue_free()
		return
	fireball_sprite.sprite_frames = _get_fireball_frames()
	fireball_sprite.play(TRAVEL_ANIM)
	fireball_sprite.scale = Vector2(absf(visual_scale.x), absf(visual_scale.y))
	fireball_sprite.flip_v = false
	fireball_sprite.rotation = PI
	_refresh_live_collision_radius()
	if absf(velocity.x) > 0.01:
		fireball_sprite.flip_h = velocity.x < 0.0


func _process(delta: float) -> void:
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
	if _try_hit_player(next_position):
		return
	global_position = next_position
	remaining_distance = maxf(0.0, remaining_distance - move_delta.length())
	if remaining_distance <= 0.0:
		_begin_impact(global_position)


func _ensure_sprite() -> void:
	if fireball_sprite != null and is_instance_valid(fireball_sprite):
		return
	var sprite := AnimatedSprite2D.new()
	sprite.centered = true
	add_child(sprite)
	fireball_sprite = sprite


func _try_block_on_player(world_start: Vector2, world_end: Vector2) -> bool:
	if target_player == null or not is_instance_valid(target_player) or target_player.is_dead:
		return false
	var shield_active := target_player.is_blocking
	if target_player.has_method("is_block_shield_active"):
		shield_active = bool(target_player.call("is_block_shield_active"))
	if not shield_active:
		return false
	if target_player.has_method("is_segment_intersecting_block_shield") and bool(target_player.call("is_segment_intersecting_block_shield", world_start, world_end, live_collision_radius)):
		if target_player.has_method("drain_block_stamina"):
			target_player.call("drain_block_stamina", blocked_stamina_cost)
		var impact_position := target_player.global_position
		if target_player.has_method("get_block_shield_center_global"):
			var center_variant: Variant = target_player.call("get_block_shield_center_global")
			if center_variant is Vector2:
				impact_position = center_variant
		_begin_impact(impact_position)
		return true
	return false


func _try_hit_player(next_position: Vector2) -> bool:
	if target_player == null or not is_instance_valid(target_player) or target_player.is_dead:
		return false
	var hitbox_center := _get_player_collision_center(target_player)
	var projectile_radius := maxf(6.0, live_collision_radius)
	var player_radius := _get_player_collision_radius(target_player)
	var total_radius := projectile_radius + player_radius
	if _distance_to_segment(hitbox_center, global_position, next_position) > total_radius:
		return false
	var hit_direction := velocity.normalized()
	if hit_direction.length_squared() <= 0.0001:
		hit_direction = Vector2.RIGHT
	var impact_position := hitbox_center - (hit_direction * player_radius)
	global_position = impact_position
	if target_player.has_method("receive_hit"):
		var source_position := source_enemy.global_position if source_enemy != null and is_instance_valid(source_enemy) else global_position
		target_player.call("receive_hit", damage, source_position, false, stun_duration, knockback_scale)
	_begin_impact(global_position)
	return true


func _begin_impact(world_position: Vector2) -> void:
	global_position = world_position
	velocity = Vector2.ZERO
	fireball_sprite.sprite_frames = _get_impact_frames()
	var impact_scale := visual_scale * maxf(1.0, impact_scale_multiplier)
	fireball_sprite.scale = Vector2(absf(impact_scale.x), absf(impact_scale.y))
	fireball_sprite.flip_h = false
	fireball_sprite.flip_v = false
	fireball_sprite.rotation = PI
	fireball_sprite.play(IMPACT_ANIM)
	fireball_sprite.animation_finished.connect(_on_impact_finished, CONNECT_ONE_SHOT)


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
		var texture := _load_texture(frame_path)
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

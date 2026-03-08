extends Node2D
class_name ImpFireballProjectile

const IMP_SHEET_PATH: String = "res://assets/external/ElthenAssets/imp/Imp Sprite Sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const HFRAMES: int = 8
const TRAVEL_ROW: int = 5
const TRAVEL_COLUMNS: Array[int] = [2, 3, 2, 3]
const IMPACT_COLUMNS: Array[int] = [5, 6, 7, 6]
const TRAVEL_ANIM: StringName = &"travel"
const IMPACT_ANIM: StringName = &"impact"

static var _sheet_texture_cache: Texture2D = null
static var _sprite_frames_cache: SpriteFrames = null

@export var visual_scale: Vector2 = Vector2(2.8, 2.8)
@export var impact_scale_multiplier: float = 1.45
@export var default_hit_radius: float = 10.0

var source_enemy: Node2D = null
var target_actor: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var damage: float = 5.0
var stun_duration: float = 0.06
var knockback_scale: float = 0.32
var remaining_distance: float = 240.0
var live_hit_radius: float = 10.0
var impact_finished: bool = false
var hitbox_debug_enabled: bool = false
var visual_travel_direction: Vector2 = Vector2.RIGHT

var sprite: AnimatedSprite2D = null
var glow_sprite: AnimatedSprite2D = null


func configure(
	source_enemy_node: Node2D,
	primary_target: Node2D,
	spawn_position: Vector2,
	direction: Vector2,
	speed: float,
	max_distance: float,
	hit_damage: float,
	hit_stun: float,
	hit_knockback: float,
	hit_radius: float
) -> void:
	source_enemy = source_enemy_node
	target_actor = primary_target
	global_position = spawn_position
	var normalized_direction := direction.normalized()
	if normalized_direction.length_squared() <= 0.0001:
		normalized_direction = Vector2.RIGHT
	visual_travel_direction = normalized_direction
	velocity = normalized_direction * maxf(1.0, speed)
	remaining_distance = maxf(24.0, max_distance)
	damage = maxf(0.0, hit_damage)
	stun_duration = maxf(0.0, hit_stun)
	knockback_scale = maxf(0.1, hit_knockback)
	live_hit_radius = maxf(6.0, hit_radius)
	top_level = true
	z_index = 232


func _ready() -> void:
	add_to_group("imp_fireballs")
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	sprite = AnimatedSprite2D.new()
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	glow_sprite = AnimatedSprite2D.new()
	glow_sprite.centered = true
	glow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow_sprite.modulate = Color(1.0, 0.58, 0.2, 0.48)
	glow_sprite.scale = Vector2(absf(visual_scale.x) * 1.32, absf(visual_scale.y) * 1.32)
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_sprite.material = glow_material
	add_child(glow_sprite)
	var frames := _get_sprite_frames()
	if frames == null:
		queue_free()
		return
	sprite.sprite_frames = frames
	sprite.animation = TRAVEL_ANIM
	sprite.play(TRAVEL_ANIM)
	glow_sprite.sprite_frames = frames
	glow_sprite.animation = TRAVEL_ANIM
	glow_sprite.play(TRAVEL_ANIM)
	sprite.scale = Vector2(absf(visual_scale.x), absf(visual_scale.y))
	_update_sprite_orientation(visual_travel_direction)


func _process(delta: float) -> void:
	if hitbox_debug_enabled:
		queue_redraw()
	if impact_finished:
		return
	if sprite == null or not is_instance_valid(sprite):
		queue_free()
		return
	if sprite.animation == IMPACT_ANIM:
		return
	_update_sprite_orientation(_get_travel_direction())
	var segment_start := global_position
	var move_delta := velocity * maxf(0.0, delta)
	var segment_end := segment_start + move_delta
	if _try_hit_friendly_target(segment_start, segment_end):
		return
	global_position = segment_end
	remaining_distance = maxf(0.0, remaining_distance - move_delta.length())
	if remaining_distance <= 0.0:
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
	draw_circle(Vector2.ZERO, live_hit_radius, Color(1.0, 0.52, 0.16, 0.14))
	draw_arc(Vector2.ZERO, live_hit_radius, 0.0, TAU, 24, Color(1.0, 0.66, 0.24, 0.94), 2.0, true)


func _try_hit_friendly_target(segment_start: Vector2, segment_end: Vector2) -> bool:
	var segment := segment_end - segment_start
	var segment_len_sq := segment.length_squared()
	var nearest_target: Node2D = null
	var nearest_progress := INF
	var nearest_center := Vector2.ZERO
	var nearest_radius := 0.0
	for candidate in _get_friendly_hit_candidates():
		var target_center := _get_target_collision_center(candidate)
		var target_radius := _get_target_collision_radius(candidate)
		var combined_radius := live_hit_radius + target_radius
		var progress := 0.0
		if segment_len_sq > 0.0001:
			progress = clampf((target_center - segment_start).dot(segment) / segment_len_sq, 0.0, 1.0)
		var nearest_point := segment_start + (segment * progress)
		if target_center.distance_to(nearest_point) > combined_radius:
			continue
		if nearest_target == null or progress < nearest_progress:
			nearest_target = candidate
			nearest_progress = progress
			nearest_center = target_center
			nearest_radius = target_radius
	if nearest_target == null:
		return false
	var travel_direction := _get_travel_direction()
	var impact_position := nearest_center - (travel_direction * nearest_radius)
	global_position = impact_position
	if nearest_target.has_method("receive_hit"):
		var source_position := source_enemy.global_position if source_enemy != null and is_instance_valid(source_enemy) else global_position
		nearest_target.call("receive_hit", damage, source_position, false, stun_duration, knockback_scale)
	_begin_impact(impact_position)
	return true


func _begin_impact(world_position: Vector2) -> void:
	if sprite == null or not is_instance_valid(sprite):
		queue_free()
		return
	var impact_direction := _get_travel_direction()
	global_position = world_position
	velocity = Vector2.ZERO
	sprite.animation = IMPACT_ANIM
	sprite.play(IMPACT_ANIM)
	var impact_scale := visual_scale * maxf(1.0, impact_scale_multiplier)
	sprite.scale = Vector2(absf(impact_scale.x), absf(impact_scale.y))
	if glow_sprite != null and is_instance_valid(glow_sprite):
		glow_sprite.animation = IMPACT_ANIM
		glow_sprite.play(IMPACT_ANIM)
		glow_sprite.scale = Vector2(absf(impact_scale.x) * 1.32, absf(impact_scale.y) * 1.32)
	_update_sprite_orientation(impact_direction)
	if not sprite.animation_finished.is_connected(_on_impact_finished):
		sprite.animation_finished.connect(_on_impact_finished, CONNECT_ONE_SHOT)


func _on_impact_finished() -> void:
	impact_finished = true
	queue_free()


func _get_travel_direction() -> Vector2:
	var direction := velocity.normalized()
	if direction.length_squared() <= 0.0001:
		direction = visual_travel_direction
	if direction.length_squared() <= 0.0001 and source_enemy != null and is_instance_valid(source_enemy):
		direction = (global_position - source_enemy.global_position).normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	visual_travel_direction = direction.normalized()
	return direction


func _update_sprite_orientation(direction: Vector2) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var resolved_direction := direction.normalized()
	if resolved_direction.length_squared() <= 0.0001:
		return
	var angle := resolved_direction.angle()
	sprite.rotation = angle
	sprite.flip_h = false
	if glow_sprite != null and is_instance_valid(glow_sprite):
		glow_sprite.rotation = angle
		glow_sprite.flip_h = false


func _get_friendly_hit_candidates() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	var seen_ids: Dictionary = {}
	var tank := _get_live_tank_player()
	if _is_valid_hit_target(tank):
		seen_ids[tank.get_instance_id()] = true
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
	var tank := target as Player
	if tank != null:
		return not tank.is_dead
	var healer := target as FriendlyHealer
	if healer != null:
		return not healer.dead
	var rat := target as FriendlyRatfolk
	if rat != null:
		return not rat.dead
	return true


func _get_live_tank_player() -> Player:
	var tank := get_tree().get_first_node_in_group("player") as Player
	if tank == null or not is_instance_valid(tank) or tank.is_dead:
		return null
	return tank


func _get_target_collision_center(target: Node2D) -> Vector2:
	var tank := target as Player
	if tank != null:
		if tank.has_method("get_block_shield_center_global"):
			var center_variant: Variant = tank.call("get_block_shield_center_global")
			if center_variant is Vector2:
				return center_variant
		return tank.global_position
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and is_instance_valid(collision_shape):
		return collision_shape.global_position
	return target.global_position


func _get_target_collision_radius(target: Node2D) -> float:
	var tank := target as Player
	if tank != null:
		var shield_radius := default_hit_radius
		if tank.has_method("get_block_shield_radius"):
			var radius_variant: Variant = tank.call("get_block_shield_radius")
			if radius_variant is float:
				shield_radius = maxf(shield_radius, float(radius_variant))
		return maxf(8.0, shield_radius)
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return default_hit_radius
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return default_hit_radius
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	return maxf(4.0, circle.radius * maxf(0.01, radius_scale))


func _get_sprite_frames() -> SpriteFrames:
	if _sprite_frames_cache != null:
		return _sprite_frames_cache
	var sheet := _get_sheet_texture()
	if sheet == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation(TRAVEL_ANIM)
	frames.set_animation_speed(TRAVEL_ANIM, 12.0)
	frames.set_animation_loop(TRAVEL_ANIM, true)
	for col in TRAVEL_COLUMNS:
		frames.add_frame(TRAVEL_ANIM, _build_frame(sheet, TRAVEL_ROW, col))
	frames.add_animation(IMPACT_ANIM)
	frames.set_animation_speed(IMPACT_ANIM, 14.0)
	frames.set_animation_loop(IMPACT_ANIM, false)
	for col in IMPACT_COLUMNS:
		frames.add_frame(IMPACT_ANIM, _build_frame(sheet, TRAVEL_ROW, col))
	_sprite_frames_cache = frames
	return _sprite_frames_cache


func _build_frame(sheet: Texture2D, row: int, col: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var frame_x: int = clampi(col, 0, HFRAMES - 1) * FRAME_SIZE.x
	var frame_y: int = maxi(0, row) * FRAME_SIZE.y
	atlas.region = Rect2i(frame_x, frame_y, FRAME_SIZE.x, FRAME_SIZE.y)
	return atlas


func _get_sheet_texture() -> Texture2D:
	if _sheet_texture_cache != null:
		return _sheet_texture_cache
	var image := Image.load_from_file(ProjectSettings.globalize_path(IMP_SHEET_PATH))
	if image == null or image.is_empty():
		return null
	_sheet_texture_cache = ImageTexture.create_from_image(image)
	return _sheet_texture_cache

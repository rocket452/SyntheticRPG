extends Node2D
class_name LizardArrowProjectile

const ARROW_TEXTURE_PATH: String = "res://assets/external/ElthenAssets/lizardfolk/Arrow.png"

static var arrow_texture_cache: Texture2D = null

@export var hit_radius: float = 10.5
@export var default_speed: float = 560.0
@export var max_lifetime: float = 2.4
@export var trail_length: float = 22.0
@export var trail_width: float = 1.8

var owner_actor: Node2D = null
var locked_target: EnemyBase = null
var travel_direction: Vector2 = Vector2.RIGHT
var move_speed: float = 560.0
var max_distance: float = 540.0
var damage_amount: float = 8.0
var stun_on_hit: float = 0.2
var knockback_on_hit: float = 0.72
var traveled_distance: float = 0.0
var alive_time: float = 0.0
var hitbox_debug_enabled: bool = false

@onready var trail: Line2D = get_node_or_null("Trail") as Line2D
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


func setup(
	source_actor: Node2D,
	start_position: Vector2,
	direction: Vector2,
	speed: float,
	distance: float,
	damage: float,
	stun_duration: float,
	knockback_scale: float,
	target_enemy: EnemyBase = null
) -> void:
	owner_actor = source_actor
	locked_target = target_enemy
	global_position = start_position
	if direction.length_squared() <= 0.0001:
		travel_direction = Vector2.RIGHT
	else:
		travel_direction = direction.normalized()
	move_speed = maxf(1.0, speed)
	max_distance = maxf(28.0, distance)
	damage_amount = maxf(0.1, damage)
	stun_on_hit = maxf(0.0, stun_duration)
	knockback_on_hit = maxf(0.1, knockback_scale)
	if is_inside_tree():
		_refresh_visual_orientation()


func _ready() -> void:
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	if sprite != null:
		if sprite.texture == null:
			sprite.texture = _get_arrow_texture()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if trail != null:
		_configure_trail_shape()
	_refresh_visual_orientation()


func _physics_process(delta: float) -> void:
	if hitbox_debug_enabled:
		queue_redraw()
	var safe_delta := maxf(0.0, delta)
	alive_time += safe_delta
	if alive_time >= maxf(0.1, max_lifetime):
		queue_free()
		return
	var previous_position := global_position
	var step := travel_direction * maxf(0.0, move_speed) * safe_delta
	global_position += step
	traveled_distance += step.length()
	if _try_hit_enemy(previous_position, global_position):
		queue_free()
		return
	if traveled_distance >= maxf(24.0, max_distance):
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
	var radius := maxf(5.0, hit_radius)
	draw_circle(Vector2.ZERO, radius, Color(0.4, 0.95, 0.48, 0.14))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.48, 1.0, 0.58, 0.94), 2.0, true)


func _refresh_visual_orientation() -> void:
	rotation = travel_direction.angle()


func _configure_trail_shape() -> void:
	if trail == null:
		return
	trail.width = maxf(0.6, trail_width)
	trail.default_color = Color(0.72, 0.9, 0.56, 0.76)
	trail.points = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(-maxf(6.0, trail_length), 0.0)
	])


func _try_hit_enemy(segment_start: Vector2, segment_end: Vector2) -> bool:
	if locked_target != null and is_instance_valid(locked_target) and not locked_target.dead:
		return _try_hit_specific_enemy(locked_target, segment_start, segment_end)
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
	var radius := maxf(6.0, hit_radius)
	if not _segment_hits_target(segment_start, segment_end, target_point, radius):
		return false
	if not enemy.has_method("receive_hit"):
		return false
	var source := owner_actor if owner_actor != null else self
	var landed := bool(enemy.call("receive_hit", damage_amount, global_position, stun_on_hit, true, knockback_on_hit, source))
	if landed and owner_actor != null and is_instance_valid(owner_actor) and owner_actor.has_method("add_special_meter_from_damage"):
		owner_actor.call("add_special_meter_from_damage", damage_amount)
	if landed and enemy.has_method("apply_hitstop"):
		enemy.call("apply_hitstop", 0.04)
	return landed


func _segment_hits_target(segment_start: Vector2, segment_end: Vector2, target: Vector2, radius: float) -> bool:
	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return segment_start.distance_squared_to(target) <= radius * radius
	var travel_t := clampf((target - segment_start).dot(segment) / segment_length_sq, 0.0, 1.0)
	var nearest_point := segment_start + (segment * travel_t)
	return nearest_point.distance_squared_to(target) <= radius * radius


func _get_arrow_texture() -> Texture2D:
	if arrow_texture_cache != null:
		return arrow_texture_cache
	var image := Image.load_from_file(ProjectSettings.globalize_path(ARROW_TEXTURE_PATH))
	if image == null or image.is_empty():
		return null
	arrow_texture_cache = ImageTexture.create_from_image(image)
	return arrow_texture_cache

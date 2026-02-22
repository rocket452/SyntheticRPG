extends CharacterBody2D
class_name FriendlyRatfolk

signal health_changed(current: float, maximum: float)
signal died(ratfolk: FriendlyRatfolk)

@export var max_health: float = 86.0
@export var move_speed: float = 96.0
@export var attack_damage: float = 8.5
@export var attack_range: float = 58.0
@export var attack_arc_degrees: float = 95.0
@export var attack_depth_tolerance: float = 44.0
@export var attack_windup: float = 0.14
@export var attack_recovery: float = 0.2
@export var attack_cooldown: float = 0.72
@export var attack_knockback_scale: float = 0.82
@export var outgoing_hit_stun_duration: float = 0.16
@export var hit_stun_duration: float = 0.2
@export var hit_knockback_speed: float = 170.0
@export var hit_knockback_decay: float = 980.0
@export var follow_player_distance: float = 116.0
@export var follow_player_min_distance: float = 50.0
@export var max_chase_distance_from_player: float = 320.0
@export var facing_flip_deadzone: float = 8.0
@export var arena_padding: float = 24.0
@export var lane_min_x: float = -760.0
@export var lane_max_x: float = 760.0
@export var lane_min_y: float = -165.0
@export var lane_max_y: float = 165.0
@export var health_bar_width: float = 56.0
@export var health_bar_thickness: float = 5.0
@export var health_bar_y_offset: float = -62.0
@export var hit_effect_duration: float = 0.12
@export var shadow_clone_enabled: bool = true
@export var shadow_clone_count: int = 2
@export var shadow_clone_cast_duration: float = 0.5
@export var shadow_clone_cooldown: float = 7.5
@export var shadow_clone_spawn_radius: float = 30.0
@export var shadow_clone_lifetime: float = 5.5
@export var shadow_clone_damage_scale: float = 0.58
@export var shadow_clone_speed_scale: float = 1.05
@export var shadow_clone_health_scale: float = 0.52
@export var shadow_clone_attack_cooldown_scale: float = 0.78
@export var shadow_clone_tint: Color = Color(0.62, 0.56, 0.98, 0.82)

const RATFOLK_SHEET_PATH: String = "res://assets/external/ElthenAssets/ratfolk/Ratfolk Rogue Sprite Sheet.png"
const RATFOLK_SCENE_PATH: String = "res://scenes/npcs/FriendlyRatfolk.tscn"
const RATFOLK_HFRAMES: int = 8
const RATFOLK_VFRAMES: int = 5
const ANIM_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"attack": 2,
	"hurt": 3,
	"death": 4
}
const ANIM_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"run": [0, 1, 2, 3, 4, 5],
	"attack": [0, 1, 2, 3, 4, 5, 6, 7],
	"hurt": [0, 1, 2, 3],
	"death": [0, 1, 2, 3]
}
const ANIM_FPS: Dictionary = {
	"idle": 7.0,
	"run": 11.0,
	"attack": 13.0,
	"hurt": 12.0,
	"death": 8.0
}

var player: Player = null
var target_enemy: EnemyBase = null
var current_health: float = 0.0
var dead: bool = false
var attack_windup_left: float = 0.0
var attack_recovery_left: float = 0.0
var attack_cooldown_left: float = 0.0
var shadow_clone_cast_left: float = 0.0
var shadow_clone_cast_active: bool = false
var shadow_clone_cooldown_left: float = 0.0
var shadow_clone_lifetime_left: float = 0.0
var is_shadow_clone: bool = false
var stun_left: float = 0.0
var hurt_anim_left: float = 0.0
var hit_flash_left: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var facing_left: bool = false
var sprite_anim_key: String = ""
var sprite_anim_time: float = 0.0
var death_anim_time: float = 0.0
var health_bar_root: Node2D = null
var health_bar_background: Line2D = null
var health_bar_fill: Line2D = null
var ratfolk_sheet_texture: Texture2D = null
var ratfolk_scene_cache: PackedScene = null
var sprite_base_scale: Vector2 = Vector2.ONE
var rng := RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("friendly_npcs")
	if _is_autoplay_requested():
		rng.seed = 4242
	else:
		rng.randomize()
	_configure_sprite()
	if is_instance_valid(sprite):
		sprite_base_scale = sprite.scale
	_acquire_player()
	_apply_shadow_clone_setup()
	current_health = maxf(1.0, max_health)
	attack_cooldown_left = attack_cooldown * 0.35
	if not is_shadow_clone:
		_setup_health_bar()
	else:
		shadow_clone_lifetime_left = maxf(0.2, shadow_clone_lifetime)
	_update_health_bar()
	health_changed.emit(current_health, max_health)


func _exit_tree() -> void:
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()


func set_player(target_player: Player) -> void:
	player = target_player


func setup_as_shadow_clone(owner_player: Player = null) -> void:
	is_shadow_clone = true
	shadow_clone_enabled = false
	shadow_clone_cast_left = 0.0
	shadow_clone_cast_active = false
	shadow_clone_cooldown_left = 0.0
	if is_instance_valid(owner_player):
		player = owner_player


func set_arena_bounds(min_x: float, max_x: float, min_y: float, max_y: float) -> void:
	lane_min_x = minf(min_x, max_x)
	lane_max_x = maxf(min_x, max_x)
	lane_min_y = minf(min_y, max_y)
	lane_max_y = maxf(min_y, max_y)
	_clamp_to_bounds()


func _apply_shadow_clone_setup() -> void:
	if not is_shadow_clone:
		return
	move_speed = maxf(24.0, move_speed * shadow_clone_speed_scale)
	attack_damage = maxf(1.0, attack_damage * shadow_clone_damage_scale)
	attack_cooldown = maxf(0.08, attack_cooldown * shadow_clone_attack_cooldown_scale)
	max_health = maxf(10.0, max_health * shadow_clone_health_scale)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(delta)
		_update_health_bar()
		if is_shadow_clone and death_anim_time >= _get_anim_duration("death") + 0.1:
			queue_free()
		return

	if not is_instance_valid(player):
		_acquire_player()

	if stun_left > 0.0:
		_interrupt_attack()
		velocity = knockback_velocity
	else:
		_tick_combat_logic(delta)
		velocity += knockback_velocity

	move_and_slide()
	_clamp_to_bounds()
	_update_animation(delta)
	_update_health_bar()


func _tick_timers(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	if shadow_clone_cast_active:
		shadow_clone_cast_left = maxf(0.0, shadow_clone_cast_left - delta)
	shadow_clone_cooldown_left = maxf(0.0, shadow_clone_cooldown_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	hurt_anim_left = maxf(0.0, hurt_anim_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, maxf(0.0, hit_knockback_decay) * delta)
	if is_instance_valid(sprite):
		var base_modulate := shadow_clone_tint if is_shadow_clone else Color(1.0, 1.0, 1.0, 1.0)
		if is_shadow_clone and shadow_clone_lifetime > 0.01:
			var life_ratio := clampf(shadow_clone_lifetime_left / maxf(0.01, shadow_clone_lifetime), 0.0, 1.0)
			base_modulate.a *= lerpf(0.32, 1.0, life_ratio)
		if hit_flash_left > 0.0:
			base_modulate = base_modulate.lerp(Color(1.0, 0.7, 0.7, base_modulate.a), 0.78)
		sprite.modulate = base_modulate
		if shadow_clone_cast_active and shadow_clone_cast_duration > 0.01:
			var cast_ratio := clampf(1.0 - (shadow_clone_cast_left / shadow_clone_cast_duration), 0.0, 1.0)
			var pulse := 1.0 + (sin(cast_ratio * TAU * 3.0) * 0.06)
			sprite.scale = sprite_base_scale * pulse
		else:
			sprite.scale = sprite_base_scale
	if is_shadow_clone and not dead:
		shadow_clone_lifetime_left = maxf(0.0, shadow_clone_lifetime_left - delta)
		if shadow_clone_lifetime_left <= 0.0:
			_die()


func _tick_combat_logic(delta: float) -> void:
	if shadow_clone_cast_active:
		velocity = Vector2.ZERO
		if shadow_clone_cast_left <= 0.0001:
			shadow_clone_cast_active = false
			_spawn_shadow_clones()
			shadow_clone_cooldown_left = maxf(0.01, shadow_clone_cooldown)
		return

	if attack_windup_left > 0.0:
		attack_windup_left = maxf(0.0, attack_windup_left - delta)
		velocity = Vector2.ZERO
		if attack_windup_left <= 0.0:
			_perform_attack()
			attack_recovery_left = maxf(0.01, attack_recovery)
		return

	if attack_recovery_left > 0.0:
		attack_recovery_left = maxf(0.0, attack_recovery_left - delta)
		velocity = Vector2.ZERO
		return

	target_enemy = _find_target_enemy()
	if target_enemy == null:
		_follow_player_when_idle()
		return

	var to_enemy := target_enemy.global_position - global_position
	_update_facing(to_enemy)
	var distance_to_enemy := to_enemy.length()
	var depth_aligned := absf(to_enemy.y) <= attack_depth_tolerance
	if _can_start_shadow_clone_cast(distance_to_enemy):
		_start_shadow_clone_cast()
		velocity = Vector2.ZERO
		return
	if attack_cooldown_left <= 0.0 and distance_to_enemy <= attack_range and depth_aligned:
		attack_windup_left = maxf(0.01, attack_windup)
		velocity = Vector2.ZERO
		return

	if distance_to_enemy <= attack_range * 0.8 and depth_aligned:
		velocity = to_enemy.normalized() * move_speed * 0.3
		return

	var move_direction := to_enemy.normalized() if distance_to_enemy > 0.0001 else Vector2.ZERO
	velocity = move_direction * move_speed


func _follow_player_when_idle() -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return
	var to_player := player.global_position - global_position
	var distance_to_player := to_player.length()
	if distance_to_player <= 0.0001:
		velocity = Vector2.ZERO
		return
	_update_facing(to_player)
	if distance_to_player > follow_player_distance:
		velocity = to_player.normalized() * move_speed * 0.9
	elif distance_to_player < follow_player_min_distance:
		velocity = -to_player.normalized() * move_speed * 0.7
	else:
		velocity = Vector2.ZERO


func _find_target_enemy() -> EnemyBase:
	var nearest_enemy: EnemyBase = null
	var nearest_distance_sq := INF
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var max_chase_distance_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy.global_position.distance_squared_to(player_position) > max_chase_distance_sq:
			continue
		var distance_sq := enemy.global_position.distance_squared_to(global_position)
		if nearest_enemy == null or distance_sq < nearest_distance_sq:
			nearest_enemy = enemy
			nearest_distance_sq = distance_sq
	return nearest_enemy


func _can_start_shadow_clone_cast(distance_to_enemy: float) -> bool:
	if is_shadow_clone:
		return false
	if not shadow_clone_enabled:
		return false
	if shadow_clone_count <= 0:
		return false
	if shadow_clone_cooldown_left > 0.0:
		return false
	if shadow_clone_cast_active or shadow_clone_cast_left > 0.0:
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if stun_left > 0.0:
		return false
	if target_enemy == null:
		return false
	return distance_to_enemy <= maxf(attack_range * 2.2, 132.0)


func _start_shadow_clone_cast() -> void:
	shadow_clone_cast_left = maxf(0.01, shadow_clone_cast_duration)
	shadow_clone_cast_active = true
	_spawn_shadow_clone_focus_effect()


func _spawn_shadow_clones() -> void:
	var spawn_scene := _get_ratfolk_scene()
	if spawn_scene == null:
		return
	var scene_root := get_parent()
	if scene_root == null:
		return
	var spawn_position_local := position
	var clone_total := maxi(1, shadow_clone_count)
	for _i in range(clone_total):
		var clone := spawn_scene.instantiate() as FriendlyRatfolk
		if clone == null:
			continue
		clone.setup_as_shadow_clone(player)
		clone.facing_left = facing_left
		scene_root.add_child(clone)
		clone.position = spawn_position_local
		clone.set_arena_bounds(lane_min_x, lane_max_x, lane_min_y, lane_max_y)
		clone.set_player(player)
		clone.attack_cooldown_left = rng.randf_range(0.02, maxf(0.06, clone.attack_cooldown * 0.4))
		clone.shadow_clone_lifetime_left = maxf(0.2, shadow_clone_lifetime)
		clone.shadow_clone_tint = shadow_clone_tint
		clone.shadow_clone_lifetime = maxf(0.2, shadow_clone_lifetime)
		clone.shadow_clone_speed_scale = shadow_clone_speed_scale
		clone.shadow_clone_damage_scale = shadow_clone_damage_scale
		clone.shadow_clone_health_scale = shadow_clone_health_scale
		clone.shadow_clone_attack_cooldown_scale = shadow_clone_attack_cooldown_scale
		_spawn_shadow_clone_birth_effect(clone.global_position)


func _get_ratfolk_scene() -> PackedScene:
	if is_instance_valid(ratfolk_scene_cache):
		return ratfolk_scene_cache
	var loaded_scene := load(RATFOLK_SCENE_PATH)
	if loaded_scene is PackedScene:
		ratfolk_scene_cache = loaded_scene as PackedScene
	return ratfolk_scene_cache


func _clamp_world_position_to_bounds(world_position: Vector2) -> Vector2:
	var clamped := world_position
	var min_x := minf(lane_min_x, lane_max_x) + arena_padding
	var max_x := maxf(lane_min_x, lane_max_x) - arena_padding
	var min_y := minf(lane_min_y, lane_max_y) + arena_padding
	var max_y := maxf(lane_min_y, lane_max_y) - arena_padding
	clamped.x = clampf(clamped.x, min_x, max_x)
	clamped.y = clampf(clamped.y, min_y, max_y)
	return clamped


func _perform_attack() -> void:
	attack_cooldown_left = maxf(0.01, attack_cooldown)
	var facing_direction := Vector2.LEFT if facing_left else Vector2.RIGHT
	var hit_any := false
	var arc_threshold := cos(deg_to_rad(attack_arc_degrees * 0.5))
	var attack_radius_sq := attack_range * attack_range

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var to_enemy := enemy.global_position - global_position
		if absf(to_enemy.y) > attack_depth_tolerance:
			continue
		if to_enemy.length_squared() > attack_radius_sq:
			continue
		var direction_to_enemy := to_enemy.normalized() if to_enemy.length_squared() > 0.0001 else facing_direction
		if facing_direction.dot(direction_to_enemy) < arc_threshold:
			continue
		if not enemy.has_method("receive_hit"):
			continue
		var landed := bool(enemy.call("receive_hit", attack_damage, global_position, outgoing_hit_stun_duration, true, attack_knockback_scale))
		if landed:
			hit_any = true

	if hit_any:
		_spawn_hit_effect(global_position + (facing_direction * 14.0) + Vector2(0.0, -10.0), Color(0.9, 0.74, 0.34, 0.95), 8.0)


func receive_hit(amount: float, source_position: Vector2, _guard_break: bool = false, stun_duration: float = 0.0) -> bool:
	if dead:
		return false
	if amount <= 0.0:
		return false
	if is_instance_valid(player) and player.is_point_inside_block_shield(global_position):
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT if facing_left else Vector2.LEFT
	knockback_velocity = knockback_direction * hit_knockback_speed
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	hit_flash_left = 0.12
	var hurt_duration := _get_hurt_animation_duration()
	hurt_anim_left = maxf(hurt_anim_left, hurt_duration)
	stun_left = maxf(stun_left, maxf(maxf(hit_stun_duration, stun_duration), hurt_duration))
	_interrupt_attack()
	_spawn_hit_effect(global_position + Vector2(0.0, -12.0), Color(1.0, 0.42, 0.34, 0.95), 9.0)
	if current_health <= 0.0:
		_die()
	return true


func _interrupt_attack() -> void:
	attack_windup_left = 0.0
	attack_recovery_left = 0.0
	shadow_clone_cast_active = false
	shadow_clone_cast_left = 0.0
	target_enemy = null


func _die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	stun_left = 0.0
	hurt_anim_left = 0.0
	attack_windup_left = 0.0
	attack_recovery_left = 0.0
	death_anim_time = 0.0
	died.emit(self)


func _configure_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = _get_ratfolk_sheet_texture()
	sprite.hframes = RATFOLK_HFRAMES
	sprite.vframes = RATFOLK_VFRAMES
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _update_facing(world_direction: Vector2) -> void:
	if not is_instance_valid(sprite):
		return
	if absf(world_direction.x) <= facing_flip_deadzone:
		return
	facing_left = world_direction.x < 0.0
	sprite.flip_h = facing_left


func _update_animation(delta: float) -> void:
	if not is_instance_valid(sprite):
		return
	if dead:
		death_anim_time += delta
		var death_duration := _get_anim_duration("death")
		var death_progress := clampf(death_anim_time / maxf(0.01, death_duration), 0.0, 1.0)
		_set_non_loop_anim("death", death_progress)
		return
	if stun_left > 0.0 or hurt_anim_left > 0.0:
		var hurt_duration := _get_hurt_animation_duration()
		var hurt_progress := clampf(1.0 - (hurt_anim_left / maxf(0.01, hurt_duration)), 0.0, 1.0)
		_set_non_loop_anim("hurt", hurt_progress)
		return
	if shadow_clone_cast_active:
		_set_loop_anim("idle", delta * 0.24)
		return
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		var total_attack_time := maxf(0.01, attack_windup + attack_recovery)
		var progress := 0.0
		if attack_windup_left > 0.0:
			progress = clampf(1.0 - (attack_windup_left / maxf(0.01, attack_windup)), 0.0, 1.0) * (attack_windup / total_attack_time)
		else:
			var recovery_progress := clampf(1.0 - (attack_recovery_left / maxf(0.01, attack_recovery)), 0.0, 1.0)
			progress = clampf((attack_windup / total_attack_time) + (recovery_progress * (attack_recovery / total_attack_time)), 0.0, 1.0)
		_set_non_loop_anim("attack", progress)
		return
	if velocity.length_squared() > 36.0:
		_set_loop_anim("run", delta)
	else:
		_set_loop_anim("idle", delta)


func _set_loop_anim(anim_key: String, delta: float) -> void:
	if sprite_anim_key != anim_key:
		sprite_anim_key = anim_key
		sprite_anim_time = 0.0
	else:
		sprite_anim_time += delta
	var columns: Array = ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var fps := float(ANIM_FPS.get(anim_key, 8.0))
	var frame_index := int(floor(sprite_anim_time * fps)) % columns.size()
	_set_sprite_frame(anim_key, frame_index)


func _set_non_loop_anim(anim_key: String, progress: float) -> void:
	sprite_anim_key = anim_key
	var columns: Array = ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var frame_index := mini(int(floor(clampf(progress, 0.0, 1.0) * float(columns.size()))), columns.size() - 1)
	_set_sprite_frame(anim_key, frame_index)


func _set_sprite_frame(anim_key: String, frame_index: int) -> void:
	if not is_instance_valid(sprite):
		return
	var row := int(ANIM_ROWS.get(anim_key, 0))
	var columns: Array = ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var safe_index := clampi(frame_index, 0, columns.size() - 1)
	var column := int(columns[safe_index])
	sprite.frame_coords = Vector2i(column, row)
	sprite.flip_h = facing_left


func _get_anim_duration(anim_key: String) -> float:
	var columns: Array = ANIM_FRAME_COLUMNS.get(anim_key, [])
	var fps := float(ANIM_FPS.get(anim_key, 8.0))
	if columns.is_empty() or fps <= 0.0:
		return 0.2
	return float(columns.size()) / fps


func _get_hurt_animation_duration() -> float:
	return _get_anim_duration("hurt")


func _acquire_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Player


func _get_ratfolk_sheet_texture() -> Texture2D:
	if is_instance_valid(ratfolk_sheet_texture):
		return ratfolk_sheet_texture
	var source_image := Image.load_from_file(ProjectSettings.globalize_path(RATFOLK_SHEET_PATH))
	if source_image == null or source_image.is_empty():
		return null
	ratfolk_sheet_texture = ImageTexture.create_from_image(source_image)
	return ratfolk_sheet_texture


func _clamp_to_bounds() -> void:
	var min_x := minf(lane_min_x, lane_max_x) + arena_padding
	var max_x := maxf(lane_min_x, lane_max_x) - arena_padding
	var min_y := minf(lane_min_y, lane_max_y) + arena_padding
	var max_y := maxf(lane_min_y, lane_max_y) - arena_padding
	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, min_y, max_y)


func _setup_health_bar() -> void:
	health_bar_root = Node2D.new()
	health_bar_root.name = "RatfolkHealthBar"
	health_bar_root.top_level = true
	health_bar_root.z_index = 255
	add_child(health_bar_root)

	health_bar_background = Line2D.new()
	health_bar_background.default_color = Color(0.08, 0.08, 0.08, 0.92)
	health_bar_background.width = health_bar_thickness
	health_bar_background.begin_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_background.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(health_bar_background)

	health_bar_fill = Line2D.new()
	health_bar_fill.default_color = Color(0.36, 0.92, 0.86, 0.95)
	health_bar_fill.width = maxf(2.0, health_bar_thickness - 1.5)
	health_bar_fill.begin_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_fill.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(health_bar_fill)


func _update_health_bar() -> void:
	if not is_instance_valid(health_bar_root):
		return
	var half_width := health_bar_width * 0.5
	var bar_start := Vector2(-half_width, 0.0)
	var bar_end := Vector2(half_width, 0.0)
	health_bar_root.global_position = global_position + Vector2(0.0, health_bar_y_offset)
	health_bar_background.points = PackedVector2Array([bar_start, bar_end])
	var health_ratio := clampf(current_health / maxf(1.0, max_health), 0.0, 1.0)
	var fill_x := lerpf(bar_start.x, bar_end.x, health_ratio)
	health_bar_fill.points = PackedVector2Array([bar_start, Vector2(fill_x, 0.0)])
	health_bar_fill.visible = health_ratio > 0.0


func _spawn_hit_effect(world_position: Vector2, effect_color: Color, effect_size: float) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var effect := Polygon2D.new()
	effect.top_level = true
	effect.global_position = world_position
	effect.z_index = 232
	effect.color = effect_color
	effect.polygon = PackedVector2Array([
		Vector2(0.0, -effect_size),
		Vector2(effect_size * 0.55, 0.0),
		Vector2(0.0, effect_size),
		Vector2(-effect_size * 0.55, 0.0)
	])
	scene_root.add_child(effect)
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector2(1.7, 1.7), hit_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, hit_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(effect):
			effect.queue_free()
	)


func _spawn_shadow_clone_focus_effect() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return

	var burst := Node2D.new()
	burst.top_level = true
	burst.global_position = global_position + Vector2(0.0, -14.0)
	burst.z_index = 233
	scene_root.add_child(burst)

	var ring := Line2D.new()
	ring.default_color = Color(0.72, 0.68, 1.0, 0.9)
	ring.width = 2.4
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = _build_ring_points(12.0, 18)
	burst.add_child(ring)

	var inner_ring := Line2D.new()
	inner_ring.default_color = Color(0.5, 0.84, 1.0, 0.72)
	inner_ring.width = 1.7
	inner_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	inner_ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	inner_ring.closed = true
	inner_ring.points = _build_ring_points(7.0, 14)
	burst.add_child(inner_ring)

	var cross := Line2D.new()
	cross.default_color = Color(0.68, 0.96, 1.0, 0.85)
	cross.width = 1.8
	cross.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cross.end_cap_mode = Line2D.LINE_CAP_ROUND
	cross.points = PackedVector2Array([Vector2(-8.0, 0.0), Vector2(8.0, 0.0)])
	burst.add_child(cross)

	var cross_v := Line2D.new()
	cross_v.default_color = Color(0.68, 0.96, 1.0, 0.85)
	cross_v.width = 1.8
	cross_v.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cross_v.end_cap_mode = Line2D.LINE_CAP_ROUND
	cross_v.points = PackedVector2Array([Vector2(0.0, -8.0), Vector2(0.0, 8.0)])
	burst.add_child(cross_v)

	var duration := maxf(0.08, shadow_clone_cast_duration)
	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2(1.55, 1.55), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(burst, "rotation", 0.8, duration)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


func _spawn_shadow_clone_birth_effect(world_position: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return

	var pulse := Node2D.new()
	pulse.top_level = true
	pulse.global_position = world_position + Vector2(0.0, -12.0)
	pulse.z_index = 231
	scene_root.add_child(pulse)

	var ring := Line2D.new()
	ring.default_color = Color(0.62, 0.92, 1.0, 0.92)
	ring.width = 2.6
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = _build_ring_points(8.0, 16)
	pulse.add_child(ring)

	var shards_color := Color(0.78, 0.74, 1.0, 0.85)
	for i in range(3):
		var shard := Polygon2D.new()
		shard.color = shards_color
		shard.rotation = (TAU * float(i)) / 3.0
		shard.position = Vector2.RIGHT.rotated(shard.rotation) * 7.0
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -3.0),
			Vector2(5.0, 0.0),
			Vector2(0.0, 3.0),
			Vector2(-1.5, 0.0)
		])
		pulse.add_child(shard)

	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.9, 1.9), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func() -> void:
		if is_instance_valid(pulse):
			pulse.queue_free()
	)


func _build_ring_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_segments := maxi(6, segments)
	for i in range(safe_segments):
		var angle := (TAU * float(i)) / float(safe_segments)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


func _is_autoplay_requested() -> bool:
	var autoplay_raw := OS.get_environment("AUTOPLAY_TEST").strip_edges().to_lower()
	if not autoplay_raw.is_empty() and autoplay_raw not in ["0", "false", "off", "no"]:
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false

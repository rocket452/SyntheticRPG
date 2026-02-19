extends CharacterBody2D
class_name EnemyBase

signal died(enemy: EnemyBase)

@export var max_health: float = 60.0
@export var move_speed: float = 105.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 46.0
@export var attack_cooldown: float = 1.2
@export var attack_windup: float = 0.2
@export var xp_reward: int = 26
@export var drop_chance: float = 0.45
@export var drop_table: Array[String] = ["iron_shard", "sturdy_hide"]
@export var hit_stun_duration: float = 0.22
@export var outgoing_hit_stun_duration: float = 0.2
@export var hit_effect_duration: float = 0.14
@export var hit_knockback_speed: float = 190.0
@export var hit_knockback_decay: float = 980.0
@export var lane_min_x: float = -760.0
@export var lane_max_x: float = 760.0
@export var lane_min_y: float = -165.0
@export var lane_max_y: float = 165.0
@export var health_bar_width: float = 58.0
@export var health_bar_thickness: float = 5.0
@export var health_bar_y_offset: float = -62.0
@export var is_miniboss: bool = false
@export var debug_orientation_overlay: bool = false
@export var debug_focus_nearest_enemy_only: bool = true

const MONSTER_HD_HFRAMES: int = 8
const MONSTER_HD_VFRAMES: int = 8
const MONSTER_SHEET: Texture2D = preload("res://assets/external/ElthenAssets/dwarf/Dwarf Sprite Sheet 1.3v.png")
const MONSTER_TEXTURES: Dictionary = {
	"idle": MONSTER_SHEET,
	"run": MONSTER_SHEET,
	"attack": MONSTER_SHEET,
	"death": MONSTER_SHEET
}
const MONSTER_FPS: Dictionary = {
	"idle": 9.0,
	"run": 12.0,
	"attack": 13.0,
	"death": 8.0
}
const MONSTER_ACTION_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"attack": 2,
	"death": 7
}
const MONSTER_ACTION_FRAME_COUNTS: Dictionary = {
	"idle": 5,
	"run": 8,
	"attack": 7,
	"death": 7
}
const MONSTER_HD_ROW_DIRECTIONS: Array[Vector2] = [
	Vector2(-0.70710677, -0.70710677),
	Vector2(0.0, -1.0),
	Vector2(-1.0, 0.0),
	Vector2(-0.70710677, 0.70710677),
	Vector2(0.70710677, 0.70710677),
	Vector2(0.0, 1.0),
	Vector2(1.0, 0.0),
	Vector2(0.70710677, -0.70710677)
]
const MONSTER_HD_ROW_NAMES: Array[String] = ["NW", "N", "W", "SW", "SE", "S", "E", "NE"]

var current_health: float = 0.0
var attack_cooldown_left: float = 0.0
var attack_windup_left: float = 0.0
var pending_attack: bool = false
var player: Node = null
var dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

var hit_flash_left: float = 0.0
var stun_left: float = 0.0
var attack_flash_left: float = 0.0
var attack_anim_left: float = 0.0
var attack_anim_total: float = 0.0
var attack_anim_strength: float = 1.0
var anim_time: float = 0.0
var slash_effect_left: float = 0.0
var slash_effect_total: float = 0.0
var weapon_trail_alpha: float = 0.0
var weapon_trail_points: Array[Vector2] = []
var monster_anim_name: String = ""
var monster_anim_time: float = 0.0
var using_external_monster_sprite: bool = false
var monster_sprite_base_position: Vector2 = Vector2.ZERO
var external_sprite_facing_direction: Vector2 = Vector2.RIGHT
var debug_overlay_root: Node2D = null
var debug_label: Label = null
var debug_row_line: Line2D = null
var debug_facing_line: Line2D = null
var debug_target_line: Line2D = null
var debug_last_row: int = 5
var debug_last_action: String = "idle"
var debug_last_facing: Vector2 = Vector2.DOWN
var debug_last_to_player: Vector2 = Vector2.ZERO
var health_bar_root: Node2D = null
var health_bar_background: Line2D = null
var health_bar_fill: Line2D = null

@onready var shadow_visual: Polygon2D = $Shadow
@onready var body_visual: Polygon2D = $Body
@onready var head_visual: Polygon2D = $Body/Head
@onready var left_arm_visual: Polygon2D = $Body/LeftArm
@onready var right_arm_visual: Polygon2D = $Body/RightArm
@onready var weapon_visual: Polygon2D = $Body/Weapon
@onready var left_leg_visual: Polygon2D = $Body/LeftLeg
@onready var right_leg_visual: Polygon2D = $Body/RightLeg
@onready var rib_plate_visual: Polygon2D = get_node_or_null("Body/RibPlate") as Polygon2D
@onready var cloth_front_visual: Polygon2D = get_node_or_null("Body/WaistClothFront") as Polygon2D
@onready var cloth_back_visual: Polygon2D = get_node_or_null("Body/WaistClothBack") as Polygon2D
@onready var monster_sprite: Sprite2D = get_node_or_null("MonsterSprite") as Sprite2D
@onready var weapon_trail: Line2D = $WeaponTrail
@onready var slash_effect: Line2D = $SlashEffect
@onready var attack_telegraph: Line2D = $AttackTelegraph

var base_body_color: Color = Color(1, 1, 1, 1)
var base_head_color: Color = Color(1, 1, 1, 1)
var base_arm_color: Color = Color(1, 1, 1, 1)
var base_weapon_color: Color = Color(1, 1, 1, 1)
var base_leg_color: Color = Color(1, 1, 1, 1)

var head_base_position: Vector2 = Vector2.ZERO
var left_arm_base_position: Vector2 = Vector2.ZERO
var right_arm_base_position: Vector2 = Vector2.ZERO
var weapon_base_position: Vector2 = Vector2.ZERO
var left_leg_base_position: Vector2 = Vector2.ZERO
var right_leg_base_position: Vector2 = Vector2.ZERO
var rib_plate_base_position: Vector2 = Vector2.ZERO
var cloth_front_base_position: Vector2 = Vector2.ZERO
var cloth_back_base_position: Vector2 = Vector2.ZERO

var head_base_rotation: float = 0.0
var left_arm_base_rotation: float = 0.0
var right_arm_base_rotation: float = 0.0
var weapon_base_rotation: float = 0.0
var left_leg_base_rotation: float = 0.0
var right_leg_base_rotation: float = 0.0
var cloth_front_base_rotation: float = 0.0
var cloth_back_base_rotation: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	attack_cooldown_left = randf_range(0.1, attack_cooldown)
	using_external_monster_sprite = is_instance_valid(monster_sprite)
	if using_external_monster_sprite:
		body_visual.visible = false
		monster_sprite.visible = true
		monster_sprite_base_position = monster_sprite.position
	base_body_color = body_visual.color
	base_head_color = head_visual.color
	base_arm_color = left_arm_visual.color
	base_weapon_color = weapon_visual.color
	base_leg_color = left_leg_visual.color
	head_base_position = head_visual.position
	left_arm_base_position = left_arm_visual.position
	right_arm_base_position = right_arm_visual.position
	weapon_base_position = weapon_visual.position
	left_leg_base_position = left_leg_visual.position
	right_leg_base_position = right_leg_visual.position
	if rib_plate_visual != null:
		rib_plate_base_position = rib_plate_visual.position
	if cloth_front_visual != null:
		cloth_front_base_position = cloth_front_visual.position
		cloth_front_base_rotation = cloth_front_visual.rotation
	if cloth_back_visual != null:
		cloth_back_base_position = cloth_back_visual.position
		cloth_back_base_rotation = cloth_back_visual.rotation
	head_base_rotation = head_visual.rotation
	left_arm_base_rotation = left_arm_visual.rotation
	right_arm_base_rotation = right_arm_visual.rotation
	weapon_base_rotation = weapon_visual.rotation
	left_leg_base_rotation = left_leg_visual.rotation
	right_leg_base_rotation = right_leg_visual.rotation
	attack_telegraph.visible = false
	weapon_trail.visible = false
	slash_effect.visible = false
	_setup_health_bar()
	_update_health_bar()
	_reacquire_player()
	_setup_debug_overlay()


func _exit_tree() -> void:
	_teardown_debug_overlay()


func _physics_process(delta: float) -> void:
	if dead:
		return

	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	attack_flash_left = maxf(0.0, attack_flash_left - delta)
	attack_anim_left = maxf(0.0, attack_anim_left - delta)
	slash_effect_left = maxf(0.0, slash_effect_left - delta)
	weapon_trail_alpha = maxf(0.0, weapon_trail_alpha - (delta * 1.45))

	if not is_instance_valid(player):
		_reacquire_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_update_visuals(delta, Vector2.RIGHT)
		_update_health_bar()
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length_squared() > 0.0001:
		if using_external_monster_sprite:
			external_sprite_facing_direction = to_player.normalized()
			rotation = 0.0
		else:
			rotation = lerp_angle(rotation, to_player.angle(), clampf(delta * 10.0, 0.0, 1.0))

	if stun_left > 0.0:
		pending_attack = false
		attack_windup_left = 0.0
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
		attack_telegraph.visible = false
		move_and_slide()
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if pending_attack:
		velocity = Vector2.ZERO
		attack_windup_left -= delta
		if attack_windup_left <= 0.0:
			pending_attack = false
			attack_cooldown_left = attack_cooldown
			_perform_attack()
		move_and_slide()
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)

	var distance_to_player := to_player.length()
	if distance_to_player > attack_range * 0.9:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
		if attack_cooldown_left <= 0.0:
			pending_attack = true
			attack_windup_left = attack_windup

	move_and_slide()
	_clamp_to_arena()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	_update_visuals(delta, to_player)
	_update_health_bar()


func set_arena_bounds(min_x: float, max_x: float, min_y: float, max_y: float) -> void:
	lane_min_x = minf(min_x, max_x)
	lane_max_x = maxf(min_x, max_x)
	lane_min_y = minf(min_y, max_y)
	lane_max_y = maxf(min_y, max_y)


func _clamp_to_arena() -> void:
	position.x = clampf(position.x, lane_min_x, lane_max_x)
	position.y = clampf(position.y, lane_min_y, lane_max_y)


func _setup_health_bar() -> void:
	health_bar_root = Node2D.new()
	health_bar_root.name = "EnemyHealthBar"
	health_bar_root.top_level = true
	health_bar_root.z_index = 250
	add_child(health_bar_root)

	health_bar_background = Line2D.new()
	health_bar_background.default_color = Color(0.08, 0.08, 0.08, 0.92)
	health_bar_background.width = health_bar_thickness
	health_bar_background.z_index = 0
	health_bar_background.begin_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_background.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(health_bar_background)

	health_bar_fill = Line2D.new()
	health_bar_fill.default_color = Color(0.9, 0.24, 0.22, 0.95)
	health_bar_fill.width = maxf(2.0, health_bar_thickness - 2.0)
	health_bar_fill.z_index = 1
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


func _reacquire_player() -> void:
	player = get_tree().get_first_node_in_group("player")


func _setup_debug_overlay() -> void:
	if not debug_orientation_overlay:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	debug_overlay_root = Node2D.new()
	debug_overlay_root.name = "EnemyDebugOverlay_%s" % name
	debug_overlay_root.top_level = true
	scene_root.add_child(debug_overlay_root)

	debug_row_line = Line2D.new()
	debug_row_line.default_color = Color(0.28, 0.98, 0.46, 0.95)
	debug_row_line.width = 2.0
	debug_row_line.z_index = 180
	debug_row_line.round_precision = 4
	debug_row_line.points = PackedVector2Array([Vector2.ZERO, Vector2(20.0, 0.0)])
	debug_overlay_root.add_child(debug_row_line)

	debug_facing_line = Line2D.new()
	debug_facing_line.default_color = Color(0.36, 0.82, 0.96, 0.95)
	debug_facing_line.width = 2.0
	debug_facing_line.z_index = 180
	debug_facing_line.round_precision = 4
	debug_facing_line.points = PackedVector2Array([Vector2.ZERO, Vector2(26.0, 0.0)])
	debug_overlay_root.add_child(debug_facing_line)

	debug_target_line = Line2D.new()
	debug_target_line.default_color = Color(1.0, 0.8, 0.34, 0.92)
	debug_target_line.width = 1.8
	debug_target_line.z_index = 179
	debug_target_line.round_precision = 4
	debug_target_line.points = PackedVector2Array([Vector2.ZERO, Vector2(32.0, 0.0)])
	debug_overlay_root.add_child(debug_target_line)

	debug_label = Label.new()
	debug_label.position = Vector2(12.0, -40.0)
	debug_label.scale = Vector2(0.8, 0.8)
	debug_label.z_index = 181
	debug_label.modulate = Color(0.95, 0.98, 1.0, 0.96)
	debug_overlay_root.add_child(debug_label)


func _teardown_debug_overlay() -> void:
	if is_instance_valid(debug_overlay_root):
		debug_overlay_root.queue_free()
	debug_overlay_root = null
	debug_label = null
	debug_row_line = null
	debug_facing_line = null
	debug_target_line = null


func _perform_attack() -> void:
	attack_flash_left = 0.10
	_start_attack_animation(0.2, 1.3)
	_trigger_slash_effect(attack_range + 12.0, 95.0, Color(0.94, 0.46, 0.26, 0.88), 0.18, 4.2)

	var player_target := _query_player_hit(attack_range + 12.0)
	if player_target == null:
		return
	if player_target.receive_hit(attack_damage, global_position, false, outgoing_hit_stun_duration):
		_spawn_hit_effect(player_target.global_position + Vector2(0.0, -14.0), Color(1.0, 0.44, 0.3, 0.95), 10.0)


func receive_hit(amount: float, source_position: Vector2, stun_duration: float = 0.0) -> bool:
	if dead:
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.LEFT if external_sprite_facing_direction.x >= 0.0 else Vector2.RIGHT
	knockback_velocity = knockback_direction * hit_knockback_speed

	current_health = maxf(0.0, current_health - amount)
	hit_flash_left = 0.12
	stun_left = maxf(stun_left, maxf(hit_stun_duration, stun_duration))
	pending_attack = false
	attack_windup_left = 0.0
	attack_cooldown_left = maxf(attack_cooldown_left, stun_left + 0.08)
	attack_anim_left = 0.0
	attack_flash_left = 0.0
	weapon_trail_alpha = 0.0
	weapon_trail.visible = false
	slash_effect.visible = false
	attack_telegraph.visible = false
	velocity = Vector2.ZERO
	_spawn_hit_effect(global_position + Vector2(0.0, -12.0), Color(1.0, 0.78, 0.42, 0.95), 8.0)
	if current_health <= 0.0:
		_die()

	return true


func _query_player_hit(max_distance: float) -> Player:
	var world := get_world_2d()
	if world == null:
		return null
	var hit_shape := CircleShape2D.new()
	hit_shape.radius = maxf(4.0, max_distance)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1
	query.exclude = [get_rid()]

	var nearest_player: Player = null
	var nearest_distance_sq := max_distance * max_distance
	for result in world.direct_space_state.intersect_shape(query, 8):
		var candidate := result.get("collider") as Player
		if candidate == null or not is_instance_valid(candidate):
			continue
		var distance_sq := candidate.global_position.distance_squared_to(global_position)
		if distance_sq > max_distance * max_distance:
			continue
		if nearest_player == null or distance_sq < nearest_distance_sq:
			nearest_player = candidate
			nearest_distance_sq = distance_sq
	return nearest_player


func _spawn_hit_effect(world_position: Vector2, effect_color: Color, effect_size: float) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var effect := Polygon2D.new()
	effect.top_level = true
	effect.global_position = world_position
	effect.z_index = 230
	effect.color = effect_color
	effect.polygon = PackedVector2Array([
		Vector2(0.0, -effect_size),
		Vector2(effect_size * 0.55, 0.0),
		Vector2(0.0, effect_size),
		Vector2(-effect_size * 0.55, 0.0)
	])
	scene_root.add_child(effect)

	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector2(1.8, 1.8), hit_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, hit_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(effect):
			effect.queue_free()
	)


func _update_visuals(delta: float, to_player: Vector2) -> void:
	var target_scale := Vector2.ONE
	var movement_ratio := clampf(velocity.length() / maxf(1.0, move_speed), 0.0, 1.0)
	_update_monster_sprite(delta, movement_ratio, to_player)
	if pending_attack:
		target_scale = Vector2(1.1, 0.9)
	elif attack_flash_left > 0.0:
		target_scale = Vector2(1.16, 0.84)

	_update_model_animation(delta, movement_ratio, to_player)

	if hit_flash_left > 0.0:
		_set_model_palette(
			Color(0.74, 0.26, 0.24, 1.0),
			Color(0.78, 0.44, 0.42, 1.0),
			Color(0.64, 0.2, 0.2, 1.0),
			Color(0.72, 0.64, 0.6, 1.0)
		)
	elif pending_attack:
		_set_model_palette(
			base_body_color.lerp(Color(0.6, 0.2, 0.18, 1.0), 0.58),
			base_head_color.lerp(Color(0.7, 0.5, 0.44, 1.0), 0.45),
			base_arm_color.lerp(Color(0.5, 0.16, 0.16, 1.0), 0.55),
			base_weapon_color.lerp(Color(0.74, 0.62, 0.48, 1.0), 0.5)
		)
	elif attack_flash_left > 0.0:
		_set_model_palette(
			base_body_color.lerp(Color(0.64, 0.24, 0.2, 1.0), 0.42),
			base_head_color,
			base_arm_color,
			base_weapon_color.lerp(Color(0.8, 0.72, 0.62, 1.0), 0.52)
		)
	else:
		_set_model_palette(base_body_color, base_head_color, base_arm_color, base_weapon_color)

	scale = scale.lerp(target_scale, clampf(delta * 14.0, 0.0, 1.0))
	_update_attack_telegraph(to_player)
	_update_weapon_fx(delta)
	_update_debug_overlay()


func _update_monster_sprite(delta: float, movement_ratio: float, to_player: Vector2) -> void:
	var facing := to_player
	if velocity.length_squared() > 0.001:
		facing = velocity
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	external_sprite_facing_direction = facing.normalized()
	debug_last_row = _pick_debug_facing_row(external_sprite_facing_direction, 6)

	var action_key := "idle"
	if dead:
		action_key = "death"
	elif pending_attack or attack_anim_left > 0.0:
		action_key = "attack"
	elif movement_ratio > 0.08:
		action_key = "run"
	var row := int(MONSTER_ACTION_ROWS.get(action_key, 0))
	debug_last_action = action_key
	debug_last_facing = facing
	debug_last_to_player = to_player

	if not using_external_monster_sprite:
		return

	monster_sprite.position = monster_sprite_base_position
	monster_sprite.flip_h = facing.x < -0.01

	var sheet := MONSTER_TEXTURES.get(action_key) as Texture2D
	if sheet == null:
		return
	var frame_count := int(MONSTER_ACTION_FRAME_COUNTS.get(action_key, MONSTER_HD_HFRAMES))
	if monster_anim_name != action_key or monster_sprite.texture != sheet:
		monster_anim_name = action_key
		monster_anim_time = 0.0
		monster_sprite.texture = sheet
		monster_sprite.hframes = MONSTER_HD_HFRAMES
		monster_sprite.vframes = MONSTER_HD_VFRAMES
		monster_sprite.frame_coords = Vector2i(0, row)
	var fps := float(MONSTER_FPS.get(action_key, 8.0))
	monster_anim_time += delta * fps
	var frame_index: int
	if action_key == "death" and dead:
		frame_index = mini(int(floor(monster_anim_time)), frame_count - 1)
	elif action_key == "attack":
		frame_index = mini(int(floor(monster_anim_time)), frame_count - 1)
	else:
		frame_index = int(floor(monster_anim_time)) % frame_count
	monster_sprite.frame_coords = Vector2i(frame_index, row)


func _pick_debug_facing_row(direction: Vector2, fallback_row: int = 6) -> int:
	if direction.length_squared() <= 0.0001:
		return fallback_row
	var normalized_direction := direction.normalized()
	var best_row := fallback_row
	var best_dot := -2.0
	for row_idx in MONSTER_HD_ROW_DIRECTIONS.size():
		var row_direction := MONSTER_HD_ROW_DIRECTIONS[row_idx]
		var alignment := normalized_direction.dot(row_direction)
		if alignment > best_dot:
			best_dot = alignment
			best_row = row_idx
	return best_row


func _update_debug_overlay() -> void:
	if not debug_orientation_overlay:
		return
	if not is_instance_valid(debug_overlay_root):
		return
	if not _is_debug_focus_enemy():
		debug_overlay_root.visible = false
		return
	debug_overlay_root.visible = true

	debug_overlay_root.global_position = global_position + Vector2(0.0, -42.0)
	var row := clampi(debug_last_row, 0, MONSTER_HD_ROW_DIRECTIONS.size() - 1)
	var row_direction := MONSTER_HD_ROW_DIRECTIONS[row]
	var facing_direction := debug_last_facing.normalized() if debug_last_facing.length_squared() > 0.0001 else Vector2.ZERO
	var target_direction := debug_last_to_player.normalized() if debug_last_to_player.length_squared() > 0.0001 else Vector2.ZERO

	if is_instance_valid(debug_row_line):
		debug_row_line.points = PackedVector2Array([Vector2.ZERO, row_direction * 22.0])
	if is_instance_valid(debug_facing_line):
		debug_facing_line.points = PackedVector2Array([Vector2.ZERO, facing_direction * 30.0])
	if is_instance_valid(debug_target_line):
		debug_target_line.visible = target_direction.length_squared() > 0.0001
		if debug_target_line.visible:
			debug_target_line.points = PackedVector2Array([Vector2.ZERO, target_direction * 36.0])

	if is_instance_valid(debug_label):
		var row_name := MONSTER_HD_ROW_NAMES[row]
		var facing_degrees := rad_to_deg(facing_direction.angle()) if facing_direction.length_squared() > 0.0001 else 0.0
		debug_label.text = "E%d r%d %s %s %ddeg" % [
			(int(get_instance_id()) % 1000),
			row,
			row_name,
			debug_last_action,
			int(round(facing_degrees))
		]


func _is_debug_focus_enemy() -> bool:
	if not debug_focus_nearest_enemy_only:
		return true
	if not is_instance_valid(player):
		return true

	var closest_enemy: EnemyBase = null
	var closest_distance_sq := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		var dist_sq := enemy.global_position.distance_squared_to(player.global_position)
		if dist_sq < closest_distance_sq:
			closest_distance_sq = dist_sq
			closest_enemy = enemy
	return closest_enemy == self


func _update_attack_telegraph(to_player: Vector2) -> void:
	if not pending_attack:
		attack_telegraph.visible = false
		return

	attack_telegraph.visible = true
	var safe_windup := maxf(0.01, attack_windup)
	var progress := clampf(1.0 - (attack_windup_left / safe_windup), 0.0, 1.0)
	attack_telegraph.rotation = to_player.angle()
	attack_telegraph.width = lerpf(2.0, 7.0, progress)
	attack_telegraph.default_color = Color(0.96, lerpf(0.64, 0.3, progress), lerpf(0.36, 0.18, progress), 0.9)
	attack_telegraph.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(lerpf(12.0, attack_range + 12.0, progress), 0.0)
	])


func _die() -> void:
	dead = true
	knockback_velocity = Vector2.ZERO
	_teardown_debug_overlay()
	died.emit(self)
	queue_free()


func _start_attack_animation(duration: float, strength: float) -> void:
	attack_anim_total = maxf(0.01, duration)
	attack_anim_left = attack_anim_total
	attack_anim_strength = strength
	weapon_trail_alpha = maxf(weapon_trail_alpha, 1.0)


func _update_model_animation(delta: float, movement_ratio: float, to_player: Vector2) -> void:
	anim_time += delta
	var pace := lerpf(4.2, 10.5, movement_ratio)
	var step := sin(anim_time * pace)
	var stride: float = absf(step)
	var bob := step * 1.1 * movement_ratio
	var breathe := sin(anim_time * 2.0) * 0.4

	body_visual.position = Vector2(0.0, bob + (breathe * 0.1))
	head_visual.position = head_base_position + Vector2(0.0, bob * 0.4 + (breathe * 0.2))
	left_arm_visual.position = left_arm_base_position + Vector2(-movement_ratio * 0.5, bob * 0.2)
	right_arm_visual.position = right_arm_base_position + Vector2(movement_ratio * 0.5, bob * 0.2)
	weapon_visual.position = weapon_base_position + Vector2(0.0, bob * 0.25)
	left_leg_visual.position = left_leg_base_position + Vector2(0.0, -stride * 0.35)
	right_leg_visual.position = right_leg_base_position + Vector2(0.0, stride * 0.35)
	if rib_plate_visual != null:
		rib_plate_visual.position = rib_plate_base_position + Vector2(0.0, bob * 0.16)
	if cloth_back_visual != null:
		cloth_back_visual.position = cloth_back_base_position + Vector2(0.0, stride * 1.5 + (movement_ratio * 0.8))
	if cloth_front_visual != null:
		cloth_front_visual.position = cloth_front_base_position + Vector2(0.0, stride * 0.95)

	left_arm_visual.rotation = left_arm_base_rotation + (step * 0.35 * movement_ratio)
	right_arm_visual.rotation = right_arm_base_rotation - (step * 0.32 * movement_ratio)
	weapon_visual.rotation = weapon_base_rotation + (step * 0.18 * movement_ratio)
	left_leg_visual.rotation = left_leg_base_rotation + (step * 0.42 * movement_ratio)
	right_leg_visual.rotation = right_leg_base_rotation - (step * 0.42 * movement_ratio)
	head_visual.rotation = lerp_angle(head_visual.rotation, to_player.angle() * 0.1, clampf(delta * 10.0, 0.0, 1.0))
	if cloth_back_visual != null:
		cloth_back_visual.rotation = cloth_back_base_rotation - (step * 0.07) - (movement_ratio * 0.06)
	if cloth_front_visual != null:
		cloth_front_visual.rotation = cloth_front_base_rotation + (step * 0.06)

	if pending_attack:
		var windup_progress := clampf(1.0 - (attack_windup_left / maxf(0.01, attack_windup)), 0.0, 1.0)
		right_arm_visual.rotation += lerpf(-0.6, 0.35, windup_progress)
		weapon_visual.rotation += lerpf(-1.05, 0.25, windup_progress)
		left_leg_visual.rotation = lerp_angle(left_leg_visual.rotation, -0.35, clampf(delta * 10.0, 0.0, 1.0))
		right_leg_visual.rotation = lerp_angle(right_leg_visual.rotation, -0.22, clampf(delta * 10.0, 0.0, 1.0))
		body_visual.rotation = lerp_angle(body_visual.rotation, to_player.angle() * 0.2, clampf(delta * 12.0, 0.0, 1.0))
		if cloth_front_visual != null:
			cloth_front_visual.rotation = lerp_angle(cloth_front_visual.rotation, 0.14, clampf(delta * 12.0, 0.0, 1.0))
		if cloth_back_visual != null:
			cloth_back_visual.rotation = lerp_angle(cloth_back_visual.rotation, -0.12, clampf(delta * 12.0, 0.0, 1.0))

	if attack_anim_left > 0.0:
		var attack_progress := 1.0 - (attack_anim_left / maxf(0.01, attack_anim_total))
		var attack_swing := sin(attack_progress * PI) * attack_anim_strength
		right_arm_visual.rotation += attack_swing * 0.95
		weapon_visual.rotation += attack_swing * 1.45
		weapon_trail_alpha = maxf(weapon_trail_alpha, 0.72)
		if cloth_front_visual != null:
			cloth_front_visual.rotation += attack_swing * 0.04

	if to_player.length_squared() > 0.0001:
		body_visual.rotation = lerp_angle(body_visual.rotation, to_player.angle() * 0.16, clampf(delta * 10.0, 0.0, 1.0))
	else:
		body_visual.rotation = lerp_angle(body_visual.rotation, 0.0, clampf(delta * 8.0, 0.0, 1.0))

	var shadow_target := Vector2(1.0 + (movement_ratio * 0.06), 1.0 - (movement_ratio * 0.04))
	if pending_attack:
		shadow_target = Vector2(1.1, 0.9)
	shadow_visual.scale = shadow_visual.scale.lerp(shadow_target, clampf(delta * 10.0, 0.0, 1.0))


func _set_model_palette(body_color: Color, head_color: Color, arm_color: Color, weapon_color: Color) -> void:
	body_visual.color = body_color
	head_visual.color = head_color
	left_arm_visual.color = arm_color
	right_arm_visual.color = arm_color.darkened(0.06)
	weapon_visual.color = weapon_color
	left_leg_visual.color = body_color.darkened(0.1)
	right_leg_visual.color = body_color.darkened(0.15)
	if rib_plate_visual != null:
		rib_plate_visual.color = body_color.lerp(weapon_color, 0.28).darkened(0.06)
	if cloth_front_visual != null:
		cloth_front_visual.color = body_color.darkened(0.24)
	if cloth_back_visual != null:
		cloth_back_visual.color = body_color.darkened(0.36)


func _update_weapon_fx(delta: float) -> void:
	var slash_active := slash_effect_left > 0.0
	if slash_active:
		var slash_progress := 1.0 - (slash_effect_left / maxf(0.01, slash_effect_total))
		slash_effect.visible = true
		slash_effect.modulate.a = lerpf(0.95, 0.0, slash_progress)
		slash_effect.scale = Vector2.ONE * lerpf(0.96, 1.1, slash_progress)
	else:
		slash_effect.visible = false
		slash_effect.modulate.a = 1.0
		slash_effect.scale = Vector2.ONE

	var trail_active := weapon_trail_alpha > 0.01 or attack_anim_left > 0.0
	if trail_active:
		var tip_global := weapon_visual.to_global(Vector2(20.0, 0.0))
		weapon_trail_points.push_front(tip_global)
		while weapon_trail_points.size() > 8:
			weapon_trail_points.pop_back()

		var local_points := PackedVector2Array()
		for point in weapon_trail_points:
			local_points.append(to_local(point))
		if local_points.size() >= 2:
			weapon_trail.visible = true
			weapon_trail.points = local_points
			var alpha := clampf(weapon_trail_alpha, 0.0, 1.0)
			var target_width := lerpf(1.0, 3.4, alpha)
			weapon_trail.width = lerpf(weapon_trail.width, target_width, clampf(delta * 18.0, 0.0, 1.0))
			var target_color := Color(0.9, 0.44, 0.24, 0.2 + (alpha * 0.56))
			weapon_trail.default_color = weapon_trail.default_color.lerp(target_color, clampf(delta * 16.0, 0.0, 1.0))
		else:
			weapon_trail.visible = false
	elif weapon_trail_points.size() > 0:
		weapon_trail_points.pop_back()
		if weapon_trail_points.size() < 2:
			weapon_trail.visible = false


func _trigger_slash_effect(attack_distance: float, arc_degrees: float, color: Color, duration: float, width: float) -> void:
	slash_effect_total = maxf(0.01, duration)
	slash_effect_left = slash_effect_total
	slash_effect.visible = true
	slash_effect.default_color = color
	slash_effect.width = width
	if using_external_monster_sprite:
		slash_effect.rotation = external_sprite_facing_direction.angle()
	else:
		slash_effect.rotation = rotation
	slash_effect.points = _build_slash_points(attack_distance, arc_degrees, 16)


func _build_slash_points(attack_distance: float, arc_degrees: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := attack_distance * 0.72
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_arc, half_arc, t)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points

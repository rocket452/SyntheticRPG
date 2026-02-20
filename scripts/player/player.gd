extends CharacterBody2D
class_name Player

enum QueuedAttack {
	NONE,
	BASIC,
	ABILITY_1
}

signal health_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal cooldowns_changed(values: Dictionary)
signal died
signal item_looted(item_name: String, total_owned: int)

@export var move_speed: float = 220.0
@export var max_health: float = 120.0
@export var basic_attack_damage: float = 18.0
@export var basic_attack_range: float = 62.0
@export var basic_attack_arc_degrees: float = 90.0
@export var basic_attack_cooldown: float = 0.45
@export var basic_attack_windup: float = 0.08
@export var basic_combo_chain_window: float = 0.42

@export var ability_1_damage: float = 30.0
@export var ability_1_range: float = 84.0
@export var ability_1_arc_degrees: float = 140.0
@export var ability_1_cooldown: float = 3.0
@export var ability_1_windup: float = 0.14

@export var ability_2_damage: float = 40.0
@export var ability_2_range: float = 88.0
@export var ability_2_arc_degrees: float = 60.0
@export var ability_2_cooldown: float = 4.5
@export var ability_2_lunge_speed: float = 460.0
@export var ability_2_lunge_duration: float = 0.22

@export var roll_speed: float = 420.0
@export var roll_duration: float = 0.24
@export var roll_cooldown: float = 1.0

@export var block_arc_degrees: float = 120.0
@export var block_damage_reduction: float = 0.65
@export var block_move_multiplier: float = 0.45
@export var depth_speed_multiplier: float = 0.62
@export var lane_min_x: float = -760.0
@export var lane_max_x: float = 760.0
@export var lane_min_y: float = -165.0
@export var lane_max_y: float = 165.0
@export var attack_depth_tolerance: float = 44.0
@export var hit_stun_duration: float = 0.24
@export var outgoing_hit_stun_duration: float = 0.2
@export var hit_effect_duration: float = 0.14
@export var hit_knockback_speed: float = 250.0
@export var hit_knockback_decay: float = 1300.0
@export var blocked_knockback_move_scale: float = 0.6

@export var pickup_radius: float = 34.0
@export var health_bar_width: float = 74.0
@export var health_bar_thickness: float = 6.0
@export var health_bar_y_offset: float = -74.0

const ITEM_NAMES: Dictionary = {
	"iron_shard": "Iron Shard",
	"sturdy_hide": "Sturdy Hide",
	"swift_boots": "Swift Boots"
}

const PLAYER_HD_HFRAMES: int = 8
const PLAYER_HD_VFRAMES: int = 6
const PLAYER_SHEET: Texture2D = preload("res://assets/external/ElthenAssets/fishfolk/Fishfolk Knight Sprite Sheet.png")
const PLAYER_HD_TEXTURES: Dictionary = {
	"idle": PLAYER_SHEET,
	"run": PLAYER_SHEET,
	"attack": PLAYER_SHEET,
	"lunge": PLAYER_SHEET,
	"roll": PLAYER_SHEET,
	"hurt": PLAYER_SHEET,
	"block": PLAYER_SHEET,
	"death": PLAYER_SHEET
}
const PLAYER_HD_FPS: Dictionary = {
	"idle": 8.0,
	"run": 12.0,
	"attack": 13.0,
	"lunge": 13.0,
	"roll": 9.0,
	"hurt": 11.0,
	"block": 9.0,
	"death": 8.0
}
const PLAYER_ACTION_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"attack": 2,
	"lunge": 2,
	"roll": 4,
	"hurt": 4,
	"block": 3,
	"death": 5
}
const PLAYER_ACTION_FRAME_COUNTS: Dictionary = {
	"idle": 4,
	"run": 8,
	"attack": 7,
	"lunge": 7,
	"roll": 4,
	"hurt": 3,
	"block": 8,
	"death": 4
}
const PLAYER_ACTION_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"run": [0, 1, 2, 3, 4, 5, 6, 7],
	"attack": [1, 2, 3, 4, 5, 6],
	"lunge": [1, 2, 3, 4, 5, 6],
	"roll": [0, 1, 2, 3],
	"hurt": [1, 2, 3],
	"block": [0, 1, 2, 3, 4, 5, 6, 7],
	"death": [0, 1, 2, 3]
}
const PLAYER_BLOCK_HOLD_FRAME_INDEX: int = 3
const BASIC_COMBO_MAX_HITS: int = 3
const BASIC_COMBO_DAMAGE_MULTIPLIERS: Array = [1.0, 1.14, 1.34]
const BASIC_COMBO_RANGE_MULTIPLIERS: Array = [1.0, 1.08, 1.18]
const BASIC_COMBO_ARC_MULTIPLIERS: Array = [1.0, 1.1, 1.24]
const BASIC_COMBO_WINDUP_MULTIPLIERS: Array = [1.0, 0.9, 0.8]
const BASIC_COMBO_COOLDOWN_MULTIPLIERS: Array = [0.42, 0.5, 1.0]
const BASIC_COMBO_ANIM_DURATION_MULTIPLIERS: Array = [1.0, 1.06, 1.2]
const BASIC_COMBO_ANIM_STRENGTH_MULTIPLIERS: Array = [1.0, 1.18, 1.36]
const BASIC_ATTACK_BASE_ANIM_DURATION: float = 0.18
const BASIC_ATTACK_BASE_ANIM_STRENGTH: float = 1.05

var current_health: float = 0.0
var current_xp: int = 0
var xp_to_next_level: int = 100
var level: int = 1
var inventory: Dictionary = {}

var facing_direction: Vector2 = Vector2.RIGHT
var is_blocking: bool = false
var is_rolling: bool = false
var is_invulnerable: bool = false
var is_dead: bool = false

var basic_attack_cooldown_left: float = 0.0
var ability_1_cooldown_left: float = 0.0
var ability_2_cooldown_left: float = 0.0
var roll_cooldown_left: float = 0.0

var roll_time_left: float = 0.0
var roll_vector: Vector2 = Vector2.ZERO

var queued_attack: QueuedAttack = QueuedAttack.NONE
var attack_windup_left: float = 0.0
var attack_windup_total: float = 0.0
var queued_melee_hit_pending: bool = false
var queued_melee_hit_damage: float = 0.0
var queued_melee_hit_range: float = 0.0
var queued_melee_hit_arc_degrees: float = 0.0
var basic_combo_step: int = 0
var basic_combo_window_left: float = 0.0
var basic_combo_buffered: bool = false
var queued_basic_combo_hit_index: int = 1
var queued_basic_combo_damage: float = 0.0
var queued_basic_combo_range: float = 0.0
var queued_basic_combo_arc_degrees: float = 0.0

var lunge_time_left: float = 0.0
var lunge_direction: Vector2 = Vector2.ZERO
var lunge_strike_applied: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

var hit_flash_left: float = 0.0
var stun_left: float = 0.0
var anim_time: float = 0.0
var attack_anim_left: float = 0.0
var attack_anim_total: float = 0.0
var attack_anim_strength: float = 1.0
var slash_effect_left: float = 0.0
var slash_effect_total: float = 0.0
var weapon_trail_alpha: float = 0.0
var weapon_trail_points: Array[Vector2] = []
var last_step_phase_sign: int = 1
var player_sprite_anim_key: String = ""
var player_sprite_anim_time: float = 0.0
var using_external_player_sprite: bool = false
var character_sprite_base_position: Vector2 = Vector2.ZERO

var head_base_position: Vector2 = Vector2.ZERO
var cape_base_position: Vector2 = Vector2.ZERO
var left_arm_base_position: Vector2 = Vector2.ZERO
var right_arm_base_position: Vector2 = Vector2.ZERO
var blade_base_position: Vector2 = Vector2.ZERO
var left_leg_base_position: Vector2 = Vector2.ZERO
var right_leg_base_position: Vector2 = Vector2.ZERO
var left_boot_base_position: Vector2 = Vector2.ZERO
var right_boot_base_position: Vector2 = Vector2.ZERO
var neck_guard_base_position: Vector2 = Vector2.ZERO
var chest_plate_base_position: Vector2 = Vector2.ZERO
var gem_base_position: Vector2 = Vector2.ZERO
var tabard_front_base_position: Vector2 = Vector2.ZERO
var tabard_back_base_position: Vector2 = Vector2.ZERO

var cape_base_rotation: float = 0.0
var left_arm_base_rotation: float = 0.0
var right_arm_base_rotation: float = 0.0
var blade_base_rotation: float = 0.0
var left_leg_base_rotation: float = 0.0
var right_leg_base_rotation: float = 0.0
var left_boot_base_rotation: float = 0.0
var right_boot_base_rotation: float = 0.0
var neck_guard_base_rotation: float = 0.0
var chest_plate_base_rotation: float = 0.0
var tabard_front_base_rotation: float = 0.0
var tabard_back_base_rotation: float = 0.0
var gem_base_scale: Vector2 = Vector2.ONE
var blade_rune_base_scale: Vector2 = Vector2.ONE

var torso_shade_base_alpha: float = 1.0
var torso_highlight_base_alpha: float = 1.0
var blade_edge_base_alpha: float = 1.0
var blade_rune_base_alpha: float = 1.0
var cape_trim_base_alpha: float = 1.0
var chest_plate_inset_base_alpha: float = 1.0
var cape_fold_base_alpha: float = 1.0
var health_bar_root: Node2D = null
var health_bar_background: Line2D = null
var health_bar_fill: Line2D = null

@onready var shadow_visual: Polygon2D = $Shadow
@onready var body_visual: Polygon2D = $Body
@onready var torso_shade_visual: Polygon2D = $Body/TorsoShade
@onready var torso_highlight_visual: Polygon2D = $Body/TorsoHighlight
@onready var head_visual: Polygon2D = $Body/Head
@onready var cape_visual: Polygon2D = $Body/Cape
@onready var cape_trim_visual: Polygon2D = $Body/Cape/CapeTrim
@onready var cape_fold_visual: Polygon2D = $Body/Cape/CapeFold
@onready var neck_guard_visual: Polygon2D = $Body/NeckGuard
@onready var neck_trim_visual: Polygon2D = $Body/NeckGuard/NeckTrim
@onready var chest_plate_visual: Polygon2D = $Body/ChestPlate
@onready var chest_plate_inset_visual: Polygon2D = $Body/ChestPlate/ChestPlateInset
@onready var gem_visual: Polygon2D = $Body/Gem
@onready var belt_pouch_visual: Polygon2D = $Body/BeltPouch
@onready var tabard_front_visual: Polygon2D = $Body/TabardFront
@onready var tabard_back_visual: Polygon2D = $Body/TabardBack
@onready var left_arm_visual: Polygon2D = $Body/LeftArm
@onready var right_arm_visual: Polygon2D = $Body/RightArm
@onready var blade_visual: Polygon2D = $Body/Blade
@onready var blade_edge_visual: Polygon2D = $Body/Blade/BladeEdge
@onready var blade_rune_visual: Polygon2D = $Body/Blade/BladeRune
@onready var blade_pommel_visual: Polygon2D = $Body/Blade/BladePommel
@onready var left_leg_visual: Polygon2D = $Body/LeftLeg
@onready var right_leg_visual: Polygon2D = $Body/RightLeg
@onready var left_boot_visual: Polygon2D = $Body/LeftBoot
@onready var right_boot_visual: Polygon2D = $Body/RightBoot
@onready var weapon_trail: Line2D = $WeaponTrail
@onready var slash_effect: Line2D = $SlashEffect
@onready var block_indicator: Line2D = $BlockIndicator
@onready var attack_telegraph: Polygon2D = $AttackTelegraph
@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var camera_2d: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	attack_telegraph.visible = false
	using_external_player_sprite = is_instance_valid(character_sprite)
	if using_external_player_sprite:
		body_visual.visible = false
		character_sprite.visible = true
		character_sprite_base_position = character_sprite.position
	else:
		body_visual.visible = true
	head_base_position = head_visual.position
	cape_base_position = cape_visual.position
	left_arm_base_position = left_arm_visual.position
	right_arm_base_position = right_arm_visual.position
	blade_base_position = blade_visual.position
	left_leg_base_position = left_leg_visual.position
	right_leg_base_position = right_leg_visual.position
	left_boot_base_position = left_boot_visual.position
	right_boot_base_position = right_boot_visual.position
	neck_guard_base_position = neck_guard_visual.position
	chest_plate_base_position = chest_plate_visual.position
	gem_base_position = gem_visual.position
	tabard_front_base_position = tabard_front_visual.position
	tabard_back_base_position = tabard_back_visual.position
	cape_base_rotation = cape_visual.rotation
	left_arm_base_rotation = left_arm_visual.rotation
	right_arm_base_rotation = right_arm_visual.rotation
	blade_base_rotation = blade_visual.rotation
	left_leg_base_rotation = left_leg_visual.rotation
	right_leg_base_rotation = right_leg_visual.rotation
	left_boot_base_rotation = left_boot_visual.rotation
	right_boot_base_rotation = right_boot_visual.rotation
	neck_guard_base_rotation = neck_guard_visual.rotation
	chest_plate_base_rotation = chest_plate_visual.rotation
	tabard_front_base_rotation = tabard_front_visual.rotation
	tabard_back_base_rotation = tabard_back_visual.rotation
	gem_base_scale = gem_visual.scale
	blade_rune_base_scale = blade_rune_visual.scale
	torso_shade_base_alpha = torso_shade_visual.color.a
	torso_highlight_base_alpha = torso_highlight_visual.color.a
	blade_edge_base_alpha = blade_edge_visual.color.a
	blade_rune_base_alpha = blade_rune_visual.color.a
	cape_trim_base_alpha = cape_trim_visual.color.a
	chest_plate_inset_base_alpha = chest_plate_inset_visual.color.a
	cape_fold_base_alpha = cape_fold_visual.color.a
	weapon_trail.visible = false
	slash_effect.visible = false
	_setup_health_bar()
	_update_health_bar()
	emit_initial_state()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_tick_timers(delta)
	_update_facing_direction()
	if stun_left > 0.0:
		_interrupt_combat_for_stun()
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	else:
		_handle_actions()
		_apply_movement()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	move_and_slide()
	_clamp_to_lane()
	_update_health_bar()
	_collect_nearby_pickups()
	_update_visual_feedback(delta)
	_emit_cooldown_state()


func emit_initial_state() -> void:
	health_changed.emit(current_health, max_health)
	xp_changed.emit(current_xp, xp_to_next_level, level)
	_emit_cooldown_state()


func set_arena_bounds(min_x: float, max_x: float, min_y: float, max_y: float) -> void:
	lane_min_x = minf(min_x, max_x)
	lane_max_x = maxf(min_x, max_x)
	lane_min_y = minf(min_y, max_y)
	lane_max_y = maxf(min_y, max_y)


func configure_camera_limits(left: float, top: float, right: float, bottom: float) -> void:
	if not is_instance_valid(camera_2d):
		return
	camera_2d.limit_left = int(floor(left))
	camera_2d.limit_top = int(floor(top))
	camera_2d.limit_right = int(ceil(right))
	camera_2d.limit_bottom = int(ceil(bottom))


func _setup_health_bar() -> void:
	health_bar_root = Node2D.new()
	health_bar_root.name = "PlayerHealthBar"
	health_bar_root.top_level = true
	health_bar_root.z_index = 260
	add_child(health_bar_root)

	health_bar_background = Line2D.new()
	health_bar_background.default_color = Color(0.08, 0.08, 0.08, 0.92)
	health_bar_background.width = health_bar_thickness
	health_bar_background.z_index = 0
	health_bar_background.begin_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_background.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(health_bar_background)

	health_bar_fill = Line2D.new()
	health_bar_fill.default_color = Color(0.24, 0.92, 0.34, 0.95)
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


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		_level_up()

	xp_changed.emit(current_xp, xp_to_next_level, level)


func collect_item(item_id: String, value: int) -> void:
	var total := int(inventory.get(item_id, 0)) + value
	inventory[item_id] = total
	_apply_item_bonus(item_id, value)
	item_looted.emit(String(ITEM_NAMES.get(item_id, item_id)), total)
	health_changed.emit(current_health, max_health)


func needs_healing(threshold_ratio: float = 0.999) -> bool:
	if is_dead:
		return false
	var clamped_threshold := clampf(threshold_ratio, 0.0, 1.0)
	return current_health < (max_health * clamped_threshold)


func receive_heal(amount: float) -> bool:
	if is_dead:
		return false
	if amount <= 0.0:
		return false

	var previous_health := current_health
	current_health = minf(max_health, current_health + amount)
	if current_health <= previous_health + 0.001:
		return false

	health_changed.emit(current_health, max_health)
	_update_health_bar()
	_spawn_hit_effect(global_position + Vector2(0.0, -14.0), Color(0.36, 0.95, 0.56, 0.92), 8.0)
	return true


func receive_hit(amount: float, source_position: Vector2, guard_break: bool = false, stun_duration: float = 0.0) -> bool:
	if is_dead:
		return false
	if is_invulnerable:
		return false

	var damage_to_apply := amount
	var blocked := false
	if is_blocking and not guard_break:
		var incoming_direction := (source_position - global_position).normalized()
		var block_threshold := cos(deg_to_rad(block_arc_degrees * 0.5))
		if facing_direction.dot(incoming_direction) >= block_threshold:
			damage_to_apply *= (1.0 - block_damage_reduction)
			blocked = true

	if damage_to_apply <= 0.0:
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.LEFT if facing_direction.x >= 0.0 else Vector2.RIGHT
	var knockback_strength := hit_knockback_speed * (0.45 if blocked else 1.0)
	knockback_velocity = knockback_direction * knockback_strength

	current_health = maxf(0.0, current_health - damage_to_apply)
	health_changed.emit(current_health, max_health)
	hit_flash_left = 0.12
	var applied_stun := 0.0 if blocked else maxf(hit_stun_duration, stun_duration)
	if not blocked:
		applied_stun = maxf(applied_stun, _get_hurt_animation_duration())
	if applied_stun > 0.0:
		stun_left = maxf(stun_left, applied_stun)
		_interrupt_combat_for_stun()
		basic_attack_cooldown_left = maxf(basic_attack_cooldown_left, stun_left)
		ability_1_cooldown_left = maxf(ability_1_cooldown_left, stun_left)
		ability_2_cooldown_left = maxf(ability_2_cooldown_left, stun_left)
	attack_anim_left = 0.0
	weapon_trail_alpha = 0.0
	weapon_trail.visible = false
	slash_effect.visible = false
	is_rolling = false
	is_invulnerable = false
	_spawn_hit_effect(global_position + Vector2(0.0, -14.0), Color(1.0, 0.42, 0.3, 0.95), 10.0)

	if current_health <= 0.0:
		_die()

	return true


func _get_hurt_animation_duration() -> float:
	var frame_columns: Array = PLAYER_ACTION_FRAME_COLUMNS.get("hurt", [])
	var frame_count := frame_columns.size() if not frame_columns.is_empty() else int(PLAYER_ACTION_FRAME_COUNTS.get("hurt", 0))
	var fps := float(PLAYER_HD_FPS.get("hurt", 0.0))
	if frame_count <= 0 or fps <= 0.0:
		return hit_stun_duration
	return float(frame_count) / fps


func _tick_timers(delta: float) -> void:
	basic_attack_cooldown_left = maxf(0.0, basic_attack_cooldown_left - delta)
	ability_1_cooldown_left = maxf(0.0, ability_1_cooldown_left - delta)
	ability_2_cooldown_left = maxf(0.0, ability_2_cooldown_left - delta)
	roll_cooldown_left = maxf(0.0, roll_cooldown_left - delta)
	basic_combo_window_left = maxf(0.0, basic_combo_window_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	attack_anim_left = maxf(0.0, attack_anim_left - delta)
	slash_effect_left = maxf(0.0, slash_effect_left - delta)
	weapon_trail_alpha = maxf(0.0, weapon_trail_alpha - (delta * 1.35))
	if basic_combo_window_left <= 0.0 and attack_windup_left <= 0.0 and attack_anim_left <= 0.0:
		basic_combo_step = 0
	if queued_melee_hit_pending and attack_windup_left <= 0.0 and attack_anim_left <= 0.0:
		_apply_queued_melee_hit()

	if attack_windup_left > 0.0:
		attack_windup_left -= delta
		if attack_windup_left <= 0.0:
			attack_windup_left = 0.0
			_resolve_queued_attack()
		else:
			_update_attack_telegraph_progress()

	if is_rolling:
		roll_time_left -= delta
		if roll_time_left <= 0.0:
			is_rolling = false
			is_invulnerable = false

	if lunge_time_left > 0.0:
		lunge_time_left -= delta
		if lunge_time_left <= 0.0:
			lunge_time_left = 0.0
			_apply_lunge_strike()

	if basic_combo_buffered and basic_attack_cooldown_left <= 0.0 and attack_windup_left <= 0.0 and attack_anim_left <= 0.0 and queued_attack == QueuedAttack.NONE and not is_rolling and lunge_time_left <= 0.0 and stun_left <= 0.0 and not is_blocking:
		_start_basic_combo_attack()


func _handle_actions() -> void:
	if is_rolling or lunge_time_left > 0.0 or attack_windup_left > 0.0:
		is_blocking = false
		return

	if Input.is_action_just_pressed("roll") and roll_cooldown_left <= 0.0:
		_start_roll()
		return

	is_blocking = Input.is_action_pressed("block")
	if is_blocking:
		return

	if Input.is_action_just_pressed("basic_attack"):
		if basic_attack_cooldown_left <= 0.0 and attack_anim_left <= 0.0:
			_start_basic_combo_attack()
		else:
			basic_combo_buffered = true
		return

	if Input.is_action_just_pressed("ability_1") and ability_1_cooldown_left <= 0.0:
		_reset_basic_combo_state()
		ability_1_cooldown_left = ability_1_cooldown
		_queue_attack(QueuedAttack.ABILITY_1, ability_1_windup, ability_1_range, ability_1_arc_degrees, Color(0.68, 0.8, 0.92, 0.36))
		return

	if Input.is_action_just_pressed("ability_2") and ability_2_cooldown_left <= 0.0:
		_reset_basic_combo_state()
		ability_2_cooldown_left = ability_2_cooldown
		_start_lunge()


func _queue_attack(kind: QueuedAttack, windup: float, attack_range: float, arc_degrees: float, telegraph_color: Color) -> void:
	queued_attack = kind
	attack_windup_total = maxf(0.01, windup)
	attack_windup_left = attack_windup_total
	_show_attack_telegraph(attack_range, arc_degrees, telegraph_color)


func _start_basic_combo_attack() -> void:
	var combo_hit := 1
	if basic_combo_window_left > 0.0 and basic_combo_step > 0:
		combo_hit = mini(BASIC_COMBO_MAX_HITS, basic_combo_step + 1)

	var combo_index := combo_hit - 1
	var damage_multiplier := float(BASIC_COMBO_DAMAGE_MULTIPLIERS[combo_index])
	var range_multiplier := float(BASIC_COMBO_RANGE_MULTIPLIERS[combo_index])
	var arc_multiplier := float(BASIC_COMBO_ARC_MULTIPLIERS[combo_index])
	var windup_multiplier := float(BASIC_COMBO_WINDUP_MULTIPLIERS[combo_index])
	var cooldown_multiplier := float(BASIC_COMBO_COOLDOWN_MULTIPLIERS[combo_index])

	queued_basic_combo_hit_index = combo_hit
	queued_basic_combo_damage = basic_attack_damage * damage_multiplier
	queued_basic_combo_range = basic_attack_range * range_multiplier
	queued_basic_combo_arc_degrees = basic_attack_arc_degrees * arc_multiplier

	basic_attack_cooldown_left = maxf(0.01, basic_attack_cooldown * cooldown_multiplier)
	_queue_attack(
		QueuedAttack.BASIC,
		maxf(0.01, basic_attack_windup * windup_multiplier),
		queued_basic_combo_range,
		queued_basic_combo_arc_degrees,
		Color(0.94, 0.66, 0.34, 0.34)
	)
	basic_combo_buffered = false

	if combo_hit >= BASIC_COMBO_MAX_HITS:
		basic_combo_step = 0
		basic_combo_window_left = 0.0
	else:
		basic_combo_step = combo_hit
		basic_combo_window_left = basic_combo_chain_window


func _resolve_queued_attack() -> void:
	match queued_attack:
		QueuedAttack.BASIC:
			var combo_hit := clampi(queued_basic_combo_hit_index, 1, BASIC_COMBO_MAX_HITS)
			var combo_index := combo_hit - 1
			var combo_damage := queued_basic_combo_damage if queued_basic_combo_damage > 0.0 else basic_attack_damage
			var combo_range := queued_basic_combo_range if queued_basic_combo_range > 0.0 else basic_attack_range
			var combo_arc := queued_basic_combo_arc_degrees if queued_basic_combo_arc_degrees > 0.0 else basic_attack_arc_degrees
			_queue_melee_hit_for_final_attack_frame(combo_damage, combo_range, combo_arc)
			var combo_anim_duration := BASIC_ATTACK_BASE_ANIM_DURATION * float(BASIC_COMBO_ANIM_DURATION_MULTIPLIERS[combo_index])
			var combo_anim_strength := BASIC_ATTACK_BASE_ANIM_STRENGTH * float(BASIC_COMBO_ANIM_STRENGTH_MULTIPLIERS[combo_index])
			_start_attack_animation(combo_anim_duration, combo_anim_strength)
			if not using_external_player_sprite:
				var slash_duration := 0.16 + (0.02 * float(combo_index))
				var slash_width := 4.8 + (0.7 * float(combo_index))
				_trigger_slash_effect(combo_range, combo_arc, Color(0.94, 0.66, 0.34, 0.88), slash_duration, slash_width)
			_clear_queued_basic_combo_attack()
		QueuedAttack.ABILITY_1:
			_queue_melee_hit_for_final_attack_frame(ability_1_damage, ability_1_range, ability_1_arc_degrees)
			_start_attack_animation(0.24, 1.45)
			if not using_external_player_sprite:
				_trigger_slash_effect(ability_1_range, ability_1_arc_degrees, Color(0.84, 0.72, 0.52, 0.9), 0.22, 6.2)
		_:
			pass

	queued_attack = QueuedAttack.NONE
	attack_telegraph.visible = false
	attack_telegraph.modulate.a = 1.0
	attack_telegraph.scale = Vector2.ONE


func _queue_melee_hit_for_final_attack_frame(damage: float, attack_range: float, arc_degrees: float) -> void:
	queued_melee_hit_pending = true
	queued_melee_hit_damage = damage
	queued_melee_hit_range = attack_range
	queued_melee_hit_arc_degrees = arc_degrees


func _clear_queued_melee_hit() -> void:
	queued_melee_hit_pending = false
	queued_melee_hit_damage = 0.0
	queued_melee_hit_range = 0.0
	queued_melee_hit_arc_degrees = 0.0


func _apply_queued_melee_hit() -> void:
	if not queued_melee_hit_pending:
		return
	var damage := queued_melee_hit_damage
	var attack_range := queued_melee_hit_range
	var arc_degrees := queued_melee_hit_arc_degrees
	_clear_queued_melee_hit()
	_apply_melee_strike(damage, attack_range, arc_degrees)


func _clear_queued_basic_combo_attack() -> void:
	queued_basic_combo_hit_index = 1
	queued_basic_combo_damage = 0.0
	queued_basic_combo_range = 0.0
	queued_basic_combo_arc_degrees = 0.0


func _reset_basic_combo_state() -> void:
	basic_combo_step = 0
	basic_combo_window_left = 0.0
	basic_combo_buffered = false
	_clear_queued_basic_combo_attack()


func _apply_lunge_strike() -> void:
	if lunge_strike_applied:
		return
	lunge_strike_applied = true
	_apply_melee_strike(ability_2_damage, ability_2_range, ability_2_arc_degrees)
	_show_instant_attack_flash(ability_2_range, ability_2_arc_degrees, Color(0.98, 0.48, 0.28, 0.34))
	_start_attack_animation(0.22, 1.9)
	if not using_external_player_sprite:
		_trigger_slash_effect(ability_2_range, ability_2_arc_degrees, Color(0.98, 0.56, 0.34, 0.92), 0.18, 6.0)


func _show_attack_telegraph(attack_range: float, arc_degrees: float, telegraph_color: Color) -> void:
	attack_telegraph.visible = true
	attack_telegraph.color = telegraph_color
	attack_telegraph.polygon = _build_arc_polygon(attack_range, arc_degrees, 18)
	attack_telegraph.rotation = facing_direction.angle()
	attack_telegraph.modulate.a = 0.25


func _show_instant_attack_flash(attack_range: float, arc_degrees: float, telegraph_color: Color) -> void:
	attack_telegraph.visible = true
	attack_telegraph.color = telegraph_color
	attack_telegraph.polygon = _build_arc_polygon(attack_range, arc_degrees, 16)
	attack_telegraph.rotation = facing_direction.angle()
	attack_telegraph.modulate.a = 0.7
	var tween := create_tween()
	tween.tween_property(attack_telegraph, "modulate:a", 0.0, 0.08)
	tween.finished.connect(func() -> void:
		if queued_attack == QueuedAttack.NONE and attack_windup_left <= 0.0:
			attack_telegraph.visible = false
			attack_telegraph.modulate.a = 1.0
	)


func _update_attack_telegraph_progress() -> void:
	if not attack_telegraph.visible:
		return
	attack_telegraph.rotation = facing_direction.angle()
	var progress := 1.0 - (attack_windup_left / attack_windup_total)
	attack_telegraph.modulate.a = lerpf(0.25, 0.85, clampf(progress, 0.0, 1.0))
	attack_telegraph.scale = Vector2.ONE * lerpf(0.92, 1.02, progress)


func _build_arc_polygon(attack_range: float, arc_degrees: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_arc, half_arc, t)
		points.append(Vector2.RIGHT.rotated(angle) * attack_range)
	return points


func _start_roll() -> void:
	var movement_vector := _get_movement_vector()
	if movement_vector == Vector2.ZERO:
		movement_vector = facing_direction

	roll_vector = movement_vector.normalized()
	is_rolling = true
	is_invulnerable = true
	roll_time_left = roll_duration
	roll_cooldown_left = roll_cooldown
	is_blocking = false
	queued_attack = QueuedAttack.NONE
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	attack_telegraph.visible = false
	slash_effect_left = 0.0
	weapon_trail_alpha = maxf(weapon_trail_alpha, 0.38)


func _start_lunge() -> void:
	lunge_direction = Vector2(signf(facing_direction.x), 0.0)
	if lunge_direction.x == 0.0:
		lunge_direction = Vector2.RIGHT
	lunge_time_left = ability_2_lunge_duration
	lunge_strike_applied = false
	is_blocking = false
	queued_attack = QueuedAttack.NONE
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	attack_telegraph.visible = false
	weapon_trail_alpha = maxf(weapon_trail_alpha, 0.72)


func _interrupt_combat_for_stun() -> void:
	is_blocking = false
	queued_attack = QueuedAttack.NONE
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	attack_telegraph.visible = false
	lunge_time_left = 0.0
	lunge_strike_applied = false


func _apply_movement() -> void:
	if is_rolling:
		var lane_roll := Vector2(roll_vector.x, roll_vector.y * depth_speed_multiplier)
		if lane_roll.length_squared() > 1.0:
			lane_roll = lane_roll.normalized()
		velocity = lane_roll * roll_speed
		return

	if lunge_time_left > 0.0:
		velocity = Vector2(signf(lunge_direction.x), 0.0) * ability_2_lunge_speed
		return

	var movement_vector := _get_movement_vector()
	movement_vector.y *= depth_speed_multiplier
	if movement_vector.length_squared() > 1.0:
		movement_vector = movement_vector.normalized()
	var movement_multiplier := block_move_multiplier if is_blocking else 1.0
	if attack_windup_left > 0.0:
		movement_multiplier *= 0.72
	velocity = movement_vector * move_speed * movement_multiplier
	if is_blocking and knockback_velocity.length_squared() > 0.0001:
		velocity += knockback_velocity * blocked_knockback_move_scale


func _clamp_to_lane() -> void:
	position.x = clampf(position.x, lane_min_x, lane_max_x)
	position.y = clampf(position.y, lane_min_y, lane_max_y)


func _get_movement_vector() -> Vector2:
	var movement_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if movement_vector.length_squared() > 1.0:
		movement_vector = movement_vector.normalized()
	return movement_vector


func _update_facing_direction() -> void:
	# Keep the current facing while guarding or in hit-stun so knockback does not flip orientation.
	if stun_left > 0.0 or is_blocking:
		return
	var movement_vector := _get_movement_vector()
	if absf(movement_vector.x) > 0.08:
		facing_direction = Vector2.RIGHT if movement_vector.x > 0.0 else Vector2.LEFT
		return
	if absf(velocity.x) > 0.08:
		facing_direction = Vector2.RIGHT if velocity.x > 0.0 else Vector2.LEFT


func _apply_melee_strike(damage: float, attack_range: float, arc_degrees: float) -> void:
	var facing := facing_direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	var arc_threshold := cos(deg_to_rad(arc_degrees * 0.5))
	var hit_ids: Dictionary = {}
	for result in _query_attack_hits(attack_range):
		var enemy := result.get("collider") as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if hit_ids.has(enemy_id):
			continue

		var to_enemy: Vector2 = enemy.global_position - global_position
		if absf(to_enemy.y) > attack_depth_tolerance:
			continue
		if to_enemy.length_squared() > attack_range * attack_range:
			continue
		if to_enemy.length_squared() > 0.0001 and facing.dot(to_enemy.normalized()) < arc_threshold:
			continue

		hit_ids[enemy_id] = true
		if enemy.receive_hit(damage, global_position, 0.0, false):
			_spawn_hit_effect(enemy.global_position + Vector2(0.0, -12.0), Color(1.0, 0.8, 0.44, 0.95), 9.0)
			if not is_dead and enemy.can_trade_melee_with(self):
				receive_hit(enemy.get_trade_damage(), enemy.global_position, false, enemy.get_trade_stun_duration())
				if is_dead:
					return


func _query_attack_hits(attack_range: float) -> Array:
	var world := get_world_2d()
	if world == null:
		return []
	var hit_shape := CircleShape2D.new()
	hit_shape.radius = maxf(4.0, attack_range)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return world.direct_space_state.intersect_shape(query, 32)


func _collect_nearby_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(pickup):
			continue
		if pickup.global_position.distance_to(global_position) > pickup_radius:
			continue
		if pickup.has_method("try_collect"):
			pickup.try_collect(self)


func _apply_item_bonus(item_id: String, value: int) -> void:
	match item_id:
		"iron_shard":
			basic_attack_damage += 0.5 * float(value)
			ability_1_damage += 0.6 * float(value)
		"sturdy_hide":
			max_health += 4.0 * float(value)
			current_health = minf(max_health, current_health + (4.0 * float(value)))
		"swift_boots":
			move_speed += 4.0 * float(value)
		_:
			pass


func _level_up() -> void:
	level += 1
	xp_to_next_level = int(ceil(float(xp_to_next_level) * 1.35))
	max_health += 14.0
	current_health = max_health
	basic_attack_damage += 1.4
	ability_1_damage += 2.2
	ability_2_damage += 2.6
	health_changed.emit(current_health, max_health)


func _update_visual_feedback(delta: float) -> void:
	block_indicator.rotation = 0.0 if facing_direction.x >= 0.0 else PI
	var movement_ratio := clampf(velocity.length() / maxf(1.0, move_speed), 0.0, 1.0)
	_update_player_sprite(delta, movement_ratio)

	var target_scale := Vector2.ONE
	if is_blocking:
		target_scale = Vector2(0.95, 1.05)
		block_indicator.default_color = Color(0.66, 0.74, 0.86, 0.95)
	elif is_rolling:
		target_scale = Vector2(1.15, 0.84)
		block_indicator.default_color = Color(0.84, 0.7, 0.52, 0.85)
	elif lunge_time_left > 0.0:
		target_scale = Vector2(1.18, 0.82)
		block_indicator.default_color = Color(0.88, 0.6, 0.42, 0.9)
	elif attack_windup_left > 0.0:
		target_scale = Vector2(1.08, 0.9)
		block_indicator.default_color = Color(0.82, 0.66, 0.46, 0.88)
	else:
		block_indicator.default_color = Color(0.42, 0.42, 0.48, 0.45)

	if hit_flash_left > 0.0:
		_set_model_palette(
			Color(0.7, 0.28, 0.28, 1.0),
			Color(0.82, 0.6, 0.58, 1.0),
			Color(0.62, 0.32, 0.34, 1.0),
			Color(0.78, 0.72, 0.7, 1.0),
			Color(0.26, 0.14, 0.16, 1.0)
		)
	elif is_blocking:
		_set_model_palette(
			Color(0.32, 0.36, 0.5, 1.0),
			Color(0.84, 0.76, 0.66, 1.0),
			Color(0.46, 0.54, 0.68, 1.0),
			Color(0.76, 0.8, 0.88, 1.0),
			Color(0.12, 0.14, 0.22, 1.0)
		)
	elif is_rolling:
		_set_model_palette(
			Color(0.36, 0.4, 0.48, 1.0),
			Color(0.82, 0.74, 0.66, 1.0),
			Color(0.48, 0.54, 0.62, 1.0),
			Color(0.76, 0.8, 0.86, 1.0),
			Color(0.16, 0.18, 0.26, 1.0)
		)
	elif lunge_time_left > 0.0:
		_set_model_palette(
			Color(0.34, 0.3, 0.28, 1.0),
			Color(0.86, 0.76, 0.66, 1.0),
			Color(0.48, 0.4, 0.36, 1.0),
			Color(0.84, 0.68, 0.46, 1.0),
			Color(0.2, 0.14, 0.12, 1.0)
		)
	elif attack_windup_left > 0.0:
		_set_model_palette(
			Color(0.38, 0.34, 0.3, 1.0),
			Color(0.86, 0.77, 0.67, 1.0),
			Color(0.52, 0.46, 0.4, 1.0),
			Color(0.86, 0.72, 0.48, 1.0),
			Color(0.22, 0.16, 0.14, 1.0)
		)
	else:
		_set_model_palette(
			Color(0.28, 0.33, 0.44, 1.0),
			Color(0.84, 0.76, 0.66, 1.0),
			Color(0.38, 0.44, 0.56, 1.0),
			Color(0.76, 0.79, 0.84, 1.0),
			Color(0.14, 0.12, 0.16, 1.0)
		)

	_update_model_animation(delta, movement_ratio)
	scale = scale.lerp(target_scale, clampf(delta * 14.0, 0.0, 1.0))
	_update_weapon_fx(delta)


func _emit_cooldown_state() -> void:
	cooldowns_changed.emit({
		"basic": basic_attack_cooldown_left,
		"ability_1": ability_1_cooldown_left,
		"ability_2": ability_2_cooldown_left,
		"roll": roll_cooldown_left,
		"block_active": is_blocking
	})


func _die() -> void:
	is_dead = true
	is_blocking = false
	is_rolling = false
	is_invulnerable = false
	_reset_basic_combo_state()
	knockback_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	weapon_trail.visible = false
	slash_effect.visible = false
	gem_visual.scale = gem_base_scale
	blade_rune_visual.scale = blade_rune_base_scale
	blade_pommel_visual.scale = Vector2.ONE
	if using_external_player_sprite:
		_update_player_sprite(0.0, 0.0)
	_set_model_palette(
		Color(0.45, 0.45, 0.45, 1.0),
		Color(0.45, 0.45, 0.45, 1.0),
		Color(0.4, 0.4, 0.4, 1.0),
		Color(0.5, 0.5, 0.5, 1.0),
		Color(0.26, 0.26, 0.26, 1.0)
	)
	died.emit()


func _start_attack_animation(duration: float, strength: float) -> void:
	attack_anim_total = maxf(0.01, duration)
	attack_anim_left = attack_anim_total
	attack_anim_strength = strength
	if not using_external_player_sprite:
		weapon_trail_alpha = maxf(weapon_trail_alpha, 1.0)


func _update_model_animation(delta: float, movement_ratio: float) -> void:
	anim_time += delta
	var pace := lerpf(4.4, 13.4, movement_ratio)
	var step := sin(anim_time * pace)
	var stride: float = absf(step)
	var bob := step * 1.35 * movement_ratio
	var sway := sin(anim_time * pace * 0.5) * 0.08
	var breathe := sin(anim_time * 2.15) * 0.7
	var attack_progress := 0.0
	if attack_anim_left > 0.0:
		attack_progress = 1.0 - (attack_anim_left / maxf(0.01, attack_anim_total))
	var attack_swing := sin(attack_progress * PI) * attack_anim_strength
	var anticipation := 0.0
	if attack_anim_left > 0.0 and attack_progress < 0.3:
		anticipation = 1.0 - (attack_progress / 0.3)
	var windup_progress := 0.0
	if attack_windup_left > 0.0:
		windup_progress = 1.0 - (attack_windup_left / maxf(0.01, attack_windup_total))
	var charge_strength := 0.0
	if lunge_time_left > 0.0:
		charge_strength = 1.0 - (lunge_time_left / maxf(0.01, ability_2_lunge_duration))
	var combat_energy := clampf((anticipation * 0.45) + (attack_swing * 0.5) + (windup_progress * 0.55) + (charge_strength * 0.65), 0.0, 1.0)
	var glint_pulse := 0.5 + (sin((anim_time * 7.8) + (attack_progress * 7.0)) * 0.5)
	var rune_pulse := 0.5 + (sin((anim_time * 9.4) + (attack_progress * 9.0)) * 0.5)

	var phase_sign: int = 1 if step >= 0.0 else -1
	if phase_sign != last_step_phase_sign and movement_ratio > 0.58:
		shadow_visual.scale += Vector2(0.03, -0.04)
	last_step_phase_sign = phase_sign

	body_visual.position = Vector2(0.0, bob + (breathe * 0.15))
	head_visual.position = head_base_position + Vector2(0.0, bob * 0.55 + (breathe * 0.35))
	neck_guard_visual.position = neck_guard_base_position + Vector2(0.0, bob * 0.35)
	chest_plate_visual.position = chest_plate_base_position + Vector2(0.0, bob * 0.22)
	gem_visual.position = gem_base_position + Vector2(0.0, bob * 0.2 - (stride * 0.2))
	cape_visual.position = cape_base_position + Vector2(-1.5 - (movement_ratio * 1.2), stride * 2.2 + (2.0 if is_rolling else 0.0))
	tabard_back_visual.position = tabard_back_base_position + Vector2(0.0, stride * 1.8 + movement_ratio * 1.2)
	tabard_front_visual.position = tabard_front_base_position + Vector2(0.0, stride * 1.15)

	cape_visual.rotation = cape_base_rotation + (step * 0.12) + sway - (velocity.length() * 0.0004)
	cape_trim_visual.rotation = (-cape_visual.rotation * 0.22) + (step * 0.04)
	cape_fold_visual.rotation = (-cape_visual.rotation * 0.18) + (step * 0.05)
	tabard_back_visual.rotation = tabard_back_base_rotation - (step * 0.1) - (movement_ratio * 0.08)
	tabard_front_visual.rotation = tabard_front_base_rotation + (step * 0.07)
	neck_guard_visual.rotation = neck_guard_base_rotation + (sway * 0.35)
	neck_trim_visual.rotation = neck_guard_visual.rotation * 0.7
	chest_plate_visual.rotation = chest_plate_base_rotation + (sway * 0.12)
	chest_plate_inset_visual.rotation = chest_plate_visual.rotation * 0.7

	left_arm_visual.position = left_arm_base_position + Vector2(-movement_ratio * 0.6, bob * 0.2)
	right_arm_visual.position = right_arm_base_position + Vector2(movement_ratio * 0.5, bob * 0.2)
	blade_visual.position = blade_base_position + Vector2(0.0, bob * 0.15)
	left_leg_visual.position = left_leg_base_position + Vector2(0.0, -stride * 0.5)
	right_leg_visual.position = right_leg_base_position + Vector2(0.0, stride * 0.5)
	left_boot_visual.position = left_boot_base_position + Vector2(0.0, -stride * 0.25)
	right_boot_visual.position = right_boot_base_position + Vector2(0.0, stride * 0.25)

	left_arm_visual.rotation = left_arm_base_rotation + (step * 0.45 * movement_ratio) - (anticipation * 0.25)
	right_arm_visual.rotation = right_arm_base_rotation - (step * 0.4 * movement_ratio) - (anticipation * 0.4)
	blade_visual.rotation = blade_base_rotation + (step * 0.2 * movement_ratio) - (anticipation * 0.6)
	left_leg_visual.rotation = left_leg_base_rotation + (step * 0.58 * movement_ratio)
	right_leg_visual.rotation = right_leg_base_rotation - (step * 0.58 * movement_ratio)
	left_boot_visual.rotation = left_boot_base_rotation + (step * 0.2 * movement_ratio)
	right_boot_visual.rotation = right_boot_base_rotation - (step * 0.2 * movement_ratio)
	head_visual.rotation = lerp_angle(head_visual.rotation, (facing_direction.angle() * 0.12) + (sway * 0.45), clampf(delta * 11.0, 0.0, 1.0))
	gem_visual.scale = gem_base_scale * (1.0 + (glint_pulse * 0.08) + (combat_energy * 0.12))
	blade_rune_visual.scale = blade_rune_base_scale * (1.0 + (rune_pulse * 0.07) + (combat_energy * 0.14))
	blade_pommel_visual.scale = Vector2.ONE * (1.0 + (combat_energy * 0.1))
	belt_pouch_visual.rotation = (step * 0.1) - (movement_ratio * 0.06)

	if attack_anim_left > 0.0:
		right_arm_visual.rotation += attack_swing * 1.12
		blade_visual.rotation += attack_swing * 1.82
		chest_plate_visual.rotation += attack_swing * 0.06
		tabard_front_visual.rotation += attack_swing * 0.05
		weapon_trail_alpha = maxf(weapon_trail_alpha, 0.7)

	if is_blocking:
		left_arm_visual.rotation = lerp_angle(left_arm_visual.rotation, -0.95, clampf(delta * 18.0, 0.0, 1.0))
		right_arm_visual.rotation = lerp_angle(right_arm_visual.rotation, 0.92, clampf(delta * 18.0, 0.0, 1.0))
		blade_visual.rotation = lerp_angle(blade_visual.rotation, 1.22, clampf(delta * 18.0, 0.0, 1.0))
		neck_guard_visual.rotation = lerp_angle(neck_guard_visual.rotation, -0.08, clampf(delta * 12.0, 0.0, 1.0))
	elif lunge_time_left > 0.0:
		right_arm_visual.rotation = lerp_angle(right_arm_visual.rotation, 0.28, clampf(delta * 14.0, 0.0, 1.0))
		blade_visual.rotation = lerp_angle(blade_visual.rotation, 0.35, clampf(delta * 14.0, 0.0, 1.0))
		left_leg_visual.rotation = lerp_angle(left_leg_visual.rotation, -0.52, clampf(delta * 14.0, 0.0, 1.0))
		right_leg_visual.rotation = lerp_angle(right_leg_visual.rotation, -0.32, clampf(delta * 14.0, 0.0, 1.0))
		tabard_front_visual.rotation = lerp_angle(tabard_front_visual.rotation, 0.18, clampf(delta * 14.0, 0.0, 1.0))
		chest_plate_visual.rotation = lerp_angle(chest_plate_visual.rotation, 0.06, clampf(delta * 14.0, 0.0, 1.0))

	if is_rolling:
		body_visual.rotation += delta * 18.0
		tabard_front_visual.rotation += delta * 9.0
		tabard_back_visual.rotation += delta * 7.0
	else:
		var target_rotation := (facing_direction.angle() * 0.22) + sway
		body_visual.rotation = lerp_angle(body_visual.rotation, target_rotation, clampf(delta * 11.0, 0.0, 1.0))

	var shade_color := torso_shade_visual.color
	shade_color.a = clampf(torso_shade_base_alpha + (movement_ratio * 0.08) + (combat_energy * 0.12), 0.08, 0.95)
	torso_shade_visual.color = shade_color
	var highlight_color := torso_highlight_visual.color
	highlight_color.a = clampf(torso_highlight_base_alpha + ((breathe + 0.7) * 0.03) + (combat_energy * 0.18), 0.06, 0.7)
	torso_highlight_visual.color = highlight_color
	var edge_color := blade_edge_visual.color
	edge_color.a = clampf(lerpf(blade_edge_base_alpha, 0.95, combat_energy) + (rune_pulse * 0.06), 0.1, 1.0)
	blade_edge_visual.color = edge_color
	var rune_color := blade_rune_visual.color
	rune_color.a = clampf(lerpf(blade_rune_base_alpha, 1.0, combat_energy) + (rune_pulse * 0.08), 0.12, 1.0)
	blade_rune_visual.color = rune_color
	var trim_color := cape_trim_visual.color
	trim_color.a = clampf(cape_trim_base_alpha + (movement_ratio * 0.05) + (combat_energy * 0.08), 0.1, 1.0)
	cape_trim_visual.color = trim_color
	var fold_color := cape_fold_visual.color
	fold_color.a = clampf(cape_fold_base_alpha + (movement_ratio * 0.04), 0.08, 0.8)
	cape_fold_visual.color = fold_color

	var shadow_target := Vector2(1.0 + (movement_ratio * 0.08) + (combat_energy * 0.05), 1.0 - (movement_ratio * 0.05) - (combat_energy * 0.03))
	if is_rolling or lunge_time_left > 0.0:
		shadow_target = Vector2(1.18, 0.85)
	shadow_visual.scale = shadow_visual.scale.lerp(shadow_target, clampf(delta * 10.0, 0.0, 1.0))


func _update_player_sprite(delta: float, movement_ratio: float) -> void:
	if not using_external_player_sprite:
		return

	var action_key := "idle"
	if is_dead:
		action_key = "death"
	elif stun_left > 0.0:
		action_key = "hurt"
	elif is_rolling:
		action_key = "roll"
	elif lunge_time_left > 0.0:
		action_key = "lunge"
	elif attack_anim_left > 0.0 or attack_windup_left > 0.0:
		action_key = "attack"
	elif is_blocking:
		action_key = "block"
	elif movement_ratio > 0.08:
		action_key = "run"

	var row := int(PLAYER_ACTION_ROWS.get(action_key, 0))
	character_sprite.position = character_sprite_base_position
	character_sprite.flip_h = facing_direction.x < -0.01

	var sheet := PLAYER_HD_TEXTURES.get(action_key) as Texture2D
	if sheet == null:
		return

	var frame_columns: Array = PLAYER_ACTION_FRAME_COLUMNS.get(action_key, [])
	var has_custom_columns := not frame_columns.is_empty()

	if player_sprite_anim_key != action_key or character_sprite.texture != sheet:
		player_sprite_anim_key = action_key
		player_sprite_anim_time = 0.0
		character_sprite.texture = sheet
		character_sprite.hframes = PLAYER_HD_HFRAMES
		character_sprite.vframes = PLAYER_HD_VFRAMES
		var first_column := int(frame_columns[0]) if has_custom_columns else 0
		character_sprite.frame_coords = Vector2i(first_column, row)

	var frame_count := int(PLAYER_ACTION_FRAME_COUNTS.get(action_key, PLAYER_HD_HFRAMES))
	if has_custom_columns:
		frame_count = frame_columns.size()
	if frame_count <= 0:
		return
	var fps := float(PLAYER_HD_FPS.get(action_key, 8.0))
	player_sprite_anim_time += delta * fps
	var frame_index: int
	if action_key == "death" and is_dead:
		frame_index = mini(int(floor(player_sprite_anim_time)), frame_count - 1)
	elif action_key == "attack":
		if attack_windup_left > 0.0:
			frame_index = 0
		else:
			var attack_progress := 1.0 - (attack_anim_left / maxf(0.01, attack_anim_total))
			frame_index = mini(int(floor(clampf(attack_progress, 0.0, 1.0) * float(frame_count))), frame_count - 1)
	elif action_key == "block":
		var hold_frame := clampi(PLAYER_BLOCK_HOLD_FRAME_INDEX, 0, frame_count - 1)
		frame_index = mini(int(floor(player_sprite_anim_time)), hold_frame)
	elif action_key == "lunge":
		var lunge_progress := 1.0 - (lunge_time_left / maxf(0.01, ability_2_lunge_duration))
		frame_index = mini(int(floor(clampf(lunge_progress, 0.0, 1.0) * float(frame_count))), frame_count - 1)
	elif action_key == "roll":
		frame_index = mini(int(floor(player_sprite_anim_time)), frame_count - 1)
	elif action_key == "hurt":
		frame_index = mini(int(floor(player_sprite_anim_time)), frame_count - 1)
	else:
		frame_index = int(floor(player_sprite_anim_time)) % frame_count
	var source_column := int(frame_columns[frame_index]) if has_custom_columns else frame_index
	character_sprite.frame_coords = Vector2i(source_column, row)
	if action_key == "attack" and attack_windup_left <= 0.0 and frame_index >= frame_count - 1:
		_apply_queued_melee_hit()
	if action_key == "lunge" and frame_index >= frame_count - 1:
		_apply_lunge_strike()


func _update_weapon_fx(delta: float) -> void:
	if using_external_player_sprite:
		weapon_trail.visible = false
		slash_effect.visible = false
		weapon_trail_points.clear()
		weapon_trail_alpha = 0.0
		return

	var slash_active := slash_effect_left > 0.0
	if slash_active:
		var slash_progress := 1.0 - (slash_effect_left / maxf(0.01, slash_effect_total))
		slash_effect.visible = true
		slash_effect.modulate.a = lerpf(0.95, 0.0, slash_progress)
		slash_effect.scale = Vector2.ONE * lerpf(0.95, 1.08, slash_progress)
		slash_effect.rotation = facing_direction.angle() + lerpf(-0.15, 0.22, slash_progress)
	else:
		slash_effect.visible = false
		slash_effect.modulate.a = 1.0
		slash_effect.scale = Vector2.ONE

	var trail_active := weapon_trail_alpha > 0.01 or attack_anim_left > 0.0 or lunge_time_left > 0.0
	if trail_active:
		var tip_global := blade_visual.to_global(Vector2(30.0, 0.0))
		weapon_trail_points.push_front(tip_global)
		while weapon_trail_points.size() > 10:
			weapon_trail_points.pop_back()

		var local_points := PackedVector2Array()
		for point in weapon_trail_points:
			local_points.append(to_local(point))
		if local_points.size() >= 2:
			weapon_trail.visible = true
			weapon_trail.points = local_points
			var alpha := clampf(weapon_trail_alpha, 0.0, 1.0)
			var target_width := lerpf(1.2, 4.3, alpha)
			weapon_trail.width = lerpf(weapon_trail.width, target_width, clampf(delta * 18.0, 0.0, 1.0))
			var target_color := Color(0.92, 0.58, 0.32, 0.18 + (alpha * 0.62))
			weapon_trail.default_color = weapon_trail.default_color.lerp(target_color, clampf(delta * 16.0, 0.0, 1.0))
		else:
			weapon_trail.visible = false
	elif weapon_trail_points.size() > 0:
		weapon_trail_points.pop_back()
		if weapon_trail_points.size() < 2:
			weapon_trail.visible = false


func _trigger_slash_effect(attack_range: float, arc_degrees: float, color: Color, duration: float, width: float) -> void:
	slash_effect_total = maxf(0.01, duration)
	slash_effect_left = slash_effect_total
	slash_effect.visible = true
	slash_effect.default_color = color
	slash_effect.width = width
	slash_effect.rotation = facing_direction.angle()
	slash_effect.points = _build_slash_points(attack_range, arc_degrees, 20)
	weapon_trail_alpha = maxf(weapon_trail_alpha, 0.8)


func _build_slash_points(attack_range: float, arc_degrees: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := attack_range * 0.72
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_arc, half_arc, t)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


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
	tween.tween_property(effect, "scale", Vector2(1.85, 1.85), hit_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, hit_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(effect):
			effect.queue_free()
	)


func _set_model_palette(body_color: Color, head_color: Color, arm_color: Color, blade_color: Color, cape_color: Color) -> void:
	body_visual.color = body_color
	head_visual.color = head_color
	left_arm_visual.color = arm_color
	right_arm_visual.color = arm_color.darkened(0.05)
	left_leg_visual.color = body_color.darkened(0.08)
	right_leg_visual.color = body_color.darkened(0.12)
	left_boot_visual.color = cape_color.darkened(0.15)
	right_boot_visual.color = cape_color.darkened(0.22)
	blade_visual.color = blade_color
	cape_visual.color = cape_color
	var shade_color := body_color.darkened(0.52)
	shade_color.a = torso_shade_base_alpha
	torso_shade_visual.color = shade_color
	var highlight_color := body_color.lightened(0.28)
	highlight_color.a = torso_highlight_base_alpha
	torso_highlight_visual.color = highlight_color
	neck_guard_visual.color = body_color.darkened(0.2)
	neck_trim_visual.color = blade_color.darkened(0.1)
	chest_plate_visual.color = body_color.lerp(blade_color, 0.32)
	var chest_inset_color := chest_plate_visual.color.darkened(0.22)
	chest_inset_color.a = chest_plate_inset_base_alpha
	chest_plate_inset_visual.color = chest_inset_color
	gem_visual.color = blade_color.lightened(0.06)
	belt_pouch_visual.color = cape_color.darkened(0.35)
	tabard_front_visual.color = cape_color.darkened(0.03)
	tabard_back_visual.color = cape_color.darkened(0.2)
	var trim_color := blade_color.lerp(cape_color, 0.45).lightened(0.08)
	trim_color.a = cape_trim_base_alpha
	cape_trim_visual.color = trim_color
	var fold_color := cape_color.darkened(0.25)
	fold_color.a = cape_fold_base_alpha
	cape_fold_visual.color = fold_color
	var edge_color := blade_color.lightened(0.22)
	edge_color.a = blade_edge_base_alpha
	blade_edge_visual.color = edge_color
	var rune_color := blade_color.lerp(Color(0.9, 0.72, 0.4, 1.0), 0.45)
	rune_color.a = blade_rune_base_alpha
	blade_rune_visual.color = rune_color
	blade_pommel_visual.color = blade_color.lerp(Color(0.66, 0.5, 0.28, 1.0), 0.5)

extends CharacterBody2D
class_name FriendlyRatfolk

signal health_changed(current: float, maximum: float)
signal died(ratfolk: FriendlyRatfolk)

enum DPSAIState {
	FOLLOWING,
	REPOSITIONING,
	DASHING,
	MARKING,
	ATTACKING,
	ASSAULT_CAST,
	BREATH_STACK
}

const DPS_AI_STATE_NAMES: Dictionary = {
	DPSAIState.FOLLOWING: "FOLLOWING",
	DPSAIState.REPOSITIONING: "REPOSITIONING",
	DPSAIState.DASHING: "DASHING",
	DPSAIState.MARKING: "MARKING",
	DPSAIState.ATTACKING: "ATTACKING",
	DPSAIState.ASSAULT_CAST: "ASSAULT_CAST",
	DPSAIState.BREATH_STACK: "BREATH_STACK"
}

# Pacing experiment knobs (slow-RPG cadence).
@export var max_health: float = 43.0
@export var move_speed: float = 127.5
@export var breath_stack_move_speed_multiplier: float = 1.75
@export var use_player_like_movement: bool = true
@export_range(4, 16, 1) var player_like_direction_steps: int = 8
@export_range(0.0, 1.0, 0.01) var player_like_move_deadzone_ratio: float = 0.24
@export var ai_decision_interval: float = 0.1
@export var attack_damage: float = 8.5
@export var attack_range: float = 82.0
@export var attack_arc_degrees: float = 95.0
@export var attack_depth_tolerance: float = 58.0
@export var preferred_attack_spacing: float = 66.0
@export var preferred_attack_spacing_tolerance: float = 6.0
@export var attack_range_indicator_duration: float = 0.14
@export var attack_range_indicator_width: float = 2.6
@export var run_anim_start_speed: float = 28.0
@export var run_anim_stop_speed: float = 16.0
@export var run_anim_displacement_deadzone: float = 0.42
@export var attack_windup: float = 0.19
@export var attack_recovery: float = 0.3
@export var attack_cooldown: float = 1.1
@export var attack_knockback_scale: float = 0.82
@export var attack_hitstop_duration: float = 0.045
@export var attack_impact_vfx_scale: float = 1.15
@export var outgoing_hit_stun_duration: float = 0.16
@export var hit_stun_duration: float = 0.2
@export var hit_knockback_speed: float = 170.0
@export var hit_knockback_decay: float = 980.0
@export var follow_player_distance: float = 138.0
@export var follow_player_min_distance: float = 62.0
@export var idle_follow_lateral_offset: float = 20.0
@export var idle_follow_anchor_smoothing: float = 520.0
@export var idle_follow_stop_distance: float = 10.0
@export var idle_follow_resume_distance: float = 18.0
@export var max_chase_distance_from_player: float = 460.0
@export var facing_flip_deadzone: float = 8.0
@export var arena_padding: float = 24.0
@export var lane_min_x: float = -760.0
@export var lane_max_x: float = 760.0
@export var lane_min_y: float = -165.0
@export var lane_max_y: float = 165.0
@export var miniboss_soft_collision_enabled: bool = false
@export var miniboss_soft_collision_radius: float = 54.0
@export var miniboss_soft_collision_push_speed: float = 255.0
@export var miniboss_soft_collision_max_push_per_frame: float = 5.8
@export var health_bar_width: float = 56.0
@export var health_bar_thickness: float = 5.0
@export var health_bar_y_offset: float = -62.0
@export var cast_bar_width: float = 52.0
@export var cast_bar_thickness: float = 3.0
@export var cast_bar_vertical_offset: float = 8.0
@export var special_bar_width: float = 52.0
@export var special_bar_thickness: float = 3.0
@export var special_bar_vertical_offset: float = 8.0
@export var special_meter_max: float = 100.0
@export var special_meter_gain_per_damage: float = 2.0
@export var special_meter_gain_per_heal: float = 2.0
@export var hit_effect_duration: float = 0.12
@export var heal_flash_duration: float = 0.16
@export var shadow_fear_enabled: bool = true
@export var shadow_fear_duration: float = 10.0
@export var shadow_fear_cooldown: float = 20.0
@export var shadow_fear_trigger_delay_min: float = 0.25
@export var shadow_fear_trigger_delay_max: float = 0.5
@export var shadow_fear_retry_delay: float = 0.38
@export var shadow_fear_consideration_distance: float = 420.0
@export var shadow_fear_projectile_speed: float = 340.0
@export var shadow_fear_projectile_max_distance: float = 980.0
@export var shadow_fear_cast_duration: float = 0.28
@export var shadow_clone_enabled: bool = true
@export var shadow_clone_count: int = 2
@export var shadow_clone_cast_duration: float = 0.5
@export var shadow_clone_cooldown: float = 11.25
@export var boss_mark_duration: float = 6.0
@export var boss_mark_cooldown: float = 4.2
@export var boss_mark_range: float = 232.0
@export var shadow_clone_spawn_radius: float = 30.0
@export var shadow_clone_lifetime: float = 5.5
@export var shadow_clone_scatter_duration: float = 0.32
@export var shadow_clone_scatter_speed: float = 178.0
@export var shadow_clone_scatter_angle_degrees: float = 90.0
@export var shadow_clone_damage_scale: float = 0.58
@export var shadow_clone_speed_scale: float = 1.05
@export var shadow_clone_health_scale: float = 0.52
@export var shadow_clone_attack_cooldown_scale: float = 0.78
@export var shadow_clone_tint: Color = Color(0.72, 0.44, 1.0, 0.82)
@export var backstab_dash_enabled: bool = true
@export var backstab_dash_cooldown: float = 2.05
@export var backstab_dash_speed: float = 285.0
@export var backstab_dash_duration: float = 0.24
@export var backstab_dash_trigger_range: float = 190.0
@export var backstab_dash_behind_distance: float = 52.0
@export var backstab_dash_stop_distance: float = 12.0
@export var backstab_dash_depth_offset: float = 18.0
@export_range(0.0, 0.95, 0.01) var backstab_required_behind_dot: float = 0.12
@export var avoid_tank_frontline_distance: float = 34.0
@export var marked_lunge_panic_freeze_duration: float = 0.22
@export var marked_lunge_move_speed_multiplier: float = 0.72
@export var marked_lunge_hold_radius: float = 20.0

const RATFOLK_SHEET_PATH: String = "res://assets/external/ElthenAssets/ratfolk/Ratfolk Rogue Sprite Sheet.png"
const RATFOLK_SCENE_PATH: String = "res://scenes/npcs/FriendlyRatfolk.tscn"
const SHADOW_FEAR_PROJECTILE_SCENE_PATH: String = "res://scenes/projectiles/ShadowFearProjectile.tscn"
const COMPANION_BREATH_RESPONSE_SCRIPT := preload("res://ai/CompanionBreathResponse.gd")
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
	"run": 9.4,
	"attack": 10.8,
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
var shadow_fear_cooldown_left: float = 0.0
var shadow_fear_pending_left: float = -1.0
var shadow_fear_pending_total: float = 0.0
var shadow_fear_cast_left: float = 0.0
var shadow_fear_cast_active: bool = false
var shadow_fear_cast_target: EnemyBase = null
var shadow_clone_cast_left: float = 0.0
var shadow_clone_cast_active: bool = false
var shadow_clone_cooldown_left: float = 0.0
var boss_mark_cooldown_left: float = 0.0
var shadow_clone_lifetime_left: float = 0.0
var shadow_clone_scatter_left: float = 0.0
var shadow_clone_scatter_direction: Vector2 = Vector2.ZERO
var backstab_dash_cooldown_left: float = 0.0
var backstab_dash_left: float = 0.0
var backstab_dash_target_position: Vector2 = Vector2.ZERO
var backstab_dash_target_enemy: EnemyBase = null
var is_shadow_clone: bool = false
var stun_left: float = 0.0
var hurt_anim_left: float = 0.0
var hit_flash_left: float = 0.0
var heal_flash_left: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var visual_motion_velocity: Vector2 = Vector2.ZERO
var visually_running: bool = false
var facing_left: bool = false
var sprite_anim_key: String = ""
var sprite_anim_time: float = 0.0
var death_anim_time: float = 0.0
var dps_ai_state: DPSAIState = DPSAIState.FOLLOWING
var dps_ai_state_name: String = "FOLLOWING"
var dps_ai_target: Node2D = null
var dps_ai_decision_left: float = 0.0
var health_bar_root: Node2D = null
var health_bar_background: Line2D = null
var health_bar_fill: Line2D = null
var cast_bar_background: Line2D = null
var cast_bar_fill: Line2D = null
var special_bar_background: Line2D = null
var special_bar_fill: Line2D = null
var special_meter: float = 0.0
var ratfolk_sheet_texture: Texture2D = null
var ratfolk_scene_cache: PackedScene = null
var shadow_fear_projectile_scene_cache: PackedScene = null
var tracked_enemy_ids: Dictionary = {}
var shadow_fear_focus_target: EnemyBase = null
var shadow_fear_resume_target: EnemyBase = null
var shadow_fear_focus_requires_close: bool = true
var sprite_base_scale: Vector2 = Vector2.ONE
var breath_threat_snapshot: Dictionary = {}
var breath_safe_indicator_left: float = 0.0
var breath_safe_indicator: Line2D = null
var breath_was_safe: bool = false
var marked_lunge_panic_left: float = 0.0
var marked_lunge_enemy_id: int = -1
var hitbox_debug_enabled: bool = false
var idle_follow_anchor_world: Vector2 = Vector2.ZERO
var idle_follow_anchor_initialized: bool = false
var idle_follow_active: bool = false
var rng := RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_visual: Polygon2D = get_node_or_null("Shadow") as Polygon2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	if is_instance_valid(shadow_visual):
		shadow_visual.visible = true
	if is_shadow_clone:
		add_to_group("shadow_clones")
	else:
		add_to_group("friendly_npcs")
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
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
	special_meter = 0.0
	attack_cooldown_left = attack_cooldown * 0.35
	shadow_fear_cooldown_left = 0.0
	shadow_fear_pending_left = -1.0
	shadow_fear_pending_total = 0.0
	shadow_fear_cast_left = 0.0
	shadow_fear_cast_active = false
	shadow_fear_cast_target = null
	tracked_enemy_ids.clear()
	shadow_fear_focus_target = null
	shadow_fear_resume_target = null
	shadow_fear_focus_requires_close = true
	marked_lunge_panic_left = 0.0
	marked_lunge_enemy_id = -1
	boss_mark_cooldown_left = 0.0
	dps_ai_state = DPSAIState.FOLLOWING
	dps_ai_state_name = String(DPS_AI_STATE_NAMES.get(dps_ai_state, "FOLLOWING"))
	dps_ai_target = player
	dps_ai_decision_left = 0.0
	if not is_shadow_clone:
		_setup_health_bar()
	else:
		shadow_clone_lifetime_left = maxf(0.2, shadow_clone_lifetime)
	_setup_breath_safe_indicator()
	_update_health_bar()
	health_changed.emit(current_health, max_health)


func _exit_tree() -> void:
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()


func set_player(target_player: Player) -> void:
	player = target_player
	idle_follow_anchor_initialized = false
	idle_follow_active = false


func setup_as_shadow_clone(owner_player: Player = null) -> void:
	is_shadow_clone = true
	shadow_fear_enabled = false
	shadow_fear_cooldown_left = 0.0
	shadow_fear_pending_left = -1.0
	shadow_fear_pending_total = 0.0
	shadow_fear_cast_left = 0.0
	shadow_fear_cast_active = false
	shadow_fear_cast_target = null
	tracked_enemy_ids.clear()
	shadow_fear_focus_target = null
	shadow_fear_resume_target = null
	shadow_fear_focus_requires_close = true
	shadow_clone_enabled = false
	shadow_clone_cast_left = 0.0
	shadow_clone_cast_active = false
	shadow_clone_cooldown_left = 0.0
	shadow_clone_scatter_left = 0.0
	shadow_clone_scatter_direction = Vector2.ZERO
	if is_in_group("friendly_npcs"):
		remove_from_group("friendly_npcs")
	if not is_in_group("shadow_clones"):
		add_to_group("shadow_clones")
	if is_instance_valid(owner_player):
		player = owner_player


func set_shadow_clone_scatter(direction: Vector2, duration: float) -> void:
	var fallback := Vector2.LEFT if facing_left else Vector2.RIGHT
	if fallback.length_squared() <= 0.0001:
		fallback = Vector2.RIGHT
	shadow_clone_scatter_direction = direction.normalized() if direction.length_squared() > 0.0001 else fallback
	shadow_clone_scatter_left = maxf(0.0, duration)


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
	if hitbox_debug_enabled:
		queue_redraw()
	var previous_position := global_position
	_tick_timers(delta)
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		visual_motion_velocity = Vector2.ZERO
		visually_running = false
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
		velocity = _apply_player_like_movement_velocity(velocity)
		velocity += knockback_velocity

	move_and_slide()
	_apply_miniboss_soft_separation(delta)
	_clamp_to_bounds()
	var frame_displacement := global_position - previous_position
	if frame_displacement.length() <= maxf(0.0, run_anim_displacement_deadzone):
		visual_motion_velocity = Vector2.ZERO
	else:
		visual_motion_velocity = frame_displacement / maxf(0.0001, delta)
	_update_animation(delta)
	_update_breath_safe_indicator()
	_update_health_bar()


func _apply_player_like_movement_velocity(raw_velocity: Vector2) -> Vector2:
	if not use_player_like_movement:
		return raw_velocity
	if raw_velocity.length_squared() <= 0.0001:
		return Vector2.ZERO
	if backstab_dash_left > 0.0:
		return raw_velocity
	if is_shadow_clone and shadow_clone_scatter_left > 0.0:
		return raw_velocity
	var speed_cap := maxf(1.0, move_speed)
	if raw_velocity.length() > speed_cap * 1.15:
		return raw_velocity
	if raw_velocity.length() <= speed_cap * clampf(player_like_move_deadzone_ratio, 0.0, 0.95):
		return Vector2.ZERO
	if _is_idle_following_state():
		return raw_velocity.normalized() * speed_cap
	var quantized_direction := _quantize_player_like_direction(raw_velocity, player_like_direction_steps)
	if quantized_direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	return quantized_direction * speed_cap


func _is_idle_following_state() -> bool:
	if dps_ai_state != DPSAIState.FOLLOWING:
		return false
	if target_enemy != null and is_instance_valid(target_enemy) and not target_enemy.dead:
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if shadow_fear_cast_active or shadow_clone_cast_active:
		return false
	if backstab_dash_left > 0.0:
		return false
	return true


func _quantize_player_like_direction(direction: Vector2, steps: int) -> Vector2:
	if direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	var normalized_direction := direction.normalized()
	var quant_steps := maxi(4, steps)
	var step_angle := TAU / float(quant_steps)
	var snapped_angle: float = round(normalized_direction.angle() / step_angle) * step_angle
	return Vector2.RIGHT.rotated(snapped_angle)


func _tick_timers(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	shadow_fear_cooldown_left = maxf(0.0, shadow_fear_cooldown_left - delta)
	if shadow_fear_pending_left >= 0.0:
		shadow_fear_pending_left = maxf(0.0, shadow_fear_pending_left - delta)
	if shadow_fear_cast_active:
		shadow_fear_cast_left = maxf(0.0, shadow_fear_cast_left - delta)
	if shadow_clone_cast_active:
		shadow_clone_cast_left = maxf(0.0, shadow_clone_cast_left - delta)
	shadow_clone_cooldown_left = maxf(0.0, shadow_clone_cooldown_left - delta)
	boss_mark_cooldown_left = maxf(0.0, boss_mark_cooldown_left - delta)
	shadow_clone_scatter_left = maxf(0.0, shadow_clone_scatter_left - delta)
	backstab_dash_cooldown_left = maxf(0.0, backstab_dash_cooldown_left - delta)
	backstab_dash_left = maxf(0.0, backstab_dash_left - delta)
	marked_lunge_panic_left = maxf(0.0, marked_lunge_panic_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	hurt_anim_left = maxf(0.0, hurt_anim_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	heal_flash_left = maxf(0.0, heal_flash_left - delta)
	breath_safe_indicator_left = maxf(0.0, breath_safe_indicator_left - delta)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, maxf(0.0, hit_knockback_decay) * delta)
	if is_instance_valid(sprite):
		var base_modulate := shadow_clone_tint if is_shadow_clone else Color(1.0, 1.0, 1.0, 1.0)
		if is_shadow_clone and shadow_clone_lifetime > 0.01:
			var life_ratio := clampf(shadow_clone_lifetime_left / maxf(0.01, shadow_clone_lifetime), 0.0, 1.0)
			base_modulate.a *= lerpf(0.32, 1.0, life_ratio)
		if hit_flash_left > 0.0:
			base_modulate = base_modulate.lerp(Color(1.0, 0.7, 0.7, base_modulate.a), 0.78)
		elif heal_flash_left > 0.0:
			base_modulate = base_modulate.lerp(Color(0.72, 1.0, 0.72, base_modulate.a), 0.78)
		sprite.modulate = base_modulate
		var cast_ratio := -1.0
		if shadow_fear_cast_active and shadow_fear_cast_duration > 0.01:
			cast_ratio = clampf(1.0 - (shadow_fear_cast_left / shadow_fear_cast_duration), 0.0, 1.0)
		elif shadow_clone_cast_active and shadow_clone_cast_duration > 0.01:
			cast_ratio = clampf(1.0 - (shadow_clone_cast_left / shadow_clone_cast_duration), 0.0, 1.0)
		if cast_ratio >= 0.0:
			var pulse := 1.0 + (sin(cast_ratio * TAU * 3.0) * 0.06)
			sprite.scale = sprite_base_scale * pulse
		else:
			sprite.scale = sprite_base_scale
	if is_shadow_clone and not dead:
		shadow_clone_lifetime_left = maxf(0.0, shadow_clone_lifetime_left - delta)
		if shadow_clone_lifetime_left <= 0.0:
			_die()


func _handle_breath_threat() -> bool:
	if is_shadow_clone:
		breath_threat_snapshot.clear()
		breath_was_safe = false
		return false
	breath_threat_snapshot = COMPANION_BREATH_RESPONSE_SCRIPT.get_active_threat(get_tree())
	if not bool(breath_threat_snapshot.get("active", false)):
		breath_was_safe = false
		return false
	_interrupt_attack()
	backstab_dash_left = 0.0
	backstab_dash_target_enemy = null
	shadow_fear_pending_left = -1.0
	shadow_fear_focus_target = null
	_set_dps_ai_state(DPSAIState.BREATH_STACK, player)
	var pocket_valid := bool(breath_threat_snapshot.get("safe_pocket_valid", false))
	var in_safe_pocket: bool = bool(COMPANION_BREATH_RESPONSE_SCRIPT.is_position_safe(global_position, breath_threat_snapshot))
	if pocket_valid and in_safe_pocket:
		velocity = Vector2.ZERO
		_update_facing((breath_threat_snapshot.get("boss_position", global_position) as Vector2) - global_position)
		if not breath_was_safe:
			breath_safe_indicator_left = maxf(breath_safe_indicator_left, 0.6)
		breath_was_safe = true
		return true
	breath_was_safe = false
	var destination: Vector2 = COMPANION_BREATH_RESPONSE_SCRIPT.compute_cover_position(breath_threat_snapshot, 1, 2) if pocket_valid else COMPANION_BREATH_RESPONSE_SCRIPT.compute_scatter_position(breath_threat_snapshot, global_position, 1)
	var to_destination: Vector2 = destination - global_position
	if to_destination.length_squared() <= 4.0:
		velocity = Vector2.ZERO
	else:
		velocity = to_destination.normalized() * (move_speed * maxf(1.0, breath_stack_move_speed_multiplier))
	_update_facing((breath_threat_snapshot.get("boss_position", destination) as Vector2) - global_position)
	return true


func _get_enemy_marking_self_for_lunge() -> EnemyBase:
	var self_id := get_instance_id()
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not enemy.has_method("is_lunge_threatening_marked_ally"):
			continue
		if not bool(enemy.call("is_lunge_threatening_marked_ally")):
			continue
		if not enemy.has_method("get_marked_ally_node"):
			continue
		var marked_target := enemy.call("get_marked_ally_node") as Node2D
		if marked_target == null or not is_instance_valid(marked_target):
			continue
		if marked_target.get_instance_id() == self_id:
			return enemy
	return null


func _handle_marked_lunge_threat(delta: float) -> bool:
	if is_shadow_clone:
		marked_lunge_enemy_id = -1
		marked_lunge_panic_left = 0.0
		return false
	var threat_enemy := _get_enemy_marking_self_for_lunge()
	if threat_enemy == null:
		marked_lunge_enemy_id = -1
		marked_lunge_panic_left = 0.0
		return false

	var enemy_id := threat_enemy.get_instance_id()
	if marked_lunge_enemy_id != enemy_id:
		marked_lunge_enemy_id = enemy_id
		marked_lunge_panic_left = maxf(marked_lunge_panic_left, maxf(0.0, marked_lunge_panic_freeze_duration))

	_interrupt_attack()
	backstab_dash_left = 0.0
	backstab_dash_target_enemy = null
	shadow_fear_pending_left = -1.0
	shadow_fear_focus_target = null
	_set_dps_ai_state(DPSAIState.REPOSITIONING, threat_enemy)
	dps_ai_state_name = "MARKED_PANIC"

	if marked_lunge_panic_left > 0.0:
		velocity = Vector2.ZERO
		_update_facing(threat_enemy.global_position - global_position)
		return true

	var desired_world := player.global_position if is_instance_valid(player) else global_position
	if threat_enemy.has_method("get_marked_ally_protection_point"):
		var protection_variant: Variant = threat_enemy.call("get_marked_ally_protection_point")
		if protection_variant is Vector2:
			desired_world = protection_variant
	var to_safe := desired_world - global_position
	var hold_radius := maxf(6.0, marked_lunge_hold_radius)
	if to_safe.length() <= hold_radius:
		velocity = Vector2.ZERO
	else:
		var speed := maxf(20.0, move_speed * maxf(0.1, marked_lunge_move_speed_multiplier))
		velocity = to_safe.normalized() * speed
	_update_facing(threat_enemy.global_position - global_position)
	return true


func _tick_combat_logic(delta: float) -> void:
	if shadow_clone_cast_active:
		velocity = Vector2.ZERO
		if shadow_clone_cast_left <= 0.0001:
			shadow_clone_cast_active = false
			_spawn_shadow_clones()
			shadow_clone_cooldown_left = maxf(0.01, shadow_clone_cooldown)
		return

	if _handle_breath_threat():
		return
	if _handle_marked_lunge_threat(delta):
		return
	if shadow_fear_cast_active:
		velocity = Vector2.ZERO
		if shadow_fear_cast_left <= 0.0001:
			_finish_shadow_fear_cast()
		return

	if _is_enemy_shadow_feared(target_enemy) or _is_enemy_shadow_feared(backstab_dash_target_enemy):
		_interrupt_attack()

	if attack_windup_left > 0.0:
		attack_windup_left = maxf(0.0, attack_windup_left - delta)
		velocity = _compute_attack_hold_spacing_velocity(target_enemy)
		if attack_windup_left <= 0.0:
			_perform_attack()
			attack_recovery_left = maxf(0.01, attack_recovery)
		return

	if attack_recovery_left > 0.0:
		attack_recovery_left = maxf(0.0, attack_recovery_left - delta)
		velocity = _compute_attack_hold_spacing_velocity(target_enemy)
		return

	if is_shadow_clone and shadow_clone_scatter_left > 0.0:
		var scatter_dir := shadow_clone_scatter_direction
		if scatter_dir.length_squared() <= 0.0001:
			scatter_dir = Vector2.LEFT if facing_left else Vector2.RIGHT
		var scatter_speed := maxf(36.0, shadow_clone_scatter_speed)
		velocity = scatter_dir * scatter_speed
		_update_facing(scatter_dir)
		return

	if backstab_dash_left > 0.0 and backstab_dash_target_enemy != null and is_instance_valid(backstab_dash_target_enemy) and not backstab_dash_target_enemy.dead:
		_set_dps_ai_state(DPSAIState.DASHING, backstab_dash_target_enemy)
		var to_dash_target := backstab_dash_target_position - global_position
		if to_dash_target.length() <= maxf(2.0, backstab_dash_stop_distance):
			backstab_dash_left = 0.0
			velocity = Vector2.ZERO
			_try_start_attack_after_dash(backstab_dash_target_enemy)
			return
		velocity = to_dash_target.normalized() * maxf(48.0, backstab_dash_speed)
		_update_facing(backstab_dash_target_enemy.global_position - global_position)
		return
	elif backstab_dash_left > 0.0:
		backstab_dash_left = 0.0
		backstab_dash_target_enemy = null

	_update_shadow_fear_trigger()
	if _try_cast_shadow_fear():
		return

	target_enemy = _find_target_enemy()
	if target_enemy == null:
		_set_dps_ai_state(DPSAIState.FOLLOWING, player)
		_follow_player_when_idle(delta)
		return

	var to_enemy := target_enemy.global_position - global_position
	var distance_to_enemy := to_enemy.length()
	var attack_depth_aligned := absf(to_enemy.y) <= (attack_depth_tolerance * 1.75)
	var attack_connect_window := _is_attack_connect_window(to_enemy)
	var attack_spacing_ready := _is_attack_spacing_ready(distance_to_enemy)
	var close_attack_ready := attack_cooldown_left <= 0.0 \
		and attack_windup_left <= 0.0 \
		and attack_recovery_left <= 0.0 \
		and not shadow_clone_cast_active \
		and backstab_dash_left <= 0.0 \
		and attack_connect_window \
		and attack_spacing_ready
	if close_attack_ready:
		_update_facing(to_enemy)
		_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
		_start_attack_windup("close_ready")
		velocity = Vector2.ZERO
		return

	if not is_shadow_clone and target_enemy.is_miniboss:
		var behind_target := _clamp_world_position_to_bounds(_get_backstab_target_position(target_enemy))
		var behind_now := _is_position_behind_enemy(target_enemy, global_position)
		var boss_vulnerable := _is_boss_vulnerable(target_enemy)
		var hold_flank := not behind_now and not boss_vulnerable
		if _can_start_shadow_clone_cast(target_enemy, distance_to_enemy, behind_now):
			_set_dps_ai_state(DPSAIState.ASSAULT_CAST, target_enemy)
			_start_shadow_clone_cast()
			velocity = Vector2.ZERO
			return
		var close_boss_attack_window := attack_connect_window and attack_spacing_ready and not hold_flank
		if close_boss_attack_window:
			_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
			_update_facing(to_enemy)
			if attack_cooldown_left <= 0.0 and attack_windup_left <= 0.0 and attack_recovery_left <= 0.0:
				_start_attack_windup("boss_close")
			velocity = Vector2.ZERO
			return
		var miniboss_commit_attack_window := not hold_flank \
			and absf(to_enemy.y) <= (attack_depth_tolerance * 2.1) \
			and distance_to_enemy <= attack_range * 2.1
		if miniboss_commit_attack_window:
			_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
			_update_facing(to_enemy)
			if attack_connect_window and attack_cooldown_left <= 0.0 and attack_windup_left <= 0.0 and attack_recovery_left <= 0.0:
				_start_attack_windup("boss_commit")
				velocity = Vector2.ZERO
				return
			velocity = _compute_reposition_velocity(target_enemy, to_enemy, distance_to_enemy)
			return
		if _can_start_backstab_dash(target_enemy, distance_to_enemy) and (not behind_now or distance_to_enemy > attack_range * 1.2):
			_start_backstab_dash(target_enemy)
			return
		if not behind_now:
			if hold_flank:
				var to_behind_hold := behind_target - global_position
				_set_dps_ai_state(DPSAIState.REPOSITIONING, target_enemy)
				if to_behind_hold.length() > maxf(4.0, backstab_dash_stop_distance * 0.8):
					velocity = to_behind_hold.normalized() * move_speed * 0.94
				else:
					velocity = _compute_reposition_velocity(target_enemy, to_enemy, distance_to_enemy)
				_update_facing(target_enemy.global_position - global_position)
				return
			var close_frontline_window := attack_cooldown_left <= 0.0 \
				and absf(to_enemy.y) <= (attack_depth_tolerance * 1.4) \
				and distance_to_enemy <= attack_range * 1.3 \
				and attack_spacing_ready
			if close_frontline_window:
				_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
				_start_attack_windup("frontline_close")
				velocity = Vector2.ZERO
				return
			var to_behind := behind_target - global_position
			if to_behind.length() > maxf(6.0, backstab_dash_stop_distance) and distance_to_enemy > attack_range * 1.15:
				var frontline_attack_window := attack_cooldown_left <= 0.0 \
					and absf(to_enemy.y) <= (attack_depth_tolerance * 1.35) \
					and distance_to_enemy <= attack_range * 1.08 \
					and attack_spacing_ready
				if frontline_attack_window:
					_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
					_start_attack_windup("frontline_window")
					velocity = Vector2.ZERO
					return
				_set_dps_ai_state(DPSAIState.REPOSITIONING, target_enemy)
				velocity = to_behind.normalized() * move_speed * 0.9
				_update_facing(target_enemy.global_position - global_position)
				return
	if _can_start_backstab_dash(target_enemy, distance_to_enemy):
		_start_backstab_dash(target_enemy)
		return
	_update_facing(to_enemy)
	var melee_engage := attack_connect_window and attack_spacing_ready
	if melee_engage and not shadow_clone_cast_active and backstab_dash_left <= 0.0:
		_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
		if attack_cooldown_left <= 0.0 and attack_windup_left <= 0.0 and attack_recovery_left <= 0.0:
			_start_attack_windup("melee_engage")
			velocity = Vector2.ZERO
			return
	else:
		_update_dps_ai_state(delta, distance_to_enemy, attack_depth_aligned)
	match dps_ai_state:
		DPSAIState.MARKING:
			if _can_apply_boss_mark(target_enemy, distance_to_enemy):
				_apply_boss_mark(target_enemy)
				velocity = Vector2.ZERO
				return
			var mark_move_direction := to_enemy.normalized() if distance_to_enemy > 0.0001 else Vector2.ZERO
			velocity = mark_move_direction * move_speed * 0.85
		DPSAIState.ASSAULT_CAST:
			var behind_now := _is_position_behind_enemy(target_enemy, global_position) if target_enemy != null and is_instance_valid(target_enemy) else false
			if _can_start_shadow_clone_cast(target_enemy, distance_to_enemy, behind_now):
				_start_shadow_clone_cast()
			velocity = Vector2.ZERO
		DPSAIState.DASHING:
			velocity = Vector2.ZERO
		DPSAIState.ATTACKING:
			if not _is_attack_spacing_ready(distance_to_enemy):
				velocity = _compute_reposition_velocity(target_enemy, to_enemy, distance_to_enemy)
				return
			if attack_cooldown_left <= 0.0 and _is_attack_connect_window(to_enemy):
				_start_attack_windup("state_attack")
				velocity = Vector2.ZERO
				return
			if _is_attack_connect_window(to_enemy):
				velocity = Vector2.ZERO
			else:
				velocity = _compute_reposition_velocity(target_enemy, to_enemy, distance_to_enemy)
		DPSAIState.REPOSITIONING:
			if _is_attack_connect_window(to_enemy) and _is_attack_spacing_ready(distance_to_enemy):
				_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
				if attack_cooldown_left <= 0.0 and attack_windup_left <= 0.0 and attack_recovery_left <= 0.0:
					_start_attack_windup("reposition_close")
				velocity = Vector2.ZERO
				return
			velocity = _compute_reposition_velocity(target_enemy, to_enemy, distance_to_enemy)
		_:
			_follow_player_when_idle(delta)


func _update_dps_ai_state(delta: float, distance_to_enemy: float, depth_aligned: bool) -> void:
	dps_ai_decision_left = maxf(0.0, dps_ai_decision_left - delta)
	if dps_ai_decision_left > 0.0:
		return
	dps_ai_decision_left = maxf(0.05, ai_decision_interval)
	if target_enemy == null or not is_instance_valid(target_enemy):
		_set_dps_ai_state(DPSAIState.FOLLOWING, player)
		return
	if not target_enemy.is_miniboss:
		if distance_to_enemy <= attack_range * 1.2 and depth_aligned:
			_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
		else:
			_set_dps_ai_state(DPSAIState.REPOSITIONING, target_enemy)
		return
	var behind_now := _is_position_behind_enemy(target_enemy, global_position)
	if _can_start_shadow_clone_cast(target_enemy, distance_to_enemy, behind_now):
		_set_dps_ai_state(DPSAIState.ASSAULT_CAST, target_enemy)
		return
	if _can_apply_boss_mark(target_enemy, distance_to_enemy) and not _has_boss_mark(target_enemy):
		_set_dps_ai_state(DPSAIState.MARKING, target_enemy)
		return
	var boss_vulnerable := _is_boss_vulnerable(target_enemy)
	if not behind_now and not boss_vulnerable:
		_set_dps_ai_state(DPSAIState.REPOSITIONING, target_enemy)
		return
	var tank_front_blocking := _is_in_front_of_tank(target_enemy) and not behind_now
	var tank_engaged := _is_tank_engaged_with_enemy(target_enemy)
	var avoid_frontline := tank_front_blocking \
		and distance_to_enemy > attack_range * 1.85 \
		and not boss_vulnerable
	var need_realign := (not depth_aligned) and distance_to_enemy > attack_range * 0.95
	var need_close_distance := distance_to_enemy > attack_range * 2.45 and not tank_engaged
	if avoid_frontline or need_realign or need_close_distance:
		_set_dps_ai_state(DPSAIState.REPOSITIONING, target_enemy)
		return
	if tank_engaged and distance_to_enemy <= attack_range * 2.9:
		_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
		return
	if distance_to_enemy <= attack_range * 1.55:
		_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)
		return
	_set_dps_ai_state(DPSAIState.REPOSITIONING, target_enemy)


func _set_dps_ai_state(next_state: DPSAIState, next_target: Node2D) -> void:
	dps_ai_state = next_state
	dps_ai_state_name = String(DPS_AI_STATE_NAMES.get(next_state, "FOLLOWING"))
	dps_ai_target = next_target


func _is_tank_engaged_with_enemy(enemy: EnemyBase) -> bool:
	if not is_instance_valid(player) or enemy == null or not is_instance_valid(enemy):
		return false
	var engage_distance := maxf(96.0, attack_range * 2.0)
	return player.global_position.distance_squared_to(enemy.global_position) <= engage_distance * engage_distance


func _should_reposition_for_target(distance_to_enemy: float, depth_aligned: bool) -> bool:
	if not is_instance_valid(player):
		return false
	if not depth_aligned:
		return true
	var to_player := player.global_position - global_position
	if to_player.length() > maxf(follow_player_distance * 1.35, follow_player_min_distance + 28.0):
		return true
	return distance_to_enemy < _get_attack_spacing_min()


func _is_in_front_of_tank(enemy: EnemyBase) -> bool:
	if not is_instance_valid(player) or enemy == null or not is_instance_valid(enemy):
		return false
	var player_to_enemy := enemy.global_position - player.global_position
	if absf(player_to_enemy.x) <= 6.0:
		return false
	var player_to_self := global_position - player.global_position
	if signf(player_to_enemy.x) != signf(player_to_self.x):
		return false
	return absf(player_to_self.x) > maxf(8.0, avoid_tank_frontline_distance)


func _can_apply_boss_mark(enemy: EnemyBase, distance_to_enemy: float) -> bool:
	if is_shadow_clone:
		return false
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return false
	if not enemy.is_miniboss:
		return false
	if boss_mark_cooldown_left > 0.0:
		return false
	if distance_to_enemy > maxf(32.0, boss_mark_range):
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if shadow_clone_cast_active:
		return false
	return true


func _has_boss_mark(enemy: EnemyBase) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if enemy.has_method("has_dps_mark"):
		return bool(enemy.call("has_dps_mark"))
	return false


func _is_boss_vulnerable(enemy: EnemyBase) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if enemy.has_method("get_boss_vulnerable_time_left"):
		var vulnerable_variant: Variant = enemy.call("get_boss_vulnerable_time_left")
		if vulnerable_variant is float:
			return float(vulnerable_variant) > 0.0
		if vulnerable_variant is int:
			return int(vulnerable_variant) > 0
	if enemy.has_method("get_boss_debug_state"):
		return String(enemy.call("get_boss_debug_state")).strip_edges().to_lower() == "vulnerable"
	return false


func _apply_boss_mark(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_method("apply_dps_mark"):
		enemy.call("apply_dps_mark", maxf(0.1, boss_mark_duration))
	boss_mark_cooldown_left = maxf(0.0, boss_mark_cooldown)
	_spawn_hit_effect(enemy.global_position + Vector2(0.0, -20.0), Color(0.48, 0.86, 1.0, 0.95), 7.2)


func _compute_reposition_velocity(enemy: EnemyBase, to_enemy: Vector2, distance_to_enemy: float) -> Vector2:
	var has_valid_enemy := enemy != null and is_instance_valid(enemy) and not enemy.dead
	if not has_valid_enemy:
		if not is_instance_valid(player):
			return Vector2.ZERO
		var fallback_to_player := player.global_position - global_position
		if fallback_to_player.length_squared() <= 0.0001:
			return Vector2.ZERO
		return fallback_to_player.normalized() * move_speed * 0.92

	var to_player := player.global_position - global_position if is_instance_valid(player) else Vector2.ZERO
	if to_player.length() > maxf(follow_player_distance * 1.75, follow_player_min_distance + 52.0) and distance_to_enemy > attack_range * 2.6:
		return to_player.normalized() * move_speed * 0.9

	var preferred_attack_position := _get_preferred_attack_position(enemy)
	var to_preferred := preferred_attack_position - global_position
	var anchor_tolerance := maxf(6.0, preferred_attack_spacing_tolerance + 2.0)
	if distance_to_enemy < _get_attack_spacing_min():
		if to_preferred.length() > 4.0:
			return to_preferred.normalized() * move_speed * 0.86
		var retreat_direction := -to_enemy
		if retreat_direction.length_squared() <= 0.0001:
			retreat_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
		return retreat_direction.normalized() * move_speed * 0.82

	var depth_misaligned := absf(to_enemy.y) > attack_depth_tolerance
	var too_far := distance_to_enemy > attack_range * 1.16
	if too_far or depth_misaligned or to_preferred.length() > anchor_tolerance:
		var move_direction := to_preferred
		if move_direction.length_squared() <= 0.0001:
			move_direction = to_enemy
		if move_direction.length_squared() <= 0.0001:
			move_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
		return move_direction.normalized() * move_speed * 0.9

	var orbit_sign := 1.0 if (int(get_instance_id()) % 2) == 0 else -1.0
	var orbit_direction := Vector2(-to_enemy.y, to_enemy.x)
	if orbit_direction.length_squared() <= 0.0001:
		orbit_direction = Vector2(0.0, orbit_sign)
	elif orbit_direction.y * orbit_sign < 0.0:
		orbit_direction = -orbit_direction
	return orbit_direction.normalized() * move_speed * 0.34


func _compute_attack_hold_spacing_velocity(enemy_candidate) -> Vector2:
	var enemy := _coerce_enemy_base(enemy_candidate)
	if enemy == null or enemy.dead:
		if target_enemy != null and not is_instance_valid(target_enemy):
			target_enemy = null
		return Vector2.ZERO
	var to_enemy := enemy.global_position - global_position
	var distance_to_enemy := to_enemy.length()
	var too_close := distance_to_enemy < (_get_attack_spacing_min() + 2.0)
	var depth_misaligned := absf(to_enemy.y) > (attack_depth_tolerance * 1.15)
	if too_close or depth_misaligned:
		return _compute_reposition_velocity(enemy, to_enemy, distance_to_enemy)
	return Vector2.ZERO


func _get_preferred_attack_position(enemy: EnemyBase) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return global_position
	var horizontal_sign := 0.0
	if is_instance_valid(player):
		horizontal_sign = -signf(player.global_position.x - enemy.global_position.x)
	if absf(horizontal_sign) <= 0.01:
		horizontal_sign = signf(global_position.x - enemy.global_position.x)
	if absf(horizontal_sign) <= 0.01:
		horizontal_sign = 1.0 if facing_left else -1.0
	var depth_sign := 1.0 if (int(get_instance_id()) % 2) == 0 else -1.0
	var depth_offset := depth_sign * minf(maxf(8.0, backstab_dash_depth_offset * 0.7), attack_depth_tolerance * 0.32)
	var desired_position := enemy.global_position + Vector2(horizontal_sign * _get_attack_spacing_target(), depth_offset)
	return _clamp_world_position_to_bounds(desired_position)


func _get_attack_spacing_target() -> float:
	return minf(maxf(20.0, preferred_attack_spacing), maxf(24.0, attack_range * 0.92))


func _get_attack_spacing_min() -> float:
	var target_spacing := _get_attack_spacing_target()
	var tolerance := maxf(2.0, preferred_attack_spacing_tolerance)
	return maxf(16.0, target_spacing - tolerance)


func _is_attack_spacing_ready(distance_to_enemy: float) -> bool:
	return distance_to_enemy >= _get_attack_spacing_min()


func _get_idle_follow_reference_direction() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.RIGHT
	var player_velocity := player.velocity
	if player_velocity.length_squared() > 36.0:
		return player_velocity.normalized()
	var player_facing := player.facing_direction
	if player_facing.length_squared() > 0.0001:
		return player_facing.normalized()
	return Vector2.LEFT if facing_left else Vector2.RIGHT


func _compute_idle_follow_anchor() -> Vector2:
	if not is_instance_valid(player):
		return global_position
	var follow_direction := _get_idle_follow_reference_direction()
	if follow_direction.length_squared() <= 0.0001:
		follow_direction = Vector2.RIGHT
	var back_direction := -follow_direction.normalized()
	var lateral := Vector2(-follow_direction.y, follow_direction.x)
	var slot_sign := 1.0 if (int(get_instance_id()) % 2) == 0 else -1.0
	var anchor_distance := maxf(follow_player_min_distance + 8.0, follow_player_distance)
	var available_back_distance := _distance_to_bounds_along_direction(player.global_position, back_direction)
	if available_back_distance < INF:
		anchor_distance = minf(anchor_distance, maxf(20.0, available_back_distance - 10.0))
	var anchor := player.global_position \
		+ (back_direction * anchor_distance) \
		+ (lateral * maxf(0.0, idle_follow_lateral_offset) * slot_sign)
	return _clamp_world_position_to_bounds(anchor)


func _distance_to_bounds_along_direction(origin_world: Vector2, direction: Vector2) -> float:
	if direction.length_squared() <= 0.0001:
		return INF
	var normalized_direction := direction.normalized()
	var min_bound_x := minf(lane_min_x, lane_max_x) + arena_padding
	var max_bound_x := maxf(lane_min_x, lane_max_x) - arena_padding
	var min_bound_y := minf(lane_min_y, lane_max_y) + arena_padding
	var max_bound_y := maxf(lane_min_y, lane_max_y) - arena_padding
	var best_t := INF
	if absf(normalized_direction.x) > 0.0001:
		var target_x := max_bound_x if normalized_direction.x > 0.0 else min_bound_x
		var t_x := (target_x - origin_world.x) / normalized_direction.x
		if t_x >= 0.0:
			best_t = minf(best_t, t_x)
	if absf(normalized_direction.y) > 0.0001:
		var target_y := max_bound_y if normalized_direction.y > 0.0 else min_bound_y
		var t_y := (target_y - origin_world.y) / normalized_direction.y
		if t_y >= 0.0:
			best_t = minf(best_t, t_y)
	return best_t


func _follow_player_when_idle(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		idle_follow_anchor_initialized = false
		idle_follow_active = false
		return
	var desired_anchor := _compute_idle_follow_anchor()
	if not idle_follow_anchor_initialized:
		idle_follow_anchor_world = desired_anchor
		idle_follow_anchor_initialized = true
	else:
		idle_follow_anchor_world = idle_follow_anchor_world.move_toward(
			desired_anchor,
			maxf(0.0, idle_follow_anchor_smoothing) * maxf(0.0, delta)
		)
	var to_anchor := idle_follow_anchor_world - global_position
	var distance_to_anchor := to_anchor.length()
	var stop_distance := maxf(2.0, idle_follow_stop_distance)
	var resume_distance := maxf(stop_distance + 1.0, idle_follow_resume_distance)
	if idle_follow_active:
		if distance_to_anchor <= stop_distance:
			idle_follow_active = false
	else:
		if distance_to_anchor >= resume_distance:
			idle_follow_active = true
	if not idle_follow_active:
		velocity = Vector2.ZERO
		var player_velocity := player.velocity
		if player_velocity.length_squared() > 9.0:
			_update_facing(player_velocity)
		else:
			_update_facing(player.global_position - global_position)
		return
	if distance_to_anchor <= 0.0001:
		velocity = Vector2.ZERO
		return
	var move_direction := to_anchor / maxf(0.0001, distance_to_anchor)
	velocity = move_direction * maxf(1.0, move_speed)
	_update_facing(move_direction)


func _find_target_enemy() -> EnemyBase:
	if not _is_valid_shadow_fear_resume_target(shadow_fear_resume_target):
		shadow_fear_resume_target = null
	if shadow_fear_resume_target != null:
		return shadow_fear_resume_target

	var nearest_minion: EnemyBase = null
	var nearest_minion_distance_sq := INF
	var nearest_minion_id := INF
	var nearest_boss: EnemyBase = null
	var nearest_boss_distance_sq := INF
	var nearest_boss_id := INF
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var max_chase_distance_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy.global_position.distance_squared_to(player_position) > max_chase_distance_sq:
			continue
		var distance_sq := enemy.global_position.distance_squared_to(global_position)
		var enemy_id := enemy.get_instance_id()
		var enemy_feared := _is_enemy_shadow_feared(enemy)
		if enemy_feared:
			continue
		if enemy.is_miniboss:
			if nearest_boss == null or distance_sq < nearest_boss_distance_sq or (is_equal_approx(distance_sq, nearest_boss_distance_sq) and enemy_id < nearest_boss_id):
				nearest_boss = enemy
				nearest_boss_distance_sq = distance_sq
				nearest_boss_id = enemy_id
			continue
		if nearest_minion == null or distance_sq < nearest_minion_distance_sq or (is_equal_approx(distance_sq, nearest_minion_distance_sq) and enemy_id < nearest_minion_id):
			nearest_minion = enemy
			nearest_minion_distance_sq = distance_sq
			nearest_minion_id = enemy_id
	if nearest_minion != null:
		return nearest_minion
	if nearest_boss != null:
		return nearest_boss
	return null


func _update_shadow_fear_trigger() -> void:
	if is_shadow_clone or not shadow_fear_enabled:
		tracked_enemy_ids.clear()
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_pending_total = 0.0
		shadow_fear_focus_requires_close = true
		return
	if _is_shadow_fear_locked_for_two_room_fourth_room():
		tracked_enemy_ids.clear()
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_pending_total = 0.0
		shadow_fear_focus_requires_close = true
		return
	var current_enemy_ids: Dictionary = {}
	var living_enemies: Array[EnemyBase] = []
	var had_seen_snapshot := not tracked_enemy_ids.is_empty()
	var newest_enemy: EnemyBase = null
	var newest_enemy_id := -1
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var enemy_id := enemy.get_instance_id()
		current_enemy_ids[enemy_id] = true
		living_enemies.append(enemy)
		if had_seen_snapshot and tracked_enemy_ids.has(enemy_id):
			continue
		if shadow_fear_cooldown_left > 0.0:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		if _enemy_has_hard_cc(enemy):
			continue
		if newest_enemy == null or enemy_id > newest_enemy_id:
			newest_enemy = enemy
			newest_enemy_id = enemy_id
	tracked_enemy_ids = current_enemy_ids
	if shadow_fear_focus_target != null:
		return
	if living_enemies.size() < 2:
		return
	if shadow_fear_cooldown_left > 0.0:
		return
	var focus_requires_close := true
	if newest_enemy == null:
		newest_enemy = _select_shadow_fear_focus_target_from_living_enemies(living_enemies)
	else:
		focus_requires_close = false
	if newest_enemy == null:
		return
	shadow_fear_focus_target = newest_enemy
	shadow_fear_resume_target = _select_shadow_fear_resume_target(newest_enemy)
	shadow_fear_focus_requires_close = focus_requires_close
	var pending_delay := _roll_shadow_fear_delay()
	shadow_fear_pending_left = pending_delay
	shadow_fear_pending_total = maxf(0.01, pending_delay)
	attack_windup_left = 0.0
	attack_recovery_left = 0.0
	if backstab_dash_left > 0.0:
		backstab_dash_left = 0.0
		backstab_dash_target_enemy = null
	var resume_name: String = String(shadow_fear_resume_target.name) if shadow_fear_resume_target != null else "None"
	_log_shadow_fear("QUEUE rat=%s fear=%s resume=%s" % [name, newest_enemy.name, resume_name])
	_spawn_hit_effect(global_position + Vector2(0.0, -16.0), Color(0.34, 0.14, 0.52, 0.86), 5.8)


func _try_cast_shadow_fear() -> bool:
	if is_shadow_clone or not shadow_fear_enabled:
		shadow_fear_focus_target = null
		shadow_fear_focus_requires_close = true
		return false
	if _is_shadow_fear_locked_for_two_room_fourth_room():
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_pending_total = 0.0
		shadow_fear_focus_requires_close = true
		return false
	if shadow_fear_focus_target == null or not is_instance_valid(shadow_fear_focus_target) or shadow_fear_focus_target.dead:
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return false
	if shadow_fear_cooldown_left > 0.0:
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return false
	if shadow_fear_focus_requires_close and not _is_enemy_in_shadow_fear_consideration_range(shadow_fear_focus_target):
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return false
	if _is_enemy_shadow_feared(shadow_fear_focus_target):
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return false
	var focus_enemy := shadow_fear_focus_target
	var to_focus_enemy := focus_enemy.global_position - global_position
	_update_facing(to_focus_enemy)
	if not _is_shadow_fear_cast_aligned(focus_enemy):
		var cast_position := _get_shadow_fear_cast_position(focus_enemy)
		var to_cast_position := cast_position - global_position
		_set_dps_ai_state(DPSAIState.REPOSITIONING, focus_enemy)
		if to_cast_position.length() > 6.0:
			velocity = to_cast_position.normalized() * move_speed * 0.92
		else:
			velocity = Vector2.ZERO
		return true
	if shadow_fear_pending_left > 0.0:
		_set_dps_ai_state(DPSAIState.REPOSITIONING, focus_enemy)
		velocity = Vector2.ZERO
		return true
	if stun_left > 0.0 or shadow_clone_cast_active:
		velocity = Vector2.ZERO
		return true
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		attack_windup_left = 0.0
		attack_recovery_left = 0.0
	if backstab_dash_left > 0.0:
		backstab_dash_left = 0.0
		backstab_dash_target_enemy = null
	_start_shadow_fear_cast(focus_enemy)
	return true


func _start_shadow_fear_cast(focus_enemy: EnemyBase) -> void:
	if focus_enemy == null or not is_instance_valid(focus_enemy) or focus_enemy.dead:
		return
	shadow_fear_cast_active = true
	shadow_fear_cast_left = maxf(0.01, shadow_fear_cast_duration)
	shadow_fear_cast_target = focus_enemy
	velocity = Vector2.ZERO
	_set_dps_ai_state(DPSAIState.MARKING, focus_enemy)
	_log_shadow_fear("CAST_START rat=%s target=%s cast=%.2f" % [name, focus_enemy.name, shadow_fear_cast_left])
	_spawn_hit_effect(global_position + Vector2(0.0, -15.0), Color(0.54, 0.24, 0.76, 0.9), 5.6)


func _finish_shadow_fear_cast() -> void:
	var focus_enemy := shadow_fear_cast_target
	shadow_fear_cast_active = false
	shadow_fear_cast_left = 0.0
	shadow_fear_cast_target = null
	if focus_enemy == null or not is_instance_valid(focus_enemy) or focus_enemy.dead:
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return
	if _is_enemy_shadow_feared(focus_enemy):
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return
	if not _spawn_shadow_fear_projectile(focus_enemy):
		shadow_fear_focus_target = null
		shadow_fear_pending_left = -1.0
		shadow_fear_focus_requires_close = true
		return
	_log_shadow_fear("CAST_RELEASE rat=%s target=%s" % [name, focus_enemy.name])
	shadow_fear_cooldown_left = maxf(0.1, shadow_fear_cooldown)
	velocity = Vector2.ZERO
	shadow_fear_pending_left = -1.0
	shadow_fear_focus_target = null
	shadow_fear_focus_requires_close = true
	if shadow_fear_resume_target != null and _is_valid_shadow_fear_resume_target(shadow_fear_resume_target):
		target_enemy = shadow_fear_resume_target
		_set_dps_ai_state(DPSAIState.ATTACKING, target_enemy)


func _is_valid_shadow_fear_resume_target(enemy) -> bool:
	var enemy_base := _coerce_enemy_base(enemy)
	if enemy_base == null or enemy_base.dead:
		return false
	if enemy_base == shadow_fear_focus_target:
		return false
	if _is_enemy_shadow_feared(enemy_base):
		return false
	return true


func _coerce_enemy_base(candidate) -> EnemyBase:
	if candidate == null or not is_instance_valid(candidate):
		return null
	if not (candidate is EnemyBase):
		return null
	return candidate as EnemyBase


func _select_shadow_fear_resume_target(new_enemy: EnemyBase) -> EnemyBase:
	if target_enemy != null and target_enemy != new_enemy and _is_valid_shadow_fear_resume_target(target_enemy):
		return target_enemy
	var preferred_boss: EnemyBase = null
	var preferred_boss_id := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy == new_enemy:
			continue
		if not enemy.is_miniboss:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if preferred_boss == null or enemy_id < preferred_boss_id:
			preferred_boss = enemy
			preferred_boss_id = enemy_id
	return preferred_boss


func _select_shadow_fear_focus_target_from_living_enemies(living_enemies: Array[EnemyBase]) -> EnemyBase:
	var preferred_non_boss: EnemyBase = null
	var preferred_non_boss_id := -1
	var preferred_boss: EnemyBase = null
	var preferred_boss_id := -1
	for enemy in living_enemies:
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not _is_enemy_in_shadow_fear_consideration_range(enemy):
			continue
		if _enemy_has_hard_cc(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if enemy.is_miniboss:
			if preferred_boss == null or enemy_id > preferred_boss_id:
				preferred_boss = enemy
				preferred_boss_id = enemy_id
			continue
		if preferred_non_boss == null or enemy_id > preferred_non_boss_id:
			preferred_non_boss = enemy
			preferred_non_boss_id = enemy_id
	if preferred_non_boss != null:
		return preferred_non_boss
	return preferred_boss


func _is_shadow_fear_cast_aligned(enemy: EnemyBase) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return false
	var max_vertical_delta := maxf(44.0, attack_depth_tolerance * 0.85)
	var min_horizontal_delta := 24.0
	var max_horizontal_delta := maxf(48.0, shadow_fear_projectile_max_distance - 8.0)
	var delta_to_enemy := enemy.global_position - global_position
	return absf(delta_to_enemy.y) <= max_vertical_delta \
		and absf(delta_to_enemy.x) >= min_horizontal_delta \
		and absf(delta_to_enemy.x) <= max_horizontal_delta


func _get_shadow_fear_cast_position(enemy: EnemyBase) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return global_position
	var direction_sign := _get_shadow_fear_projectile_direction(enemy)
	var desired_position := global_position
	var delta_to_enemy := enemy.global_position - global_position
	var max_vertical_delta := maxf(44.0, attack_depth_tolerance * 0.85)
	var min_horizontal_delta := 24.0
	var max_horizontal_delta := maxf(48.0, shadow_fear_projectile_max_distance - 8.0)
	if absf(delta_to_enemy.y) > max_vertical_delta:
		desired_position.y = enemy.global_position.y
	if absf(delta_to_enemy.x) < min_horizontal_delta or absf(delta_to_enemy.x) > max_horizontal_delta:
		desired_position.x = enemy.global_position.x - (direction_sign * _get_shadow_fear_cast_offset())
	return _clamp_world_position_to_bounds(desired_position)


func _get_shadow_fear_projectile_direction(enemy: EnemyBase) -> float:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return -1.0 if facing_left else 1.0
	if is_instance_valid(player):
		var player_delta_x := enemy.global_position.x - player.global_position.x
		if absf(player_delta_x) > 6.0:
			return -1.0 if player_delta_x < 0.0 else 1.0
	var enemy_delta_x := enemy.global_position.x - global_position.x
	if absf(enemy_delta_x) > 6.0:
		return -1.0 if enemy_delta_x < 0.0 else 1.0
	return -1.0 if facing_left else 1.0


func _get_shadow_fear_cast_offset() -> float:
	return clampf(shadow_fear_projectile_max_distance * 0.08, 72.0, 112.0)


func _get_shadow_fear_projectile_spawn_position(enemy: EnemyBase, direction_sign: float) -> Vector2:
	var spawn_position := global_position + Vector2(0.0, -12.0)
	if is_instance_valid(sprite):
		spawn_position = sprite.global_position
	return spawn_position


func _count_active_hostile_enemies() -> int:
	var count := 0
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var max_chase_distance_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy.global_position.distance_squared_to(player_position) > max_chase_distance_sq:
			continue
		count += 1
	return count


func _select_shadow_fear_target() -> EnemyBase:
	var preferred_target: EnemyBase = null
	var preferred_id := -1
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var max_chase_distance_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	var max_vertical_delta := maxf(18.0, attack_depth_tolerance * 0.75)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy.is_miniboss:
			continue
		if enemy.global_position.distance_squared_to(player_position) > max_chase_distance_sq:
			continue
		if absf(enemy.global_position.y - global_position.y) > max_vertical_delta:
			continue
		if not _is_enemy_in_shadow_fear_consideration_range(enemy):
			continue
		if _enemy_has_hard_cc(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if preferred_target == null or enemy_id > preferred_id:
			preferred_target = enemy
			preferred_id = enemy_id
	return preferred_target


func _spawn_shadow_fear_projectile(enemy: EnemyBase) -> bool:
	var projectile_scene := _get_shadow_fear_projectile_scene()
	if projectile_scene == null:
		return false
	var scene_root := get_parent()
	if scene_root == null:
		return false
	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return false
	var direction_sign := _get_shadow_fear_projectile_direction(enemy)
	var spawn_position := _get_shadow_fear_projectile_spawn_position(enemy, direction_sign)
	_update_facing(Vector2(direction_sign, 0.0))
	scene_root.add_child(projectile)
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			self,
			spawn_position,
			direction_sign,
			maxf(0.1, shadow_fear_projectile_speed),
			maxf(24.0, shadow_fear_projectile_max_distance),
			maxf(0.1, shadow_fear_duration),
			enemy
		)
	_log_shadow_fear("CAST rat=%s target=%s active=%d dir=%.0f" % [name, enemy.name, _count_active_hostile_enemies(), direction_sign])
	_spawn_hit_effect(global_position + Vector2(12.0 * direction_sign, -14.0), Color(0.42, 0.2, 0.62, 0.92), 6.4)
	return true


func _get_shadow_fear_projectile_scene() -> PackedScene:
	if is_instance_valid(shadow_fear_projectile_scene_cache):
		return shadow_fear_projectile_scene_cache
	var loaded_scene := load(SHADOW_FEAR_PROJECTILE_SCENE_PATH)
	if loaded_scene is PackedScene:
		shadow_fear_projectile_scene_cache = loaded_scene as PackedScene
	return shadow_fear_projectile_scene_cache


func _roll_shadow_fear_delay() -> float:
	var min_delay := maxf(0.0, shadow_fear_trigger_delay_min)
	var max_delay := maxf(min_delay, shadow_fear_trigger_delay_max)
	return rng.randf_range(min_delay, max_delay)


func _is_shadow_fear_locked_for_two_room_fourth_room() -> bool:
	var active_arena := _get_active_arena()
	if active_arena == null:
		return false
	if not active_arena.two_room_test_active:
		return false
	if int(active_arena.two_room_test_room_index) != 4:
		return false
	return not _is_any_room_four_minotaur_fighting_player()


func _get_active_arena() -> Arena:
	var scene_root := get_tree().current_scene
	if scene_root is Arena:
		return scene_root as Arena
	var cursor := get_parent()
	while cursor != null:
		if cursor is Arena:
			return cursor as Arena
		cursor = cursor.get_parent()
	return null


func _is_any_room_four_minotaur_fighting_player() -> bool:
	var tank_player := player if is_instance_valid(player) else (get_tree().get_first_node_in_group("player") as Player)
	if tank_player == null or not is_instance_valid(tank_player) or tank_player.is_dead:
		return false
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := _coerce_enemy_base(node)
		if enemy == null or enemy.dead:
			continue
		if enemy.monster_visual_profile != EnemyBase.MonsterVisualProfile.MINOTAUR:
			continue
		if not enemy.minotaur_aggroed:
			continue
		var current_target := enemy.player
		if current_target != null and is_instance_valid(current_target) and current_target == tank_player:
			return true
	return false


func _is_enemy_in_shadow_fear_consideration_range(enemy: EnemyBase) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return false
	var max_distance := maxf(24.0, shadow_fear_consideration_distance)
	return enemy.global_position.distance_squared_to(global_position) <= max_distance * max_distance


func _is_enemy_shadow_feared(enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if enemy is EnemyBase and (enemy as EnemyBase).dead:
		return false
	if enemy.has_method("is_shadow_fear_active"):
		return bool(enemy.call("is_shadow_fear_active"))
	return false


func _enemy_has_hard_cc(enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if enemy is EnemyBase and (enemy as EnemyBase).dead:
		return false
	if enemy.has_method("has_hard_cc_active"):
		return bool(enemy.call("has_hard_cc_active"))
	return _is_enemy_shadow_feared(enemy)


func _log_shadow_fear(message: String) -> void:
	if is_shadow_clone:
		return
	print("[SHADOW_FEAR] %s" % message)


func _can_start_shadow_clone_cast(enemy: EnemyBase, distance_to_enemy: float, behind_now: bool = false) -> bool:
	if is_shadow_clone:
		return false
	if not shadow_clone_enabled:
		return false
	if shadow_clone_count <= 0:
		return false
	if not _is_special_meter_full():
		return false
	if shadow_clone_cast_active or shadow_clone_cast_left > 0.0:
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if stun_left > 0.0:
		return false
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return false
	if not enemy.is_miniboss:
		return false
	if distance_to_enemy > maxf(attack_range * 2.2, 132.0):
		return false
	# Good cast opportunities are when the rat is behind a boss that is facing away,
	# or during boss vulnerability windows.
	if behind_now:
		return true
	return _is_boss_vulnerable(enemy)


func _can_start_backstab_dash(enemy: EnemyBase, distance_to_enemy: float) -> bool:
	if is_shadow_clone:
		return false
	if not backstab_dash_enabled:
		return false
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return false
	if not enemy.is_miniboss:
		return false
	if stun_left > 0.0 or shadow_clone_cast_active:
		return false
	if _is_boss_vulnerable(enemy):
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if backstab_dash_left > 0.0 or backstab_dash_cooldown_left > 0.0:
		return false
	if absf(enemy.global_position.y - global_position.y) > (attack_depth_tolerance * 1.4):
		return false
	if distance_to_enemy > maxf(attack_range * 2.4, backstab_dash_trigger_range):
		return false
	if distance_to_enemy < maxf(22.0, backstab_dash_stop_distance * 1.2):
		return false
	var dash_target := _clamp_world_position_to_bounds(_get_backstab_target_position(enemy))
	if dash_target.distance_squared_to(global_position) <= maxf(16.0, backstab_dash_stop_distance * 1.8) * maxf(16.0, backstab_dash_stop_distance * 1.8):
		return false
	return true


func _start_backstab_dash(enemy: EnemyBase) -> void:
	backstab_dash_target_enemy = enemy
	backstab_dash_target_position = _clamp_world_position_to_bounds(_get_backstab_target_position(enemy))
	backstab_dash_left = maxf(0.08, backstab_dash_duration)
	backstab_dash_cooldown_left = maxf(backstab_dash_cooldown_left, backstab_dash_cooldown)
	_set_dps_ai_state(DPSAIState.DASHING, enemy)


func _get_backstab_target_position(enemy: EnemyBase) -> Vector2:
	var enemy_forward := _get_enemy_forward(enemy)
	var behind_x := -signf(enemy_forward.x)
	if absf(behind_x) <= 0.01 and is_instance_valid(player):
		behind_x = -signf(player.global_position.x - enemy.global_position.x)
	if absf(behind_x) <= 0.01:
		behind_x = -1.0
	var behind_direction := Vector2(behind_x, 0.0)
	var side_seed := 1.0 if (int(get_instance_id()) % 2) == 0 else -1.0
	var depth_bias := Vector2(0.0, side_seed * minf(backstab_dash_depth_offset, attack_depth_tolerance * 0.5))
	return enemy.global_position + (behind_direction * maxf(16.0, backstab_dash_behind_distance)) + depth_bias


func _get_enemy_forward(enemy: EnemyBase) -> Vector2:
	if enemy != null and is_instance_valid(enemy):
		var facing := enemy.external_sprite_facing_direction
		if facing.length_squared() > 0.0001:
			return facing.normalized()
		if is_instance_valid(player):
			var fallback := (player.global_position - enemy.global_position).normalized()
			if fallback.length_squared() > 0.0001:
				return fallback
	return Vector2.RIGHT


func _is_position_behind_enemy(enemy: EnemyBase, world_position: Vector2) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	var enemy_forward := _get_enemy_forward(enemy)
	var forward_x := signf(enemy_forward.x)
	if absf(forward_x) <= 0.01 and is_instance_valid(player):
		forward_x = signf(player.global_position.x - enemy.global_position.x)
	if absf(forward_x) <= 0.01:
		forward_x = 1.0
	var flattened_forward := Vector2(forward_x, 0.0)
	var to_actor := world_position - enemy.global_position
	to_actor.y *= 0.45
	if to_actor.length_squared() <= 0.0001:
		return false
	var alignment := flattened_forward.dot(to_actor.normalized())
	return alignment <= -clampf(backstab_required_behind_dot, 0.0, 0.95)


func _try_start_attack_after_dash(enemy: EnemyBase) -> void:
	backstab_dash_target_enemy = null
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	if _is_enemy_shadow_feared(enemy):
		return
	var to_enemy := enemy.global_position - global_position
	if not _is_attack_connect_window(to_enemy):
		return
	if attack_cooldown_left > 0.0:
		return
	_update_facing(to_enemy)
	_start_attack_windup("after_dash", 0.8)


func _is_attack_connect_window(to_enemy: Vector2) -> bool:
	var effective_depth_tolerance := attack_depth_tolerance * 1.35
	if absf(to_enemy.y) > effective_depth_tolerance:
		return false
	var attack_radius := attack_range * 1.12
	return to_enemy.length_squared() <= attack_radius * attack_radius


func _start_attack_windup(reason: String, windup_scale: float = 1.0) -> void:
	attack_windup_left = maxf(0.01, attack_windup * maxf(0.1, windup_scale))
	_spawn_attack_range_indicator()


func _start_shadow_clone_cast() -> void:
	_consume_special_meter()
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
	var scatter_spread_radians := deg_to_rad(clampf(shadow_clone_scatter_angle_degrees, 0.0, 179.0))
	var base_forward := Vector2.LEFT if facing_left else Vector2.RIGHT
	if base_forward.length_squared() <= 0.0001:
		base_forward = Vector2.RIGHT
	for i in range(clone_total):
		var clone := spawn_scene.instantiate() as FriendlyRatfolk
		if clone == null:
			continue
		clone.setup_as_shadow_clone(player)
		clone.facing_left = facing_left
		scene_root.add_child(clone)
		clone.position = spawn_position_local
		clone.set_arena_bounds(lane_min_x, lane_max_x, lane_min_y, lane_max_y)
		clone.set_player(player)
		clone.attack_cooldown_left = minf(maxf(0.02, clone.attack_cooldown * 0.18) + (0.03 * float(i)), maxf(0.06, clone.attack_cooldown * 0.42))
		clone.shadow_clone_lifetime_left = maxf(0.2, shadow_clone_lifetime)
		clone.shadow_clone_tint = shadow_clone_tint
		clone.shadow_clone_lifetime = maxf(0.2, shadow_clone_lifetime)
		clone.shadow_clone_speed_scale = shadow_clone_speed_scale
		clone.shadow_clone_damage_scale = shadow_clone_damage_scale
		clone.shadow_clone_health_scale = shadow_clone_health_scale
		clone.shadow_clone_attack_cooldown_scale = shadow_clone_attack_cooldown_scale
		var scatter_angle := 0.0
		if clone_total > 1:
			var t := float(i) / float(clone_total - 1)
			var centered := (t * 2.0) - 1.0
			scatter_angle = centered * (scatter_spread_radians * 0.5)
		var scatter_direction := base_forward.rotated(scatter_angle)
		clone.set_shadow_clone_scatter(scatter_direction, maxf(0.0, shadow_clone_scatter_duration))
		_spawn_shadow_clone_birth_effect(clone.global_position)


func _get_ratfolk_scene() -> PackedScene:
	if is_instance_valid(ratfolk_scene_cache):
		return ratfolk_scene_cache
	var loaded_scene := load(RATFOLK_SCENE_PATH)
	if loaded_scene is PackedScene:
		ratfolk_scene_cache = loaded_scene as PackedScene
	return ratfolk_scene_cache


func _clamp_world_position_to_bounds(world_position: Vector2) -> Vector2:
	var parent_node := get_parent() as Node2D
	var clamped_local := world_position
	if parent_node != null:
		clamped_local = parent_node.to_local(world_position)
	var min_x := minf(lane_min_x, lane_max_x) + arena_padding
	var max_x := maxf(lane_min_x, lane_max_x) - arena_padding
	var min_y := minf(lane_min_y, lane_max_y) + arena_padding
	var max_y := maxf(lane_min_y, lane_max_y) - arena_padding
	clamped_local.x = clampf(clamped_local.x, min_x, max_x)
	clamped_local.y = clampf(clamped_local.y, min_y, max_y)
	if parent_node != null:
		return parent_node.to_global(clamped_local)
	return clamped_local


func _perform_attack() -> void:
	attack_cooldown_left = maxf(0.01, attack_cooldown)
	var facing_direction := Vector2.LEFT if facing_left else Vector2.RIGHT
	if target_enemy != null and is_instance_valid(target_enemy) and not target_enemy.dead:
		var to_target := target_enemy.global_position - global_position
		if to_target.length_squared() > 0.0001:
			facing_direction = to_target.normalized()
	var hit_any := false
	var arc_threshold := cos(deg_to_rad(attack_arc_degrees * 0.5))
	var attack_radius_sq := (attack_range * 1.12) * (attack_range * 1.12)
	var effective_depth_tolerance := attack_depth_tolerance * 1.35

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var to_enemy := enemy.global_position - global_position
		if absf(to_enemy.y) > effective_depth_tolerance:
			continue
		if to_enemy.length_squared() > attack_radius_sq:
			continue
		var direction_to_enemy := to_enemy.normalized() if to_enemy.length_squared() > 0.0001 else facing_direction
		if facing_direction.dot(direction_to_enemy) < arc_threshold:
			continue
		if not enemy.has_method("receive_hit"):
			continue
		var landed := bool(enemy.call("receive_hit", attack_damage, global_position, outgoing_hit_stun_duration, true, attack_knockback_scale, self))
		if landed:
			hit_any = true
			add_special_meter_from_damage(attack_damage)
			if enemy.has_method("apply_hitstop"):
				enemy.apply_hitstop(maxf(0.0, attack_hitstop_duration))
			var impact_scale := maxf(0.6, attack_impact_vfx_scale)
			_spawn_hit_effect(enemy.global_position + Vector2(0.0, -12.0), Color(1.0, 0.8, 0.42, 0.95), 7.2 * impact_scale)

	if hit_any:
		var swing_scale := maxf(0.6, attack_impact_vfx_scale)
		_spawn_hit_effect(global_position + (facing_direction * 14.0) + Vector2(0.0, -10.0), Color(0.94, 0.78, 0.36, 0.95), 8.0 * swing_scale)


func needs_healing(threshold_ratio: float = 0.999) -> bool:
	if dead:
		return false
	var clamped_threshold := clampf(threshold_ratio, 0.0, 1.0)
	return current_health < (max_health * clamped_threshold)


func receive_heal(amount: float) -> bool:
	if dead:
		return false
	if amount <= 0.0:
		return false
	var previous_health := current_health
	current_health = minf(max_health, current_health + amount)
	if current_health <= previous_health + 0.001:
		return false
	heal_flash_left = maxf(heal_flash_left, maxf(0.01, heal_flash_duration))
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	_spawn_hit_effect(global_position + Vector2(0.0, -12.0), Color(0.36, 0.95, 0.56, 0.9), 7.5)
	return true


func revive_at_full_health() -> void:
	dead = false
	current_health = maxf(1.0, max_health)
	stun_left = 0.0
	hurt_anim_left = 0.0
	hit_flash_left = 0.0
	heal_flash_left = 0.0
	special_meter = 0.0
	attack_windup_left = 0.0
	attack_recovery_left = 0.0
	attack_cooldown_left = maxf(0.0, attack_cooldown * 0.35)
	shadow_fear_cast_active = false
	shadow_fear_cast_left = 0.0
	shadow_fear_pending_left = -1.0
	shadow_fear_pending_total = 0.0
	shadow_fear_cast_target = null
	shadow_clone_cast_active = false
	shadow_clone_cast_left = 0.0
	shadow_fear_focus_target = null
	shadow_fear_resume_target = null
	backstab_dash_left = 0.0
	backstab_dash_target_enemy = null
	target_enemy = null
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	visual_motion_velocity = Vector2.ZERO
	visually_running = false
	death_anim_time = 0.0
	if not is_shadow_clone and not is_instance_valid(health_bar_root):
		_setup_health_bar()
	if is_instance_valid(sprite):
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_set_sprite_frame("idle", 0)
	_update_health_bar()
	health_changed.emit(current_health, max_health)


func receive_hit(amount: float, source_position: Vector2, _guard_break: bool = false, stun_duration: float = 0.0, knockback_scale: float = 1.0) -> bool:
	if dead:
		return false
	if amount <= 0.0:
		return false
	if is_instance_valid(player) and player.is_point_inside_block_shield(global_position):
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT if facing_left else Vector2.LEFT
	knockback_velocity = knockback_direction * hit_knockback_speed * maxf(0.1, knockback_scale)
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
	shadow_fear_cast_active = false
	shadow_fear_cast_left = 0.0
	shadow_fear_cast_target = null
	shadow_clone_cast_active = false
	shadow_clone_cast_left = 0.0
	backstab_dash_left = 0.0
	backstab_dash_target_enemy = null
	target_enemy = null


func _die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	stun_left = 0.0
	hurt_anim_left = 0.0
	heal_flash_left = 0.0
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
	if shadow_fear_cast_active:
		var cast_duration := maxf(0.01, shadow_fear_cast_duration)
		var cast_progress := clampf(1.0 - (shadow_fear_cast_left / cast_duration), 0.0, 1.0)
		_set_non_loop_anim("attack", cast_progress * 0.55)
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
	var motion_speed := visual_motion_velocity.length()
	if visually_running:
		visually_running = motion_speed >= maxf(0.0, run_anim_stop_speed)
	else:
		visually_running = motion_speed >= maxf(0.0, run_anim_start_speed)
	if visually_running:
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
	set_player(get_tree().get_first_node_in_group("player") as Player)


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


func _apply_miniboss_soft_separation(delta: float) -> void:
	if not miniboss_soft_collision_enabled:
		return
	if dead or delta <= 0.0:
		return
	var desired_spacing := maxf(1.0, miniboss_soft_collision_radius)
	var desired_spacing_sq := desired_spacing * desired_spacing
	var separation := Vector2.ZERO
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var miniboss := enemy_node as EnemyBase
		if miniboss == null:
			continue
		if not is_instance_valid(miniboss) or miniboss.dead or not miniboss.is_miniboss:
			continue
		var to_self := global_position - miniboss.global_position
		var distance_sq := to_self.length_squared()
		if distance_sq <= 0.0001:
			var fallback_sign := 1.0 if get_instance_id() > miniboss.get_instance_id() else -1.0
			to_self = Vector2(fallback_sign, 0.0)
			distance_sq = 1.0
		if distance_sq >= desired_spacing_sq:
			continue
		var distance := sqrt(distance_sq)
		var penetration_ratio := (desired_spacing - distance) / desired_spacing
		separation += (to_self / distance) * penetration_ratio
	if separation.length_squared() <= 0.0001:
		return
	var push_step := separation * (miniboss_soft_collision_push_speed * delta)
	var max_push_step := maxf(0.1, miniboss_soft_collision_max_push_per_frame)
	if push_step.length() > max_push_step:
		push_step = push_step.normalized() * max_push_step
	global_position += push_step


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

	cast_bar_background = Line2D.new()
	cast_bar_background.default_color = Color(0.08, 0.08, 0.08, 0.88)
	cast_bar_background.width = maxf(1.0, cast_bar_thickness)
	cast_bar_background.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cast_bar_background.end_cap_mode = Line2D.LINE_CAP_ROUND
	cast_bar_background.visible = false
	health_bar_root.add_child(cast_bar_background)

	cast_bar_fill = Line2D.new()
	cast_bar_fill.default_color = Color(0.68, 0.42, 0.94, 0.95)
	cast_bar_fill.width = maxf(1.0, cast_bar_thickness - 1.0)
	cast_bar_fill.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cast_bar_fill.end_cap_mode = Line2D.LINE_CAP_ROUND
	cast_bar_fill.visible = false
	health_bar_root.add_child(cast_bar_fill)

	special_bar_background = Line2D.new()
	special_bar_background.default_color = Color(0.08, 0.08, 0.08, 0.9)
	special_bar_background.width = maxf(1.0, special_bar_thickness)
	special_bar_background.begin_cap_mode = Line2D.LINE_CAP_ROUND
	special_bar_background.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(special_bar_background)

	special_bar_fill = Line2D.new()
	special_bar_fill.default_color = Color(0.98, 0.84, 0.36, 0.95)
	special_bar_fill.width = maxf(1.0, special_bar_thickness - 1.0)
	special_bar_fill.begin_cap_mode = Line2D.LINE_CAP_ROUND
	special_bar_fill.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(special_bar_fill)


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

	if not is_instance_valid(cast_bar_background) or not is_instance_valid(cast_bar_fill):
		return
	var cast_half_width := cast_bar_width * 0.5
	var cast_start := Vector2(-cast_half_width, -cast_bar_vertical_offset)
	var cast_end := Vector2(cast_half_width, -cast_bar_vertical_offset)
	cast_bar_background.points = PackedVector2Array([cast_start, cast_end])
	var cast_ratio := _get_cast_progress_ratio()
	var show_cast := cast_ratio >= 0.0
	cast_bar_background.visible = show_cast
	if show_cast:
		var cast_fill_x := lerpf(cast_start.x, cast_end.x, cast_ratio)
		cast_bar_fill.points = PackedVector2Array([cast_start, Vector2(cast_fill_x, cast_start.y)])
		cast_bar_fill.visible = cast_ratio > 0.0
	else:
		cast_bar_fill.visible = false

	if not is_instance_valid(special_bar_background) or not is_instance_valid(special_bar_fill):
		return
	var special_half_width := special_bar_width * 0.5
	var special_start := Vector2(-special_half_width, special_bar_vertical_offset)
	var special_end := Vector2(special_half_width, special_bar_vertical_offset)
	special_bar_background.points = PackedVector2Array([special_start, special_end])
	var special_ratio := _get_special_meter_ratio()
	var special_fill_x := lerpf(special_start.x, special_end.x, special_ratio)
	special_bar_fill.points = PackedVector2Array([special_start, Vector2(special_fill_x, special_start.y)])
	special_bar_fill.visible = special_ratio > 0.0


func _get_cast_progress_ratio() -> float:
	if shadow_fear_cast_active and shadow_fear_cast_duration > 0.01:
		return clampf(1.0 - (shadow_fear_cast_left / shadow_fear_cast_duration), 0.0, 1.0)
	if shadow_clone_cast_active and shadow_clone_cast_duration > 0.01:
		return clampf(1.0 - (shadow_clone_cast_left / shadow_clone_cast_duration), 0.0, 1.0)
	var has_pending_shadow_fear := shadow_fear_pending_left >= 0.0 and shadow_fear_focus_target != null and is_instance_valid(shadow_fear_focus_target) and not shadow_fear_focus_target.dead
	if has_pending_shadow_fear:
		if shadow_fear_pending_total <= 0.01:
			return 1.0
		return clampf(1.0 - (shadow_fear_pending_left / shadow_fear_pending_total), 0.0, 1.0)
	return -1.0


func _get_special_meter_ratio() -> float:
	if is_shadow_clone:
		return 0.0
	return clampf(special_meter / maxf(1.0, special_meter_max), 0.0, 1.0)


func _is_special_meter_full() -> bool:
	return _get_special_meter_ratio() >= 0.999


func _add_special_meter(raw_amount: float) -> void:
	if is_shadow_clone:
		return
	var amount := maxf(0.0, raw_amount)
	if amount <= 0.0:
		return
	special_meter = clampf(special_meter + amount, 0.0, maxf(1.0, special_meter_max))
	_update_health_bar()


func _consume_special_meter() -> void:
	if is_shadow_clone:
		return
	special_meter = 0.0
	_update_health_bar()


func add_special_meter_from_damage(damage_amount: float) -> void:
	_add_special_meter(maxf(0.0, damage_amount) * maxf(0.0, special_meter_gain_per_damage))


func add_special_meter_from_heal(heal_amount: float) -> void:
	_add_special_meter(maxf(0.0, heal_amount) * maxf(0.0, special_meter_gain_per_heal))


func _setup_breath_safe_indicator() -> void:
	if breath_safe_indicator != null and is_instance_valid(breath_safe_indicator):
		return
	var icon := Line2D.new()
	icon.name = "BreathSafeIndicator"
	icon.width = 2.2
	icon.default_color = Color(0.46, 0.92, 1.0, 0.0)
	icon.begin_cap_mode = Line2D.LINE_CAP_ROUND
	icon.end_cap_mode = Line2D.LINE_CAP_ROUND
	icon.joint_mode = Line2D.LINE_JOINT_ROUND
	icon.closed = true
	icon.points = PackedVector2Array([
		Vector2(0.0, -6.0),
		Vector2(6.0, 0.0),
		Vector2(0.0, 6.0),
		Vector2(-6.0, 0.0)
	])
	icon.visible = false
	add_child(icon)
	breath_safe_indicator = icon


func _update_breath_safe_indicator() -> void:
	if breath_safe_indicator == null or not is_instance_valid(breath_safe_indicator):
		return
	if breath_safe_indicator_left <= 0.0:
		breath_safe_indicator.visible = false
		return
	var pulse := 0.5 + (sin(Time.get_ticks_msec() * 0.014) * 0.5)
	breath_safe_indicator.visible = true
	breath_safe_indicator.position = Vector2(0.0, -42.0)
	breath_safe_indicator.scale = Vector2.ONE * lerpf(0.96, 1.14, pulse)
	breath_safe_indicator.default_color = Color(0.46, 0.92, 1.0, lerpf(0.24, 0.78, clampf(breath_safe_indicator_left / 0.6, 0.0, 1.0)))


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


func _spawn_attack_range_indicator() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return

	var facing_direction := Vector2.LEFT if facing_left else Vector2.RIGHT
	if target_enemy != null and is_instance_valid(target_enemy) and not target_enemy.dead:
		var to_target := target_enemy.global_position - global_position
		if to_target.length_squared() > 0.0001:
			facing_direction = to_target.normalized()

	var indicator := Node2D.new()
	indicator.top_level = true
	indicator.global_position = global_position + Vector2(0.0, -12.0)
	indicator.rotation = facing_direction.angle()
	indicator.z_index = 229
	scene_root.add_child(indicator)

	var attack_radius := attack_range * 0.28
	var arc := Line2D.new()
	arc.default_color = Color(1.0, 0.82, 0.42, 0.84)
	arc.width = maxf(1.4, attack_range_indicator_width)
	arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	arc.points = _build_attack_arc_points(attack_radius, attack_arc_degrees, 13)
	indicator.add_child(arc)

	var guide := Line2D.new()
	guide.default_color = Color(1.0, 0.92, 0.58, 0.62)
	guide.width = maxf(1.0, attack_range_indicator_width * 0.45)
	guide.begin_cap_mode = Line2D.LINE_CAP_ROUND
	guide.end_cap_mode = Line2D.LINE_CAP_ROUND
	guide.points = PackedVector2Array([Vector2.ZERO, Vector2(attack_radius, 0.0)])
	indicator.add_child(guide)

	var duration := maxf(0.06, attack_range_indicator_duration)
	var tween := create_tween()
	tween.tween_property(indicator, "scale", Vector2(1.08, 1.08), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(indicator, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(indicator):
			indicator.queue_free()
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
	ring.default_color = Color(0.72, 0.44, 1.0, 0.9)
	ring.width = 2.4
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = _build_ring_points(12.0, 18)
	burst.add_child(ring)

	var inner_ring := Line2D.new()
	inner_ring.default_color = Color(0.72, 0.44, 1.0, 0.72)
	inner_ring.width = 1.7
	inner_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	inner_ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	inner_ring.closed = true
	inner_ring.points = _build_ring_points(7.0, 14)
	burst.add_child(inner_ring)

	var cross := Line2D.new()
	cross.default_color = Color(0.72, 0.44, 1.0, 0.85)
	cross.width = 1.8
	cross.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cross.end_cap_mode = Line2D.LINE_CAP_ROUND
	cross.points = PackedVector2Array([Vector2(-8.0, 0.0), Vector2(8.0, 0.0)])
	burst.add_child(cross)

	var cross_v := Line2D.new()
	cross_v.default_color = Color(0.72, 0.44, 1.0, 0.85)
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
	ring.default_color = Color(0.72, 0.44, 1.0, 0.92)
	ring.width = 2.6
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = _build_ring_points(8.0, 16)
	pulse.add_child(ring)

	var shards_color := Color(0.72, 0.44, 1.0, 0.85)
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


func _build_attack_arc_points(radius: float, arc_degrees: float, points_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_radius := maxf(8.0, radius)
	var safe_points := maxi(3, points_count)
	var half_arc := deg_to_rad(clampf(arc_degrees, 10.0, 179.0) * 0.5)
	for i in range(safe_points):
		var t := float(i) / float(safe_points - 1)
		var angle := lerpf(-half_arc, half_arc, t)
		points.append(Vector2.RIGHT.rotated(angle) * safe_radius)
	return points


func set_hitbox_debug_enabled(enabled: bool) -> void:
	var next_enabled := bool(enabled)
	if hitbox_debug_enabled == next_enabled:
		return
	hitbox_debug_enabled = next_enabled
	queue_redraw()


func _draw() -> void:
	if not hitbox_debug_enabled or dead:
		return
	_draw_rat_hurtbox_debug()
	_draw_rat_attack_hitbox_debug()


func _draw_rat_hurtbox_debug() -> void:
	if collision_shape == null or not is_instance_valid(collision_shape):
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return
	var center := to_local(collision_shape.global_position)
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	var radius := maxf(4.0, circle.radius * maxf(0.01, radius_scale))
	draw_circle(center, radius, Color(0.24, 0.98, 1.0, 0.12))
	draw_arc(center, radius, 0.0, TAU, 28, Color(0.32, 1.0, 1.0, 0.9), 1.8, true)


func _draw_rat_attack_hitbox_debug() -> void:
	var facing_direction := Vector2.LEFT if facing_left else Vector2.RIGHT
	var attack_radius := maxf(8.0, attack_range * 1.12)
	var points := PackedVector2Array([Vector2.ZERO])
	var arc_points := _build_attack_arc_points(attack_radius, attack_arc_degrees, 28)
	for point in arc_points:
		points.append(point.rotated(facing_direction.angle()))
	draw_colored_polygon(points, Color(1.0, 0.78, 0.3, 0.12))
	draw_polyline(points, Color(1.0, 0.88, 0.5, 0.92), 1.8, true)


func _is_autoplay_requested() -> bool:
	var autoplay_raw := OS.get_environment("AUTOPLAY_TEST").strip_edges().to_lower()
	if not autoplay_raw.is_empty() and autoplay_raw not in ["0", "false", "off", "no"]:
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false


func get_ai_debug_state() -> String:
	return dps_ai_state_name


func get_ai_debug_target() -> String:
	if dps_ai_target == null or not is_instance_valid(dps_ai_target):
		return "-"
	return dps_ai_target.name


func is_shadow_clone_actor() -> bool:
	return is_shadow_clone

extends CharacterBody2D
class_name EnemyBase

const SHADOW_FEAR_DEBUFF_TEXTURE_PATH: String = "res://assets/vfx/opengameart/shadow_fear_debuff_pure_21.png"
const SHADOW_FEAR_DEBUFF_SPRITE_SCALE: Vector2 = Vector2(0.42, 0.42)

static var shadow_fear_debuff_texture_cache: Texture2D = null

signal died(enemy: EnemyBase)
signal summon_minions_requested(enemy: EnemyBase, count: int)

enum BossLoopState {
	IDLE,
	MARK,
	WINDUP,
	LUNGE,
	VULNERABLE,
	SUMMON
}

const BOSS_LOOP_STATE_NAMES: Dictionary = {
	BossLoopState.IDLE: "Idle",
	BossLoopState.MARK: "Windup",
	BossLoopState.WINDUP: "Windup",
	BossLoopState.LUNGE: "Lunge",
	BossLoopState.VULNERABLE: "Vulnerable",
	BossLoopState.SUMMON: "Summon"
}

# Pacing experiment knobs (slow-RPG cadence).
@export var max_health: float = 240.0
@export var move_speed: float = 89.25
@export var attack_damage: float = 12.0
@export var attack_range: float = 46.0
@export var basic_attack_hit_start_offset: float = 6.0
@export var basic_attack_hit_end_bonus: float = 24.0
@export var basic_attack_hit_half_width: float = 24.0
@export var basic_attack_tip_radius: float = 20.0
@export var attack_cooldown: float = 1.8
@export var attack_windup: float = 0.28
@export var attack_prestrike_hold_duration: float = 0.0
@export var attack_hold_frame: int = 2
@export var attack_recovery_hold_duration: float = 0.0
@export var use_single_phase_loop: bool = true
@export var boss_can_summon_minions: bool = true
@export var boss_mark_start_range: float = 210.0
@export var boss_mark_duration: float = 0.5
@export var boss_windup_duration: float = 2.1
@export var boss_lunge_duration: float = 0.44
@export var boss_lunge_speed: float = 420.0
@export var boss_lunge_damage_multiplier: float = 1.35
@export var boss_lunge_stun_bonus: float = 0.08
@export var boss_lunge_max_duration: float = 0.72
@export var boss_lunge_distance_padding: float = 14.0
@export var boss_lunge_steer_rate: float = 9.0
@export var boss_lunge_hit_start_offset: float = 12.0
@export var boss_lunge_hit_length: float = 112.0
@export var boss_lunge_hit_half_width: float = 26.0
@export var boss_lunge_tip_radius: float = 22.0
@export var boss_lunge_collateral_trigger_travel: float = 18.0
@export var boss_lunge_knockback_scale: float = 2.35
@export var boss_lunge_impact_effect_size: float = 22.0
@export var boss_lunge_block_effect_size: float = 28.0
@export var boss_lunge_block_hitstop: float = 0.09
@export var basic_block_success_fx_delay: float = 0.08
@export var boss_vulnerable_duration: float = 3.0
@export var boss_mark_cycle_interval: float = 12.5
@export var boss_summon_interval: float = 25.0
@export var boss_vulnerable_speed_multiplier: float = 0.32
@export var boss_vulnerable_damage_taken_multiplier: float = 1.55
@export var boss_dps_mark_damage_taken_multiplier: float = 1.16
@export var boss_short_recovery_duration: float = 0.95
@export var boss_summon_duration: float = 0.75
@export var boss_summon_every_cycles: int = 3
@export var boss_summon_count: int = 2
@export var boss_mark_warning_radius_x: float = 72.0
@export var boss_mark_warning_radius_y: float = 40.0
@export var prioritize_companion_targets: bool = false
@export var companion_target_refresh_interval: float = 0.18
@export var spin_attack_enabled: bool = true
@export var spin_charge_duration: float = 2.0
@export var spin_attack_duration: float = 1.35
@export var spin_attack_radius: float = 94.0
@export var spin_attack_edge_padding: float = 22.0
@export var spin_attack_depth_scale: float = 0.62
@export var spin_attack_center_offset: float = 0.0
@export var basic_attacks_required_for_spin: int = 3
@export var spin_attack_damage_multiplier: float = 1.8
@export var spin_attack_cooldown: float = 5.5
@export var spin_trigger_range: float = 140.0
@export var spin_hit_interval: float = 0.2
@export var spin_guard_break: bool = false
@export var spin_stun_bonus: float = 0.18
@export var spin_warning_color: Color = Color(1.0, 0.18, 0.18, 0.3)
@export var blocked_counter_stun_duration: float = 0.44
@export var melee_trade_damage_scale: float = 1.0
@export var melee_trade_reach_bonus: float = 12.0
@export var melee_trade_depth_tolerance: float = 52.0
@export var xp_reward: int = 26
@export var drop_chance: float = 0.45
@export var drop_table: Array[String] = ["iron_shard", "sturdy_hide"]
@export var hit_stun_duration: float = 0.22
@export var outgoing_hit_stun_duration: float = 0.2
@export var hit_effect_duration: float = 0.14
@export var hurt_anim_duration: float = 0.4
@export var periodic_hurt_anim_enabled: bool = true
@export var periodic_hurt_anim_duration: float = 0.16
@export var periodic_hurt_anim_interval_min: float = 2.4
@export var periodic_hurt_anim_interval_max: float = 4.8
@export var hit_knockback_speed: float = 190.0
@export var hit_knockback_decay: float = 980.0
@export var lane_min_x: float = -760.0
@export var lane_max_x: float = 760.0
@export var lane_min_y: float = -165.0
@export var lane_max_y: float = 165.0
@export var soft_collision_enabled: bool = true
@export var soft_collision_radius: float = 36.0
@export var soft_collision_push_speed: float = 180.0
@export var soft_collision_max_push_per_frame: float = 3.5
@export var health_bar_width: float = 58.0
@export var health_bar_thickness: float = 5.0
@export var health_bar_y_offset: float = -62.0
@export var shadow_fear_break_duration: float = 5.0
@export var is_miniboss: bool = false
@export var debug_orientation_overlay: bool = false
@export var debug_focus_nearest_enemy_only: bool = true

const MONSTER_HD_HFRAMES: int = 10
const MONSTER_HD_VFRAMES: int = 20
const MONSTER_SHEET: Texture2D = preload("res://assets/external/ElthenAssets/mintotaur/Minotaur - Sprite Sheet Cropped.png")
const MONSTER_TEXTURES: Dictionary = {
	"idle": MONSTER_SHEET,
	"run": MONSTER_SHEET,
	"attack": MONSTER_SHEET,
	"spin": MONSTER_SHEET,
	"hurt": MONSTER_SHEET,
	"death": MONSTER_SHEET
}
const MONSTER_FPS: Dictionary = {
	"idle": 9.0,
	"run": 10.4,
	"attack": 10.8,
	"spin": 14.0,
	"hurt": 11.0,
	"death": 8.0
}
const MONSTER_ACTION_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"attack": 3,
	"spin": 6,
	"hurt": 4,
	"death": 9
}
const MONSTER_ACTION_FRAME_COUNTS: Dictionary = {
	"idle": 5,
	"run": 8,
	"attack": 9,
	"spin": 8,
	"hurt": 5,
	"death": 6
}
const MONSTER_ACTION_FRAME_COLUMNS: Dictionary = {
	"spin": [0, 1, 2, 3, 4, 5, 6, 7],
	"hurt": [1, 2, 3, 4]
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
var attack_prestrike_hold_left: float = 0.0
var attack_recovery_hold_left: float = 0.0
var pending_attack: bool = false
var player: Node = null
var dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

var hit_flash_left: float = 0.0
var hurt_anim_left: float = 0.0
var cosmetic_hurt_anim_left: float = 0.0
var periodic_hurt_anim_cooldown_left: float = 0.0
var stun_left: float = 0.0
var hitstop_left: float = 0.0
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
var committed_attack_facing_direction: Vector2 = Vector2.RIGHT
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
var spin_attack_cooldown_left: float = 0.0
var spin_charge_left: float = 0.0
var spin_active_left: float = 0.0
var spin_hit_tick_left: float = 0.0
var spin_warning_area: Polygon2D = null
var basic_attacks_since_last_spin: int = 0
var boss_loop_state: BossLoopState = BossLoopState.IDLE
var boss_state_time_left: float = 0.0
var boss_marked_ally: Node2D = null
var boss_lunge_direction: Vector2 = Vector2.RIGHT
var boss_lunge_hit_landed: bool = false
var boss_lunge_intercepted: bool = false
var boss_lunge_impact_triggered: bool = false
var boss_lunge_travel_distance: float = 0.0
var boss_lunge_last_impact_reason: String = ""
var boss_lunge_hit_ids: Dictionary = {}
var block_success_fx_count: int = 0
var pending_basic_block_success_fx: Array[Dictionary] = []
var boss_completed_lunge_cycles: int = 0
var boss_summon_emitted: bool = false
var boss_lunge_debug_logging_enabled: bool = false
var boss_mark_cycle_left: float = 0.0
var boss_summon_cycle_left: float = 0.0
var companion_target_refresh_left: float = 0.0
var boss_dps_mark_left: float = 0.0
var shadow_fear_left: float = 0.0
var shadow_fear_apply_count: int = 0
var shadow_fear_vfx_time: float = 0.0
var shadow_fear_vfx_root: Node2D = null
var shadow_fear_vfx_sprite: Sprite2D = null

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
	boss_lunge_debug_logging_enabled = _is_env_flag_enabled("BOSS_LUNGE_DEBUG")
	add_to_group("enemies")
	current_health = max_health
	attack_cooldown_left = randf_range(0.1, attack_cooldown)
	spin_attack_cooldown_left = randf_range(spin_attack_cooldown * 0.35, spin_attack_cooldown * 0.8)
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
	_setup_spin_warning_area()
	_setup_health_bar()
	_update_health_bar()
	_reacquire_player()
	_setup_debug_overlay()
	boss_mark_cycle_left = 0.0
	boss_summon_cycle_left = maxf(1.0, boss_summon_interval)
	companion_target_refresh_left = 0.0
	_reset_periodic_hurt_anim_cooldown()
	_set_boss_loop_state(BossLoopState.IDLE, 0.0)


func _is_env_flag_enabled(env_key: String) -> bool:
	var raw := OS.get_environment(env_key).strip_edges().to_lower()
	return not raw.is_empty() and raw not in ["0", "false", "off", "no"]


func _log_boss_lunge(message: String) -> void:
	if not boss_lunge_debug_logging_enabled:
		return
	if not is_miniboss:
		return
	print("[BOSS_LUNGE] %s" % message)


func _get_boss_lunge_marked_distance() -> float:
	if not _is_valid_mark_target(boss_marked_ally):
		return -1.0
	return global_position.distance_to(boss_marked_ally.global_position)


func _log_shadow_fear(message: String) -> void:
	print("[SHADOW_FEAR] %s" % message)


func _get_shadow_fear_debuff_texture() -> Texture2D:
	if shadow_fear_debuff_texture_cache != null:
		return shadow_fear_debuff_texture_cache
	var texture_path := ProjectSettings.globalize_path(SHADOW_FEAR_DEBUFF_TEXTURE_PATH)
	var image := Image.new()
	var error := image.load(texture_path)
	if error != OK:
		push_warning("Failed to load Shadow Fear debuff texture: %s (%s)" % [texture_path, error_string(error)])
		return null
	shadow_fear_debuff_texture_cache = ImageTexture.create_from_image(image)
	return shadow_fear_debuff_texture_cache


func is_shadow_fear_active() -> bool:
	return shadow_fear_left > 0.0


func has_hard_cc_active() -> bool:
	return shadow_fear_left > 0.0 or stun_left > 0.0


func apply_shadow_fear(duration: float) -> bool:
	if dead:
		return false
	var applied_duration := maxf(0.0, duration)
	if applied_duration <= 0.0:
		applied_duration = maxf(0.0, shadow_fear_break_duration)
	if applied_duration <= 0.0:
		return false
	if has_hard_cc_active():
		return false
	shadow_fear_left = applied_duration
	shadow_fear_apply_count += 1
	shadow_fear_vfx_time = 0.0
	_cancel_spin_attack()
	pending_attack = false
	attack_windup_left = 0.0
	attack_prestrike_hold_left = 0.0
	attack_recovery_hold_left = 0.0
	attack_anim_left = 0.0
	attack_flash_left = 0.0
	attack_telegraph.visible = false
	weapon_trail_alpha = 0.0
	weapon_trail.visible = false
	slash_effect.visible = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	_spawn_shadow_fear_vfx()
	_log_shadow_fear("APPLIED enemy=%s duration=%.2f" % [name, applied_duration])
	return true


func _clear_shadow_fear(broken_by_damage: bool) -> void:
	if shadow_fear_left <= 0.0 and (shadow_fear_vfx_root == null or not is_instance_valid(shadow_fear_vfx_root)):
		return
	shadow_fear_left = 0.0
	_shadow_fear_teardown_vfx()
	if broken_by_damage:
		_log_shadow_fear("BROKEN enemy=%s reason=damage" % name)
	else:
		_log_shadow_fear("EXPIRED enemy=%s" % name)


func _tick_shadow_fear_status(delta: float) -> void:
	if shadow_fear_left <= 0.0:
		return
	shadow_fear_left = maxf(0.0, shadow_fear_left - maxf(0.0, delta))
	_update_shadow_fear_vfx(delta)
	if shadow_fear_left <= 0.0:
		_clear_shadow_fear(false)


func _hold_shadow_fear_state(delta: float, to_player: Vector2) -> void:
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	attack_telegraph.visible = false
	weapon_trail.visible = false
	slash_effect.visible = false
	move_and_slide()
	_clamp_to_arena()
	_update_visuals(delta, to_player)
	_update_health_bar()


func _spawn_shadow_fear_vfx() -> void:
	_shadow_fear_teardown_vfx()
	shadow_fear_vfx_root = Node2D.new()
	shadow_fear_vfx_root.name = "ShadowFearVfx"
	shadow_fear_vfx_root.z_index = 5
	add_child(shadow_fear_vfx_root)
	shadow_fear_vfx_sprite = Sprite2D.new()
	shadow_fear_vfx_sprite.name = "FearBurst"
	shadow_fear_vfx_sprite.centered = true
	shadow_fear_vfx_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow_fear_vfx_sprite.texture = _get_shadow_fear_debuff_texture()
	shadow_fear_vfx_sprite.position = Vector2.ZERO
	shadow_fear_vfx_sprite.scale = SHADOW_FEAR_DEBUFF_SPRITE_SCALE
	shadow_fear_vfx_sprite.modulate = Color(0.64, 0.3, 0.9, 0.9)
	shadow_fear_vfx_root.add_child(shadow_fear_vfx_sprite)

	_update_shadow_fear_vfx(0.0)


func _update_shadow_fear_vfx(delta: float) -> void:
	if shadow_fear_vfx_root == null or not is_instance_valid(shadow_fear_vfx_root):
		return
	shadow_fear_vfx_time += maxf(0.0, delta)
	var pulse := 0.5 + (sin(shadow_fear_vfx_time * 6.8) * 0.5)
	var sway := sin(shadow_fear_vfx_time * 8.2)
	shadow_fear_vfx_root.position = Vector2(sway * 1.8, -28.0 + (sin(shadow_fear_vfx_time * 3.2) * 3.2))
	if shadow_fear_vfx_sprite != null and is_instance_valid(shadow_fear_vfx_sprite):
		var sprite_scale := lerpf(0.36, 0.54, pulse)
		shadow_fear_vfx_sprite.scale = Vector2(sprite_scale, sprite_scale)
		shadow_fear_vfx_sprite.rotation = sway * 0.12
		shadow_fear_vfx_sprite.modulate = Color(0.6 + (pulse * 0.18), 0.24 + (pulse * 0.14), 0.86 + (pulse * 0.12), lerpf(0.62, 1.0, pulse))


func _shadow_fear_teardown_vfx() -> void:
	if is_instance_valid(shadow_fear_vfx_root):
		shadow_fear_vfx_root.queue_free()
	shadow_fear_vfx_root = null
	shadow_fear_vfx_sprite = null


func _exit_tree() -> void:
	_teardown_debug_overlay()
	_shadow_fear_teardown_vfx()
	if is_instance_valid(spin_warning_area):
		spin_warning_area.queue_free()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if use_single_phase_loop:
		_physics_process_single_phase(delta)
		return
	if hitstop_left > 0.0:
		hitstop_left = maxf(0.0, hitstop_left - delta)
		_tick_shadow_fear_status(delta)
		if not is_instance_valid(player):
			_reacquire_player()
		var freeze_to_player := Vector2.RIGHT
		if is_instance_valid(player):
			freeze_to_player = player.global_position - global_position
		velocity = Vector2.ZERO
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(0.0, freeze_to_player)
		_update_health_bar()
		return

	var previous_attack_anim_left := attack_anim_left
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	hurt_anim_left = maxf(0.0, hurt_anim_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	attack_flash_left = maxf(0.0, attack_flash_left - delta)
	attack_anim_left = maxf(0.0, attack_anim_left - delta)
	attack_recovery_hold_left = maxf(0.0, attack_recovery_hold_left - delta)
	slash_effect_left = maxf(0.0, slash_effect_left - delta)
	spin_attack_cooldown_left = maxf(0.0, spin_attack_cooldown_left - delta)
	_tick_pending_basic_block_success_fx(delta)
	_tick_shadow_fear_status(delta)
	weapon_trail_alpha = maxf(0.0, weapon_trail_alpha - (delta * 1.45))
	if previous_attack_anim_left > 0.0 and attack_anim_left <= 0.0:
		attack_recovery_hold_left = maxf(attack_recovery_hold_left, attack_recovery_hold_duration)

	companion_target_refresh_left = maxf(0.0, companion_target_refresh_left - delta)
	if not is_instance_valid(player) or companion_target_refresh_left <= 0.0:
		_reacquire_player()
		companion_target_refresh_left = maxf(0.05, companion_target_refresh_interval)
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_update_visuals(delta, Vector2.RIGHT)
		_update_health_bar()
		return

	var to_player: Vector2 = player.global_position - global_position
	var lock_facing_from_hit := stun_left > 0.0 or hurt_anim_left > 0.0
	var committed_attack_active := (pending_attack or attack_anim_left > 0.0 or attack_recovery_hold_left > 0.0 or spin_charge_left > 0.0 or spin_active_left > 0.0) and committed_attack_facing_direction.length_squared() > 0.0001
	if not lock_facing_from_hit:
		if committed_attack_active:
			if using_external_monster_sprite:
				external_sprite_facing_direction = committed_attack_facing_direction
				rotation = 0.0
			else:
				rotation = lerp_angle(rotation, committed_attack_facing_direction.angle(), clampf(delta * 16.0, 0.0, 1.0))
		elif to_player.length_squared() > 0.0001:
			if using_external_monster_sprite:
				external_sprite_facing_direction = to_player.normalized()
				rotation = 0.0
			else:
				rotation = lerp_angle(rotation, to_player.angle(), clampf(delta * 10.0, 0.0, 1.0))

	if stun_left > 0.0:
		_cancel_spin_attack()
		pending_attack = false
		attack_windup_left = 0.0
		attack_prestrike_hold_left = 0.0
		attack_recovery_hold_left = 0.0
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
		attack_telegraph.visible = false
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if shadow_fear_left > 0.0:
		_hold_shadow_fear_state(delta, to_player)
		return

	if spin_charge_left > 0.0:
		velocity = Vector2.ZERO
		spin_charge_left = maxf(0.0, spin_charge_left - delta)
		if spin_charge_left <= 0.0:
			_begin_spin_attack()
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if spin_active_left > 0.0:
		velocity = Vector2.ZERO
		spin_active_left = maxf(0.0, spin_active_left - delta)
		spin_hit_tick_left = maxf(0.0, spin_hit_tick_left - delta)
		if spin_hit_tick_left <= 0.0:
			_perform_spin_attack_hit()
			spin_hit_tick_left = spin_hit_interval
		if spin_active_left <= 0.0:
			_finish_spin_attack()
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if pending_attack:
		velocity = Vector2.ZERO
		if attack_windup_left > 0.0:
			attack_windup_left = maxf(0.0, attack_windup_left - delta)
			if attack_windup_left <= 0.0:
				attack_prestrike_hold_left = maxf(0.0, attack_prestrike_hold_duration)
				if attack_prestrike_hold_left > 0.0:
					var hold_frame_count := int(MONSTER_ACTION_FRAME_COUNTS.get("attack", MONSTER_HD_HFRAMES))
					var hold_frame := clampi(attack_hold_frame, 0, max(0, hold_frame_count - 1))
					monster_anim_time = float(hold_frame)
		elif attack_prestrike_hold_left > 0.0:
			attack_prestrike_hold_left = maxf(0.0, attack_prestrike_hold_left - delta)
		if attack_windup_left <= 0.0 and attack_prestrike_hold_left <= 0.0:
			pending_attack = false
			attack_cooldown_left = attack_cooldown
			_perform_attack()
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if attack_recovery_hold_left > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		_apply_soft_enemy_separation(delta)
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
			var spin_ready := spin_attack_enabled \
				and spin_attack_cooldown_left <= 0.0 \
				and distance_to_player <= spin_trigger_range \
				and basic_attacks_since_last_spin >= maxi(0, basic_attacks_required_for_spin)
			if spin_ready:
				_begin_spin_charge(to_player)
			else:
				pending_attack = true
				attack_windup_left = attack_windup
				attack_prestrike_hold_left = 0.0
				attack_recovery_hold_left = 0.0
				var initial_attack_facing := to_player.normalized()
				if initial_attack_facing.length_squared() <= 0.0001:
					initial_attack_facing = external_sprite_facing_direction
				if initial_attack_facing.length_squared() <= 0.0001:
					initial_attack_facing = Vector2.RIGHT
				committed_attack_facing_direction = initial_attack_facing.normalized()

	move_and_slide()
	_apply_soft_enemy_separation(delta)
	_clamp_to_arena()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	_update_visuals(delta, to_player)
	_update_health_bar()


func _physics_process_single_phase(delta: float) -> void:
	if hitstop_left > 0.0:
		hitstop_left = maxf(0.0, hitstop_left - delta)
		_tick_shadow_fear_status(delta)
		if not is_instance_valid(player):
			_reacquire_player()
		var freeze_to_player := Vector2.RIGHT
		if is_instance_valid(player):
			freeze_to_player = player.global_position - global_position
		velocity = Vector2.ZERO
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(0.0, freeze_to_player)
		_update_health_bar()
		return

	_tick_enemy_runtime_timers(delta)
	if not is_instance_valid(player) or companion_target_refresh_left <= 0.0:
		_reacquire_player()
		companion_target_refresh_left = maxf(0.05, companion_target_refresh_interval)
	var to_player := Vector2.RIGHT
	if is_instance_valid(player):
		to_player = player.global_position - global_position

	_update_boss_facing(delta, to_player)

	if stun_left > 0.0:
		_cancel_spin_attack()
		pending_attack = false
		attack_windup_left = 0.0
		attack_prestrike_hold_left = 0.0
		attack_recovery_hold_left = 0.0
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
		attack_telegraph.visible = false
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if shadow_fear_left > 0.0:
		_hold_shadow_fear_state(delta, to_player)
		return

	if pending_attack and boss_loop_state == BossLoopState.IDLE:
		velocity = Vector2.ZERO
		if attack_windup_left > 0.0:
			attack_windup_left = maxf(0.0, attack_windup_left - delta)
			if attack_windup_left <= 0.0:
				attack_prestrike_hold_left = maxf(0.0, attack_prestrike_hold_duration)
				if attack_prestrike_hold_left > 0.0:
					var hold_frame_count := int(MONSTER_ACTION_FRAME_COUNTS.get("attack", MONSTER_HD_HFRAMES))
					var hold_frame := clampi(attack_hold_frame, 0, max(0, hold_frame_count - 1))
					monster_anim_time = float(hold_frame)
		elif attack_prestrike_hold_left > 0.0:
			attack_prestrike_hold_left = maxf(0.0, attack_prestrike_hold_left - delta)
		if attack_windup_left <= 0.0 and attack_prestrike_hold_left <= 0.0:
			pending_attack = false
			attack_cooldown_left = attack_cooldown
			_perform_attack()
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	if attack_recovery_hold_left > 0.0 and boss_loop_state == BossLoopState.IDLE:
		velocity = Vector2.ZERO
		move_and_slide()
		_apply_soft_enemy_separation(delta)
		_clamp_to_arena()
		_update_visuals(delta, to_player)
		_update_health_bar()
		return

	_tick_single_phase_boss_loop(delta, to_player)
	_apply_idle_cooldown_melee_hold(to_player)
	_tick_periodic_hurt_animation()

	move_and_slide()
	_apply_soft_enemy_separation(delta)
	_clamp_to_arena()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	_update_visuals(delta, to_player)
	_update_health_bar()


func _apply_idle_cooldown_melee_hold(to_player: Vector2) -> void:
	if boss_loop_state != BossLoopState.IDLE:
		return
	if pending_attack or attack_recovery_hold_left > 0.0:
		return
	if attack_cooldown_left <= 0.0:
		return
	if to_player.length_squared() <= 0.0001:
		return
	var distance_to_player := to_player.length()
	var melee_trigger_range := maxf(
		attack_range + 20.0,
		attack_range + (basic_attack_hit_end_bonus * 0.75)
	)
	var melee_hold_range := maxf(melee_trigger_range + 18.0, attack_range + basic_attack_hit_end_bonus + 16.0)
	if distance_to_player <= melee_hold_range:
		velocity = Vector2.ZERO


func _tick_enemy_runtime_timers(delta: float) -> void:
	var previous_attack_anim_left := attack_anim_left
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	hurt_anim_left = maxf(0.0, hurt_anim_left - delta)
	cosmetic_hurt_anim_left = maxf(0.0, cosmetic_hurt_anim_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	attack_flash_left = maxf(0.0, attack_flash_left - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	attack_anim_left = maxf(0.0, attack_anim_left - delta)
	attack_recovery_hold_left = maxf(0.0, attack_recovery_hold_left - delta)
	slash_effect_left = maxf(0.0, slash_effect_left - delta)
	spin_attack_cooldown_left = maxf(0.0, spin_attack_cooldown_left - delta)
	boss_mark_cycle_left = maxf(0.0, boss_mark_cycle_left - delta)
	boss_summon_cycle_left = maxf(0.0, boss_summon_cycle_left - delta)
	boss_dps_mark_left = maxf(0.0, boss_dps_mark_left - delta)
	companion_target_refresh_left = maxf(0.0, companion_target_refresh_left - delta)
	periodic_hurt_anim_cooldown_left = maxf(0.0, periodic_hurt_anim_cooldown_left - delta)
	_tick_pending_basic_block_success_fx(delta)
	_tick_shadow_fear_status(delta)
	weapon_trail_alpha = maxf(0.0, weapon_trail_alpha - (delta * 1.45))
	if previous_attack_anim_left > 0.0 and attack_anim_left <= 0.0:
		attack_recovery_hold_left = maxf(attack_recovery_hold_left, attack_recovery_hold_duration)


func _tick_periodic_hurt_animation() -> void:
	if not periodic_hurt_anim_enabled or not is_miniboss or not use_single_phase_loop:
		cosmetic_hurt_anim_left = 0.0
		return
	if hurt_anim_left > 0.0:
		cosmetic_hurt_anim_left = 0.0
		return
	if _is_combat_action_active_for_periodic_hurt():
		cosmetic_hurt_anim_left = 0.0
		return
	if periodic_hurt_anim_cooldown_left > 0.0:
		return
	cosmetic_hurt_anim_left = maxf(cosmetic_hurt_anim_left, maxf(0.06, periodic_hurt_anim_duration))
	_reset_periodic_hurt_anim_cooldown()


func _is_combat_action_active_for_periodic_hurt() -> bool:
	if stun_left > 0.0 or hitstop_left > 0.0 or shadow_fear_left > 0.0:
		return true
	if pending_attack \
		or attack_windup_left > 0.0 \
		or attack_prestrike_hold_left > 0.0 \
		or attack_anim_left > 0.0 \
		or attack_recovery_hold_left > 0.0 \
		or spin_charge_left > 0.0 \
		or spin_active_left > 0.0:
		return true
	return boss_loop_state != BossLoopState.IDLE


func _is_lunge_charge_visual_active() -> bool:
	return use_single_phase_loop \
		and boss_loop_state == BossLoopState.LUNGE \
		and not boss_lunge_impact_triggered \
		and not boss_lunge_intercepted


func _reset_periodic_hurt_anim_cooldown() -> void:
	var min_interval := maxf(0.1, periodic_hurt_anim_interval_min)
	var max_interval := maxf(min_interval, periodic_hurt_anim_interval_max)
	periodic_hurt_anim_cooldown_left = randf_range(min_interval, max_interval)


func _update_boss_facing(delta: float, to_player: Vector2) -> void:
	var lock_facing_from_hit := stun_left > 0.0 or hurt_anim_left > 0.0
	if lock_facing_from_hit:
		return
	var committed_attack_active := (pending_attack or attack_anim_left > 0.0 or attack_recovery_hold_left > 0.0 or boss_loop_state == BossLoopState.WINDUP or boss_loop_state == BossLoopState.LUNGE) and committed_attack_facing_direction.length_squared() > 0.0001
	if committed_attack_active:
		if using_external_monster_sprite:
			external_sprite_facing_direction = committed_attack_facing_direction
			rotation = 0.0
		else:
			rotation = lerp_angle(rotation, committed_attack_facing_direction.angle(), clampf(delta * 16.0, 0.0, 1.0))
	elif to_player.length_squared() > 0.0001:
		if using_external_monster_sprite:
			external_sprite_facing_direction = to_player.normalized()
			rotation = 0.0
		else:
			rotation = lerp_angle(rotation, to_player.angle(), clampf(delta * 10.0, 0.0, 1.0))


func _tick_single_phase_boss_loop(delta: float, to_player: Vector2) -> void:
	match boss_loop_state:
		BossLoopState.IDLE:
			_tick_boss_idle_state(to_player)
		BossLoopState.MARK:
			_tick_boss_mark_state(delta)
		BossLoopState.WINDUP:
			_tick_boss_windup_state(delta)
		BossLoopState.LUNGE:
			_tick_boss_lunge_state(delta)
		BossLoopState.VULNERABLE:
			_tick_boss_vulnerable_state(delta)
		BossLoopState.SUMMON:
			_tick_boss_summon_state(delta)
		_:
			_set_boss_loop_state(BossLoopState.IDLE, 0.0)
			velocity = Vector2.ZERO


func _tick_boss_idle_state(to_player: Vector2) -> void:
	velocity = Vector2.ZERO
	pending_attack = false
	attack_windup_left = 0.0
	attack_prestrike_hold_left = 0.0
	if attack_recovery_hold_left > 0.0:
		return
	if boss_can_summon_minions and boss_summon_count > 0 and boss_summon_cycle_left <= 0.0:
		_set_boss_loop_state(BossLoopState.SUMMON, boss_summon_duration)
		boss_summon_cycle_left = maxf(1.0, boss_summon_interval)
		return
	if boss_mark_cycle_left > 0.0:
		_tick_boss_idle_basic_pressure(to_player)
		return
	var mark_target := _select_mark_target()
	if mark_target == null:
		_tick_boss_idle_basic_pressure(to_player)
		return
	boss_marked_ally = mark_target
	var to_marked := mark_target.global_position - global_position
	if to_marked.length_squared() <= 0.0001:
		# If we are stacked on top of the mark target, keep the loop progressing.
		# Use a stable fallback facing instead of bailing out of the attack cycle.
		if committed_attack_facing_direction.length_squared() > 0.0001:
			to_marked = committed_attack_facing_direction
		elif to_player.length_squared() > 0.0001:
			to_marked = to_player
		else:
			to_marked = Vector2.RIGHT
	committed_attack_facing_direction = to_marked.normalized()
	boss_mark_cycle_left = maxf(0.4, boss_mark_cycle_interval)
	_set_boss_loop_state(BossLoopState.MARK, boss_mark_duration)


func _tick_boss_idle_basic_pressure(to_player: Vector2) -> void:
	if to_player.length_squared() <= 0.0001:
		return
	var distance_to_player := to_player.length()
	# Start basic swings from farther out and hold earlier to avoid body-pushing.
	var melee_trigger_range := maxf(
		attack_range + 20.0,
		attack_range + (basic_attack_hit_end_bonus * 0.75)
	)
	var melee_hold_range := maxf(melee_trigger_range + 18.0, attack_range + basic_attack_hit_end_bonus + 16.0)
	if attack_cooldown_left <= 0.0:
		if distance_to_player <= melee_trigger_range:
			pending_attack = true
			attack_windup_left = attack_windup
			attack_prestrike_hold_left = 0.0
			attack_recovery_hold_left = 0.0
			var initial_attack_facing := to_player.normalized()
			if initial_attack_facing.length_squared() <= 0.0001:
				initial_attack_facing = external_sprite_facing_direction
			if initial_attack_facing.length_squared() <= 0.0001:
				initial_attack_facing = Vector2.RIGHT
			committed_attack_facing_direction = initial_attack_facing.normalized()
			velocity = Vector2.ZERO
		else:
			velocity = to_player.normalized() * (move_speed * 0.55)
	elif distance_to_player <= attack_range:
		# Once in core melee range, hold position and wait for cooldown.
		# This prevents body-pushing the tank while the next swing is charging.
		velocity = Vector2.ZERO
	elif distance_to_player > melee_hold_range:
		velocity = to_player.normalized() * (move_speed * 0.42)
	else:
		velocity = Vector2.ZERO


func _tick_boss_mark_state(delta: float) -> void:
	velocity = Vector2.ZERO
	var mark_target := _get_or_reacquire_mark_target()
	if mark_target == null:
		_set_boss_loop_state(BossLoopState.IDLE, 0.0)
		return
	var to_marked := mark_target.global_position - global_position
	if to_marked.length_squared() > 0.0001:
		committed_attack_facing_direction = to_marked.normalized()
	_tick_boss_state_timer(delta)
	if boss_state_time_left <= 0.0:
		_set_boss_loop_state(BossLoopState.WINDUP, boss_windup_duration)


func _tick_boss_windup_state(delta: float) -> void:
	velocity = Vector2.ZERO
	var mark_target := _get_or_reacquire_mark_target()
	if mark_target == null:
		_set_boss_loop_state(BossLoopState.IDLE, 0.0)
		return
	var to_marked := mark_target.global_position - global_position
	if to_marked.length_squared() > 0.0001:
		committed_attack_facing_direction = to_marked.normalized()
	_tick_boss_state_timer(delta)
	if boss_state_time_left > 0.0:
		return
	_begin_boss_lunge(mark_target.global_position)


func _begin_boss_lunge(marked_position: Vector2) -> void:
	var lunge_direction := marked_position - global_position
	var marked_distance := lunge_direction.length()
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = committed_attack_facing_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = Vector2.RIGHT
	boss_lunge_direction = lunge_direction.normalized()
	committed_attack_facing_direction = boss_lunge_direction
	boss_lunge_hit_landed = false
	boss_lunge_intercepted = false
	boss_lunge_impact_triggered = false
	boss_lunge_travel_distance = 0.0
	boss_lunge_last_impact_reason = ""
	boss_lunge_hit_ids.clear()
	var base_lunge_duration := maxf(0.12, boss_lunge_duration)
	var max_lunge_duration := maxf(base_lunge_duration, boss_lunge_max_duration)
	var lunge_speed := maxf(40.0, boss_lunge_speed)
	var required_duration := (marked_distance + maxf(0.0, boss_lunge_distance_padding)) / lunge_speed
	var resolved_lunge_duration := clampf(maxf(base_lunge_duration, required_duration), base_lunge_duration, max_lunge_duration)
	var target_name: String = String(boss_marked_ally.name) if _is_valid_mark_target(boss_marked_ally) else "None"
	_log_boss_lunge("BEGIN target=%s marked_distance=%.2f duration=%.3f direction=(%.2f, %.2f)" % [
		target_name,
		_get_boss_lunge_marked_distance(),
		resolved_lunge_duration,
		boss_lunge_direction.x,
		boss_lunge_direction.y
	])
	_set_boss_loop_state(BossLoopState.LUNGE, resolved_lunge_duration)


func _trigger_boss_lunge_impact(trigger_reason: String = "unknown") -> void:
	if boss_lunge_impact_triggered:
		return
	boss_lunge_impact_triggered = true
	boss_lunge_last_impact_reason = trigger_reason
	_log_boss_lunge("IMPACT reason=%s travel=%.2f marked_distance=%.2f" % [
		trigger_reason,
		boss_lunge_travel_distance,
		_get_boss_lunge_marked_distance()
	])
	attack_flash_left = maxf(attack_flash_left, 0.18)
	_start_attack_animation(maxf(0.16, boss_lunge_duration * 0.92), 1.48)
	_trigger_slash_effect(maxf(26.0, boss_lunge_hit_length), 72.0, Color(0.98, 0.42, 0.26, 0.9), 0.2, 4.8)


func _is_boss_lunge_contact_with_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var lunge_direction := boss_lunge_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = committed_attack_facing_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = Vector2.RIGHT
	lunge_direction = lunge_direction.normalized()
	# Use current-position overlap only so impact cannot fire early.
	var contact_radius := maxf(7.0, boss_lunge_tip_radius * 0.28)
	var to_target := target.global_position - global_position
	var forward_distance := to_target.dot(lunge_direction)
	if forward_distance < -contact_radius:
		return false
	return to_target.length_squared() <= contact_radius * contact_radius


func _is_boss_lunge_contact_with_any_friendly() -> bool:
	for candidate in _get_attackable_friendly_targets():
		if _is_boss_lunge_contact_with_target(candidate):
			return true
	return false


func _get_boss_lunge_blocking_player() -> Player:
	var lunge_direction := boss_lunge_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = committed_attack_facing_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = Vector2.RIGHT
	lunge_direction = lunge_direction.normalized()
	var shield_check_length := maxf(32.0, boss_lunge_hit_length)
	var segment_start := global_position + (lunge_direction * boss_lunge_hit_start_offset)
	var segment_end := segment_start + (lunge_direction * shield_check_length)
	var half_width := maxf(12.0, boss_lunge_hit_half_width)
	var tip_radius := maxf(10.0, boss_lunge_tip_radius)
	for player_node in get_tree().get_nodes_in_group("player"):
		var player_target := player_node as Player
		if player_target == null or not is_instance_valid(player_target) or player_target.is_dead:
			continue
		if _is_lunge_intersecting_player_block_shield(player_target, segment_start, segment_end, half_width, tip_radius):
			return player_target
	return null


func _spawn_lunge_block_success_effect(blocking_player: Player) -> void:
	if blocking_player == null or not is_instance_valid(blocking_player):
		return
	block_success_fx_count += 1
	var shield_center := blocking_player.global_position + Vector2(0.0, -10.0)
	if blocking_player.has_method("get_block_shield_center_global"):
		var center_variant: Variant = blocking_player.call("get_block_shield_center_global")
		if center_variant is Vector2:
			shield_center = center_variant
	_spawn_hit_effect(shield_center, Color(0.62, 0.96, 1.0, 0.96), maxf(14.0, boss_lunge_block_effect_size))
	_spawn_hit_effect(shield_center + (boss_lunge_direction.normalized() * 8.0), Color(1.0, 1.0, 1.0, 0.9), maxf(10.0, boss_lunge_block_effect_size * 0.78))
	_trigger_slash_effect(maxf(36.0, boss_lunge_hit_length * 0.62), 138.0, Color(0.62, 0.95, 1.0, 0.9), 0.24, 7.2)
	attack_flash_left = maxf(attack_flash_left, 0.24)
	apply_hitstop(maxf(0.0, boss_lunge_block_hitstop))


func _queue_basic_block_success_effect(blocked_player: Player) -> void:
	if blocked_player == null or not is_instance_valid(blocked_player):
		return
	var delay := maxf(0.0, basic_block_success_fx_delay)
	if delay <= 0.0:
		_spawn_lunge_block_success_effect(blocked_player)
		_log_boss_lunge("BASIC_BLOCK_FX target=%s delay=0.00" % blocked_player.name)
		return
	pending_basic_block_success_fx.append({
		"player": blocked_player,
		"time_left": delay
	})


func _tick_pending_basic_block_success_fx(delta: float) -> void:
	if pending_basic_block_success_fx.is_empty():
		return
	var active_entries: Array[Dictionary] = []
	var step := maxf(0.0, delta)
	for pending in pending_basic_block_success_fx:
		var blocked_player := pending.get("player") as Player
		if blocked_player == null or not is_instance_valid(blocked_player):
			continue
		var time_left := maxf(0.0, float(pending.get("time_left", 0.0)) - step)
		if time_left > 0.0:
			pending["time_left"] = time_left
			active_entries.append(pending)
			continue
		_spawn_lunge_block_success_effect(blocked_player)
		_log_boss_lunge("BASIC_BLOCK_FX target=%s delay=%.2f" % [blocked_player.name, basic_block_success_fx_delay])
	pending_basic_block_success_fx = active_entries


func _tick_boss_lunge_state(delta: float) -> void:
	var lunge_step_distance := maxf(0.0, boss_lunge_speed) * maxf(0.0, delta)
	if not boss_lunge_impact_triggered:
		if _is_valid_mark_target(boss_marked_ally):
			var to_marked := boss_marked_ally.global_position - global_position
			if to_marked.length_squared() > 0.0001:
				var desired_lunge_direction := to_marked.normalized()
				var steer_blend := clampf(delta * maxf(0.0, boss_lunge_steer_rate), 0.0, 1.0)
				boss_lunge_direction = boss_lunge_direction.slerp(desired_lunge_direction, steer_blend).normalized()
				committed_attack_facing_direction = boss_lunge_direction
		var collateral_unlock_distance := maxf(0.0, boss_lunge_collateral_trigger_travel)
		var allow_collateral_impact := boss_lunge_travel_distance >= collateral_unlock_distance
		var shield_unlock_distance := minf(collateral_unlock_distance, maxf(8.0, boss_lunge_collateral_trigger_travel * 0.5))
		var allow_shield_intercept := boss_lunge_travel_distance >= shield_unlock_distance
		var blocking_player := _get_boss_lunge_blocking_player()
		if allow_shield_intercept and blocking_player != null:
			_spawn_lunge_block_success_effect(blocking_player)
			_apply_blocked_counter_stun()
			boss_lunge_intercepted = true
			_trigger_boss_lunge_impact("shield_intercept")
		elif _is_boss_lunge_contact_with_target(boss_marked_ally):
			_trigger_boss_lunge_impact("marked_contact")
		elif allow_collateral_impact and _is_boss_lunge_contact_with_any_friendly():
			_trigger_boss_lunge_impact("collateral_contact")
	if boss_lunge_impact_triggered and not boss_lunge_intercepted:
		_attempt_boss_lunge_hits()
	if boss_lunge_intercepted:
		velocity = Vector2.ZERO
		boss_completed_lunge_cycles += 1
		boss_marked_ally = null
		_face_player_after_lunge()
		_set_boss_loop_state(BossLoopState.VULNERABLE, boss_vulnerable_duration)
		return
	if boss_lunge_impact_triggered:
		velocity = Vector2.ZERO
	else:
		velocity = boss_lunge_direction * maxf(40.0, boss_lunge_speed)
		boss_lunge_travel_distance += lunge_step_distance
	_tick_boss_state_timer(delta)
	if boss_state_time_left > 0.0:
		return
	if not boss_lunge_impact_triggered:
		_log_boss_lunge("END no_impact travel=%.2f marked_distance=%.2f" % [
			boss_lunge_travel_distance,
			_get_boss_lunge_marked_distance()
		])
	elif not boss_lunge_hit_landed:
		_log_boss_lunge("END impact_no_hit travel=%.2f marked_distance=%.2f intercepted=%s" % [
			boss_lunge_travel_distance,
			_get_boss_lunge_marked_distance(),
			str(boss_lunge_intercepted)
		])
	else:
		_log_boss_lunge("END hit_landed travel=%.2f marked_distance=%.2f intercepted=%s" % [
			boss_lunge_travel_distance,
			_get_boss_lunge_marked_distance(),
			str(boss_lunge_intercepted)
		])
	boss_completed_lunge_cycles += 1
	if boss_lunge_intercepted or not boss_lunge_hit_landed:
		boss_marked_ally = null
		_face_player_after_lunge()
		_set_boss_loop_state(BossLoopState.VULNERABLE, boss_vulnerable_duration)
		return
	boss_marked_ally = null
	_face_player_after_lunge()
	attack_recovery_hold_left = maxf(attack_recovery_hold_left, boss_short_recovery_duration)
	_set_boss_loop_state(BossLoopState.IDLE, 0.0)


func _face_player_after_lunge() -> void:
	var player_node := player as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var to_player: Vector2 = player_node.global_position - global_position
	if to_player.length_squared() > 0.0001:
		committed_attack_facing_direction = to_player.normalized()


func _tick_boss_vulnerable_state(delta: float) -> void:
	velocity = Vector2.ZERO
	var vulnerable_target: Node2D = null
	if not is_instance_valid(player):
		_reacquire_player()
	if is_instance_valid(player):
		vulnerable_target = player as Node2D
	elif _is_valid_mark_target(boss_marked_ally):
		vulnerable_target = boss_marked_ally
	if vulnerable_target != null and is_instance_valid(vulnerable_target):
		var to_target := vulnerable_target.global_position - global_position
		if to_target.length_squared() > 0.0001:
			var slow_speed := move_speed * clampf(boss_vulnerable_speed_multiplier, 0.0, 1.0)
			velocity = to_target.normalized() * slow_speed
	_tick_boss_state_timer(delta)
	if boss_state_time_left <= 0.0:
		_set_boss_loop_state(BossLoopState.IDLE, 0.0)


func _tick_boss_summon_state(delta: float) -> void:
	velocity = Vector2.ZERO
	if not boss_summon_emitted:
		boss_summon_emitted = true
		if boss_can_summon_minions and boss_summon_count > 0:
			summon_minions_requested.emit(self, maxi(1, boss_summon_count))
		_spawn_hit_effect(global_position + Vector2(0.0, -18.0), Color(1.0, 0.36, 0.3, 0.95), 11.0)
	_tick_boss_state_timer(delta)
	if boss_state_time_left <= 0.0:
		_set_boss_loop_state(BossLoopState.IDLE, 0.0)


func _attempt_boss_lunge_hits() -> void:
	var lunge_targets := _query_friendly_hits_for_lunge()
	if lunge_targets.is_empty():
		return
	var lunge_direction := boss_lunge_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = committed_attack_facing_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = Vector2.RIGHT
	lunge_direction = lunge_direction.normalized()
	var contact_length := maxf(18.0, boss_lunge_hit_length * 0.34)
	var segment_start := global_position + (lunge_direction * boss_lunge_hit_start_offset)
	var segment_end := segment_start + (lunge_direction * contact_length)
	var half_width := maxf(12.0, boss_lunge_hit_half_width * 0.5)
	var tip_radius := maxf(10.0, boss_lunge_tip_radius * 0.75)
	for target in lunge_targets:
		var target_id := target.get_instance_id()
		if boss_lunge_hit_ids.has(target_id):
			continue
		boss_lunge_hit_ids[target_id] = true
		var player_target := target as Player
		var blocked_by_player_arc := false
		if player_target != null:
			blocked_by_player_arc = _is_target_blocking_attack(player_target)
			var blocked_by_shield_area := player_target.is_blocking and _is_lunge_intersecting_player_block_shield(player_target, segment_start, segment_end, half_width, tip_radius)
			if blocked_by_shield_area:
				_spawn_lunge_block_success_effect(player_target)
				_apply_blocked_counter_stun()
				boss_lunge_intercepted = true
				return
		var landed := _attempt_friendly_hit(
			target,
			attack_damage * boss_lunge_damage_multiplier,
			false,
			outgoing_hit_stun_duration + boss_lunge_stun_bonus,
			boss_lunge_knockback_scale
		)
		if player_target != null and blocked_by_player_arc:
			boss_lunge_intercepted = true
			if landed:
				boss_lunge_hit_landed = true
				_spawn_hit_effect(target.global_position + Vector2(0.0, -15.0), Color(1.0, 0.54, 0.34, 0.96), maxf(12.0, boss_lunge_impact_effect_size))
				_log_boss_lunge("HIT target=%s blocked_arc=true distance=%.2f kb=%.2f" % [target.name, global_position.distance_to(target.global_position), boss_lunge_knockback_scale])
			return
		if not landed:
			continue
		boss_lunge_hit_landed = true
		_spawn_hit_effect(target.global_position + Vector2(0.0, -15.0), Color(1.0, 0.54, 0.34, 0.96), maxf(12.0, boss_lunge_impact_effect_size))
		_log_boss_lunge("HIT target=%s blocked_arc=false distance=%.2f kb=%.2f" % [target.name, global_position.distance_to(target.global_position), boss_lunge_knockback_scale])
		if player_target != null:
			boss_lunge_intercepted = true
			return
		return


func _query_friendly_hits_for_lunge() -> Array[Node2D]:
	var hit_targets: Array[Node2D] = []
	var lunge_direction := boss_lunge_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = committed_attack_facing_direction
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = Vector2.RIGHT
	lunge_direction = lunge_direction.normalized()
	var contact_length := maxf(18.0, boss_lunge_hit_length * 0.34)
	var segment_start := global_position + (lunge_direction * boss_lunge_hit_start_offset)
	var segment_end := segment_start + (lunge_direction * contact_length)
	var half_width := maxf(12.0, boss_lunge_hit_half_width * 0.5)
	var tip_radius := maxf(10.0, boss_lunge_tip_radius * 0.75)
	for candidate in _get_attackable_friendly_targets():
		if _is_boss_lunge_contact_with_target(candidate):
			hit_targets.append(candidate)
			continue
		var player_candidate := candidate as Player
		if player_candidate != null and _is_lunge_intersecting_player_block_shield(player_candidate, segment_start, segment_end, half_width, tip_radius):
			hit_targets.append(candidate)
			continue
		var distance_to_sweep := _distance_to_segment(candidate.global_position, segment_start, segment_end)
		if distance_to_sweep <= half_width:
			hit_targets.append(candidate)
			continue
		if candidate.global_position.distance_to(segment_end) <= tip_radius:
			hit_targets.append(candidate)
	return hit_targets


func _is_lunge_intersecting_player_block_shield(player_target: Player, segment_start: Vector2, segment_end: Vector2, half_width: float, tip_radius: float) -> bool:
	if player_target == null or not is_instance_valid(player_target):
		return false
	var block_held := player_target.is_blocking
	var shield_pose_active := false
	if player_target.has_method("is_block_shield_active"):
		shield_pose_active = bool(player_target.call("is_block_shield_active"))
	if not block_held and not shield_pose_active:
		return false

	if shield_pose_active and player_target.has_method("is_point_inside_block_shield") and bool(player_target.call("is_point_inside_block_shield", global_position)):
		return true

	var shield_center := player_target.global_position
	if player_target.has_method("get_block_shield_center_global"):
		var center_variant: Variant = player_target.call("get_block_shield_center_global")
		if center_variant is Vector2:
			shield_center = center_variant

	var shield_radius := maxf(8.0, player_target.block_shield_radius)
	var lunge_reach_radius := maxf(half_width, tip_radius)
	var distance_to_sweep := _distance_to_segment(shield_center, segment_start, segment_end)
	return distance_to_sweep <= (shield_radius + lunge_reach_radius)


func _set_boss_loop_state(next_state: BossLoopState, duration: float) -> void:
	boss_loop_state = next_state
	boss_state_time_left = maxf(0.0, duration)
	match boss_loop_state:
		BossLoopState.IDLE:
			pending_attack = false
			attack_windup_left = 0.0
			attack_prestrike_hold_left = 0.0
			_hide_spin_warning()
		BossLoopState.MARK:
			pending_attack = false
			attack_windup_left = 0.0
			attack_prestrike_hold_left = 0.0
			_show_spin_warning()
		BossLoopState.WINDUP:
			pending_attack = true
			attack_windup_left = maxf(0.01, duration)
			attack_prestrike_hold_left = 0.0
			_show_spin_warning()
		BossLoopState.LUNGE:
			pending_attack = false
			attack_windup_left = 0.0
			attack_prestrike_hold_left = 0.0
			_hide_spin_warning()
		BossLoopState.VULNERABLE:
			pending_attack = false
			attack_windup_left = 0.0
			attack_prestrike_hold_left = 0.0
			_hide_spin_warning()
		BossLoopState.SUMMON:
			pending_attack = false
			attack_windup_left = 0.0
			attack_prestrike_hold_left = 0.0
			boss_summon_emitted = false
			_hide_spin_warning()
		_:
			pending_attack = false
			_hide_spin_warning()


func _tick_boss_state_timer(delta: float) -> void:
	boss_state_time_left = maxf(0.0, boss_state_time_left - delta)


func _get_or_reacquire_mark_target() -> Node2D:
	# Keep the marked ally locked for the current mark->windup->lunge cycle.
	# If the target becomes invalid, cancel the sequence instead of retargeting.
	if _is_valid_mark_target(boss_marked_ally):
		return boss_marked_ally
	return null


func _is_valid_mark_target(target: Variant) -> bool:
	if target == null:
		return false
	if not (target is Object):
		return false
	if not is_instance_valid(target):
		return false
	var target_node := target as Node2D
	if target_node == null:
		return false
	var target_healer := target_node as FriendlyHealer
	var target_ratfolk := target_node as FriendlyRatfolk
	if target_healer == null and target_ratfolk == null:
		return false
	if not _is_friendly_target_alive(target_node):
		return false
	if not target_node.has_method("receive_hit"):
		return false
	if target_node.is_in_group("shadow_clones"):
		return false
	if target_node.has_method("is_shadow_clone_actor") and bool(target_node.call("is_shadow_clone_actor")):
		return false
	return true


func _is_mark_target_in_start_range(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var engage_range := maxf(24.0, boss_mark_start_range)
	return global_position.distance_squared_to(target.global_position) <= engage_range * engage_range


func _is_friendly_target_alive(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var target_player := target as Player
	if target_player != null:
		return not target_player.is_dead
	var target_healer := target as FriendlyHealer
	if target_healer != null:
		return not target_healer.dead
	var target_ratfolk := target as FriendlyRatfolk
	if target_ratfolk != null:
		return not target_ratfolk.dead
	return true


func _select_mark_target() -> Node2D:
	var best_target: Node2D = null
	var best_score := INF
	var best_id := INF
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null:
			continue
		if not _is_valid_mark_target(candidate):
			continue
		if not _is_mark_target_in_start_range(candidate):
			continue
		var score := candidate.global_position.distance_squared_to(global_position)
		var candidate_id := candidate.get_instance_id()
		if score < best_score or (is_equal_approx(score, best_score) and candidate_id < best_id):
			best_score = score
			best_target = candidate
			best_id = candidate_id
	return best_target


func get_marked_ally_node() -> Node2D:
	if not _is_valid_mark_target(boss_marked_ally):
		return null
	return boss_marked_ally


func is_lunge_threatening_marked_ally() -> bool:
	return use_single_phase_loop and boss_loop_state in [BossLoopState.MARK, BossLoopState.WINDUP, BossLoopState.LUNGE] and _is_valid_mark_target(boss_marked_ally)


func get_guardian_intercept_point(marked_world_position: Vector2) -> Vector2:
	var direction := marked_world_position - global_position
	if direction.length_squared() <= 0.0001:
		direction = committed_attack_facing_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var intercept_distance := minf(maxf(24.0, boss_lunge_hit_length * 0.52), global_position.distance_to(marked_world_position) * 0.56)
	if boss_loop_state == BossLoopState.LUNGE:
		intercept_distance = maxf(18.0, boss_lunge_hit_length * 0.36)
		direction = boss_lunge_direction if boss_lunge_direction.length_squared() > 0.0001 else direction
	return global_position + (direction * intercept_distance)


func get_boss_debug_state() -> String:
	return String(BOSS_LOOP_STATE_NAMES.get(boss_loop_state, "Idle"))


func get_boss_vulnerable_time_left() -> float:
	if boss_loop_state != BossLoopState.VULNERABLE:
		return 0.0
	return maxf(0.0, boss_state_time_left)


func get_boss_marked_ally_name() -> String:
	var marked := get_marked_ally_node()
	if marked == null:
		return "-"
	return marked.name


func set_arena_bounds(min_x: float, max_x: float, min_y: float, max_y: float) -> void:
	lane_min_x = minf(min_x, max_x)
	lane_max_x = maxf(min_x, max_x)
	lane_min_y = minf(min_y, max_y)
	lane_max_y = maxf(min_y, max_y)


func _clamp_to_arena() -> void:
	position.x = clampf(position.x, lane_min_x, lane_max_x)
	position.y = clampf(position.y, lane_min_y, lane_max_y)


func _apply_soft_enemy_separation(delta: float) -> void:
	if not soft_collision_enabled:
		return
	if dead or delta <= 0.0:
		return
	var desired_spacing := maxf(1.0, soft_collision_radius)
	var desired_spacing_sq := desired_spacing * desired_spacing
	var separation := Vector2.ZERO
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var other := enemy_node as EnemyBase
		if other == null or other == self:
			continue
		if not is_instance_valid(other) or other.dead:
			continue
		var to_self := global_position - other.global_position
		var distance_sq := to_self.length_squared()
		if distance_sq <= 0.0001:
			var fallback_sign := 1.0 if get_instance_id() > other.get_instance_id() else -1.0
			to_self = Vector2(fallback_sign, 0.0)
			distance_sq = 1.0
		if distance_sq >= desired_spacing_sq:
			continue
		var distance := sqrt(distance_sq)
		var penetration_ratio := (desired_spacing - distance) / desired_spacing
		separation += (to_self / distance) * penetration_ratio
	if separation.length_squared() <= 0.0001:
		return
	var push_step := separation * (soft_collision_push_speed * delta)
	var max_push_step := maxf(0.1, soft_collision_max_push_per_frame)
	if push_step.length() > max_push_step:
		push_step = push_step.normalized() * max_push_step
	global_position += push_step


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


func _setup_spin_warning_area() -> void:
	spin_warning_area = Polygon2D.new()
	spin_warning_area.visible = false
	spin_warning_area.z_index = 1
	spin_warning_area.color = spin_warning_color
	_rebuild_spin_warning_polygon()
	_update_spin_warning_transform()
	add_child(spin_warning_area)


func _rebuild_spin_warning_polygon() -> void:
	if spin_warning_area == null:
		return
	if use_single_phase_loop:
		var radius_x := maxf(24.0, boss_mark_warning_radius_x)
		var radius_y := maxf(14.0, boss_mark_warning_radius_y)
		spin_warning_area.polygon = _build_ellipse_polygon(radius_x, radius_y, 44)
		return
	var spin_radii := _get_spin_hit_radii()
	spin_warning_area.polygon = _build_ellipse_polygon(spin_radii.x, spin_radii.y, 44)


func _get_spin_hit_radii() -> Vector2:
	var extra_reach := maxf(0.0, spin_attack_edge_padding)
	var horizontal_radius := maxf(24.0, spin_attack_radius + extra_reach)
	var base_vertical_radius := (spin_attack_radius * clampf(spin_attack_depth_scale, 0.3, 1.0)) + (extra_reach * 0.9)
	var vertical_radius := maxf(18.0, base_vertical_radius * 0.8)
	return Vector2(horizontal_radius, vertical_radius)


func _build_ellipse_polygon(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var safe_segments := maxi(10, segments)
	var points := PackedVector2Array()
	for i in range(safe_segments):
		var angle := (TAU * float(i)) / float(safe_segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _get_spin_attack_direction() -> Vector2:
	var facing := committed_attack_facing_direction
	if facing.length_squared() <= 0.0001:
		facing = external_sprite_facing_direction
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	return facing.normalized()


func _get_spin_attack_center() -> Vector2:
	return global_position + Vector2(spin_attack_center_offset, 0.0)


func _update_spin_warning_transform() -> void:
	if spin_warning_area == null:
		return
	if use_single_phase_loop and boss_loop_state in [BossLoopState.MARK, BossLoopState.WINDUP] and _is_valid_mark_target(boss_marked_ally):
		spin_warning_area.position = to_local(boss_marked_ally.global_position)
		spin_warning_area.rotation = 0.0
		return
	spin_warning_area.position = Vector2(spin_attack_center_offset, 0.0)
	spin_warning_area.rotation = 0.0


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
	var next_target: Node2D = null
	if prioritize_companion_targets:
		next_target = _find_priority_companion_target()
	if next_target == null:
		next_target = get_tree().get_first_node_in_group("player") as Node2D
	player = next_target


func _find_priority_companion_target() -> Node2D:
	var best_target: Node2D = null
	var best_distance_sq := INF
	var best_id := INF
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate.is_in_group("shadow_clones"):
			continue
		if candidate.has_method("is_shadow_clone_actor") and bool(candidate.call("is_shadow_clone_actor")):
			continue
		var healer_target := candidate as FriendlyHealer
		var rat_target := candidate as FriendlyRatfolk
		if healer_target == null and rat_target == null:
			continue
		if not _is_friendly_target_alive(candidate):
			continue
		var distance_sq := candidate.global_position.distance_squared_to(global_position)
		var candidate_id := candidate.get_instance_id()
		if best_target == null or distance_sq < best_distance_sq or (is_equal_approx(distance_sq, best_distance_sq) and candidate_id < best_id):
			best_target = candidate
			best_distance_sq = distance_sq
			best_id = candidate_id
	return best_target


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
	basic_attacks_since_last_spin += 1
	var basic_hit_reach := attack_range + basic_attack_hit_end_bonus
	_trigger_slash_effect(basic_hit_reach, 95.0, Color(0.94, 0.46, 0.26, 0.88), 0.18, 4.2)

	var hit_targets := _query_friendly_hits_for_basic()
	if hit_targets.is_empty():
		return
	for target in hit_targets:
		_attempt_friendly_hit(target, attack_damage, false, outgoing_hit_stun_duration, 1.0, true)


func _begin_spin_charge(to_player: Vector2) -> void:
	pending_attack = false
	attack_windup_left = 0.0
	attack_prestrike_hold_left = 0.0
	attack_recovery_hold_left = 0.0
	basic_attacks_since_last_spin = 0
	spin_charge_left = maxf(0.1, spin_charge_duration)
	spin_active_left = 0.0
	spin_hit_tick_left = 0.0
	var spin_facing := to_player.normalized()
	if spin_facing.length_squared() <= 0.0001:
		spin_facing = external_sprite_facing_direction
	if spin_facing.length_squared() <= 0.0001:
		spin_facing = Vector2.RIGHT
	committed_attack_facing_direction = spin_facing
	_show_spin_warning()


func _begin_spin_attack() -> void:
	spin_charge_left = 0.0
	spin_active_left = maxf(0.2, spin_attack_duration)
	spin_hit_tick_left = 0.0
	attack_flash_left = maxf(attack_flash_left, 0.22)
	var spin_reach := _get_spin_hit_radii().x
	_trigger_slash_effect(spin_reach * 0.95, 320.0, Color(1.0, 0.34, 0.22, 0.9), 0.26, 5.8)
	_hide_spin_warning()


func _finish_spin_attack() -> void:
	spin_active_left = 0.0
	spin_hit_tick_left = 0.0
	spin_attack_cooldown_left = maxf(spin_attack_cooldown_left, spin_attack_cooldown)
	attack_cooldown_left = maxf(attack_cooldown_left, attack_cooldown * 0.8)
	attack_recovery_hold_left = maxf(attack_recovery_hold_left, 0.24)
	_hide_spin_warning()


func _cancel_spin_attack() -> void:
	spin_charge_left = 0.0
	spin_active_left = 0.0
	spin_hit_tick_left = 0.0
	_hide_spin_warning()


func _perform_spin_attack_hit() -> void:
	var hit_targets := _query_friendly_hits_for_spin()
	if hit_targets.is_empty():
		return
	for target in hit_targets:
		var landed := _attempt_friendly_hit(
			target,
			attack_damage * spin_attack_damage_multiplier,
			spin_guard_break,
			outgoing_hit_stun_duration + spin_stun_bonus
		)
		if landed:
			attack_flash_left = maxf(attack_flash_left, 0.08)


func receive_hit(amount: float, source_position: Vector2, stun_duration: float = 0.0, apply_hit_stun: bool = true, knockback_scale: float = 1.0) -> bool:
	if dead:
		return false
	if shadow_fear_left > 0.0 and amount > 0.0:
		_clear_shadow_fear(true)
	var damage_to_apply := maxf(0.0, amount)
	if boss_dps_mark_left > 0.0:
		damage_to_apply *= maxf(1.0, boss_dps_mark_damage_taken_multiplier)
	if use_single_phase_loop and boss_loop_state == BossLoopState.VULNERABLE:
		damage_to_apply *= maxf(1.0, boss_vulnerable_damage_taken_multiplier)

	var attack_commit_active := pending_attack \
		or attack_windup_left > 0.0 \
		or attack_prestrike_hold_left > 0.0 \
		or attack_anim_left > 0.0 \
		or attack_recovery_hold_left > 0.0 \
		or spin_charge_left > 0.0 \
		or spin_active_left > 0.0
	var loop_interrupt_lock := use_single_phase_loop and boss_loop_state in [BossLoopState.MARK, BossLoopState.WINDUP, BossLoopState.LUNGE, BossLoopState.SUMMON]
	var ignore_interrupts := attack_commit_active or loop_interrupt_lock
	var suppress_knockback := is_miniboss
	if ignore_interrupts or suppress_knockback:
		knockback_velocity = Vector2.ZERO
	else:
		var knockback_direction := (global_position - source_position).normalized()
		if knockback_direction == Vector2.ZERO:
			knockback_direction = Vector2.LEFT if external_sprite_facing_direction.x >= 0.0 else Vector2.RIGHT
		knockback_velocity = knockback_direction * (hit_knockback_speed * maxf(0.1, knockback_scale))

	current_health = maxf(0.0, current_health - damage_to_apply)
	hit_flash_left = 0.12
	var applied_stun := 0.0
	if not ignore_interrupts:
		hurt_anim_left = maxf(hurt_anim_left, hurt_anim_duration)
		cosmetic_hurt_anim_left = 0.0
		applied_stun = maxf(hit_stun_duration, stun_duration) if apply_hit_stun else maxf(0.0, stun_duration)
		stun_left = maxf(stun_left, applied_stun)
	if applied_stun > 0.0:
		_cancel_spin_attack()
		pending_attack = false
		attack_windup_left = 0.0
		attack_prestrike_hold_left = 0.0
		attack_recovery_hold_left = 0.0
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


func apply_dps_mark(duration: float) -> void:
	boss_dps_mark_left = maxf(boss_dps_mark_left, maxf(0.0, duration))
	_spawn_hit_effect(global_position + Vector2(0.0, -18.0), Color(0.55, 0.86, 1.0, 0.9), 7.0)


func has_dps_mark() -> bool:
	return boss_dps_mark_left > 0.0


func apply_hitstop(duration: float) -> void:
	hitstop_left = maxf(hitstop_left, maxf(0.0, duration))


func can_trade_melee_with(target: Node2D) -> bool:
	if dead:
		return false
	if stun_left > 0.0:
		return false
	if not is_instance_valid(target):
		return false
	var to_target := target.global_position - global_position
	if absf(to_target.y) > melee_trade_depth_tolerance:
		return false
	var max_distance := attack_range + melee_trade_reach_bonus
	return to_target.length_squared() <= max_distance * max_distance


func get_trade_damage() -> float:
	return maxf(1.0, attack_damage * melee_trade_damage_scale)


func get_trade_stun_duration() -> float:
	return outgoing_hit_stun_duration


func _attempt_friendly_hit(target: Node2D, damage: float, guard_break: bool = false, stun_duration: float = 0.0, knockback_scale: float = 1.0, spawn_block_success_fx: bool = false) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("receive_hit"):
		return false
	var was_blocked := _is_target_blocking_attack(target)
	var adjusted_damage := damage * _get_protective_shield_damage_multiplier(target)
	var landed := bool(target.call("receive_hit", adjusted_damage, global_position, guard_break, stun_duration, knockback_scale))
	if landed:
		_spawn_hit_effect(target.global_position + Vector2(0.0, -14.0), Color(1.0, 0.44, 0.3, 0.95), 10.0)
	if was_blocked and not guard_break:
		if spawn_block_success_fx:
			var blocked_player := target as Player
			if blocked_player != null:
				_queue_basic_block_success_effect(blocked_player)
		_apply_blocked_counter_stun()
	return landed


func _get_protective_shield_damage_multiplier(target: Node2D) -> float:
	var multiplier := 1.0
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var healer := node as FriendlyHealer
		if healer == null or not is_instance_valid(healer):
			continue
		if not healer.has_method("get_shield_damage_multiplier_for"):
			continue
		var shield_multiplier_variant: Variant = healer.call("get_shield_damage_multiplier_for", target)
		if shield_multiplier_variant is float:
			multiplier = minf(multiplier, clampf(float(shield_multiplier_variant), 0.0, 1.0))
	return multiplier


func _is_target_blocking_attack(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var player_target := target as Player
	if player_target == null:
		return false
	if not player_target.is_blocking:
		return false
	var incoming_direction := (global_position - player_target.global_position).normalized()
	if incoming_direction == Vector2.ZERO:
		incoming_direction = Vector2.LEFT if player_target.facing_direction.x >= 0.0 else Vector2.RIGHT
	var block_threshold := cos(deg_to_rad(player_target.block_arc_degrees * 0.5))
	return player_target.facing_direction.dot(incoming_direction) >= block_threshold


func _apply_blocked_counter_stun() -> void:
	stun_left = maxf(stun_left, blocked_counter_stun_duration)
	pending_attack = false
	attack_windup_left = 0.0
	attack_prestrike_hold_left = 0.0
	attack_cooldown_left = maxf(attack_cooldown_left, blocked_counter_stun_duration + 0.1)
	if attack_anim_left <= 0.0 and attack_recovery_hold_left <= 0.0:
		attack_flash_left = 0.0
		weapon_trail_alpha = 0.0
		weapon_trail.visible = false
		slash_effect.visible = false
	attack_telegraph.visible = false
	velocity = Vector2.ZERO
	_spawn_hit_effect(global_position + Vector2(0.0, -12.0), Color(0.86, 0.9, 1.0, 0.88), 6.0)


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


func _get_basic_attack_direction() -> Vector2:
	var attack_direction := committed_attack_facing_direction
	if attack_direction.length_squared() <= 0.0001:
		attack_direction = external_sprite_facing_direction
	if attack_direction.length_squared() <= 0.0001 and is_instance_valid(player):
		attack_direction = (player.global_position - global_position).normalized()
	if attack_direction.length_squared() <= 0.0001:
		attack_direction = Vector2.RIGHT
	return attack_direction.normalized()


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var segment_len_sq := segment.length_squared()
	if segment_len_sq <= 0.0001:
		return point.distance_to(segment_start)
	var segment_t := clampf((point - segment_start).dot(segment) / segment_len_sq, 0.0, 1.0)
	var closest := segment_start + (segment * segment_t)
	return point.distance_to(closest)


func _query_friendly_hits_for_basic() -> Array[Node2D]:
	var hit_targets: Array[Node2D] = []
	var attack_direction := _get_basic_attack_direction()
	var segment_start := global_position + (attack_direction * basic_attack_hit_start_offset)
	var segment_end := global_position + (attack_direction * (attack_range + basic_attack_hit_end_bonus))
	for candidate in _get_attackable_friendly_targets():
		var distance_to_sweep := _distance_to_segment(candidate.global_position, segment_start, segment_end)
		if distance_to_sweep <= maxf(6.0, basic_attack_hit_half_width):
			hit_targets.append(candidate)
			continue
		if candidate.global_position.distance_to(segment_end) <= maxf(8.0, basic_attack_tip_radius):
			hit_targets.append(candidate)
	return hit_targets


func _query_friendly_hits_for_spin() -> Array[Node2D]:
	var hit_targets: Array[Node2D] = []
	var center := _get_spin_attack_center()
	var spin_radii := _get_spin_hit_radii()
	var radius_x := maxf(10.0, spin_radii.x)
	var radius_y := maxf(8.0, spin_radii.y)
	for candidate in _get_attackable_friendly_targets():
		var to_candidate := candidate.global_position - center
		var normalized_distance := (to_candidate.x * to_candidate.x) / (radius_x * radius_x)
		normalized_distance += (to_candidate.y * to_candidate.y) / (radius_y * radius_y)
		if normalized_distance <= 1.0:
			hit_targets.append(candidate)
	return hit_targets


func _get_attackable_friendly_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	if not is_instance_valid(player):
		_reacquire_player()
	var player_target := player as Node2D
	if player_target != null and is_instance_valid(player_target) and _is_friendly_target_alive(player_target) and player_target.has_method("receive_hit"):
		targets.append(player_target)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var target := node as Node2D
		if target == null or not is_instance_valid(target):
			continue
		if not _is_friendly_target_alive(target):
			continue
		if target == player_target:
			continue
		if target.is_in_group("shadow_clones"):
			continue
		if target.has_method("is_shadow_clone_actor") and bool(target.call("is_shadow_clone_actor")):
			continue
		if not target.has_method("receive_hit"):
			continue
		targets.append(target)
	return targets


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
	if spin_charge_left > 0.0:
		target_scale = Vector2(1.08, 0.94)
	elif spin_active_left > 0.0:
		target_scale = Vector2(1.18, 0.82)
	elif pending_attack:
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
	elif spin_charge_left > 0.0:
		_set_model_palette(
			base_body_color.lerp(Color(0.76, 0.2, 0.18, 1.0), 0.62),
			base_head_color.lerp(Color(0.8, 0.44, 0.4, 1.0), 0.5),
			base_arm_color.lerp(Color(0.68, 0.18, 0.16, 1.0), 0.58),
			base_weapon_color.lerp(Color(0.94, 0.54, 0.4, 1.0), 0.56)
		)
	elif spin_active_left > 0.0:
		_set_model_palette(
			base_body_color.lerp(Color(0.84, 0.16, 0.12, 1.0), 0.7),
			base_head_color.lerp(Color(0.86, 0.36, 0.32, 1.0), 0.55),
			base_arm_color.lerp(Color(0.78, 0.14, 0.12, 1.0), 0.62),
			base_weapon_color.lerp(Color(1.0, 0.62, 0.44, 1.0), 0.64)
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
	_update_spin_warning_visual(delta)
	_update_weapon_fx(delta)
	_update_debug_overlay()


func _update_monster_sprite(delta: float, movement_ratio: float, to_player: Vector2) -> void:
	var lock_facing_from_hit := stun_left > 0.0 or hurt_anim_left > 0.0
	var facing := external_sprite_facing_direction if lock_facing_from_hit else to_player
	if not lock_facing_from_hit and (pending_attack or attack_anim_left > 0.0 or attack_recovery_hold_left > 0.0 or spin_charge_left > 0.0 or spin_active_left > 0.0) and committed_attack_facing_direction.length_squared() > 0.0001:
		facing = committed_attack_facing_direction
	elif not lock_facing_from_hit and velocity.length_squared() > 0.001:
		facing = velocity
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	external_sprite_facing_direction = facing.normalized()
	debug_last_row = _pick_debug_facing_row(external_sprite_facing_direction, 6)
	var has_true_hurt_anim := hurt_anim_left > 0.0
	var has_cosmetic_hurt_anim := cosmetic_hurt_anim_left > 0.0 and not _is_combat_action_active_for_periodic_hurt()
	var displayed_hurt_left := hurt_anim_left if has_true_hurt_anim else cosmetic_hurt_anim_left
	var displayed_hurt_duration := hurt_anim_duration if has_true_hurt_anim else periodic_hurt_anim_duration
	var lunge_charge_visual_active := _is_lunge_charge_visual_active()

	var action_key := "idle"
	if dead:
		action_key = "death"
	elif has_true_hurt_anim:
		action_key = "hurt"
	elif spin_active_left > 0.0:
		action_key = "spin"
	elif spin_charge_left > 0.0:
		action_key = "attack"
	elif lunge_charge_visual_active:
		action_key = "attack"
	elif pending_attack or attack_anim_left > 0.0 or attack_recovery_hold_left > 0.0:
		action_key = "attack"
	elif has_cosmetic_hurt_anim:
		action_key = "hurt"
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
	var frame_columns: Array = MONSTER_ACTION_FRAME_COLUMNS.get(action_key, [])
	var has_custom_columns := not frame_columns.is_empty()
	if has_custom_columns:
		frame_count = frame_columns.size()
	if monster_anim_name != action_key or monster_sprite.texture != sheet:
		monster_anim_name = action_key
		monster_anim_time = 0.0
		monster_sprite.texture = sheet
		monster_sprite.hframes = MONSTER_HD_HFRAMES
		monster_sprite.vframes = MONSTER_HD_VFRAMES
		var first_column := int(frame_columns[0]) if has_custom_columns else 0
		monster_sprite.frame_coords = Vector2i(first_column, row)
	var fps := float(MONSTER_FPS.get(action_key, 8.0))
	var holding_attack_frame := action_key == "attack" and pending_attack and attack_windup_left <= 0.0 and attack_prestrike_hold_left > 0.0
	var preparing_attack_hold := action_key == "attack" and pending_attack and attack_windup_left > 0.0 and attack_prestrike_hold_duration > 0.0
	var holding_recovery_frame := action_key == "attack" and not pending_attack and attack_anim_left <= 0.0 and attack_recovery_hold_left > 0.0
	var holding_spin_charge_frame := action_key == "attack" and spin_charge_left > 0.0
	var holding_lunge_charge_frame := action_key == "attack" and lunge_charge_visual_active
	if not holding_attack_frame and not holding_recovery_frame:
		monster_anim_time += delta * fps
	var frame_index: int
	if action_key == "death" and dead:
		frame_index = mini(int(floor(monster_anim_time)), frame_count - 1)
	elif action_key == "attack":
		if holding_spin_charge_frame:
			frame_index = clampi(maxi(0, attack_hold_frame - 1), 0, max(0, frame_count - 1))
			monster_anim_time = float(frame_index)
		elif holding_lunge_charge_frame:
			frame_index = clampi(maxi(0, attack_hold_frame), 0, max(0, frame_count - 1))
			monster_anim_time = float(frame_index)
		elif holding_attack_frame:
			frame_index = clampi(attack_hold_frame, 0, max(0, frame_count - 1))
			monster_anim_time = float(frame_index)
		elif preparing_attack_hold:
			var pre_hold_frame := clampi(attack_hold_frame, 0, max(0, frame_count - 1))
			frame_index = mini(int(floor(monster_anim_time)), pre_hold_frame)
			if frame_index >= pre_hold_frame:
				monster_anim_time = float(pre_hold_frame)
		elif holding_recovery_frame:
			frame_index = frame_count - 1
			monster_anim_time = float(frame_index)
		else:
			frame_index = mini(int(floor(monster_anim_time)), frame_count - 1)
	elif action_key == "hurt":
		var hurt_progress := 1.0 - (displayed_hurt_left / maxf(0.01, displayed_hurt_duration))
		frame_index = mini(int(floor(clampf(hurt_progress, 0.0, 1.0) * float(frame_count))), frame_count - 1)
	else:
		frame_index = int(floor(monster_anim_time)) % frame_count
	var source_column := int(frame_columns[frame_index]) if has_custom_columns else frame_index
	monster_sprite.frame_coords = Vector2i(source_column, row)


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
	if spin_charge_left > 0.0 or spin_active_left > 0.0:
		attack_telegraph.visible = false
		return
	if not pending_attack:
		attack_telegraph.visible = false
		return

	attack_telegraph.visible = true
	var aim_direction := to_player
	if committed_attack_facing_direction.length_squared() > 0.0001:
		aim_direction = committed_attack_facing_direction
	if aim_direction.length_squared() <= 0.0001:
		aim_direction = Vector2.RIGHT
	var safe_windup := maxf(0.01, attack_windup)
	var progress := clampf(1.0 - (attack_windup_left / safe_windup), 0.0, 1.0)
	attack_telegraph.rotation = aim_direction.angle()
	attack_telegraph.width = lerpf(2.0, 7.0, progress)
	attack_telegraph.default_color = Color(0.96, lerpf(0.64, 0.3, progress), lerpf(0.36, 0.18, progress), 0.9)
	attack_telegraph.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(lerpf(12.0, attack_range + basic_attack_hit_end_bonus, progress), 0.0)
	])


func _show_spin_warning() -> void:
	if spin_warning_area == null:
		return
	_rebuild_spin_warning_polygon()
	_update_spin_warning_transform()
	spin_warning_area.visible = true
	spin_warning_area.color = spin_warning_color
	spin_warning_area.scale = Vector2.ONE


func _hide_spin_warning() -> void:
	if spin_warning_area == null:
		return
	spin_warning_area.visible = false
	spin_warning_area.scale = Vector2.ONE


func _update_spin_warning_visual(delta: float) -> void:
	if spin_warning_area == null:
		return
	_update_spin_warning_transform()
	if use_single_phase_loop:
		var warning_active := boss_loop_state in [BossLoopState.MARK, BossLoopState.WINDUP]
		if not warning_active:
			if spin_warning_area.visible:
				spin_warning_area.visible = false
				spin_warning_area.scale = Vector2.ONE
			return
		var safe_duration := maxf(0.01, boss_mark_duration if boss_loop_state == BossLoopState.MARK else boss_windup_duration)
		var stage_progress := clampf(1.0 - (boss_state_time_left / safe_duration), 0.0, 1.0)
		var pulse := 0.5 + (sin(anim_time * 9.5) * 0.5)
		spin_warning_area.visible = true
		spin_warning_area.color = spin_warning_color.lerp(Color(1.0, 0.12, 0.12, 0.58), stage_progress * 0.86)
		spin_warning_area.scale = spin_warning_area.scale.lerp(Vector2.ONE * lerpf(0.95, 1.08, pulse), clampf(delta * 10.0, 0.0, 1.0))
		return
	if spin_charge_left <= 0.0:
		if spin_warning_area.visible:
			spin_warning_area.visible = false
			spin_warning_area.scale = Vector2.ONE
		return
	var charge_progress := clampf(1.0 - (spin_charge_left / maxf(0.01, spin_charge_duration)), 0.0, 1.0)
	var pulse := 0.5 + (sin(anim_time * 9.5) * 0.5)
	spin_warning_area.visible = true
	spin_warning_area.color = spin_warning_color.lerp(Color(1.0, 0.1, 0.1, 0.55), charge_progress * 0.8)
	spin_warning_area.scale = spin_warning_area.scale.lerp(Vector2.ONE * lerpf(0.96, 1.08, pulse), clampf(delta * 10.0, 0.0, 1.0))


func _die() -> void:
	dead = true
	knockback_velocity = Vector2.ZERO
	shadow_fear_left = 0.0
	_shadow_fear_teardown_vfx()
	pending_basic_block_success_fx.clear()
	_cancel_spin_attack()
	_teardown_debug_overlay()
	died.emit(self)
	queue_free()


func _start_attack_animation(duration: float, strength: float) -> void:
	var attack_facing := external_sprite_facing_direction
	if attack_facing.length_squared() <= 0.0001 and is_instance_valid(player):
		attack_facing = (player.global_position - global_position).normalized()
	if attack_facing.length_squared() <= 0.0001:
		attack_facing = Vector2.RIGHT
	committed_attack_facing_direction = attack_facing.normalized()
	attack_anim_total = maxf(0.01, duration)
	attack_anim_left = attack_anim_total
	attack_recovery_hold_left = 0.0
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
	var lunge_charge_visual_active := _is_lunge_charge_visual_active()

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

	if spin_charge_left > 0.0:
		var charge_progress := clampf(1.0 - (spin_charge_left / maxf(0.01, spin_charge_duration)), 0.0, 1.0)
		right_arm_visual.rotation = lerp_angle(right_arm_visual.rotation, 0.8, clampf(delta * 12.0, 0.0, 1.0))
		weapon_visual.rotation = lerp_angle(weapon_visual.rotation, 1.18, clampf(delta * 12.0, 0.0, 1.0))
		left_leg_visual.rotation = lerp_angle(left_leg_visual.rotation, -0.28, clampf(delta * 10.0, 0.0, 1.0))
		right_leg_visual.rotation = lerp_angle(right_leg_visual.rotation, -0.2, clampf(delta * 10.0, 0.0, 1.0))
		body_visual.rotation = lerp_angle(body_visual.rotation, body_visual.rotation + (charge_progress * 0.06), clampf(delta * 8.0, 0.0, 1.0))
	elif lunge_charge_visual_active:
		right_arm_visual.rotation = lerp_angle(right_arm_visual.rotation, -1.05, clampf(delta * 14.0, 0.0, 1.0))
		weapon_visual.rotation = lerp_angle(weapon_visual.rotation, -1.55, clampf(delta * 14.0, 0.0, 1.0))
		left_leg_visual.rotation = lerp_angle(left_leg_visual.rotation, -0.2, clampf(delta * 10.0, 0.0, 1.0))
		right_leg_visual.rotation = lerp_angle(right_leg_visual.rotation, -0.16, clampf(delta * 10.0, 0.0, 1.0))

	if spin_active_left > 0.0:
		body_visual.rotation += delta * 15.0
		head_visual.rotation += delta * 7.5
		right_arm_visual.rotation += delta * 11.0
		weapon_visual.rotation += delta * 20.0
		left_leg_visual.rotation += delta * 8.0
		right_leg_visual.rotation -= delta * 8.0
		weapon_trail_alpha = maxf(weapon_trail_alpha, 0.95)

	if attack_anim_left > 0.0:
		var attack_progress := 1.0 - (attack_anim_left / maxf(0.01, attack_anim_total))
		var attack_swing := sin(attack_progress * PI) * attack_anim_strength
		right_arm_visual.rotation += attack_swing * 0.95
		weapon_visual.rotation += attack_swing * 1.45
		weapon_trail_alpha = maxf(weapon_trail_alpha, 0.72)
		if cloth_front_visual != null:
			cloth_front_visual.rotation += attack_swing * 0.04

	if spin_active_left <= 0.0:
		var body_aim := external_sprite_facing_direction if (stun_left > 0.0 or hurt_anim_left > 0.0) else to_player
		if stun_left <= 0.0 and hurt_anim_left <= 0.0 and (pending_attack or attack_anim_left > 0.0 or attack_recovery_hold_left > 0.0 or spin_charge_left > 0.0 or lunge_charge_visual_active) and committed_attack_facing_direction.length_squared() > 0.0001:
			body_aim = committed_attack_facing_direction
		if body_aim.length_squared() > 0.0001:
			body_visual.rotation = lerp_angle(body_visual.rotation, body_aim.angle() * 0.16, clampf(delta * 10.0, 0.0, 1.0))
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
	if using_external_monster_sprite:
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

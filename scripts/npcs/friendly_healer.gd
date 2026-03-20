extends Node2D
class_name FriendlyHealer

signal health_changed(current: float, maximum: float)
signal died(healer: FriendlyHealer)

enum HealerAIState {
	IDLE_SUPPORT,
	REPOSITIONING,
	HEALING,
	ATTACKING,
	BREATH_STACK
}

const HEALER_AI_STATE_NAMES: Dictionary = {
	HealerAIState.IDLE_SUPPORT: "IDLE_SUPPORT",
	HealerAIState.REPOSITIONING: "REPOSITIONING",
	HealerAIState.HEALING: "HEALING",
	HealerAIState.ATTACKING: "ATTACKING",
	HealerAIState.BREATH_STACK: "BREATH_STACK"
}

enum CastAction {
	NONE,
	QUICK_HEAL,
	BIG_HEAL,
	TIDAL_WAVE,
	LIGHT_BOLT
}

# Pacing experiment knobs (slow-RPG cadence).
@export var heal_amount: float = 12.0
@export var heal_interval: float = 4.2
@export var heal_interval_variance: float = 0.7
@export var heal_threshold_ratio: float = 0.98
@export var min_missing_health_to_heal: float = 1.0
@export var heal_effect_duration: float = 0.24
@export var heal_flash_duration: float = 0.16
@export var cast_frame_to_heal: int = 4
@export var reacquire_retry_interval: float = 0.3
@export var react_heal_delay: float = 0.18
@export var emergency_cast_on_damage: bool = true
@export var move_speed: float = 100.3
@export var roll_speed: float = 210.0
@export var roll_duration: float = 0.24
@export var roll_cooldown: float = 4.0
@export var roll_depth_speed_multiplier: float = 0.62
@export var use_player_like_movement: bool = true
@export_range(4, 16, 1) var player_like_direction_steps: int = 8
@export_range(0.0, 1.0, 0.01) var player_like_move_deadzone_ratio: float = 0.24
@export var movement_acceleration: float = 860.0
@export var movement_deceleration: float = 980.0
@export var ai_decision_interval: float = 0.1
@export var move_deadzone: float = 8.0
@export var slow_down_radius: float = 36.0
@export var cast_move_speed_multiplier: float = 0.9
@export var breath_stack_move_speed_multiplier: float = 1.75
@export var input_decision_interval_min: float = 0.08
@export var input_decision_interval_max: float = 0.18
@export var input_noise_degrees: float = 8.0
@export var input_release_chance: float = 0.12
@export var strafe_input_chance: float = 0.22
@export var stick_quantization_steps: int = 8
@export var follow_distance: float = 108.0
@export var min_distance_to_player: float = 40.0
@export var max_distance_to_player: float = 160.0
@export var healer_follow_min_band: float = 140.0
@export var healer_follow_max_band: float = 210.0
@export var target_smoothing_speed: float = 430.0
@export var guard_side_swap_threshold: float = 40.0
@export var follow_vertical_scale: float = 0.2
@export var follow_vertical_bias: float = 0.0
@export var orbit_lateral_distance: float = 14.0
@export var orbit_depth_distance: float = 8.0
@export var orbit_speed: float = 1.25
@export var marked_lunge_panic_freeze_duration: float = 0.24
@export var marked_lunge_move_speed_multiplier: float = 0.65
@export var marked_lunge_hold_radius: float = 22.0
@export var move_facing_threshold: float = 20.0
@export var facing_flip_deadzone: float = 10.0
@export var pixel_snap_movement: bool = false
@export var arena_padding: float = 26.0
@export var tidal_wave_enabled: bool = true
@export var basic_heal_cooldown: float = 1.5
@export var basic_heal_range: float = 171.6
@export var basic_heal_range_buffer: float = 10.0
@export var quick_heal_cast_time_multiplier: float = 2.0
@export var big_heal_cooldown: float = 7.5
@export var big_heal_amount_multiplier: float = 3.0
@export var big_heal_cast_time_multiplier: float = 2.0
@export var light_bolt_enabled: bool = true
@export var light_bolt_damage: float = 7.5
@export var light_bolt_cooldown: float = 0.0
@export var light_bolt_range: float = 208.0
@export var light_bolt_stun_duration: float = 0.1
@export var light_bolt_hitstop_duration: float = 0.045
@export var light_bolt_projectile_speed: float = 520.0
@export var light_bolt_projectile_hit_radius: float = 12.0
@export var light_bolt_projectile_knockback_scale: float = 0.88
@export var light_bolt_projectile_max_lifetime: float = 1.2
@export var harpoon_enabled: bool = true
@export var harpoon_cooldown: float = 6.75
@export var harpoon_min_charge_time: float = 0.12
@export var harpoon_max_charge_time: float = 0.9
@export var harpoon_min_range: float = 120.0
@export var harpoon_max_range: float = 280.0
@export var harpoon_min_projectile_speed: float = 520.0
@export var harpoon_max_projectile_speed: float = 840.0
@export var harpoon_min_reel_speed: float = 120.0
@export var harpoon_max_reel_speed: float = 220.0
@export var harpoon_ally_reel_speed_multiplier: float = 2.0
@export var harpoon_stop_distance: float = 0.0
@export var harpoon_contact_distance_scale: float = 0.45
@export var harpoon_enemy_damage: float = 8.0
@export var harpoon_arrival_stagger_duration: float = 0.36
@export var harpoon_heavy_tug_distance: float = 56.0
@export var harpoon_projectile_hit_radius: float = 14.0
@export var harpoon_reel_max_duration: float = 2.6
@export var tidal_wave_cooldown: float = 9.0
@export var tidal_wave_speed: float = 310.0
@export var tidal_wave_duration: float = 1.5
@export var tidal_wave_heal_amount: float = 9.0
@export var tidal_wave_damage: float = 4.0
@export var tidal_wave_knockback_scale: float = 1.85
@export var tidal_wave_stun_duration: float = 0.14
@export var tidal_wave_hitstop_duration: float = 0.055
@export var tidal_wave_hit_length: float = 82.0
@export var tidal_wave_hit_half_width: float = 26.0
@export var tidal_wave_visual_height_scale: float = 1.55
@export var tidal_wave_droplet_interval: float = 0.07
@export var tidal_wave_sprite_scale: Vector2 = Vector2(0.72, 0.7)
@export var max_health: float = 45.0
@export var health_bar_width: float = 54.0
@export var health_bar_thickness: float = 5.0
@export var health_bar_y_offset: float = -62.0
@export var combat_number_popups_enabled: bool = true
@export var combat_number_popup_duration: float = 0.42
@export var combat_number_popup_rise_distance: float = 26.0
@export var combat_number_popup_x_spread: float = 8.0
@export var combat_number_popup_scale: float = 1.0
@export var combat_number_popup_font_size: int = 17
@export var combat_number_popup_outline_size: int = 3
@export var combat_number_popup_head_offset_y: float = -44.0
@export var cast_bar_width: float = 52.0
@export var cast_bar_thickness: float = 3.0
@export var cast_bar_vertical_offset: float = 8.0
@export var heal_range_indicator_enabled: bool = true
@export var heal_range_indicator_width: float = 1.6
@export_range(16, 96, 1) var heal_range_indicator_segments: int = 64
@export var heal_range_indicator_alpha: float = 0.12
@export var heal_range_indicator_radius_scale: float = 1.0
@export var heal_range_indicator_y_offset: float = 0.0
@export var special_bar_width: float = 52.0
@export var special_bar_thickness: float = 3.0
@export var special_bar_vertical_offset: float = 8.0
@export var special_meter_max: float = 100.0
@export var special_meter_gain_per_damage: float = 2.0
@export var special_meter_gain_per_heal: float = 2.0
@export var hit_stun_duration: float = 0.18
@export var hit_knockback_speed: float = 170.0
@export var hit_knockback_decay: float = 960.0
@export var miniboss_soft_collision_enabled: bool = false
@export var miniboss_soft_collision_radius: float = 52.0
@export var miniboss_soft_collision_push_speed: float = 245.0
@export var miniboss_soft_collision_max_push_per_frame: float = 5.6

const HEALER_SHEET: Texture2D = preload("res://assets/external/ElthenAssets/fishfolk/Fishfolk Archpriest Sprite Sheet.png")
const TIDAL_WAVE_STARTUP_SHEET_PATH: String = "res://assets/external/Water Blast - Spritesheet/Water Blast - Startup and Infinite.png"
const TIDAL_WAVE_END_SHEET_PATH: String = "res://assets/external/Water Blast - Spritesheet/Water Blast - End.png"
const COMPANION_BREATH_RESPONSE_SCRIPT := preload("res://ai/CompanionBreathResponse.gd")
const HEALER_LIGHT_BOLT_PROJECTILE_SCRIPT := preload("res://scripts/projectiles/healer_light_bolt_projectile.gd")
const TIDAL_WAVE_FRAME_SIZE: Vector2i = Vector2i(128, 128)
const TIDAL_WAVE_STARTUP_FRAME_COUNT: int = 12
const TIDAL_WAVE_LOOP_FRAME_START: int = 8
const TIDAL_WAVE_LOOP_FRAME_END: int = 11
const TIDAL_WAVE_END_FRAME_COUNT: int = 9
const HEALER_HFRAMES: int = 9
const HEALER_VFRAMES: int = 6
const FRAME_ALPHA_THRESHOLD: float = 0.08
const INVALID_FRAME_ANCHOR: Vector2 = Vector2(-1.0, -1.0)
const ANIM_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"cast": 2,
	"death": 5
}
const ANIM_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"run": [0, 1, 2, 3],
	"cast": [0, 1, 2, 3, 4, 5, 6],
	"death": [0, 1, 2, 3]
}
const ANIM_FPS: Dictionary = {
	"idle": 6.0,
	"run": 8.8,
	"cast": 10.0,
	"death": 8.0
}
const HEALER_ITEM_PRICE: int = 15
const HEALER_WEAPON_DEFINITIONS: Dictionary = {
	"riverlight_rod": {
		"id": "riverlight_rod",
		"name": "Riverlight Rod",
		"icon": "WPN",
		"description": "Healing shaves 0.6s off Light Bolt cooldown.",
		"bolt_cooldown_refund_on_heal": 0.6
	},
	"chain_mender_focus": {
		"id": "chain_mender_focus",
		"name": "Chainmender Focus",
		"icon": "WPN",
		"description": "Quick/Big Heal chains to a second ally for 45% power.",
		"chain_heal_ratio": 0.45
	},
	"stormcall_codex": {
		"id": "stormcall_codex",
		"name": "Stormcall Codex",
		"icon": "WPN",
		"description": "Light Bolt arcs to another nearby enemy for 65% damage.",
		"bolt_arc_ratio": 0.65
	}
}
const HEALER_TRINKET_DEFINITIONS: Dictionary = {
	"restoration_talisman": {
		"id": "restoration_talisman",
		"name": "Restoration Talisman",
		"icon": "TRK",
		"description": "Healing and damage grant 25% more Special meter.",
		"special_gain_multiplier": 1.25
	},
	"anchor_relic": {
		"id": "anchor_relic",
		"name": "Anchor Relic",
		"icon": "TRK",
		"description": "While casting, take 35% less damage and casts are not interrupted.",
		"cast_damage_multiplier": 0.65,
		"cast_uninterruptible": true
	},
	"echo_prism": {
		"id": "echo_prism",
		"name": "Echo Prism",
		"icon": "TRK",
		"description": "Harpoon impact triggers a healing pulse and refunds 1.0s cooldown.",
		"harpoon_refund": 1.0,
		"harpoon_pulse_radius": 96.0,
		"harpoon_pulse_heal": 6.0
	}
}
const HEALER_BOOT_DEFINITIONS: Dictionary = {
	"foamstep_boots": {
		"id": "foamstep_boots",
		"name": "Foamstep Boots",
		"icon": "BTS",
		"description": "Increases movement speed by 15%.",
		"move_speed_multiplier": 1.15
	},
	"blinkstep_boots": {
		"id": "blinkstep_boots",
		"name": "Blinkstep Boots",
		"icon": "BTS",
		"description": "Roll cooldown -40% and roll speed +20%.",
		"roll_cooldown_multiplier": 0.6,
		"roll_speed_multiplier": 1.2
	},
	"tidegrip_boots": {
		"id": "tidegrip_boots",
		"name": "Tidegrip Boots",
		"icon": "BTS",
		"description": "Harpoon cooldown -35% and reel speed +25%.",
		"harpoon_cooldown_multiplier": 0.65,
		"harpoon_reel_speed_multiplier": 1.25
	}
}
const HEALER_WEAPON_ORDER: Array[String] = [
	"riverlight_rod",
	"chain_mender_focus",
	"stormcall_codex"
]
const HEALER_TRINKET_ORDER: Array[String] = [
	"restoration_talisman",
	"anchor_relic",
	"echo_prism"
]
const HEALER_BOOT_ORDER: Array[String] = [
	"foamstep_boots",
	"blinkstep_boots",
	"tidegrip_boots"
]
const HEALER_STORE_ITEM_ORDER: Array[String] = [
	"riverlight_rod",
	"chain_mender_focus",
	"stormcall_codex",
	"restoration_talisman",
	"anchor_relic",
	"echo_prism",
	"foamstep_boots",
	"blinkstep_boots",
	"tidegrip_boots"
]

var player: Player = null
var heal_timer_left: float = 0.0
var idle_anim_time: float = 0.0
var run_anim_time: float = 0.0
var cast_anim_time: float = 0.0
var is_casting: bool = false
var heal_applied_this_cast: bool = false
var basic_heal_cooldown_left: float = 0.0
var big_heal_cooldown_left: float = 0.0
var tidal_wave_cooldown_left: float = 0.0
var light_bolt_cooldown_left: float = 0.0
var cast_debug_logging_enabled: bool = false
var reacquire_left: float = 0.0
var harpoon_cooldown_left: float = 0.0
var harpoon_charge_active: bool = false
var harpoon_charge_time: float = 0.0
var harpoon_charge_ratio: float = 0.0
var harpoon_throw_direction_sign: float = 1.0
var harpoon_projectile_active: bool = false
var harpoon_projectile_position: Vector2 = Vector2.ZERO
var harpoon_projectile_travel_left: float = 0.0
var harpoon_projectile_speed: float = 0.0
var harpoon_reel_active: bool = false
var harpoon_reel_left: float = 0.0
var harpoon_reel_speed: float = 0.0
var harpoon_reel_charge_ratio: float = 0.0
var harpoon_hooked_target: Node2D = null
var harpoon_hooked_target_is_enemy: bool = false
var harpoon_hooked_target_is_heavy: bool = false
var harpoon_hooked_has_velocity: bool = false
var harpoon_hooked_has_move_velocity: bool = false
var harpoon_hooked_has_knockback_velocity: bool = false
var harpoon_hooked_has_stun_left: bool = false
var tracked_player_health: float = -1.0
var sprite_base_position: Vector2 = Vector2.ZERO
var frame_pixel_size: Vector2 = Vector2.ZERO
var frame_anchor_points: Dictionary = {}
var alignment_anchor_point: Vector2 = Vector2.ZERO
var active_tidal_waves: Array[Dictionary] = []
var tidal_wave_sprite_frames: SpriteFrames = null
var tidal_wave_startup_sheet_texture: Texture2D = null
var tidal_wave_end_sheet_texture: Texture2D = null
var move_velocity: Vector2 = Vector2.ZERO
var orbit_phase: float = 0.0
var smoothed_target_position: Vector2 = Vector2.ZERO
var desired_guard_side: float = 0.0
var healer_ai_state: HealerAIState = HealerAIState.IDLE_SUPPORT
var healer_ai_state_name: String = "IDLE_SUPPORT"
var healer_ai_target: Node2D = null
var healer_ai_decision_left: float = 0.0
var healer_ai_desired_position: Vector2 = Vector2.ZERO
var pending_cast_action: CastAction = CastAction.NONE
var pending_cast_target: Node2D = null
var facing_left: bool = false
var rng := RandomNumberGenerator.new()
var current_health: float = 0.0
var health_bar_root: Node2D = null
var health_bar_background: Line2D = null
var health_bar_fill: Line2D = null
var cast_bar_background: Line2D = null
var cast_bar_fill: Line2D = null
var special_bar_background: Line2D = null
var special_bar_fill: Line2D = null
var heal_range_indicator: Line2D = null
var special_meter: float = 0.0
var stun_left: float = 0.0
var hit_flash_left: float = 0.0
var heal_flash_left: float = 0.0
var combat_number_popup_sequence: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO
var dead: bool = false
var manual_control_enabled: bool = false
var is_rolling: bool = false
var roll_invulnerable: bool = false
var roll_time_left: float = 0.0
var roll_cooldown_left: float = 0.0
var roll_vector: Vector2 = Vector2.ZERO
var available_weapon_ids: Array[String] = []
var equipped_weapon_id: String = ""
var available_trinket_ids: Array[String] = []
var equipped_trinket_id: String = ""
var available_boot_ids: Array[String] = []
var death_anim_time: float = 0.0
var death_cleanup_started: bool = false
var marked_lunge_panic_left: float = 0.0
var marked_lunge_enemy_id: int = -1
var breath_threat_snapshot: Dictionary = {}
var breath_safe_indicator_left: float = 0.0
var breath_safe_indicator: Line2D = null
var harpoon_charge_telegraph: Polygon2D = null
var harpoon_tether_line: Line2D = null
var harpoon_tether_glow_line: Line2D = null
var harpoon_projectile_visual: Node2D = null
var breath_was_safe: bool = false
var hitbox_debug_enabled: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_visual: Polygon2D = get_node_or_null("Shadow") as Polygon2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	if is_instance_valid(shadow_visual):
		shadow_visual.visible = true
	add_to_group("friendly_npcs")
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	if _is_autoplay_requested():
		rng.seed = 2026
	else:
		rng.randomize()
	cast_debug_logging_enabled = _is_env_flag_enabled("HEALER_CAST_DEBUG")
	orbit_phase = 0.0
	heal_timer_left = _next_heal_interval() * 0.45
	basic_heal_cooldown_left = 0.0
	big_heal_cooldown_left = 0.0
	tidal_wave_cooldown_left = 0.0
	light_bolt_cooldown_left = 0.0
	harpoon_cooldown_left = 0.0
	roll_cooldown_left = 0.0
	roll_time_left = 0.0
	is_rolling = false
	roll_invulnerable = false
	roll_vector = Vector2.ZERO
	_initialize_default_equipment_inventory()
	reacquire_left = 0.0
	_acquire_player()
	_configure_sprite()
	if is_instance_valid(sprite):
		sprite_base_position = sprite.position
		facing_left = sprite.flip_h
	smoothed_target_position = position
	desired_guard_side = -1.0 if facing_left else 1.0
	healer_ai_state = HealerAIState.IDLE_SUPPORT
	healer_ai_state_name = String(HEALER_AI_STATE_NAMES.get(healer_ai_state, "IDLE_SUPPORT"))
	healer_ai_target = player
	healer_ai_decision_left = 0.0
	healer_ai_desired_position = position
	pending_cast_action = CastAction.NONE
	pending_cast_target = null
	marked_lunge_panic_left = 0.0
	marked_lunge_enemy_id = -1
	_setup_heal_range_indicator()
	_setup_breath_safe_indicator()
	_setup_harpoon_visuals()
	_prepare_frame_alignment()
	_set_anim_frame("idle", 0)
	current_health = maxf(1.0, max_health)
	special_meter = 0.0
	_setup_health_bar()
	_update_health_bar()
	health_changed.emit(current_health, max_health)


func _exit_tree() -> void:
	_unbind_player_signal()
	_clear_tidal_waves()
	_teardown_harpoon_visuals()
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()


func _physics_process(delta: float) -> void:
	if hitbox_debug_enabled:
		queue_redraw()
	if dead:
		_cancel_harpoon_state()
		if is_instance_valid(heal_range_indicator):
			heal_range_indicator.visible = false
		_tick_death(delta)
		return
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	heal_flash_left = maxf(0.0, heal_flash_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	breath_safe_indicator_left = maxf(0.0, breath_safe_indicator_left - delta)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, maxf(0.0, hit_knockback_decay) * delta)
	if knockback_velocity.length_squared() > 0.0001:
		position += knockback_velocity * delta
		position = _clamp_to_bounds(position)
		if pixel_snap_movement:
			position = position.round()
	if is_instance_valid(sprite):
		if hit_flash_left > 0.0:
			sprite.modulate = Color(1.0, 0.72, 0.72, 1.0)
		elif heal_flash_left > 0.0:
			sprite.modulate = Color(0.72, 1.0, 0.72, 1.0)
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if not is_instance_valid(player):
		reacquire_left = maxf(0.0, reacquire_left - delta)
		if reacquire_left <= 0.0:
			_acquire_player()
			reacquire_left = reacquire_retry_interval
	_refresh_breath_threat()
	if _is_breath_threat_active() and is_casting:
		_cancel_cast_for_breath()
	var marked_lunge_active := false
	if not manual_control_enabled and not _is_breath_threat_active():
		marked_lunge_active = _handle_marked_lunge_threat(delta)
		if marked_lunge_active and is_casting:
			_cancel_cast_for_lunge_mark()
	var primary_enemy := _find_primary_enemy()
	if manual_control_enabled:
		healer_ai_state_name = "PLAYER_CONTROLLED"
		_update_manual_control_movement(delta, primary_enemy)
	elif not marked_lunge_active:
		_update_healer_ai_state(delta, primary_enemy)
		_update_tactical_positioning(delta)
	_apply_miniboss_soft_separation(delta)
	_update_facing()
	_update_heal_range_indicator()
	_update_breath_safe_indicator()
	_update_health_bar()
	basic_heal_cooldown_left = maxf(0.0, basic_heal_cooldown_left - delta)
	big_heal_cooldown_left = maxf(0.0, big_heal_cooldown_left - delta)
	tidal_wave_cooldown_left = maxf(0.0, tidal_wave_cooldown_left - delta)
	light_bolt_cooldown_left = maxf(0.0, light_bolt_cooldown_left - delta)
	harpoon_cooldown_left = maxf(0.0, harpoon_cooldown_left - delta)
	roll_cooldown_left = maxf(0.0, roll_cooldown_left - delta)
	if is_rolling:
		roll_time_left = maxf(0.0, roll_time_left - delta)
		if roll_time_left <= 0.0:
			is_rolling = false
			roll_invulnerable = false
			roll_vector = Vector2.ZERO
	_tick_harpoon_state(delta)
	_update_harpoon_visuals()
	_update_tidal_waves(delta)

	if is_casting:
		_tick_cast(delta)
		return
	if manual_control_enabled:
		if not _is_breath_threat_active():
			_handle_manual_control_actions()
		if _is_tactically_moving():
			_tick_run(delta)
		else:
			_tick_idle(delta)
		return
	if _is_breath_threat_active() or marked_lunge_active:
		return

	if _is_tactically_moving():
		_tick_run(delta)
	else:
		_tick_idle(delta)
	if _find_best_heal_target(false) != null:
		heal_timer_left = minf(heal_timer_left, react_heal_delay)
	heal_timer_left = maxf(0.0, heal_timer_left - delta)
	if heal_timer_left > 0.0:
		return
	_try_begin_ai_cast()


func _update_manual_control_movement(delta: float, attack_target: EnemyBase) -> void:
	if stun_left > 0.0:
		move_velocity = move_velocity.move_toward(Vector2.ZERO, maxf(0.0, movement_deceleration) * delta)
		return
	if is_rolling:
		var lane_roll := Vector2(roll_vector.x, roll_vector.y * maxf(0.1, roll_depth_speed_multiplier))
		if lane_roll.length_squared() > 1.0:
			lane_roll = lane_roll.normalized()
		move_velocity = lane_roll * maxf(1.0, roll_speed * _get_healer_roll_speed_multiplier())
		position += move_velocity * maxf(0.0, delta)
		position = _clamp_to_bounds(position)
		if pixel_snap_movement:
			position = position.round()
		if absf(move_velocity.x) > 2.0:
			facing_left = move_velocity.x < 0.0
		return
	var move_input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if move_input.length_squared() > 1.0:
		move_input = move_input.normalized()
	if is_casting:
		if move_input.length_squared() <= 0.0001:
			move_velocity = Vector2.ZERO
			return
		_cancel_current_cast(false)
	move_velocity = move_input * maxf(1.0, move_speed * _get_healer_move_speed_multiplier())
	position += move_velocity * maxf(0.0, delta)
	position = _clamp_to_bounds(position)
	if pixel_snap_movement:
		position = position.round()
	if absf(move_velocity.x) > 2.0:
		facing_left = move_velocity.x < 0.0
	elif attack_target != null and is_instance_valid(attack_target):
		var to_target_x := attack_target.global_position.x - global_position.x
		if absf(to_target_x) > 2.0:
			facing_left = to_target_x < 0.0


func _handle_manual_control_actions() -> void:
	if harpoon_charge_active or harpoon_projectile_active or harpoon_reel_active:
		return
	if is_rolling:
		return
	if Input.is_action_just_pressed("roll"):
		if _try_start_manual_roll():
			return
	var allow_full_health_heal_targets := _should_allow_full_health_heal_targets()
	if Input.is_action_just_pressed("basic_attack"):
		var attack_target := _find_healer_attack_target()
		if light_bolt_enabled and light_bolt_cooldown_left <= 0.0 and _can_cast_light_bolt_on_target(attack_target):
			_queue_cast_action(CastAction.LIGHT_BOLT, attack_target, 0.1)
			return
	if Input.is_action_just_pressed("ability_1"):
		if _try_start_harpoon_charge():
			return
	if Input.is_action_just_pressed("counter_strike"):
		var quick_heal_target := _get_manual_heal_cast_target(allow_full_health_heal_targets)
		if basic_heal_cooldown_left <= 0.0 and _can_cast_basic_heal_on_target(quick_heal_target, allow_full_health_heal_targets):
			_queue_cast_action(CastAction.QUICK_HEAL, quick_heal_target, 0.1)
			return
	if Input.is_action_just_pressed("block"):
		var big_heal_target := _get_manual_heal_cast_target(allow_full_health_heal_targets)
		if big_heal_cooldown_left <= 0.0 and _can_cast_basic_heal_on_target(big_heal_target, allow_full_health_heal_targets):
			_queue_cast_action(CastAction.BIG_HEAL, big_heal_target, 0.1)
			return
	if Input.is_action_just_pressed("ability_2"):
		var wave_target := _find_healer_attack_target()
		if _can_cast_tidal_wave_on_target(wave_target):
			_queue_cast_action(CastAction.TIDAL_WAVE, wave_target, 0.1)


func _can_start_manual_roll() -> bool:
	if not manual_control_enabled:
		return false
	if dead:
		return false
	if roll_cooldown_left > 0.0:
		return false
	if is_rolling:
		return false
	if stun_left > 0.0:
		return false
	if is_casting:
		return false
	if harpoon_charge_active or harpoon_projectile_active or harpoon_reel_active:
		return false
	return true


func _try_start_manual_roll() -> bool:
	if not _can_start_manual_roll():
		return false
	var movement_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if movement_vector.length_squared() > 1.0:
		movement_vector = movement_vector.normalized()
	if movement_vector == Vector2.ZERO:
		movement_vector = Vector2.LEFT if facing_left else Vector2.RIGHT
	roll_vector = movement_vector.normalized()
	is_rolling = true
	roll_invulnerable = true
	roll_time_left = maxf(0.05, roll_duration)
	roll_cooldown_left = maxf(0.05, roll_cooldown * _get_healer_roll_cooldown_multiplier())
	move_velocity = Vector2.ZERO
	is_casting = false
	cast_anim_time = 0.0
	heal_applied_this_cast = false
	pending_cast_action = CastAction.NONE
	pending_cast_target = null
	_set_anim_frame("idle", 0)
	_cancel_harpoon_state()
	return true


func _acquire_player() -> void:
	_bind_player(get_tree().get_first_node_in_group("player") as Player)


func set_player(target_player: Player) -> void:
	_bind_player(target_player)
	if _player_needs_healing():
		heal_timer_left = minf(heal_timer_left, react_heal_delay)


func _get_quick_heal_cooldown_duration() -> float:
	if manual_control_enabled:
		return 0.0
	return maxf(0.0, basic_heal_cooldown)


func set_manual_control_enabled(enabled: bool) -> void:
	manual_control_enabled = enabled
	move_velocity = Vector2.ZERO
	_update_heal_range_indicator()
	if not manual_control_enabled:
		is_rolling = false
		roll_invulnerable = false
		roll_time_left = 0.0
		roll_vector = Vector2.ZERO
		_cancel_harpoon_state()
		healer_ai_decision_left = 0.0
		return
	basic_heal_cooldown_left = 0.0
	healer_ai_state_name = "PLAYER_CONTROLLED"
	pending_cast_action = CastAction.NONE
	pending_cast_target = null


func is_manual_control_enabled() -> bool:
	return manual_control_enabled


func get_shield_slot_display_name() -> String:
	return "Trinkets"


func get_shield_slot_singular_display_name() -> String:
	return "Trinket"


func get_shield_slot_empty_text() -> String:
	return "No trinkets found."


func get_shield_slot_default_icon() -> String:
	return "TRK"


func get_available_sword_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for weapon_id in available_weapon_ids:
		if not HEALER_WEAPON_DEFINITIONS.has(weapon_id):
			continue
		var weapon_data_variant: Variant = HEALER_WEAPON_DEFINITIONS[weapon_id]
		if weapon_data_variant is Dictionary:
			entries.append((weapon_data_variant as Dictionary).duplicate(true))
	return entries


func get_equipped_sword_id() -> String:
	return equipped_weapon_id


func get_equipped_sword_name() -> String:
	if equipped_weapon_id.is_empty():
		return "No Weapon"
	if not HEALER_WEAPON_DEFINITIONS.has(equipped_weapon_id):
		return equipped_weapon_id
	var weapon_data_variant: Variant = HEALER_WEAPON_DEFINITIONS[equipped_weapon_id]
	if weapon_data_variant is Dictionary:
		return String((weapon_data_variant as Dictionary).get("name", equipped_weapon_id))
	return equipped_weapon_id


func equip_sword(sword_id: String) -> bool:
	var weapon_id := sword_id.strip_edges().to_lower()
	if weapon_id.is_empty():
		return false
	if available_weapon_ids.find(weapon_id) == -1:
		return false
	if equipped_weapon_id == weapon_id:
		return false
	equipped_weapon_id = weapon_id
	return true


func get_available_shield_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for trinket_id in available_trinket_ids:
		if not HEALER_TRINKET_DEFINITIONS.has(trinket_id):
			continue
		var trinket_data_variant: Variant = HEALER_TRINKET_DEFINITIONS[trinket_id]
		if trinket_data_variant is Dictionary:
			entries.append((trinket_data_variant as Dictionary).duplicate(true))
	return entries


func get_equipped_shield_id() -> String:
	return equipped_trinket_id


func get_equipped_shield_name() -> String:
	if equipped_trinket_id.is_empty():
		return "No Trinket"
	if not HEALER_TRINKET_DEFINITIONS.has(equipped_trinket_id):
		return equipped_trinket_id
	var trinket_data_variant: Variant = HEALER_TRINKET_DEFINITIONS[equipped_trinket_id]
	if trinket_data_variant is Dictionary:
		return String((trinket_data_variant as Dictionary).get("name", equipped_trinket_id))
	return equipped_trinket_id


func equip_shield(shield_id: String) -> bool:
	var trinket_id := shield_id.strip_edges().to_lower()
	if trinket_id.is_empty():
		return false
	if available_trinket_ids.find(trinket_id) == -1:
		return false
	if equipped_trinket_id == trinket_id:
		return false
	equipped_trinket_id = trinket_id
	return true


func get_available_ring_entries() -> Array[Dictionary]:
	return []


func get_equipped_ring_id() -> String:
	return ""


func get_equipped_ring_name() -> String:
	return "No Ring"


func equip_ring(_ring_id: String) -> bool:
	return false


func get_equipped_boot_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for boot_id in available_boot_ids:
		if not HEALER_BOOT_DEFINITIONS.has(boot_id):
			continue
		var boot_data_variant: Variant = HEALER_BOOT_DEFINITIONS[boot_id]
		if not (boot_data_variant is Dictionary):
			continue
		var boot_data := (boot_data_variant as Dictionary).duplicate(true)
		boot_data["equipped"] = true
		entries.append(boot_data)
	return entries


func get_gold_total() -> int:
	if not is_instance_valid(player):
		return 0
	if not player.has_method("get_gold_total"):
		return 0
	return maxi(0, int(player.call("get_gold_total")))


func get_store_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_id_variant in HEALER_STORE_ITEM_ORDER:
		var item_id := String(item_id_variant).strip_edges().to_lower()
		if item_id.is_empty():
			continue
		var item_data := _get_healer_store_definition(item_id)
		if item_data.is_empty():
			continue
		entries.append({
			"item_id": item_id,
			"name": String(item_data.get("name", item_id)),
			"description": String(item_data.get("description", "Healer upgrade.")),
			"price": HEALER_ITEM_PRICE,
			"owned": _is_store_item_owned(item_id)
		})
	return entries


func purchase_store_item(item_id: String) -> Dictionary:
	var normalized_item_id := item_id.strip_edges().to_lower()
	if normalized_item_id.is_empty() or _get_healer_store_definition(normalized_item_id).is_empty():
		return {
			"success": false,
			"reason": "Item unavailable.",
			"gold_total": get_gold_total()
		}
	if _is_store_item_owned(normalized_item_id):
		return {
			"success": false,
			"reason": "Already owned.",
			"gold_total": get_gold_total()
		}
	if get_gold_total() < HEALER_ITEM_PRICE:
		return {
			"success": false,
			"reason": "Not enough gold.",
			"gold_total": get_gold_total()
		}
	if not _spend_shared_gold(HEALER_ITEM_PRICE):
		return {
			"success": false,
			"reason": "Unable to spend gold.",
			"gold_total": get_gold_total()
		}
	var granted := _grant_store_item(normalized_item_id)
	if not granted:
		return {
			"success": false,
			"reason": "Grant failed.",
			"gold_total": get_gold_total()
		}
	var item_data := _get_healer_store_definition(normalized_item_id)
	return {
		"success": true,
		"item_id": normalized_item_id,
		"item_name": String(item_data.get("name", normalized_item_id)),
		"price": HEALER_ITEM_PRICE,
		"gold_total": get_gold_total()
	}


func _is_store_item_owned(item_id: String) -> bool:
	if HEALER_WEAPON_DEFINITIONS.has(item_id):
		return available_weapon_ids.find(item_id) != -1
	if HEALER_TRINKET_DEFINITIONS.has(item_id):
		return available_trinket_ids.find(item_id) != -1
	if HEALER_BOOT_DEFINITIONS.has(item_id):
		return available_boot_ids.find(item_id) != -1
	return false


func _get_healer_store_definition(item_id: String) -> Dictionary:
	if HEALER_WEAPON_DEFINITIONS.has(item_id):
		return (HEALER_WEAPON_DEFINITIONS[item_id] as Dictionary).duplicate(true)
	if HEALER_TRINKET_DEFINITIONS.has(item_id):
		return (HEALER_TRINKET_DEFINITIONS[item_id] as Dictionary).duplicate(true)
	if HEALER_BOOT_DEFINITIONS.has(item_id):
		return (HEALER_BOOT_DEFINITIONS[item_id] as Dictionary).duplicate(true)
	return {}


func _spend_shared_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if not is_instance_valid(player):
		return false
	var current_gold := maxi(0, int(player.gold_total))
	if current_gold < amount:
		return false
	player.gold_total = maxi(0, current_gold - amount)
	return true


func _grant_store_item(item_id: String) -> bool:
	if HEALER_WEAPON_DEFINITIONS.has(item_id):
		if available_weapon_ids.find(item_id) == -1:
			available_weapon_ids.append(item_id)
		if equipped_weapon_id.is_empty():
			equipped_weapon_id = item_id
		_sort_healer_owned_items()
		return true
	if HEALER_TRINKET_DEFINITIONS.has(item_id):
		if available_trinket_ids.find(item_id) == -1:
			available_trinket_ids.append(item_id)
		if equipped_trinket_id.is_empty():
			equipped_trinket_id = item_id
		_sort_healer_owned_items()
		return true
	if HEALER_BOOT_DEFINITIONS.has(item_id):
		if available_boot_ids.find(item_id) == -1:
			available_boot_ids.append(item_id)
		_sort_healer_owned_items()
		return true
	return false


func get_manual_control_cooldown_state() -> Dictionary:
	var special_ratio := _get_special_meter_ratio()
	var special_ready := special_ratio >= 0.999
	return {
		"ability_layout": "healer",
		"basic": light_bolt_cooldown_left,
		"basic_unlocked": light_bolt_enabled,
		"quick_heal": 0.0,
		"quick_heal_unlocked": true,
		"ability_1": harpoon_cooldown_left,
		"ability_1_unlocked": harpoon_enabled,
		"harpoon_charging": harpoon_charge_active,
		"harpoon_charge_ratio": _get_harpoon_charge_ratio_from_time(harpoon_charge_time) if harpoon_charge_active else 0.0,
		"ability_2": tidal_wave_cooldown_left,
		"ability_2_unlocked": tidal_wave_enabled and special_ready,
		"roll": roll_cooldown_left,
		"roll_unlocked": true,
		"block_active": false,
		"block_cooldown_left": big_heal_cooldown_left,
		"counter_unlocked": true,
		"counter_ready": special_ready,
		"counter_window_left": 0.0,
		"special_meter_ratio": special_ratio
	}


func _initialize_default_equipment_inventory() -> void:
	available_weapon_ids.clear()
	equipped_weapon_id = ""
	available_trinket_ids.clear()
	equipped_trinket_id = ""
	available_boot_ids.clear()


func _is_equipped_healer_weapon(weapon_id: String) -> bool:
	return not weapon_id.is_empty() and equipped_weapon_id == weapon_id


func _is_equipped_healer_trinket(trinket_id: String) -> bool:
	return not trinket_id.is_empty() and equipped_trinket_id == trinket_id


func _has_healer_boot(boot_id: String) -> bool:
	return not boot_id.is_empty() and available_boot_ids.find(boot_id) != -1


func _get_equipped_healer_weapon_data() -> Dictionary:
	if equipped_weapon_id.is_empty() or not HEALER_WEAPON_DEFINITIONS.has(equipped_weapon_id):
		return {}
	return (HEALER_WEAPON_DEFINITIONS[equipped_weapon_id] as Dictionary).duplicate(true)


func _get_equipped_healer_trinket_data() -> Dictionary:
	if equipped_trinket_id.is_empty() or not HEALER_TRINKET_DEFINITIONS.has(equipped_trinket_id):
		return {}
	return (HEALER_TRINKET_DEFINITIONS[equipped_trinket_id] as Dictionary).duplicate(true)


func _get_healer_move_speed_multiplier() -> float:
	if not _has_healer_boot("foamstep_boots"):
		return 1.0
	var boot_data := HEALER_BOOT_DEFINITIONS.get("foamstep_boots", {}) as Dictionary
	return maxf(1.0, float(boot_data.get("move_speed_multiplier", 1.0)))


func _get_healer_roll_cooldown_multiplier() -> float:
	if not _has_healer_boot("blinkstep_boots"):
		return 1.0
	var boot_data := HEALER_BOOT_DEFINITIONS.get("blinkstep_boots", {}) as Dictionary
	return clampf(float(boot_data.get("roll_cooldown_multiplier", 1.0)), 0.1, 1.0)


func _get_healer_roll_speed_multiplier() -> float:
	if not _has_healer_boot("blinkstep_boots"):
		return 1.0
	var boot_data := HEALER_BOOT_DEFINITIONS.get("blinkstep_boots", {}) as Dictionary
	return maxf(1.0, float(boot_data.get("roll_speed_multiplier", 1.0)))


func _get_healer_harpoon_cooldown_multiplier() -> float:
	if not _has_healer_boot("tidegrip_boots"):
		return 1.0
	var boot_data := HEALER_BOOT_DEFINITIONS.get("tidegrip_boots", {}) as Dictionary
	return clampf(float(boot_data.get("harpoon_cooldown_multiplier", 1.0)), 0.1, 1.0)


func _get_healer_harpoon_reel_speed_multiplier() -> float:
	if not _has_healer_boot("tidegrip_boots"):
		return 1.0
	var boot_data := HEALER_BOOT_DEFINITIONS.get("tidegrip_boots", {}) as Dictionary
	return maxf(1.0, float(boot_data.get("harpoon_reel_speed_multiplier", 1.0)))


func _get_healer_special_meter_gain_multiplier() -> float:
	var trinket_data := _get_equipped_healer_trinket_data()
	if trinket_data.is_empty():
		return 1.0
	return maxf(0.1, float(trinket_data.get("special_gain_multiplier", 1.0)))


func _is_cast_uninterruptible_from_trinket() -> bool:
	var trinket_data := _get_equipped_healer_trinket_data()
	if trinket_data.is_empty():
		return false
	return bool(trinket_data.get("cast_uninterruptible", false))


func _get_cast_damage_multiplier_from_trinket() -> float:
	var trinket_data := _get_equipped_healer_trinket_data()
	if trinket_data.is_empty():
		return 1.0
	return clampf(float(trinket_data.get("cast_damage_multiplier", 1.0)), 0.1, 1.0)


func _sort_healer_owned_items() -> void:
	available_weapon_ids = _sort_ids_by_order(available_weapon_ids, HEALER_WEAPON_ORDER)
	available_trinket_ids = _sort_ids_by_order(available_trinket_ids, HEALER_TRINKET_ORDER)
	available_boot_ids = _sort_ids_by_order(available_boot_ids, HEALER_BOOT_ORDER)


func _sort_ids_by_order(ids: Array[String], ordered_ids: Array[String]) -> Array[String]:
	var sorted: Array[String] = []
	for ordered_id in ordered_ids:
		if ids.find(ordered_id) != -1:
			sorted.append(ordered_id)
	for id in ids:
		if sorted.find(id) == -1:
			sorted.append(id)
	return sorted


func _bind_player(target_player: Player) -> void:
	if player == target_player and is_instance_valid(player):
		return
	_unbind_player_signal()
	player = target_player
	if not is_instance_valid(player):
		tracked_player_health = -1.0
		return
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	tracked_player_health = player.current_health
	_on_player_health_changed(player.current_health, player.max_health)


func _unbind_player_signal() -> void:
	if not is_instance_valid(player):
		return
	if player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.disconnect(_on_player_health_changed)


func _on_player_health_changed(current: float, maximum: float) -> void:
	var was_higher := tracked_player_health > current + 0.001
	tracked_player_health = current
	if maximum <= 0.0:
		return
	if current >= (maximum * heal_threshold_ratio):
		return
	if is_casting:
		return
	if emergency_cast_on_damage and was_higher:
		heal_timer_left = 0.0
		return
	if heal_timer_left > react_heal_delay or was_higher:
		heal_timer_left = minf(heal_timer_left, react_heal_delay)


func _refresh_breath_threat() -> void:
	breath_threat_snapshot = COMPANION_BREATH_RESPONSE_SCRIPT.get_active_threat(get_tree())
	if not _is_breath_threat_active():
		breath_was_safe = false
		return
	var in_safe_pocket: bool = COMPANION_BREATH_RESPONSE_SCRIPT.is_position_safe(global_position, breath_threat_snapshot)
	if in_safe_pocket and not breath_was_safe:
		breath_safe_indicator_left = maxf(breath_safe_indicator_left, 0.6)
	breath_was_safe = in_safe_pocket


func _is_breath_threat_active() -> bool:
	return bool(breath_threat_snapshot.get("active", false))


func _cancel_current_cast(reset_heal_timer: bool = true) -> void:
	if not is_casting and pending_cast_action == CastAction.NONE and pending_cast_target == null:
		return
	is_casting = false
	cast_anim_time = 0.0
	heal_applied_this_cast = false
	pending_cast_action = CastAction.NONE
	pending_cast_target = null
	_set_anim_frame("idle", 0)
	if reset_heal_timer:
		heal_timer_left = minf(heal_timer_left, react_heal_delay)


func _cancel_cast_for_breath() -> void:
	_cancel_current_cast(true)


func _cancel_cast_for_lunge_mark() -> void:
	_cancel_current_cast(true)


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
	var threat_enemy := _get_enemy_marking_self_for_lunge()
	if threat_enemy == null:
		marked_lunge_enemy_id = -1
		marked_lunge_panic_left = 0.0
		return false

	var enemy_id := threat_enemy.get_instance_id()
	if marked_lunge_enemy_id != enemy_id:
		marked_lunge_enemy_id = enemy_id
		marked_lunge_panic_left = maxf(marked_lunge_panic_left, maxf(0.0, marked_lunge_panic_freeze_duration))

	move_velocity = Vector2.ZERO
	healer_ai_state = HealerAIState.REPOSITIONING
	healer_ai_target = threat_enemy
	healer_ai_state_name = "MARKED_PANIC"
	marked_lunge_panic_left = maxf(0.0, marked_lunge_panic_left - maxf(0.0, delta))
	if marked_lunge_panic_left > 0.0:
		return true

	var desired_world := player.global_position if is_instance_valid(player) else global_position
	if threat_enemy.has_method("get_marked_ally_protection_point"):
		var protection_variant: Variant = threat_enemy.call("get_marked_ally_protection_point")
		if protection_variant is Vector2:
			desired_world = protection_variant
	var desired_local := _clamp_to_bounds(desired_world)
	var to_safe := desired_local - position
	var hold_radius := maxf(6.0, marked_lunge_hold_radius)
	if to_safe.length() <= hold_radius:
		move_velocity = Vector2.ZERO
		position = _clamp_to_bounds(position)
		return true

	var speed := maxf(18.0, move_speed * _get_healer_move_speed_multiplier() * maxf(0.1, marked_lunge_move_speed_multiplier))
	var move_dir := to_safe.normalized()
	if use_player_like_movement:
		move_dir = _quantize_player_like_direction(move_dir)
	move_velocity = move_dir * speed
	position += move_velocity * maxf(0.0, delta)
	position = _clamp_to_bounds(position)
	if pixel_snap_movement:
		position = position.round()
	return true


func _update_healer_ai_state(delta: float, primary_enemy: EnemyBase) -> void:
	healer_ai_decision_left = maxf(0.0, healer_ai_decision_left - delta)
	if healer_ai_decision_left > 0.0:
		return
	healer_ai_decision_left = maxf(0.05, ai_decision_interval)
	if _is_breath_threat_active():
		_set_healer_ai_state(HealerAIState.BREATH_STACK, primary_enemy if primary_enemy != null else player)
		return

	var heal_target := _find_best_heal_target(false)
	if heal_target != null:
		_set_healer_ai_state(HealerAIState.HEALING, heal_target)
		return

	var attack_target := _find_healer_attack_target()
	if attack_target != null:
		if _needs_reposition(primary_enemy) and not _should_prepare_tidal_wave(attack_target):
			_set_healer_ai_state(HealerAIState.REPOSITIONING, player)
		else:
			_set_healer_ai_state(HealerAIState.ATTACKING, attack_target)
		return

	if _needs_reposition(primary_enemy):
		_set_healer_ai_state(HealerAIState.REPOSITIONING, player)
		return
	_set_healer_ai_state(HealerAIState.IDLE_SUPPORT, player)


func _set_healer_ai_state(next_state: HealerAIState, next_target: Node2D) -> void:
	healer_ai_state = next_state
	healer_ai_state_name = String(HEALER_AI_STATE_NAMES.get(next_state, "IDLE_SUPPORT"))
	healer_ai_target = next_target


func _is_valid_support_target(target: Node2D) -> bool:
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
	var target_ratfolk := target as FriendlyRatfolk
	if target_ratfolk != null:
		if target_ratfolk.is_shadow_clone_actor():
			return false
		return not target_ratfolk.dead
	return false


func _find_healer_attack_target() -> EnemyBase:
	var best_minion: EnemyBase = null
	var best_minion_distance_sq := INF
	var best_minion_id := INF
	var best_boss: EnemyBase = null
	var best_boss_distance_sq := INF
	var best_boss_id := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var distance_sq := global_position.distance_squared_to(enemy.global_position)
		var enemy_id := enemy.get_instance_id()
		if enemy.is_miniboss:
			if best_boss == null or distance_sq < best_boss_distance_sq or (is_equal_approx(distance_sq, best_boss_distance_sq) and enemy_id < best_boss_id):
				best_boss = enemy
				best_boss_distance_sq = distance_sq
				best_boss_id = enemy_id
			continue
		if best_minion == null or distance_sq < best_minion_distance_sq or (is_equal_approx(distance_sq, best_minion_distance_sq) and enemy_id < best_minion_id):
			best_minion = enemy
			best_minion_distance_sq = distance_sq
			best_minion_id = enemy_id
	if best_minion != null:
		return best_minion
	return best_boss


func _needs_reposition(primary_enemy: EnemyBase) -> bool:
	if not is_instance_valid(player):
		return false
	var to_player := player.global_position - global_position
	var distance_to_player := to_player.length()
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		var idle_min_band := maxf(min_distance_to_player, follow_distance - 24.0)
		var idle_max_band := maxf(idle_min_band + 8.0, follow_distance + 28.0)
		return distance_to_player < idle_min_band or distance_to_player > idle_max_band
	var min_band := maxf(min_distance_to_player, healer_follow_min_band)
	var max_band := maxf(min_band + 8.0, healer_follow_max_band)
	if distance_to_player < min_band or distance_to_player > max_band:
		return true
	var player_to_enemy := primary_enemy.global_position - player.global_position
	var player_to_healer := global_position - player.global_position
	if absf(player_to_enemy.x) <= 8.0:
		return false
	return signf(player_to_enemy.x) == signf(player_to_healer.x)


func _try_begin_ai_cast() -> void:
	if is_casting:
		return
	pending_cast_action = CastAction.NONE
	pending_cast_target = null
	match healer_ai_state:
		HealerAIState.HEALING:
			var heal_target := _resolve_heal_target(healer_ai_target, false)
			var wave_attack_target := _find_healer_attack_target()
			if _should_cast_tidal_wave(wave_attack_target):
				_queue_cast_action(CastAction.TIDAL_WAVE, wave_attack_target, 0.08)
				return
			if basic_heal_cooldown_left <= 0.0:
				if _can_cast_basic_heal_on_target(heal_target, false):
					_queue_cast_action(CastAction.QUICK_HEAL, heal_target, 0.08)
				else:
					heal_timer_left = 0.08
				return
			heal_timer_left = maxf(0.08, basic_heal_cooldown_left)
			return
		HealerAIState.ATTACKING:
			var attack_target := _resolve_attack_target(healer_ai_target)
			if light_bolt_enabled and light_bolt_cooldown_left <= 0.0 and _can_cast_light_bolt_on_target(attack_target):
				_queue_cast_action(CastAction.LIGHT_BOLT, attack_target, 0.1)
				return
			var next_attack_ready := maxf(0.1, light_bolt_cooldown_left)
			if tidal_wave_enabled:
				next_attack_ready = minf(next_attack_ready, maxf(0.1, tidal_wave_cooldown_left))
			heal_timer_left = next_attack_ready
			return
		_:
			pass
	var fallback_heal_target := _find_best_heal_target(false)
	if basic_heal_cooldown_left <= 0.0 and _can_cast_basic_heal_on_target(fallback_heal_target, false):
		_queue_cast_action(CastAction.QUICK_HEAL, fallback_heal_target, 0.14)
		return
	if _is_healing_ability_ready():
		heal_timer_left = 0.22
	else:
		heal_timer_left = maxf(0.1, _time_until_next_healing_ability_ready())


func _queue_cast_action(action: CastAction, target: Node2D, next_timer: float) -> void:
	var selected_target := target
	if action == CastAction.QUICK_HEAL or action == CastAction.BIG_HEAL:
		var allow_full_health_heal_targets := _should_allow_full_health_heal_targets()
		selected_target = _resolve_heal_target(target, allow_full_health_heal_targets)
		if selected_target == null:
			selected_target = _find_best_heal_target(allow_full_health_heal_targets)
	pending_cast_action = action
	pending_cast_target = selected_target
	if action == CastAction.LIGHT_BOLT or action == CastAction.TIDAL_WAVE:
		_face_target(selected_target)
	_log_cast_event("QUEUE", action, selected_target)
	if cast_debug_logging_enabled and action == CastAction.TIDAL_WAVE:
		var evaluation := _evaluate_tidal_wave_targets(selected_target)
		print("[HEALER_CAST] TIDAL_WAVE_EVAL target=%s enemies=%d allies=%d injured_allies=%d target_in_lane=%s dir=%.0f" % [
			selected_target.name if selected_target != null and is_instance_valid(selected_target) else "None",
			int(evaluation.get("enemy_hits", 0)),
			int(evaluation.get("ally_hits", 0)),
			int(evaluation.get("injured_allies", 0)),
			str(bool(evaluation.get("target_in_lane", false))),
			float((evaluation.get("direction", Vector2.RIGHT) as Vector2).x)
		])
	_begin_cast()
	heal_timer_left = maxf(0.05, next_timer)


func _configure_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = HEALER_SHEET
	sprite.hframes = HEALER_HFRAMES
	sprite.vframes = HEALER_VFRAMES


func _tick_idle(delta: float) -> void:
	var fps := float(ANIM_FPS.get("idle", 6.0))
	var frame_count := _anim_frame_count("idle")
	idle_anim_time += delta * fps
	var frame_index := int(floor(idle_anim_time)) % frame_count
	_set_anim_frame("idle", frame_index)


func _tick_run(delta: float) -> void:
	var fps := float(ANIM_FPS.get("run", 10.0))
	var frame_count := _anim_frame_count("run")
	run_anim_time += delta * fps
	var frame_index := int(floor(run_anim_time)) % frame_count
	_set_anim_frame("run", frame_index)


func _begin_cast() -> void:
	is_casting = true
	cast_anim_time = 0.0
	heal_applied_this_cast = false
	move_velocity = Vector2.ZERO
	if pending_cast_action == CastAction.LIGHT_BOLT or pending_cast_action == CastAction.TIDAL_WAVE:
		_face_target(pending_cast_target)
	_set_anim_frame("cast", 0)
	_spawn_cast_flash(global_position + Vector2(0.0, -18.0))


func _tick_cast(delta: float) -> void:
	var fps := float(ANIM_FPS.get("cast", 12.0))
	var frame_count := _anim_frame_count("cast")
	var cast_time_multiplier := _get_cast_time_multiplier_for_action(pending_cast_action)
	var cast_rate_scale := 1.0 / maxf(0.01, cast_time_multiplier)
	cast_anim_time += delta * fps * cast_rate_scale

	var cast_progress := clampf(cast_anim_time / maxf(1.0, float(frame_count)), 0.0, 1.0)
	var frame_index := frame_count - 1
	if frame_count > 1:
		frame_index = mini(int(floor(cast_progress * float(frame_count - 1))), frame_count - 1)
	_set_anim_frame("cast", frame_index)

	if not heal_applied_this_cast and cast_anim_time >= float(frame_count):
		heal_applied_this_cast = true
		_trigger_healing_ability()

	if cast_anim_time < float(frame_count):
		return

	is_casting = false
	cast_anim_time = 0.0
	heal_timer_left = minf(_next_heal_interval() * 0.2, react_heal_delay)
	_set_anim_frame("idle", 0)


func _get_cast_time_multiplier_for_action(action: CastAction) -> float:
	if action == CastAction.QUICK_HEAL:
		return maxf(0.1, quick_heal_cast_time_multiplier)
	if action == CastAction.BIG_HEAL:
		return maxf(0.1, quick_heal_cast_time_multiplier * maxf(0.1, big_heal_cast_time_multiplier))
	return 1.0


func _player_needs_healing() -> bool:
	if not is_instance_valid(player):
		return false
	return player.needs_healing(heal_threshold_ratio)


func _should_allow_full_health_heal_targets() -> bool:
	return manual_control_enabled


func _is_manual_self_heal_modifier_pressed() -> bool:
	return manual_control_enabled and Input.is_key_pressed(KEY_SHIFT)


func _get_manual_heal_cast_target(allow_full_health_targets: bool = true) -> Node2D:
	if _is_manual_self_heal_modifier_pressed():
		var self_target := _resolve_heal_target(self, allow_full_health_targets)
		if self_target != null:
			return self_target
	return _resolve_heal_target(_find_best_heal_target(allow_full_health_targets), allow_full_health_targets)


func _is_valid_heal_target(target: Node2D) -> bool:
	if not _is_valid_support_target(target):
		return false
	if not target.has_method("needs_healing"):
		return false
	if not target.has_method("receive_heal"):
		return false
	if _is_marked_target_waiting_for_damage(target):
		return false
	return true


func _is_marked_target_waiting_for_damage(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
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
		if marked_target.get_instance_id() == target.get_instance_id():
			return true
	return false


func _get_target_current_health(target: Node2D) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0
	var target_max_health := maxf(1.0, float(target.get("max_health")))
	return clampf(float(target.get("current_health")), 0.0, target_max_health)


func _get_missing_health(target: Node2D) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0
	var target_max_health := maxf(1.0, float(target.get("max_health")))
	var target_current_health := _get_target_current_health(target)
	return maxf(0.0, target_max_health - target_current_health)


func _is_heal_target_injured(target: Node2D) -> bool:
	return _get_missing_health(target) > 0.001


func _find_best_heal_target(allow_full_health_targets: bool = true) -> Node2D:
	# Healing casts lock to the nearest valid ally at cast start.
	var best_target: Node2D = null
	var best_distance_sq := INF
	var best_id := INF
	var candidates := _collect_heal_target_candidates(false, allow_full_health_targets)
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		var distance_sq := global_position.distance_squared_to(candidate.global_position)
		var candidate_id := candidate.get_instance_id()
		if best_target == null or distance_sq < best_distance_sq - 0.0001 or (is_equal_approx(distance_sq, best_distance_sq) and candidate_id < best_id):
			best_target = candidate
			best_distance_sq = distance_sq
			best_id = candidate_id
	if best_target != null:
		return best_target
	if _is_valid_heal_target(self) and (allow_full_health_targets or _is_heal_target_injured(self)):
		return self
	return null


func _collect_heal_target_candidates(include_self: bool = false, allow_full_health_targets: bool = true) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	if is_instance_valid(player) and _is_valid_heal_target(player):
		if allow_full_health_targets or _is_heal_target_injured(player):
			candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not include_self and candidate == self:
			continue
		if not _is_valid_heal_target(candidate):
			continue
		if not allow_full_health_targets and not _is_heal_target_injured(candidate):
			continue
		candidates.append(candidate)
	return candidates


func _resolve_heal_target(preferred_target: Node2D = null, allow_full_health_targets: bool = true) -> Node2D:
	if _is_valid_heal_target(preferred_target) and (allow_full_health_targets or _is_heal_target_injured(preferred_target)):
		return preferred_target
	var state_target := healer_ai_target
	if _is_valid_heal_target(state_target) and (allow_full_health_targets or _is_heal_target_injured(state_target)):
		return state_target
	var fallback_target := _find_best_heal_target(allow_full_health_targets)
	if _is_valid_heal_target(fallback_target) and (allow_full_health_targets or _is_heal_target_injured(fallback_target)):
		return fallback_target
	return null


func _is_in_basic_heal_range(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= maxf(16.0, basic_heal_range)


func _can_cast_basic_heal_on_target(target: Node2D, allow_full_health_targets: bool = true) -> bool:
	var resolved_target := _resolve_heal_target(target, allow_full_health_targets)
	if resolved_target == null:
		return false
	if not allow_full_health_targets and not _is_heal_target_injured(resolved_target):
		return false
	return _is_in_basic_heal_range(resolved_target)


func _resolve_attack_target(preferred_target: Node2D = null) -> EnemyBase:
	var preferred_enemy := preferred_target as EnemyBase
	if preferred_enemy != null and is_instance_valid(preferred_enemy) and not preferred_enemy.dead and not _is_enemy_shadow_feared(preferred_enemy):
		return preferred_enemy
	return _find_healer_attack_target()


func _can_cast_light_bolt_on_target(target: Node2D) -> bool:
	var resolved_target := _resolve_attack_target(target)
	if resolved_target != null and _is_enemy_shadow_feared(resolved_target):
		return false
	return true


func _can_cast_tidal_wave_on_target(target: Node2D) -> bool:
	if not tidal_wave_enabled:
		return false
	if not _is_special_meter_full():
		return false
	var resolved_target := _resolve_attack_target(target)
	if resolved_target == null:
		return false
	return true


func _should_cast_tidal_wave(target: Node2D) -> bool:
	if not tidal_wave_enabled:
		return false
	if not _is_special_meter_full():
		return false
	var resolved_target := _resolve_attack_target(target)
	if resolved_target == null:
		return false
	var evaluation := _evaluate_tidal_wave_targets(resolved_target)
	var enemy_hits := int(evaluation.get("enemy_hits", 0))
	if enemy_hits <= 0:
		return false
	var injured_allies := int(evaluation.get("injured_allies", 0))
	if injured_allies <= 0:
		return false
	return bool(evaluation.get("target_in_lane", false))


func _should_prepare_tidal_wave(target: Node2D) -> bool:
	if not tidal_wave_enabled:
		return false
	if not _is_special_meter_full():
		return false
	if _resolve_attack_target(target) == null:
		return false
	return _find_best_tidal_wave_heal_target(target) != null


func _apply_heal(target: Node2D = null, amount_multiplier: float = 1.0) -> bool:
	var heal_target := _resolve_heal_target(target, _should_allow_full_health_heal_targets())
	return _apply_heal_to_locked_target(heal_target, amount_multiplier)


func _apply_heal_to_locked_target(heal_target: Node2D, amount_multiplier: float = 1.0) -> bool:
	if heal_target == null:
		return false
	if not _is_valid_heal_target(heal_target):
		return false
	if not _is_in_basic_heal_range(heal_target):
		return false

	var final_heal_amount := maxf(0.0, heal_amount * maxf(0.0, amount_multiplier))
	if final_heal_amount <= 0.0:
		return false
	var weapon_data := _get_equipped_healer_weapon_data()
	var target_world := heal_target.global_position + Vector2(0.0, -16.0)
	var target_health_before := _get_target_current_health(heal_target)
	var healed := bool(heal_target.call("receive_heal", final_heal_amount))
	var target_health_after := _get_target_current_health(heal_target)
	var recovered_health := maxf(0.0, target_health_after - target_health_before)
	_spawn_heal_beam(global_position + Vector2(0.0, -18.0), target_world, healed)
	_spawn_heal_burst(target_world, healed)
	if recovered_health > 0.0:
		_spawn_heal_number_popup(target_world + Vector2(0.0, combat_number_popup_head_offset_y * 0.28), recovered_health)
	if healed:
		EnemyBase.add_healing_threat_to_active_enemies(self, final_heal_amount)
		add_special_meter_from_heal(final_heal_amount)
		var bolt_refund := maxf(0.0, float(weapon_data.get("bolt_cooldown_refund_on_heal", 0.0)))
		if bolt_refund > 0.0:
			light_bolt_cooldown_left = maxf(0.0, light_bolt_cooldown_left - bolt_refund)
		var chain_ratio := clampf(float(weapon_data.get("chain_heal_ratio", 0.0)), 0.0, 1.0)
		if chain_ratio > 0.0:
			_apply_chain_heal_from_target(heal_target, final_heal_amount * chain_ratio)
	return true


func _apply_chain_heal_from_target(primary_target: Node2D, chain_heal_amount: float) -> void:
	if chain_heal_amount <= 0.0:
		return
	var secondary_target := _find_chain_heal_target(primary_target)
	if secondary_target == null:
		return
	var source_position := primary_target.global_position + Vector2(0.0, -16.0)
	var secondary_position := secondary_target.global_position + Vector2(0.0, -16.0)
	var health_before := _get_target_current_health(secondary_target)
	var healed := bool(secondary_target.call("receive_heal", chain_heal_amount))
	var health_after := _get_target_current_health(secondary_target)
	var healed_amount := maxf(0.0, health_after - health_before)
	_spawn_heal_beam(source_position, secondary_position, true)
	_spawn_heal_burst(secondary_position, healed)
	if healed_amount > 0.0:
		_spawn_heal_number_popup(secondary_position + Vector2(0.0, combat_number_popup_head_offset_y * 0.22), healed_amount)
	if healed:
		EnemyBase.add_healing_threat_to_active_enemies(self, chain_heal_amount)
		add_special_meter_from_heal(chain_heal_amount)


func _find_chain_heal_target(excluded_target: Node2D) -> Node2D:
	var allow_full_health_targets := _should_allow_full_health_heal_targets()
	var best_target: Node2D = null
	var best_distance_sq := INF
	var max_range_sq := maxf(16.0, basic_heal_range * 1.25)
	max_range_sq *= max_range_sq
	var candidates: Array[Node2D] = []
	if is_instance_valid(player):
		candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate == self:
			candidates.append(candidate)
			continue
		if not _is_valid_support_target(candidate):
			continue
		candidates.append(candidate)
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		if excluded_target != null and is_instance_valid(excluded_target) and candidate.get_instance_id() == excluded_target.get_instance_id():
			continue
		if not _is_valid_heal_target(candidate):
			continue
		if not allow_full_health_targets and not _is_heal_target_injured(candidate):
			continue
		var distance_sq := candidate.global_position.distance_squared_to(global_position)
		if distance_sq > max_range_sq:
			continue
		if best_target == null or distance_sq < best_distance_sq:
			best_target = candidate
			best_distance_sq = distance_sq
	return best_target


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
	return true


func revive_at_full_health() -> void:
	dead = false
	is_rolling = false
	roll_invulnerable = false
	roll_time_left = 0.0
	roll_vector = Vector2.ZERO
	is_casting = false
	heal_applied_this_cast = false
	pending_cast_action = CastAction.NONE
	pending_cast_target = null
	current_health = maxf(1.0, max_health)
	special_meter = 0.0
	stun_left = 0.0
	hit_flash_left = 0.0
	heal_flash_left = 0.0
	knockback_velocity = Vector2.ZERO
	death_anim_time = 0.0
	death_cleanup_started = false
	marked_lunge_panic_left = 0.0
	marked_lunge_enemy_id = -1
	breath_threat_snapshot = {}
	breath_safe_indicator_left = 0.0
	big_heal_cooldown_left = 0.0
	harpoon_cooldown_left = 0.0
	_cancel_harpoon_state()
	_clear_tidal_waves()
	_setup_harpoon_visuals()
	if not is_instance_valid(health_bar_root):
		_setup_health_bar()
	if is_instance_valid(sprite):
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_set_anim_frame("idle", 0)
	_update_health_bar()
	health_changed.emit(current_health, max_health)


func receive_hit(amount: float, source_position: Vector2, _guard_break: bool = false, stun_duration: float = 0.0, knockback_scale: float = 1.0) -> bool:
	if dead:
		return false
	if roll_invulnerable:
		return false
	if amount <= 0.0:
		return false
	var final_amount := amount
	if is_casting:
		final_amount *= _get_cast_damage_multiplier_from_trinket()
	if is_instance_valid(player) and player.is_point_inside_block_shield(global_position):
		_spawn_heal_burst(global_position + Vector2(0.0, -14.0), true)
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	knockback_velocity = knockback_direction * maxf(0.0, hit_knockback_speed) * maxf(0.1, knockback_scale)
	stun_left = maxf(stun_left, maxf(hit_stun_duration, stun_duration))
	hit_flash_left = 0.12
	current_health = maxf(0.0, current_health - final_amount)
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	if is_casting and not _is_cast_uninterruptible_from_trinket():
		_cancel_current_cast(false)
	_spawn_heal_burst(global_position + Vector2(0.0, -14.0), false)
	if current_health <= 0.0:
		_die()
	return true


func _apply_light_bolt(target: Node2D) -> bool:
	var bolt_target := _resolve_attack_target(target)
	if bolt_target != null and _is_enemy_shadow_feared(bolt_target):
		return false
	if not _can_cast_light_bolt_on_target(bolt_target):
		return false
	var projectile_origin := global_position + Vector2(0.0, -16.0)
	var direction_sign := _resolve_light_bolt_direction_sign(bolt_target)
	if not _spawn_light_bolt_projectile(projectile_origin, direction_sign, bolt_target):
		return false
	_spawn_heal_burst(projectile_origin + Vector2(direction_sign * 6.0, 0.0), false)
	light_bolt_cooldown_left = maxf(0.0, light_bolt_cooldown)
	return true


func _resolve_light_bolt_direction_sign(target: EnemyBase) -> float:
	if target != null and is_instance_valid(target):
		var delta_x := target.global_position.x - global_position.x
		if absf(delta_x) > 2.0:
			return 1.0 if delta_x >= 0.0 else -1.0
	return -1.0 if facing_left else 1.0


func _face_target(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var delta_x := target.global_position.x - global_position.x
	if absf(delta_x) <= 2.0:
		return
	facing_left = delta_x < 0.0
	if is_instance_valid(sprite):
		sprite.flip_h = facing_left


func _spawn_light_bolt_projectile(spawn_position: Vector2, direction_sign: float, locked_target: EnemyBase) -> bool:
	if HEALER_LIGHT_BOLT_PROJECTILE_SCRIPT == null:
		return false
	var projectile := HEALER_LIGHT_BOLT_PROJECTILE_SCRIPT.new()
	if projectile == null:
		return false
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return false
	var lane_min_x := -INF
	var lane_max_x := INF
	var travel_distance := maxf(24.0, light_bolt_range)
	if is_instance_valid(player):
		var lane_space := player.get_parent() as Node2D
		if lane_space != null:
			lane_min_x = lane_space.to_global(Vector2(player.lane_min_x + arena_padding, 0.0)).x
			lane_max_x = lane_space.to_global(Vector2(player.lane_max_x - arena_padding, 0.0)).x
		else:
			lane_min_x = player.lane_min_x + arena_padding
			lane_max_x = player.lane_max_x - arena_padding
		if lane_min_x < lane_max_x:
			var lane_travel_distance := travel_distance
			if direction_sign >= 0.0:
				lane_travel_distance = maxf(8.0, lane_max_x - spawn_position.x)
			else:
				lane_travel_distance = maxf(8.0, spawn_position.x - lane_min_x)
			travel_distance = minf(travel_distance, lane_travel_distance)
	var projectile_lifetime := maxf(0.1, light_bolt_projectile_max_lifetime)
	if maxf(1.0, light_bolt_projectile_speed) > 0.0:
		projectile_lifetime = maxf(projectile_lifetime, (travel_distance / maxf(1.0, light_bolt_projectile_speed)) + 0.2)
	scene_root.add_child(projectile)
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			self,
			spawn_position,
			direction_sign,
			maxf(1.0, light_bolt_projectile_speed),
			maxf(24.0, travel_distance),
			maxf(0.1, light_bolt_damage),
			maxf(0.0, light_bolt_stun_duration),
			maxf(0.1, light_bolt_projectile_knockback_scale),
			maxf(0.0, light_bolt_hitstop_duration),
			maxf(6.0, light_bolt_projectile_hit_radius),
			projectile_lifetime,
			lane_min_x,
			lane_max_x,
			locked_target
		)
	if projectile.has_method("set_hitbox_debug_enabled"):
		projectile.call("set_hitbox_debug_enabled", hitbox_debug_enabled)
	return true


func _on_healer_light_bolt_projectile_hit(hit_enemy: EnemyBase, damage_dealt: float, hit_world_position: Vector2) -> void:
	if hit_enemy == null or not is_instance_valid(hit_enemy):
		return
	var impact_position := hit_world_position
	if impact_position == Vector2.ZERO:
		impact_position = hit_enemy.global_position + Vector2(0.0, -12.0)
	_spawn_heal_beam(global_position + Vector2(0.0, -16.0), impact_position, false)
	_spawn_heal_burst(impact_position, false)
	if damage_dealt > 0.0:
		_spawn_damage_number_popup(impact_position + Vector2(0.0, combat_number_popup_head_offset_y * 0.2), damage_dealt)
		add_special_meter_from_damage(damage_dealt)
	var weapon_data := _get_equipped_healer_weapon_data()
	var bolt_arc_ratio := clampf(float(weapon_data.get("bolt_arc_ratio", 0.0)), 0.0, 1.0)
	if bolt_arc_ratio > 0.0:
		_apply_light_bolt_arc(hit_enemy, light_bolt_damage * bolt_arc_ratio)


func _apply_light_bolt_arc(primary_target: EnemyBase, arc_damage: float) -> void:
	if primary_target == null or not is_instance_valid(primary_target) or primary_target.dead:
		return
	if arc_damage <= 0.0:
		return
	var secondary_target := _find_light_bolt_arc_target(primary_target)
	if secondary_target == null:
		return
	var start := primary_target.global_position + Vector2(0.0, -12.0)
	var end := secondary_target.global_position + Vector2(0.0, -12.0)
	var health_before := _get_target_current_health(secondary_target)
	_spawn_heal_beam(start, end, false)
	_spawn_heal_burst(end, false)
	var landed := secondary_target.receive_hit(
		arc_damage,
		global_position,
		light_bolt_stun_duration * 0.75,
		true,
		0.82,
		self
	)
	if not landed:
		return
	var health_after := _get_target_current_health(secondary_target)
	var damage_dealt := maxf(0.0, health_before - health_after)
	if damage_dealt > 0.0:
		_spawn_damage_number_popup(end + Vector2(0.0, combat_number_popup_head_offset_y * 0.2), damage_dealt)
	add_special_meter_from_damage(arc_damage)
	if secondary_target.has_method("apply_hitstop"):
		secondary_target.apply_hitstop(maxf(0.0, light_bolt_hitstop_duration * 0.7))


func _find_light_bolt_arc_target(primary_target: EnemyBase) -> EnemyBase:
	if primary_target == null or not is_instance_valid(primary_target):
		return null
	var best_target: EnemyBase = null
	var best_distance_sq := INF
	var max_arc_range_sq := 132.0 * 132.0
	var primary_id := primary_target.get_instance_id()
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if enemy.get_instance_id() == primary_id:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var distance_sq := enemy.global_position.distance_squared_to(primary_target.global_position)
		if distance_sq > max_arc_range_sq:
			continue
		if best_target == null or distance_sq < best_distance_sq:
			best_target = enemy
			best_distance_sq = distance_sq
	return best_target


func _trigger_healing_ability() -> void:
	var cast_target: Node2D = _as_valid_node2d_ref(pending_cast_target)
	_log_cast_event("RESOLVE", pending_cast_action, cast_target)
	match pending_cast_action:
		CastAction.QUICK_HEAL:
			if basic_heal_cooldown_left <= 0.0 and _apply_heal_to_locked_target(cast_target):
				basic_heal_cooldown_left = _get_quick_heal_cooldown_duration()
		CastAction.BIG_HEAL:
			if big_heal_cooldown_left <= 0.0 and _apply_heal_to_locked_target(cast_target, maxf(0.0, big_heal_amount_multiplier)):
				big_heal_cooldown_left = maxf(0.0, big_heal_cooldown)
		CastAction.TIDAL_WAVE:
			if tidal_wave_enabled and _is_special_meter_full():
				_consume_special_meter()
				_spawn_tidal_wave(cast_target)
				tidal_wave_cooldown_left = maxf(0.0, tidal_wave_cooldown)
		CastAction.LIGHT_BOLT:
			if light_bolt_enabled and light_bolt_cooldown_left <= 0.0:
				_apply_light_bolt(cast_target)
		_:
			pass
	pending_cast_action = CastAction.NONE
	pending_cast_target = null


func _is_healing_ability_ready() -> bool:
	if basic_heal_cooldown_left <= 0.0:
		return true
	if tidal_wave_enabled and _is_special_meter_full():
		return true
	if light_bolt_enabled and light_bolt_cooldown_left <= 0.0:
		return true
	return false


func _time_until_next_healing_ability_ready() -> float:
	var next_ready := maxf(0.0, basic_heal_cooldown_left)
	if tidal_wave_enabled and _is_special_meter_full():
		next_ready = minf(next_ready, maxf(0.0, tidal_wave_cooldown_left))
	if light_bolt_enabled:
		next_ready = minf(next_ready, maxf(0.0, light_bolt_cooldown_left))
	return maxf(0.0, next_ready)


func _update_facing() -> void:
	if not is_instance_valid(sprite):
		return
	if not is_instance_valid(player) and not manual_control_enabled:
		return
	var move_threshold := maxf(0.0, move_facing_threshold)
	if absf(move_velocity.x) >= move_threshold:
		facing_left = move_velocity.x < 0.0
	elif manual_control_enabled:
		var attack_target := _find_healer_attack_target()
		if attack_target != null and is_instance_valid(attack_target):
			var delta_x_to_target := attack_target.global_position.x - global_position.x
			var deadzone_manual := maxf(0.0, facing_flip_deadzone)
			if delta_x_to_target > deadzone_manual:
				facing_left = false
			elif delta_x_to_target < -deadzone_manual:
				facing_left = true
	else:
		var delta_x := player.position.x - position.x
		var deadzone := maxf(0.0, facing_flip_deadzone)
		if delta_x > deadzone:
			facing_left = false
		elif delta_x < -deadzone:
			facing_left = true
	sprite.flip_h = facing_left


func _quantize_player_like_direction(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	var normalized_direction := direction.normalized()
	var quant_steps := maxi(4, player_like_direction_steps)
	var step_angle := TAU / float(quant_steps)
	var snapped_angle: float = round(normalized_direction.angle() / step_angle) * step_angle
	return Vector2.RIGHT.rotated(snapped_angle)


func _should_quantize_player_like_move(enemy: EnemyBase) -> bool:
	if healer_ai_state == HealerAIState.BREATH_STACK:
		return true
	if healer_ai_state == HealerAIState.HEALING or healer_ai_state == HealerAIState.ATTACKING:
		return true
	return enemy != null and is_instance_valid(enemy)


func _update_tactical_positioning(delta: float) -> void:
	if not is_instance_valid(player):
		move_velocity = move_velocity.move_toward(Vector2.ZERO, movement_deceleration * delta)
		return
	if stun_left > 0.0:
		move_velocity = move_velocity.move_toward(Vector2.ZERO, movement_deceleration * delta)
		return
	if is_casting:
		move_velocity = Vector2.ZERO
		return
	orbit_phase = wrapf(orbit_phase + (delta * maxf(0.0, orbit_speed)), 0.0, TAU)

	var enemy := _find_primary_enemy()
	var desired_position := _compute_desired_position()
	if healer_ai_state == HealerAIState.BREATH_STACK and _is_breath_threat_active():
		var shared_parent := get_parent() as Node2D
		if bool(breath_threat_snapshot.get("safe_pocket_valid", false)):
			var cover_world_position := COMPANION_BREATH_RESPONSE_SCRIPT.compute_cover_position(breath_threat_snapshot, 0, 2)
			var cover_local_position := shared_parent.to_local(cover_world_position) if shared_parent != null else cover_world_position
			desired_position = _clamp_to_bounds(cover_local_position)
		else:
			var scatter_world_position := COMPANION_BREATH_RESPONSE_SCRIPT.compute_scatter_position(breath_threat_snapshot, global_position, 0)
			var scatter_local_position := shared_parent.to_local(scatter_world_position) if shared_parent != null else scatter_world_position
			desired_position = _clamp_to_bounds(scatter_local_position)
	elif healer_ai_state == HealerAIState.HEALING:
		var heal_target := _resolve_heal_target(healer_ai_target, false)
		var wave_attack_target := _find_healer_attack_target()
		if _should_prepare_tidal_wave(wave_attack_target):
			desired_position = _compute_tidal_wave_attack_position(wave_attack_target)
		else:
			desired_position = _compute_heal_approach_position(heal_target)
	elif healer_ai_state == HealerAIState.ATTACKING:
		var attack_target := _resolve_attack_target(healer_ai_target)
		if attack_target != null and is_instance_valid(attack_target):
			var attack_target_position := _get_position_in_actor_space(attack_target)
			var to_attack_target := attack_target_position - position
			var desired_attack_distance := clampf(maxf(40.0, light_bolt_range * 0.72), 40.0, maxf(56.0, light_bolt_range - 24.0))
			if to_attack_target.length() > desired_attack_distance:
				desired_position = _clamp_to_bounds(attack_target_position - (to_attack_target.normalized() * desired_attack_distance))
	healer_ai_desired_position = desired_position
	var effective_speed := move_speed * _get_healer_move_speed_multiplier()
	if is_casting:
		effective_speed *= clampf(cast_move_speed_multiplier, 0.0, 1.0)
	if healer_ai_state == HealerAIState.BREATH_STACK:
		effective_speed *= maxf(1.0, breath_stack_move_speed_multiplier)
	if use_player_like_movement:
		smoothed_target_position = healer_ai_desired_position
		var direct_to_target := healer_ai_desired_position - position
		var direct_distance := direct_to_target.length()
		var speed_cap := maxf(1.0, effective_speed)
		var stop_distance := maxf(0.0, move_deadzone)
		if healer_ai_state == HealerAIState.BREATH_STACK:
			stop_distance = minf(stop_distance, 2.0)
		var start_distance := stop_distance + maxf(2.0, speed_cap * clampf(player_like_move_deadzone_ratio, 0.0, 0.95) * 0.45)
		var moving_now := move_velocity.length_squared() > 0.0001
		var must_stop := direct_distance <= stop_distance
		var can_start := direct_distance > start_distance
		if must_stop or (not moving_now and not can_start):
			move_velocity = Vector2.ZERO
		else:
			var move_direction := direct_to_target.normalized() if direct_distance > 0.0001 else Vector2.ZERO
			if _should_quantize_player_like_move(enemy):
				move_direction = _quantize_player_like_direction(move_direction)
			if move_direction.length_squared() <= 0.0001:
				move_velocity = Vector2.ZERO
			else:
				move_velocity = move_direction * speed_cap
		position += move_velocity * delta
		position = _clamp_to_bounds(position)
		if pixel_snap_movement:
			position = position.round()
		return

	smoothed_target_position = smoothed_target_position.move_toward(healer_ai_desired_position, maxf(0.0, target_smoothing_speed) * delta)
	var to_target := smoothed_target_position - position
	var distance_to_target := to_target.length()
	var speed_scale := 1.0
	var slowdown := maxf(move_deadzone + 0.001, slow_down_radius)
	if distance_to_target < slowdown:
		speed_scale = clampf((distance_to_target - move_deadzone) / (slowdown - move_deadzone), 0.0, 1.0)
	var input_direction := Vector2.ZERO
	if distance_to_target > move_deadzone:
		input_direction = to_target / maxf(0.0001, distance_to_target)
	var desired_velocity := input_direction * (effective_speed * speed_scale)
	if healer_ai_state == HealerAIState.IDLE_SUPPORT and enemy != null and is_instance_valid(enemy):
		desired_velocity *= 0.9

	var steer_rate := movement_acceleration if desired_velocity.length_squared() >= move_velocity.length_squared() else movement_deceleration
	move_velocity = move_velocity.move_toward(desired_velocity, maxf(0.0, steer_rate) * delta)
	if desired_velocity == Vector2.ZERO:
		move_velocity = move_velocity.move_toward(Vector2.ZERO, maxf(0.0, movement_deceleration) * delta)
		if move_velocity.length_squared() <= 1.0:
			move_velocity = Vector2.ZERO

	position += move_velocity * delta
	position = _clamp_to_bounds(position)
	if pixel_snap_movement:
		position = position.round()


func _compute_desired_position() -> Vector2:
	if not is_instance_valid(player):
		return position
	var player_position := player.position
	var orbit_lateral := sin(orbit_phase) * maxf(0.0, orbit_lateral_distance)
	var orbit_depth := cos(orbit_phase * 0.9) * maxf(0.0, orbit_depth_distance)
	var enemy := _find_primary_enemy()
	var desired_side := _resolve_guard_side(player_position, enemy)
	var desired_offset := Vector2(desired_side * follow_distance, follow_vertical_bias)
	if enemy != null and is_instance_valid(enemy):
		var desired_follow_distance := clampf(follow_distance + (orbit_depth * 0.4), min_distance_to_player + 4.0, max_distance_to_player - 8.0)
		desired_offset = Vector2(
			(desired_side * desired_follow_distance) + orbit_lateral,
			follow_vertical_bias + (orbit_depth * follow_vertical_scale)
		)
	else:
		var follow_direction := player.facing_direction
		if player.velocity.length_squared() > 36.0:
			follow_direction = player.velocity.normalized()
		elif follow_direction.length_squared() > 0.0001:
			follow_direction = follow_direction.normalized()
		else:
			follow_direction = Vector2.RIGHT
		var lateral := Vector2(-follow_direction.y, follow_direction.x)
		var idle_follow_distance := clampf(follow_distance, min_distance_to_player + 8.0, max_distance_to_player - 6.0)
		desired_offset = (-follow_direction * idle_follow_distance) \
			+ (lateral * desired_side * maxf(8.0, orbit_lateral_distance * 0.8)) \
			+ Vector2(0.0, follow_vertical_bias)

	var target_position := player_position + desired_offset
	if enemy != null and is_instance_valid(enemy):
		var enemy_position_now := _get_position_in_actor_space(enemy)
		var enemy_side_now := signf(enemy_position_now.x - player_position.x)
		if absf(enemy_side_now) > 0.01:
			var target_side := signf(target_position.x - player_position.x)
			if absf(target_side) <= 0.01 or target_side == enemy_side_now:
				target_position.x = player_position.x - (enemy_side_now * (min_distance_to_player + 6.0))
	var player_to_target := target_position - player_position
	var target_distance := player_to_target.length()
	if target_distance < min_distance_to_player:
		var push_direction := player_to_target.normalized() if player_to_target.length_squared() > 0.0001 else Vector2.LEFT
		target_position = player_position + (push_direction * min_distance_to_player)
	elif target_distance > max_distance_to_player:
		var pull_direction := player_to_target.normalized() if player_to_target.length_squared() > 0.0001 else Vector2.LEFT
		target_position = player_position + (pull_direction * max_distance_to_player)

	return _clamp_to_bounds(target_position)


func _compute_heal_approach_position(heal_target: Node2D) -> Vector2:
	if heal_target == null or not is_instance_valid(heal_target):
		return _compute_desired_position()
	var target_position := _get_position_in_actor_space(heal_target)
	var desired_cast_distance := maxf(16.0, basic_heal_range - maxf(0.0, basic_heal_range_buffer))
	desired_cast_distance = minf(desired_cast_distance, maxf(20.0, basic_heal_range * 0.88))
	var to_target := target_position - position
	var distance_to_target := to_target.length()
	if distance_to_target > desired_cast_distance:
		var approach_direction := to_target / maxf(0.0001, distance_to_target)
		return _clamp_to_bounds(target_position - (approach_direction * desired_cast_distance))

	var enemy := _find_primary_enemy()
	var heal_side := -1.0
	if enemy != null and is_instance_valid(enemy):
		var enemy_position := _get_position_in_actor_space(enemy)
		heal_side = -signf(enemy_position.x - target_position.x)
	if absf(heal_side) <= 0.01 and is_instance_valid(player):
		heal_side = -signf(player.facing_direction.x)
	if absf(heal_side) <= 0.01:
		heal_side = -1.0

	# Hold a safer standoff while healing, but stay within cast range.
	var hold_distance := clampf(basic_heal_range * 0.72, 48.0, desired_cast_distance)
	var desired_position := target_position + Vector2(heal_side * hold_distance, follow_vertical_bias + 8.0)

	if enemy != null and is_instance_valid(enemy):
		var enemy_position := _get_position_in_actor_space(enemy)
		var from_enemy := desired_position - enemy_position
		var enemy_distance := from_enemy.length()
		var enemy_safe_distance := maxf(56.0, hold_distance)
		if enemy_distance < enemy_safe_distance:
			var safe_direction := from_enemy / maxf(0.0001, enemy_distance)
			if safe_direction.length_squared() <= 0.0001:
				safe_direction = Vector2(-heal_side, 0.0)
			desired_position = enemy_position + (safe_direction * enemy_safe_distance)
			var to_target_after_push := desired_position - target_position
			var target_distance_after_push := to_target_after_push.length()
			if target_distance_after_push > desired_cast_distance:
				desired_position = target_position + ((to_target_after_push / maxf(0.0001, target_distance_after_push)) * desired_cast_distance)

	return _clamp_to_bounds(desired_position)


func _resolve_guard_side(player_position: Vector2, enemy: EnemyBase) -> float:
	var fallback_side := desired_guard_side
	if absf(fallback_side) <= 0.01:
		fallback_side = -signf(player.facing_direction.x)
		if absf(fallback_side) <= 0.01:
			fallback_side = -1.0

	if enemy == null or not is_instance_valid(enemy):
		desired_guard_side = fallback_side
		return desired_guard_side

	var enemy_position := _get_position_in_actor_space(enemy)
	var enemy_delta_x := enemy_position.x - player_position.x
	var enemy_side := signf(enemy_delta_x)
	if absf(enemy_side) <= 0.01:
		desired_guard_side = fallback_side
		return desired_guard_side

	var desired_from_enemy := -enemy_side
	if desired_from_enemy == fallback_side or absf(enemy_delta_x) >= guard_side_swap_threshold:
		desired_guard_side = desired_from_enemy
	else:
		desired_guard_side = fallback_side
	return desired_guard_side


func _find_primary_enemy() -> EnemyBase:
	if not is_instance_valid(player):
		return null
	var nearest_minion: EnemyBase = null
	var nearest_minion_dist_sq := INF
	var nearest_minion_id := INF
	var nearest_boss: EnemyBase = null
	var nearest_boss_dist_sq := INF
	var nearest_boss_id := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var distance_sq := enemy.global_position.distance_squared_to(player.global_position)
		var enemy_id := enemy.get_instance_id()
		if enemy.is_miniboss:
			if nearest_boss == null or distance_sq < nearest_boss_dist_sq or (is_equal_approx(distance_sq, nearest_boss_dist_sq) and enemy_id < nearest_boss_id):
				nearest_boss = enemy
				nearest_boss_dist_sq = distance_sq
				nearest_boss_id = enemy_id
			continue
		if nearest_minion == null or distance_sq < nearest_minion_dist_sq or (is_equal_approx(distance_sq, nearest_minion_dist_sq) and enemy_id < nearest_minion_id):
			nearest_minion = enemy
			nearest_minion_dist_sq = distance_sq
			nearest_minion_id = enemy_id
	if nearest_minion != null:
		return nearest_minion
	return nearest_boss


func _clamp_to_bounds(local_position: Vector2) -> Vector2:
	if not is_instance_valid(player):
		return local_position
	var clamped := local_position
	clamped.x = clampf(clamped.x, player.lane_min_x + arena_padding, player.lane_max_x - arena_padding)
	clamped.y = clampf(clamped.y, player.lane_min_y + arena_padding, player.lane_max_y - arena_padding)
	return clamped


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
		var miniboss_position := _get_position_in_actor_space(miniboss)
		var to_self := position - miniboss_position
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
	position = _clamp_to_bounds(position + push_step)
	if pixel_snap_movement:
		position = position.round()


func _get_position_in_actor_space(node: Node2D) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2.ZERO
	var shared_parent := get_parent() as Node2D
	if shared_parent != null and node.get_parent() == shared_parent:
		return node.position
	if shared_parent == null:
		return node.global_position
	return shared_parent.to_local(node.global_position)


func _is_tactically_moving() -> bool:
	return move_velocity.length_squared() > 36.0


func get_ai_debug_state() -> String:
	return healer_ai_state_name


func get_ai_debug_target() -> String:
	if healer_ai_target == null or not is_instance_valid(healer_ai_target):
		return "-"
	return healer_ai_target.name


func _set_anim_frame(anim_name: String, frame_index: int) -> void:
	if not is_instance_valid(sprite):
		return
	var row := int(ANIM_ROWS.get(anim_name, 0))
	var anim_columns := _anim_columns(anim_name)
	if anim_columns.is_empty():
		return
	var clamped_frame := clampi(frame_index, 0, anim_columns.size() - 1)
	var source_column := int(anim_columns[clamped_frame])
	sprite.frame_coords = Vector2i(source_column, row)
	_apply_frame_alignment(row, source_column)


func _next_heal_interval() -> float:
	return maxf(0.9, heal_interval)


func _spawn_tidal_wave(target: Node2D = null) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var wave_direction := _get_tidal_wave_direction(target)

	var wave_node := Node2D.new()
	wave_node.top_level = true
	wave_node.global_position = global_position + Vector2(0.0, -14.0) + (wave_direction * 18.0)
	wave_node.rotation = 0.0
	wave_node.z_index = 236
	scene_root.add_child(wave_node)

	var height_scale := maxf(1.0, tidal_wave_visual_height_scale)
	var sprite_frames := _get_tidal_wave_sprite_frames()
	if sprite_frames.get_animation_names().is_empty():
		if is_instance_valid(wave_node):
			wave_node.queue_free()
		return
	var base_scale := Vector2(
		maxf(0.2, tidal_wave_sprite_scale.x) * (0.85 + ((height_scale - 1.0) * 0.55)),
		maxf(0.2, tidal_wave_sprite_scale.y) * (0.88 + ((height_scale - 1.0) * 0.68))
	)

	var wave_sprite := AnimatedSprite2D.new()
	wave_sprite.sprite_frames = sprite_frames
	wave_sprite.animation = "startup"
	wave_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wave_sprite.centered = true
	wave_sprite.position = Vector2(0.0, -2.0)
	wave_sprite.scale = base_scale
	wave_sprite.flip_h = wave_direction.x < 0.0
	wave_sprite.modulate = Color(0.92, 0.98, 1.0, 0.92)
	wave_node.add_child(wave_sprite)
	wave_sprite.play("startup")

	active_tidal_waves.append({
		"node": wave_node,
		"direction": wave_direction,
		"time_left": maxf(0.25, tidal_wave_duration),
		"travel_phase": 0.0,
		"height_scale": height_scale,
		"base_scale": base_scale,
		"sprite": wave_sprite,
		"startup_finished": false,
		"droplet_timer": 0.0,
		"healed_ids": {},
		"hit_ids": {}
	})


func _get_horizontal_facing_direction() -> Vector2:
	if is_instance_valid(sprite) and sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT


func _get_tidal_wave_direction(target: Node2D = null) -> Vector2:
	var attack_target := _resolve_attack_target(target)
	if attack_target != null and is_instance_valid(attack_target):
		var delta_x := attack_target.global_position.x - global_position.x
		if absf(delta_x) > 4.0:
			return Vector2.LEFT if delta_x < 0.0 else Vector2.RIGHT
	return _get_horizontal_facing_direction()


func _update_tidal_waves(delta: float) -> void:
	if active_tidal_waves.is_empty():
		return

	for wave_index in range(active_tidal_waves.size() - 1, -1, -1):
		var wave_state := active_tidal_waves[wave_index]
		var wave_node := wave_state.get("node") as Node2D
		if not is_instance_valid(wave_node):
			active_tidal_waves.remove_at(wave_index)
			continue

		var wave_direction := wave_state.get("direction", Vector2.RIGHT) as Vector2
		var time_left := maxf(0.0, float(wave_state.get("time_left", 0.0)) - delta)
		var travel_phase := float(wave_state.get("travel_phase", 0.0)) + delta
		var height_scale := float(wave_state.get("height_scale", 1.0))
		var base_scale: Vector2 = wave_state.get("base_scale", Vector2.ONE)
		var droplet_timer := maxf(0.0, float(wave_state.get("droplet_timer", 0.0)) - delta)
		var wave_sprite := wave_state.get("sprite") as AnimatedSprite2D
		var startup_finished := bool(wave_state.get("startup_finished", false))

		wave_node.global_position += wave_direction * tidal_wave_speed * delta
		var body_pulse := sin(travel_phase * 10.5)
		var ripple_x := 1.0 + (sin(travel_phase * 8.8) * 0.06)
		var ripple_y := 1.0 + (cos(travel_phase * 7.1) * 0.07)
		if is_instance_valid(wave_sprite):
			if not startup_finished and wave_sprite.animation == "startup" and wave_sprite.frame >= maxi(0, TIDAL_WAVE_STARTUP_FRAME_COUNT - 1):
				startup_finished = true
				wave_sprite.play("loop")
			wave_sprite.scale = Vector2(base_scale.x * ripple_x, base_scale.y * ripple_y)
			wave_sprite.modulate = Color(0.9 + (body_pulse * 0.03), 0.98, 1.0, 0.84 + ((body_pulse + 1.0) * 0.04))
		if time_left < 0.2:
			wave_node.modulate.a = clampf(time_left / 0.2, 0.0, 1.0)
		else:
			wave_node.modulate.a = 1.0

		if droplet_timer <= 0.0:
			var crest_position := wave_node.global_position + (wave_direction * 46.0)
			_spawn_tidal_wave_droplet(crest_position + Vector2(0.0, -8.0 * height_scale), wave_direction, height_scale * 1.08)
			_spawn_tidal_wave_droplet(crest_position + Vector2(-4.0 * wave_direction.x, 7.0 * height_scale), wave_direction, height_scale * 0.95)
			droplet_timer = maxf(0.03, tidal_wave_droplet_interval)

		_process_tidal_wave_hits(wave_state, wave_node.global_position, wave_direction)

		if time_left <= 0.0:
			_spawn_tidal_wave_end_effect(wave_node.global_position, base_scale, wave_direction)
			if is_instance_valid(wave_node):
				wave_node.queue_free()
			active_tidal_waves.remove_at(wave_index)
			continue

		wave_state["time_left"] = time_left
		wave_state["travel_phase"] = travel_phase
		wave_state["droplet_timer"] = droplet_timer
		wave_state["startup_finished"] = startup_finished
		active_tidal_waves[wave_index] = wave_state


func _get_tidal_wave_sprite_frames() -> SpriteFrames:
	if tidal_wave_sprite_frames != null:
		return tidal_wave_sprite_frames
	var startup_texture := _get_tidal_wave_startup_sheet_texture()
	var end_texture := _get_tidal_wave_end_sheet_texture()
	if startup_texture == null:
		return SpriteFrames.new()
	var frames := SpriteFrames.new()
	frames.add_animation("startup")
	frames.set_animation_speed("startup", 12.0)
	frames.set_animation_loop("startup", false)
	frames.add_animation("loop")
	frames.set_animation_speed("loop", 10.0)
	frames.set_animation_loop("loop", true)
	frames.add_animation("end")
	frames.set_animation_speed("end", 12.0)
	frames.set_animation_loop("end", false)
	var startup_frames := _build_tidal_wave_sheet_frames(startup_texture, TIDAL_WAVE_STARTUP_FRAME_COUNT)
	for frame_texture in startup_frames:
		frames.add_frame("startup", frame_texture)
	for loop_index in range(TIDAL_WAVE_LOOP_FRAME_START, mini(TIDAL_WAVE_LOOP_FRAME_END + 1, startup_frames.size())):
		frames.add_frame("loop", startup_frames[loop_index])
	if frames.get_frame_count("loop") <= 0:
		for frame_texture in startup_frames:
			frames.add_frame("loop", frame_texture)
	if end_texture != null:
		var end_frames := _build_tidal_wave_sheet_frames(end_texture, TIDAL_WAVE_END_FRAME_COUNT)
		for frame_texture in end_frames:
			frames.add_frame("end", frame_texture)
	tidal_wave_sprite_frames = frames
	return tidal_wave_sprite_frames


func _build_tidal_wave_sheet_frames(sheet_texture: Texture2D, max_frames: int) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	if sheet_texture == null:
		return frames
	var frame_width := maxi(1, TIDAL_WAVE_FRAME_SIZE.x)
	var frame_height := maxi(1, TIDAL_WAVE_FRAME_SIZE.y)
	var sheet_width := maxi(frame_width, sheet_texture.get_width())
	var sheet_height := maxi(frame_height, sheet_texture.get_height())
	var columns := maxi(1, sheet_width / frame_width)
	var rows := maxi(1, sheet_height / frame_height)
	var frames_added := 0
	for row in range(rows):
		for col in range(columns):
			if frames_added >= max_frames:
				return frames
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet_texture
			atlas.region = Rect2i(col * frame_width, row * frame_height, frame_width, frame_height)
			frames.append(atlas)
			frames_added += 1
	return frames


func _get_tidal_wave_startup_sheet_texture() -> Texture2D:
	if tidal_wave_startup_sheet_texture != null:
		return tidal_wave_startup_sheet_texture
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(TIDAL_WAVE_STARTUP_SHEET_PATH))
	if err != OK:
		push_warning("Failed to load tidal wave startup sprite sheet at %s (error %s)." % [TIDAL_WAVE_STARTUP_SHEET_PATH, err])
		return null
	tidal_wave_startup_sheet_texture = ImageTexture.create_from_image(image)
	return tidal_wave_startup_sheet_texture


func _get_tidal_wave_end_sheet_texture() -> Texture2D:
	if tidal_wave_end_sheet_texture != null:
		return tidal_wave_end_sheet_texture
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(TIDAL_WAVE_END_SHEET_PATH))
	if err != OK:
		push_warning("Failed to load tidal wave end sprite sheet at %s (error %s)." % [TIDAL_WAVE_END_SHEET_PATH, err])
		return null
	tidal_wave_end_sheet_texture = ImageTexture.create_from_image(image)
	return tidal_wave_end_sheet_texture


func _spawn_tidal_wave_end_effect(world_position: Vector2, base_scale: Vector2, wave_direction: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var sprite_frames := _get_tidal_wave_sprite_frames()
	if sprite_frames == null or not sprite_frames.has_animation("end") or sprite_frames.get_frame_count("end") <= 0:
		return
	var end_sprite := AnimatedSprite2D.new()
	end_sprite.top_level = true
	end_sprite.global_position = world_position
	end_sprite.rotation = 0.0
	end_sprite.z_index = 236
	end_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	end_sprite.centered = true
	end_sprite.sprite_frames = sprite_frames
	end_sprite.animation = "end"
	end_sprite.scale = base_scale
	end_sprite.flip_h = wave_direction.x < 0.0
	end_sprite.modulate = Color(0.92, 0.98, 1.0, 0.95)
	scene_root.add_child(end_sprite)
	end_sprite.play("end")
	var total_frames: int = maxi(1, sprite_frames.get_frame_count("end"))
	var lifetime := float(total_frames) / 12.0
	var cleanup := create_tween()
	cleanup.tween_interval(maxf(0.1, lifetime))
	cleanup.finished.connect(func() -> void:
		if is_instance_valid(end_sprite):
			end_sprite.queue_free()
	)


func _process_tidal_wave_hits(wave_state: Dictionary, wave_center: Vector2, wave_direction: Vector2) -> void:
	var sweep_start := wave_center - (wave_direction * (tidal_wave_hit_length * 0.3))
	var sweep_end := wave_center + (wave_direction * (tidal_wave_hit_length * 0.7))
	var healed_ids: Dictionary = wave_state.get("healed_ids", {}) as Dictionary
	var hit_ids: Dictionary = wave_state.get("hit_ids", {}) as Dictionary

	var friendly_targets: Array[Node2D] = []
	if is_instance_valid(player):
		friendly_targets.append(player)
	for friendly in get_tree().get_nodes_in_group("friendly_npcs"):
		var friendly_actor := friendly as Node2D
		if friendly_actor == null or not is_instance_valid(friendly_actor):
			continue
		if friendly_actor == self:
			friendly_targets.append(friendly_actor)
			continue
		if not _is_valid_support_target(friendly_actor):
			continue
		friendly_targets.append(friendly_actor)

	var seen_friendly_ids: Dictionary = {}
	for friendly_target in friendly_targets:
		if friendly_target == null or not is_instance_valid(friendly_target):
			continue
		var friendly_id := friendly_target.get_instance_id()
		if seen_friendly_ids.has(friendly_id):
			continue
		seen_friendly_ids[friendly_id] = true
		if healed_ids.has(friendly_id):
			continue
		var friendly_distance := _distance_to_segment(friendly_target.global_position, sweep_start, sweep_end)
		if friendly_distance > tidal_wave_hit_half_width:
			continue
		if not friendly_target.has_method("receive_heal"):
			continue
		var friendly_health_before := _get_target_current_health(friendly_target)
		var healed := bool(friendly_target.call("receive_heal", tidal_wave_heal_amount))
		var friendly_health_after := _get_target_current_health(friendly_target)
		var healed_amount := maxf(0.0, friendly_health_after - friendly_health_before)
		healed_ids[friendly_id] = true
		if healed:
			EnemyBase.add_healing_threat_to_active_enemies(self, tidal_wave_heal_amount)
			add_special_meter_from_heal(tidal_wave_heal_amount)
			var burst_position := friendly_target.global_position + Vector2(0.0, -16.0)
			_spawn_heal_burst(burst_position, true)
			_spawn_heal_beam(wave_center, burst_position, true)
			if healed_amount > 0.0:
				_spawn_heal_number_popup(burst_position + Vector2(0.0, combat_number_popup_head_offset_y * 0.2), healed_amount)

	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if hit_ids.has(enemy_id):
			continue
		var enemy_distance := _distance_to_segment(enemy.global_position, sweep_start, sweep_end)
		if enemy_distance > tidal_wave_hit_half_width:
			continue
		hit_ids[enemy_id] = true
		var enemy_health_before := _get_target_current_health(enemy)
		var landed := enemy.receive_hit(tidal_wave_damage, wave_center, tidal_wave_stun_duration, true, tidal_wave_knockback_scale, self)
		if landed:
			var enemy_health_after := _get_target_current_health(enemy)
			var damage_dealt := maxf(0.0, enemy_health_before - enemy_health_after)
			if damage_dealt > 0.0:
				_spawn_damage_number_popup(enemy.global_position + Vector2(0.0, combat_number_popup_head_offset_y), damage_dealt)
			add_special_meter_from_damage(tidal_wave_damage)
			if enemy.has_method("apply_hitstop"):
				enemy.apply_hitstop(maxf(0.0, tidal_wave_hitstop_duration))
			_spawn_heal_burst(enemy.global_position + Vector2(0.0, -12.0), false)

	wave_state["healed_ids"] = healed_ids
	wave_state["hit_ids"] = hit_ids


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return point.distance_to(segment_start)
	var segment_t := clampf((point - segment_start).dot(segment) / segment_length_sq, 0.0, 1.0)
	var closest_point := segment_start + (segment * segment_t)
	return point.distance_to(closest_point)


func _find_best_tidal_wave_heal_target(attack_target: Node2D = null) -> Node2D:
	var target_position := attack_target.global_position if attack_target != null and is_instance_valid(attack_target) else Vector2.ZERO
	var has_attack_target := attack_target != null and is_instance_valid(attack_target)
	var missing_health_threshold := maxf(0.01, min_missing_health_to_heal)
	var best_target: Node2D = null
	var best_lane_delta := INF
	var best_missing_health := -1.0
	var best_id := INF
	var candidates: Array[Node2D] = []
	if _is_valid_support_target(player):
		candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not _is_valid_support_target(candidate):
			continue
		candidates.append(candidate)
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not candidate.has_method("receive_heal"):
			continue
		var missing_health := _get_missing_health(candidate)
		if missing_health < missing_health_threshold:
			continue
		if _is_marked_target_waiting_for_damage(candidate):
			continue
		var lane_delta := 0.0
		if has_attack_target:
			lane_delta = absf(candidate.global_position.y - target_position.y)
		var candidate_id := candidate.get_instance_id()
		if best_target == null \
			or lane_delta < best_lane_delta - 0.0001 \
			or (is_equal_approx(lane_delta, best_lane_delta) and missing_health > best_missing_health + 0.0001) \
			or (is_equal_approx(lane_delta, best_lane_delta) and is_equal_approx(missing_health, best_missing_health) and candidate_id < best_id):
			best_target = candidate
			best_lane_delta = lane_delta
			best_missing_health = missing_health
			best_id = candidate_id
	return best_target


func _is_enemy_shadow_feared(target: EnemyBase) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("is_shadow_fear_active"):
		return false
	return bool(target.call("is_shadow_fear_active"))


func _evaluate_tidal_wave_targets(target: Node2D = null) -> Dictionary:
	var wave_direction := _get_tidal_wave_direction(target)
	var wave_origin := global_position + Vector2(0.0, -14.0) + (wave_direction * 18.0)
	var projected_distance := maxf(32.0, tidal_wave_speed * maxf(0.25, tidal_wave_duration))
	var sweep_start := wave_origin - (wave_direction * (tidal_wave_hit_length * 0.3))
	var sweep_end := wave_origin + (wave_direction * (projected_distance + (tidal_wave_hit_length * 0.7)))
	var ally_hits := 0
	var injured_allies := 0
	var enemy_hits := 0
	var target_in_lane := false
	var seen_friendly_ids: Dictionary = {}
	var ally_candidates: Array[Node2D] = []
	if _is_valid_support_target(player):
		ally_candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not _is_valid_support_target(candidate):
			continue
		ally_candidates.append(candidate)
	for ally in ally_candidates:
		if ally == null or not is_instance_valid(ally):
			continue
		var ally_id := ally.get_instance_id()
		if seen_friendly_ids.has(ally_id):
			continue
		seen_friendly_ids[ally_id] = true
		var ally_distance := _distance_to_segment(ally.global_position, sweep_start, sweep_end)
		if ally_distance > tidal_wave_hit_half_width:
			continue
		ally_hits += 1
		if ally.has_method("receive_heal") and _get_missing_health(ally) >= maxf(0.01, min_missing_health_to_heal):
			injured_allies += 1
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		var enemy_distance := _distance_to_segment(enemy.global_position, sweep_start, sweep_end)
		if enemy_distance > tidal_wave_hit_half_width:
			continue
		enemy_hits += 1
		if target != null and is_instance_valid(target) and enemy.get_instance_id() == target.get_instance_id():
			target_in_lane = true
	return {
		"ally_hits": ally_hits,
		"injured_allies": injured_allies,
		"enemy_hits": enemy_hits,
		"target_in_lane": target_in_lane,
		"direction": wave_direction
	}


func _compute_tidal_wave_attack_position(target: Node2D) -> Vector2:
	var attack_target := _resolve_attack_target(target)
	if attack_target == null:
		return _compute_desired_position()
	var target_position := _get_position_in_actor_space(attack_target)
	var wave_direction := _get_tidal_wave_direction(attack_target)
	var desired_standoff := clampf(maxf(56.0, light_bolt_range * 0.46), 56.0, maxf(84.0, light_bolt_range * 0.64))
	var desired_position := target_position - (wave_direction * desired_standoff)
	var heal_target := _find_best_tidal_wave_heal_target(attack_target)
	if heal_target != null and is_instance_valid(heal_target):
		var heal_target_position := _get_position_in_actor_space(heal_target)
		var lane_y := (target_position.y + heal_target_position.y) * 0.5
		if wave_direction.x >= 0.0:
			desired_position.x = minf(target_position.x, heal_target_position.x) - desired_standoff
		else:
			desired_position.x = maxf(target_position.x, heal_target_position.x) + desired_standoff
		desired_position.y = lane_y
	else:
		desired_position.y = target_position.y + clampf(follow_vertical_bias * 0.4, -8.0, 8.0)
	return _clamp_to_bounds(desired_position)


func _build_tidal_wave_body_points(height_scale: float, stretch: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	var safe_stretch := maxf(0.8, stretch)
	return PackedVector2Array([
		Vector2(-34.0 * safe_stretch, -22.0 * safe_height),
		Vector2(-6.0 * safe_stretch, -30.0 * safe_height),
		Vector2(24.0 * safe_stretch, -36.0 * safe_height),
		Vector2(50.0 * safe_stretch, -16.0 * safe_height),
		Vector2(62.0 * safe_stretch, 0.0),
		Vector2(50.0 * safe_stretch, 16.0 * safe_height),
		Vector2(24.0 * safe_stretch, 34.0 * safe_height),
		Vector2(-8.0 * safe_stretch, 28.0 * safe_height),
		Vector2(-34.0 * safe_stretch, 20.0 * safe_height),
		Vector2(-56.0 * safe_stretch, 0.0)
	])


func _build_tidal_wave_inner_points(height_scale: float, stretch: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	var safe_stretch := maxf(0.8, stretch)
	return PackedVector2Array([
		Vector2(-24.0 * safe_stretch, -14.0 * safe_height),
		Vector2(-2.0 * safe_stretch, -22.0 * safe_height),
		Vector2(20.0 * safe_stretch, -26.0 * safe_height),
		Vector2(36.0 * safe_stretch, -10.0 * safe_height),
		Vector2(42.0 * safe_stretch, 0.0),
		Vector2(34.0 * safe_stretch, 10.0 * safe_height),
		Vector2(18.0 * safe_stretch, 20.0 * safe_height),
		Vector2(-2.0 * safe_stretch, 16.0 * safe_height),
		Vector2(-22.0 * safe_stretch, 8.0 * safe_height),
		Vector2(-32.0 * safe_stretch, 0.0)
	])


func _build_tidal_wave_foam_points(height_scale: float, crest_shift: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	return PackedVector2Array([
		Vector2(-26.0, -12.0 * safe_height),
		Vector2(-6.0, -20.0 * safe_height + (crest_shift * 0.2)),
		Vector2(16.0, -27.0 * safe_height + (crest_shift * 0.45)),
		Vector2(36.0, -20.0 * safe_height + (crest_shift * 0.3)),
		Vector2(50.0, -8.0 * safe_height),
		Vector2(56.0, 0.0),
		Vector2(50.0, 8.0 * safe_height),
		Vector2(36.0, 20.0 * safe_height + (crest_shift * 0.15)),
		Vector2(16.0, 25.0 * safe_height),
		Vector2(-4.0, 18.0 * safe_height),
		Vector2(-24.0, 10.0 * safe_height)
	])


func _build_tidal_wave_rim_points(height_scale: float, crest_shift: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	return PackedVector2Array([
		Vector2(-10.0, -17.0 * safe_height),
		Vector2(10.0, -25.0 * safe_height + (crest_shift * 0.28)),
		Vector2(30.0, -28.0 * safe_height + (crest_shift * 0.48)),
		Vector2(48.0, -16.0 * safe_height + (crest_shift * 0.2)),
		Vector2(56.0, 0.0),
		Vector2(46.0, 14.0 * safe_height),
		Vector2(26.0, 22.0 * safe_height),
		Vector2(8.0, 18.0 * safe_height)
	])


func _build_tidal_wave_trail_points(height_scale: float, y_sign: float, shift: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	var safe_sign := -1.0 if y_sign < 0.0 else 1.0
	return PackedVector2Array([
		Vector2(-82.0, safe_sign * (15.0 * safe_height)),
		Vector2(-62.0, safe_sign * ((12.0 * safe_height) + (shift * 0.4))),
		Vector2(-42.0, safe_sign * ((10.0 * safe_height) + (shift * 0.28))),
		Vector2(-24.0, safe_sign * ((8.0 * safe_height) + (shift * 0.2))),
		Vector2(-10.0, safe_sign * ((6.0 * safe_height) + (shift * 0.12)))
	])


func _build_tidal_wave_mist_points(height_scale: float, shift: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	return PackedVector2Array([
		Vector2(-94.0, -10.0 * safe_height + (shift * 0.3)),
		Vector2(-74.0, -18.0 * safe_height + (shift * 0.45)),
		Vector2(-50.0, -16.0 * safe_height + (shift * 0.35)),
		Vector2(-22.0, -10.0 * safe_height + (shift * 0.2)),
		Vector2(-12.0, 0.0),
		Vector2(-24.0, 10.0 * safe_height - (shift * 0.2)),
		Vector2(-52.0, 16.0 * safe_height - (shift * 0.35)),
		Vector2(-78.0, 14.0 * safe_height - (shift * 0.45)),
		Vector2(-98.0, 6.0 * safe_height - (shift * 0.3))
	])


func _build_tidal_wave_glint_points(height_scale: float, crest_shift: float) -> PackedVector2Array:
	var safe_height := maxf(1.0, height_scale)
	return PackedVector2Array([
		Vector2(-4.0, -6.0 * safe_height),
		Vector2(14.0, -11.0 * safe_height + (crest_shift * 0.15)),
		Vector2(30.0, -13.0 * safe_height + (crest_shift * 0.24)),
		Vector2(40.0, -8.0 * safe_height + (crest_shift * 0.12))
	])


func _spawn_tidal_wave_droplet(world_position: Vector2, wave_direction: Vector2, height_scale: float) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var droplet := Polygon2D.new()
	droplet.top_level = true
	droplet.global_position = world_position + Vector2(
		rng.randf_range(-3.0, 3.0),
		rng.randf_range(-12.0, 12.0) * maxf(1.0, height_scale * 0.72)
	)
	droplet.z_index = 237
	var droplet_size := rng.randf_range(1.6, 3.3) * clampf(height_scale * 0.75, 0.75, 1.65)
	droplet.color = Color(0.74 + rng.randf_range(-0.04, 0.06), 0.96 + rng.randf_range(-0.02, 0.03), 1.0, 0.72 + rng.randf_range(-0.08, 0.08))
	droplet.polygon = PackedVector2Array([
		Vector2(0.0, -droplet_size),
		Vector2(droplet_size * 0.72, 0.0),
		Vector2(0.0, droplet_size),
		Vector2(-droplet_size * 0.72, 0.0)
	])
	scene_root.add_child(droplet)

	var drift := Vector2(
		wave_direction.x * rng.randf_range(18.0, 34.0),
		rng.randf_range(-18.0, 18.0) - (4.0 * signf(wave_direction.x))
	)
	var tween := create_tween()
	tween.tween_property(droplet, "global_position", droplet.global_position + drift, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(droplet, "scale", Vector2(0.35, 0.35), 0.22)
	tween.parallel().tween_property(droplet, "modulate:a", 0.0, 0.22)
	tween.finished.connect(func() -> void:
		if is_instance_valid(droplet):
			droplet.queue_free()
	)


func _clear_tidal_waves() -> void:
	for wave_state_variant in active_tidal_waves:
		var wave_state := wave_state_variant as Dictionary
		var wave_node := wave_state.get("node") as Node2D
		if is_instance_valid(wave_node):
			wave_node.queue_free()
	active_tidal_waves.clear()


func _die() -> void:
	if dead:
		return
	dead = true
	is_rolling = false
	roll_invulnerable = false
	roll_time_left = 0.0
	roll_vector = Vector2.ZERO
	_cancel_harpoon_state()
	is_casting = false
	stun_left = 0.0
	heal_flash_left = 0.0
	knockback_velocity = Vector2.ZERO
	death_anim_time = 0.0
	death_cleanup_started = false
	_set_anim_frame("death", 0)
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()
	health_bar_root = null
	health_bar_background = null
	health_bar_fill = null
	cast_bar_background = null
	cast_bar_fill = null
	_clear_tidal_waves()
	died.emit(self)


func _tick_death(delta: float) -> void:
	var fps := float(ANIM_FPS.get("death", 8.0))
	var frame_count := _anim_frame_count("death")
	death_anim_time += maxf(0.0, delta) * maxf(0.01, fps)
	var frame_index := mini(int(floor(death_anim_time)), frame_count - 1)
	_set_anim_frame("death", frame_index)
	if death_cleanup_started:
		_set_anim_frame("death", frame_count - 1)
		return
	if death_anim_time < float(frame_count):
		return
	death_cleanup_started = true
	death_anim_time = float(frame_count - 1)
	_set_anim_frame("death", frame_count - 1)


func _setup_health_bar() -> void:
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()
	health_bar_root = Node2D.new()
	health_bar_root.name = "HealerHealthBar"
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
	health_bar_fill.default_color = Color(0.28, 0.88, 0.98, 0.95)
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
	cast_bar_fill.default_color = Color(0.42, 0.74, 1.0, 0.95)
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
	special_bar_fill.default_color = Color(0.64, 0.94, 1.0, 0.95)
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
	if not is_casting:
		return -1.0
	var frame_count := float(_anim_frame_count("cast"))
	if frame_count <= 0.01:
		return 1.0
	return clampf(cast_anim_time / frame_count, 0.0, 1.0)


func _get_special_meter_ratio() -> float:
	return clampf(special_meter / maxf(1.0, special_meter_max), 0.0, 1.0)


func _is_special_meter_full() -> bool:
	return _get_special_meter_ratio() >= 0.999


func _add_special_meter(raw_amount: float) -> void:
	var amount := maxf(0.0, raw_amount)
	if amount <= 0.0:
		return
	special_meter = clampf(special_meter + amount, 0.0, maxf(1.0, special_meter_max))
	_update_health_bar()


func _consume_special_meter() -> void:
	special_meter = 0.0
	_update_health_bar()


func add_special_meter_from_damage(damage_amount: float) -> void:
	var gain_multiplier := _get_healer_special_meter_gain_multiplier()
	_add_special_meter(maxf(0.0, damage_amount) * maxf(0.0, special_meter_gain_per_damage) * gain_multiplier)


func add_special_meter_from_heal(heal_amount: float) -> void:
	var gain_multiplier := _get_healer_special_meter_gain_multiplier()
	_add_special_meter(maxf(0.0, heal_amount) * maxf(0.0, special_meter_gain_per_heal) * gain_multiplier)


func _can_start_harpoon_throw() -> bool:
	if not manual_control_enabled:
		return false
	if not harpoon_enabled:
		return false
	if dead or stun_left > 0.0:
		return false
	if is_casting:
		return false
	if harpoon_cooldown_left > 0.0:
		return false
	if harpoon_charge_active or harpoon_projectile_active or harpoon_reel_active:
		return false
	return true


func _try_start_harpoon_charge() -> bool:
	if not _can_start_harpoon_throw():
		return false
	harpoon_charge_active = true
	harpoon_charge_time = 0.0
	harpoon_charge_ratio = 0.0
	harpoon_throw_direction_sign = -1.0 if facing_left else 1.0
	harpoon_reel_charge_ratio = 0.0
	harpoon_projectile_active = false
	harpoon_reel_active = false
	harpoon_hooked_target = null
	return true


func _tick_harpoon_state(delta: float) -> void:
	if harpoon_charge_active:
		if not manual_control_enabled or is_casting:
			_cancel_harpoon_state()
			return
		if Input.is_action_pressed("ability_1"):
			harpoon_charge_time = minf(maxf(0.01, harpoon_max_charge_time), harpoon_charge_time + maxf(0.0, delta))
			harpoon_charge_ratio = _get_harpoon_charge_ratio_from_time(harpoon_charge_time)
		else:
			_release_harpoon_throw()
	if harpoon_projectile_active:
		_advance_harpoon_projectile(delta)
	if harpoon_reel_active:
		_tick_harpoon_reel(delta)


func _release_harpoon_throw() -> void:
	if not harpoon_charge_active:
		return
	harpoon_charge_active = false
	_hide_harpoon_charge_telegraph()
	harpoon_charge_ratio = _get_harpoon_charge_ratio_from_time(harpoon_charge_time)
	harpoon_reel_charge_ratio = harpoon_charge_ratio
	harpoon_throw_direction_sign = -1.0 if facing_left else 1.0
	var throw_origin := _get_harpoon_origin_global()
	harpoon_projectile_active = true
	harpoon_projectile_position = throw_origin
	harpoon_projectile_travel_left = lerpf(maxf(24.0, harpoon_min_range), maxf(harpoon_min_range, harpoon_max_range), harpoon_charge_ratio)
	harpoon_projectile_speed = lerpf(maxf(80.0, harpoon_min_projectile_speed), maxf(harpoon_min_projectile_speed, harpoon_max_projectile_speed), harpoon_charge_ratio)
	harpoon_cooldown_left = maxf(harpoon_cooldown_left, maxf(0.05, harpoon_cooldown * _get_healer_harpoon_cooldown_multiplier()))
	_spawn_heal_burst(throw_origin, false)


func _advance_harpoon_projectile(delta: float) -> void:
	if not harpoon_projectile_active:
		return
	var step_distance := harpoon_projectile_speed * maxf(0.0, delta)
	if step_distance <= 0.0:
		return
	var travel_step := minf(step_distance, harpoon_projectile_travel_left)
	var previous_position := harpoon_projectile_position
	harpoon_projectile_position.x += harpoon_throw_direction_sign * travel_step
	harpoon_projectile_travel_left = maxf(0.0, harpoon_projectile_travel_left - travel_step)
	var hit_target := _find_harpoon_first_target(previous_position, harpoon_projectile_position, harpoon_throw_direction_sign)
	if hit_target != null and is_instance_valid(hit_target):
		var hit_is_enemy := hit_target is EnemyBase
		var hit_is_heavy := false
		if hit_is_enemy:
			hit_is_heavy = _is_harpoon_heavy_enemy(hit_target as EnemyBase)
		harpoon_projectile_active = false
		_spawn_heal_burst(hit_target.global_position + Vector2(0.0, -12.0), false)
		_begin_harpoon_reel(hit_target, hit_is_enemy, hit_is_heavy)
		return
	if harpoon_projectile_travel_left <= 0.0:
		harpoon_projectile_active = false
		_spawn_heal_burst(harpoon_projectile_position + Vector2(0.0, -3.0), false)


func _begin_harpoon_reel(target: Node2D, target_is_enemy: bool, target_is_heavy: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	harpoon_hooked_target = target
	harpoon_hooked_target_is_enemy = target_is_enemy
	harpoon_hooked_target_is_heavy = target_is_heavy
	_cache_harpoon_hooked_target_properties(target)
	harpoon_reel_active = true
	harpoon_reel_speed = lerpf(maxf(80.0, harpoon_min_reel_speed), maxf(harpoon_min_reel_speed, harpoon_max_reel_speed), harpoon_reel_charge_ratio)
	harpoon_reel_speed *= _get_healer_harpoon_reel_speed_multiplier()
	if not target_is_enemy:
		harpoon_reel_speed *= maxf(0.1, harpoon_ally_reel_speed_multiplier)
	var destination := _get_harpoon_reel_destination(target.global_position)
	var travel_distance := target.global_position.distance_to(destination)
	var estimated_reel_time := travel_distance / maxf(1.0, harpoon_reel_speed)
	harpoon_reel_left = clampf(estimated_reel_time + 0.2, 0.2, maxf(0.2, harpoon_reel_max_duration))


func _tick_harpoon_reel(delta: float) -> void:
	if not harpoon_reel_active:
		return
	if harpoon_hooked_target == null or not is_instance_valid(harpoon_hooked_target):
		_cancel_harpoon_state()
		return
	harpoon_reel_left = maxf(0.0, harpoon_reel_left - maxf(0.0, delta))
	var target_position := harpoon_hooked_target.global_position
	var destination := _get_harpoon_reel_destination(target_position)
	var max_step := harpoon_reel_speed * maxf(0.0, delta)
	target_position = target_position.move_toward(destination, max_step)
	_apply_harpoon_reel_target_position(harpoon_hooked_target, target_position, delta)
	if target_position.distance_to(destination) <= 2.0:
		_finalize_harpoon_reel(true)
		return
	if harpoon_reel_left <= 0.0:
		target_position = destination
		_apply_harpoon_reel_target_position(harpoon_hooked_target, target_position, delta)
		_finalize_harpoon_reel(true)


func _finalize_harpoon_reel(arrived: bool) -> void:
	if harpoon_hooked_target != null and is_instance_valid(harpoon_hooked_target) and arrived:
		if harpoon_hooked_target_is_enemy:
			if harpoon_hooked_target_is_heavy:
				_apply_harpoon_heavy_tug_effect(harpoon_hooked_target as EnemyBase)
			else:
				_apply_harpoon_enemy_arrival_effect(harpoon_hooked_target as EnemyBase)
		else:
			_apply_harpoon_ally_arrival_effect(harpoon_hooked_target)
	_cancel_harpoon_state()


func _cancel_harpoon_state() -> void:
	var was_harpoon_charging := harpoon_charge_active
	harpoon_charge_active = false
	harpoon_charge_time = 0.0
	harpoon_charge_ratio = 0.0
	harpoon_projectile_active = false
	harpoon_projectile_travel_left = 0.0
	harpoon_reel_active = false
	harpoon_reel_left = 0.0
	harpoon_hooked_target = null
	harpoon_hooked_target_is_enemy = false
	harpoon_hooked_target_is_heavy = false
	harpoon_hooked_has_velocity = false
	harpoon_hooked_has_move_velocity = false
	harpoon_hooked_has_knockback_velocity = false
	harpoon_hooked_has_stun_left = false
	if is_instance_valid(harpoon_tether_line):
		harpoon_tether_line.visible = false
	if is_instance_valid(harpoon_tether_glow_line):
		harpoon_tether_glow_line.visible = false
	if is_instance_valid(harpoon_projectile_visual):
		harpoon_projectile_visual.visible = false
	if was_harpoon_charging:
		_hide_harpoon_charge_telegraph()


func _find_harpoon_first_target(from_position: Vector2, to_position: Vector2, direction_sign: float) -> Node2D:
	var best_target: Node2D = null
	var best_progress := INF
	var segment_min_x := minf(from_position.x, to_position.x)
	var segment_max_x := maxf(from_position.x, to_position.x)
	for candidate in _collect_harpoon_targets():
		if not _is_valid_harpoon_target(candidate):
			continue
		var radius := _get_harpoon_target_radius(candidate)
		var max_distance := maxf(4.0, harpoon_projectile_hit_radius) + radius
		var candidate_position := candidate.global_position
		if candidate_position.x < segment_min_x - max_distance or candidate_position.x > segment_max_x + max_distance:
			continue
		if absf(candidate_position.y - from_position.y) > max_distance:
			continue
		var forward_progress := (candidate_position.x - from_position.x) * direction_sign
		if forward_progress < -max_distance:
			continue
		var closest_x := clampf(candidate_position.x, segment_min_x, segment_max_x)
		var delta := candidate_position - Vector2(closest_x, from_position.y)
		if delta.length_squared() > max_distance * max_distance:
			continue
		if forward_progress < best_progress:
			best_progress = forward_progress
			best_target = candidate
	return best_target


func _collect_harpoon_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	var seen_ids: Dictionary = {}
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy_target := node as Node2D
		if enemy_target == null:
			continue
		var enemy_id := enemy_target.get_instance_id()
		if seen_ids.has(enemy_id):
			continue
		seen_ids[enemy_id] = true
		targets.append(enemy_target)
	if is_instance_valid(player):
		var player_id := player.get_instance_id()
		seen_ids[player_id] = true
		targets.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var friendly_target := node as Node2D
		if friendly_target == null:
			continue
		var ally_id := friendly_target.get_instance_id()
		if seen_ids.has(ally_id):
			continue
		seen_ids[ally_id] = true
		targets.append(friendly_target)
	return targets


func _is_valid_harpoon_target(candidate: Node2D) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false
	if candidate == self:
		return false
	if candidate is EnemyBase:
		return not (candidate as EnemyBase).dead
	if candidate is Player:
		var player_candidate := candidate as Player
		return not player_candidate.is_dead
	if candidate is FriendlyHealer:
		return not (candidate as FriendlyHealer).dead
	if candidate is FriendlyRatfolk:
		return not (candidate as FriendlyRatfolk).dead
	if candidate is FriendlyLizardfolk:
		return not (candidate as FriendlyLizardfolk).dead
	return false


func _get_harpoon_target_radius(candidate: Node2D) -> float:
	if candidate is EnemyBase:
		var enemy := candidate as EnemyBase
		if enemy.collision_shape == null or enemy.collision_shape.shape == null:
			return 14.0
		var enemy_shape := enemy.collision_shape.shape
		if enemy_shape is CircleShape2D:
			return maxf(6.0, (enemy_shape as CircleShape2D).radius)
		if enemy_shape is CapsuleShape2D:
			var enemy_capsule := enemy_shape as CapsuleShape2D
			return maxf(6.0, enemy_capsule.radius + (enemy_capsule.height * 0.25))
		if enemy_shape is RectangleShape2D:
			var enemy_rectangle := enemy_shape as RectangleShape2D
			return maxf(6.0, maxf(enemy_rectangle.size.x, enemy_rectangle.size.y) * 0.5)
		return 14.0
	var collision_node := candidate.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_node == null or collision_node.shape == null:
		return 14.0
	var shape := collision_node.shape
	if shape is CircleShape2D:
		return maxf(6.0, (shape as CircleShape2D).radius)
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return maxf(6.0, capsule.radius + (capsule.height * 0.25))
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		return maxf(6.0, maxf(rectangle.size.x, rectangle.size.y) * 0.5)
	return 14.0


func _is_harpoon_heavy_enemy(enemy: EnemyBase) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if enemy.is_miniboss:
		return true
	return enemy.monster_visual_profile in [
		EnemyBase.MonsterVisualProfile.MINOTAUR,
		EnemyBase.MonsterVisualProfile.CACODEMON,
		EnemyBase.MonsterVisualProfile.SHARDSOUL
	]


func _get_harpoon_reel_destination_x(current_target_x: float) -> float:
	var healer_radius := _get_healer_harpoon_collision_radius()
	var target_radius := _get_harpoon_target_radius(harpoon_hooked_target) if (harpoon_hooked_target != null and is_instance_valid(harpoon_hooked_target)) else 14.0
	var contact_gap := maxf(0.0, harpoon_stop_distance)
	var contact_scale := clampf(harpoon_contact_distance_scale, 0.35, 1.0)
	var stop_distance := maxf(6.0, (healer_radius + target_radius) * contact_scale + contact_gap)
	return global_position.x + (harpoon_throw_direction_sign * stop_distance)


func _get_harpoon_reel_destination(current_target_position: Vector2) -> Vector2:
	var destination_x := _get_harpoon_reel_destination_x(current_target_position.x)
	return Vector2(destination_x, global_position.y)


func _get_healer_harpoon_collision_radius() -> float:
	if collision_shape == null or not is_instance_valid(collision_shape) or collision_shape.shape == null:
		return 14.0
	var shape := collision_shape.shape
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
		return maxf(6.0, circle.radius * maxf(0.01, radius_scale))
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return maxf(6.0, capsule.radius + (capsule.height * 0.25))
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		return maxf(6.0, maxf(rectangle.size.x, rectangle.size.y) * 0.5)
	return 14.0


func _apply_harpoon_enemy_arrival_effect(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	var final_damage := maxf(0.0, harpoon_enemy_damage) * lerpf(0.9, 1.35, harpoon_reel_charge_ratio)
	var final_stagger := maxf(0.0, harpoon_arrival_stagger_duration) * lerpf(0.9, 1.3, harpoon_reel_charge_ratio)
	var to_healer := (global_position - enemy.global_position).normalized()
	if to_healer == Vector2.ZERO:
		to_healer = Vector2.LEFT if harpoon_throw_direction_sign >= 0.0 else Vector2.RIGHT
	var inward_knock_source := enemy.global_position - (to_healer * 12.0)
	var enemy_health_before := _get_target_current_health(enemy)
	var landed := enemy.receive_hit(final_damage, inward_knock_source, final_stagger, true, 0.1, self)
	if landed:
		var enemy_health_after := _get_target_current_health(enemy)
		var damage_dealt := maxf(0.0, enemy_health_before - enemy_health_after)
		if damage_dealt > 0.0:
			_spawn_damage_number_popup(enemy.global_position + Vector2(0.0, combat_number_popup_head_offset_y), damage_dealt)
		add_special_meter_from_damage(final_damage)
		_apply_echo_prism_harpoon_pulse(enemy.global_position)
		if _is_equipped_healer_trinket("echo_prism"):
			var trinket_data := _get_equipped_healer_trinket_data()
			var refund := maxf(0.0, float(trinket_data.get("harpoon_refund", 0.0)))
			if refund > 0.0:
				harpoon_cooldown_left = maxf(0.0, harpoon_cooldown_left - refund)
	_spawn_heal_burst(enemy.global_position + Vector2(0.0, -12.0), false)


func _apply_harpoon_heavy_tug_effect(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	if enemy.has_method("apply_hitstop"):
		enemy.call("apply_hitstop", 0.09)
	_set_node_float_max(enemy, "stun_left", maxf(0.0, harpoon_arrival_stagger_duration) * 0.35)
	_spawn_heal_burst(enemy.global_position + Vector2(0.0, -12.0), false)


func _apply_harpoon_ally_arrival_effect(ally_target: Node2D) -> void:
	if ally_target == null or not is_instance_valid(ally_target):
		return
	_set_node_float(ally_target, "stun_left", 0.0)
	_set_node_vector(ally_target, "knockback_velocity", Vector2.ZERO)
	_spawn_heal_burst(ally_target.global_position + Vector2(0.0, -14.0), true)


func _apply_echo_prism_harpoon_pulse(pulse_origin: Vector2) -> void:
	if not _is_equipped_healer_trinket("echo_prism"):
		return
	var trinket_data := _get_equipped_healer_trinket_data()
	var pulse_radius := maxf(24.0, float(trinket_data.get("harpoon_pulse_radius", 96.0)))
	var pulse_heal := maxf(0.0, float(trinket_data.get("harpoon_pulse_heal", 6.0)))
	if pulse_heal <= 0.0:
		return
	var pulse_radius_sq := pulse_radius * pulse_radius
	var candidates: Array[Node2D] = []
	if _is_valid_support_target(player):
		candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not _is_valid_support_target(candidate):
			continue
		candidates.append(candidate)
	var seen_ids: Dictionary = {}
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		var candidate_id := candidate.get_instance_id()
		if seen_ids.has(candidate_id):
			continue
		seen_ids[candidate_id] = true
		if candidate.global_position.distance_squared_to(pulse_origin) > pulse_radius_sq:
			continue
		if not candidate.has_method("receive_heal"):
			continue
		var health_before := _get_target_current_health(candidate)
		var healed := bool(candidate.call("receive_heal", pulse_heal))
		var health_after := _get_target_current_health(candidate)
		var healed_amount := maxf(0.0, health_after - health_before)
		var burst_position := candidate.global_position + Vector2(0.0, -14.0)
		_spawn_heal_burst(burst_position, healed)
		_spawn_heal_beam(pulse_origin + Vector2(0.0, -10.0), burst_position, true)
		if healed_amount > 0.0:
			_spawn_heal_number_popup(burst_position + Vector2(0.0, combat_number_popup_head_offset_y * 0.2), healed_amount)
		if healed:
			EnemyBase.add_healing_threat_to_active_enemies(self, pulse_heal)
			add_special_meter_from_heal(pulse_heal)


func _cache_harpoon_hooked_target_properties(target: Node2D) -> void:
	harpoon_hooked_has_velocity = false
	harpoon_hooked_has_move_velocity = false
	harpoon_hooked_has_knockback_velocity = false
	harpoon_hooked_has_stun_left = false
	if target == null or not is_instance_valid(target):
		return
	harpoon_hooked_has_velocity = _object_has_property(target, "velocity")
	harpoon_hooked_has_move_velocity = _object_has_property(target, "move_velocity")
	harpoon_hooked_has_knockback_velocity = _object_has_property(target, "knockback_velocity")
	harpoon_hooked_has_stun_left = _object_has_property(target, "stun_left")


func _apply_harpoon_reel_target_position(target: Node2D, reel_position: Vector2, delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if harpoon_hooked_target_is_enemy:
		if harpoon_hooked_has_velocity:
			target.set("velocity", Vector2.ZERO)
		if harpoon_hooked_has_move_velocity:
			target.set("move_velocity", Vector2.ZERO)
		if harpoon_hooked_has_knockback_velocity:
			target.set("knockback_velocity", Vector2.ZERO)
		var reel_stun := maxf(0.05, maxf(0.0, delta) + 0.02)
		if harpoon_hooked_target_is_heavy:
			reel_stun = minf(reel_stun, 0.06)
		if harpoon_hooked_has_stun_left:
			var current_stun := float(target.get("stun_left"))
			if reel_stun > current_stun:
				target.set("stun_left", reel_stun)
	else:
		if harpoon_hooked_has_knockback_velocity:
			target.set("knockback_velocity", Vector2.ZERO)
	if target.global_position.distance_squared_to(reel_position) > 0.0001:
		target.global_position = reel_position


func _object_has_property(target: Object, property_name: String) -> bool:
	for property_info in target.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false


func _set_node_float_max(target: Object, property_name: String, value: float) -> void:
	if target == null or property_name.is_empty():
		return
	if not _object_has_property(target, property_name):
		return
	var current_value := float(target.get(property_name))
	target.set(property_name, maxf(current_value, value))


func _set_node_vector(target: Object, property_name: String, value: Vector2) -> void:
	if target == null or property_name.is_empty():
		return
	if not _object_has_property(target, property_name):
		return
	target.set(property_name, value)


func _set_node_float(target: Object, property_name: String, value: float) -> void:
	if target == null or property_name.is_empty():
		return
	if not _object_has_property(target, property_name):
		return
	target.set(property_name, value)


func _get_harpoon_charge_ratio_from_time(charge_time_value: float) -> float:
	var clamped_time := clampf(charge_time_value, 0.0, maxf(0.01, harpoon_max_charge_time))
	var min_time := maxf(0.0, harpoon_min_charge_time)
	var normalized := 0.0
	if clamped_time <= min_time:
		normalized = 0.0
	else:
		normalized = (clamped_time - min_time) / maxf(0.01, harpoon_max_charge_time - min_time)
	return clampf(normalized, 0.0, 1.0)


func _get_harpoon_origin_global() -> Vector2:
	return global_position + Vector2(24.0 * harpoon_throw_direction_sign, -16.0)


func _update_harpoon_visuals() -> void:
	if (harpoon_tether_line == null or not is_instance_valid(harpoon_tether_line)) \
		or (harpoon_tether_glow_line == null or not is_instance_valid(harpoon_tether_glow_line)) \
		or (harpoon_projectile_visual == null or not is_instance_valid(harpoon_projectile_visual)):
		_setup_harpoon_visuals()
	if harpoon_tether_line == null or harpoon_tether_glow_line == null or harpoon_projectile_visual == null:
		return
	var origin := _get_harpoon_origin_global()
	if harpoon_charge_active:
		var preview_ratio := _get_harpoon_charge_ratio_from_time(harpoon_charge_time)
		var preview_distance := lerpf(maxf(24.0, harpoon_min_range), maxf(harpoon_min_range, harpoon_max_range), preview_ratio)
		var charge_progress := clampf(harpoon_charge_time / maxf(0.01, harpoon_max_charge_time), 0.0, 1.0)
		var telegraph_length := lerpf(20.0, preview_distance, charge_progress)
		var preview_tip := origin + Vector2(preview_distance * harpoon_throw_direction_sign, 0.0)
		_show_harpoon_charge_telegraph(telegraph_length)
		_set_harpoon_tether_visual(
			origin,
			preview_tip,
			4.2,
			Color(0.12, 0.34, 0.44, 0.94),
			Color(0.68, 0.98, 1.0, lerpf(0.44, 0.94, preview_ratio)),
			lerpf(0.4, 2.0, preview_ratio)
		)
		harpoon_projectile_visual.visible = true
		harpoon_projectile_visual.global_position = preview_tip
		harpoon_projectile_visual.rotation = (0.0 if harpoon_throw_direction_sign >= 0.0 else PI) + (sin(Time.get_ticks_msec() * 0.016) * 0.06)
		harpoon_projectile_visual.scale = Vector2.ONE * lerpf(0.82, 1.28, preview_ratio)
		return
	if harpoon_projectile_active:
		_set_harpoon_tether_visual(
			origin,
			harpoon_projectile_position,
			4.8,
			Color(0.1, 0.32, 0.42, 0.94),
			Color(0.66, 0.98, 1.0, 0.96),
			1.2
		)
		harpoon_projectile_visual.visible = true
		harpoon_projectile_visual.global_position = harpoon_projectile_position
		harpoon_projectile_visual.rotation = (0.0 if harpoon_throw_direction_sign >= 0.0 else PI) + (sin(Time.get_ticks_msec() * 0.022) * 0.08)
		harpoon_projectile_visual.scale = Vector2.ONE * lerpf(0.9, 1.26, harpoon_charge_ratio)
		return
	if harpoon_reel_active and harpoon_hooked_target != null and is_instance_valid(harpoon_hooked_target):
		var target_position := harpoon_hooked_target.global_position + Vector2(0.0, -8.0)
		_set_harpoon_tether_visual(
			origin,
			target_position,
			5.2,
			Color(0.1, 0.34, 0.44, 0.96),
			Color(0.76, 0.99, 1.0, 0.98),
			1.6
		)
		var reel_sign := 1.0 if target_position.x >= origin.x else -1.0
		harpoon_projectile_visual.visible = true
		harpoon_projectile_visual.global_position = target_position
		harpoon_projectile_visual.rotation = (0.0 if reel_sign >= 0.0 else PI) + (sin(Time.get_ticks_msec() * 0.02) * 0.05)
		harpoon_projectile_visual.scale = Vector2.ONE * 1.08
		return
	if is_instance_valid(harpoon_charge_telegraph):
		harpoon_charge_telegraph.visible = false
	harpoon_tether_line.visible = false
	harpoon_tether_glow_line.visible = false
	harpoon_projectile_visual.visible = false


func _set_harpoon_tether_visual(
	origin: Vector2,
	tip: Vector2,
	core_width: float,
	core_color: Color,
	glow_color: Color,
	wave_strength: float
) -> void:
	var points := _build_harpoon_tether_points(origin, tip, wave_strength)
	harpoon_tether_line.visible = true
	harpoon_tether_line.width = core_width
	harpoon_tether_line.default_color = core_color
	harpoon_tether_line.points = points
	harpoon_tether_glow_line.visible = true
	harpoon_tether_glow_line.width = maxf(1.6, core_width * 0.45)
	harpoon_tether_glow_line.default_color = glow_color
	harpoon_tether_glow_line.points = points


func _build_harpoon_tether_points(origin: Vector2, tip: Vector2, wave_strength: float) -> PackedVector2Array:
	var desired_segments := int(round(origin.distance_to(tip) / 24.0))
	var segment_count := clampi(desired_segments, 8, 24)
	var points := PackedVector2Array()
	var span := tip - origin
	var span_length := maxf(1.0, span.length())
	var direction := span / span_length
	var normal := Vector2(-direction.y, direction.x)
	var time_wave := float(Time.get_ticks_msec()) * 0.001
	for i in range(segment_count + 1):
		var t := float(i) / float(segment_count)
		var falloff := 1.0 - absf((t * 2.0) - 1.0)
		var sway := sin((t * PI * 4.0) + (time_wave * 17.0)) * wave_strength * falloff
		points.append(to_local(origin.lerp(tip, t) + (normal * sway)))
	return points


func _show_harpoon_charge_telegraph(telegraph_length: float) -> void:
	if harpoon_charge_telegraph == null or not is_instance_valid(harpoon_charge_telegraph):
		return
	harpoon_charge_telegraph.visible = true
	harpoon_charge_telegraph.color = Color(0.4, 0.82, 1.0, 0.34)
	harpoon_charge_telegraph.polygon = _build_harpoon_arrow_polygon(telegraph_length)
	harpoon_charge_telegraph.position = Vector2(24.0 * harpoon_throw_direction_sign, -16.0)
	harpoon_charge_telegraph.rotation = 0.0 if harpoon_throw_direction_sign >= 0.0 else PI
	harpoon_charge_telegraph.modulate.a = 0.25
	harpoon_charge_telegraph.scale = Vector2.ONE


func _hide_harpoon_charge_telegraph() -> void:
	if harpoon_charge_telegraph == null or not is_instance_valid(harpoon_charge_telegraph):
		return
	harpoon_charge_telegraph.visible = false
	harpoon_charge_telegraph.position = Vector2.ZERO
	harpoon_charge_telegraph.scale = Vector2.ONE
	harpoon_charge_telegraph.modulate.a = 1.0


func _build_harpoon_arrow_polygon(arrow_length: float) -> PackedVector2Array:
	var body_length := maxf(18.0, arrow_length)
	var head_length := clampf(body_length * 0.24, 14.0, 28.0)
	var half_width := clampf(body_length * 0.045, 3.4, 7.0)
	var tail_x := 0.0
	var body_end_x := body_length - head_length
	var tip_x := body_length
	return PackedVector2Array([
		Vector2(tail_x, -half_width * 0.62),
		Vector2(body_end_x, -half_width * 0.62),
		Vector2(body_end_x, -half_width * 1.35),
		Vector2(tip_x, 0.0),
		Vector2(body_end_x, half_width * 1.35),
		Vector2(body_end_x, half_width * 0.62),
		Vector2(tail_x, half_width * 0.62)
	])


func _setup_harpoon_visuals() -> void:
	if harpoon_charge_telegraph == null or not is_instance_valid(harpoon_charge_telegraph):
		var telegraph := Polygon2D.new()
		telegraph.name = "HarpoonChargeTelegraph"
		telegraph.visible = false
		telegraph.z_index = 228
		telegraph.color = Color(0.4, 0.82, 1.0, 0.34)
		add_child(telegraph)
		harpoon_charge_telegraph = telegraph
	if harpoon_tether_line == null or not is_instance_valid(harpoon_tether_line):
		var tether := Line2D.new()
		tether.name = "HarpoonTether"
		tether.default_color = Color(0.1, 0.34, 0.44, 0.94)
		tether.width = 4.6
		tether.begin_cap_mode = Line2D.LINE_CAP_ROUND
		tether.end_cap_mode = Line2D.LINE_CAP_ROUND
		tether.visible = false
		tether.z_index = 230
		add_child(tether)
		harpoon_tether_line = tether
	if harpoon_tether_glow_line == null or not is_instance_valid(harpoon_tether_glow_line):
		var tether_glow := Line2D.new()
		tether_glow.name = "HarpoonTetherGlow"
		tether_glow.default_color = Color(0.76, 0.98, 1.0, 0.88)
		tether_glow.width = 2.0
		tether_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
		tether_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
		tether_glow.visible = false
		tether_glow.z_index = 231
		add_child(tether_glow)
		harpoon_tether_glow_line = tether_glow
	if harpoon_projectile_visual == null or not is_instance_valid(harpoon_projectile_visual):
		var hook_root := Node2D.new()
		hook_root.name = "HarpoonProjectile"
		hook_root.visible = false
		hook_root.z_index = 232
		var hook_body := Polygon2D.new()
		hook_body.color = Color(0.14, 0.46, 0.56, 0.96)
		hook_body.polygon = PackedVector2Array([
			Vector2(13.0, 0.0),
			Vector2(4.0, -3.2),
			Vector2(-4.0, -3.2),
			Vector2(-10.0, 0.0),
			Vector2(-4.0, 3.2),
			Vector2(4.0, 3.2)
		])
		hook_root.add_child(hook_body)
		var hook_highlight := Polygon2D.new()
		hook_highlight.color = Color(0.78, 1.0, 1.0, 0.94)
		hook_highlight.polygon = PackedVector2Array([
			Vector2(13.0, 0.0),
			Vector2(4.0, -2.4),
			Vector2(-4.0, -2.4),
			Vector2(-9.0, 0.0),
			Vector2(-4.0, 2.4),
			Vector2(4.0, 2.4)
		])
		hook_root.add_child(hook_highlight)
		add_child(hook_root)
		harpoon_projectile_visual = hook_root


func _teardown_harpoon_visuals() -> void:
	if harpoon_charge_telegraph != null and is_instance_valid(harpoon_charge_telegraph):
		harpoon_charge_telegraph.queue_free()
	if harpoon_tether_line != null and is_instance_valid(harpoon_tether_line):
		harpoon_tether_line.queue_free()
	if harpoon_tether_glow_line != null and is_instance_valid(harpoon_tether_glow_line):
		harpoon_tether_glow_line.queue_free()
	if harpoon_projectile_visual != null and is_instance_valid(harpoon_projectile_visual):
		harpoon_projectile_visual.queue_free()
	harpoon_charge_telegraph = null
	harpoon_tether_line = null
	harpoon_tether_glow_line = null
	harpoon_projectile_visual = null


func _setup_heal_range_indicator() -> void:
	if heal_range_indicator != null and is_instance_valid(heal_range_indicator):
		return
	var ring := Line2D.new()
	ring.name = "HealRangeIndicator"
	ring.width = maxf(0.5, heal_range_indicator_width)
	ring.default_color = Color(0.42, 0.78, 1.0, clampf(heal_range_indicator_alpha, 0.0, 0.35))
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.joint_mode = Line2D.LINE_JOINT_ROUND
	ring.closed = true
	ring.z_as_relative = true
	ring.z_index = -5
	ring.visible = false
	add_child(ring)
	heal_range_indicator = ring
	_rebuild_heal_range_indicator_points()


func _rebuild_heal_range_indicator_points() -> void:
	if heal_range_indicator == null or not is_instance_valid(heal_range_indicator):
		return
	var radius := maxf(8.0, basic_heal_range * maxf(0.1, heal_range_indicator_radius_scale))
	var segment_count := maxi(16, heal_range_indicator_segments)
	var points := PackedVector2Array()
	for i in range(segment_count):
		var ratio := float(i) / float(segment_count)
		var angle := TAU * ratio
		var point := Vector2(cos(angle), sin(angle)) * radius
		point.y += heal_range_indicator_y_offset
		points.append(point)
	heal_range_indicator.points = points


func _update_heal_range_indicator() -> void:
	if heal_range_indicator == null or not is_instance_valid(heal_range_indicator):
		return
	var should_show := heal_range_indicator_enabled and manual_control_enabled and not dead
	heal_range_indicator.visible = should_show
	if not should_show:
		return
	heal_range_indicator.default_color = Color(0.42, 0.78, 1.0, clampf(heal_range_indicator_alpha, 0.0, 0.35))


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


func _anim_columns(anim_name: String) -> Array:
	var values: Array = ANIM_FRAME_COLUMNS.get(anim_name, [])
	return values


func _anim_frame_count(anim_name: String) -> int:
	var values := _anim_columns(anim_name)
	return maxi(1, values.size())


func _prepare_frame_alignment() -> void:
	frame_anchor_points.clear()
	if HEALER_SHEET == null:
		return
	var image := HEALER_SHEET.get_image()
	if image == null:
		return

	var frame_w := image.get_width() / HEALER_HFRAMES
	var frame_h := image.get_height() / HEALER_VFRAMES
	frame_pixel_size = Vector2(frame_w, frame_h)

	var idle_row := int(ANIM_ROWS.get("idle", 0))
	var idle_columns := _anim_columns("idle")
	var idle_reference_col := int(idle_columns[0]) if not idle_columns.is_empty() else 0
	var reference_anchor := _extract_frame_foot_anchor(image, idle_row, idle_reference_col, frame_w, frame_h)
	if reference_anchor == INVALID_FRAME_ANCHOR:
		reference_anchor = Vector2(float(frame_w) * 0.5, float(frame_h - 1))
	alignment_anchor_point = reference_anchor

	for anim_name_variant in ANIM_ROWS.keys():
		var anim_name := String(anim_name_variant)
		var row := int(ANIM_ROWS.get(anim_name, 0))
		var columns := _anim_columns(anim_name)
		for source_col_variant in columns:
			var source_col := int(source_col_variant)
			var frame_anchor := _extract_frame_foot_anchor(image, row, source_col, frame_w, frame_h)
			if frame_anchor == INVALID_FRAME_ANCHOR:
				frame_anchor = alignment_anchor_point
			frame_anchor_points[_frame_key(row, source_col)] = frame_anchor


func _frame_key(row: int, col: int) -> int:
	return (row << 8) | col


func _extract_frame_foot_anchor(image: Image, row: int, col: int, frame_w: int, frame_h: int) -> Vector2:
	if frame_w <= 0 or frame_h <= 0:
		return INVALID_FRAME_ANCHOR
	var start_x := col * frame_w
	var start_y := row * frame_h
	if start_x < 0 or start_y < 0:
		return INVALID_FRAME_ANCHOR
	if start_x + frame_w > image.get_width():
		return INVALID_FRAME_ANCHOR
	if start_y + frame_h > image.get_height():
		return INVALID_FRAME_ANCHOR

	for local_y in range(frame_h - 1, -1, -1):
		var pixel_y := start_y + local_y
		var foot_x_sum := 0.0
		var foot_count := 0
		for local_x in range(frame_w):
			var pixel_x := start_x + local_x
			if image.get_pixel(pixel_x, pixel_y).a <= FRAME_ALPHA_THRESHOLD:
				continue
			foot_x_sum += float(local_x)
			foot_count += 1
		if foot_count > 0:
			return Vector2(foot_x_sum / float(foot_count), float(local_y))
	return INVALID_FRAME_ANCHOR


func _apply_frame_alignment(row: int, col: int) -> void:
	if not is_instance_valid(sprite):
		return
	if frame_anchor_points.is_empty():
		sprite.position = sprite_base_position
		return

	var frame_anchor: Vector2 = alignment_anchor_point
	var key := _frame_key(row, col)
	if frame_anchor_points.has(key):
		frame_anchor = frame_anchor_points[key]

	var aligned_foot_x := frame_anchor.x
	if sprite.flip_h:
		aligned_foot_x = (frame_pixel_size.x - 1.0) - aligned_foot_x
	var delta_pixels := Vector2(alignment_anchor_point.x - aligned_foot_x, alignment_anchor_point.y - frame_anchor.y)
	var sprite_scale := Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
	sprite.position = (sprite_base_position + Vector2(delta_pixels.x * sprite_scale.x, delta_pixels.y * sprite_scale.y)).round()


func _spawn_damage_number_popup(world_position: Vector2, damage_amount: float) -> void:
	_spawn_combat_number_popup(
		world_position,
		damage_amount,
		Color(1.0, 0.88, 0.34, 0.98),
		Color(0.08, 0.05, 0.02, 0.95)
	)


func _spawn_heal_number_popup(world_position: Vector2, heal_amount: float) -> void:
	if not _should_show_heal_number_popups():
		return
	_spawn_combat_number_popup(
		world_position,
		heal_amount,
		Color(0.44, 1.0, 0.56, 0.98),
		Color(0.04, 0.12, 0.04, 0.95),
		"+"
	)


func _should_show_heal_number_popups() -> bool:
	return manual_control_enabled


func _spawn_combat_number_popup(
	world_position: Vector2,
	amount: float,
	text_color: Color,
	outline_color: Color,
	prefix: String = ""
) -> void:
	if not combat_number_popups_enabled:
		return
	if amount <= 0.0:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return

	var label := Label.new()
	label.top_level = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.global_position = world_position
	label.z_index = 262
	label.text = "%s%d" % [prefix, int(round(amount))]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.scale = Vector2.ONE * maxf(0.1, combat_number_popup_scale)

	var label_settings := LabelSettings.new()
	label_settings.font_size = maxi(8, combat_number_popup_font_size)
	label_settings.font_color = text_color
	label_settings.outline_size = maxi(0, combat_number_popup_outline_size)
	label_settings.outline_color = outline_color
	label.label_settings = label_settings
	scene_root.add_child(label)

	combat_number_popup_sequence += 1
	var spread_step := float((combat_number_popup_sequence % 5) - 2)
	var x_offset := spread_step * maxf(0.0, combat_number_popup_x_spread)
	var rise := maxf(6.0, combat_number_popup_rise_distance)
	var duration := maxf(0.06, combat_number_popup_duration)

	var tween := create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(x_offset, -rise), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)


func _spawn_cast_flash(world_position: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var flash := Polygon2D.new()
	flash.top_level = true
	flash.global_position = world_position
	flash.z_index = 235
	flash.color = Color(0.54, 0.9, 1.0, 0.9)
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(5.0, 0.0),
		Vector2(0.0, 10.0),
		Vector2(-5.0, 0.0)
	])
	scene_root.add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector2(1.7, 1.7), heal_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, heal_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)


func _spawn_heal_beam(from_world: Vector2, to_world: Vector2, healed: bool) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var beam := Line2D.new()
	beam.top_level = true
	beam.global_position = Vector2.ZERO
	beam.z_index = 236
	beam.default_color = Color(0.44, 0.98, 0.62, 0.86) if healed else Color(0.62, 0.74, 0.8, 0.72)
	beam.width = 3.0
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam.points = PackedVector2Array([from_world, to_world])
	scene_root.add_child(beam)

	var tween := create_tween()
	tween.tween_property(beam, "width", 0.9, heal_effect_duration)
	tween.parallel().tween_property(beam, "modulate:a", 0.0, heal_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
	)


func _spawn_heal_burst(world_position: Vector2, healed: bool) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var burst := Node2D.new()
	burst.top_level = true
	burst.global_position = world_position
	burst.z_index = 237
	scene_root.add_child(burst)

	var ring := Line2D.new()
	ring.default_color = Color(0.42, 1.0, 0.56, 0.92) if healed else Color(0.54, 0.68, 0.78, 0.85)
	ring.width = 2.4
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.points = _build_ring_points(11.0, 16)
	burst.add_child(ring)

	var vertical := Line2D.new()
	vertical.default_color = ring.default_color.lightened(0.16)
	vertical.width = 2.2
	vertical.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vertical.end_cap_mode = Line2D.LINE_CAP_ROUND
	vertical.points = PackedVector2Array([Vector2(0.0, -5.0), Vector2(0.0, 5.0)])
	burst.add_child(vertical)

	var horizontal := Line2D.new()
	horizontal.default_color = ring.default_color.lightened(0.16)
	horizontal.width = 2.2
	horizontal.begin_cap_mode = Line2D.LINE_CAP_ROUND
	horizontal.end_cap_mode = Line2D.LINE_CAP_ROUND
	horizontal.points = PackedVector2Array([Vector2(-5.0, 0.0), Vector2(5.0, 0.0)])
	burst.add_child(horizontal)

	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2(1.65, 1.65), heal_effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, heal_effect_duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


func _build_ring_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(maxi(3, segments)):
		var angle := (TAU * float(i)) / float(maxi(3, segments))
		points.append(Vector2.RIGHT.rotated(angle) * radius)
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
	_draw_healer_hurtbox_debug()
	_draw_healer_cast_hitbox_debug()


func _draw_healer_hurtbox_debug() -> void:
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


func _draw_healer_cast_hitbox_debug() -> void:
	if pending_cast_action == CastAction.LIGHT_BOLT:
		var bolt_target := _resolve_attack_target(pending_cast_target)
		if bolt_target != null and is_instance_valid(bolt_target):
			var from_point := Vector2.ZERO
			var to_point := to_local(bolt_target.global_position)
			draw_line(from_point, to_point, Color(1.0, 0.92, 0.44, 0.92), 2.0, true)
			draw_circle(to_point, 7.0, Color(1.0, 0.92, 0.44, 0.18))
			draw_arc(to_point, 7.0, 0.0, TAU, 20, Color(1.0, 0.96, 0.62, 0.94), 1.6, true)
	if pending_cast_action == CastAction.TIDAL_WAVE and pending_cast_target != null and is_instance_valid(pending_cast_target):
		var wave_direction := _get_tidal_wave_direction(pending_cast_target)
		var sweep_start := Vector2.ZERO - (wave_direction * (tidal_wave_hit_length * 0.3))
		var sweep_end := Vector2.ZERO + (wave_direction * (tidal_wave_hit_length * 0.7))
		var half_width := maxf(6.0, tidal_wave_hit_half_width)
		draw_line(sweep_start, sweep_end, Color(0.42, 0.9, 1.0, 0.16), half_width * 2.0, true)
		draw_arc(sweep_start, half_width, 0.0, TAU, 24, Color(0.56, 0.94, 1.0, 0.88), 1.8, true)
		draw_arc(sweep_end, half_width, 0.0, TAU, 24, Color(0.56, 0.94, 1.0, 0.88), 1.8, true)


func _is_autoplay_requested() -> bool:
	var autoplay_raw := OS.get_environment("AUTOPLAY_TEST").strip_edges().to_lower()
	if not autoplay_raw.is_empty() and autoplay_raw not in ["0", "false", "off", "no"]:
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false


func _is_env_flag_enabled(env_key: String) -> bool:
	var raw := OS.get_environment(env_key).strip_edges().to_lower()
	return not raw.is_empty() and raw not in ["0", "false", "off", "no"]


func _cast_action_name(action: CastAction) -> String:
	match action:
		CastAction.QUICK_HEAL:
			return "QUICK_HEAL"
		CastAction.BIG_HEAL:
			return "BIG_HEAL"
		CastAction.TIDAL_WAVE:
			return "TIDAL_WAVE"
		CastAction.LIGHT_BOLT:
			return "LIGHT_BOLT"
		_:
			return "NONE"


func _as_valid_node2d_ref(candidate: Variant) -> Node2D:
	if candidate == null:
		return null
	if not is_instance_valid(candidate):
		return null
	return candidate as Node2D


func _log_cast_event(prefix: String, action: CastAction, target: Variant) -> void:
	if not cast_debug_logging_enabled:
		return
	var resolved_target: Node2D = _as_valid_node2d_ref(target)
	var target_name := "None"
	var current := 0.0
	var maximum := 0.0
	var missing := 0.0
	var marked_blocked := false
	if resolved_target != null:
		target_name = resolved_target.name
		maximum = maxf(1.0, float(resolved_target.get("max_health")))
		current = clampf(float(resolved_target.get("current_health")), 0.0, maximum)
		missing = maxf(0.0, maximum - current)
		marked_blocked = _is_marked_target_waiting_for_damage(resolved_target)
	print("[HEALER_CAST] %s action=%s target=%s hp=%.2f/%.2f missing=%.2f marked_blocked=%s state=%s" % [
		prefix,
		_cast_action_name(action),
		target_name,
		current,
		maximum,
		missing,
		str(marked_blocked),
		healer_ai_state_name
	])

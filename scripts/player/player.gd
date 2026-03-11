extends CharacterBody2D
class_name Player

const SWORD_DEFINITIONS := preload("res://scripts/systems/sword_definitions.gd")
const SHIELD_DEFINITIONS := preload("res://scripts/systems/shield_definitions.gd")

enum QueuedAttack {
	NONE,
	BASIC,
	ABILITY_1,
	COUNTER_STRIKE
}

enum CombatState {
	IDLE_MOVE,
	CHARGING_ATTACK,
	ATTACK_WINDUP,
	ATTACK_ACTIVE,
	ATTACK_RECOVERY,
	HITSTUN
}

signal health_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal cooldowns_changed(values: Dictionary)
signal died
signal item_looted(item_name: String, total_owned: int)
signal equipped_sword_changed(sword_id: String, sword_name: String)
signal equipped_shield_changed(shield_id: String, shield_name: String)
signal combat_status_message(text: String, duration: float)

# Pacing experiment knobs (slow-RPG cadence).
@export var move_speed: float = 82.9
@export var max_health: float = 60.0
@export var basic_attack_damage: float = 15.0
@export var basic_attack_range: float = 62.0
@export var basic_attack_arc_degrees: float = 90.0
@export var basic_attack_cooldown: float = 1.35
@export var basic_attack_input_buffer_window: float = 0.15
@export var basic_attack_cadence_debug_logging: bool = false
@export var sword_combat_debug_logging: bool = true
@export var basic_attack_windup: float = 0.2
@export var basic_combo_chain_window: float = 0.42
@export var basic_combo_end_cooldown: float = 0.8

@export var ability_1_damage: float = 30.0
@export var ability_1_range: float = 84.0
@export var ability_1_arc_degrees: float = 140.0
@export var ability_1_cooldown: float = 4.5
@export var ability_1_windup: float = 0.14
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

@export var ability_2_damage: float = 40.0
@export var ability_2_range: float = 88.0
@export var ability_2_arc_degrees: float = 60.0
@export var ability_2_cooldown: float = 6.75
@export var ability_2_lunge_speed: float = 460.0
@export var ability_2_lunge_duration: float = 0.22
@export var ability_2_arrive_distance: float = 16.0
@export var ability_2_min_dash_distance: float = 10.0
@export var ability_2_min_duration: float = 0.08
@export_range(-1.0, 1.0, 0.05) var ability_2_facing_dot_threshold: float = 0.2
@export var ability_2_instant_block_grace: float = 0.26
@export var guardian_dash_mark_priority_scale: float = 0.78
@export var guardian_dash_lunge_priority_scale: float = 0.68

@export var roll_speed: float = 210.0
@export var roll_duration: float = 0.24
@export var roll_cooldown: float = 1.0

@export var block_arc_degrees: float = 120.0
@export var block_damage_reduction: float = 0.65
@export var block_move_multiplier: float = 0.45
@export var block_stamina_max: float = 100.0
@export var block_stamina_hold_drain_per_second: float = 7.5
@export var block_stamina_recharge_per_second: float = 13.0
@export var block_stamina_blocked_hit_cost: float = 24.0
@export var block_stamina_min_to_raise: float = 5.0
@export var block_stamina_recover_threshold_ratio: float = 0.5
@export var block_input_grace_duration: float = 0.12
@export var perfect_block_window: float = 0.24
@export var counter_strike_unlock_duration: float = 4.0
@export var counter_strike_startup: float = 0.12
@export var counter_strike_recovery: float = 0.22
@export var counter_strike_damage: float = 34.0
@export var counter_strike_range: float = 74.0
@export var counter_strike_arc_degrees: float = 80.0
@export var counter_strike_enemy_stun: float = 0.72
@export var counter_strike_knockback_scale: float = 1.65
@export var counter_strike_hitstop: float = 0.11
@export var counter_strike_vfx_scale: float = 1.45
@export var counter_strike_anim_duration: float = 0.21
@export var counter_strike_anim_strength: float = 1.75
@export var depth_speed_multiplier: float = 0.62
@export var lane_min_x: float = -760.0
@export var lane_max_x: float = 760.0
@export var lane_min_y: float = -165.0
@export var lane_max_y: float = 165.0
@export var miniboss_soft_collision_enabled: bool = false
@export var miniboss_soft_collision_radius: float = 64.0
@export var miniboss_soft_collision_push_speed: float = 285.0
@export var miniboss_soft_collision_max_push_per_frame: float = 6.0
@export var attack_depth_tolerance: float = 44.0
@export var hit_stun_duration: float = 0.24
@export var outgoing_hit_stun_duration: float = 0.2
@export var hit_effect_duration: float = 0.14
@export var heal_flash_duration: float = 0.16
@export var hit_knockback_speed: float = 250.0
@export var hit_knockback_decay: float = 1300.0
@export var blocked_knockback_move_scale: float = 0.6
@export var block_shield_radius: float = 57.6
@export var block_shield_forward_offset: float = 24.0
@export var block_shield_half_width_scale: float = 0.78
@export var block_shield_half_height_scale: float = 1.14
@export var block_shield_y_offset: float = -10.0
@export var block_shield_line_width: float = 6.0
@export var block_shield_pulse_speed: float = 7.5
@export var block_shield_segments: int = 28

@export var min_charge_time: float = 0.15
@export var max_charge_time: float = 1.0
@export var charge_curve_exponent: float = 2.0
@export var charge_max_damage_mult: float = 1.5
@export var charge_max_knockback_mult: float = 2.0
@export var charge_base_hitstop: float = 0.08
@export var charge_max_hitstop: float = 0.15
@export var charge_armor_start: float = 0.25
@export var charge_armor_end: float = 1.0
@export var armor_break_threshold: float = 32.0
@export var charge_cancel_lockout: float = 0.12
@export var heavy_lunge_impulse: float = 180.0
@export var heavy_lunge_decay: float = 760.0
@export var charge_windup_duration: float = 0.07
@export var charge_active_duration: float = 0.2
@export var charge_recovery_duration: float = 0.26
@export var charge_range_bonus: float = 34.0
@export var charge_arc_bonus: float = 24.0
@export var charge_enemy_stun_min: float = 0.14
@export var charge_enemy_stun_max: float = 0.34
@export var hit_confirm_cancel_enabled: bool = true
@export var camera_shake_duration: float = 0.14
@export var camera_shake_strength: float = 5.0
@export var impact_hitstop_multiplier: float = 1.22
@export var impact_camera_shake_multiplier: float = 1.18
@export var impact_vfx_scale_multiplier: float = 1.15
@export var damage_popup_enabled: bool = true
@export var damage_popup_duration: float = 0.42
@export var damage_popup_rise_distance: float = 26.0
@export var damage_popup_x_spread: float = 8.0
@export var damage_popup_scale: float = 1.0
@export var damage_popup_font_size: int = 17
@export var damage_popup_outline_size: int = 3
@export var damage_popup_head_offset_y: float = -44.0

@export var pickup_radius: float = 34.0
@export var health_bar_width: float = 74.0
@export var health_bar_thickness: float = 6.0
@export var health_bar_y_offset: float = -74.0
@export var block_stamina_bar_width_scale: float = 0.92
@export var block_stamina_bar_thickness: float = 4.0
@export var block_stamina_bar_y_offset: float = -9.0

const ITEM_NAMES: Dictionary = {
	"iron_shard": "Iron Shard",
	"sturdy_hide": "Sturdy Hide",
	"swift_boots": "Swift Boots",
	"sword_extended_charge": "Extended Charge Sword",
	"sword_slowing": "Slowing Sword",
	"sword_stacking_dot": "Stacking DoT Sword",
	"shield_revenge": "Revenge Shield"
}

const SWORD_PICKUP_TO_SWORD_ID: Dictionary = {
	"sword_extended_charge": SWORD_DEFINITIONS.EXTENDED_CHARGE_SWORD,
	"sword_slowing": SWORD_DEFINITIONS.SLOWING_SWORD,
	"sword_stacking_dot": SWORD_DEFINITIONS.STACKING_DOT_SWORD
}

const SHIELD_PICKUP_TO_SHIELD_ID: Dictionary = {
	"shield_revenge": SHIELD_DEFINITIONS.REVENGE_SHIELD
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
	"run": 10.2,
	"attack": 10.6,
	"lunge": 10.6,
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
const BLOCK_SHIELD_EFFECT_SHEET_PATH: String = "res://assets/external/shieldeffect/shieldEffectSpriteSheet.png"
const BLOCK_SHIELD_EFFECT_FRAME_SIZE: Vector2i = Vector2i(32, 32)
const BLOCK_SHIELD_EFFECT_FRAME_ROWS: int = 3
const BLOCK_SHIELD_EFFECT_ANIM_FPS: float = 9.0
const BASIC_COMBO_MAX_HITS: int = 3
const BASIC_COMBO_DAMAGE_MULTIPLIERS: Array = [1.0, 1.14, 1.34]
const BASIC_COMBO_RANGE_MULTIPLIERS: Array = [1.0, 1.08, 1.18]
const BASIC_COMBO_ARC_MULTIPLIERS: Array = [1.0, 1.1, 1.24]
const BASIC_COMBO_WINDUP_MULTIPLIERS: Array = [1.0, 0.9, 0.8]
const BASIC_COMBO_COOLDOWN_MULTIPLIERS: Array = [0.8, 0.9, 1.0]
const BASIC_COMBO_ANIM_DURATION_MULTIPLIERS: Array = [1.0, 1.06, 1.2]
const BASIC_COMBO_ANIM_STRENGTH_MULTIPLIERS: Array = [1.0, 1.18, 1.36]
const BASIC_ATTACK_BASE_ANIM_DURATION: float = 0.24
const BASIC_ATTACK_BASE_ANIM_STRENGTH: float = 1.05
const COMBAT_STATE_NAMES: Dictionary = {
	CombatState.IDLE_MOVE: "IDLE_MOVE",
	CombatState.CHARGING_ATTACK: "CHARGING_ATTACK",
	CombatState.ATTACK_WINDUP: "ATTACK_WINDUP",
	CombatState.ATTACK_ACTIVE: "ATTACK_ACTIVE",
	CombatState.ATTACK_RECOVERY: "ATTACK_RECOVERY",
	CombatState.HITSTUN: "HITSTUN"
}

var current_health: float = 0.0
var current_block_stamina: float = 0.0
var block_stamina_broken: bool = false
var block_input_grace_left: float = 0.0
var perfect_block_window_left: float = 0.0
var counter_strike_available: bool = false
var counter_strike_window_left: float = 0.0
var current_xp: int = 0
var xp_to_next_level: int = 100
var level: int = 1
var inventory: Dictionary = {}
var available_sword_ids: Array[String] = []
var equipped_sword_id: String = ""
var equipped_sword_definition: Dictionary = {}
var available_shield_ids: Array[String] = []
var equipped_shield_id: String = ""
var equipped_shield_definition: Dictionary = {}
var gameplay_input_blocked: bool = false
var last_charge_attack_raw_ratio: float = 0.0

var facing_direction: Vector2 = Vector2.RIGHT
var is_blocking: bool = false
var debug_auto_block_enabled: bool = false
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
var basic_combo_auto_hits_remaining: int = 0
var basic_attack_input_buffered: bool = false
var basic_attack_input_buffer_left: float = 0.0
var queued_basic_combo_hit_index: int = 1
var queued_basic_combo_damage: float = 0.0
var queued_basic_combo_range: float = 0.0
var queued_basic_combo_arc_degrees: float = 0.0
var queued_melee_hit_stun_duration: float = 0.0
var queued_melee_hit_knockback_scale: float = 1.0
var queued_melee_hit_hitstop: float = 0.0
var queued_melee_hit_vfx_scale: float = 1.0
var queued_melee_hit_apply_sword_effect: bool = false

var lunge_time_left: float = 0.0
var lunge_total_duration: float = 0.0
var lunge_direction: Vector2 = Vector2.ZERO
var lunge_strike_applied: bool = false
var ally_dash_block_grace_left: float = 0.0
var instant_dash_block_latched: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var charge_lunge_velocity: Vector2 = Vector2.ZERO

var hit_flash_left: float = 0.0
var heal_flash_left: float = 0.0
var hurt_anim_left: float = 0.0
var stun_left: float = 0.0
var hitstop_left: float = 0.0
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
var block_shield_effect_sprite: AnimatedSprite2D = null
var block_shield_effect_frames: SpriteFrames = null
var block_shield_effect_texture: Texture2D = null
var character_sprite_base_position: Vector2 = Vector2.ZERO
var light_attack_recovery_left: float = 0.0
var combat_state: CombatState = CombatState.IDLE_MOVE
var combat_state_name: String = "IDLE_MOVE"
var is_charging_attack: bool = false
var charge_time: float = 0.0
var charge_release_direction: Vector2 = Vector2.RIGHT
var charge_release_windup_left: float = 0.0
var charge_attack_active_left: float = 0.0
var charge_attack_recovery_left: float = 0.0
var charge_attack_hit_pending: bool = false
var charge_attack_hit_confirmed: bool = false
var charge_attack_damage: float = 0.0
var charge_attack_range: float = 0.0
var charge_attack_arc: float = 0.0
var charge_attack_knockback_scale: float = 1.0
var charge_attack_hitstop: float = 0.0
var charge_attack_vfx_scale: float = 1.0
var charge_attack_enemy_stun: float = 0.0
var charge_attack_anim_strength: float = 1.0
var harpoon_charge_active: bool = false
var harpoon_charge_time: float = 0.0
var harpoon_charge_ratio: float = 0.0
var harpoon_throw_direction_sign: float = 1.0
var harpoon_projectile_active: bool = false
var harpoon_projectile_position: Vector2 = Vector2.ZERO
var harpoon_projectile_start: Vector2 = Vector2.ZERO
var harpoon_projectile_travel_left: float = 0.0
var harpoon_projectile_speed: float = 0.0
var harpoon_reel_active: bool = false
var harpoon_reel_left: float = 0.0
var harpoon_reel_speed: float = 0.0
var harpoon_reel_charge_ratio: float = 0.0
var harpoon_hooked_target: Node2D = null
var harpoon_hooked_target_is_enemy: bool = false
var harpoon_hooked_target_is_heavy: bool = false
var harpoon_heavy_start_x: float = 0.0
var harpoon_tether_line: Line2D = null
var harpoon_tether_glow_line: Line2D = null
var harpoon_projectile_visual: Node2D = null
var camera_base_offset: Vector2 = Vector2.ZERO
var camera_shake_left: float = 0.0
var camera_shake_current_strength: float = 0.0
var autoplay_test_enabled: bool = false
var autoplay_log_path: String = ""

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
var block_stamina_bar_background: Line2D = null
var block_stamina_bar_fill: Line2D = null
var damage_popup_sequence: int = 0
var hitbox_debug_enabled: bool = false
var hitbox_debug_overlay_root: Node2D = null
var hitbox_debug_hurtbox_ring: Line2D = null
var hitbox_debug_hurtbox_cross_h: Line2D = null
var hitbox_debug_hurtbox_cross_v: Line2D = null
var hitbox_debug_shield_ring: Line2D = null
var hitbox_debug_shield_box: Line2D = null

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
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	add_to_group("hitbox_debuggable")
	if get_tree() != null and get_tree().has_meta("debug_hitbox_mode_enabled"):
		hitbox_debug_enabled = bool(get_tree().get_meta("debug_hitbox_mode_enabled"))
	current_health = max_health
	current_block_stamina = block_stamina_max
	available_sword_ids = SWORD_DEFINITIONS.get_sword_ids()
	equipped_sword_id = String(SWORD_DEFINITIONS.DEFAULT_SWORD_ID)
	if available_sword_ids.find(equipped_sword_id) == -1 and not available_sword_ids.is_empty():
		equipped_sword_id = available_sword_ids[0]
	available_shield_ids.clear()
	equipped_shield_id = ""
	var env_sword_id := OS.get_environment("EQUIPPED_SWORD_ID").strip_edges().to_lower()
	if not env_sword_id.is_empty() and available_sword_ids.find(env_sword_id) != -1:
		equipped_sword_id = env_sword_id
	var env_shield_id := OS.get_environment("EQUIPPED_SHIELD_ID").strip_edges().to_lower()
	if SHIELD_DEFINITIONS.has_definition(env_shield_id):
		available_shield_ids.append(env_shield_id)
		equipped_shield_id = env_shield_id
	_refresh_equipped_sword_visuals()
	_refresh_equipped_shield_visuals()
	camera_base_offset = camera_2d.offset if is_instance_valid(camera_2d) else Vector2.ZERO
	_configure_autoplay_logging()
	_set_combat_state(CombatState.IDLE_MOVE)
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
	block_indicator.visible = false
	block_indicator.closed = true
	block_indicator.round_precision = 8
	block_indicator.begin_cap_mode = Line2D.LINE_CAP_ROUND
	block_indicator.end_cap_mode = Line2D.LINE_CAP_ROUND
	_setup_block_shield_effect_sprite()
	_setup_harpoon_visuals()
	_setup_hitbox_debug_overlay()
	_setup_health_bar()
	_update_health_bar()
	equipped_sword_changed.emit(equipped_sword_id, get_equipped_sword_name())
	equipped_shield_changed.emit(equipped_shield_id, get_equipped_shield_name())
	emit_initial_state()


func _physics_process(delta: float) -> void:
	_request_hitbox_debug_redraw()
	if is_dead:
		return

	_tick_timers(delta)
	_update_camera_shake(delta)
	if hitstop_left > 0.0:
		_update_health_bar()
		_update_visual_feedback(0.0)
		_emit_cooldown_state()
		return
	_update_facing_direction()
	if stun_left > 0.0:
		_interrupt_combat_for_stun()
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	else:
		_handle_actions()
		_tick_block_stamina(delta)
		_apply_movement()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, hit_knockback_decay * delta)
	move_and_slide()
	_apply_miniboss_soft_separation(delta)
	_clamp_to_lane()
	_update_health_bar()
	_collect_nearby_pickups()
	_update_visual_feedback(delta)
	_emit_cooldown_state()


func _exit_tree() -> void:
	if hitbox_debug_overlay_root != null and is_instance_valid(hitbox_debug_overlay_root):
		hitbox_debug_overlay_root.queue_free()
	if harpoon_tether_line != null and is_instance_valid(harpoon_tether_line):
		harpoon_tether_line.queue_free()
	if harpoon_tether_glow_line != null and is_instance_valid(harpoon_tether_glow_line):
		harpoon_tether_glow_line.queue_free()
	if harpoon_projectile_visual != null and is_instance_valid(harpoon_projectile_visual):
		harpoon_projectile_visual.queue_free()
	hitbox_debug_overlay_root = null
	hitbox_debug_hurtbox_ring = null
	hitbox_debug_hurtbox_cross_h = null
	hitbox_debug_hurtbox_cross_v = null
	hitbox_debug_shield_ring = null
	hitbox_debug_shield_box = null
	harpoon_tether_line = null
	harpoon_tether_glow_line = null
	harpoon_projectile_visual = null


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

	block_stamina_bar_background = Line2D.new()
	block_stamina_bar_background.default_color = Color(0.06, 0.08, 0.12, 0.9)
	block_stamina_bar_background.width = maxf(2.0, block_stamina_bar_thickness)
	block_stamina_bar_background.z_index = 2
	block_stamina_bar_background.begin_cap_mode = Line2D.LINE_CAP_ROUND
	block_stamina_bar_background.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(block_stamina_bar_background)

	block_stamina_bar_fill = Line2D.new()
	block_stamina_bar_fill.default_color = Color(0.34, 0.86, 1.0, 0.96)
	block_stamina_bar_fill.width = maxf(1.0, block_stamina_bar_thickness - 1.0)
	block_stamina_bar_fill.z_index = 3
	block_stamina_bar_fill.begin_cap_mode = Line2D.LINE_CAP_ROUND
	block_stamina_bar_fill.end_cap_mode = Line2D.LINE_CAP_ROUND
	health_bar_root.add_child(block_stamina_bar_fill)


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

	if is_instance_valid(block_stamina_bar_background) and is_instance_valid(block_stamina_bar_fill):
		var stamina_half_width := half_width * clampf(block_stamina_bar_width_scale, 0.25, 1.0)
		var stamina_start := Vector2(-stamina_half_width, block_stamina_bar_y_offset)
		var stamina_end := Vector2(stamina_half_width, block_stamina_bar_y_offset)
		block_stamina_bar_background.points = PackedVector2Array([stamina_start, stamina_end])
		var stamina_ratio := clampf(current_block_stamina / maxf(1.0, block_stamina_max), 0.0, 1.0)
		var stamina_fill_x := lerpf(stamina_start.x, stamina_end.x, stamina_ratio)
		block_stamina_bar_fill.points = PackedVector2Array([stamina_start, Vector2(stamina_fill_x, block_stamina_bar_y_offset)])
		block_stamina_bar_fill.visible = stamina_ratio > 0.0
		var stamina_locked := block_stamina_broken
		block_stamina_bar_background.default_color = Color(0.28, 0.08, 0.08, 0.92) if stamina_locked else Color(0.2, 0.15, 0.04, 0.92)
		if stamina_locked:
			block_stamina_bar_fill.default_color = Color(1.0, 0.22, 0.18, 0.98)
		else:
			block_stamina_bar_fill.default_color = Color(0.96, 0.82, 0.22, 0.98)


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		_level_up()

	xp_changed.emit(current_xp, xp_to_next_level, level)


func collect_item(item_id: String, value: int) -> void:
	if _try_collect_shield_pickup(item_id):
		return
	if _try_collect_sword_pickup(item_id):
		return
	var total := int(inventory.get(item_id, 0)) + value
	inventory[item_id] = total
	_apply_item_bonus(item_id, value)
	item_looted.emit(String(ITEM_NAMES.get(item_id, item_id)), total)
	health_changed.emit(current_health, max_health)


func get_available_sword_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for sword_id in available_sword_ids:
		entries.append(SWORD_DEFINITIONS.get_definition(sword_id))
	return entries


func get_available_shield_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for shield_id in available_shield_ids:
		entries.append(SHIELD_DEFINITIONS.get_definition(shield_id))
	return entries


func get_equipped_sword_id() -> String:
	return equipped_sword_id


func get_equipped_shield_id() -> String:
	return equipped_shield_id


func get_equipped_sword_name() -> String:
	if equipped_sword_id.is_empty():
		return "No Sword"
	return SWORD_DEFINITIONS.get_display_name(equipped_sword_id)


func get_equipped_shield_name() -> String:
	if equipped_shield_id.is_empty():
		return "No Shield"
	return SHIELD_DEFINITIONS.get_display_name(equipped_shield_id)


func equip_sword(sword_id: String) -> bool:
	if sword_id.is_empty():
		return false
	if available_sword_ids.find(sword_id) == -1:
		return false
	if equipped_sword_id == sword_id:
		return false
	equipped_sword_id = sword_id
	_refresh_equipped_sword_visuals()
	equipped_sword_changed.emit(equipped_sword_id, get_equipped_sword_name())
	_emit_cooldown_state()
	_log_sword_effect("EQUIP id=%s name=%s" % [equipped_sword_id, get_equipped_sword_name()])
	return true


func equip_shield(shield_id: String) -> bool:
	if shield_id.is_empty():
		return false
	if available_shield_ids.find(shield_id) == -1:
		return false
	if equipped_shield_id == shield_id:
		return false
	equipped_shield_id = shield_id
	_refresh_equipped_shield_visuals()
	equipped_shield_changed.emit(equipped_shield_id, get_equipped_shield_name())
	if not _is_counter_strike_unlocked():
		_expire_counter_strike()
	_emit_cooldown_state()
	return true


func has_sword_unlocked(sword_id: String) -> bool:
	if sword_id.is_empty():
		return false
	return available_sword_ids.find(sword_id) != -1


func has_shield_unlocked(shield_id: String) -> bool:
	if shield_id.is_empty():
		return false
	return available_shield_ids.find(shield_id) != -1


func get_missing_sword_ids() -> Array[String]:
	var missing: Array[String] = []
	for sword_id in SWORD_DEFINITIONS.get_sword_ids():
		if available_sword_ids.find(sword_id) == -1:
			missing.append(sword_id)
	return missing


func get_missing_shield_ids() -> Array[String]:
	var missing: Array[String] = []
	for shield_id in SHIELD_DEFINITIONS.get_shield_ids():
		if available_shield_ids.find(shield_id) == -1:
			missing.append(shield_id)
	return missing


func reset_sword_inventory_for_encounter() -> void:
	inventory.clear()
	available_sword_ids.clear()
	available_shield_ids.clear()
	equipped_sword_id = ""
	equipped_shield_id = ""
	_refresh_equipped_sword_visuals()
	_refresh_equipped_shield_visuals()
	equipped_sword_changed.emit(equipped_sword_id, get_equipped_sword_name())
	equipped_shield_changed.emit(equipped_shield_id, get_equipped_shield_name())
	_expire_counter_strike()
	_emit_cooldown_state()


func restore_default_sword_inventory() -> void:
	var previously_equipped := equipped_sword_id
	available_sword_ids = SWORD_DEFINITIONS.get_sword_ids()
	var fallback_default := String(SWORD_DEFINITIONS.DEFAULT_SWORD_ID)
	if not previously_equipped.is_empty() and available_sword_ids.find(previously_equipped) != -1:
		equipped_sword_id = previously_equipped
	elif available_sword_ids.find(fallback_default) != -1:
		equipped_sword_id = fallback_default
	elif not available_sword_ids.is_empty():
		equipped_sword_id = available_sword_ids[0]
	else:
		equipped_sword_id = ""
	available_shield_ids.clear()
	equipped_shield_id = ""
	_refresh_equipped_sword_visuals()
	_refresh_equipped_shield_visuals()
	equipped_sword_changed.emit(equipped_sword_id, get_equipped_sword_name())
	equipped_shield_changed.emit(equipped_shield_id, get_equipped_shield_name())
	_expire_counter_strike()
	_emit_cooldown_state()


func set_gameplay_input_blocked(blocked: bool) -> void:
	gameplay_input_blocked = blocked
	if not gameplay_input_blocked:
		_emit_cooldown_state()
		return
	is_blocking = false
	perfect_block_window_left = 0.0
	is_charging_attack = false
	_cancel_harpoon_state()
	_cancel_charge_attack()
	_reset_basic_combo_state()
	_emit_cooldown_state()


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
	heal_flash_left = maxf(heal_flash_left, maxf(0.01, heal_flash_duration))
	_spawn_hit_effect(global_position + Vector2(0.0, -14.0), Color(0.36, 0.95, 0.56, 0.92), 8.0)
	return true


func receive_hit(amount: float, source_position: Vector2, guard_break: bool = false, stun_duration: float = 0.0, knockback_scale: float = 1.0) -> bool:
	if is_dead:
		return false
	if is_invulnerable:
		return false

	var damage_to_apply := amount
	var blocked := false
	var perfect_block := false
	var incoming_direction := (source_position - global_position).normalized()
	if incoming_direction == Vector2.ZERO:
		incoming_direction = Vector2.LEFT if facing_direction.x >= 0.0 else Vector2.RIGHT
	if is_blocking and not guard_break:
		var block_threshold := cos(deg_to_rad(block_arc_degrees * 0.5))
		if facing_direction.dot(incoming_direction) >= block_threshold:
			damage_to_apply *= (1.0 - block_damage_reduction)
			blocked = true
			perfect_block = perfect_block_window_left > 0.0
			perfect_block_window_left = 0.0
			drain_block_stamina(block_stamina_blocked_hit_cost)
			if perfect_block:
				_register_perfect_block(source_position)

	if damage_to_apply <= 0.0:
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.LEFT if facing_direction.x >= 0.0 else Vector2.RIGHT
	var can_super_armor := _has_super_armor() and not blocked and not guard_break
	var super_armor_active := can_super_armor and damage_to_apply < armor_break_threshold
	var knockback_strength := hit_knockback_speed * (0.45 if blocked else 1.0) * maxf(0.1, knockback_scale)
	if super_armor_active:
		knockback_strength *= 0.45
	knockback_velocity = knockback_direction * knockback_strength

	current_health = maxf(0.0, current_health - damage_to_apply)
	health_changed.emit(current_health, max_health)
	hit_flash_left = 0.12
	var applied_stun := 0.0 if blocked or super_armor_active else maxf(hit_stun_duration, stun_duration)
	if not blocked:
		if super_armor_active:
			applied_stun = 0.0
		else:
			var hurt_duration := _get_hurt_animation_duration()
			hurt_anim_left = maxf(hurt_anim_left, hurt_duration)
			applied_stun = maxf(applied_stun, hurt_duration)
	if applied_stun > 0.0:
		stun_left = maxf(stun_left, applied_stun)
		_interrupt_combat_for_stun()
		basic_attack_cooldown_left = maxf(basic_attack_cooldown_left, stun_left)
		ability_1_cooldown_left = maxf(ability_1_cooldown_left, stun_left)
		ability_2_cooldown_left = maxf(ability_2_cooldown_left, stun_left)
		_set_combat_state(CombatState.HITSTUN)
	elif not is_charging_attack and charge_release_windup_left <= 0.0 and charge_attack_active_left <= 0.0 and charge_attack_recovery_left <= 0.0:
		_set_combat_state(CombatState.IDLE_MOVE)
	if not super_armor_active:
		attack_anim_left = 0.0
		light_attack_recovery_left = 0.0
		weapon_trail_alpha = 0.0
		weapon_trail.visible = false
		slash_effect.visible = false
		is_rolling = false
		is_invulnerable = false
	charge_attack_hit_confirmed = false
	_spawn_hit_effect(
		global_position + Vector2(0.0, -14.0),
		Color(0.58, 0.86, 1.0, 0.95) if super_armor_active else Color(1.0, 0.42, 0.3, 0.95),
		8.0 if super_armor_active else 10.0
	)

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
	heal_flash_left = maxf(0.0, heal_flash_left - delta)
	hurt_anim_left = maxf(0.0, hurt_anim_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	hitstop_left = maxf(0.0, hitstop_left - delta)
	attack_anim_left = maxf(0.0, attack_anim_left - delta)
	light_attack_recovery_left = maxf(0.0, light_attack_recovery_left - delta)
	ally_dash_block_grace_left = maxf(0.0, ally_dash_block_grace_left - delta)
	block_input_grace_left = maxf(0.0, block_input_grace_left - delta)
	perfect_block_window_left = maxf(0.0, perfect_block_window_left - delta)
	slash_effect_left = maxf(0.0, slash_effect_left - delta)
	weapon_trail_alpha = maxf(0.0, weapon_trail_alpha - (delta * 1.35))
	charge_lunge_velocity = charge_lunge_velocity.move_toward(Vector2.ZERO, heavy_lunge_decay * delta)
	if counter_strike_available:
		counter_strike_window_left = maxf(0.0, counter_strike_window_left - delta)
		if counter_strike_window_left <= 0.0:
			_expire_counter_strike()
	else:
		counter_strike_window_left = 0.0
	_tick_charge_attack_state(delta)
	_tick_harpoon_state(delta)
	if stun_left <= 0.0 and combat_state == CombatState.HITSTUN and not is_charging_attack and charge_release_windup_left <= 0.0 and charge_attack_active_left <= 0.0 and charge_attack_recovery_left <= 0.0:
		_set_combat_state(CombatState.IDLE_MOVE)
	if basic_combo_window_left <= 0.0 and attack_windup_left <= 0.0 and attack_anim_left <= 0.0 and basic_combo_auto_hits_remaining <= 0:
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

	if combat_state == CombatState.ATTACK_ACTIVE and attack_anim_left <= 0.0 and light_attack_recovery_left > 0.0 and charge_attack_active_left <= 0.0:
		_set_combat_state(CombatState.ATTACK_RECOVERY)
	if light_attack_recovery_left <= 0.0 and combat_state == CombatState.ATTACK_RECOVERY and charge_attack_recovery_left <= 0.0 and charge_attack_active_left <= 0.0 and attack_windup_left <= 0.0 and not is_charging_attack:
		_set_combat_state(CombatState.IDLE_MOVE)

	if is_rolling:
		roll_time_left -= delta
		if roll_time_left <= 0.0:
			is_rolling = false
			is_invulnerable = false

	if lunge_time_left > 0.0:
		lunge_time_left -= delta
		if lunge_time_left <= 0.0:
			lunge_time_left = 0.0
			lunge_total_duration = 0.0
			_apply_lunge_strike()

	if basic_attack_input_buffer_left > 0.0:
		basic_attack_input_buffer_left = maxf(0.0, basic_attack_input_buffer_left - delta)
		if basic_attack_input_buffer_left <= 0.0:
			basic_attack_input_buffered = false

	if basic_combo_buffered and basic_combo_auto_hits_remaining > 0 and _can_start_basic_attack_now():
		_try_start_basic_attack(true, "combo_auto")
	elif basic_attack_input_buffered and _can_start_basic_attack_now():
		_clear_basic_attack_buffer()
		_try_start_basic_attack(false, "buffered_input", true)
	_update_harpoon_visuals()


func _tick_block_stamina(delta: float) -> void:
	if delta <= 0.0:
		return
	if is_blocking:
		drain_block_stamina(block_stamina_hold_drain_per_second * delta)
	else:
		if current_block_stamina >= block_stamina_max:
			return
		current_block_stamina = minf(block_stamina_max, current_block_stamina + maxf(0.0, block_stamina_recharge_per_second) * delta)
		if block_stamina_broken and current_block_stamina >= _get_block_stamina_recover_threshold():
			block_stamina_broken = false


func _get_block_stamina_recover_threshold() -> float:
	return maxf(maxf(0.0, block_stamina_min_to_raise), block_stamina_max * clampf(block_stamina_recover_threshold_ratio, 0.0, 1.0))


func can_raise_block() -> bool:
	if block_stamina_broken:
		return false
	return current_block_stamina > maxf(0.0, block_stamina_min_to_raise)


func drain_block_stamina(amount: float) -> float:
	if amount <= 0.0:
		return current_block_stamina
	current_block_stamina = maxf(0.0, current_block_stamina - amount)
	if current_block_stamina <= 0.0:
		block_stamina_broken = true
		is_blocking = false
		instant_dash_block_latched = false
	return current_block_stamina


func _on_block_started() -> void:
	perfect_block_window_left = maxf(0.0, perfect_block_window)


func _unlock_counter_strike() -> void:
	if not _is_counter_strike_unlocked():
		counter_strike_available = false
		counter_strike_window_left = 0.0
		_emit_cooldown_state()
		return
	counter_strike_available = true
	counter_strike_window_left = maxf(0.0, counter_strike_unlock_duration)
	_emit_cooldown_state()
	_spawn_hit_effect(get_block_shield_center_global(), Color(0.86, 0.96, 1.0, 0.94), 11.0)
	_spawn_combat_text_popup(get_block_shield_center_global() + Vector2(-8.0, -58.0), "Counter Ready", Color(0.86, 0.98, 1.0, 0.98), 0.5)
	combat_status_message.emit("Perfect Block! Counter Strike Ready", 1.0)


func _consume_counter_strike() -> void:
	counter_strike_available = false
	counter_strike_window_left = 0.0
	_emit_cooldown_state()
	_spawn_combat_text_popup(global_position + Vector2(-8.0, -56.0), "Counter Used", Color(1.0, 0.86, 0.52, 0.96), 0.45)
	combat_status_message.emit("Counter Strike used", 0.75)


func _expire_counter_strike() -> void:
	if not counter_strike_available:
		counter_strike_window_left = 0.0
		return
	counter_strike_available = false
	counter_strike_window_left = 0.0
	_emit_cooldown_state()
	_spawn_combat_text_popup(global_position + Vector2(-8.0, -56.0), "Counter Expired", Color(0.86, 0.9, 0.98, 0.94), 0.45)
	combat_status_message.emit("Counter Strike expired", 0.75)


func _register_perfect_block(source_position: Vector2) -> void:
	_spawn_hit_effect(get_block_shield_center_global(), Color(0.72, 0.96, 1.0, 0.96), 13.0)
	_spawn_hit_effect(get_block_shield_center_global() + Vector2(0.0, -6.0), Color(0.98, 1.0, 1.0, 0.94), 8.2)
	_spawn_hit_effect(source_position + Vector2(0.0, -8.0), Color(0.72, 0.96, 1.0, 0.9), 6.4)
	_start_hitstop(0.05)
	_start_camera_shake(0.1, 3.2)
	_spawn_combat_text_popup(get_block_shield_center_global() + Vector2(-8.0, -72.0), "Perfect Block!", Color(0.78, 0.98, 1.0, 1.0), 0.55)
	if not _is_counter_strike_unlocked():
		combat_status_message.emit("Perfect Block! Equip a shield to unlock Counter", 1.1)
		_emit_cooldown_state()
		return
	_unlock_counter_strike()


func _can_start_counter_strike() -> bool:
	if not _is_counter_strike_unlocked():
		return false
	if gameplay_input_blocked:
		return false
	if is_dead or stun_left > 0.0:
		return false
	if harpoon_charge_active or harpoon_projectile_active or harpoon_reel_active:
		return false
	if is_rolling or lunge_time_left > 0.0:
		return false
	if is_charging_attack or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0 or charge_attack_recovery_left > 0.0:
		return false
	if attack_windup_left > 0.0 or attack_anim_left > 0.0 or light_attack_recovery_left > 0.0:
		return false
	if queued_attack != QueuedAttack.NONE:
		return false
	return true


func _try_start_counter_strike() -> bool:
	if not counter_strike_available:
		return false
	if not _can_start_counter_strike():
		return false
	_consume_counter_strike()
	is_blocking = false
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	light_attack_recovery_left = 0.0
	_queue_attack(
		QueuedAttack.COUNTER_STRIKE,
		maxf(0.01, counter_strike_startup),
		maxf(10.0, counter_strike_range),
		clampf(counter_strike_arc_degrees, 10.0, 179.0),
		Color(0.8, 0.96, 1.0, 0.52)
	)
	return true


func _can_start_harpoon_throw() -> bool:
	if gameplay_input_blocked:
		return false
	if is_dead or stun_left > 0.0:
		return false
	if counter_strike_available:
		return false
	if ability_1_cooldown_left > 0.0:
		return false
	if harpoon_charge_active or harpoon_projectile_active or harpoon_reel_active:
		return false
	if is_blocking:
		return false
	if is_rolling or lunge_time_left > 0.0:
		return false
	if is_charging_attack or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0 or charge_attack_recovery_left > 0.0:
		return false
	if attack_windup_left > 0.0 or attack_anim_left > 0.0 or light_attack_recovery_left > 0.0:
		return false
	if queued_attack != QueuedAttack.NONE:
		return false
	return true


func _try_start_harpoon_charge() -> bool:
	if not _can_start_harpoon_throw():
		return false
	harpoon_charge_active = true
	harpoon_charge_time = 0.0
	harpoon_charge_ratio = 0.0
	harpoon_throw_direction_sign = _get_block_shield_facing_sign()
	harpoon_reel_charge_ratio = 0.0
	harpoon_projectile_active = false
	harpoon_reel_active = false
	harpoon_hooked_target = null
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	_spawn_combat_text_popup(global_position + Vector2(0.0, -58.0), "Tidehook", Color(0.48, 0.92, 1.0, 0.96), 0.32)
	return true


func _tick_harpoon_state(delta: float) -> void:
	if harpoon_charge_active:
		if is_blocking or is_rolling or lunge_time_left > 0.0 or attack_windup_left > 0.0:
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
	var throw_sign := _get_block_shield_facing_sign()
	if absf(facing_direction.x) > 0.01:
		throw_sign = -1.0 if facing_direction.x < 0.0 else 1.0
	harpoon_throw_direction_sign = throw_sign
	var throw_origin := _get_harpoon_origin_global()
	harpoon_projectile_active = true
	harpoon_projectile_position = throw_origin
	harpoon_projectile_start = throw_origin
	harpoon_projectile_travel_left = lerpf(maxf(24.0, harpoon_min_range), maxf(harpoon_min_range, harpoon_max_range), harpoon_charge_ratio)
	harpoon_projectile_speed = lerpf(maxf(80.0, harpoon_min_projectile_speed), maxf(harpoon_min_projectile_speed, harpoon_max_projectile_speed), harpoon_charge_ratio)
	ability_1_cooldown_left = maxf(ability_1_cooldown_left, maxf(0.05, ability_1_cooldown))
	_spawn_hit_effect(throw_origin, Color(0.52, 0.94, 1.0, 0.92), 6.8)
	_emit_cooldown_state()


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
			var enemy := hit_target as EnemyBase
			hit_is_heavy = _is_harpoon_heavy_enemy(enemy)
		harpoon_projectile_active = false
		_spawn_hit_effect(hit_target.global_position + Vector2(0.0, -12.0), Color(0.62, 0.98, 1.0, 0.94), 7.6)
		_begin_harpoon_reel(hit_target, hit_is_enemy, hit_is_heavy)
		return
	if harpoon_projectile_travel_left <= 0.0:
		harpoon_projectile_active = false
		_spawn_hit_effect(harpoon_projectile_position + Vector2(0.0, -3.0), Color(0.42, 0.84, 1.0, 0.82), 5.2)


func _begin_harpoon_reel(target: Node2D, target_is_enemy: bool, target_is_heavy: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	harpoon_hooked_target = target
	harpoon_hooked_target_is_enemy = target_is_enemy
	harpoon_hooked_target_is_heavy = target_is_heavy
	harpoon_heavy_start_x = target.global_position.x
	harpoon_reel_active = true
	harpoon_reel_speed = lerpf(maxf(80.0, harpoon_min_reel_speed), maxf(harpoon_min_reel_speed, harpoon_max_reel_speed), harpoon_reel_charge_ratio)
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
	if harpoon_tether_line != null and is_instance_valid(harpoon_tether_line):
		harpoon_tether_line.visible = false
	if harpoon_tether_glow_line != null and is_instance_valid(harpoon_tether_glow_line):
		harpoon_tether_glow_line.visible = false
	if harpoon_projectile_visual != null and is_instance_valid(harpoon_projectile_visual):
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
	if candidate is FriendlyHealer:
		return not (candidate as FriendlyHealer).dead
	if candidate is FriendlyRatfolk:
		return not (candidate as FriendlyRatfolk).dead
	return false


func _get_harpoon_target_radius(candidate: Node2D) -> float:
	if candidate is EnemyBase:
		return _get_enemy_attack_collision_radius(candidate as EnemyBase)
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
	var player_radius := _get_player_harpoon_collision_radius()
	var target_radius := _get_harpoon_target_radius(harpoon_hooked_target) if (harpoon_hooked_target != null and is_instance_valid(harpoon_hooked_target)) else 14.0
	var contact_gap := maxf(0.0, harpoon_stop_distance)
	var contact_scale := clampf(harpoon_contact_distance_scale, 0.35, 1.0)
	var stop_distance := maxf(6.0, (player_radius + target_radius) * contact_scale + contact_gap)
	return global_position.x + (harpoon_throw_direction_sign * stop_distance)


func _get_harpoon_reel_destination(current_target_position: Vector2) -> Vector2:
	var destination_x := _get_harpoon_reel_destination_x(current_target_position.x)
	return Vector2(destination_x, global_position.y)


func _get_player_harpoon_collision_radius() -> float:
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
	var to_player := (global_position - enemy.global_position).normalized()
	if to_player == Vector2.ZERO:
		to_player = Vector2.LEFT if harpoon_throw_direction_sign >= 0.0 else Vector2.RIGHT
	var inward_knock_source := enemy.global_position - (to_player * 12.0)
	var landed := enemy.receive_hit(final_damage, inward_knock_source, final_stagger, true, 0.1, self)
	if landed:
		_spawn_damage_popup(enemy.global_position + Vector2(0.0, damage_popup_head_offset_y), final_damage)
	_spawn_hit_effect(enemy.global_position + Vector2(0.0, -12.0), Color(0.72, 0.96, 1.0, 0.96), 8.8)
	_start_hitstop(0.06)
	_start_camera_shake(0.1, 3.8)


func _apply_harpoon_heavy_tug_effect(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	if enemy.has_method("apply_hitstop"):
		enemy.call("apply_hitstop", 0.09)
	_set_node_float_max(enemy, "stun_left", maxf(0.0, harpoon_arrival_stagger_duration) * 0.35)
	_spawn_hit_effect(enemy.global_position + Vector2(0.0, -12.0), Color(0.68, 0.9, 1.0, 0.94), 8.2)
	_spawn_combat_text_popup(enemy.global_position + Vector2(0.0, -52.0), "Tugged", Color(0.72, 0.94, 1.0, 0.94), 0.36)
	_start_hitstop(0.04)


func _apply_harpoon_ally_arrival_effect(ally_target: Node2D) -> void:
	if ally_target == null or not is_instance_valid(ally_target):
		return
	_set_node_float(ally_target, "stun_left", 0.0)
	_set_node_vector(ally_target, "knockback_velocity", Vector2.ZERO)
	_spawn_hit_effect(ally_target.global_position + Vector2(0.0, -14.0), Color(0.52, 0.96, 1.0, 0.9), 7.4)
	_spawn_combat_text_popup(ally_target.global_position + Vector2(0.0, -54.0), "Rescued", Color(0.72, 1.0, 1.0, 0.94), 0.4)


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


func _apply_harpoon_reel_target_position(target: Node2D, reel_position: Vector2, delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if harpoon_hooked_target_is_enemy:
		# Lock enemy motion each reel tick so enemy AI/physics cannot immediately overwrite the pull.
		_set_node_vector(target, "velocity", Vector2.ZERO)
		_set_node_vector(target, "move_velocity", Vector2.ZERO)
		_set_node_vector(target, "knockback_velocity", Vector2.ZERO)
		var reel_stun := maxf(0.05, maxf(0.0, delta) + 0.02)
		if harpoon_hooked_target_is_heavy:
			reel_stun = minf(reel_stun, 0.06)
		_set_node_float_max(target, "stun_left", reel_stun)
	else:
		# Allies should keep their current action state while being repositioned.
		_set_node_vector(target, "knockback_velocity", Vector2.ZERO)
	target.global_position = reel_position
	target.set_deferred("global_position", reel_position)


func _object_has_property(target: Object, property_name: String) -> bool:
	for property_info in target.get_property_list():
		var name_variant: Variant = property_info.get("name", "")
		if String(name_variant) == property_name:
			return true
	return false


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
			lerpf(4.2, 5.8, preview_ratio),
			Color(0.12, 0.34, 0.44, 0.94),
			Color(0.68, 0.98, 1.0, lerpf(0.44, 0.94, preview_ratio)),
			lerpf(0.4, 2.0, preview_ratio)
		)
		harpoon_projectile_visual.visible = true
		harpoon_projectile_visual.global_position = preview_tip
		harpoon_projectile_visual.rotation = (0.0 if harpoon_throw_direction_sign >= 0.0 else PI) + (sin(anim_time * 16.0) * 0.06)
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
		harpoon_projectile_visual.rotation = (0.0 if harpoon_throw_direction_sign >= 0.0 else PI) + (sin(anim_time * 22.0) * 0.08)
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
		harpoon_projectile_visual.rotation = (0.0 if reel_sign >= 0.0 else PI) + (sin(anim_time * 20.0) * 0.05)
		harpoon_projectile_visual.scale = Vector2.ONE * 1.08
		return
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
	var segment_count := maxi(8, int(round(origin.distance_to(tip) / 18.0)))
	var points := PackedVector2Array()
	var span := tip - origin
	var span_length := maxf(1.0, span.length())
	var direction := span / span_length
	var normal := Vector2(-direction.y, direction.x)
	for i in range(segment_count + 1):
		var t := float(i) / float(segment_count)
		var falloff := 1.0 - absf((t * 2.0) - 1.0)
		var sway := sin((t * PI * 4.0) + (anim_time * 17.0)) * wave_strength * falloff
		points.append(to_local(origin.lerp(tip, t) + (normal * sway)))
	return points


func _configure_autoplay_logging() -> void:
	basic_attack_cadence_debug_logging = basic_attack_cadence_debug_logging or _is_env_enabled("TANK_BASIC_ATTACK_DEBUG")
	sword_combat_debug_logging = sword_combat_debug_logging or _is_env_enabled("SWORD_DEBUG")
	autoplay_test_enabled = _is_autoplay_requested()
	if not autoplay_test_enabled:
		autoplay_log_path = ""
		return
	autoplay_log_path = OS.get_environment("AUTOPLAY_LOG_PATH")
	if autoplay_log_path.is_empty():
		autoplay_log_path = ProjectSettings.globalize_path("res://artifacts/log.txt")


func _is_env_enabled(key: String) -> bool:
	var raw := OS.get_environment(key).strip_edges().to_lower()
	if raw.is_empty():
		return false
	return raw not in ["0", "false", "off", "no"]


func _is_autoplay_requested() -> bool:
	if _is_env_enabled("AUTOPLAY_TEST"):
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false


func _autoplay_log(message: String) -> void:
	if not autoplay_test_enabled:
		return
	print(message)
	if autoplay_log_path.is_empty():
		return
	var file := FileAccess.open(autoplay_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(autoplay_log_path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(message)


func _set_combat_state(next_state: CombatState) -> void:
	if combat_state == next_state:
		return
	combat_state = next_state
	combat_state_name = String(COMBAT_STATE_NAMES.get(next_state, "UNKNOWN"))
	match combat_state:
		CombatState.ATTACK_WINDUP:
			_autoplay_log("STATE WINDUP")
		CombatState.ATTACK_ACTIVE:
			_autoplay_log("STATE ACTIVE")
		CombatState.ATTACK_RECOVERY:
			_autoplay_log("STATE RECOVERY")
		_:
			pass


func _log_basic_attack_cadence(message: String) -> void:
	if not basic_attack_cadence_debug_logging:
		return
	print("[TankBasicAttack] %s" % message)


func _get_basic_attack_start_blocker() -> String:
	# Authoritative gameplay-side gate for all tank basic attack starts.
	if basic_attack_cooldown_left > 0.0:
		return "cooldown"
	if harpoon_charge_active:
		return "harpoon_charge"
	if harpoon_projectile_active:
		return "harpoon_projectile"
	# Allow J attacks during reel so Tidehook can flow directly into melee follow-up.
	if attack_anim_left > 0.0:
		return "attack_anim"
	if light_attack_recovery_left > 0.0:
		return "attack_recovery"
	if attack_windup_left > 0.0:
		return "attack_windup"
	if queued_attack != QueuedAttack.NONE:
		return "queued_attack"
	if is_rolling:
		return "rolling"
	if lunge_time_left > 0.0:
		return "lunging"
	if stun_left > 0.0:
		return "stunned"
	if is_blocking:
		return "blocking"
	if is_charging_attack:
		return "charging"
	if charge_release_windup_left > 0.0:
		return "charge_release_windup"
	if charge_attack_active_left > 0.0:
		return "charge_attack_active"
	if charge_attack_recovery_left > 0.0:
		return "charge_attack_recovery"
	return ""


func _can_start_basic_attack_now() -> bool:
	return _get_basic_attack_start_blocker().is_empty()


func _queue_basic_attack_buffer(reason: String) -> void:
	var buffer_window := maxf(0.0, basic_attack_input_buffer_window)
	if buffer_window <= 0.0:
		return
	basic_attack_input_buffered = true
	basic_attack_input_buffer_left = buffer_window
	_log_basic_attack_cadence("BUFFER_SET reason=%s window=%.3f" % [reason, basic_attack_input_buffer_left])


func _clear_basic_attack_buffer() -> void:
	basic_attack_input_buffered = false
	basic_attack_input_buffer_left = 0.0


func _try_start_basic_attack(use_combo: bool, source: String, consumed_buffer: bool = false) -> bool:
	if not _can_start_basic_attack_now():
		return false
	if consumed_buffer:
		_log_basic_attack_cadence("BUFFER_CONSUMED source=%s" % source)
	_log_basic_attack_cadence("ACCEPT source=%s mode=%s" % [source, "combo" if use_combo else "single"])
	if use_combo and basic_combo_auto_hits_remaining > 0:
		_start_basic_combo_attack()
	else:
		_start_basic_single_attack()
	return true


func _can_start_charge_attack() -> bool:
	return basic_attack_cooldown_left <= 0.0 and attack_anim_left <= 0.0 and light_attack_recovery_left <= 0.0 and attack_windup_left <= 0.0 and queued_attack == QueuedAttack.NONE and not is_rolling and lunge_time_left <= 0.0 and stun_left <= 0.0 and not is_charging_attack and charge_release_windup_left <= 0.0 and charge_attack_active_left <= 0.0 and charge_attack_recovery_left <= 0.0 and not harpoon_charge_active and not harpoon_projectile_active and not harpoon_reel_active


func _start_charge_attack() -> void:
	if not _can_start_charge_attack():
		return
	is_charging_attack = true
	charge_time = 0.0
	charge_lunge_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	charge_release_direction = _resolve_charge_release_direction()
	charge_attack_hit_pending = false
	charge_attack_hit_confirmed = false
	charge_attack_active_left = 0.0
	charge_attack_recovery_left = 0.0
	charge_release_windup_left = 0.0
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	_set_combat_state(CombatState.CHARGING_ATTACK)
	_autoplay_log("CHARGE_START")
	_show_attack_telegraph(basic_attack_range, basic_attack_arc_degrees, _get_equipped_sword_charge_preview_color(0.35))


func _cancel_charge_attack() -> void:
	is_charging_attack = false
	charge_time = 0.0
	charge_release_windup_left = 0.0
	charge_attack_active_left = 0.0
	charge_attack_hit_pending = false
	charge_attack_hit_confirmed = false
	attack_telegraph.visible = false
	attack_telegraph.scale = Vector2.ONE
	attack_telegraph.modulate.a = 1.0


func _release_charge_attack() -> void:
	if not is_charging_attack:
		return
	var release_time := charge_time
	var charge_ratio := _get_charge_ratio()
	var scaled_ratio := _get_scaled_charge_ratio()
	is_charging_attack = false
	attack_telegraph.visible = false
	if release_time < min_charge_time:
		_autoplay_log("CHARGE_RELEASE time=%.3f ratio=%.3f type=tap" % [release_time, charge_ratio])
		_begin_basic_combo_sequence()
		return

	charge_release_direction = _resolve_charge_release_direction()
	if absf(charge_release_direction.x) > 0.01:
		facing_direction = Vector2.RIGHT if charge_release_direction.x > 0.0 else Vector2.LEFT
	charge_attack_damage = basic_attack_damage * lerpf(1.0, charge_max_damage_mult, scaled_ratio)
	charge_attack_range = basic_attack_range + (charge_range_bonus * scaled_ratio)
	charge_attack_arc = basic_attack_arc_degrees + (charge_arc_bonus * scaled_ratio)
	charge_attack_knockback_scale = lerpf(1.0, charge_max_knockback_mult, scaled_ratio)
	charge_attack_hitstop = lerpf(charge_base_hitstop, charge_max_hitstop, scaled_ratio)
	charge_attack_vfx_scale = lerpf(1.0, 1.95, scaled_ratio)
	charge_attack_enemy_stun = lerpf(charge_enemy_stun_min, charge_enemy_stun_max, scaled_ratio)
	charge_attack_anim_strength = lerpf(1.22, 2.08, scaled_ratio)
	last_charge_attack_raw_ratio = charge_ratio
	charge_release_windup_left = maxf(0.01, charge_windup_duration)
	charge_attack_active_left = 0.0
	charge_attack_recovery_left = 0.0
	charge_attack_hit_pending = true
	charge_attack_hit_confirmed = false
	basic_attack_cooldown_left = maxf(basic_attack_cooldown_left, basic_attack_cooldown)
	_set_combat_state(CombatState.ATTACK_WINDUP)
	_autoplay_log("CHARGE_RELEASE time=%.3f ratio=%.3f type=heavy" % [release_time, charge_ratio])
	_show_attack_telegraph(charge_attack_range, charge_attack_arc, _get_equipped_sword_charge_release_color(0.42))
	_update_attack_telegraph_progress()


func _tick_charge_attack_state(delta: float) -> void:
	if is_charging_attack:
		if Input.is_action_pressed("ability_1"):
			charge_time = minf(max_charge_time, charge_time + delta)
			if charge_time >= max_charge_time - 0.0001:
				_release_charge_attack()
		else:
			_release_charge_attack()
		if is_charging_attack:
			var charge_ratio := _get_charge_ratio()
			var scaled_ratio := _get_scaled_charge_ratio()
			var preview_color := _get_equipped_sword_charge_preview_color(lerpf(0.28, 0.6, charge_ratio))
			_show_attack_telegraph(
				basic_attack_range + (charge_range_bonus * scaled_ratio * 0.6),
				basic_attack_arc_degrees + (charge_arc_bonus * scaled_ratio * 0.5),
				preview_color
			)
			attack_telegraph.rotation = _resolve_charge_release_direction().angle()
			attack_telegraph.modulate.a = lerpf(0.35, 0.92, charge_ratio)
			attack_telegraph.scale = Vector2.ONE * lerpf(0.94, 1.12, charge_ratio)

	if charge_release_windup_left > 0.0:
		charge_release_windup_left = maxf(0.0, charge_release_windup_left - delta)
		var windup_progress := 1.0 - (charge_release_windup_left / maxf(0.01, charge_windup_duration))
		attack_telegraph.color = _get_equipped_sword_charge_release_color(lerpf(0.45, 0.85, windup_progress))
		attack_telegraph.rotation = charge_release_direction.angle()
		attack_telegraph.modulate.a = lerpf(0.45, 0.96, windup_progress)
		attack_telegraph.scale = Vector2.ONE * lerpf(1.0, 1.18, windup_progress)
		if charge_release_windup_left <= 0.0:
			_begin_charge_attack_active()

	if charge_attack_active_left > 0.0:
		if charge_attack_hit_pending:
			_apply_charge_attack_hit()
		charge_attack_active_left = maxf(0.0, charge_attack_active_left - delta)
		if charge_attack_active_left <= 0.0:
			_begin_charge_attack_recovery()

	if charge_attack_recovery_left > 0.0:
		charge_attack_recovery_left = maxf(0.0, charge_attack_recovery_left - delta)
		if charge_attack_recovery_left <= 0.0:
			_cancel_charge_attack_recovery()
			if not is_rolling and stun_left <= 0.0:
				_set_combat_state(CombatState.IDLE_MOVE)


func _begin_charge_attack_active() -> void:
	charge_attack_active_left = maxf(0.01, charge_active_duration)
	_set_combat_state(CombatState.ATTACK_ACTIVE)
	var charge_flash_color := _get_equipped_sword_charge_release_color(0.46)
	_show_instant_attack_flash(
		charge_attack_range,
		charge_attack_arc,
		charge_flash_color,
		charge_release_direction
	)
	_start_attack_animation(lerpf(0.24, 0.34, _get_scaled_charge_ratio()), charge_attack_anim_strength)
	if not using_external_player_sprite:
		_trigger_slash_effect(
			charge_attack_range,
			charge_attack_arc,
			_get_equipped_sword_charge_release_color(0.92),
			0.22 + (_get_scaled_charge_ratio() * 0.08),
			6.4 + (_get_scaled_charge_ratio() * 2.8)
		)
	charge_lunge_velocity = charge_release_direction.normalized() * heavy_lunge_impulse


func _apply_charge_attack_hit() -> void:
	if not charge_attack_hit_pending:
		return
	charge_attack_hit_pending = false
	var hit_confirmed := _apply_melee_strike(
		charge_attack_damage,
		charge_attack_range,
		charge_attack_arc,
		charge_attack_enemy_stun,
		charge_attack_knockback_scale,
		charge_attack_hitstop,
		charge_attack_vfx_scale,
		charge_release_direction,
		false
	)
	if hit_confirmed:
		charge_attack_hit_confirmed = true


func _begin_charge_attack_recovery() -> void:
	charge_attack_recovery_left = maxf(0.01, charge_recovery_duration)
	_set_combat_state(CombatState.ATTACK_RECOVERY)


func _cancel_charge_attack_recovery() -> void:
	charge_attack_recovery_left = 0.0
	charge_attack_hit_confirmed = false
	charge_attack_hit_pending = false
	charge_attack_active_left = 0.0
	charge_release_windup_left = 0.0
	charge_lunge_velocity = Vector2.ZERO
	attack_telegraph.visible = false
	attack_telegraph.scale = Vector2.ONE
	attack_telegraph.modulate.a = 1.0


func _can_dodge_cancel_charge_recovery() -> bool:
	if not hit_confirm_cancel_enabled:
		return false
	return charge_attack_recovery_left > 0.0 and charge_attack_hit_confirmed


func _resolve_charge_release_direction() -> Vector2:
	if has_meta("aim_direction"):
		var aim_meta: Variant = get_meta("aim_direction")
		if aim_meta is Vector2:
			var aim_direction: Vector2 = aim_meta
			if aim_direction.length_squared() > 0.0001:
				return aim_direction.normalized()
	var movement_direction := _get_movement_vector()
	if movement_direction.length_squared() > 0.0001:
		return movement_direction.normalized()
	if facing_direction.length_squared() > 0.0001:
		return facing_direction.normalized()
	return Vector2.RIGHT


func _get_charge_ratio() -> float:
	return clampf(charge_time / maxf(0.01, max_charge_time), 0.0, 1.0)


func _get_scaled_charge_ratio() -> float:
	return pow(_get_charge_ratio(), maxf(0.2, charge_curve_exponent))


func _has_super_armor() -> bool:
	if charge_attack_active_left > 0.0:
		return true
	if not is_charging_attack:
		return false
	var charge_progress_time := charge_time
	return charge_progress_time >= charge_armor_start and charge_progress_time <= maxf(charge_armor_start, charge_armor_end)


func _start_hitstop(duration: float) -> void:
	var clamped_duration := maxf(0.0, duration)
	if clamped_duration <= 0.0:
		return
	if clamped_duration > hitstop_left + 0.0001:
		_autoplay_log("HITSTOP_START duration=%.3f" % clamped_duration)
	hitstop_left = maxf(hitstop_left, clamped_duration)


func _start_camera_shake(duration: float, strength: float) -> void:
	camera_shake_left = maxf(camera_shake_left, maxf(0.0, duration))
	camera_shake_current_strength = maxf(camera_shake_current_strength, maxf(0.0, strength))


func _update_camera_shake(delta: float) -> void:
	if not is_instance_valid(camera_2d):
		return
	if camera_shake_left > 0.0:
		camera_shake_left = maxf(0.0, camera_shake_left - delta)
		var shake_ratio := clampf(camera_shake_left / maxf(0.01, camera_shake_duration), 0.0, 1.0)
		var shake := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * camera_shake_current_strength * shake_ratio
		camera_2d.offset = camera_base_offset + shake
		if camera_shake_left <= 0.0:
			camera_shake_current_strength = 0.0
			camera_2d.offset = camera_base_offset
	else:
		camera_2d.offset = camera_base_offset


func _handle_actions() -> void:
	if gameplay_input_blocked:
		is_blocking = false
		return

	if _can_dodge_cancel_charge_recovery() and Input.is_action_just_pressed("roll") and roll_cooldown_left <= 0.0:
		_cancel_charge_attack_recovery()
		_start_roll()
		return

	var raw_wants_block := Input.is_action_pressed("block") or debug_auto_block_enabled
	if raw_wants_block:
		block_input_grace_left = maxf(block_input_grace_left, maxf(0.0, block_input_grace_duration))
	var wants_block := raw_wants_block or block_input_grace_left > 0.0
	var was_blocking := is_blocking
	var can_block_now := current_block_stamina > 0.0 and (was_blocking or can_raise_block())
	if not raw_wants_block and block_input_grace_left <= 0.0:
		instant_dash_block_latched = false
	if wants_block and can_block_now and _can_enter_instant_dash_block():
		_enter_instant_dash_block()
		return

	if is_charging_attack:
		is_blocking = false
		if Input.is_action_just_pressed("roll") and roll_cooldown_left <= 0.0 and charge_time >= charge_cancel_lockout:
			_cancel_charge_attack()
			_start_roll()
			return
		if not Input.is_action_pressed("ability_1"):
			_release_charge_attack()
		return

	if charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0:
		is_blocking = false
		return
	if charge_attack_recovery_left > 0.0:
		is_blocking = false
		return
	if light_attack_recovery_left > 0.0:
		is_blocking = false
		return

	if is_rolling or lunge_time_left > 0.0 or attack_windup_left > 0.0:
		is_blocking = false
		return

	if Input.is_action_just_pressed("roll") and roll_cooldown_left <= 0.0:
		_start_roll()
		return

	is_blocking = wants_block and can_block_now
	if is_blocking and not was_blocking:
		_on_block_started()
	elif not is_blocking:
		perfect_block_window_left = 0.0
	if Input.is_action_just_pressed("counter_strike"):
		var counter_started := _try_start_counter_strike()
		if counter_started or counter_strike_available:
			return
	if is_blocking:
		return
	if Input.is_action_just_pressed("ability_1"):
		_try_start_harpoon_charge()
		return

	if Input.is_action_just_pressed("basic_attack"):
		_log_basic_attack_cadence("INPUT_PRESS cooldown_left=%.3f" % basic_attack_cooldown_left)
		var blocker := _get_basic_attack_start_blocker()
		if blocker.is_empty():
			_clear_basic_attack_buffer()
			_try_start_basic_attack(false, "input_press")
		else:
			basic_combo_auto_hits_remaining = 0
			basic_combo_buffered = false
			if blocker == "cooldown":
				_log_basic_attack_cadence("REJECT reason=cooldown remaining=%.3f" % basic_attack_cooldown_left)
				if basic_attack_cooldown_left <= maxf(0.0, basic_attack_input_buffer_window):
					_queue_basic_attack_buffer("cooldown")
			else:
				_log_basic_attack_cadence("REJECT reason=%s" % blocker)
		return

	if Input.is_action_just_pressed("ability_2") and ability_2_cooldown_left <= 0.0:
		_reset_basic_combo_state()
		if _start_ally_dash():
			ability_2_cooldown_left = ability_2_cooldown


func _queue_attack(kind: QueuedAttack, windup: float, attack_range: float, arc_degrees: float, telegraph_color: Color) -> void:
	queued_attack = kind
	attack_windup_total = maxf(0.01, windup)
	attack_windup_left = attack_windup_total
	light_attack_recovery_left = 0.0
	_set_combat_state(CombatState.ATTACK_WINDUP)
	_show_attack_telegraph(attack_range, arc_degrees, telegraph_color)


func _start_basic_combo_attack() -> void:
	var combo_hit := 1
	if basic_combo_auto_hits_remaining > 0:
		combo_hit = clampi((BASIC_COMBO_MAX_HITS - basic_combo_auto_hits_remaining) + 1, 1, BASIC_COMBO_MAX_HITS)
	elif basic_combo_window_left > 0.0 and basic_combo_step > 0:
		combo_hit = mini(BASIC_COMBO_MAX_HITS, basic_combo_step + 1)

	var combo_index := combo_hit - 1
	var damage_multiplier := float(BASIC_COMBO_DAMAGE_MULTIPLIERS[combo_index])
	var range_multiplier := float(BASIC_COMBO_RANGE_MULTIPLIERS[combo_index])
	var arc_multiplier := float(BASIC_COMBO_ARC_MULTIPLIERS[combo_index])
	var windup_multiplier := float(BASIC_COMBO_WINDUP_MULTIPLIERS[combo_index])
	var cooldown_multiplier := float(BASIC_COMBO_COOLDOWN_MULTIPLIERS[combo_index])
	var sword_range_multiplier := _get_equipped_basic_attack_range_multiplier()
	if sword_range_multiplier > 1.001:
		_log_sword_effect("BASIC_RANGE_MULT hit=%d x%.2f" % [combo_hit, sword_range_multiplier])

	queued_basic_combo_hit_index = combo_hit
	queued_basic_combo_damage = basic_attack_damage * damage_multiplier
	queued_basic_combo_range = basic_attack_range * range_multiplier * sword_range_multiplier
	queued_basic_combo_arc_degrees = basic_attack_arc_degrees * arc_multiplier

	basic_attack_cooldown_left = maxf(basic_attack_cooldown, basic_attack_cooldown * cooldown_multiplier)
	_queue_attack(
		QueuedAttack.BASIC,
		maxf(0.01, basic_attack_windup * windup_multiplier),
		queued_basic_combo_range,
		queued_basic_combo_arc_degrees,
		_get_equipped_sword_charge_preview_color(0.34)
	)
	if basic_combo_auto_hits_remaining > 0:
		basic_combo_auto_hits_remaining -= 1
		if basic_combo_auto_hits_remaining > 0:
			basic_combo_step = combo_hit
			basic_combo_window_left = basic_combo_chain_window
			basic_combo_buffered = true
		else:
			basic_combo_step = 0
			basic_combo_window_left = 0.0
			basic_combo_buffered = false
			basic_attack_cooldown_left = maxf(basic_attack_cooldown_left, basic_combo_end_cooldown)
		return

	basic_combo_buffered = false
	if combo_hit >= BASIC_COMBO_MAX_HITS:
		basic_combo_step = 0
		basic_combo_window_left = 0.0
		basic_attack_cooldown_left = maxf(basic_attack_cooldown_left, basic_combo_end_cooldown)
	else:
		basic_combo_step = combo_hit
		basic_combo_window_left = basic_combo_chain_window


func _start_basic_single_attack() -> void:
	_reset_basic_combo_state()
	var combo_index := 0
	var sword_range_multiplier := _get_equipped_basic_attack_range_multiplier()
	if sword_range_multiplier > 1.001:
		_log_sword_effect("BASIC_RANGE_MULT hit=1 x%.2f" % sword_range_multiplier)
	queued_basic_combo_hit_index = 1
	queued_basic_combo_damage = basic_attack_damage * float(BASIC_COMBO_DAMAGE_MULTIPLIERS[combo_index])
	queued_basic_combo_range = basic_attack_range * float(BASIC_COMBO_RANGE_MULTIPLIERS[combo_index]) * sword_range_multiplier
	queued_basic_combo_arc_degrees = basic_attack_arc_degrees * float(BASIC_COMBO_ARC_MULTIPLIERS[combo_index])
	basic_attack_cooldown_left = maxf(0.01, basic_attack_cooldown)
	_queue_attack(
		QueuedAttack.BASIC,
		maxf(0.01, basic_attack_windup * float(BASIC_COMBO_WINDUP_MULTIPLIERS[combo_index])),
		queued_basic_combo_range,
		queued_basic_combo_arc_degrees,
		_get_equipped_sword_charge_preview_color(0.34)
	)
	basic_combo_buffered = false


func _begin_basic_combo_sequence() -> void:
	_reset_basic_combo_state()
	basic_combo_auto_hits_remaining = BASIC_COMBO_MAX_HITS
	basic_combo_buffered = true


func _resolve_queued_attack() -> void:
	match queued_attack:
		QueuedAttack.BASIC:
			var combo_hit := clampi(queued_basic_combo_hit_index, 1, BASIC_COMBO_MAX_HITS)
			var combo_index := combo_hit - 1
			var combo_damage := queued_basic_combo_damage if queued_basic_combo_damage > 0.0 else basic_attack_damage
			var combo_range := queued_basic_combo_range if queued_basic_combo_range > 0.0 else basic_attack_range
			var combo_arc := queued_basic_combo_arc_degrees if queued_basic_combo_arc_degrees > 0.0 else basic_attack_arc_degrees
			var combo_hitstop := 0.045 + (0.012 * float(combo_index))
			var combo_knockback := 1.0 + (0.08 * float(combo_index))
			_queue_melee_hit_for_final_attack_frame(combo_damage, combo_range, combo_arc, outgoing_hit_stun_duration, combo_knockback, combo_hitstop, 1.0 + (0.16 * float(combo_index)), true)
			var combo_anim_duration := BASIC_ATTACK_BASE_ANIM_DURATION * float(BASIC_COMBO_ANIM_DURATION_MULTIPLIERS[combo_index])
			var combo_anim_strength := BASIC_ATTACK_BASE_ANIM_STRENGTH * float(BASIC_COMBO_ANIM_STRENGTH_MULTIPLIERS[combo_index])
			_start_attack_animation(combo_anim_duration, combo_anim_strength)
			light_attack_recovery_left = maxf(light_attack_recovery_left, 0.14 + (0.04 * float(combo_index)))
			_set_combat_state(CombatState.ATTACK_ACTIVE)
			if not using_external_player_sprite:
				var slash_duration := 0.16 + (0.02 * float(combo_index))
				var slash_width := 4.8 + (0.7 * float(combo_index))
				_trigger_slash_effect(combo_range, combo_arc, _get_equipped_sword_charge_release_color(0.88), slash_duration, slash_width)
			_clear_queued_basic_combo_attack()
		QueuedAttack.ABILITY_1:
			_queue_melee_hit_for_final_attack_frame(ability_1_damage, ability_1_range, ability_1_arc_degrees, outgoing_hit_stun_duration + 0.06, 1.25, 0.085, 1.45, false)
			_start_attack_animation(0.24, 1.45)
			light_attack_recovery_left = maxf(light_attack_recovery_left, 0.22)
			_set_combat_state(CombatState.ATTACK_ACTIVE)
			if not using_external_player_sprite:
				_trigger_slash_effect(ability_1_range, ability_1_arc_degrees, Color(0.84, 0.72, 0.52, 0.9), 0.22, 6.2)
		QueuedAttack.COUNTER_STRIKE:
			var counter_range := maxf(10.0, counter_strike_range)
			var counter_arc := clampf(counter_strike_arc_degrees, 10.0, 179.0)
			_queue_melee_hit_for_final_attack_frame(
				counter_strike_damage,
				counter_range,
				counter_arc,
				maxf(0.0, counter_strike_enemy_stun),
				maxf(0.1, counter_strike_knockback_scale),
				maxf(0.0, counter_strike_hitstop),
				maxf(0.25, counter_strike_vfx_scale),
				false
			)
			_start_attack_animation(maxf(0.06, counter_strike_anim_duration), maxf(0.2, counter_strike_anim_strength))
			light_attack_recovery_left = maxf(light_attack_recovery_left, maxf(0.06, counter_strike_recovery))
			_set_combat_state(CombatState.ATTACK_ACTIVE)
			_show_instant_attack_flash(counter_range, counter_arc, Color(0.86, 0.98, 1.0, 0.92))
			_spawn_hit_effect(global_position + Vector2(12.0 * _get_block_shield_facing_sign(), -12.0), Color(0.86, 0.98, 1.0, 0.9), 7.4)
			if not using_external_player_sprite:
				_trigger_slash_effect(counter_range, counter_arc, Color(0.86, 0.98, 1.0, 0.92), 0.19, 7.0)
		_:
			pass

	queued_attack = QueuedAttack.NONE
	attack_telegraph.visible = false
	attack_telegraph.modulate.a = 1.0
	attack_telegraph.scale = Vector2.ONE


func _queue_melee_hit_for_final_attack_frame(
	damage: float,
	attack_range: float,
	arc_degrees: float,
	stun_duration: float = outgoing_hit_stun_duration,
	knockback_scale: float = 1.0,
	hitstop_duration: float = 0.05,
	vfx_scale: float = 1.0,
	apply_sword_effect: bool = false
) -> void:
	queued_melee_hit_pending = true
	queued_melee_hit_damage = damage
	queued_melee_hit_range = attack_range
	queued_melee_hit_arc_degrees = arc_degrees
	queued_melee_hit_stun_duration = stun_duration
	queued_melee_hit_knockback_scale = maxf(0.1, knockback_scale)
	queued_melee_hit_hitstop = maxf(0.0, hitstop_duration)
	queued_melee_hit_vfx_scale = maxf(0.25, vfx_scale)
	queued_melee_hit_apply_sword_effect = apply_sword_effect


func _clear_queued_melee_hit() -> void:
	queued_melee_hit_pending = false
	queued_melee_hit_damage = 0.0
	queued_melee_hit_range = 0.0
	queued_melee_hit_arc_degrees = 0.0
	queued_melee_hit_stun_duration = 0.0
	queued_melee_hit_knockback_scale = 1.0
	queued_melee_hit_hitstop = 0.0
	queued_melee_hit_vfx_scale = 1.0
	queued_melee_hit_apply_sword_effect = false


func _apply_queued_melee_hit() -> void:
	if not queued_melee_hit_pending:
		return
	var damage := queued_melee_hit_damage
	var attack_range := queued_melee_hit_range
	var arc_degrees := queued_melee_hit_arc_degrees
	var stun_duration := queued_melee_hit_stun_duration
	var knockback_scale := queued_melee_hit_knockback_scale
	var hitstop_duration := queued_melee_hit_hitstop
	var vfx_scale := queued_melee_hit_vfx_scale
	var apply_sword_effect := queued_melee_hit_apply_sword_effect
	_clear_queued_melee_hit()
	var hit_confirmed := _apply_melee_strike(damage, attack_range, arc_degrees, stun_duration, knockback_scale, hitstop_duration, vfx_scale, Vector2.ZERO, apply_sword_effect)
	if hit_confirmed:
		charge_attack_hit_confirmed = true


func _clear_queued_basic_combo_attack() -> void:
	queued_basic_combo_hit_index = 1
	queued_basic_combo_damage = 0.0
	queued_basic_combo_range = 0.0
	queued_basic_combo_arc_degrees = 0.0


func _reset_basic_combo_state() -> void:
	basic_combo_step = 0
	basic_combo_window_left = 0.0
	basic_combo_buffered = false
	basic_combo_auto_hits_remaining = 0
	_clear_basic_attack_buffer()
	_clear_queued_basic_combo_attack()


func _apply_lunge_strike() -> void:
	if lunge_strike_applied:
		return
	lunge_strike_applied = true
	ally_dash_block_grace_left = maxf(ally_dash_block_grace_left, maxf(0.0, ability_2_instant_block_grace))
	light_attack_recovery_left = maxf(light_attack_recovery_left, 0.08)
	_set_combat_state(CombatState.ATTACK_RECOVERY)


func _show_attack_telegraph(attack_range: float, arc_degrees: float, telegraph_color: Color) -> void:
	attack_telegraph.visible = true
	attack_telegraph.color = telegraph_color
	attack_telegraph.polygon = _build_arc_polygon(attack_range, arc_degrees, 18)
	attack_telegraph.position = Vector2.ZERO
	var telegraph_direction := facing_direction
	if is_charging_attack or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0:
		telegraph_direction = charge_release_direction
	if telegraph_direction.length_squared() <= 0.0001:
		telegraph_direction = facing_direction
	attack_telegraph.rotation = telegraph_direction.angle()
	attack_telegraph.modulate.a = 0.25


func _show_instant_attack_flash(
	attack_range: float,
	arc_degrees: float,
	telegraph_color: Color,
	telegraph_direction: Vector2 = Vector2.ZERO
) -> void:
	attack_telegraph.visible = true
	attack_telegraph.color = telegraph_color
	attack_telegraph.polygon = _build_arc_polygon(attack_range, arc_degrees, 16)
	attack_telegraph.position = Vector2.ZERO
	var direction := telegraph_direction
	if direction.length_squared() <= 0.0001:
		direction = facing_direction
	attack_telegraph.rotation = direction.angle()
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
	if is_charging_attack:
		attack_telegraph.color = _get_equipped_sword_charge_preview_color(attack_telegraph.color.a)
	elif charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0:
		attack_telegraph.color = _get_equipped_sword_charge_release_color(attack_telegraph.color.a)
	var telegraph_direction := facing_direction
	if is_charging_attack or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0:
		telegraph_direction = charge_release_direction
	if telegraph_direction.length_squared() <= 0.0001:
		telegraph_direction = facing_direction
	attack_telegraph.rotation = telegraph_direction.angle()
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


func _show_harpoon_charge_telegraph(telegraph_length: float) -> void:
	attack_telegraph.visible = true
	attack_telegraph.color = _get_equipped_sword_charge_preview_color(0.34)
	attack_telegraph.polygon = _build_harpoon_arrow_polygon(telegraph_length)
	attack_telegraph.position = Vector2(24.0 * harpoon_throw_direction_sign, -16.0)
	attack_telegraph.rotation = 0.0 if harpoon_throw_direction_sign >= 0.0 else PI
	attack_telegraph.modulate.a = 0.25
	attack_telegraph.scale = Vector2.ONE


func _hide_harpoon_charge_telegraph() -> void:
	attack_telegraph.visible = false
	attack_telegraph.position = Vector2.ZERO
	attack_telegraph.scale = Vector2.ONE
	attack_telegraph.modulate.a = 1.0


func _build_harpoon_arrow_polygon(arrow_length: float) -> PackedVector2Array:
	var length := maxf(18.0, arrow_length)
	var head_length := clampf(length * 0.22, 12.0, 30.0)
	var shaft_half_height := clampf(length * 0.035, 4.0, 8.0)
	var head_half_height := shaft_half_height * 2.2
	var shaft_end := maxf(6.0, length - head_length)
	return PackedVector2Array([
		Vector2(0.0, -shaft_half_height),
		Vector2(shaft_end, -shaft_half_height),
		Vector2(shaft_end, -head_half_height),
		Vector2(length, 0.0),
		Vector2(shaft_end, head_half_height),
		Vector2(shaft_end, shaft_half_height),
		Vector2(0.0, shaft_half_height)
	])


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
	_cancel_harpoon_state()
	_cancel_charge_attack()
	_cancel_charge_attack_recovery()
	queued_attack = QueuedAttack.NONE
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	light_attack_recovery_left = 0.0
	attack_telegraph.visible = false
	slash_effect_left = 0.0
	ally_dash_block_grace_left = 0.0
	instant_dash_block_latched = false
	weapon_trail_alpha = maxf(weapon_trail_alpha, 0.38)
	_set_combat_state(CombatState.IDLE_MOVE)


func _start_ally_dash() -> bool:
	var dash_selection := _find_guardian_dash_selection()
	var dash_destination := global_position
	if not dash_selection.is_empty():
		var selected_point: Variant = dash_selection.get("point", global_position)
		if selected_point is Vector2:
			dash_destination = selected_point
	else:
		var ally_target := _find_nearest_facing_ally()
		if ally_target == null:
			return false
		dash_destination = ally_target.global_position
	return _begin_ally_dash_to_point(dash_destination)


func _begin_ally_dash_to_point(destination: Vector2) -> bool:
	var to_destination := destination - global_position
	var destination_distance := to_destination.length()
	if destination_distance <= 0.0001:
		return false
	var dash_distance := maxf(0.0, destination_distance - maxf(0.0, ability_2_arrive_distance))
	if dash_distance <= maxf(0.0, ability_2_min_dash_distance):
		return false
	lunge_direction = to_destination / destination_distance
	if absf(lunge_direction.x) > 0.01:
		facing_direction = Vector2.RIGHT if lunge_direction.x > 0.0 else Vector2.LEFT
	lunge_total_duration = maxf(maxf(0.01, ability_2_min_duration), dash_distance / maxf(1.0, ability_2_lunge_speed))
	lunge_time_left = lunge_total_duration
	lunge_strike_applied = false
	ally_dash_block_grace_left = 0.0
	instant_dash_block_latched = false
	is_blocking = false
	_cancel_harpoon_state()
	_cancel_charge_attack()
	_cancel_charge_attack_recovery()
	queued_attack = QueuedAttack.NONE
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	light_attack_recovery_left = 0.0
	attack_telegraph.visible = false
	weapon_trail_alpha = maxf(weapon_trail_alpha, 0.72)
	_set_combat_state(CombatState.ATTACK_ACTIVE)
	return true


func _find_guardian_dash_selection() -> Dictionary:
	var best_selection: Dictionary = {}
	var facing := facing_direction.normalized()
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	var dot_threshold := clampf(ability_2_facing_dot_threshold, -1.0, 1.0)
	var best_score := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("get_marked_ally_node"):
			continue
		var marked_ally := enemy.call("get_marked_ally_node") as Node2D
		if not _is_valid_ally_dash_target(marked_ally):
			continue
		var to_marked := marked_ally.global_position - global_position
		var distance_sq := to_marked.length_squared()
		if distance_sq <= 0.0001:
			continue
		var direction_to_marked := to_marked / sqrt(distance_sq)
		if facing.dot(direction_to_marked) < dot_threshold:
			continue
		# Guardian dash should only move to ally positions, never to enemy intercept points.
		var to_intercept := marked_ally.global_position - global_position
		var intercept_distance_sq := to_intercept.length_squared()
		if intercept_distance_sq <= 0.0001:
			continue
		var score := intercept_distance_sq
		if enemy.has_method("is_lunge_threatening_marked_ally") and bool(enemy.call("is_lunge_threatening_marked_ally")):
			score *= maxf(0.1, guardian_dash_lunge_priority_scale)
		else:
			score *= maxf(0.1, guardian_dash_mark_priority_scale)
		if score < best_score:
			best_score = score
			best_selection = {
				"point": marked_ally.global_position,
				"ally": marked_ally,
				"enemy": enemy
			}
	return best_selection


func _find_nearest_facing_ally() -> Node2D:
	var facing := facing_direction.normalized()
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	var dot_threshold := clampf(ability_2_facing_dot_threshold, -1.0, 1.0)
	var best_target: Node2D = null
	var best_distance_sq := INF
	for candidate in _get_ally_dash_candidates():
		if not _is_valid_ally_dash_target(candidate):
			continue
		var to_candidate := candidate.global_position - global_position
		var distance_sq := to_candidate.length_squared()
		if distance_sq <= 0.0001:
			continue
		var candidate_direction := to_candidate / sqrt(distance_sq)
		if facing.dot(candidate_direction) < dot_threshold:
			continue
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = candidate
	return best_target


func _get_ally_dash_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	var seen_ids: Dictionary = {}
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var ally := node as Node2D
		if ally == null:
			continue
		var ally_id := ally.get_instance_id()
		if seen_ids.has(ally_id):
			continue
		seen_ids[ally_id] = true
		candidates.append(ally)
	for node in get_tree().get_nodes_in_group("player"):
		var ally_player := node as Node2D
		if ally_player == null:
			continue
		var player_id := ally_player.get_instance_id()
		if seen_ids.has(player_id):
			continue
		seen_ids[player_id] = true
		candidates.append(ally_player)
	return candidates


func _is_valid_ally_dash_target(candidate: Node2D) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false
	if candidate == self:
		return false
	var valid_ally_type := candidate is Player or candidate is FriendlyHealer or candidate is FriendlyRatfolk
	if not valid_ally_type:
		return false
	if candidate is Player:
		var ally_player := candidate as Player
		if ally_player == null or ally_player.is_dead:
			return false
	elif candidate is FriendlyHealer:
		var ally_healer := candidate as FriendlyHealer
		if ally_healer == null or ally_healer.dead:
			return false
	elif candidate is FriendlyRatfolk:
		var ally_ratfolk := candidate as FriendlyRatfolk
		if ally_ratfolk == null or ally_ratfolk.dead:
			return false
	return true


func _has_ally_dash_block_window() -> bool:
	return lunge_time_left > 0.0 or ally_dash_block_grace_left > 0.0


func _can_enter_instant_dash_block() -> bool:
	if not _has_ally_dash_block_window():
		return false
	if is_dead or stun_left > 0.0 or is_rolling:
		return false
	if is_charging_attack or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0 or charge_attack_recovery_left > 0.0:
		return false
	return true


func _enter_instant_dash_block() -> void:
	var was_blocking := is_blocking
	if lunge_time_left > 0.0:
		lunge_time_left = 0.0
		lunge_total_duration = 0.0
		lunge_strike_applied = true
	light_attack_recovery_left = 0.0
	ally_dash_block_grace_left = maxf(ally_dash_block_grace_left, maxf(0.0, ability_2_instant_block_grace))
	instant_dash_block_latched = true
	is_blocking = true
	if not was_blocking:
		_on_block_started()
	_set_combat_state(CombatState.IDLE_MOVE)


func _interrupt_combat_for_stun() -> void:
	is_blocking = false
	perfect_block_window_left = 0.0
	_cancel_harpoon_state()
	_cancel_charge_attack()
	_cancel_charge_attack_recovery()
	queued_attack = QueuedAttack.NONE
	_reset_basic_combo_state()
	_clear_queued_melee_hit()
	attack_windup_left = 0.0
	light_attack_recovery_left = 0.0
	attack_telegraph.visible = false
	lunge_time_left = 0.0
	lunge_total_duration = 0.0
	lunge_strike_applied = false
	ally_dash_block_grace_left = 0.0
	instant_dash_block_latched = false
	charge_lunge_velocity = Vector2.ZERO
	_set_combat_state(CombatState.HITSTUN)


func _apply_movement() -> void:
	if is_rolling:
		var lane_roll := Vector2(roll_vector.x, roll_vector.y * depth_speed_multiplier)
		if lane_roll.length_squared() > 1.0:
			lane_roll = lane_roll.normalized()
		velocity = lane_roll * roll_speed
		return

	if lunge_time_left > 0.0:
		velocity = lunge_direction * ability_2_lunge_speed + charge_lunge_velocity
		return

	if is_charging_attack:
		velocity = Vector2.ZERO
		return

	# Lock manual movement for the full charge-attack sequence triggered by J.
	if charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0 or charge_attack_recovery_left > 0.0:
		# Preserve built-in charge impulse, but ignore player movement input.
		velocity = charge_lunge_velocity
		if is_blocking and knockback_velocity.length_squared() > 0.0001:
			velocity += knockback_velocity * blocked_knockback_move_scale
		return

	# Basic attack (J) windup should root the player in place.
	if attack_windup_left > 0.0 and queued_attack != QueuedAttack.NONE:
		velocity = Vector2.ZERO
		return

	if is_blocking:
		velocity = charge_lunge_velocity
		if knockback_velocity.length_squared() > 0.0001:
			velocity += knockback_velocity * blocked_knockback_move_scale
		return

	var movement_vector := _get_movement_vector()
	movement_vector.y *= depth_speed_multiplier
	if movement_vector.length_squared() > 1.0:
		movement_vector = movement_vector.normalized()
	var movement_multiplier := block_move_multiplier if is_blocking else 1.0
	velocity = movement_vector * move_speed * movement_multiplier + charge_lunge_velocity
	if is_blocking and knockback_velocity.length_squared() > 0.0001:
		velocity += knockback_velocity * blocked_knockback_move_scale


func _clamp_to_lane() -> void:
	position.x = clampf(position.x, lane_min_x, lane_max_x)
	position.y = clampf(position.y, lane_min_y, lane_max_y)


func _apply_miniboss_soft_separation(delta: float) -> void:
	if not miniboss_soft_collision_enabled:
		return
	if is_dead or delta <= 0.0:
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


func _get_movement_vector() -> Vector2:
	if gameplay_input_blocked:
		return Vector2.ZERO
	var movement_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if movement_vector.length_squared() > 1.0:
		movement_vector = movement_vector.normalized()
	return movement_vector


func _update_facing_direction() -> void:
	# Keep the current facing while guarding or in hit-stun so knockback does not flip orientation.
	if stun_left > 0.0 or is_blocking or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0:
		return
	if is_charging_attack:
		var charge_move_vector := _get_movement_vector()
		if absf(charge_move_vector.x) > 0.08:
			facing_direction = Vector2.RIGHT if charge_move_vector.x > 0.0 else Vector2.LEFT
		return
	var movement_vector := _get_movement_vector()
	if absf(movement_vector.x) > 0.08:
		facing_direction = Vector2.RIGHT if movement_vector.x > 0.0 else Vector2.LEFT
		return
	if absf(velocity.x) > 0.08:
		facing_direction = Vector2.RIGHT if velocity.x > 0.0 else Vector2.LEFT


func _apply_melee_strike(
	damage: float,
	attack_range: float,
	arc_degrees: float,
	stun_duration: float = outgoing_hit_stun_duration,
	knockback_scale: float = 1.0,
	hitstop_duration: float = 0.05,
	vfx_scale: float = 1.0,
	strike_direction: Vector2 = Vector2.ZERO,
	apply_sword_effect: bool = false
) -> bool:
	var facing := strike_direction.normalized()
	if facing == Vector2.ZERO:
		facing = facing_direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	var hitstop_scale := maxf(0.4, impact_hitstop_multiplier)
	var shake_scale := maxf(0.4, impact_camera_shake_multiplier)
	var impact_vfx_scale := maxf(0.5, impact_vfx_scale_multiplier)
	var half_arc_radians := deg_to_rad(arc_degrees * 0.5)
	var arc_edge_tolerance_radians := deg_to_rad(3.0)
	var hit_ids: Dictionary = {}
	var hit_confirmed := false
	var strongest_hitstop := 0.0
	var strongest_vfx_scale := 1.0
	for enemy in _collect_attack_targets(attack_range):
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if hit_ids.has(enemy_id):
			continue

		var target_point := _get_enemy_attack_target_point(enemy, global_position)
		var target_radius := _get_enemy_attack_collision_radius(enemy)
		var to_enemy: Vector2 = target_point - global_position
		var is_air_boss := enemy.monster_visual_profile == EnemyBase.MonsterVisualProfile.CACODEMON \
			or enemy.monster_visual_profile == EnemyBase.MonsterVisualProfile.SHARDSOUL
		var effective_depth_tolerance := attack_depth_tolerance + (18.0 if is_air_boss else 0.0) + target_radius
		var effective_attack_range := attack_range + (14.0 if is_air_boss else 0.0) + target_radius
		if absf(to_enemy.y) > effective_depth_tolerance:
			continue
		if to_enemy.length_squared() > effective_attack_range * effective_attack_range:
			continue
		if to_enemy.length_squared() > 0.0001:
			var distance_to_target := to_enemy.length()
			var radius_arc_allowance := asin(clampf(target_radius / maxf(1.0, distance_to_target), 0.0, 0.99))
			var alignment_threshold := cos(half_arc_radians + radius_arc_allowance + arc_edge_tolerance_radians)
			if facing.dot(to_enemy / distance_to_target) < alignment_threshold:
				continue

		hit_ids[enemy_id] = true
		var enemy_health_before := enemy.current_health
		if enemy.receive_hit(damage, global_position, stun_duration, true, knockback_scale, self):
			hit_confirmed = true
			if apply_sword_effect:
				_apply_equipped_sword_on_basic_hit(enemy)
			var hit_world_position := enemy.global_position + Vector2(0.0, -12.0)
			var damage_dealt := maxf(0.0, enemy_health_before - enemy.current_health)
			if damage_dealt <= 0.01:
				damage_dealt = maxf(0.0, damage)
			_spawn_damage_popup(enemy.global_position + Vector2(0.0, damage_popup_head_offset_y), damage_dealt)
			var applied_hitstop := hitstop_duration * hitstop_scale
			strongest_hitstop = maxf(strongest_hitstop, applied_hitstop)
			strongest_vfx_scale = maxf(strongest_vfx_scale, vfx_scale * impact_vfx_scale)
			if enemy.has_method("apply_hitstop"):
				enemy.apply_hitstop(applied_hitstop)
			_spawn_hit_effect(hit_world_position, Color(1.0, 0.82, 0.46, 0.95), 9.0 * maxf(0.6, vfx_scale * impact_vfx_scale))
			if not is_dead and enemy.can_trade_melee_with(self):
				receive_hit(enemy.get_trade_damage(), enemy.global_position, false, enemy.get_trade_stun_duration())
				if is_dead:
					return true
	if hit_confirmed:
		_start_hitstop(strongest_hitstop)
		_start_camera_shake(camera_shake_duration * shake_scale, (camera_shake_strength * shake_scale) * maxf(0.7, strongest_vfx_scale))
	return hit_confirmed


func _apply_equipped_sword_on_basic_hit(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.dead:
		return
	if equipped_sword_id.is_empty():
		return
	var sword_data := equipped_sword_definition if not equipped_sword_definition.is_empty() else SWORD_DEFINITIONS.get_definition(equipped_sword_id)
	var sword_id := String(sword_data.get("id", ""))
	_spawn_equipped_sword_impact_fx(enemy.global_position + Vector2(0.0, -12.0))
	if sword_id == String(SWORD_DEFINITIONS.SLOWING_SWORD):
		var slow_duration := maxf(0.0, float(sword_data.get("slow_duration", 2.4)))
		var slow_multiplier := clampf(float(sword_data.get("slow_speed_multiplier", 0.5)), 0.1, 1.0)
		if enemy.has_method("apply_player_weapon_slow"):
			enemy.call("apply_player_weapon_slow", slow_duration, slow_multiplier)
			_log_sword_effect("SLOW_APPLY target=%s duration=%.2f speed_mult=%.2f" % [enemy.name, slow_duration, slow_multiplier])
		return
	if sword_id == String(SWORD_DEFINITIONS.STACKING_DOT_SWORD):
		var dot_duration := maxf(0.1, float(sword_data.get("dot_duration", 4.0)))
		var tick_interval := maxf(0.1, float(sword_data.get("dot_tick_interval", 0.5)))
		var damage_per_stack := maxf(0.1, float(sword_data.get("dot_damage_per_stack", 2.0)))
		var max_stacks := maxi(1, int(sword_data.get("dot_max_stacks", 5)))
		if enemy.has_method("apply_player_weapon_dot"):
			enemy.call("apply_player_weapon_dot", dot_duration, tick_interval, damage_per_stack, max_stacks, self)
			_log_sword_effect("DOT_APPLY target=%s duration=%.2f interval=%.2f dps=%.2f max_stacks=%d" % [enemy.name, dot_duration, tick_interval, damage_per_stack, max_stacks])


func _log_sword_effect(message: String) -> void:
	if not sword_combat_debug_logging:
		return
	print("[SWORD] %s" % message)


func _refresh_equipped_sword_visuals() -> void:
	if equipped_sword_id.is_empty() or available_sword_ids.find(equipped_sword_id) == -1:
		equipped_sword_definition = {}
		return
	equipped_sword_definition = SWORD_DEFINITIONS.get_definition(equipped_sword_id)


func _refresh_equipped_shield_visuals() -> void:
	if equipped_shield_id.is_empty() or available_shield_ids.find(equipped_shield_id) == -1:
		equipped_shield_definition = {}
		return
	equipped_shield_definition = SHIELD_DEFINITIONS.get_definition(equipped_shield_id)


func _try_collect_shield_pickup(item_id: String) -> bool:
	if not SHIELD_PICKUP_TO_SHIELD_ID.has(item_id):
		return false
	var shield_id := String(SHIELD_PICKUP_TO_SHIELD_ID[item_id])
	if shield_id.is_empty():
		return true
	if available_shield_ids.find(shield_id) == -1:
		available_shield_ids.append(shield_id)
		available_shield_ids.sort()
		var auto_equip := equipped_shield_id.is_empty()
		if auto_equip:
			equipped_shield_id = shield_id
		_refresh_equipped_shield_visuals()
		equipped_shield_changed.emit(equipped_shield_id, get_equipped_shield_name())
		var shield_name := SHIELD_DEFINITIONS.get_display_name(shield_id)
		item_looted.emit(shield_name, available_shield_ids.size())
		if auto_equip:
			combat_status_message.emit("%s equipped - Counter unlocked" % shield_name, 1.1)
	else:
		item_looted.emit(String(ITEM_NAMES.get(item_id, item_id)), available_shield_ids.size())
	_emit_cooldown_state()
	return true


func _try_collect_sword_pickup(item_id: String) -> bool:
	if not SWORD_PICKUP_TO_SWORD_ID.has(item_id):
		return false
	var sword_id := String(SWORD_PICKUP_TO_SWORD_ID[item_id])
	if sword_id.is_empty():
		return true
	if available_sword_ids.find(sword_id) == -1:
		available_sword_ids.append(sword_id)
		available_sword_ids.sort()
		var auto_equip := equipped_sword_id.is_empty()
		if auto_equip:
			equipped_sword_id = sword_id
		_refresh_equipped_sword_visuals()
		equipped_sword_changed.emit(equipped_sword_id, get_equipped_sword_name())
		_emit_cooldown_state()
		var sword_name := SWORD_DEFINITIONS.get_display_name(sword_id)
		item_looted.emit(sword_name, available_sword_ids.size())
		_log_sword_effect("UNLOCK id=%s name=%s owned=%d" % [sword_id, sword_name, available_sword_ids.size()])
		if auto_equip:
			combat_status_message.emit("%s equipped" % sword_name, 1.0)
	else:
		item_looted.emit(String(ITEM_NAMES.get(item_id, item_id)), available_sword_ids.size())
	return true


func _is_counter_strike_unlocked() -> bool:
	return bool(equipped_shield_definition.get("unlocks_counter_strike", false))


func _is_extended_charge_sword_equipped() -> bool:
	return String(equipped_sword_definition.get("id", equipped_sword_id)) == String(SWORD_DEFINITIONS.EXTENDED_CHARGE_SWORD)


func _get_equipped_basic_attack_range_multiplier() -> float:
	if not _is_extended_charge_sword_equipped():
		return 1.0
	return maxf(1.0, float(equipped_sword_definition.get("extended_basic_range_multiplier", 1.0)))


func _get_equipped_sword_charge_preview_color(alpha: float = 0.35) -> Color:
	var fallback := Color(1.0, 0.78, 0.32, alpha)
	var color_variant: Variant = equipped_sword_definition.get("charge_preview_color", fallback)
	var color := fallback
	if color_variant is Color:
		color = color_variant as Color
	color.a = clampf(alpha, 0.0, 1.0)
	return color


func _get_equipped_sword_charge_release_color(alpha: float = 0.45) -> Color:
	var fallback := Color(1.0, 0.62, 0.28, alpha)
	var color_variant: Variant = equipped_sword_definition.get("charge_release_color", fallback)
	var color := fallback
	if color_variant is Color:
		color = color_variant as Color
	color.a = clampf(alpha, 0.0, 1.0)
	return color


func _get_equipped_sword_impact_color(alpha: float = 0.95) -> Color:
	var fallback := Color(1.0, 0.82, 0.45, alpha)
	var color_variant: Variant = equipped_sword_definition.get("impact_color", fallback)
	var color := fallback
	if color_variant is Color:
		color = color_variant as Color
	color.a = clampf(alpha, 0.0, 1.0)
	return color


func _spawn_equipped_sword_impact_fx(world_position: Vector2) -> void:
	var impact_color := _get_equipped_sword_impact_color(0.95)
	var facing_sign := -1.0 if facing_direction.x < 0.0 else 1.0
	var sword_id := String(equipped_sword_definition.get("id", equipped_sword_id))
	if sword_id == String(SWORD_DEFINITIONS.EXTENDED_CHARGE_SWORD):
		_spawn_hit_effect(world_position + Vector2(8.0 * facing_sign, -3.0), impact_color, 11.5)
		_spawn_hit_effect(world_position + Vector2(-7.0 * facing_sign, 2.0), impact_color.lightened(0.14), 8.0)
		return
	if sword_id == String(SWORD_DEFINITIONS.SLOWING_SWORD):
		_spawn_hit_effect(world_position + Vector2(0.0, -4.0), impact_color, 10.8)
		_spawn_hit_effect(world_position + Vector2(5.0 * facing_sign, -14.0), Color(0.72, 0.96, 1.0, 0.9), 6.3)
		return
	if sword_id == String(SWORD_DEFINITIONS.STACKING_DOT_SWORD):
		_spawn_hit_effect(world_position + Vector2(0.0, -4.0), impact_color, 10.4)
		_spawn_hit_effect(world_position + Vector2(7.0 * facing_sign, 2.0), Color(1.0, 0.68, 0.92, 0.88), 7.2)


func _collect_attack_targets(attack_range: float) -> Array[EnemyBase]:
	var targets: Array[EnemyBase] = []
	var seen_ids: Dictionary = {}
	for result in _query_attack_hits(attack_range):
		var enemy := result.get("collider") as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var enemy_id := enemy.get_instance_id()
		if seen_ids.has(enemy_id):
			continue
		seen_ids[enemy_id] = true
		targets.append(enemy)
	var fallback_radius := maxf(attack_range + 56.0, attack_range * 1.55)
	var fallback_radius_sq := fallback_radius * fallback_radius
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var enemy_id := enemy.get_instance_id()
		if seen_ids.has(enemy_id):
			continue
		if global_position.distance_squared_to(enemy.global_position) > fallback_radius_sq:
			continue
		seen_ids[enemy_id] = true
		targets.append(enemy)
	return targets


func _get_enemy_attack_target_point(enemy: EnemyBase, attack_origin: Vector2) -> Vector2:
	var target_point := enemy.global_position
	var collision_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return target_point
	target_point = collision_shape.global_position
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return target_point
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	var hit_radius := maxf(0.0, circle.radius * maxf(0.01, radius_scale))
	var to_enemy := target_point - attack_origin
	var distance := to_enemy.length()
	if distance <= 0.0001 or hit_radius <= 0.01:
		return target_point
	var clamped_inset := minf(hit_radius, distance * 0.8)
	return target_point - (to_enemy / distance) * clamped_inset


func _get_enemy_attack_collision_radius(enemy: EnemyBase) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	var collision_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return 0.0
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return 0.0
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	return maxf(0.0, circle.radius * maxf(0.01, radius_scale))


func _query_attack_hits(attack_range: float) -> Array:
	var world := get_world_2d()
	if world == null:
		return []
	var hit_shape := CircleShape2D.new()
	hit_shape.radius = maxf(4.0, maxf(attack_range + 56.0, attack_range * 1.55))
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
	var movement_ratio := clampf(velocity.length() / maxf(1.0, move_speed), 0.0, 1.0)
	_update_player_sprite(delta, movement_ratio)

	var target_scale := Vector2.ONE
	if is_blocking:
		target_scale = Vector2(0.95, 1.05)
		block_indicator.default_color = Color(0.66, 0.74, 0.86, 0.95)
	elif is_charging_attack:
		target_scale = Vector2(1.04, 0.96)
		block_indicator.default_color = Color(0.82, 0.78, 0.46, 0.9)
	elif charge_release_windup_left > 0.0:
		target_scale = Vector2(1.08, 0.92)
		block_indicator.default_color = Color(0.9, 0.52, 0.3, 0.92)
	elif charge_attack_active_left > 0.0:
		target_scale = Vector2(1.14, 0.86)
		block_indicator.default_color = Color(1.0, 0.58, 0.34, 0.94)
	elif charge_attack_recovery_left > 0.0:
		target_scale = Vector2(0.98, 1.02)
		block_indicator.default_color = Color(0.74, 0.56, 0.4, 0.78)
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
	elif heal_flash_left > 0.0:
		_set_model_palette(
			Color(0.36, 0.78, 0.46, 1.0),
			Color(0.74, 0.94, 0.76, 1.0),
			Color(0.42, 0.72, 0.5, 1.0),
			Color(0.74, 0.98, 0.8, 1.0),
			Color(0.14, 0.22, 0.16, 1.0)
		)
	elif _has_super_armor():
		_set_model_palette(
			Color(0.3, 0.38, 0.52, 1.0),
			Color(0.88, 0.79, 0.7, 1.0),
			Color(0.45, 0.54, 0.72, 1.0),
			Color(0.86, 0.86, 0.9, 1.0),
			Color(0.16, 0.2, 0.3, 1.0)
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
	_update_block_indicator_visual()
	scale = scale.lerp(target_scale, clampf(delta * 14.0, 0.0, 1.0))
	_update_weapon_fx(delta)


func _is_block_pose_ready() -> bool:
	return is_blocking


func is_block_shield_active() -> bool:
	return _is_block_pose_ready()


func _get_block_shield_facing_sign() -> float:
	return -1.0 if facing_direction.x < 0.0 else 1.0


func get_block_shield_center_local() -> Vector2:
	return get_block_shield_visual_center_local()


func get_block_shield_visual_center_local() -> Vector2:
	return Vector2(0.0, block_shield_y_offset)


func get_block_shield_center_global() -> Vector2:
	return global_position + get_block_shield_center_local()


func get_block_shield_half_extents() -> Vector2:
	var radius := maxf(8.0, block_shield_radius)
	return Vector2(
		maxf(6.0, radius * maxf(0.2, block_shield_half_width_scale)),
		maxf(6.0, radius * maxf(0.2, block_shield_half_height_scale))
	)


func orient_block_toward(world_source: Vector2) -> void:
	var to_source := world_source - global_position
	if absf(to_source.x) <= 0.01:
		return
	facing_direction = Vector2.LEFT if to_source.x < 0.0 else Vector2.RIGHT


func toggle_debug_auto_block() -> bool:
	debug_auto_block_enabled = not debug_auto_block_enabled
	return debug_auto_block_enabled


func set_hitbox_debug_enabled(enabled: bool) -> void:
	var next_enabled := bool(enabled)
	if hitbox_debug_enabled == next_enabled:
		return
	hitbox_debug_enabled = next_enabled
	_update_hitbox_debug_overlay()
	queue_redraw()


func _request_hitbox_debug_redraw() -> void:
	_update_hitbox_debug_overlay()
	if hitbox_debug_enabled:
		queue_redraw()


func _draw() -> void:
	if not hitbox_debug_enabled:
		return
	_draw_hurtbox_debug()
	_draw_attack_debug()
	_draw_block_shield_debug()


func _draw_hurtbox_debug() -> void:
	if collision_shape == null or not is_instance_valid(collision_shape):
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		return
	var center := to_local(collision_shape.global_position)
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	var radius := maxf(4.0, circle.radius * maxf(0.01, radius_scale))
	draw_circle(center, radius, Color(0.2, 1.0, 1.0, 0.14))
	draw_arc(center, radius, 0.0, TAU, 36, Color(0.2, 1.0, 1.0, 0.92), 2.0, true)


func _draw_attack_debug() -> void:
	var facing := facing_direction.normalized()
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	var direction := facing
	var attack_range := basic_attack_range
	var attack_arc := basic_attack_arc_degrees
	var fill_color := Color(1.0, 0.68, 0.18, 0.13)
	var outline_color := Color(1.0, 0.82, 0.42, 0.95)
	if is_charging_attack:
		var charge_ratio := _get_scaled_charge_ratio()
		attack_range = basic_attack_range + (charge_range_bonus * charge_ratio)
		attack_arc = basic_attack_arc_degrees + (charge_arc_bonus * charge_ratio)
		direction = _resolve_charge_release_direction()
		fill_color = Color(1.0, 0.42, 0.22, 0.18)
		outline_color = Color(1.0, 0.52, 0.32, 0.96)
	elif charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0 or charge_attack_recovery_left > 0.0:
		attack_range = maxf(attack_range, charge_attack_range)
		attack_arc = maxf(attack_arc, charge_attack_arc)
		direction = charge_release_direction if charge_release_direction.length_squared() > 0.0001 else direction
		fill_color = Color(1.0, 0.34, 0.2, 0.2)
		outline_color = Color(1.0, 0.48, 0.32, 0.96)
	if direction.length_squared() <= 0.0001:
		direction = facing
	var cone := _build_arc_polygon(maxf(8.0, attack_range), clampf(attack_arc, 5.0, 179.0), 28)
	var rotated_cone := PackedVector2Array()
	var rotation_angle := direction.angle()
	for point in cone:
		rotated_cone.append(point.rotated(rotation_angle))
	draw_colored_polygon(rotated_cone, fill_color)
	draw_polyline(rotated_cone, outline_color, 2.0, true)


func _draw_block_shield_debug() -> void:
	var half_extents := get_block_shield_half_extents()
	var center := get_block_shield_center_local()
	var shield_points := PackedVector2Array()
	var segments := maxi(16, block_shield_segments)
	for i in range(segments):
		var t := (TAU * float(i)) / float(segments)
		shield_points.append(center + Vector2(cos(t) * half_extents.x, sin(t) * half_extents.y))
	draw_colored_polygon(shield_points, Color(0.36, 0.88, 1.0, 0.12))
	draw_polyline(shield_points, Color(0.54, 0.94, 1.0, 0.92), 2.0, true)


func _setup_hitbox_debug_overlay() -> void:
	if hitbox_debug_overlay_root != null and is_instance_valid(hitbox_debug_overlay_root):
		return
	var root := Node2D.new()
	root.name = "HitboxDebugOverlay"
	root.top_level = true
	root.z_index = 420
	root.visible = false
	add_child(root)
	hitbox_debug_overlay_root = root

	var ring := Line2D.new()
	ring.default_color = Color(0.16, 1.0, 1.0, 0.98)
	ring.width = 2.4
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.closed = true
	ring.round_precision = 8
	root.add_child(ring)
	hitbox_debug_hurtbox_ring = ring

	var cross_h := Line2D.new()
	cross_h.default_color = Color(0.74, 1.0, 1.0, 0.95)
	cross_h.width = 1.8
	cross_h.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cross_h.end_cap_mode = Line2D.LINE_CAP_ROUND
	root.add_child(cross_h)
	hitbox_debug_hurtbox_cross_h = cross_h

	var cross_v := Line2D.new()
	cross_v.default_color = Color(0.74, 1.0, 1.0, 0.95)
	cross_v.width = 1.8
	cross_v.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cross_v.end_cap_mode = Line2D.LINE_CAP_ROUND
	root.add_child(cross_v)
	hitbox_debug_hurtbox_cross_v = cross_v

	var shield_ring := Line2D.new()
	shield_ring.default_color = Color(0.34, 0.9, 1.0, 0.98)
	shield_ring.width = 2.2
	shield_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shield_ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	shield_ring.closed = true
	shield_ring.round_precision = 8
	shield_ring.visible = false
	root.add_child(shield_ring)
	hitbox_debug_shield_ring = shield_ring

	var shield_box := Line2D.new()
	shield_box.default_color = Color(1.0, 0.32, 0.26, 0.98)
	shield_box.width = 1.8
	shield_box.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shield_box.end_cap_mode = Line2D.LINE_CAP_ROUND
	shield_box.closed = true
	shield_box.round_precision = 2
	shield_box.visible = false
	root.add_child(shield_box)
	hitbox_debug_shield_box = shield_box


func _update_hitbox_debug_overlay() -> void:
	if hitbox_debug_overlay_root == null or not is_instance_valid(hitbox_debug_overlay_root):
		return
	var visible := hitbox_debug_enabled and collision_shape != null and is_instance_valid(collision_shape)
	hitbox_debug_overlay_root.visible = visible
	if not visible:
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		hitbox_debug_overlay_root.visible = false
		return
	var radius_scale := maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
	var radius := maxf(4.0, circle.radius * maxf(0.01, radius_scale))
	hitbox_debug_overlay_root.global_position = collision_shape.global_position
	if hitbox_debug_hurtbox_ring != null and is_instance_valid(hitbox_debug_hurtbox_ring):
		hitbox_debug_hurtbox_ring.points = _build_circle_line_points(Vector2.ZERO, radius, 30)
	if hitbox_debug_hurtbox_cross_h != null and is_instance_valid(hitbox_debug_hurtbox_cross_h):
		hitbox_debug_hurtbox_cross_h.points = PackedVector2Array([Vector2(-radius, 0.0), Vector2(radius, 0.0)])
	if hitbox_debug_hurtbox_cross_v != null and is_instance_valid(hitbox_debug_hurtbox_cross_v):
		hitbox_debug_hurtbox_cross_v.points = PackedVector2Array([Vector2(0.0, -radius), Vector2(0.0, radius)])
	var shield_active := is_block_shield_active()
	if hitbox_debug_shield_ring != null and is_instance_valid(hitbox_debug_shield_ring):
		hitbox_debug_shield_ring.visible = shield_active
	if hitbox_debug_shield_box != null and is_instance_valid(hitbox_debug_shield_box):
		hitbox_debug_shield_box.visible = shield_active
	if not shield_active:
		return
	var shield_center := get_block_shield_center_global()
	var local_shield_center := shield_center - hitbox_debug_overlay_root.global_position
	var half_extents := get_block_shield_half_extents()
	if hitbox_debug_shield_ring != null and is_instance_valid(hitbox_debug_shield_ring):
		hitbox_debug_shield_ring.points = _build_ellipse_line_points(local_shield_center, half_extents, 28)
	if hitbox_debug_shield_box != null and is_instance_valid(hitbox_debug_shield_box):
		var hx := maxf(1.0, half_extents.x)
		var hy := maxf(1.0, half_extents.y)
		hitbox_debug_shield_box.points = PackedVector2Array([
			local_shield_center + Vector2(-hx, -hy),
			local_shield_center + Vector2(hx, -hy),
			local_shield_center + Vector2(hx, hy),
			local_shield_center + Vector2(-hx, hy)
		])


func _build_ellipse_line_points(center: Vector2, half_extents: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_segments := maxi(10, segments)
	var half_width := maxf(1.0, half_extents.x)
	var half_height := maxf(1.0, half_extents.y)
	for i in range(safe_segments):
		var angle := (TAU * float(i)) / float(safe_segments)
		points.append(center + Vector2(cos(angle) * half_width, sin(angle) * half_height))
	return points


func _is_point_inside_block_shield_ellipse(world_point: Vector2, half_extents: Vector2) -> bool:
	var center := get_block_shield_center_global()
	var local := world_point - center
	var half_width := maxf(1.0, half_extents.x)
	var half_height := maxf(1.0, half_extents.y)
	var norm_x := local.x / half_width
	var norm_y := local.y / half_height
	return (norm_x * norm_x) + (norm_y * norm_y) <= 1.0


func is_point_inside_block_shield(world_point: Vector2) -> bool:
	if not is_block_shield_active():
		return false
	return _is_point_inside_block_shield_ellipse(world_point, get_block_shield_half_extents())


func is_segment_intersecting_block_shield(world_start: Vector2, world_end: Vector2, padding: float = 0.0) -> bool:
	if not is_block_shield_active():
		return false
	var padded_extents := get_block_shield_half_extents() + Vector2.ONE * maxf(0.0, padding)
	if _is_point_inside_block_shield_ellipse(world_start, padded_extents):
		return true
	if _is_point_inside_block_shield_ellipse(world_end, padded_extents):
		return true
	var distance := world_start.distance_to(world_end)
	var sample_spacing := maxf(6.0, minf(padded_extents.x, padded_extents.y) * 0.35)
	var samples := clampi(int(ceil(distance / sample_spacing)), 6, 24)
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var sample_point := world_start.lerp(world_end, t)
		if _is_point_inside_block_shield_ellipse(sample_point, padded_extents):
			return true
	return false


func _build_circle_line_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var safe_segments := maxi(10, segments)
	var points := PackedVector2Array()
	for i in range(safe_segments):
		var angle := (TAU * float(i)) / float(safe_segments)
		points.append(center + (Vector2.RIGHT.rotated(angle) * radius))
	return points


func _setup_block_shield_effect_sprite() -> void:
	if block_shield_effect_sprite != null and is_instance_valid(block_shield_effect_sprite):
		return
	var effect_sprite := AnimatedSprite2D.new()
	effect_sprite.name = "BlockShieldEffect"
	effect_sprite.centered = true
	effect_sprite.z_index = block_indicator.z_index
	effect_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect_sprite.visible = false
	effect_sprite.sprite_frames = _get_block_shield_effect_frames()
	add_child(effect_sprite)
	block_shield_effect_sprite = effect_sprite


func _get_block_shield_effect_frames() -> SpriteFrames:
	if block_shield_effect_frames != null:
		return block_shield_effect_frames
	var sheet_texture := _get_block_shield_effect_texture()
	var frames := SpriteFrames.new()
	frames.add_animation("shield")
	frames.set_animation_speed("shield", BLOCK_SHIELD_EFFECT_ANIM_FPS)
	frames.set_animation_loop("shield", true)
	if sheet_texture == null:
		block_shield_effect_frames = frames
		return block_shield_effect_frames
	for row in range(BLOCK_SHIELD_EFFECT_FRAME_ROWS):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_texture
		atlas.region = Rect2i(0, row * BLOCK_SHIELD_EFFECT_FRAME_SIZE.y, BLOCK_SHIELD_EFFECT_FRAME_SIZE.x, BLOCK_SHIELD_EFFECT_FRAME_SIZE.y)
		frames.add_frame("shield", atlas)
	block_shield_effect_frames = frames
	return block_shield_effect_frames


func _get_block_shield_effect_texture() -> Texture2D:
	if block_shield_effect_texture != null:
		return block_shield_effect_texture
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(BLOCK_SHIELD_EFFECT_SHEET_PATH))
	if err != OK:
		push_warning("Failed to load block shield effect sprite sheet at %s (error %s)." % [BLOCK_SHIELD_EFFECT_SHEET_PATH, err])
		return null
	block_shield_effect_texture = ImageTexture.create_from_image(image)
	return block_shield_effect_texture


func _setup_harpoon_visuals() -> void:
	if harpoon_tether_line == null or not is_instance_valid(harpoon_tether_line):
		var tether := Line2D.new()
		tether.name = "HarpoonTether"
		tether.visible = false
		tether.width = 4.8
		tether.default_color = Color(0.12, 0.34, 0.42, 0.94)
		tether.begin_cap_mode = Line2D.LINE_CAP_ROUND
		tether.end_cap_mode = Line2D.LINE_CAP_ROUND
		tether.z_index = 228
		tether.antialiased = true
		add_child(tether)
		harpoon_tether_line = tether
	if harpoon_tether_glow_line == null or not is_instance_valid(harpoon_tether_glow_line):
		var tether_glow := Line2D.new()
		tether_glow.name = "HarpoonTetherGlow"
		tether_glow.visible = false
		tether_glow.width = 2.2
		tether_glow.default_color = Color(0.66, 0.98, 1.0, 0.96)
		tether_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
		tether_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
		tether_glow.z_index = 229
		tether_glow.antialiased = true
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
			Vector2(20.0, 0.0),
			Vector2(6.0, -5.0),
			Vector2(-6.0, -5.0),
			Vector2(-10.0, -10.0),
			Vector2(-14.0, -8.0),
			Vector2(-10.0, -2.0),
			Vector2(-18.0, 0.0),
			Vector2(-10.0, 2.0),
			Vector2(-14.0, 8.0),
			Vector2(-10.0, 10.0),
			Vector2(-6.0, 5.0),
			Vector2(6.0, 5.0)
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


func _update_block_indicator_visual() -> void:
	block_indicator.rotation = 0.0
	block_indicator.visible = false
	if not _is_block_pose_ready():
		if block_shield_effect_sprite != null and is_instance_valid(block_shield_effect_sprite):
			block_shield_effect_sprite.visible = false
			block_shield_effect_sprite.stop()
		return

	var pulse := 0.5 + (sin(anim_time * maxf(0.1, block_shield_pulse_speed)) * 0.5)
	var radius := maxf(8.0, block_shield_radius * lerpf(0.96, 1.04, pulse))
	var center_local := get_block_shield_visual_center_local()
	if block_shield_effect_sprite == null or not is_instance_valid(block_shield_effect_sprite):
		_setup_block_shield_effect_sprite()
	if block_shield_effect_sprite == null or not is_instance_valid(block_shield_effect_sprite):
		return
	var frame_extent := float(maxi(BLOCK_SHIELD_EFFECT_FRAME_SIZE.x, BLOCK_SHIELD_EFFECT_FRAME_SIZE.y))
	var base_scale := (radius * 2.0) / maxf(1.0, frame_extent)
	block_shield_effect_sprite.visible = true
	block_shield_effect_sprite.position = center_local
	block_shield_effect_sprite.flip_h = facing_direction.x < 0.0
	block_shield_effect_sprite.scale = Vector2.ONE * (base_scale * 1.3)
	block_shield_effect_sprite.modulate = Color(0.48, 0.86, 1.0, lerpf(0.42, 0.74, pulse))
	if block_shield_effect_sprite.sprite_frames != null and block_shield_effect_sprite.sprite_frames.has_animation("shield"):
		if block_shield_effect_sprite.animation != "shield" or not block_shield_effect_sprite.is_playing():
			block_shield_effect_sprite.play("shield")


func _emit_cooldown_state() -> void:
	cooldowns_changed.emit({
		"basic": basic_attack_cooldown_left,
		"ability_1": ability_1_cooldown_left,
		"ability_2": ability_2_cooldown_left,
		"roll": roll_cooldown_left,
		"block_active": is_blocking,
		"counter_unlocked": _is_counter_strike_unlocked(),
		"counter_ready": counter_strike_available,
		"counter_window_left": counter_strike_window_left,
		"harpoon_charging": harpoon_charge_active,
		"harpoon_charge_ratio": _get_harpoon_charge_ratio_from_time(harpoon_charge_time) if harpoon_charge_active else 0.0,
		"charge_ratio": _get_charge_ratio(),
		"combat_state": combat_state_name,
		"equipped_sword_id": equipped_sword_id,
		"equipped_sword_name": get_equipped_sword_name(),
		"equipped_shield_id": equipped_shield_id,
		"equipped_shield_name": get_equipped_shield_name()
	})


func _die() -> void:
	is_dead = true
	is_blocking = false
	perfect_block_window_left = 0.0
	counter_strike_available = false
	counter_strike_window_left = 0.0
	is_rolling = false
	is_invulnerable = false
	heal_flash_left = 0.0
	_cancel_harpoon_state()
	_cancel_charge_attack()
	_cancel_charge_attack_recovery()
	_reset_basic_combo_state()
	knockback_velocity = Vector2.ZERO
	lunge_time_left = 0.0
	lunge_total_duration = 0.0
	lunge_strike_applied = false
	ally_dash_block_grace_left = 0.0
	instant_dash_block_latched = false
	charge_lunge_velocity = Vector2.ZERO
	hitstop_left = 0.0
	velocity = Vector2.ZERO
	weapon_trail.visible = false
	slash_effect.visible = false
	block_indicator.visible = false
	if block_shield_effect_sprite != null and is_instance_valid(block_shield_effect_sprite):
		block_shield_effect_sprite.visible = false
		block_shield_effect_sprite.stop()
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
	_set_combat_state(CombatState.IDLE_MOVE)
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
		charge_strength = 1.0 - (lunge_time_left / maxf(0.01, lunge_total_duration))
	var charged_attack_energy := _get_scaled_charge_ratio() if is_charging_attack else 0.0
	if charge_release_windup_left > 0.0:
		charged_attack_energy = maxf(charged_attack_energy, 1.0 - (charge_release_windup_left / maxf(0.01, charge_windup_duration)))
	if charge_attack_active_left > 0.0:
		charged_attack_energy = maxf(charged_attack_energy, 1.0)
	var combat_energy := clampf((anticipation * 0.45) + (attack_swing * 0.5) + (windup_progress * 0.55) + (charge_strength * 0.65) + (charged_attack_energy * 0.8), 0.0, 1.0)
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
	elif hurt_anim_left > 0.0 or stun_left > 0.0:
		action_key = "hurt"
	elif is_rolling:
		action_key = "roll"
	elif lunge_time_left > 0.0:
		action_key = "run"
	elif is_charging_attack or charge_release_windup_left > 0.0 or charge_attack_active_left > 0.0 or charge_attack_recovery_left > 0.0 or attack_anim_left > 0.0 or attack_windup_left > 0.0:
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
		if is_charging_attack:
			frame_index = 0
		elif charge_release_windup_left > 0.0:
			frame_index = 0
		elif charge_attack_active_left > 0.0:
			var active_progress := 1.0 - (charge_attack_active_left / maxf(0.01, charge_active_duration))
			frame_index = mini(int(floor(clampf(active_progress, 0.0, 1.0) * float(frame_count))), frame_count - 1)
		elif charge_attack_recovery_left > 0.0:
			frame_index = frame_count - 1
		elif attack_windup_left > 0.0:
			frame_index = 0
		else:
			var attack_progress := 1.0 - (attack_anim_left / maxf(0.01, attack_anim_total))
			frame_index = mini(int(floor(clampf(attack_progress, 0.0, 1.0) * float(frame_count))), frame_count - 1)
	elif action_key == "block":
		var hold_frame := clampi(PLAYER_BLOCK_HOLD_FRAME_INDEX, 0, frame_count - 1)
		frame_index = mini(int(floor(player_sprite_anim_time)), hold_frame)
	elif action_key == "lunge":
		var lunge_progress := 1.0 - (lunge_time_left / maxf(0.01, lunge_total_duration))
		frame_index = mini(int(floor(clampf(lunge_progress, 0.0, 1.0) * float(frame_count))), frame_count - 1)
	elif action_key == "roll":
		frame_index = mini(int(floor(player_sprite_anim_time)), frame_count - 1)
	elif action_key == "hurt":
		frame_index = mini(int(floor(player_sprite_anim_time)), frame_count - 1)
	else:
		frame_index = int(floor(player_sprite_anim_time)) % frame_count
	var source_column := int(frame_columns[frame_index]) if has_custom_columns else frame_index
	character_sprite.frame_coords = Vector2i(source_column, row)
	if hit_flash_left > 0.0:
		character_sprite.modulate = Color(1.0, 0.72, 0.72, 1.0)
	elif heal_flash_left > 0.0:
		var heal_strength := clampf(heal_flash_left / maxf(0.01, heal_flash_duration), 0.0, 1.0)
		character_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(Color(0.72, 1.0, 0.72, 1.0), minf(0.82, heal_strength))
	else:
		character_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if action_key == "attack" and not is_charging_attack and attack_windup_left <= 0.0 and charge_release_windup_left <= 0.0 and charge_attack_active_left <= 0.0 and charge_attack_recovery_left <= 0.0 and frame_index >= frame_count - 1:
		_apply_queued_melee_hit()
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


func _spawn_damage_popup(world_position: Vector2, damage_amount: float) -> void:
	if not damage_popup_enabled:
		return
	if damage_amount <= 0.0:
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
	label.z_index = 260
	label.text = str(int(round(damage_amount)))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.scale = Vector2.ONE * maxf(0.1, damage_popup_scale)

	var label_settings := LabelSettings.new()
	label_settings.font_size = maxi(8, damage_popup_font_size)
	label_settings.font_color = Color(1.0, 0.88, 0.34, 0.98)
	label_settings.outline_size = maxi(0, damage_popup_outline_size)
	label_settings.outline_color = Color(0.08, 0.05, 0.02, 0.95)
	label.label_settings = label_settings
	scene_root.add_child(label)

	damage_popup_sequence += 1
	var spread_step := float((damage_popup_sequence % 5) - 2)
	var x_offset := spread_step * maxf(0.0, damage_popup_x_spread)
	var rise := maxf(6.0, damage_popup_rise_distance)
	var duration := maxf(0.06, damage_popup_duration)

	var tween := create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(x_offset, -rise), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)


func _spawn_combat_text_popup(world_position: Vector2, text: String, text_color: Color, duration: float = 0.45) -> void:
	if text.is_empty():
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
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.scale = Vector2.ONE * maxf(0.1, damage_popup_scale * 0.95)

	var label_settings := LabelSettings.new()
	label_settings.font_size = maxi(8, damage_popup_font_size - 1)
	label_settings.font_color = text_color
	label_settings.outline_size = maxi(0, damage_popup_outline_size)
	label_settings.outline_color = Color(0.06, 0.08, 0.12, 0.96)
	label.label_settings = label_settings
	scene_root.add_child(label)

	var rise := maxf(8.0, damage_popup_rise_distance * 0.62)
	var popup_duration := maxf(0.08, duration)
	var tween := create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0.0, -rise), popup_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, popup_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
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

extends Node2D
class_name FriendlyHealer

signal health_changed(current: float, maximum: float)
signal died(healer: FriendlyHealer)

enum HealerAIState {
	IDLE_SUPPORT,
	REPOSITIONING,
	HEALING,
	SHIELDING,
	ATTACKING,
	BREATH_STACK
}

const HEALER_AI_STATE_NAMES: Dictionary = {
	HealerAIState.IDLE_SUPPORT: "IDLE_SUPPORT",
	HealerAIState.REPOSITIONING: "REPOSITIONING",
	HealerAIState.HEALING: "HEALING",
	HealerAIState.SHIELDING: "SHIELDING",
	HealerAIState.ATTACKING: "ATTACKING",
	HealerAIState.BREATH_STACK: "BREATH_STACK"
}

enum CastAction {
	NONE,
	QUICK_HEAL,
	PROTECTIVE_SHIELD,
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
@export var cast_frame_to_heal: int = 4
@export var reacquire_retry_interval: float = 0.3
@export var react_heal_delay: float = 0.18
@export var emergency_cast_on_damage: bool = true
@export var shield_cooldown: float = 7.5
@export var shield_duration: float = 2.1
@export var shield_damage_multiplier: float = 0.35
@export var shield_cast_range: float = 164.0
@export var move_speed: float = 100.3
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
@export var move_facing_threshold: float = 20.0
@export var facing_flip_deadzone: float = 10.0
@export var pixel_snap_movement: bool = false
@export var arena_padding: float = 26.0
@export var tidal_wave_enabled: bool = true
@export var basic_heal_cooldown: float = 1.5
@export var basic_heal_range: float = 132.0
@export var basic_heal_range_buffer: float = 10.0
@export var light_bolt_enabled: bool = true
@export var light_bolt_damage: float = 7.5
@export var light_bolt_cooldown: float = 1.9
@export var light_bolt_range: float = 208.0
@export var light_bolt_stun_duration: float = 0.1
@export var light_bolt_hitstop_duration: float = 0.045
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
@export var max_health: float = 90.0
@export var health_bar_width: float = 54.0
@export var health_bar_thickness: float = 5.0
@export var health_bar_y_offset: float = -62.0
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
	"cast": 2
}
const ANIM_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"run": [0, 1, 2, 3],
	"cast": [0, 1, 2, 3, 4, 5, 6]
}
const ANIM_FPS: Dictionary = {
	"idle": 6.0,
	"run": 8.8,
	"cast": 10.0
}

var player: Player = null
var heal_timer_left: float = 0.0
var idle_anim_time: float = 0.0
var run_anim_time: float = 0.0
var cast_anim_time: float = 0.0
var is_casting: bool = false
var heal_applied_this_cast: bool = false
var basic_heal_cooldown_left: float = 0.0
var tidal_wave_cooldown_left: float = 0.0
var shield_cooldown_left: float = 0.0
var light_bolt_cooldown_left: float = 0.0
var cast_debug_logging_enabled: bool = false
var active_shield_target_id: int = -1
var active_shield_left: float = 0.0
var reacquire_left: float = 0.0
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
var stun_left: float = 0.0
var hit_flash_left: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var dead: bool = false
var breath_threat_snapshot: Dictionary = {}
var breath_safe_indicator_left: float = 0.0
var breath_safe_indicator: Line2D = null
var breath_was_safe: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("friendly_npcs")
	if _is_autoplay_requested():
		rng.seed = 2026
	else:
		rng.randomize()
	cast_debug_logging_enabled = _is_env_flag_enabled("HEALER_CAST_DEBUG")
	orbit_phase = 0.0
	heal_timer_left = _next_heal_interval() * 0.45
	basic_heal_cooldown_left = 0.0
	tidal_wave_cooldown_left = 0.0
	shield_cooldown_left = 0.0
	light_bolt_cooldown_left = 0.0
	active_shield_target_id = -1
	active_shield_left = 0.0
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
	_setup_breath_safe_indicator()
	_prepare_frame_alignment()
	_set_anim_frame("idle", 0)
	current_health = maxf(1.0, max_health)
	_setup_health_bar()
	_update_health_bar()
	health_changed.emit(current_health, max_health)


func _exit_tree() -> void:
	_unbind_player_signal()
	_clear_tidal_waves()
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()


func _physics_process(delta: float) -> void:
	if dead:
		return
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	breath_safe_indicator_left = maxf(0.0, breath_safe_indicator_left - delta)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, maxf(0.0, hit_knockback_decay) * delta)
	if knockback_velocity.length_squared() > 0.0001:
		position += knockback_velocity * delta
		position = _clamp_to_bounds(position)
		if pixel_snap_movement:
			position = position.round()
	if is_instance_valid(sprite):
		sprite.modulate = Color(1.0, 0.72, 0.72, 1.0) if hit_flash_left > 0.0 else Color(1.0, 1.0, 1.0, 1.0)
	if not is_instance_valid(player):
		reacquire_left = maxf(0.0, reacquire_left - delta)
		if reacquire_left <= 0.0:
			_acquire_player()
			reacquire_left = reacquire_retry_interval
	_refresh_breath_threat()
	if _is_breath_threat_active() and is_casting:
		_cancel_cast_for_breath()
	var primary_enemy := _find_primary_enemy()
	_update_healer_ai_state(delta, primary_enemy)
	_update_tactical_positioning(delta)
	_apply_miniboss_soft_separation(delta)
	_update_facing()
	_update_breath_safe_indicator()
	_update_health_bar()
	basic_heal_cooldown_left = maxf(0.0, basic_heal_cooldown_left - delta)
	tidal_wave_cooldown_left = maxf(0.0, tidal_wave_cooldown_left - delta)
	shield_cooldown_left = maxf(0.0, shield_cooldown_left - delta)
	light_bolt_cooldown_left = maxf(0.0, light_bolt_cooldown_left - delta)
	active_shield_left = maxf(0.0, active_shield_left - delta)
	if active_shield_left <= 0.0:
		active_shield_target_id = -1
	_update_tidal_waves(delta)

	if is_casting:
		_tick_cast(delta)
		return
	if _is_breath_threat_active():
		return

	if _is_tactically_moving():
		_tick_run(delta)
	else:
		_tick_idle(delta)
	if _find_best_heal_target() != null:
		heal_timer_left = minf(heal_timer_left, react_heal_delay)
	heal_timer_left = maxf(0.0, heal_timer_left - delta)
	if heal_timer_left > 0.0:
		return
	_try_begin_ai_cast()


func _acquire_player() -> void:
	_bind_player(get_tree().get_first_node_in_group("player") as Player)


func set_player(target_player: Player) -> void:
	_bind_player(target_player)
	if _player_needs_healing():
		heal_timer_left = minf(heal_timer_left, react_heal_delay)


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


func _cancel_cast_for_breath() -> void:
	is_casting = false
	cast_anim_time = 0.0
	heal_applied_this_cast = false
	pending_cast_action = CastAction.NONE
	pending_cast_target = null
	_set_anim_frame("idle", 0)
	heal_timer_left = minf(heal_timer_left, react_heal_delay)


func _update_healer_ai_state(delta: float, primary_enemy: EnemyBase) -> void:
	healer_ai_decision_left = maxf(0.0, healer_ai_decision_left - delta)
	if healer_ai_decision_left > 0.0:
		return
	healer_ai_decision_left = maxf(0.05, ai_decision_interval)
	if _is_breath_threat_active():
		_set_healer_ai_state(HealerAIState.BREATH_STACK, primary_enemy if primary_enemy != null else player)
		return
	var marked_target := _find_marked_ally_under_threat()
	if marked_target != null:
		_set_healer_ai_state(HealerAIState.SHIELDING, marked_target)
		return

	var heal_target := _find_best_heal_target()
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


func _find_marked_ally_under_threat() -> Node2D:
	var best_target: Node2D = null
	var best_distance_sq := INF
	var best_enemy_id := INF
	var missing_health_threshold := maxf(0.01, min_missing_health_to_heal)
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
		if not _is_valid_support_target(marked_target):
			continue
		if _get_missing_health(marked_target) < missing_health_threshold:
			continue
		var distance_sq := global_position.distance_squared_to(marked_target.global_position)
		var enemy_id := enemy.get_instance_id()
		if best_target == null or distance_sq < best_distance_sq or (is_equal_approx(distance_sq, best_distance_sq) and enemy_id < best_enemy_id):
			best_target = marked_target
			best_distance_sq = distance_sq
			best_enemy_id = enemy_id
	return best_target


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
	var min_band := maxf(min_distance_to_player, healer_follow_min_band)
	var max_band := maxf(min_band + 8.0, healer_follow_max_band)
	if distance_to_player < min_band or distance_to_player > max_band:
		return true
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		return false
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
			var heal_target := _resolve_heal_target(healer_ai_target)
			var wave_attack_target := _find_healer_attack_target()
			if _should_cast_tidal_wave(wave_attack_target):
				_queue_cast_action(CastAction.TIDAL_WAVE, wave_attack_target, 0.08)
				return
			if basic_heal_cooldown_left <= 0.0:
				if _can_cast_basic_heal_on_target(heal_target):
					_queue_cast_action(CastAction.QUICK_HEAL, heal_target, 0.08)
				else:
					heal_timer_left = 0.08
				return
			heal_timer_left = maxf(0.08, basic_heal_cooldown_left)
			return
		HealerAIState.SHIELDING:
			var shield_target := _resolve_support_target(healer_ai_target)
			var missing_health_threshold := maxf(0.01, min_missing_health_to_heal)
			if _get_missing_health(shield_target) < missing_health_threshold:
				heal_timer_left = 0.08
				return
			if shield_cooldown_left <= 0.0 and _can_cast_shield_on_target(shield_target):
				_queue_cast_action(CastAction.PROTECTIVE_SHIELD, shield_target, 0.08)
				return
			heal_timer_left = maxf(0.08, shield_cooldown_left)
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
	var fallback_heal_target := _find_best_heal_target()
	if basic_heal_cooldown_left <= 0.0 and _can_cast_basic_heal_on_target(fallback_heal_target):
		_queue_cast_action(CastAction.QUICK_HEAL, fallback_heal_target, 0.14)
		return
	if _is_healing_ability_ready():
		heal_timer_left = 0.22
	else:
		heal_timer_left = maxf(0.1, _time_until_next_healing_ability_ready())


func _queue_cast_action(action: CastAction, target: Node2D, next_timer: float) -> void:
	pending_cast_action = action
	pending_cast_target = target
	_log_cast_event("QUEUE", action, target)
	if cast_debug_logging_enabled and action == CastAction.TIDAL_WAVE:
		var evaluation := _evaluate_tidal_wave_targets(target)
		print("[HEALER_CAST] TIDAL_WAVE_EVAL target=%s enemies=%d allies=%d injured_allies=%d target_in_lane=%s dir=%.0f" % [
			target.name if target != null and is_instance_valid(target) else "None",
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
	_set_anim_frame("cast", 0)
	_spawn_cast_flash(global_position + Vector2(0.0, -18.0))


func _tick_cast(delta: float) -> void:
	var fps := float(ANIM_FPS.get("cast", 12.0))
	var frame_count := _anim_frame_count("cast")
	cast_anim_time += delta * fps

	var frame_index := mini(int(floor(cast_anim_time)), frame_count - 1)
	_set_anim_frame("cast", frame_index)

	if not heal_applied_this_cast and frame_index >= cast_frame_to_heal:
		heal_applied_this_cast = true
		_trigger_healing_ability()

	if cast_anim_time < float(frame_count):
		return

	is_casting = false
	cast_anim_time = 0.0
	heal_timer_left = minf(_next_heal_interval() * 0.2, react_heal_delay)
	_set_anim_frame("idle", 0)


func _player_needs_healing() -> bool:
	if not is_instance_valid(player):
		return false
	return player.needs_healing(heal_threshold_ratio)


func _is_valid_heal_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("needs_healing"):
		return false
	if not target.has_method("receive_heal"):
		return false
	if _is_marked_target_waiting_for_damage(target):
		return false
	if not bool(target.call("needs_healing", heal_threshold_ratio)):
		return false
	return _get_missing_health(target) >= maxf(0.01, min_missing_health_to_heal)


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


func _find_best_heal_target() -> Node2D:
	var best_target: Node2D = null
	var best_health_ratio := INF
	var best_id := INF
	var candidates: Array[Node2D] = []
	if player != null:
		candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if not _is_valid_heal_target(candidate):
			continue
		candidates.append(candidate)
	for candidate in candidates:
		if not _is_valid_heal_target(candidate):
			continue
		var candidate_max_health := maxf(1.0, float(candidate.get("max_health")))
		var candidate_health := clampf(float(candidate.get("current_health")), 0.0, candidate_max_health)
		var ratio := candidate_health / candidate_max_health
		var candidate_id := candidate.get_instance_id()
		if best_target == null or ratio < best_health_ratio - 0.0001 or (is_equal_approx(ratio, best_health_ratio) and candidate_id < best_id):
			best_target = candidate
			best_health_ratio = ratio
			best_id = candidate_id
	return best_target


func _resolve_heal_target(preferred_target: Node2D = null) -> Node2D:
	if _is_valid_heal_target(preferred_target):
		return preferred_target
	var state_target := healer_ai_target
	if _is_valid_heal_target(state_target):
		return state_target
	var fallback_target := _find_best_heal_target()
	if _is_valid_heal_target(fallback_target):
		return fallback_target
	return null


func _is_in_basic_heal_range(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= maxf(16.0, basic_heal_range)


func _can_cast_basic_heal_on_target(target: Node2D) -> bool:
	var resolved_target := _resolve_heal_target(target)
	if resolved_target == null:
		return false
	return _is_in_basic_heal_range(resolved_target)


func _resolve_support_target(preferred_target: Node2D = null) -> Node2D:
	if _is_valid_support_target(preferred_target):
		return preferred_target
	return _find_marked_ally_under_threat()


func _resolve_attack_target(preferred_target: Node2D = null) -> EnemyBase:
	var preferred_enemy := preferred_target as EnemyBase
	if preferred_enemy != null and is_instance_valid(preferred_enemy) and not preferred_enemy.dead and not _is_enemy_shadow_feared(preferred_enemy):
		return preferred_enemy
	return _find_healer_attack_target()


func _can_cast_shield_on_target(target: Node2D) -> bool:
	var resolved_target := _resolve_support_target(target)
	if resolved_target == null:
		return false
	return global_position.distance_squared_to(resolved_target.global_position) <= shield_cast_range * shield_cast_range


func _can_cast_light_bolt_on_target(target: Node2D) -> bool:
	var resolved_target := _resolve_attack_target(target)
	if resolved_target == null:
		return false
	if _is_enemy_shadow_feared(resolved_target):
		return false
	return global_position.distance_squared_to(resolved_target.global_position) <= light_bolt_range * light_bolt_range


func _can_cast_tidal_wave_on_target(target: Node2D) -> bool:
	if not tidal_wave_enabled:
		return false
	var resolved_target := _resolve_attack_target(target)
	if resolved_target == null:
		return false
	var evaluation := _evaluate_tidal_wave_targets(resolved_target)
	if int(evaluation.get("enemy_hits", 0)) <= 0:
		return false
	if int(evaluation.get("injured_allies", 0)) <= 0:
		return false
	if not bool(evaluation.get("target_in_lane", false)):
		return false
	return true


func _should_cast_tidal_wave(target: Node2D) -> bool:
	if not tidal_wave_enabled or tidal_wave_cooldown_left > 0.0:
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
	if tidal_wave_cooldown_left > 0.3:
		return false
	if _resolve_attack_target(target) == null:
		return false
	return _find_best_tidal_wave_heal_target(target) != null


func _apply_heal(target: Node2D = null) -> bool:
	var heal_target := _resolve_heal_target(target)
	if heal_target == null:
		return false
	if not _is_valid_heal_target(heal_target):
		return false
	if not _is_in_basic_heal_range(heal_target):
		return false

	var target_world := heal_target.global_position + Vector2(0.0, -16.0)
	var healed := bool(heal_target.call("receive_heal", heal_amount))
	if not healed:
		return false
	_spawn_heal_beam(global_position + Vector2(0.0, -18.0), target_world, healed)
	_spawn_heal_burst(target_world, healed)
	return healed


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
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	return true


func receive_hit(amount: float, source_position: Vector2, _guard_break: bool = false, stun_duration: float = 0.0, knockback_scale: float = 1.0) -> bool:
	if dead:
		return false
	if amount <= 0.0:
		return false
	if is_instance_valid(player) and player.is_point_inside_block_shield(global_position):
		_spawn_heal_burst(global_position + Vector2(0.0, -14.0), true)
		return false

	var knockback_direction := (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	knockback_velocity = knockback_direction * maxf(0.0, hit_knockback_speed) * maxf(0.1, knockback_scale)
	stun_left = maxf(stun_left, maxf(hit_stun_duration, stun_duration))
	hit_flash_left = 0.12
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	if is_casting:
		is_casting = false
		cast_anim_time = 0.0
		heal_applied_this_cast = false
	_spawn_heal_burst(global_position + Vector2(0.0, -14.0), false)
	if current_health <= 0.0:
		_die()
	return true


func get_shield_damage_multiplier_for(target: Node2D) -> float:
	if active_shield_left <= 0.0:
		return 1.0
	if target == null or not is_instance_valid(target):
		return 1.0
	if target.get_instance_id() != active_shield_target_id:
		return 1.0
	return clampf(shield_damage_multiplier, 0.05, 1.0)


func _apply_protective_shield(target: Node2D) -> bool:
	var shield_target := _resolve_support_target(target)
	if shield_target == null:
		return false
	if not _can_cast_shield_on_target(shield_target):
		return false
	active_shield_target_id = shield_target.get_instance_id()
	active_shield_left = maxf(0.1, shield_duration)
	shield_cooldown_left = maxf(0.0, shield_cooldown)
	var burst_position := shield_target.global_position + Vector2(0.0, -14.0)
	_spawn_heal_burst(burst_position, false)
	_spawn_heal_beam(global_position + Vector2(0.0, -16.0), burst_position, false)
	return true


func _apply_light_bolt(target: Node2D) -> bool:
	var bolt_target := _resolve_attack_target(target)
	if bolt_target == null:
		return false
	if _is_enemy_shadow_feared(bolt_target):
		return false
	if not _can_cast_light_bolt_on_target(bolt_target):
		return false
	var hit_origin := global_position + Vector2(0.0, -16.0)
	var hit_position := bolt_target.global_position + Vector2(0.0, -12.0)
	_spawn_heal_beam(hit_origin, hit_position, false)
	_spawn_heal_burst(hit_position, false)
	var landed := bolt_target.receive_hit(light_bolt_damage, global_position, light_bolt_stun_duration, true, 0.88)
	if landed and bolt_target.has_method("apply_hitstop"):
		bolt_target.apply_hitstop(maxf(0.0, light_bolt_hitstop_duration))
	light_bolt_cooldown_left = maxf(0.0, light_bolt_cooldown)
	return landed


func _trigger_healing_ability() -> void:
	var cast_target := pending_cast_target
	_log_cast_event("RESOLVE", pending_cast_action, cast_target)
	match pending_cast_action:
		CastAction.QUICK_HEAL:
			if basic_heal_cooldown_left <= 0.0 and _apply_heal(cast_target):
				basic_heal_cooldown_left = maxf(0.0, basic_heal_cooldown)
		CastAction.PROTECTIVE_SHIELD:
			if shield_cooldown_left <= 0.0:
				_apply_protective_shield(cast_target)
		CastAction.TIDAL_WAVE:
			if tidal_wave_enabled and tidal_wave_cooldown_left <= 0.0:
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
	if shield_cooldown_left <= 0.0:
		return true
	if tidal_wave_enabled and tidal_wave_cooldown_left <= 0.0:
		return true
	if light_bolt_enabled and light_bolt_cooldown_left <= 0.0:
		return true
	return false


func _time_until_next_healing_ability_ready() -> float:
	var next_ready := maxf(0.0, basic_heal_cooldown_left)
	next_ready = minf(next_ready, maxf(0.0, shield_cooldown_left))
	if tidal_wave_enabled:
		next_ready = minf(next_ready, maxf(0.0, tidal_wave_cooldown_left))
	if light_bolt_enabled:
		next_ready = minf(next_ready, maxf(0.0, light_bolt_cooldown_left))
	return maxf(0.0, next_ready)


func _update_facing() -> void:
	if not is_instance_valid(sprite):
		return
	if not is_instance_valid(player):
		return
	var move_threshold := maxf(0.0, move_facing_threshold)
	if absf(move_velocity.x) >= move_threshold:
		facing_left = move_velocity.x < 0.0
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


func _update_tactical_positioning(delta: float) -> void:
	if not is_instance_valid(player):
		move_velocity = move_velocity.move_toward(Vector2.ZERO, movement_deceleration * delta)
		return
	if stun_left > 0.0:
		move_velocity = move_velocity.move_toward(Vector2.ZERO, movement_deceleration * delta)
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
	elif healer_ai_state == HealerAIState.SHIELDING:
		var shield_target := _resolve_support_target(healer_ai_target)
		if shield_target != null and is_instance_valid(shield_target):
			var shield_target_position := _get_position_in_actor_space(shield_target)
			var to_target := shield_target_position - position
			var desired_cast_distance := clampf(maxf(18.0, shield_cast_range - 20.0), 18.0, maxf(28.0, shield_cast_range))
			if to_target.length() > desired_cast_distance:
				desired_position = _clamp_to_bounds(shield_target_position - (to_target.normalized() * desired_cast_distance))
			else:
				desired_position = _clamp_to_bounds(shield_target_position + Vector2(-14.0, 10.0))
	elif healer_ai_state == HealerAIState.HEALING:
		var heal_target := _resolve_heal_target(healer_ai_target)
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
	var effective_speed := move_speed
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
			var quantized_direction := _quantize_player_like_direction(direct_to_target)
			if quantized_direction.length_squared() <= 0.0001:
				move_velocity = Vector2.ZERO
			else:
				move_velocity = quantized_direction * speed_cap
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
		desired_offset = Vector2(
			(desired_side * ((follow_distance * 0.72) + (orbit_depth * 0.3))) + (orbit_lateral * 0.55),
			follow_vertical_bias + (sin(orbit_phase * 0.65) * 4.0)
		)

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
	wave_node.rotation = 0.0 if wave_direction.x >= 0.0 else PI
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
	end_sprite.rotation = 0.0 if wave_direction.x >= 0.0 else PI
	end_sprite.z_index = 236
	end_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	end_sprite.centered = true
	end_sprite.sprite_frames = sprite_frames
	end_sprite.animation = "end"
	end_sprite.scale = base_scale
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
		var healed := bool(friendly_target.call("receive_heal", tidal_wave_heal_amount))
		healed_ids[friendly_id] = true
		if healed:
			var burst_position := friendly_target.global_position + Vector2(0.0, -16.0)
			_spawn_heal_burst(burst_position, true)
			_spawn_heal_beam(wave_center, burst_position, true)

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
		var landed := enemy.receive_hit(tidal_wave_damage, wave_center, tidal_wave_stun_duration, true, tidal_wave_knockback_scale)
		if landed:
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
	if is_instance_valid(player):
		candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate != self and not _is_valid_support_target(candidate):
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
	if is_instance_valid(player):
		ally_candidates.append(player)
	for node in get_tree().get_nodes_in_group("friendly_npcs"):
		var candidate := node as Node2D
		if candidate == null or not is_instance_valid(candidate):
			continue
		if candidate != self and not _is_valid_support_target(candidate):
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
	is_casting = false
	if is_instance_valid(health_bar_root):
		health_bar_root.queue_free()
		health_bar_root = null
		health_bar_background = null
		health_bar_fill = null
	_clear_tidal_waves()
	died.emit(self)
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.18)
	fade.finished.connect(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)


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
		CastAction.PROTECTIVE_SHIELD:
			return "PROTECTIVE_SHIELD"
		CastAction.TIDAL_WAVE:
			return "TIDAL_WAVE"
		CastAction.LIGHT_BOLT:
			return "LIGHT_BOLT"
		_:
			return "NONE"


func _log_cast_event(prefix: String, action: CastAction, target: Node2D) -> void:
	if not cast_debug_logging_enabled:
		return
	var target_name := "None"
	var current := 0.0
	var maximum := 0.0
	var missing := 0.0
	var marked_blocked := false
	if target != null and is_instance_valid(target):
		target_name = target.name
		maximum = maxf(1.0, float(target.get("max_health")))
		current = clampf(float(target.get("current_health")), 0.0, maximum)
		missing = maxf(0.0, maximum - current)
		marked_blocked = _is_marked_target_waiting_for_damage(target)
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

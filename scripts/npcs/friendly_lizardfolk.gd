extends FriendlyRatfolk
class_name FriendlyLizardfolk

const LIZARDFOLK_SHEET_PATH: String = "res://assets/external/ElthenAssets/lizardfolk/Lizardfolk Archer Sprite Sheet.png"
const LIZARDFOLK_SCENE_PATH: String = "res://scenes/npcs/FriendlyLizardfolk.tscn"
const LIZARD_ARROW_PROJECTILE_SCENE_PATH: String = "res://scenes/projectiles/LizardArrowProjectile.tscn"
const LIZARDFOLK_HFRAMES: int = 8
const LIZARDFOLK_VFRAMES: int = 6

const LIZARD_ANIM_ROWS: Dictionary = {
	"idle": 0,
	"run": 1,
	"attack": 3,
	"hurt": 4,
	"death": 5
}

const LIZARD_ANIM_FRAME_COLUMNS: Dictionary = {
	"idle": [0, 1, 2, 3],
	"run": [0, 1, 2, 3, 4, 5, 6, 7],
	"attack": [0, 1, 2, 3, 4, 5],
	"hurt": [0, 1, 2, 3],
	"death": [0, 1, 2, 3, 4, 5]
}

const LIZARD_ANIM_FPS: Dictionary = {
	"idle": 7.0,
	"run": 9.2,
	"attack": 10.4,
	"hurt": 11.5,
	"death": 8.0
}

var lizardfolk_sheet_texture: Texture2D = null
var lizardfolk_scene_cache: PackedScene = null
var lizard_arrow_projectile_scene_cache: PackedScene = null

@export var arrow_projectile_speed: float = 560.0
@export var arrow_projectile_max_distance: float = 700.0
@export var arrow_spawn_forward_offset: float = 22.0
@export var arrow_spawn_vertical_offset: float = -21.0
@export var arrow_impact_hitstop: float = 0.04
@export var flurry_enabled: bool = true
@export var flurry_cooldown: float = 8.0
@export var flurry_windup: float = 0.34
@export var flurry_duration: float = 1.05
@export var flurry_shot_interval: float = 0.16
@export var flurry_min_targets: int = 2
@export var flurry_max_targets_per_volley: int = 3
@export var flurry_trigger_range: float = 560.0
@export var flurry_arrow_damage_scale: float = 0.65
@export var flurry_arrow_speed_scale: float = 1.12
@export var flurry_aim_spread_degrees: float = 3.5
@export_range(0.0, 1.0, 0.01) var flurry_opening_cooldown_ratio: float = 0.45
@export var behind_tank_distance: float = 148.0
@export var behind_tank_depth_offset: float = 18.0
@export var engage_distance_from_player: float = 260.0
@export var disengage_distance_from_player: float = 340.0

var flurry_cooldown_left: float = 0.0
var flurry_windup_left: float = 0.0
var flurry_active_left: float = 0.0
var flurry_shot_left: float = 0.0
var flurry_sequence_active: bool = false
var flurry_has_started_firing: bool = false
var lizard_combat_engaged: bool = false


func _ready() -> void:
	# Keep this ally focused as a straightforward ranged striker (no clone branching).
	shadow_clone_enabled = false
	shadow_fear_enabled = false
	backstab_dash_enabled = false
	attack_range = 430.0
	attack_depth_tolerance = 122.0
	preferred_attack_spacing = 336.0
	preferred_attack_spacing_tolerance = 24.0
	follow_player_distance = 236.0
	follow_player_min_distance = 132.0
	max_chase_distance_from_player = 720.0
	attack_windup = 0.48
	attack_recovery = 0.16
	attack_cooldown = 1.08
	attack_impact_vfx_scale = 1.0
	outgoing_hit_stun_duration = 0.2
	attack_knockback_scale = 0.72
	super._ready()
	flurry_cooldown_left = maxf(0.0, flurry_cooldown * clampf(flurry_opening_cooldown_ratio, 0.0, 1.0))
	flurry_windup_left = 0.0
	flurry_active_left = 0.0
	flurry_shot_left = 0.0
	flurry_sequence_active = false
	flurry_has_started_firing = false


func _configure_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = _get_ratfolk_sheet_texture()
	sprite.hframes = LIZARDFOLK_HFRAMES
	sprite.vframes = LIZARDFOLK_VFRAMES
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _set_loop_anim(anim_key: String, delta: float) -> void:
	if sprite_anim_key != anim_key:
		sprite_anim_key = anim_key
		sprite_anim_time = 0.0
	else:
		sprite_anim_time += delta
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var fps := float(LIZARD_ANIM_FPS.get(anim_key, 8.0))
	var frame_index := int(floor(sprite_anim_time * fps)) % columns.size()
	_set_sprite_frame(anim_key, frame_index)


func _set_non_loop_anim(anim_key: String, progress: float) -> void:
	sprite_anim_key = anim_key
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var frame_index := mini(int(floor(clampf(progress, 0.0, 1.0) * float(columns.size()))), columns.size() - 1)
	_set_sprite_frame(anim_key, frame_index)


func _set_sprite_frame(anim_key: String, frame_index: int) -> void:
	if not is_instance_valid(sprite):
		return
	var row := int(LIZARD_ANIM_ROWS.get(anim_key, 0))
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	if columns.is_empty():
		return
	var safe_index := clampi(frame_index, 0, columns.size() - 1)
	var column := int(columns[safe_index])
	sprite.frame_coords = Vector2i(column, row)
	sprite.flip_h = facing_left


func _get_anim_duration(anim_key: String) -> float:
	var columns: Array = LIZARD_ANIM_FRAME_COLUMNS.get(anim_key, [])
	var fps := float(LIZARD_ANIM_FPS.get(anim_key, 8.0))
	if columns.is_empty() or fps <= 0.0:
		return 0.2
	return float(columns.size()) / fps


func _get_ratfolk_sheet_texture() -> Texture2D:
	if is_instance_valid(lizardfolk_sheet_texture):
		return lizardfolk_sheet_texture
	var source_image := Image.load_from_file(ProjectSettings.globalize_path(LIZARDFOLK_SHEET_PATH))
	if source_image == null or source_image.is_empty():
		return null
	lizardfolk_sheet_texture = ImageTexture.create_from_image(source_image)
	return lizardfolk_sheet_texture


func _get_ratfolk_scene() -> PackedScene:
	if is_instance_valid(lizardfolk_scene_cache):
		return lizardfolk_scene_cache
	var loaded_scene := load(LIZARDFOLK_SCENE_PATH)
	if loaded_scene is PackedScene:
		lizardfolk_scene_cache = loaded_scene as PackedScene
	return lizardfolk_scene_cache


func _tick_timers(delta: float) -> void:
	super._tick_timers(delta)
	flurry_cooldown_left = maxf(0.0, flurry_cooldown_left - maxf(0.0, delta))
	flurry_windup_left = maxf(0.0, flurry_windup_left - maxf(0.0, delta))
	flurry_active_left = maxf(0.0, flurry_active_left - maxf(0.0, delta))
	flurry_shot_left = maxf(0.0, flurry_shot_left - maxf(0.0, delta))


func _interrupt_attack() -> void:
	super._interrupt_attack()
	_reset_flurry_state()


func _die() -> void:
	_reset_flurry_state()
	super._die()


func _update_animation(delta: float) -> void:
	if flurry_sequence_active and (flurry_windup_left > 0.0 or flurry_active_left > 0.0):
		_set_loop_anim("attack", delta)
		return
	super._update_animation(delta)


func _get_preferred_attack_position(enemy: EnemyBase) -> Vector2:
	if enemy == null or not is_instance_valid(enemy) or not is_instance_valid(player):
		return super._get_preferred_attack_position(enemy)
	var tank_position := player.global_position
	var tank_to_enemy := enemy.global_position - tank_position
	var away_from_enemy := Vector2.ZERO
	if tank_to_enemy.length_squared() > 0.0001:
		away_from_enemy = -tank_to_enemy.normalized()
	else:
		away_from_enemy = Vector2.LEFT if facing_left else Vector2.RIGHT
	var depth_sign := 1.0 if (int(get_instance_id()) % 2) == 0 else -1.0
	var depth_offset := depth_sign * minf(maxf(6.0, behind_tank_depth_offset), attack_depth_tolerance * 0.55)
	var desired_position := tank_position + (away_from_enemy * maxf(24.0, behind_tank_distance)) + Vector2(0.0, depth_offset)

	var min_enemy_distance := _get_attack_spacing_min()
	var desired_to_enemy := enemy.global_position - desired_position
	if desired_to_enemy.length() < min_enemy_distance:
		var fallback_away := away_from_enemy
		if fallback_away.length_squared() <= 0.0001:
			fallback_away = (desired_position - enemy.global_position).normalized()
		if fallback_away.length_squared() <= 0.0001:
			fallback_away = Vector2.LEFT if facing_left else Vector2.RIGHT
		desired_position = enemy.global_position + (fallback_away.normalized() * min_enemy_distance)

	return _clamp_world_position_to_bounds(desired_position)


func _tick_combat_logic(delta: float) -> void:
	if flurry_sequence_active:
		if _handle_breath_threat():
			_reset_flurry_state()
			return
		if _handle_marked_lunge_threat(delta):
			_reset_flurry_state()
			return
		velocity = Vector2.ZERO
		if not flurry_has_started_firing:
			var prep_targets := _get_flurry_targets(1)
			if not prep_targets.is_empty():
				_update_facing(prep_targets[0].global_position - global_position)
			if flurry_windup_left > 0.0:
				return
			flurry_has_started_firing = true
			flurry_active_left = maxf(0.1, flurry_duration)
			flurry_shot_left = 0.0
			_spawn_hit_effect(global_position + Vector2(0.0, -18.0), Color(0.76, 0.96, 0.62, 0.9), 6.8)
		if flurry_active_left <= 0.0:
			_reset_flurry_state()
			return
		var volley_targets := _get_flurry_targets(flurry_max_targets_per_volley)
		if volley_targets.is_empty():
			_reset_flurry_state()
			return
		_update_facing(volley_targets[0].global_position - global_position)
		if flurry_shot_left <= 0.0:
			_fire_flurry_volley(volley_targets)
			flurry_shot_left = maxf(0.03, flurry_shot_interval)
		return

	if _can_start_flurry():
		_start_flurry()
		velocity = Vector2.ZERO
		return

	super._tick_combat_logic(delta)


func _perform_attack() -> void:
	attack_cooldown_left = maxf(0.01, attack_cooldown)
	var target := target_enemy
	if target == null or not is_instance_valid(target) or target.dead:
		target = _find_target_enemy()
	if target == null or not is_instance_valid(target) or target.dead:
		return
	if _is_enemy_shadow_feared(target):
		return

	var fired := _fire_arrow_at_target(target, 1.0, 1.0, 1.0, true)
	if fired:
		return

	if target.has_method("receive_hit"):
		var fallback_hit := bool(target.call("receive_hit", attack_damage, global_position, outgoing_hit_stun_duration, true, attack_knockback_scale, self))
		if fallback_hit and target.has_method("apply_hitstop"):
			target.call("apply_hitstop", arrow_impact_hitstop)


func _can_start_flurry() -> bool:
	if not flurry_enabled:
		return false
	if flurry_sequence_active:
		return false
	if flurry_cooldown_left > 0.0:
		return false
	if attack_windup_left > 0.0 or attack_recovery_left > 0.0:
		return false
	if backstab_dash_left > 0.0 or shadow_clone_cast_active or shadow_fear_cast_active:
		return false
	if not is_instance_valid(player):
		return false
	var ready_targets := _get_flurry_targets(flurry_max_targets_per_volley)
	return ready_targets.size() >= maxi(2, flurry_min_targets)


func _start_flurry() -> void:
	flurry_sequence_active = true
	flurry_has_started_firing = false
	flurry_windup_left = maxf(0.06, flurry_windup)
	flurry_active_left = 0.0
	flurry_shot_left = 0.0
	flurry_cooldown_left = maxf(0.1, flurry_cooldown)
	_set_dps_ai_state(DPSAIState.ASSAULT_CAST, target_enemy)
	_spawn_hit_effect(global_position + Vector2(0.0, -14.0), Color(0.72, 0.9, 0.58, 0.86), 5.6)


func _reset_flurry_state() -> void:
	flurry_sequence_active = false
	flurry_has_started_firing = false
	flurry_windup_left = 0.0
	flurry_active_left = 0.0
	flurry_shot_left = 0.0


func _find_target_enemy() -> EnemyBase:
	var candidate := super._find_target_enemy()
	if candidate == null or not is_instance_valid(candidate):
		lizard_combat_engaged = false
		return null
	if not is_instance_valid(player):
		lizard_combat_engaged = true
		return candidate
	var engage_distance := maxf(40.0, engage_distance_from_player)
	var disengage_distance := maxf(engage_distance + 20.0, disengage_distance_from_player)
	var distance_to_player := player.global_position.distance_to(candidate.global_position)
	if lizard_combat_engaged:
		if distance_to_player <= disengage_distance:
			return candidate
		lizard_combat_engaged = false
		return null
	if distance_to_player <= engage_distance:
		lizard_combat_engaged = true
		return candidate
	return null


func _fire_flurry_volley(targets: Array[EnemyBase]) -> void:
	if targets.is_empty():
		return
	var fired_count := 0
	for enemy in targets:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if _fire_arrow_at_target(enemy, flurry_arrow_damage_scale, flurry_arrow_speed_scale, 1.0, false):
			fired_count += 1
	if fired_count > 0:
		_spawn_hit_effect(global_position + Vector2(0.0, -16.0), Color(0.72, 0.98, 0.64, 0.9), 4.6 + float(fired_count))


func _get_flurry_targets(max_count: int) -> Array[EnemyBase]:
	var limit := maxi(1, max_count)
	var trigger_range_sq := maxf(32.0, flurry_trigger_range) * maxf(32.0, flurry_trigger_range)
	var chase_range_sq := maxf(1.0, max_chase_distance_from_player) * maxf(1.0, max_chase_distance_from_player)
	var player_position := player.global_position if is_instance_valid(player) else global_position
	var candidates: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if _is_enemy_shadow_feared(enemy):
			continue
		if enemy.global_position.distance_squared_to(player_position) > chase_range_sq:
			continue
		var dist_sq := enemy.global_position.distance_squared_to(global_position)
		if dist_sq > trigger_range_sq:
			continue
		candidates.append({
			"enemy": enemy,
			"dist_sq": dist_sq
		})
	candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("dist_sq", INF)) < float(b.get("dist_sq", INF))
	)
	var selected: Array[EnemyBase] = []
	for entry_variant in candidates:
		var entry := entry_variant as Dictionary
		var enemy_candidate := entry.get("enemy") as EnemyBase
		if enemy_candidate == null or not is_instance_valid(enemy_candidate) or enemy_candidate.dead:
			continue
		selected.append(enemy_candidate)
		if selected.size() >= limit:
			break
	return selected


func _fire_arrow_at_target(target: EnemyBase, damage_scale: float = 1.0, speed_scale: float = 1.0, distance_scale: float = 1.0, spawn_cast_effect: bool = true) -> bool:
	if target == null or not is_instance_valid(target) or target.dead:
		return false
	var to_target := target.global_position - global_position
	var fire_direction := to_target.normalized() if to_target.length_squared() > 0.0001 else (Vector2.LEFT if facing_left else Vector2.RIGHT)
	if flurry_active_left > 0.0 and flurry_aim_spread_degrees > 0.0:
		var spread_radians := deg_to_rad(clampf(flurry_aim_spread_degrees, 0.0, 45.0))
		fire_direction = fire_direction.rotated(rng.randf_range(-spread_radians, spread_radians))
		if fire_direction.length_squared() <= 0.0001:
			fire_direction = to_target.normalized() if to_target.length_squared() > 0.0001 else Vector2.RIGHT
		else:
			fire_direction = fire_direction.normalized()
	_update_facing(fire_direction)

	var projectile_scene := _get_arrow_projectile_scene()
	if projectile_scene == null:
		return false

	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return false
	var scene_root := get_parent()
	if scene_root == null:
		projectile.queue_free()
		return false
	scene_root.add_child(projectile)
	var spawn_position := global_position + Vector2(fire_direction.x * maxf(8.0, arrow_spawn_forward_offset), arrow_spawn_vertical_offset)
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			self,
			spawn_position,
			fire_direction,
			maxf(1.0, arrow_projectile_speed * maxf(0.1, speed_scale)),
			maxf(24.0, arrow_projectile_max_distance * maxf(0.1, distance_scale)),
			maxf(0.1, attack_damage * maxf(0.1, damage_scale)),
			maxf(0.0, outgoing_hit_stun_duration),
			maxf(0.1, attack_knockback_scale),
			target
		)
	if spawn_cast_effect:
		_spawn_hit_effect(spawn_position, Color(0.86, 0.96, 0.72, 0.86), 4.2)
	return true


func _get_cast_progress_ratio() -> float:
	var inherited_ratio := super._get_cast_progress_ratio()
	if inherited_ratio >= 0.0:
		return inherited_ratio
	if attack_windup_left > 0.0 and attack_windup > 0.01:
		return clampf(1.0 - (attack_windup_left / attack_windup), 0.0, 1.0)
	return -1.0


func _get_arrow_projectile_scene() -> PackedScene:
	if is_instance_valid(lizard_arrow_projectile_scene_cache):
		return lizard_arrow_projectile_scene_cache
	var loaded_scene := load(LIZARD_ARROW_PROJECTILE_SCENE_PATH)
	if loaded_scene is PackedScene:
		lizard_arrow_projectile_scene_cache = loaded_scene as PackedScene
	return lizard_arrow_projectile_scene_cache

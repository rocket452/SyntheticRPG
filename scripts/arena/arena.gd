extends Node2D
class_name Arena

enum EncounterType {
	MINOTAUR,
	CACODEMON,
	SHARDSOUL
}

signal player_health_changed(current: float, maximum: float)
signal player_xp_changed(current: int, needed: int, level: int)
signal cooldowns_changed(values: Dictionary)
signal objective_changed(text: String)
signal item_collected(item_name: String, total_owned: int)
signal player_died
signal demo_won
signal combat_debug_changed(values: Dictionary)
signal status_message(text: String, duration: float)

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const FRIENDLY_HEALER_SCENE: PackedScene = preload("res://scenes/npcs/FriendlyHealer.tscn")
const FRIENDLY_RATFOLK_SCENE: PackedScene = preload("res://scenes/npcs/FriendlyRatfolk.tscn")
const MELEE_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/MeleeEnemy.tscn")
const ITEM_SCENE: PackedScene = preload("res://scenes/items/ItemPickup.tscn")
const COMPANION_BREATH_RESPONSE_SCRIPT := preload("res://ai/CompanionBreathResponse.gd")
const IMP_SUMMON_PENTAGRAM_EFFECT_SCRIPT := preload("res://scripts/effects/imp_summon_pentagram.gd")

@export var regular_enemy_count: int = 1
@export var allow_multiple_minotaurs: bool = true
@export var max_active_minotaurs: int = 2
@export var timed_extra_minotaur_enabled: bool = true
@export var timed_extra_minotaur_delay: float = 12.0
@export var spawn_jitter: float = 18.0
@export var encounter_initial_enemy_distance_scale: float = 1.55
@export var encounter_initial_enemy_min_party_distance: float = 360.0
@export var encounter_initial_enemy_max_party_distance: float = 700.0
@export var encounter_initial_enemy_min_enemy_distance: float = 132.0
@export var encounter_spawn_reposition_step: float = 52.0
@export var encounter_spawn_reposition_attempts: int = 12
@export var encounter_pair_vertical_spacing: float = 124.0
@export var encounter_edge_spawn_inset: float = 22.0
@export var encounter_spacing_debug_logging: bool = false
@export var encounter_spacing_debug_opening_window: float = 6.0
@export var encounter_spacing_debug_log_interval: float = 0.85
@export var arena_min_x: float = -760.0
@export var arena_max_x: float = 760.0
@export var arena_min_y: float = -165.0
@export var arena_max_y: float = 165.0
@export var camera_limit_padding: Vector2 = Vector2(84.0, 60.0)
@export var summoned_minion_edge_inset: float = 28.0
@export var summoned_minion_y_spacing: float = 34.0
@export var summoned_imp_spawn_distance_x: float = 88.0
@export var summoned_imp_spawn_x_stagger: float = 18.0
@export var summoned_minion_health_scale: float = 0.68
@export var summoned_imp_health_multiplier: float = 0.75
@export var summoned_minion_speed_scale: float = 0.9
@export var summoned_minion_damage_scale: float = 0.82
@export var summoned_imp_damage_multiplier: float = 0.5
@export var summoned_minion_xp_scale: float = 0.35
@export var miniboss_health_scale: float = 4.0
@export var imp_summon_pentagram_enabled: bool = true
@export var imp_summon_pentagram_y_offset: float = 12.0
@export var summoned_imp_spawn_stagger: float = 0.04

@onready var actors: Node2D = $Actors
@onready var drops: Node2D = $Drops
@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var healer_spawn: Marker2D = get_node_or_null("HealerSpawn") as Marker2D
@onready var ratfolk_spawn: Marker2D = get_node_or_null("RatfolkSpawn") as Marker2D

var player: Player = null
var healer: Node2D = null
var ratfolk: Node2D = null
var alive_regular_enemies: int = 0
var demo_started: bool = false
var spawn_next_debug_enemy_on_left: bool = true
var demo_elapsed: float = 0.0
var timed_extra_minotaur_spawned: bool = false
var initial_minotaur_spawn_on_left: bool = false
var spawned_minotaurs_total: int = 0
var selected_encounter: int = EncounterType.MINOTAUR
var rng := RandomNumberGenerator.new()
var hitbox_debug_mode_enabled: bool = false
var hitbox_debug_sync_left: float = 0.0
var spacing_debug_runtime_enabled: bool = false
var spacing_debug_next_log_at: float = 0.0


func _ready() -> void:
	if _is_autoplay_requested():
		rng.seed = 1337
	else:
		rng.randomize()
	spacing_debug_runtime_enabled = encounter_spacing_debug_logging or _is_env_flag_enabled("ENCOUNTER_SPACING_DEBUG")


func _process(delta: float) -> void:
	if not demo_started:
		return
	demo_elapsed += maxf(0.0, delta)
	if hitbox_debug_mode_enabled:
		hitbox_debug_sync_left = maxf(0.0, hitbox_debug_sync_left - maxf(0.0, delta))
		if hitbox_debug_sync_left <= 0.0:
			hitbox_debug_sync_left = 0.2
			_sync_hitbox_debug_mode()
	_maybe_log_opening_spacing()
	_try_spawn_timed_extra_minotaur()
	_emit_combat_debug()


func start_demo_with_encounter(encounter_type: int) -> void:
	set_encounter_type(encounter_type)
	start_demo()


func set_encounter_type(encounter_type: int) -> void:
	if encounter_type == EncounterType.CACODEMON:
		selected_encounter = EncounterType.CACODEMON
	elif encounter_type == EncounterType.SHARDSOUL:
		selected_encounter = EncounterType.SHARDSOUL
	else:
		selected_encounter = EncounterType.MINOTAUR


func start_demo() -> void:
	if demo_started:
		return
	demo_started = true
	demo_elapsed = 0.0
	spacing_debug_next_log_at = 0.0
	timed_extra_minotaur_spawned = false
	initial_minotaur_spawn_on_left = false
	spawned_minotaurs_total = 0
	_spawn_player()
	_spawn_friendly_healer()
	_spawn_friendly_ratfolk()
	_prewarm_imp_summon_effect_cache()
	_spawn_regular_enemies()
	_log_encounter_spacing_snapshot("spawn_init")
	_sync_hitbox_debug_mode()
	_update_objective()
	broadcast_current_state()


func broadcast_current_state() -> void:
	if is_instance_valid(player):
		player.emit_initial_state()
	_update_objective()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	if player == null:
		push_error("Failed to instantiate player scene.")
		return
	actors.add_child(player)
	player.global_position = player_spawn.global_position
	_apply_bounds_to_player(player)
	_apply_hitbox_debug_to_node(player)

	player.health_changed.connect(_on_player_health_changed)
	player.xp_changed.connect(_on_player_xp_changed)
	player.cooldowns_changed.connect(_on_player_cooldowns_changed)
	player.item_looted.connect(_on_player_item_looted)
	player.died.connect(_on_player_died)


func _spawn_friendly_healer() -> void:
	if not is_instance_valid(healer_spawn):
		return
	healer = FRIENDLY_HEALER_SCENE.instantiate() as Node2D
	if healer == null:
		push_error("Failed to instantiate friendly healer scene.")
		return
	actors.add_child(healer)
	healer.global_position = healer_spawn.global_position
	_apply_hitbox_debug_to_node(healer)
	if healer.has_method("set_player") and is_instance_valid(player):
		healer.set_player(player)


func _spawn_friendly_ratfolk() -> void:
	if not is_instance_valid(ratfolk_spawn):
		return
	ratfolk = FRIENDLY_RATFOLK_SCENE.instantiate() as Node2D
	if ratfolk == null:
		push_error("Failed to instantiate friendly ratfolk scene.")
		return
	actors.add_child(ratfolk)
	ratfolk.global_position = ratfolk_spawn.global_position
	_apply_hitbox_debug_to_node(ratfolk)
	if ratfolk.has_method("set_player") and is_instance_valid(player):
		ratfolk.set_player(player)
	if ratfolk.has_method("set_arena_bounds"):
		ratfolk.call("set_arena_bounds", arena_min_x, arena_max_x, arena_min_y, arena_max_y)


func _spawn_regular_enemies() -> void:
	alive_regular_enemies = 0
	if selected_encounter == EncounterType.CACODEMON:
		_spawn_cacodemon_encounter()
		return
	if selected_encounter == EncounterType.SHARDSOUL:
		_spawn_shardsoul_encounter()
		return
	var spawn_count := regular_enemy_count
	var minotaur_cap := _get_minotaur_spawn_cap()
	spawn_count = mini(spawn_count, minotaur_cap)
	if spawn_count >= 2:
		var pair_offset := maxf(20.0, encounter_pair_vertical_spacing * 0.5)
		_spawn_edge_minotaur_on_side(false, -pair_offset)
		_spawn_edge_minotaur_on_side(false, pair_offset)
		spawn_count -= 2
	if spawn_count <= 0:
		return
	if spawn_points.is_empty():
		push_error("No spawn points configured in Arena scene.")
		return
	for i in spawn_count:
		var spawn_marker := spawn_points[rng.randi_range(0, spawn_points.size() - 1)] as Marker2D
		if spawn_marker == null:
			continue
		var spawn_position := spawn_marker.global_position + Vector2(
			rng.randf_range(-spawn_jitter, spawn_jitter),
			rng.randf_range(-spawn_jitter, spawn_jitter)
		)
		spawn_position = _resolve_encounter_spawn_position(spawn_position)
		var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position)
		if enemy == null:
			continue
		_configure_miniboss(enemy)
		if alive_regular_enemies <= 0:
			initial_minotaur_spawn_on_left = spawn_position.x < _get_arena_center_x()
		alive_regular_enemies += 1
		spawned_minotaurs_total += 1


func spawn_debug_minotaur_alternating() -> void:
	if not demo_started:
		return
	if selected_encounter != EncounterType.MINOTAUR:
		return
	if not _can_spawn_additional_minotaur():
		return
	_spawn_edge_minotaur()


func _try_spawn_timed_extra_minotaur() -> void:
	if selected_encounter != EncounterType.MINOTAUR:
		return
	if not timed_extra_minotaur_enabled:
		return
	if timed_extra_minotaur_spawned:
		return
	if not _can_spawn_additional_minotaur():
		return
	if alive_regular_enemies <= 0:
		return
	if demo_elapsed < maxf(0.0, timed_extra_minotaur_delay):
		return
	timed_extra_minotaur_spawned = true
	_spawn_edge_minotaur_on_side(initial_minotaur_spawn_on_left)


func _spawn_cacodemon_encounter() -> void:
	_spawn_air_boss_encounter(int(EnemyBase.MonsterVisualProfile.CACODEMON))


func _spawn_shardsoul_encounter() -> void:
	_spawn_air_boss_encounter(int(EnemyBase.MonsterVisualProfile.SHARDSOUL))


func _spawn_air_boss_encounter(visual_profile: int) -> void:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var edge_inset := maxf(8.0, encounter_edge_spawn_inset)
	var spawn_x := max_x - edge_inset
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 10.0, max_y - 10.0)
	var spawn_position := _resolve_encounter_spawn_position(to_global(Vector2(spawn_x, spawn_y)))
	var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position, visual_profile)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	if visual_profile == int(EnemyBase.MonsterVisualProfile.CACODEMON):
		enemy.boss_can_summon_minions = true
		enemy.boss_summon_count = 4
		enemy.boss_summon_interval = 20.0
		enemy.boss_summon_cycle_left = 15.0
	alive_regular_enemies = 1


func _configure_miniboss(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	enemy.is_miniboss = true
	enemy.boss_can_summon_minions = false
	enemy.boss_summon_count = 0
	enemy.max_health = maxf(10.0, enemy.max_health * miniboss_health_scale)
	enemy.current_health = enemy.max_health


func _spawn_edge_minotaur() -> void:
	_spawn_edge_minotaur_on_side(spawn_next_debug_enemy_on_left)
	spawn_next_debug_enemy_on_left = not spawn_next_debug_enemy_on_left


func _spawn_edge_minotaur_on_side(spawn_on_left: bool, vertical_offset: float = 0.0) -> void:
	if not _can_spawn_additional_minotaur():
		return
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var edge_inset := maxf(8.0, encounter_edge_spawn_inset)
	var spawn_x := min_x + edge_inset if spawn_on_left else max_x - edge_inset
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 8.0, max_y - 8.0)
	spawn_y = clampf(spawn_y + vertical_offset, min_y + 8.0, max_y - 8.0)
	var spawn_position := _resolve_encounter_spawn_position(to_global(Vector2(spawn_x, spawn_y)))
	var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	if alive_regular_enemies <= 0:
		initial_minotaur_spawn_on_left = spawn_on_left
	alive_regular_enemies += 1
	spawned_minotaurs_total += 1
	_update_objective()


func _can_spawn_additional_minotaur() -> bool:
	var minotaur_cap := _get_minotaur_spawn_cap()
	if spawned_minotaurs_total >= minotaur_cap:
		return false
	return _count_alive_minotaurs() < minotaur_cap


func _get_minotaur_spawn_cap() -> int:
	var minotaur_cap := maxi(1, max_active_minotaurs)
	if not allow_multiple_minotaurs:
		minotaur_cap = 1
	return minotaur_cap


func _count_alive_minotaurs() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not enemy.is_miniboss:
			continue
		count += 1
	return count


func _get_arena_center_x() -> float:
	return (minf(arena_min_x, arena_max_x) + maxf(arena_min_x, arena_max_x)) * 0.5


func _spawn_enemy(scene: PackedScene, spawn_position: Vector2, visual_profile_override: int = -1) -> EnemyBase:
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		push_error("Failed to instantiate enemy scene: %s" % scene.resource_path)
		return null
	if visual_profile_override >= 0:
		enemy.monster_visual_profile = visual_profile_override
	actors.add_child(enemy)
	enemy.global_position = spawn_position
	_apply_hitbox_debug_to_node(enemy)
	_apply_bounds_to_enemy(enemy)
	enemy.died.connect(_on_enemy_died)
	if not enemy.summon_minions_requested.is_connected(_on_enemy_summon_minions_requested):
		enemy.summon_minions_requested.connect(_on_enemy_summon_minions_requested)
	if not enemy.breath_threat.is_connected(_on_enemy_breath_threat):
		enemy.breath_threat.connect(_on_enemy_breath_threat.bind(enemy))
	return enemy


func _on_enemy_summon_minions_requested(source_enemy: EnemyBase, count: int) -> void:
	if not demo_started:
		return
	var use_imp_profile := source_enemy != null and is_instance_valid(source_enemy) and source_enemy.monster_visual_profile == EnemyBase.MonsterVisualProfile.CACODEMON
	var total_to_spawn := 4 if use_imp_profile else maxi(1, count)
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var source_local := to_local(source_enemy.global_position) if is_instance_valid(source_enemy) else Vector2.ZERO
	var spawn_positions: Array[Vector2] = []
	if use_imp_profile and is_instance_valid(source_enemy):
		var center_local := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
		source_enemy.global_position = to_global(center_local)
		source_enemy.velocity = Vector2.ZERO
		source_enemy.knockback_velocity = Vector2.ZERO
		source_local = center_local
		var edge_inset := maxf(8.0, maxf(summoned_minion_edge_inset, encounter_edge_spawn_inset))
		var left_x := min_x + edge_inset
		var right_x := max_x - edge_inset
		var top_y := min_y + edge_inset
		var bottom_y := max_y - edge_inset
		spawn_positions = [
			to_global(Vector2(left_x, top_y)),
			to_global(Vector2(right_x, top_y)),
			to_global(Vector2(left_x, bottom_y)),
			to_global(Vector2(right_x, bottom_y))
		]
	else:
		for i in range(total_to_spawn):
			var spawn_on_left := spawn_next_debug_enemy_on_left
			var spawn_x := (min_x + summoned_minion_edge_inset) if spawn_on_left else (max_x - summoned_minion_edge_inset)
			var y_offset := (float(i) - (float(total_to_spawn - 1) * 0.5)) * summoned_minion_y_spacing
			var spawn_y := clampf(source_local.y + y_offset, min_y + 10.0, max_y - 10.0)
			var spawn_position := to_global(Vector2(spawn_x, spawn_y))
			spawn_positions.append(spawn_position)
			spawn_next_debug_enemy_on_left = not spawn_next_debug_enemy_on_left

	if use_imp_profile:
		var summon_delay := 0.0
		for spawn_position in spawn_positions:
			var effect := _spawn_imp_summon_pentagram(spawn_position)
			if effect == null or not is_instance_valid(effect):
				continue
			if effect.has_method("get_expected_duration"):
				var duration_variant: Variant = effect.call("get_expected_duration")
				if duration_variant is float:
					summon_delay = maxf(summon_delay, float(duration_variant))
		if summon_delay > 0.0:
			await get_tree().create_timer(summon_delay).timeout
		if not demo_started:
			return

	var spawn_stagger := maxf(0.0, summoned_imp_spawn_stagger) if use_imp_profile else 0.0
	for spawn_index in range(spawn_positions.size()):
		var spawn_position := spawn_positions[spawn_index]
		var minion_profile := int(EnemyBase.MonsterVisualProfile.IMP) if use_imp_profile else -1
		var minion := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position, minion_profile)
		if minion == null:
			continue
		minion.is_miniboss = false
		minion.use_single_phase_loop = false
		minion.boss_can_summon_minions = false
		minion.spin_attack_enabled = false
		minion.prioritize_companion_targets = true
		minion.max_health = maxf(10.0, minion.max_health * summoned_minion_health_scale)
		if use_imp_profile:
			minion.max_health = maxf(10.0, minion.max_health * maxf(0.0, summoned_imp_health_multiplier))
		minion.current_health = minion.max_health
		minion.move_speed = maxf(40.0, minion.move_speed * summoned_minion_speed_scale)
		minion.attack_damage = maxf(1.0, minion.attack_damage * summoned_minion_damage_scale)
		if use_imp_profile:
			minion.attack_damage = maxf(1.0, minion.attack_damage * maxf(0.0, summoned_imp_damage_multiplier))
		if use_imp_profile:
			minion.pending_attack = false
			minion.attack_windup_left = 0.0
			minion.attack_prestrike_hold_left = 0.0
			minion.attack_recovery_hold_left = 0.0
			minion.attack_prestrike_hold_duration = maxf(minion.attack_prestrike_hold_duration, 0.06)
			minion.attack_hold_frame = 2
			# Let summoned imps start threatening quickly instead of idling post-spawn.
			minion.attack_cooldown_left = minf(minion.attack_cooldown_left, 0.2)
			minion.attack_cooldown = minf(minion.attack_cooldown, 1.2)
			minion.attack_windup = minf(minion.attack_windup, 0.2)
			# Summoned imps are ranged attackers; keep them at cast distance so their throw anim/projectile is visible.
			minion.attack_range = maxf(minion.attack_range, 180.0)
			minion.imp_fireball_speed = minf(minion.imp_fireball_speed, 190.0)
			minion.velocity = Vector2.ZERO
			if is_instance_valid(player):
				var to_player := player.global_position - minion.global_position
				if to_player.length_squared() > 0.0001:
					var facing := to_player.normalized()
					minion.external_sprite_facing_direction = facing
					minion.committed_attack_facing_direction = facing
		minion.xp_reward = maxi(1, int(round(float(minion.xp_reward) * summoned_minion_xp_scale)))
		alive_regular_enemies += 1
		if spawn_stagger > 0.0 and spawn_index < (spawn_positions.size() - 1):
			await get_tree().create_timer(spawn_stagger).timeout
	_update_objective()


func _spawn_imp_summon_pentagram(spawn_position: Vector2) -> Node2D:
	if not imp_summon_pentagram_enabled:
		return null
	var effect := IMP_SUMMON_PENTAGRAM_EFFECT_SCRIPT.new() as Node2D
	if effect == null:
		return null
	actors.add_child(effect)
	effect.global_position = spawn_position + Vector2(0.0, imp_summon_pentagram_y_offset)
	return effect


func _prewarm_imp_summon_effect_cache() -> void:
	if not imp_summon_pentagram_enabled:
		return
	if selected_encounter != EncounterType.CACODEMON and selected_encounter != EncounterType.SHARDSOUL:
		return
	ImpSummonPentagramEffect.warm_cache()


func _on_enemy_breath_threat(active: bool, boss_pos: Vector2, dir: Vector2, time_remaining: float, source_enemy: EnemyBase) -> void:
	if not active:
		return
	if source_enemy == null or not is_instance_valid(source_enemy):
		return
	if not source_enemy.has_method("get_breath_threat_snapshot"):
		return
	var snapshot_variant: Variant = source_enemy.call("get_breath_threat_snapshot")
	if not (snapshot_variant is Dictionary):
		return
	var snapshot := snapshot_variant as Dictionary
	if not bool(snapshot.get("charge_active", false)):
		return
	status_message.emit("BREATH INCOMING!", 0.85)


func _has_any_alive_enemy() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.dead:
			continue
		return true
	return false


func _apply_bounds_to_player(target_player: Player) -> void:
	if target_player == null:
		return
	target_player.set_arena_bounds(arena_min_x, arena_max_x, arena_min_y, arena_max_y)
	target_player.position.x = clampf(target_player.position.x, minf(arena_min_x, arena_max_x), maxf(arena_min_x, arena_max_x))
	target_player.position.y = clampf(target_player.position.y, minf(arena_min_y, arena_max_y), maxf(arena_min_y, arena_max_y))
	var global_bounds := _get_global_arena_bounds()
	target_player.configure_camera_limits(
		global_bounds.position.x - camera_limit_padding.x,
		global_bounds.position.y - camera_limit_padding.y,
		global_bounds.end.x + camera_limit_padding.x,
		global_bounds.end.y + camera_limit_padding.y
	)


func _apply_bounds_to_enemy(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	enemy.set_arena_bounds(arena_min_x, arena_max_x, arena_min_y, arena_max_y)
	enemy.position.x = clampf(enemy.position.x, minf(arena_min_x, arena_max_x), maxf(arena_min_x, arena_max_x))
	enemy.position.y = clampf(enemy.position.y, minf(arena_min_y, arena_max_y), maxf(arena_min_y, arena_max_y))


func _get_global_arena_bounds() -> Rect2:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var top_left := to_global(Vector2(min_x, min_y))
	var bottom_right := to_global(Vector2(max_x, max_y))
	return Rect2(top_left, bottom_right - top_left)


func _on_enemy_died(enemy: EnemyBase) -> void:
	if is_instance_valid(player):
		player.add_experience(enemy.xp_reward)

	_try_spawn_item_drop(enemy)

	alive_regular_enemies = max(0, alive_regular_enemies - 1)
	if alive_regular_enemies == 0:
		objective_changed.emit("Objective: Victory")
		demo_won.emit()
		return
	_update_objective()


func _try_spawn_item_drop(enemy: EnemyBase) -> void:
	if enemy.drop_table.is_empty():
		return
	if rng.randf() > enemy.drop_chance:
		return

	var item_id: String = enemy.drop_table[rng.randi_range(0, enemy.drop_table.size() - 1)]
	var pickup := ITEM_SCENE.instantiate() as ItemPickup
	if pickup == null:
		return
	drops.add_child(pickup)
	pickup.global_position = enemy.global_position + Vector2(
		rng.randf_range(-10.0, 10.0),
		rng.randf_range(-10.0, 10.0)
	)
	pickup.set_item(item_id, 1)


func _update_objective() -> void:
	if not demo_started:
		objective_changed.emit("Objective: Prepare for combat")
		return
	if alive_regular_enemies <= 0:
		objective_changed.emit("Objective: Victory")
		return
	if selected_encounter == EncounterType.CACODEMON:
		objective_changed.emit("Objective: Defeat the Cacodemon")
		return
	if selected_encounter == EncounterType.SHARDSOUL:
		objective_changed.emit("Objective: Defeat the Shardsoul")
		return
	objective_changed.emit("Objective: Defeat enemies (%d remaining)" % alive_regular_enemies)


func _emit_combat_debug() -> void:
	var tank_basic_cd_left := 0.0
	if is_instance_valid(player):
		tank_basic_cd_left = player.basic_attack_cooldown_left

	var healer_state := "-"
	var healer_target := "-"
	if is_instance_valid(healer):
		if healer.has_method("get_ai_debug_state"):
			healer_state = String(healer.call("get_ai_debug_state"))
		if healer.has_method("get_ai_debug_target"):
			healer_target = String(healer.call("get_ai_debug_target"))
	var dps_state := "-"
	var dps_target := "-"
	if is_instance_valid(ratfolk):
		if ratfolk.has_method("get_ai_debug_state"):
			dps_state = String(ratfolk.call("get_ai_debug_state"))
		if ratfolk.has_method("get_ai_debug_target"):
			dps_target = String(ratfolk.call("get_ai_debug_target"))

	var marked_ally := "-"
	var boss_state := "Idle"
	var vulnerable_left := 0.0
	var boss_windup_duration := 0.0
	var boss_lunge_cycle_left := 0.0
	var minion_count := 0
	var clone_count := 0
	var breath_state := "Idle"
	var breath_time_left := 0.0
	var tank_blocking := is_instance_valid(player) and player.is_blocking
	var pocket_valid := false
	var companions_safe := 0

	var debug_boss := _get_debug_boss()
	if debug_boss != null:
		if debug_boss.has_method("get_boss_marked_ally_name"):
			marked_ally = String(debug_boss.call("get_boss_marked_ally_name"))
		if debug_boss.has_method("get_boss_debug_state"):
			boss_state = String(debug_boss.call("get_boss_debug_state"))
		if debug_boss.has_method("get_boss_vulnerable_time_left"):
			var vulnerable_variant: Variant = debug_boss.call("get_boss_vulnerable_time_left")
			if vulnerable_variant is float:
				vulnerable_left = vulnerable_variant
			elif vulnerable_variant is int:
				vulnerable_left = float(vulnerable_variant)
		if debug_boss.has_method("get_breath_threat_snapshot"):
			var breath_variant: Variant = debug_boss.call("get_breath_threat_snapshot")
			if breath_variant is Dictionary:
				var breath_snapshot := breath_variant as Dictionary
				breath_state = String(breath_snapshot.get("state_name", "Idle"))
				breath_time_left = float(breath_snapshot.get("time_remaining", 0.0))
				tank_blocking = bool(breath_snapshot.get("tank_blocking", tank_blocking))
				pocket_valid = bool(breath_snapshot.get("safe_pocket_valid", false))
				companions_safe = COMPANION_BREATH_RESPONSE_SCRIPT.count_friendlies_in_pocket(get_tree(), breath_snapshot)
		boss_windup_duration = debug_boss.boss_windup_duration
		boss_lunge_cycle_left = debug_boss.boss_mark_cycle_left

	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		if not enemy.is_miniboss:
			minion_count += 1

	for clone_node in get_tree().get_nodes_in_group("shadow_clones"):
		var clone := clone_node as Node2D
		if clone == null or not is_instance_valid(clone):
			continue
		clone_count += 1

	combat_debug_changed.emit({
		"healer_state": healer_state,
		"healer_target": healer_target,
		"dps_state": dps_state,
		"dps_target": dps_target,
		"marked_ally": marked_ally,
		"boss_state": boss_state,
		"boss_vulnerable_left": vulnerable_left,
		"tank_basic_cd_left": tank_basic_cd_left,
		"boss_windup_duration": boss_windup_duration,
		"boss_lunge_cycle_left": boss_lunge_cycle_left,
		"minion_count": minion_count,
		"clone_count": clone_count,
		"breath_state": breath_state,
		"breath_time_left": breath_time_left,
		"tank_blocking": tank_blocking,
		"pocket_valid": pocket_valid,
		"companions_safe": companions_safe
	})


func _get_debug_boss() -> EnemyBase:
	var nearest_enemy: EnemyBase = null
	var nearest_dist_sq := INF
	var player_position := player.global_position if is_instance_valid(player) else global_position
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var dist_sq := enemy.global_position.distance_squared_to(player_position)
		if nearest_enemy == null or dist_sq < nearest_dist_sq:
			nearest_enemy = enemy
			nearest_dist_sq = dist_sq
	return nearest_enemy


func force_debug_boss_breath() -> void:
	var debug_boss := _get_debug_boss()
	if debug_boss == null or not is_instance_valid(debug_boss):
		return
	if debug_boss.has_method("debug_force_cacodemon_breath"):
		debug_boss.call("debug_force_cacodemon_breath")


func cycle_debug_breath_vfx_mode() -> int:
	var debug_boss := _get_debug_boss()
	if debug_boss == null or not is_instance_valid(debug_boss):
		return -1
	if debug_boss.has_method("cycle_cacodemon_breath_visual_mode"):
		return int(debug_boss.call("cycle_cacodemon_breath_visual_mode"))
	return -1


func toggle_player_auto_block() -> bool:
	if not is_instance_valid(player):
		return false
	if player.has_method("toggle_debug_auto_block"):
		return bool(player.call("toggle_debug_auto_block"))
	return false


func toggle_hitbox_debug_mode() -> bool:
	hitbox_debug_mode_enabled = not hitbox_debug_mode_enabled
	hitbox_debug_sync_left = 0.0
	_sync_hitbox_debug_mode()
	return hitbox_debug_mode_enabled


func _sync_hitbox_debug_mode() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.debug_collisions_hint = hitbox_debug_mode_enabled
	tree.set_meta("debug_hitbox_mode_enabled", hitbox_debug_mode_enabled)
	_apply_hitbox_debug_to_node(player)
	_apply_hitbox_debug_to_node(healer)
	_apply_hitbox_debug_to_node(ratfolk)
	for node in tree.get_nodes_in_group("hitbox_debuggable"):
		_apply_hitbox_debug_to_node(node as Node)


func _resolve_encounter_spawn_position(start_global_position: Vector2) -> Vector2:
	var resolved := _clamp_global_position_to_arena(start_global_position)
	var desired_party_distance := _get_desired_initial_enemy_party_distance()
	var desired_enemy_distance := maxf(12.0, encounter_initial_enemy_min_enemy_distance)
	var reposition_step := maxf(6.0, encounter_spawn_reposition_step)
	var max_attempts := maxi(0, encounter_spawn_reposition_attempts)
	var original := resolved
	var party_nodes := _get_alive_party_nodes()
	var party_distance_targets: Dictionary = {}
	var distance_scale := maxf(1.0, encounter_initial_enemy_distance_scale)
	var distance_cap := maxf(desired_party_distance, encounter_initial_enemy_max_party_distance)
	var max_party_target_distance := desired_party_distance
	for ally in party_nodes:
		var ally_id := ally.get_instance_id()
		var baseline_distance := original.distance_to(ally.global_position)
		var target_distance := clampf(maxf(desired_party_distance, baseline_distance * distance_scale), desired_party_distance, distance_cap)
		party_distance_targets[ally_id] = target_distance
		max_party_target_distance = maxf(max_party_target_distance, target_distance)
	for attempt in range(max_attempts):
		var adjusted := false
		var fallback_angle := float(attempt) * 0.78
		for ally in party_nodes:
			var to_candidate := resolved - ally.global_position
			var distance := to_candidate.length()
			var ally_id := ally.get_instance_id()
			var ally_target_distance := float(party_distance_targets.get(ally_id, desired_party_distance))
			if distance >= ally_target_distance:
				continue
			var push_direction := to_candidate.normalized() if distance > 0.001 else _get_spawn_fallback_direction(fallback_angle)
			var deficit := ally_target_distance - distance
			resolved += push_direction * (deficit + (reposition_step * 0.12))
			adjusted = true
		for enemy in _get_alive_enemy_nodes():
			var to_candidate := resolved - enemy.global_position
			var distance := to_candidate.length()
			if distance >= desired_enemy_distance:
				continue
			var push_direction := to_candidate.normalized() if distance > 0.001 else _get_spawn_fallback_direction(fallback_angle + 1.17)
			var deficit := desired_enemy_distance - distance
			resolved += push_direction * (deficit + (reposition_step * 0.16))
			adjusted = true
		resolved = _clamp_global_position_to_arena(resolved)
		if not adjusted:
			break
	if spacing_debug_runtime_enabled:
		var moved_distance := original.distance_to(resolved)
		if moved_distance >= 1.0:
			print(
				"[SPACING] spawn_adjust moved=%.1f party_min=%.1f enemy_min=%.1f from=%s to=%s" % [
					moved_distance,
					max_party_target_distance,
					desired_enemy_distance,
					original,
					resolved
				]
			)
	return resolved


func _get_desired_initial_enemy_party_distance() -> float:
	var base_distance := maxf(0.0, encounter_initial_enemy_min_party_distance)
	var scaled_distance := base_distance * maxf(0.1, encounter_initial_enemy_distance_scale)
	return maxf(base_distance, scaled_distance)


func _clamp_global_position_to_arena(world_position: Vector2) -> Vector2:
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var local := to_local(world_position)
	local.x = clampf(local.x, min_x, max_x)
	local.y = clampf(local.y, min_y, max_y)
	return to_global(local)


func _get_alive_party_nodes() -> Array[Node2D]:
	var party_nodes: Array[Node2D] = []
	if is_instance_valid(player):
		party_nodes.append(player)
	if is_instance_valid(healer):
		party_nodes.append(healer)
	if is_instance_valid(ratfolk):
		party_nodes.append(ratfolk)
	return party_nodes


func _get_alive_enemy_nodes() -> Array[EnemyBase]:
	var enemies: Array[EnemyBase] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		enemies.append(enemy)
	return enemies


func _get_spawn_fallback_direction(angle_offset: float = 0.0) -> Vector2:
	var avg_party_position := Vector2.ZERO
	var party_nodes := _get_alive_party_nodes()
	if party_nodes.is_empty():
		return Vector2.RIGHT.rotated(angle_offset)
	for ally in party_nodes:
		avg_party_position += ally.global_position
	avg_party_position /= float(party_nodes.size())
	var away_from_party := global_position - avg_party_position
	if away_from_party.length_squared() <= 0.0001:
		away_from_party = Vector2.RIGHT
	return away_from_party.normalized().rotated(angle_offset)


func _maybe_log_opening_spacing() -> void:
	if not spacing_debug_runtime_enabled:
		return
	var opening_window := maxf(0.0, encounter_spacing_debug_opening_window)
	if demo_elapsed > opening_window:
		return
	if demo_elapsed + 0.0001 < spacing_debug_next_log_at:
		return
	_log_encounter_spacing_snapshot("t=%.2f" % demo_elapsed)
	spacing_debug_next_log_at = demo_elapsed + maxf(0.2, encounter_spacing_debug_log_interval)


func _log_encounter_spacing_snapshot(label: String) -> void:
	if not spacing_debug_runtime_enabled:
		return
	var enemies := _get_alive_enemy_nodes()
	var party_nodes := _get_alive_party_nodes()
	var min_enemy_to_party := INF
	var avg_enemy_to_party := 0.0
	var enemy_to_party_samples := 0
	for enemy in enemies:
		if party_nodes.is_empty():
			continue
		var nearest_party_distance := INF
		for ally in party_nodes:
			nearest_party_distance = minf(nearest_party_distance, enemy.global_position.distance_to(ally.global_position))
		if nearest_party_distance < INF:
			min_enemy_to_party = minf(min_enemy_to_party, nearest_party_distance)
			avg_enemy_to_party += nearest_party_distance
			enemy_to_party_samples += 1
	var min_enemy_to_enemy := INF
	for i in range(enemies.size()):
		for j in range(i + 1, enemies.size()):
			var separation := enemies[i].global_position.distance_to(enemies[j].global_position)
			min_enemy_to_enemy = minf(min_enemy_to_enemy, separation)
	var separation_active_count := 0
	var separation_push_sum := 0.0
	var approach_slot_active_count := 0
	var approach_slot_offset_sum := 0.0
	for enemy in enemies:
		if not enemy.has_method("get_soft_separation_debug_snapshot"):
			continue
		var snapshot_variant: Variant = enemy.call("get_soft_separation_debug_snapshot")
		if not (snapshot_variant is Dictionary):
			continue
		var snapshot := snapshot_variant as Dictionary
		if bool(snapshot.get("applied", false)):
			separation_active_count += 1
			separation_push_sum += float(snapshot.get("push_magnitude", 0.0))
		if bool(snapshot.get("approach_slot_applied", false)):
			approach_slot_active_count += 1
			var slot_offset_variant: Variant = snapshot.get("approach_slot_offset", Vector2.ZERO)
			if slot_offset_variant is Vector2:
				approach_slot_offset_sum += (slot_offset_variant as Vector2).length()
	var avg_enemy_to_party_text := "-"
	if enemy_to_party_samples > 0:
		avg_enemy_to_party_text = "%.1f" % (avg_enemy_to_party / float(enemy_to_party_samples))
	var min_enemy_to_party_text := "-" if min_enemy_to_party == INF else "%.1f" % min_enemy_to_party
	var min_enemy_to_enemy_text := "-" if min_enemy_to_enemy == INF else "%.1f" % min_enemy_to_enemy
	var avg_push_text := "-"
	if separation_active_count > 0:
		avg_push_text = "%.2f" % (separation_push_sum / float(separation_active_count))
	var avg_slot_offset_text := "-"
	if approach_slot_active_count > 0:
		avg_slot_offset_text = "%.1f" % (approach_slot_offset_sum / float(approach_slot_active_count))
	print(
		"[SPACING] snapshot=%s enemies=%d party=%d min_enemy_party=%s avg_enemy_party=%s min_enemy_enemy=%s sep_active=%d sep_avg_push=%s slot_active=%d slot_avg_offset=%s" % [
			label,
			enemies.size(),
			party_nodes.size(),
			min_enemy_to_party_text,
			avg_enemy_to_party_text,
			min_enemy_to_enemy_text,
			separation_active_count,
			avg_push_text,
			approach_slot_active_count,
			avg_slot_offset_text
		]
	)


func _apply_hitbox_debug_to_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.has_method("set_hitbox_debug_enabled"):
		node.call("set_hitbox_debug_enabled", hitbox_debug_mode_enabled)


func _on_player_health_changed(current: float, maximum: float) -> void:
	player_health_changed.emit(current, maximum)


func _on_player_xp_changed(current: int, needed: int, level: int) -> void:
	player_xp_changed.emit(current, needed, level)


func _on_player_cooldowns_changed(values: Dictionary) -> void:
	cooldowns_changed.emit(values)


func _on_player_item_looted(item_name: String, total_owned: int) -> void:
	item_collected.emit(item_name, total_owned)


func _on_player_died() -> void:
	objective_changed.emit("Objective: Defeat")
	player_died.emit()


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

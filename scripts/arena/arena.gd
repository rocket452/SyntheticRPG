extends Node2D
class_name Arena

enum EncounterType {
	MINOTAUR,
	CACODEMON
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

@export var regular_enemy_count: int = 1
@export var allow_multiple_minotaurs: bool = true
@export var max_active_minotaurs: int = 2
@export var timed_extra_minotaur_enabled: bool = true
@export var timed_extra_minotaur_delay: float = 12.0
@export var spawn_jitter: float = 18.0
@export var arena_min_x: float = -760.0
@export var arena_max_x: float = 760.0
@export var arena_min_y: float = -165.0
@export var arena_max_y: float = 165.0
@export var camera_limit_padding: Vector2 = Vector2(84.0, 60.0)
@export var summoned_minion_edge_inset: float = 28.0
@export var summoned_minion_y_spacing: float = 34.0
@export var summoned_minion_health_scale: float = 0.68
@export var summoned_minion_speed_scale: float = 0.9
@export var summoned_minion_damage_scale: float = 0.82
@export var summoned_minion_xp_scale: float = 0.35
@export var miniboss_health_scale: float = 4.0

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


func _ready() -> void:
	if _is_autoplay_requested():
		rng.seed = 1337
	else:
		rng.randomize()


func _process(delta: float) -> void:
	if not demo_started:
		return
	demo_elapsed += maxf(0.0, delta)
	_try_spawn_timed_extra_minotaur()
	_emit_combat_debug()


func start_demo_with_encounter(encounter_type: int) -> void:
	set_encounter_type(encounter_type)
	start_demo()


func set_encounter_type(encounter_type: int) -> void:
	if encounter_type == EncounterType.CACODEMON:
		selected_encounter = EncounterType.CACODEMON
	else:
		selected_encounter = EncounterType.MINOTAUR


func start_demo() -> void:
	if demo_started:
		return
	demo_started = true
	demo_elapsed = 0.0
	timed_extra_minotaur_spawned = false
	initial_minotaur_spawn_on_left = false
	spawned_minotaurs_total = 0
	_spawn_player()
	_spawn_friendly_healer()
	_spawn_friendly_ratfolk()
	_spawn_regular_enemies()
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
	if ratfolk.has_method("set_player") and is_instance_valid(player):
		ratfolk.set_player(player)
	if ratfolk.has_method("set_arena_bounds"):
		ratfolk.call("set_arena_bounds", arena_min_x, arena_max_x, arena_min_y, arena_max_y)


func _spawn_regular_enemies() -> void:
	alive_regular_enemies = 0
	if selected_encounter == EncounterType.CACODEMON:
		_spawn_cacodemon_encounter()
		return
	var spawn_count := regular_enemy_count
	var minotaur_cap := _get_minotaur_spawn_cap()
	spawn_count = mini(spawn_count, minotaur_cap)
	if spawn_count >= 2:
		_spawn_edge_minotaur_on_side(false, -24.0)
		_spawn_edge_minotaur_on_side(false, 24.0)
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
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var spawn_x := max_x - 42.0
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 10.0, max_y - 10.0)
	var spawn_position := to_global(Vector2(spawn_x, spawn_y))
	var enemy := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position)
	if enemy == null:
		return
	_configure_miniboss(enemy)
	if enemy.has_method("set_monster_visual_profile"):
		enemy.call("set_monster_visual_profile", int(EnemyBase.MonsterVisualProfile.CACODEMON))
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
	var edge_inset := 26.0
	var spawn_x := min_x + edge_inset if spawn_on_left else max_x - edge_inset
	var spawn_y := lerpf(min_y, max_y, 0.5)
	if is_instance_valid(player):
		spawn_y = clampf(player.position.y, min_y + 8.0, max_y - 8.0)
	spawn_y = clampf(spawn_y + vertical_offset, min_y + 8.0, max_y - 8.0)
	var spawn_position := to_global(Vector2(spawn_x, spawn_y))
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


func _spawn_enemy(scene: PackedScene, spawn_position: Vector2) -> EnemyBase:
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		push_error("Failed to instantiate enemy scene: %s" % scene.resource_path)
		return null
	actors.add_child(enemy)
	enemy.global_position = spawn_position
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
	var total_to_spawn := maxi(1, count)
	var min_x := minf(arena_min_x, arena_max_x)
	var max_x := maxf(arena_min_x, arena_max_x)
	var min_y := minf(arena_min_y, arena_max_y)
	var max_y := maxf(arena_min_y, arena_max_y)
	var source_local := to_local(source_enemy.global_position) if is_instance_valid(source_enemy) else Vector2.ZERO
	for i in range(total_to_spawn):
		var spawn_on_left := spawn_next_debug_enemy_on_left
		var spawn_x := (min_x + summoned_minion_edge_inset) if spawn_on_left else (max_x - summoned_minion_edge_inset)
		var y_offset := (float(i) - (float(total_to_spawn - 1) * 0.5)) * summoned_minion_y_spacing
		var spawn_y := clampf(source_local.y + y_offset, min_y + 10.0, max_y - 10.0)
		var spawn_position := to_global(Vector2(spawn_x, spawn_y))
		var minion := _spawn_enemy(MELEE_ENEMY_SCENE, spawn_position)
		if minion == null:
			continue
		minion.is_miniboss = false
		minion.use_single_phase_loop = false
		minion.boss_can_summon_minions = false
		minion.spin_attack_enabled = false
		minion.prioritize_companion_targets = true
		minion.max_health = maxf(10.0, minion.max_health * summoned_minion_health_scale)
		minion.current_health = minion.max_health
		minion.move_speed = maxf(40.0, minion.move_speed * summoned_minion_speed_scale)
		minion.attack_damage = maxf(1.0, minion.attack_damage * summoned_minion_damage_scale)
		minion.xp_reward = maxi(1, int(round(float(minion.xp_reward) * summoned_minion_xp_scale)))
		alive_regular_enemies += 1
		spawn_next_debug_enemy_on_left = not spawn_next_debug_enemy_on_left
	_update_objective()


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

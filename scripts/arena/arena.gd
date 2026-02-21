extends Node2D
class_name Arena

signal player_health_changed(current: float, maximum: float)
signal player_xp_changed(current: int, needed: int, level: int)
signal cooldowns_changed(values: Dictionary)
signal objective_changed(text: String)
signal item_collected(item_name: String, total_owned: int)
signal player_died
signal demo_won

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const FRIENDLY_HEALER_SCENE: PackedScene = preload("res://scenes/npcs/FriendlyHealer.tscn")
const MELEE_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/MeleeEnemy.tscn")
const ITEM_SCENE: PackedScene = preload("res://scenes/items/ItemPickup.tscn")

@export var regular_enemy_count: int = 1
@export var spawn_jitter: float = 18.0
@export var arena_min_x: float = -760.0
@export var arena_max_x: float = 760.0
@export var arena_min_y: float = -165.0
@export var arena_max_y: float = 165.0
@export var camera_limit_padding: Vector2 = Vector2(84.0, 60.0)

@onready var actors: Node2D = $Actors
@onready var drops: Node2D = $Drops
@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var healer_spawn: Marker2D = get_node_or_null("HealerSpawn") as Marker2D

var player: Player = null
var healer: Node2D = null
var alive_regular_enemies: int = 0
var demo_started: bool = false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	if _is_autoplay_requested():
		rng.seed = 1337
	else:
		rng.randomize()


func start_demo() -> void:
	if demo_started:
		return
	demo_started = true
	_spawn_player()
	_spawn_friendly_healer()
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


func _spawn_regular_enemies() -> void:
	alive_regular_enemies = 0
	if spawn_points.is_empty():
		push_error("No spawn points configured in Arena scene.")
		return
	for i in regular_enemy_count:
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
		enemy.is_miniboss = false
		alive_regular_enemies += 1


func _spawn_enemy(scene: PackedScene, spawn_position: Vector2) -> EnemyBase:
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		push_error("Failed to instantiate enemy scene: %s" % scene.resource_path)
		return null
	actors.add_child(enemy)
	enemy.global_position = spawn_position
	_apply_bounds_to_enemy(enemy)
	enemy.died.connect(_on_enemy_died)
	return enemy


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
	objective_changed.emit("Objective: Defeat enemies (%d remaining)" % alive_regular_enemies)


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

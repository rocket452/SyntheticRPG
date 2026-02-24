extends Node
class_name AutoplayTestRunner

@export var approach_distance_x: float = 12.0
@export var approach_distance_y: float = 10.0
@export var charge_hold_duration: float = 0.32
@export var max_attempts: int = 3
@export var timeout_seconds: float = 24.0
@export var settle_time_after_release: float = 1.2

var arena: Arena = null
var player: Player = null
var enemy: EnemyBase = null
var elapsed: float = 0.0
var phase: int = 0
var phase_time: float = 0.0
var attempt_count: int = 0
var saw_hitstop: bool = false
var autoplay_log_path: String = ""


func configure(target_arena: Arena) -> void:
	arena = target_arena


func _ready() -> void:
	autoplay_log_path = OS.get_environment("AUTOPLAY_LOG_PATH")
	if autoplay_log_path.is_empty():
		autoplay_log_path = ProjectSettings.globalize_path("res://artifacts/log.txt")
	_write_log("AUTOPLAY_TEST START")
	_write_log("Loaded test scene")
	set_physics_process(true)


func _exit_tree() -> void:
	_release_all_inputs()


func _physics_process(delta: float) -> void:
	elapsed += delta
	phase_time += delta
	_refresh_refs()
	if elapsed >= timeout_seconds:
		_finish(1, "timeout")
		return
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	if player.is_dead:
		_finish(1, "player_dead")
		return

	match phase:
		0:
			phase = 1
			phase_time = 0.0
		1:
			_step_approach_enemy()
		2:
			_step_charge_hold()
		3:
			_step_wait_for_resolution()
		_:
			pass


func _refresh_refs() -> void:
	if not is_instance_valid(player):
		if is_instance_valid(arena):
			player = arena.player
		if not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(enemy):
		var nearest_enemy: EnemyBase = null
		var nearest_dist_sq := INF
		for node in get_tree().get_nodes_in_group("enemies"):
			var candidate := node as EnemyBase
			if candidate == null or not is_instance_valid(candidate) or candidate.dead:
				continue
			var dist_sq := candidate.global_position.distance_squared_to(player.global_position) if is_instance_valid(player) else INF
			if dist_sq < nearest_dist_sq:
				nearest_dist_sq = dist_sq
				nearest_enemy = candidate
		enemy = nearest_enemy


func _step_approach_enemy() -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	var to_enemy := enemy.global_position - player.global_position
	var input_vector := Vector2.ZERO
	if absf(to_enemy.x) > approach_distance_x:
		input_vector.x = signf(to_enemy.x)
	if absf(to_enemy.y) > approach_distance_y:
		input_vector.y = signf(to_enemy.y)
	_set_move_inputs(input_vector)
	if input_vector == Vector2.ZERO:
		_set_move_inputs(Vector2.ZERO)
		Input.action_press("ability_1")
		phase = 2
		phase_time = 0.0


func _step_charge_hold() -> void:
	if phase_time < charge_hold_duration:
		return
	Input.action_release("ability_1")
	phase = 3
	phase_time = 0.0


func _step_wait_for_resolution() -> void:
	if not is_instance_valid(player):
		return
	_set_move_inputs(Vector2.ZERO)
	if player.hitstop_left > 0.0:
		saw_hitstop = true
	if phase_time < settle_time_after_release:
		return
	if saw_hitstop:
		_finish(0, "ok")
		return
	attempt_count += 1
	if attempt_count >= max_attempts:
		_finish(1, "no_hitstop")
		return
	phase = 1
	phase_time = 0.0
	enemy = null


func _set_move_inputs(direction: Vector2) -> void:
	if direction.y < -0.2:
		Input.action_press("move_up")
	else:
		Input.action_release("move_up")
	if direction.y > 0.2:
		Input.action_press("move_down")
	else:
		Input.action_release("move_down")
	if direction.x < -0.2:
		Input.action_press("move_left")
	else:
		Input.action_release("move_left")
	if direction.x > 0.2:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")


func _release_all_inputs() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "basic_attack", "ability_1", "ability_2", "roll", "block"]:
		Input.action_release(action)


func _finish(quit_code: int, reason: String) -> void:
	_release_all_inputs()
	_write_log("AUTOPLAY_TEST END (quit=%d reason=%s)" % [quit_code, reason])
	call_deferred("_quit_tree", quit_code)


func _quit_tree(quit_code: int) -> void:
	get_tree().quit(quit_code)


func _write_log(message: String) -> void:
	print(message)
	var file := FileAccess.open(autoplay_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(autoplay_log_path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(message)

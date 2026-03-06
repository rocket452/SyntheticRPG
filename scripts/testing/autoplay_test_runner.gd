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
var autoplay_scenario: String = "charge_attack"
var elapsed: float = 0.0
var phase: int = 0
var phase_time: float = 0.0
var attempt_count: int = 0
var saw_hitstop: bool = false
var autoplay_log_path: String = ""
var shadow_fear_primary_enemy_id: int = -1
var shadow_fear_new_enemy_applied: bool = false
var shadow_fear_primary_engaged: bool = false
var shadow_fear_tuned_miniboss_ids: Dictionary = {}
var shadow_fear_layout_variant: int = 0
var shadow_fear_layout_applied: bool = false
var healer_tidal_wave_setup_done: bool = false
var healer_respects_fear_setup_done: bool = false
var healer_respects_fear_start_time: float = -1.0
var healer_respects_fear_health_floor: float = -1.0
var cacodemon_breath_setup_done: bool = false
var cacodemon_breath_started: bool = false
var cacodemon_breath_start_time: float = -1.0
var cacodemon_breath_health_floor: float = -1.0
var cacodemon_breath_stack_setup_done: bool = false
var cacodemon_breath_stack_success_time: float = -1.0
var cacodemon_breath_stack_fire_seen: bool = false
var cacodemon_breath_stack_best_safe_count: int = 0
var cacodemon_fireball_setup_done: bool = false
var cacodemon_fireball_seen: bool = false
var cacodemon_fireball_seen_time: float = -1.0
var cacodemon_fireball_health_floor: float = -1.0
var cacodemon_summon_setup_done: bool = false
var cacodemon_summon_success_time: float = -1.0
var cacodemon_player_hit_setup_done: bool = false
var cacodemon_player_hit_start_time: float = -1.0
var cacodemon_player_hit_health_floor: float = -1.0
var cacodemon_player_hit_last_pulse: int = -1
var cacodemon_natural_fireball_setup_done: bool = false
var cacodemon_natural_fireball_seen: bool = false
var cacodemon_natural_fireball_last_debug_second: int = -1
var cacodemon_fireball_pressure_setup_done: bool = false
var cacodemon_fireball_pressure_seen: bool = false


func configure(target_arena: Arena) -> void:
	arena = target_arena


func _ready() -> void:
	autoplay_scenario = OS.get_environment("AUTOPLAY_SCENARIO").strip_edges().to_lower()
	if autoplay_scenario.is_empty():
		autoplay_scenario = "charge_attack"
	shadow_fear_primary_enemy_id = -1
	shadow_fear_new_enemy_applied = false
	shadow_fear_primary_engaged = false
	shadow_fear_tuned_miniboss_ids.clear()
	shadow_fear_layout_applied = false
	healer_tidal_wave_setup_done = false
	healer_respects_fear_setup_done = false
	healer_respects_fear_start_time = -1.0
	healer_respects_fear_health_floor = -1.0
	cacodemon_breath_setup_done = false
	cacodemon_breath_started = false
	cacodemon_breath_start_time = -1.0
	cacodemon_breath_health_floor = -1.0
	cacodemon_breath_stack_setup_done = false
	cacodemon_breath_stack_success_time = -1.0
	cacodemon_breath_stack_fire_seen = false
	cacodemon_breath_stack_best_safe_count = 0
	cacodemon_fireball_setup_done = false
	cacodemon_fireball_seen = false
	cacodemon_fireball_seen_time = -1.0
	cacodemon_fireball_health_floor = -1.0
	cacodemon_summon_setup_done = false
	cacodemon_summon_success_time = -1.0
	cacodemon_player_hit_setup_done = false
	cacodemon_player_hit_start_time = -1.0
	cacodemon_player_hit_health_floor = -1.0
	cacodemon_player_hit_last_pulse = -1
	cacodemon_natural_fireball_setup_done = false
	cacodemon_natural_fireball_seen = false
	cacodemon_natural_fireball_last_debug_second = -1
	cacodemon_fireball_pressure_setup_done = false
	cacodemon_fireball_pressure_seen = false
	var layout_variant_env := OS.get_environment("AUTOPLAY_LAYOUT_VARIANT").strip_edges()
	shadow_fear_layout_variant = int(layout_variant_env) if layout_variant_env.is_valid_int() else 0
	if autoplay_scenario == "lunge_block" or autoplay_scenario == "basic_block" or autoplay_scenario == "shadow_fear" or autoplay_scenario == "shadow_fear_break" or autoplay_scenario == "shadow_fear_new_enemy" or autoplay_scenario == "healer_tidal_wave" or autoplay_scenario == "healer_respects_fear" or autoplay_scenario == "cacodemon_breath_block" or autoplay_scenario == "cacodemon_breath_stack" or autoplay_scenario == "cacodemon_fireball_block" or autoplay_scenario == "cacodemon_summon_imps" or autoplay_scenario == "cacodemon_player_hit" or autoplay_scenario == "cacodemon_fireball_natural" or autoplay_scenario == "cacodemon_fireball_pressure":
		timeout_seconds = maxf(timeout_seconds, 45.0)
	autoplay_log_path = OS.get_environment("AUTOPLAY_LOG_PATH")
	if autoplay_log_path.is_empty():
		autoplay_log_path = ProjectSettings.globalize_path("res://artifacts/log.txt")
	_write_log("AUTOPLAY_TEST START")
	_write_log("Loaded test scene (scenario=%s)" % autoplay_scenario)
	set_physics_process(true)


func _exit_tree() -> void:
	_release_all_inputs()


func _physics_process(delta: float) -> void:
	elapsed += delta
	phase_time += delta
	_refresh_refs()
	if elapsed >= timeout_seconds:
		_finish(1, "timeout_%s" % autoplay_scenario)
		return
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	if player.is_dead:
		_finish(1, "player_dead")
		return

	if autoplay_scenario == "lunge_block":
		_step_lunge_block_scenario()
		return
	if autoplay_scenario == "basic_block":
		_step_basic_block_scenario()
		return
	if autoplay_scenario == "shadow_fear":
		_step_shadow_fear_scenario()
		return
	if autoplay_scenario == "shadow_fear_break":
		_step_shadow_fear_scenario()
		return
	if autoplay_scenario == "shadow_fear_new_enemy":
		_step_shadow_fear_new_enemy_scenario()
		return
	if autoplay_scenario == "healer_tidal_wave":
		_step_healer_tidal_wave_scenario()
		return
	if autoplay_scenario == "healer_respects_fear":
		_step_healer_respects_fear_scenario()
		return
	if autoplay_scenario == "cacodemon_breath_block":
		_step_cacodemon_breath_block_scenario()
		return
	if autoplay_scenario == "cacodemon_breath_stack":
		_step_cacodemon_breath_stack_scenario()
		return
	if autoplay_scenario == "cacodemon_fireball_block":
		_step_cacodemon_fireball_block_scenario()
		return
	if autoplay_scenario == "cacodemon_summon_imps":
		_step_cacodemon_summon_imps_scenario()
		return
	if autoplay_scenario == "cacodemon_player_hit":
		_step_cacodemon_player_hit_scenario()
		return
	if autoplay_scenario == "cacodemon_fireball_natural":
		_step_cacodemon_natural_fireball_scenario()
		return
	if autoplay_scenario == "cacodemon_fireball_pressure":
		_step_cacodemon_fireball_pressure_scenario()
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


func _step_lunge_block_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return

	var threatened := false
	var marked_target: Node2D = null
	if enemy.has_method("is_lunge_threatening_marked_ally"):
		threatened = bool(enemy.call("is_lunge_threatening_marked_ally"))
	if threatened and enemy.has_method("get_marked_ally_node"):
		marked_target = enemy.call("get_marked_ally_node") as Node2D

	if threatened and marked_target != null and is_instance_valid(marked_target):
		var intercept_point := marked_target.global_position
		if enemy.has_method("get_guardian_intercept_point"):
			var intercept_variant: Variant = enemy.call("get_guardian_intercept_point", marked_target.global_position)
			if intercept_variant is Vector2:
				intercept_point = intercept_variant
		var to_intercept := intercept_point - player.global_position
		if to_intercept.length() > 52.0:
			_set_move_inputs(to_intercept.normalized())
			Input.action_press("block")
		else:
			_set_move_inputs(Vector2.ZERO)
			Input.action_press("block")
	else:
		Input.action_release("block")
		var to_enemy := enemy.global_position - player.global_position
		var desired_distance := 72.0
		if to_enemy.length() > desired_distance + 12.0:
			_set_move_inputs(to_enemy.normalized())
		elif to_enemy.length() < desired_distance - 12.0:
			_set_move_inputs((-to_enemy).normalized())
		else:
			_set_move_inputs(Vector2.ZERO)

	var impact_reason := String(enemy.get("boss_lunge_last_impact_reason")).strip_edges().to_lower()
	if impact_reason == "shield_intercept":
		_finish(0, "shield_intercept")


func _step_basic_block_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return

	enemy.use_single_phase_loop = false
	enemy.spin_attack_enabled = false

	var block_fx_count := int(enemy.get("block_success_fx_count"))
	if block_fx_count > 0:
		_finish(0, "basic_block_fx")
		return

	var to_enemy := enemy.global_position - player.global_position
	var attack_range := maxf(28.0, enemy.attack_range)
	var desired_distance := attack_range - 6.0
	if to_enemy.length() > desired_distance + 8.0:
		Input.action_release("block")
		_set_move_inputs(to_enemy.normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
		Input.action_press("block")


func _step_shadow_fear_scenario() -> void:
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	if is_instance_valid(arena):
		arena.allow_multiple_minotaurs = true
	boss_enemy.spin_attack_enabled = false
	boss_enemy.boss_summon_interval = minf(boss_enemy.boss_summon_interval, 4.0)
	boss_enemy.boss_summon_cycle_left = minf(float(boss_enemy.get("boss_summon_cycle_left")), 0.2)
	if get_tree().get_nodes_in_group("enemies").size() < 2 and is_instance_valid(arena):
		arena.call("_on_enemy_summon_minions_requested", boss_enemy, 2)

	for node in get_tree().get_nodes_in_group("enemies"):
		var candidate := node as EnemyBase
		if candidate == null or not is_instance_valid(candidate) or candidate.dead or candidate.is_miniboss:
			continue
		if candidate.has_method("is_shadow_fear_active") and bool(candidate.call("is_shadow_fear_active")):
			if autoplay_scenario == "shadow_fear_break":
				candidate.receive_hit(1.0, player.global_position, 0.0, false, 1.0, player)
				if not bool(candidate.call("is_shadow_fear_active")):
					_finish(0, "shadow_fear_break")
				return
			_finish(0, "shadow_fear")
			return

	var to_boss := boss_enemy.global_position - player.global_position
	var desired_distance := 92.0
	if to_boss.length() > desired_distance + 14.0:
		Input.action_release("block")
		_set_move_inputs(to_boss.normalized())
	elif to_boss.length() < desired_distance - 16.0:
		Input.action_release("block")
		_set_move_inputs((-to_boss).normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
		Input.action_press("block")


func _step_shadow_fear_new_enemy_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return

	arena.allow_multiple_minotaurs = true
	arena.max_active_minotaurs = maxi(2, arena.max_active_minotaurs)
	arena.timed_extra_minotaur_enabled = true
	arena.timed_extra_minotaur_delay = 12.0

	var minibosses: Array[EnemyBase] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var candidate := node as EnemyBase
		if candidate == null or not is_instance_valid(candidate) or candidate.dead:
			continue
		if not candidate.is_miniboss:
			continue
		var candidate_id := candidate.get_instance_id()
		if not shadow_fear_tuned_miniboss_ids.has(candidate_id):
			candidate.max_health = maxf(candidate.max_health, 1000.0)
			candidate.current_health = candidate.max_health
			shadow_fear_tuned_miniboss_ids[candidate_id] = true
		candidate.boss_can_summon_minions = false
		candidate.boss_summon_count = 0
		candidate.spin_attack_enabled = false
		candidate.use_single_phase_loop = false
		candidate.attack_cooldown = maxf(candidate.attack_cooldown, 3.5)
		candidate.attack_damage = minf(candidate.attack_damage, 2.0)
		candidate.move_speed = 0.0
		minibosses.append(candidate)
	if minibosses.is_empty():
		return

	if shadow_fear_primary_enemy_id < 0:
		var lowest_id := INF
		for candidate in minibosses:
			var candidate_id := candidate.get_instance_id()
			if candidate_id < lowest_id:
				lowest_id = candidate_id
		shadow_fear_primary_enemy_id = int(lowest_id)

	var primary_enemy: EnemyBase = null
	var newest_enemy: EnemyBase = null
	var newest_id := -1
	for candidate in minibosses:
		var candidate_id := candidate.get_instance_id()
		if candidate_id == shadow_fear_primary_enemy_id:
			primary_enemy = candidate
		if candidate_id > newest_id:
			newest_id = candidate_id
			newest_enemy = candidate
	if primary_enemy == null:
		primary_enemy = minibosses[0]
	_apply_shadow_fear_opening_layout(primary_enemy)
	if is_instance_valid(arena.ratfolk) and arena.ratfolk.get("target_enemy") == primary_enemy:
		shadow_fear_primary_engaged = true
	if minibosses.size() >= 2 and newest_enemy != null and newest_enemy != primary_enemy:
		var newest_apply_count := int(newest_enemy.get("shadow_fear_apply_count"))
		if newest_apply_count > 0:
			shadow_fear_new_enemy_applied = true
		if shadow_fear_primary_engaged and shadow_fear_new_enemy_applied:
			var rat_target_matches_primary := true
			if is_instance_valid(arena.ratfolk):
				rat_target_matches_primary = arena.ratfolk.get("target_enemy") == primary_enemy
			if rat_target_matches_primary:
				_finish(0, "shadow_fear_new_enemy")
				return

	var to_primary := primary_enemy.global_position - player.global_position
	var desired_distance := 128.0
	if to_primary.length() > desired_distance + 14.0:
		Input.action_release("block")
		_set_move_inputs(to_primary.normalized())
	elif to_primary.length() < desired_distance - 16.0:
		Input.action_release("block")
		_set_move_inputs((-to_primary).normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
		Input.action_press("block")


func _step_healer_tidal_wave_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = false
	boss_enemy.move_speed = 0.0
	boss_enemy.attack_cooldown = maxf(boss_enemy.attack_cooldown, 3.5)
	boss_enemy.attack_damage = minf(boss_enemy.attack_damage, 2.0)
	boss_enemy.max_health = maxf(boss_enemy.max_health, 1000.0)
	boss_enemy.current_health = boss_enemy.max_health

	if not healer_tidal_wave_setup_done:
		_apply_healer_tidal_wave_layout(boss_enemy)
		if is_instance_valid(player):
			player.current_health = maxf(1.0, player.current_health - 24.0)
			if player.has_method("_update_health_bar"):
				player.call("_update_health_bar")
		if is_instance_valid(arena.healer):
			arena.healer.set("tidal_wave_cooldown_left", 0.0)
			var light_bolt_cooldown_value: float = 0.4
			var light_bolt_cooldown_variant: Variant = arena.healer.get("light_bolt_cooldown")
			if light_bolt_cooldown_variant is float or light_bolt_cooldown_variant is int:
				light_bolt_cooldown_value = light_bolt_cooldown_variant
			arena.healer.set("light_bolt_cooldown_left", maxf(0.4, light_bolt_cooldown_value))
			arena.healer.set("basic_heal_cooldown_left", 0.0)
			arena.healer.set("heal_timer_left", 0.0)
		healer_tidal_wave_setup_done = true
		_write_log("Healer tidal wave setup applied")

	if is_instance_valid(arena.healer):
		var active_waves: Variant = arena.healer.get("active_tidal_waves")
		if active_waves is Array and (active_waves as Array).size() > 0:
			_finish(0, "healer_tidal_wave")
			return

	var to_boss := boss_enemy.global_position - player.global_position
	var desired_distance := 128.0
	if to_boss.length() > desired_distance + 14.0:
		Input.action_release("block")
		_set_move_inputs(to_boss.normalized())
	elif to_boss.length() < desired_distance - 16.0:
		Input.action_release("block")
		_set_move_inputs((-to_boss).normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
		Input.action_press("block")


func _step_healer_respects_fear_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = false
	boss_enemy.move_speed = 0.0
	boss_enemy.attack_cooldown = maxf(boss_enemy.attack_cooldown, 3.5)
	boss_enemy.attack_damage = minf(boss_enemy.attack_damage, 2.0)
	boss_enemy.max_health = maxf(boss_enemy.max_health, 1000.0)
	boss_enemy.current_health = boss_enemy.max_health

	if not healer_respects_fear_setup_done:
		_apply_healer_tidal_wave_layout(boss_enemy)
		if is_instance_valid(player):
			player.current_health = maxf(1.0, player.current_health - 24.0)
			healer_respects_fear_health_floor = player.current_health
			if player.has_method("_update_health_bar"):
				player.call("_update_health_bar")
		if is_instance_valid(arena.healer):
			arena.healer.set("tidal_wave_cooldown_left", 0.0)
			arena.healer.set("light_bolt_cooldown_left", 0.0)
			arena.healer.set("basic_heal_cooldown_left", 0.0)
			arena.healer.set("heal_timer_left", 0.0)
		if boss_enemy.has_method("apply_shadow_fear"):
			boss_enemy.call("apply_shadow_fear", 5.0)
		healer_respects_fear_setup_done = true
		healer_respects_fear_start_time = elapsed
		_write_log("Healer respects fear setup applied")

	_set_move_inputs(Vector2.ZERO)
	Input.action_press("block")

	var scenario_elapsed := maxf(0.0, elapsed - healer_respects_fear_start_time)
	var fear_active := bool(boss_enemy.call("is_shadow_fear_active")) if boss_enemy.has_method("is_shadow_fear_active") else false
	if scenario_elapsed >= 0.45 and not fear_active:
		_finish(1, "healer_broke_fear")
		return
	var player_healed := is_instance_valid(player) and player.current_health > healer_respects_fear_health_floor + 0.1
	if scenario_elapsed >= 2.4:
		if not fear_active:
			_finish(1, "healer_broke_fear")
			return
		if not player_healed:
			_finish(1, "healer_no_heal")
			return
		_finish(0, "healer_respects_fear")
		return


func _step_cacodemon_breath_block_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.attack_cooldown_left = 0.0
	boss_enemy.cacodemon_breath_first_use_left = 0.0
	var breath_style_override := OS.get_environment("CACODEMON_BREATH_STYLE").strip_edges()
	if breath_style_override != "" and breath_style_override.is_valid_int():
		boss_enemy.cacodemon_breath_visual_style = clampi(int(breath_style_override), 0, 4)
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", _get_air_boss_debug_visual_profile())

	if not cacodemon_breath_setup_done:
		var min_x := minf(arena.arena_min_x, arena.arena_max_x)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		var player_pos := Vector2(max_x - 360.0, clampf(10.0, min_y + 8.0, max_y - 8.0))
		var enemy_pos := Vector2(max_x - 160.0, clampf(10.0, min_y + 8.0, max_y - 8.0))
		player.global_position = arena.to_global(player_pos)
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(enemy_pos)
			enemy_body.velocity = Vector2.ZERO
		cacodemon_breath_health_floor = player.current_health
		cacodemon_breath_setup_done = true
		_write_log("Cacodemon breath block setup applied")
		_write_log("Cacodemon breath style=%d" % boss_enemy.cacodemon_breath_visual_style)
		if boss_enemy.has_method("debug_force_cacodemon_breath"):
			boss_enemy.call("debug_force_cacodemon_breath")

	var to_boss := boss_enemy.global_position - player.global_position
	var desired_distance := 178.0
	if to_boss.length() > desired_distance + 12.0:
		_set_move_inputs(to_boss.normalized())
	elif to_boss.length() < desired_distance - 12.0:
		_set_move_inputs((-to_boss).normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
	Input.action_press("block")

	var breath_left := float(boss_enemy.get("cacodemon_breath_left"))
	if breath_left > 0.0:
		if not cacodemon_breath_started:
			cacodemon_breath_started = true
			cacodemon_breath_start_time = elapsed
			_write_log("Cacodemon breath observed")
		if elapsed - cacodemon_breath_start_time >= 2.8:
			if player.current_health < cacodemon_breath_health_floor - 0.1:
				_finish(1, "cacodemon_breath_block_failed")
				return
			_finish(0, "cacodemon_breath_block")
			return


func _step_cacodemon_breath_stack_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.move_speed = 0.0
	boss_enemy.attack_damage = minf(boss_enemy.attack_damage, 1.0)
	boss_enemy.attack_cooldown_left = 0.0
	boss_enemy.cacodemon_breath_first_use_left = 0.0
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", _get_air_boss_debug_visual_profile())

	if not cacodemon_breath_stack_setup_done:
		var min_x := minf(arena.arena_min_x, arena.arena_max_x)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		var player_pos := Vector2(max_x - 360.0, clampf(8.0, min_y + 8.0, max_y - 8.0))
		var enemy_pos := Vector2(max_x - 140.0, clampf(8.0, min_y + 8.0, max_y - 8.0))
		var healer_pos := Vector2(max_x - 300.0, clampf(-78.0, min_y + 8.0, max_y - 8.0))
		var rat_pos := Vector2(max_x - 290.0, clampf(84.0, min_y + 8.0, max_y - 8.0))
		player.global_position = arena.to_global(player_pos)
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(enemy_pos)
			enemy_body.velocity = Vector2.ZERO
		if is_instance_valid(arena.healer):
			arena.healer.global_position = arena.to_global(healer_pos)
			arena.healer.move_velocity = Vector2.ZERO
		if is_instance_valid(arena.ratfolk):
			arena.ratfolk.global_position = arena.to_global(rat_pos)
			arena.ratfolk.velocity = Vector2.ZERO
		if boss_enemy.has_method("debug_force_cacodemon_breath"):
			boss_enemy.call("debug_force_cacodemon_breath")
		cacodemon_breath_stack_setup_done = true
		_write_log("Cacodemon breath stack setup applied")
		if boss_enemy.has_method("debug_force_cacodemon_breath"):
			boss_enemy.call("debug_force_cacodemon_breath")

	_set_move_inputs(Vector2.ZERO)
	Input.action_press("block")

	if not boss_enemy.has_method("get_breath_threat_snapshot"):
		return
	var snapshot_variant: Variant = boss_enemy.call("get_breath_threat_snapshot")
	if not (snapshot_variant is Dictionary):
		return
	var snapshot := snapshot_variant as Dictionary
	if bool(snapshot.get("fire_active", false)):
		cacodemon_breath_stack_fire_seen = true
	var companion_safe_count := _count_companions_in_safe_pocket(snapshot)
	if companion_safe_count > cacodemon_breath_stack_best_safe_count:
		cacodemon_breath_stack_best_safe_count = companion_safe_count
		_write_log("Cacodemon stack safe_count=%d" % companion_safe_count)
	if bool(snapshot.get("active", false)) and cacodemon_breath_stack_fire_seen and companion_safe_count >= 2:
		if cacodemon_breath_stack_success_time < 0.0:
			cacodemon_breath_stack_success_time = elapsed
		elif elapsed - cacodemon_breath_stack_success_time >= 0.25:
			_finish(0, "cacodemon_breath_stack")
			return
	else:
		cacodemon_breath_stack_success_time = -1.0

	if cacodemon_breath_stack_fire_seen and not bool(snapshot.get("active", false)):
		_finish(1, "cacodemon_breath_stack_failed")
		return


func _step_cacodemon_fireball_block_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.move_speed = 0.0
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", int(EnemyBase.MonsterVisualProfile.CACODEMON))

	if not cacodemon_fireball_setup_done:
		var min_x := minf(arena.arena_min_x, arena.arena_max_x)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		var player_pos := Vector2(max_x - 360.0, clampf(10.0, min_y + 8.0, max_y - 8.0))
		var enemy_pos := Vector2(max_x - 170.0, clampf(10.0, min_y + 8.0, max_y - 8.0))
		player.global_position = arena.to_global(player_pos)
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(enemy_pos)
			enemy_body.velocity = Vector2.ZERO
		boss_enemy.cacodemon_fireball_first_use_left = 0.0
		boss_enemy.cacodemon_fireball_cooldown_left = 0.0
		boss_enemy.cacodemon_fireball_enabled = true
		cacodemon_fireball_health_floor = player.current_health
		cacodemon_fireball_setup_done = true
		_write_log("Cacodemon fireball block setup applied")
		if boss_enemy.has_method("debug_force_cacodemon_breath"):
			boss_enemy.call("debug_force_cacodemon_breath")

	var to_boss := boss_enemy.global_position - player.global_position
	var desired_distance := 176.0
	if to_boss.length() > desired_distance + 10.0:
		_set_move_inputs(to_boss.normalized())
	elif to_boss.length() < desired_distance - 10.0:
		_set_move_inputs((-to_boss).normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
	Input.action_press("block")

	var active_fireballs := get_tree().get_nodes_in_group("cacodemon_fireballs").size()
	var fireball_cast_active := bool(boss_enemy.get("cacodemon_fireball_pending")) or float(boss_enemy.get("cacodemon_fireball_cast_left")) > 0.0
	if (active_fireballs > 0 or fireball_cast_active) and not cacodemon_fireball_seen:
		cacodemon_fireball_seen = true
		cacodemon_fireball_seen_time = elapsed
		_write_log("Cacodemon fireball observed")
	if cacodemon_fireball_seen and elapsed - cacodemon_fireball_seen_time >= 1.2:
		if player.current_health < cacodemon_fireball_health_floor - 0.1:
			_finish(1, "cacodemon_fireball_block_failed")
			return
		_finish(0, "cacodemon_fireball_block")
		return


func _step_cacodemon_summon_imps_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.move_speed = 0.0
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", int(EnemyBase.MonsterVisualProfile.CACODEMON))

	if not cacodemon_summon_setup_done:
		var min_x := minf(arena.arena_min_x, arena.arena_max_x)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		player.global_position = arena.to_global(Vector2(max_x - 360.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(Vector2(max_x - 170.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
			enemy_body.velocity = Vector2.ZERO
		boss_enemy.boss_can_summon_minions = true
		boss_enemy.boss_summon_count = 4
		boss_enemy.boss_summon_cycle_left = 0.0
		var summon_trigger_ratio := clampf(float(boss_enemy.get("cacodemon_summon_health_trigger_ratio")), 0.0, 1.0)
		boss_enemy.current_health = minf(
			boss_enemy.current_health,
			maxf(1.0, boss_enemy.max_health * maxf(0.05, summon_trigger_ratio - 0.05))
		)
		if boss_enemy.has_method("_update_health_bar"):
			boss_enemy.call("_update_health_bar")
		cacodemon_summon_setup_done = true
		_write_log("Cacodemon summon setup applied")

	_set_move_inputs(Vector2.ZERO)
	Input.action_press("block")

	var imp_count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		var candidate := node as EnemyBase
		if candidate == null or not is_instance_valid(candidate) or candidate.dead or candidate.is_miniboss:
			continue
		if candidate.monster_visual_profile == EnemyBase.MonsterVisualProfile.IMP:
			imp_count += 1
	var required_imp_count := maxi(1, int(boss_enemy.get("boss_summon_count")))
	if imp_count >= required_imp_count:
		if cacodemon_summon_success_time < 0.0:
			cacodemon_summon_success_time = elapsed
			_write_log("Cacodemon summoned imps=%d" % imp_count)
		elif elapsed - cacodemon_summon_success_time >= 1.8:
			_finish(0, "cacodemon_summon_imps")
			return


func _step_cacodemon_player_hit_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.move_speed = 0.0
	boss_enemy.spin_attack_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.cacodemon_fireball_enabled = false
	boss_enemy.cacodemon_fireball_first_use_left = 99.0
	boss_enemy.cacodemon_fireball_cooldown_left = 99.0
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", int(EnemyBase.MonsterVisualProfile.CACODEMON))

	if not cacodemon_player_hit_setup_done:
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		player.global_position = arena.to_global(Vector2(max_x - 320.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(Vector2(max_x - 256.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
			enemy_body.velocity = Vector2.ZERO
		cacodemon_player_hit_health_floor = boss_enemy.current_health
		cacodemon_player_hit_start_time = elapsed
		cacodemon_player_hit_last_pulse = -1
		cacodemon_player_hit_setup_done = true
		_write_log("Cacodemon player-hit setup applied health=%.2f" % boss_enemy.current_health)

	Input.action_release("block")
	var to_boss := boss_enemy.global_position - player.global_position
	if to_boss.length() > 56.0:
		_set_move_inputs(to_boss.normalized())
	else:
		_set_move_inputs(Vector2.ZERO)

	var elapsed_since_start := maxf(0.0, elapsed - cacodemon_player_hit_start_time)
	var pulse := int(floor(elapsed_since_start / 0.24))
	if pulse != cacodemon_player_hit_last_pulse:
		cacodemon_player_hit_last_pulse = pulse
		if (pulse % 2) == 0:
			Input.action_press("basic_attack")
		else:
			Input.action_release("basic_attack")

	if boss_enemy.current_health < cacodemon_player_hit_health_floor - 0.1:
		_write_log("Cacodemon took player damage before=%.2f after=%.2f" % [cacodemon_player_hit_health_floor, boss_enemy.current_health])
		_finish(0, "cacodemon_player_hit")
		return
	if elapsed_since_start >= 7.0:
		_finish(1, "cacodemon_player_hit_failed")


func _step_cacodemon_natural_fireball_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.spin_attack_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.cacodemon_fireball_enabled = true
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", int(EnemyBase.MonsterVisualProfile.CACODEMON))

	if not cacodemon_natural_fireball_setup_done:
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		player.global_position = arena.to_global(Vector2(max_x - 380.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(Vector2(max_x - 180.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
			enemy_body.velocity = Vector2.ZERO
		cacodemon_natural_fireball_setup_done = true
		_write_log("Cacodemon natural fireball setup applied")

	var to_boss := boss_enemy.global_position - player.global_position
	var desired_distance := 176.0
	if to_boss.length() > desired_distance + 12.0:
		_set_move_inputs(to_boss.normalized())
	elif to_boss.length() < desired_distance - 12.0:
		_set_move_inputs((-to_boss).normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
	Input.action_release("block")

	var active_fireballs := get_tree().get_nodes_in_group("cacodemon_fireballs").size()
	var fireball_cast_active := bool(boss_enemy.get("cacodemon_fireball_pending")) or float(boss_enemy.get("cacodemon_fireball_cast_left")) > 0.0
	if (active_fireballs > 0 or fireball_cast_active) and not cacodemon_natural_fireball_seen:
		cacodemon_natural_fireball_seen = true
		_write_log("Cacodemon natural fireball observed")
		_finish(0, "cacodemon_fireball_natural")
		return
	var debug_second := int(floor(elapsed))
	if debug_second != cacodemon_natural_fireball_last_debug_second:
		cacodemon_natural_fireball_last_debug_second = debug_second
		_write_log(
			"NaturalFB t=%.2f first=%.2f cd=%.2f pending=%s cast=%.2f attack=%.2f rec=%.2f dist=%.1f" % [
				elapsed,
				float(boss_enemy.get("cacodemon_fireball_first_use_left")),
				float(boss_enemy.get("cacodemon_fireball_cooldown_left")),
				("true" if bool(boss_enemy.get("cacodemon_fireball_pending")) else "false"),
				float(boss_enemy.get("cacodemon_fireball_cast_left")),
				float(boss_enemy.get("attack_anim_left")),
				float(boss_enemy.get("attack_recovery_hold_left")),
				to_boss.length()
			]
		)


func _step_cacodemon_fireball_pressure_scenario() -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	var boss_enemy := _get_boss_enemy()
	if boss_enemy == null:
		return

	arena.allow_multiple_minotaurs = false
	arena.max_active_minotaurs = 1
	arena.timed_extra_minotaur_enabled = false
	boss_enemy.use_single_phase_loop = true
	boss_enemy.spin_attack_enabled = false
	boss_enemy.boss_can_summon_minions = false
	boss_enemy.boss_summon_count = 0
	boss_enemy.cacodemon_fireball_enabled = true
	if boss_enemy.has_method("set_monster_visual_profile"):
		boss_enemy.call("set_monster_visual_profile", int(EnemyBase.MonsterVisualProfile.CACODEMON))

	if not cacodemon_fireball_pressure_setup_done:
		var min_y := minf(arena.arena_min_y, arena.arena_max_y)
		var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
		var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
		player.global_position = arena.to_global(Vector2(max_x - 320.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
		player.velocity = Vector2.ZERO
		var enemy_body := boss_enemy as CharacterBody2D
		if enemy_body != null:
			enemy_body.global_position = arena.to_global(Vector2(max_x - 250.0, clampf(10.0, min_y + 8.0, max_y - 8.0)))
			enemy_body.velocity = Vector2.ZERO
		cacodemon_fireball_pressure_setup_done = true
		_write_log("Cacodemon pressure fireball setup applied")

	var to_boss := boss_enemy.global_position - player.global_position
	if to_boss.length() > 62.0:
		_set_move_inputs(to_boss.normalized())
	else:
		_set_move_inputs(Vector2.ZERO)
	Input.action_release("block")
	Input.action_press("basic_attack")

	var active_fireballs := get_tree().get_nodes_in_group("cacodemon_fireballs").size()
	var fireball_cast_active := bool(boss_enemy.get("cacodemon_fireball_pending")) or float(boss_enemy.get("cacodemon_fireball_cast_left")) > 0.0
	if (active_fireballs > 0 or fireball_cast_active) and not cacodemon_fireball_pressure_seen:
		cacodemon_fireball_pressure_seen = true
		_write_log("Cacodemon pressure fireball observed")
		_finish(0, "cacodemon_fireball_pressure")


func _apply_shadow_fear_opening_layout(primary_enemy: EnemyBase) -> void:
	if shadow_fear_layout_applied:
		return
	if not is_instance_valid(arena) or not is_instance_valid(player) or not is_instance_valid(arena.ratfolk):
		return
	if primary_enemy == null or not is_instance_valid(primary_enemy) or primary_enemy.dead:
		return
	var min_x := minf(arena.arena_min_x, arena.arena_max_x)
	var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
	var min_y := minf(arena.arena_min_y, arena.arena_max_y)
	var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
	var player_pos := Vector2(max_x - 420.0, clampf(18.0, min_y + 8.0, max_y - 8.0))
	var rat_pos := Vector2(max_x - 300.0, clampf(-6.0, min_y + 8.0, max_y - 8.0))
	var first_enemy_pos := Vector2(max_x - 190.0, clampf(12.0, min_y + 8.0, max_y - 8.0))
	match posmod(shadow_fear_layout_variant, 3):
		1:
			player_pos = Vector2(max_x - 460.0, clampf(-42.0, min_y + 8.0, max_y - 8.0))
			rat_pos = Vector2(max_x - 330.0, clampf(-10.0, min_y + 8.0, max_y - 8.0))
			first_enemy_pos = Vector2(max_x - 210.0, clampf(-48.0, min_y + 8.0, max_y - 8.0))
		2:
			player_pos = Vector2(max_x - 400.0, clampf(76.0, min_y + 8.0, max_y - 8.0))
			rat_pos = Vector2(max_x - 280.0, clampf(38.0, min_y + 8.0, max_y - 8.0))
			first_enemy_pos = Vector2(max_x - 170.0, clampf(58.0, min_y + 8.0, max_y - 8.0))
	player.global_position = arena.to_global(player_pos)
	player.velocity = Vector2.ZERO
	var rat_body := arena.ratfolk as CharacterBody2D
	if rat_body != null:
		rat_body.global_position = arena.to_global(rat_pos)
		rat_body.velocity = Vector2.ZERO
	var first_enemy := primary_enemy as CharacterBody2D
	if first_enemy != null:
		first_enemy.global_position = arena.to_global(first_enemy_pos)
		first_enemy.velocity = Vector2.ZERO
	shadow_fear_layout_applied = true
	_write_log("Shadow fear layout variant=%d" % posmod(shadow_fear_layout_variant, 3))


func _count_companions_in_safe_pocket(snapshot: Dictionary) -> int:
	if snapshot.is_empty():
		return 0
	var count := 0
	var actors: Array[Node2D] = []
	if is_instance_valid(arena.healer):
		actors.append(arena.healer)
	if is_instance_valid(arena.ratfolk):
		actors.append(arena.ratfolk)
	for actor in actors:
		if not is_instance_valid(actor):
			continue
		if _is_position_in_snapshot_safe_pocket(actor.global_position, snapshot):
			count += 1
	return count


func _is_position_in_snapshot_safe_pocket(world_position: Vector2, snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("safe_pocket_valid", false)):
		return false
	var center: Vector2 = snapshot.get("safe_pocket_center", Vector2.ZERO)
	var dir: Vector2 = snapshot.get("dir", Vector2.RIGHT)
	var half_depth := maxf(1.0, float(snapshot.get("safe_pocket_half_depth", 32.0)))
	var half_width := maxf(1.0, float(snapshot.get("safe_pocket_half_width", 36.0)))
	var delta := world_position - center
	var local_x := delta.dot(dir)
	var local_y := delta.dot(Vector2(-dir.y, dir.x))
	var normalized_x := local_x / half_depth
	var normalized_y := local_y / half_width
	return (normalized_x * normalized_x) + (normalized_y * normalized_y) <= 1.0


func _apply_healer_tidal_wave_layout(primary_enemy: EnemyBase) -> void:
	if not is_instance_valid(arena) or not is_instance_valid(player) or not is_instance_valid(arena.healer):
		return
	if primary_enemy == null or not is_instance_valid(primary_enemy) or primary_enemy.dead:
		return
	var min_x := minf(arena.arena_min_x, arena.arena_max_x)
	var max_x := maxf(arena.arena_min_x, arena.arena_max_x)
	var min_y := minf(arena.arena_min_y, arena.arena_max_y)
	var max_y := maxf(arena.arena_min_y, arena.arena_max_y)
	var player_pos := Vector2(max_x - 430.0, clampf(16.0, min_y + 8.0, max_y - 8.0))
	var healer_pos := Vector2(max_x - 560.0, clampf(12.0, min_y + 8.0, max_y - 8.0))
	var rat_pos := Vector2(max_x - 470.0, clampf(-12.0, min_y + 8.0, max_y - 8.0))
	var enemy_pos := Vector2(max_x - 230.0, clampf(14.0, min_y + 8.0, max_y - 8.0))
	player.global_position = arena.to_global(player_pos)
	player.velocity = Vector2.ZERO
	var healer_body := arena.healer as Node2D
	if healer_body != null:
		healer_body.global_position = arena.to_global(healer_pos)
	var rat_body := arena.ratfolk as CharacterBody2D
	if rat_body != null:
		rat_body.global_position = arena.to_global(rat_pos)
		rat_body.velocity = Vector2.ZERO
	var enemy_body := primary_enemy as CharacterBody2D
	if enemy_body != null:
		enemy_body.global_position = arena.to_global(enemy_pos)
		enemy_body.velocity = Vector2.ZERO


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


func _get_boss_enemy() -> EnemyBase:
	for node in get_tree().get_nodes_in_group("enemies"):
		var candidate := node as EnemyBase
		if candidate == null or not is_instance_valid(candidate) or candidate.dead:
			continue
		if candidate.is_miniboss:
			return candidate
	return null


func _get_air_boss_debug_visual_profile() -> int:
	var encounter_raw := OS.get_environment("AUTOPLAY_ENCOUNTER").strip_edges().to_lower()
	if autoplay_scenario == "cacodemon_breath_block" or autoplay_scenario == "cacodemon_breath_stack":
		return int(EnemyBase.MonsterVisualProfile.SHARDSOUL)
	if encounter_raw == "shardsoul" or encounter_raw == "3":
		return int(EnemyBase.MonsterVisualProfile.SHARDSOUL)
	return int(EnemyBase.MonsterVisualProfile.CACODEMON)


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

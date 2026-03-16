extends SceneTree

func _init() -> void:
	call_deferred("_run_probe")

func _clear_non_cooldown_blockers(player: Node) -> void:
	player.set("attack_windup_left", 0.0)
	player.set("attack_anim_left", 0.0)
	player.set("light_attack_recovery_left", 0.0)
	player.set("queued_attack", 0)
	player.set("is_blocking", false)
	player.set("is_rolling", false)
	player.set("lunge_time_left", 0.0)
	player.set("stun_left", 0.0)
	player.set("is_charging_attack", false)
	player.set("charge_release_windup_left", 0.0)
	player.set("charge_attack_active_left", 0.0)
	player.set("charge_attack_recovery_left", 0.0)

func _run_probe() -> void:
	var packed: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = packed.instantiate()
	root.add_child(player)
	await process_frame

	player.set("basic_attack_cooldown", 1.35)
	player.set("basic_attack_input_buffer_window", 0.15)
	player.set("basic_attack_cadence_debug_logging", false)
	_clear_non_cooldown_blockers(player)

	var accepted_times: Array[float] = []
	var t: float = 0.0
	while t <= 4.05:
		if bool(player.call("_try_start_basic_attack", false, "probe_mash")):
			accepted_times.append(t)
		player.call("_tick_timers", 0.05)
		_clear_non_cooldown_blockers(player)
		t += 0.05

	var min_delta := INF
	for i in range(1, accepted_times.size()):
		min_delta = minf(min_delta, accepted_times[i] - accepted_times[i - 1])
	if accepted_times.size() < 2:
		min_delta = -1.0
	print("PROBE_ACCEPT_TIMES=", accepted_times)
	print("PROBE_MIN_DELTA=", min_delta)

	# Buffer check: press inside last 0.10s of cooldown and ensure it triggers on legal frame.
	player.set("basic_attack_cooldown_left", 0.10)
	_clear_non_cooldown_blockers(player)
	player.call("_queue_basic_attack_buffer", "probe")
	player.call("_tick_timers", 0.05)
	_clear_non_cooldown_blockers(player)
	var cooldown_after_first_tick: float = player.get("basic_attack_cooldown_left")
	var buffered_after_first_tick: bool = player.get("basic_attack_input_buffered")
	player.call("_tick_timers", 0.05)
	_clear_non_cooldown_blockers(player)
	var cooldown_after_second_tick: float = player.get("basic_attack_cooldown_left")
	var buffered_after_second_tick: bool = player.get("basic_attack_input_buffered")
	print("PROBE_BUFFER_STEP1 cd=%.3f buffered=%s" % [cooldown_after_first_tick, str(buffered_after_first_tick)])
	print("PROBE_BUFFER_STEP2 cd=%.3f buffered=%s" % [cooldown_after_second_tick, str(buffered_after_second_tick)])

	quit()

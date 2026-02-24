extends Node2D

const AUTOPLAY_TEST_RUNNER_SCRIPT := preload("res://scripts/testing/autoplay_test_runner.gd")

@onready var arena: Arena = $Arena
@onready var hud: HUD = $HUD


func _ready() -> void:
	InputConfig.ensure_actions()
	_connect_signals()
	arena.start_demo()
	_maybe_start_autoplay_test()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_8 and key_event.keycode != KEY_KP_8:
		return
	if is_instance_valid(arena):
		arena.spawn_debug_minotaur_alternating()
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	arena.player_health_changed.connect(hud.update_health)
	arena.player_xp_changed.connect(hud.update_xp)
	arena.cooldowns_changed.connect(hud.update_cooldowns)
	arena.objective_changed.connect(hud.update_objective)
	arena.item_collected.connect(hud.show_item_pickup)
	arena.player_died.connect(hud.show_defeat)
	arena.demo_won.connect(hud.show_victory)
	arena.combat_debug_changed.connect(hud.update_combat_debug)


func _maybe_start_autoplay_test() -> void:
	if not _is_autoplay_requested():
		return
	var runner := AUTOPLAY_TEST_RUNNER_SCRIPT.new()
	if runner == null:
		push_error("Failed to instantiate autoplay runner.")
		return
	add_child(runner)
	runner.configure(arena)


func _is_autoplay_requested() -> bool:
	var autoplay_raw := OS.get_environment("AUTOPLAY_TEST").strip_edges().to_lower()
	if not autoplay_raw.is_empty() and autoplay_raw not in ["0", "false", "off", "no"]:
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false

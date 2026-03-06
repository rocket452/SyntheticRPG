extends Node2D

const AUTOPLAY_TEST_RUNNER_SCRIPT := preload("res://scripts/testing/autoplay_test_runner.gd")

@onready var arena: Arena = $Arena
@onready var hud: HUD = $HUD

var encounter_picker_layer: CanvasLayer = null


func _ready() -> void:
	InputConfig.ensure_actions()
	_connect_signals()
	if _is_autoplay_requested():
		arena.start_demo_with_encounter(_get_autoplay_encounter_type())
		_maybe_start_autoplay_test()
		return
	_show_encounter_picker()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if not key_event.pressed or key_event.echo:
		return
	if _has_active_encounter_picker():
		if key_event.keycode == KEY_1 or key_event.keycode == KEY_KP_1:
			_start_selected_encounter(Arena.EncounterType.MINOTAUR)
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_2 or key_event.keycode == KEY_KP_2:
			_start_selected_encounter(Arena.EncounterType.CACODEMON)
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_3 or key_event.keycode == KEY_KP_3:
			_start_selected_encounter(Arena.EncounterType.SHARDSOUL)
			get_viewport().set_input_as_handled()
			return
		return
	if key_event.keycode == KEY_F6:
		if is_instance_valid(arena):
			arena.force_debug_boss_breath()
			hud.show_status_message("Forced boss breath", 0.75)
			get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F7:
		if is_instance_valid(arena):
			var next_mode := arena.cycle_debug_breath_vfx_mode()
			if next_mode >= 0:
				hud.show_status_message("Breath VFX Mode %d" % [next_mode + 1], 0.9)
				get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F9:
		if is_instance_valid(arena):
			var auto_block_enabled := arena.toggle_player_auto_block()
			hud.show_status_message("Auto-block %s" % ("ON" if auto_block_enabled else "OFF"), 0.9)
			get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F10:
		if is_instance_valid(arena):
			var hitbox_debug_enabled := arena.toggle_hitbox_debug_mode()
			hud.show_status_message("Hit/Hurtbox Debug %s" % ("ON" if hitbox_debug_enabled else "OFF"), 1.0)
			get_viewport().set_input_as_handled()
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
	arena.status_message.connect(hud.show_status_message)
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


func _show_encounter_picker() -> void:
	if _has_active_encounter_picker():
		return
	var layer := CanvasLayer.new()
	layer.name = "EncounterPicker"
	add_child(layer)
	encounter_picker_layer = layer

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.04, 0.82)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(0.0, 220.0)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Choose Encounter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var description := Label.new()
	description.text = "1. Minotaur uses the current boss fight.\n2. Cacodemon reuses the same boss logic with the new sprite sheet.\n3. Shardsoul reuses the cacodemon encounter with the shardsoul sprite sheet."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)

	var minotaur_button := Button.new()
	minotaur_button.text = "1. Start Minotaur Fight"
	minotaur_button.custom_minimum_size = Vector2(0.0, 44.0)
	minotaur_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.MINOTAUR)
	)
	content.add_child(minotaur_button)

	var cacodemon_button := Button.new()
	cacodemon_button.text = "2. Start Cacodemon Fight"
	cacodemon_button.custom_minimum_size = Vector2(0.0, 44.0)
	cacodemon_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.CACODEMON)
	)
	content.add_child(cacodemon_button)

	var shardsoul_button := Button.new()
	shardsoul_button.text = "3. Start Shardsoul Fight"
	shardsoul_button.custom_minimum_size = Vector2(0.0, 44.0)
	shardsoul_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.SHARDSOUL)
	)
	content.add_child(shardsoul_button)

	var hint := Label.new()
	hint.text = "Press 1, 2, or 3, or click a button."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	minotaur_button.grab_focus()


func _start_selected_encounter(encounter_type: int) -> void:
	if not is_instance_valid(arena):
		return
	if _has_active_encounter_picker():
		encounter_picker_layer.queue_free()
		encounter_picker_layer = null
	arena.start_demo_with_encounter(encounter_type)


func _has_active_encounter_picker() -> bool:
	return is_instance_valid(encounter_picker_layer)


func _get_autoplay_encounter_type() -> int:
	var encounter_raw := OS.get_environment("AUTOPLAY_ENCOUNTER").strip_edges().to_lower()
	if encounter_raw == "cacodemon" or encounter_raw == "2":
		return Arena.EncounterType.CACODEMON
	if encounter_raw == "shardsoul" or encounter_raw == "3":
		return Arena.EncounterType.SHARDSOUL
	return Arena.EncounterType.MINOTAUR


func _is_autoplay_requested() -> bool:
	var autoplay_raw := OS.get_environment("AUTOPLAY_TEST").strip_edges().to_lower()
	if not autoplay_raw.is_empty() and autoplay_raw not in ["0", "false", "off", "no"]:
		return true
	for arg in OS.get_cmdline_user_args():
		var normalized := String(arg).strip_edges().to_lower()
		if normalized == "--autoplay_test" or normalized == "autoplay_test" or normalized == "--autoplay_test=1":
			return true
	return false

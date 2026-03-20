extends Node2D

const AUTOPLAY_TEST_RUNNER_SCRIPT := preload("res://scripts/testing/autoplay_test_runner.gd")
const INVENTORY_MENU_SCRIPT := preload("res://scripts/ui/inventory_menu.gd")
const SWORD_DEFINITIONS := preload("res://scripts/systems/sword_definitions.gd")
const SHIELD_DEFINITIONS := preload("res://scripts/systems/shield_definitions.gd")
const RING_DEFINITIONS := preload("res://scripts/systems/ring_definitions.gd")
const CHEST_BOOT_ITEM_DESCRIPTIONS: Dictionary = {
	"swift_boots": "Reduces Roll cooldown by 50%.",
	"strider_boots": "Increases base movement speed by 15%.",
	"bodyguard_boots": "Enables Dash to Ally ability.",
	"trailblazer_boots": "Increases base movement speed by 15%."
}
const CHEST_ITEM_DISPLAY_NAMES: Dictionary = {
	"swift_boots": "Swift Boots",
	"strider_boots": "Strider Boots",
	"bodyguard_boots": "Bodyguard Boots",
	"ring_bulwark": "Ring of the Bulwark",
	"ring_berserker": "Ring of the Berserker",
	"ring_shield": "Ring of the Shield",
	"trailblazer_boots": "Trailblazer Boots",
	"sword_extended_charge": "Extended Charge Sword",
	"sword_slowing": "Slowing Sword",
	"sword_stacking_dot": "Stacking DoT Sword",
	"shield_revenge": "Revenge Shield",
	"shield_thorns": "Thorns Shield",
	"shield_wide_guard": "Wide Guard Shield"
}
const CHEST_PICKUP_TO_SWORD_ID: Dictionary = {
	"sword_extended_charge": SWORD_DEFINITIONS.EXTENDED_CHARGE_SWORD,
	"sword_slowing": SWORD_DEFINITIONS.SLOWING_SWORD,
	"sword_stacking_dot": SWORD_DEFINITIONS.STACKING_DOT_SWORD
}
const CHEST_PICKUP_TO_SHIELD_ID: Dictionary = {
	"shield_revenge": SHIELD_DEFINITIONS.REVENGE_SHIELD,
	"shield_thorns": SHIELD_DEFINITIONS.THORNS_SHIELD,
	"shield_wide_guard": SHIELD_DEFINITIONS.WIDE_GUARD_SHIELD
}
const CHEST_PICKUP_TO_RING_ID: Dictionary = {
	"ring_bulwark": RING_DEFINITIONS.BULWARK_RING,
	"ring_berserker": RING_DEFINITIONS.BERSERKER_RING,
	"ring_shield": RING_DEFINITIONS.SHIELD_RING
}
const CHEST_POPUP_MIN_CLOSE_DELAY_MS: int = 120
const ADVENTURE_DEATH_POPUP_MIN_CLOSE_DELAY_MS: int = 120

@onready var arena: Arena = $Arena
@onready var hud: HUD = $HUD

var encounter_picker_layer: CanvasLayer = null
var adventure_start_picker_layer: CanvasLayer = null
var inventory_menu_layer: CanvasLayer = null
var chest_item_popup_layer: CanvasLayer = null
var chest_item_popup_opened_at_ms: int = 0
var adventure_death_popup_layer: CanvasLayer = null
var adventure_death_popup_opened_at_ms: int = 0


func _ready() -> void:
	InputConfig.ensure_actions()
	_connect_signals()
	if is_instance_valid(hud) and hud.has_method("set_text_debug_visible"):
		hud.call("set_text_debug_visible", false)
	if _is_autoplay_requested():
		arena.start_demo_with_encounter(_get_autoplay_encounter_type())
		_maybe_start_autoplay_test()
		return
	_show_encounter_picker()


func _unhandled_input(event: InputEvent) -> void:
	if _has_active_adventure_death_popup():
		var death_key_event := event as InputEventKey
		if death_key_event != null and death_key_event.pressed and not death_key_event.echo:
			var is_enter_pressed := death_key_event.keycode == KEY_ENTER or death_key_event.keycode == KEY_KP_ENTER
			if is_enter_pressed:
				var elapsed := Time.get_ticks_msec() - adventure_death_popup_opened_at_ms
				if elapsed >= ADVENTURE_DEATH_POPUP_MIN_CLOSE_DELAY_MS:
					_confirm_adventure_death_popup()
			get_viewport().set_input_as_handled()
		return
	if _has_active_chest_item_popup():
		var key_event := event as InputEventKey
		if key_event != null and key_event.pressed and not key_event.echo:
			var elapsed := Time.get_ticks_msec() - chest_item_popup_opened_at_ms
			if elapsed >= CHEST_POPUP_MIN_CLOSE_DELAY_MS:
				_close_chest_item_popup()
			get_viewport().set_input_as_handled()
		return
	if _has_active_adventure_start_picker():
		var pick_event := event as InputEventKey
		if pick_event != null and pick_event.pressed and not pick_event.echo:
			if pick_event.keycode == KEY_1 or pick_event.keycode == KEY_KP_1:
				_start_adventure_with_character("tank")
			elif pick_event.keycode == KEY_2 or pick_event.keycode == KEY_KP_2:
				_start_adventure_with_character("healer")
			elif pick_event.keycode == KEY_3 or pick_event.keycode == KEY_KP_3:
				_start_adventure_with_character("ratfolk")
			elif pick_event.keycode == KEY_ESCAPE:
				_close_adventure_start_picker()
			get_viewport().set_input_as_handled()
		else:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory_toggle"):
		if not _has_active_encounter_picker():
			_toggle_inventory_menu()
		get_viewport().set_input_as_handled()
		return
	if _has_active_inventory_menu():
		return
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if not key_event.pressed or key_event.echo:
		return
	if _has_active_encounter_picker():
		if key_event.keycode == KEY_1 or key_event.keycode == KEY_KP_1:
			_start_selected_encounter(Arena.EncounterType.COBRA)
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_2 or key_event.keycode == KEY_KP_2:
			_start_selected_encounter(Arena.EncounterType.MINOTAUR)
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_3 or key_event.keycode == KEY_KP_3:
			_start_selected_encounter(Arena.EncounterType.CACODEMON)
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_4 or key_event.keycode == KEY_KP_4:
			_start_selected_encounter(Arena.EncounterType.SHARDSOUL)
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_5 or key_event.keycode == KEY_KP_5:
			_start_selected_encounter(Arena.EncounterType.COBRA_TWO_ROOM_TEST)
			get_viewport().set_input_as_handled()
			return
		return
	var debug_room_jump_target := _get_debug_adventure_room_jump_target(key_event)
	if debug_room_jump_target > 0:
		if is_instance_valid(arena) and arena.has_method("debug_jump_to_adventure_room"):
			var jumped := bool(arena.call("debug_jump_to_adventure_room", debug_room_jump_target))
			if jumped:
				hud.show_status_message("Debug jump -> Adventure Room %d" % debug_room_jump_target, 0.95)
			get_viewport().set_input_as_handled()
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
			if is_instance_valid(hud) and hud.has_method("set_text_debug_visible"):
				hud.call("set_text_debug_visible", hitbox_debug_enabled)
			hud.show_status_message("Hit/Hurtbox Debug %s" % ("ON" if hitbox_debug_enabled else "OFF"), 1.0)
			get_viewport().set_input_as_handled()
		return
	if key_event.keycode != KEY_8 and key_event.keycode != KEY_KP_8:
		return
	if is_instance_valid(arena):
		arena.spawn_debug_minotaur_alternating()
		get_viewport().set_input_as_handled()


func _get_debug_adventure_room_jump_target(key_event: InputEventKey) -> int:
	if key_event == null:
		return 0
	if not key_event.ctrl_pressed:
		return 0
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			return 1
		KEY_2, KEY_KP_2:
			return 2
		KEY_3, KEY_KP_3:
			return 3
		KEY_4, KEY_KP_4:
			return 4
		KEY_5, KEY_KP_5:
			return 5
		KEY_6, KEY_KP_6:
			return 6
		_:
			return 0


func _connect_signals() -> void:
	arena.player_health_changed.connect(hud.update_health)
	arena.player_xp_changed.connect(hud.update_xp)
	arena.cooldowns_changed.connect(hud.update_cooldowns)
	arena.objective_changed.connect(hud.update_objective)
	arena.item_collected.connect(hud.show_item_pickup)
	arena.status_message.connect(hud.show_status_message)
	arena.player_died.connect(_on_arena_player_died)
	arena.demo_won.connect(hud.show_victory)
	arena.combat_debug_changed.connect(hud.update_combat_debug)
	if arena.has_signal("two_room_chest_item_received"):
		arena.two_room_chest_item_received.connect(_on_two_room_chest_item_received)
	if is_instance_valid(arena.player) and arena.player.has_signal("equipped_sword_changed"):
		arena.player.equipped_sword_changed.connect(_on_player_equipped_sword_changed)
	if is_instance_valid(arena.player) and arena.player.has_signal("equipped_shield_changed"):
		arena.player.equipped_shield_changed.connect(_on_player_equipped_shield_changed)
	if is_instance_valid(arena.player) and arena.player.has_signal("equipped_ring_changed"):
		arena.player.equipped_ring_changed.connect(_on_player_equipped_ring_changed)


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
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(0.0, 290.0)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Choose Encounter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var cobra_button := Button.new()
	cobra_button.text = "1. Start Cobra Fight"
	cobra_button.custom_minimum_size = Vector2(0.0, 44.0)
	cobra_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.COBRA)
	)
	content.add_child(cobra_button)

	var minotaur_button := Button.new()
	minotaur_button.text = "2. Start Minotaur Fight"
	minotaur_button.custom_minimum_size = Vector2(0.0, 44.0)
	minotaur_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.MINOTAUR)
	)
	content.add_child(minotaur_button)

	var cacodemon_button := Button.new()
	cacodemon_button.text = "3. Start Cacodemon Fight"
	cacodemon_button.custom_minimum_size = Vector2(0.0, 44.0)
	cacodemon_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.CACODEMON)
	)
	content.add_child(cacodemon_button)

	var shardsoul_button := Button.new()
	shardsoul_button.text = "4. Start Shardsoul Fight"
	shardsoul_button.custom_minimum_size = Vector2(0.0, 44.0)
	shardsoul_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.SHARDSOUL)
	)
	content.add_child(shardsoul_button)

	var two_room_button := Button.new()
	two_room_button.text = "5. Adventure Mode"
	two_room_button.custom_minimum_size = Vector2(0.0, 44.0)
	two_room_button.pressed.connect(func() -> void:
		_start_selected_encounter(Arena.EncounterType.COBRA_TWO_ROOM_TEST)
	)
	content.add_child(two_room_button)

	var hint := Label.new()
	hint.text = "Press 1-5, or click a button."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	cobra_button.grab_focus()


func _start_selected_encounter(encounter_type: int) -> void:
	if not is_instance_valid(arena):
		return
	if encounter_type == Arena.EncounterType.COBRA_TWO_ROOM_TEST:
		_show_adventure_start_picker()
		return
	_begin_encounter(encounter_type)


func _begin_encounter(encounter_type: int) -> void:
	if not is_instance_valid(arena):
		return
	_close_chest_item_popup()
	_close_adventure_death_popup()
	_close_inventory_menu()
	_close_adventure_start_picker()
	if _has_active_encounter_picker():
		encounter_picker_layer.queue_free()
		encounter_picker_layer = null
	arena.start_demo_with_encounter(encounter_type)


func _has_active_adventure_start_picker() -> bool:
	return is_instance_valid(adventure_start_picker_layer)


func _show_adventure_start_picker() -> void:
	if _has_active_adventure_start_picker():
		return
	var layer := CanvasLayer.new()
	layer.name = "AdventureStartPicker"
	add_child(layer)
	adventure_start_picker_layer = layer

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.04, 0.82)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(0.0, 300.0)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Adventure Start"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose who you control in Room 1."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)

	var tank_button := Button.new()
	tank_button.text = "1. Play as Tank"
	tank_button.custom_minimum_size = Vector2(0.0, 44.0)
	tank_button.pressed.connect(func() -> void:
		_start_adventure_with_character("tank")
	)
	content.add_child(tank_button)

	var healer_button := Button.new()
	healer_button.text = "2. Play as Healer"
	healer_button.custom_minimum_size = Vector2(0.0, 44.0)
	healer_button.pressed.connect(func() -> void:
		_start_adventure_with_character("healer")
	)
	content.add_child(healer_button)

	var rat_button := Button.new()
	rat_button.text = "3. Play as Ratfolk"
	rat_button.custom_minimum_size = Vector2(0.0, 44.0)
	rat_button.pressed.connect(func() -> void:
		_start_adventure_with_character("ratfolk")
	)
	content.add_child(rat_button)

	var hint := Label.new()
	hint.text = "Press 1-3 to select, or Esc to go back."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	tank_button.grab_focus()


func _close_adventure_start_picker() -> void:
	if not _has_active_adventure_start_picker():
		return
	if is_instance_valid(adventure_start_picker_layer):
		adventure_start_picker_layer.queue_free()
	adventure_start_picker_layer = null


func _start_adventure_with_character(control_id: String) -> void:
	if not is_instance_valid(arena):
		return
	if arena.has_method("set_adventure_start_character"):
		arena.call("set_adventure_start_character", control_id)
	_begin_encounter(Arena.EncounterType.COBRA_TWO_ROOM_TEST)


func _has_active_encounter_picker() -> bool:
	return is_instance_valid(encounter_picker_layer)


func _has_active_inventory_menu() -> bool:
	return is_instance_valid(inventory_menu_layer)


func _get_inventory_menu_owner() -> Object:
	if not is_instance_valid(arena):
		return null
	if arena.has_method("get_controlled_inventory_actor"):
		var owner_variant: Variant = arena.call("get_controlled_inventory_actor")
		if owner_variant is Object:
			var owner := owner_variant as Object
			if owner != null and is_instance_valid(owner):
				return owner
	if is_instance_valid(arena.player):
		return arena.player
	return null


func _get_inventory_owner_array_entries(owner: Object, method_name: String) -> Array[Dictionary]:
	if owner == null or not is_instance_valid(owner) or not owner.has_method(method_name):
		return []
	var entries_variant: Variant = owner.call(method_name)
	var entries: Array[Dictionary] = []
	if entries_variant is Array:
		for entry_variant in (entries_variant as Array):
			if entry_variant is Dictionary:
				entries.append((entry_variant as Dictionary).duplicate(true))
	return entries


func _get_inventory_owner_string(owner: Object, method_name: String, fallback: String = "") -> String:
	if owner == null or not is_instance_valid(owner) or not owner.has_method(method_name):
		return fallback
	return String(owner.call(method_name))


func _get_inventory_owner_int(owner: Object, method_name: String, fallback: int = 0) -> int:
	if owner == null or not is_instance_valid(owner) or not owner.has_method(method_name):
		return fallback
	return int(owner.call(method_name))


func _build_inventory_menu_payload() -> Dictionary:
	var owner := _get_inventory_menu_owner()
	return {
		"sword_entries": _get_inventory_owner_array_entries(owner, "get_available_sword_entries"),
		"equipped_sword_id": _get_inventory_owner_string(owner, "get_equipped_sword_id"),
		"shield_entries": _get_inventory_owner_array_entries(owner, "get_available_shield_entries"),
		"equipped_shield_id": _get_inventory_owner_string(owner, "get_equipped_shield_id"),
		"shield_slot_title": _get_inventory_owner_string(owner, "get_shield_slot_display_name", "Shields"),
		"shield_slot_empty_text": _get_inventory_owner_string(owner, "get_shield_slot_empty_text", "No shields found."),
		"shield_slot_default_icon": _get_inventory_owner_string(owner, "get_shield_slot_default_icon", "SHD"),
		"ring_entries": _get_inventory_owner_array_entries(owner, "get_available_ring_entries"),
		"equipped_ring_id": _get_inventory_owner_string(owner, "get_equipped_ring_id"),
		"gold_total": maxi(0, _get_inventory_owner_int(owner, "get_gold_total", 0)),
		"store_entries": _get_inventory_owner_array_entries(owner, "get_store_entries"),
		"boot_entries": _get_inventory_owner_array_entries(owner, "get_equipped_boot_entries")
	}


func _toggle_inventory_menu() -> void:
	if _has_active_inventory_menu():
		_close_inventory_menu()
	else:
		_open_inventory_menu()


func _open_inventory_menu() -> void:
	if _has_active_inventory_menu():
		return
	if not is_instance_valid(arena) or not is_instance_valid(arena.player):
		return
	if INVENTORY_MENU_SCRIPT == null:
		return
	var menu_layer := INVENTORY_MENU_SCRIPT.new() as CanvasLayer
	if menu_layer == null:
		return
	add_child(menu_layer)
	inventory_menu_layer = menu_layer
	var payload := _build_inventory_menu_payload()
	if menu_layer.has_method("configure"):
		menu_layer.call(
			"configure",
			payload.get("sword_entries", []),
			String(payload.get("equipped_sword_id", "")),
			payload.get("shield_entries", []),
			String(payload.get("equipped_shield_id", "")),
			payload.get("ring_entries", []),
			String(payload.get("equipped_ring_id", "")),
			int(payload.get("gold_total", 0)),
			payload.get("store_entries", []),
			arena.call("get_party_member_entries"),
			payload.get("boot_entries", []),
			arena.call("get_control_target_entries"),
			arena.call("get_controlled_character_id"),
			String(payload.get("shield_slot_title", "Shields")),
			String(payload.get("shield_slot_empty_text", "No shields found.")),
			String(payload.get("shield_slot_default_icon", "SHD"))
		)
	if menu_layer.has_signal("sword_selected"):
		menu_layer.connect("sword_selected", Callable(self, "_on_inventory_sword_selected"))
	if menu_layer.has_signal("shield_selected"):
		menu_layer.connect("shield_selected", Callable(self, "_on_inventory_shield_selected"))
	if menu_layer.has_signal("ring_selected"):
		menu_layer.connect("ring_selected", Callable(self, "_on_inventory_ring_selected"))
	if menu_layer.has_signal("store_purchase_requested"):
		menu_layer.connect("store_purchase_requested", Callable(self, "_on_inventory_store_purchase_requested"))
	if menu_layer.has_signal("party_member_toggled"):
		menu_layer.connect("party_member_toggled", Callable(self, "_on_inventory_party_member_toggled"))
	if menu_layer.has_signal("controlled_character_selected"):
		menu_layer.connect("controlled_character_selected", Callable(self, "_on_inventory_controlled_character_selected"))
	if menu_layer.has_signal("menu_closed"):
		menu_layer.connect("menu_closed", Callable(self, "_on_inventory_menu_closed"))
	if arena.player.has_method("set_gameplay_input_blocked"):
		arena.player.call("set_gameplay_input_blocked", true)
	get_tree().paused = true
	hud.show_status_message("Inventory Open - Equip gear / buy from store", 1.0)


func _close_inventory_menu() -> void:
	if not _has_active_inventory_menu():
		return
	if is_instance_valid(inventory_menu_layer):
		inventory_menu_layer.queue_free()
	inventory_menu_layer = null
	get_tree().paused = false
	if is_instance_valid(arena) and is_instance_valid(arena.player) and arena.player.has_method("set_gameplay_input_blocked"):
		arena.player.call("set_gameplay_input_blocked", false)
	hud.show_status_message("Inventory Closed", 0.8)


func _on_inventory_sword_selected(sword_id: String) -> void:
	if not is_instance_valid(arena):
		return
	var owner := _get_inventory_menu_owner()
	if owner == null or not is_instance_valid(owner):
		return
	if not owner.has_method("equip_sword"):
		return
	var changed := bool(owner.call("equip_sword", sword_id))
	if changed:
		var sword_name := _get_inventory_owner_string(owner, "get_equipped_sword_name", sword_id)
		hud.show_status_message("Equipped: %s" % sword_name, 1.2)
	_refresh_inventory_menu_contents()


func _on_inventory_shield_selected(shield_id: String) -> void:
	if not is_instance_valid(arena):
		return
	var owner := _get_inventory_menu_owner()
	if owner == null or not is_instance_valid(owner):
		return
	if not owner.has_method("equip_shield"):
		return
	var changed := bool(owner.call("equip_shield", shield_id))
	if changed:
		var shield_name := _get_inventory_owner_string(owner, "get_equipped_shield_name", shield_id)
		var slot_name := _get_inventory_owner_string(owner, "get_shield_slot_singular_display_name", "Shield")
		hud.show_status_message("Equipped %s: %s" % [slot_name, shield_name], 1.2)
	_refresh_inventory_menu_contents()


func _on_inventory_ring_selected(ring_id: String) -> void:
	if not is_instance_valid(arena):
		return
	var owner := _get_inventory_menu_owner()
	if owner == null or not is_instance_valid(owner):
		return
	if not owner.has_method("equip_ring"):
		return
	var changed := bool(owner.call("equip_ring", ring_id))
	if changed:
		var ring_name := _get_inventory_owner_string(owner, "get_equipped_ring_name", ring_id)
		hud.show_status_message("Equipped: %s" % ring_name, 1.2)
	_refresh_inventory_menu_contents()


func _on_inventory_store_purchase_requested(item_id: String) -> void:
	if not is_instance_valid(arena):
		return
	var owner := _get_inventory_menu_owner()
	if owner == null or not is_instance_valid(owner):
		return
	if not owner.has_method("purchase_store_item"):
		hud.show_status_message("Store unavailable for this character.", 1.0)
		return
	var result_variant: Variant = owner.call("purchase_store_item", item_id)
	if result_variant is Dictionary:
		var result := result_variant as Dictionary
		var purchase_succeeded := bool(result.get("success", false))
		if purchase_succeeded:
			var item_name := String(result.get("item_name", item_id))
			var gold_left := maxi(0, int(result.get("gold_total", 0)))
			hud.show_status_message("Purchased %s (%d gold left)" % [item_name, gold_left], 1.3)
		else:
			var reason := String(result.get("reason", "Purchase failed."))
			if reason.to_lower().find("not enough gold") != -1 and hud.has_method("show_warning_status_message"):
				hud.call("show_warning_status_message", reason, 2.2)
			else:
				hud.show_status_message(reason, 1.0)
	_refresh_inventory_menu_contents()


func _on_inventory_party_member_toggled(member_id: String, enabled: bool) -> void:
	if not is_instance_valid(arena):
		return
	if not arena.has_method("set_party_member_enabled"):
		return
	var changed := bool(arena.call("set_party_member_enabled", member_id, enabled))
	if changed:
		var member_name := member_id
		if arena.has_method("get_party_member_entries"):
			var entries_variant: Variant = arena.call("get_party_member_entries")
			if entries_variant is Array:
				for entry_variant in (entries_variant as Array):
					if not (entry_variant is Dictionary):
						continue
					var entry := entry_variant as Dictionary
					if String(entry.get("id", "")) != member_id:
						continue
					member_name = String(entry.get("name", member_id))
					break
		hud.show_status_message("%s %s" % [member_name, "enabled" if enabled else "disabled"], 1.0)
	elif enabled and arena.has_method("get_party_member_toggle_failure_reason"):
		var reason := String(arena.call("get_party_member_toggle_failure_reason"))
		if not reason.is_empty():
			if reason.to_lower().find("party is full") != -1 and hud.has_method("show_warning_status_message"):
				hud.call("show_warning_status_message", reason, 1.8)
			else:
				hud.show_status_message(reason, 1.2)
	_refresh_inventory_menu_contents()


func _on_inventory_controlled_character_selected(control_id: String) -> void:
	if not is_instance_valid(arena):
		return
	if not arena.has_method("set_controlled_character"):
		return
	var changed := bool(arena.call("set_controlled_character", control_id))
	if changed:
		if arena.has_method("get_controlled_character_display_name"):
			var display_name := String(arena.call("get_controlled_character_display_name"))
			hud.show_status_message("Control switched: %s" % display_name, 1.1)
		else:
			hud.show_status_message("Control switched.", 1.0)
	elif arena.has_method("get_control_target_failure_reason"):
		var reason := String(arena.call("get_control_target_failure_reason"))
		if not reason.is_empty():
			hud.show_status_message(reason, 1.2)
	_refresh_inventory_menu_contents()


func _on_inventory_menu_closed() -> void:
	_close_inventory_menu()


func _on_player_equipped_sword_changed(_sword_id: String, sword_name: String) -> void:
	hud.show_status_message("Sword: %s" % sword_name, 1.2)


func _on_player_equipped_shield_changed(_shield_id: String, shield_name: String) -> void:
	hud.show_status_message("Shield: %s" % shield_name, 1.2)


func _on_player_equipped_ring_changed(_ring_id: String, ring_name: String) -> void:
	hud.show_status_message("Ring: %s" % ring_name, 1.2)


func _on_arena_player_died() -> void:
	var adventure_active := false
	if is_instance_valid(arena) and arena.has_method("is_adventure_mode_active"):
		adventure_active = bool(arena.call("is_adventure_mode_active"))
	if not adventure_active:
		hud.show_defeat()
		return
	_close_inventory_menu()
	_close_chest_item_popup()
	var gold_lost := 0
	var gold_remaining := 0
	if is_instance_valid(arena) and arena.has_method("apply_adventure_death_penalty"):
		var penalty_variant: Variant = arena.call("apply_adventure_death_penalty")
		if penalty_variant is Dictionary:
			var penalty := penalty_variant as Dictionary
			gold_lost = maxi(0, int(penalty.get("gold_lost", 0)))
			gold_remaining = maxi(0, int(penalty.get("gold_remaining", 0)))
	_show_adventure_death_popup(gold_lost, gold_remaining)


func _refresh_inventory_menu_contents() -> void:
	if not _has_active_inventory_menu():
		return
	if not is_instance_valid(arena):
		return
	if not inventory_menu_layer.has_method("configure"):
		return
	var payload := _build_inventory_menu_payload()
	inventory_menu_layer.call(
		"configure",
		payload.get("sword_entries", []),
		String(payload.get("equipped_sword_id", "")),
		payload.get("shield_entries", []),
		String(payload.get("equipped_shield_id", "")),
		payload.get("ring_entries", []),
		String(payload.get("equipped_ring_id", "")),
		int(payload.get("gold_total", 0)),
		payload.get("store_entries", []),
		arena.call("get_party_member_entries"),
		payload.get("boot_entries", []),
		arena.call("get_control_target_entries"),
		arena.call("get_controlled_character_id"),
		String(payload.get("shield_slot_title", "Shields")),
		String(payload.get("shield_slot_empty_text", "No shields found.")),
		String(payload.get("shield_slot_default_icon", "SHD"))
	)


func _on_two_room_chest_item_received(item_id: String) -> void:
	var chest_item_data := _build_chest_item_popup_data(item_id)
	_show_chest_item_popup(
		String(chest_item_data.get("name", "Treasure")),
		String(chest_item_data.get("description", "A rare item from the chest."))
	)


func _has_active_chest_item_popup() -> bool:
	return is_instance_valid(chest_item_popup_layer)


func _has_active_adventure_death_popup() -> bool:
	return is_instance_valid(adventure_death_popup_layer)


func _show_adventure_death_popup(gold_lost: int, gold_remaining: int) -> void:
	_close_adventure_death_popup(false)
	var layer := CanvasLayer.new()
	layer.name = "AdventureDeathPopup"
	add_child(layer)
	adventure_death_popup_layer = layer
	adventure_death_popup_opened_at_ms = Time.get_ticks_msec()

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.01, 0.01, 0.86)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660.0, 0.0)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(0.0, 244.0)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Label.new()
	title.text = "You Were Slain"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(1.0, 0.78, 0.76, 1.0)
	content.add_child(title)

	var summary := Label.new()
	summary.text = "You lost %d gold (50%%)." % maxi(0, gold_lost)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 22)
	content.add_child(summary)

	var remaining := Label.new()
	remaining.text = "Gold remaining: %d" % maxi(0, gold_remaining)
	remaining.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining.add_theme_font_size_override("font_size", 20)
	remaining.modulate = Color(0.96, 0.9, 0.66, 1.0)
	content.add_child(remaining)

	var instruction := Label.new()
	instruction.text = "Press Enter to return to Room 1"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.custom_minimum_size = Vector2(560.0, 74.0)
	instruction.add_theme_font_size_override("font_size", 18)
	instruction.modulate = Color(0.82, 0.92, 1.0, 0.96)
	content.add_child(instruction)

	if is_instance_valid(arena) and is_instance_valid(arena.player) and arena.player.has_method("set_gameplay_input_blocked"):
		arena.player.call("set_gameplay_input_blocked", true)


func _confirm_adventure_death_popup() -> void:
	_close_adventure_death_popup(false)
	var recovered := false
	if is_instance_valid(arena) and arena.has_method("recover_from_adventure_death"):
		recovered = bool(arena.call("recover_from_adventure_death"))
	if recovered:
		return
	if is_instance_valid(arena) and is_instance_valid(arena.player) and arena.player.has_method("set_gameplay_input_blocked"):
		arena.player.call("set_gameplay_input_blocked", false)


func _close_adventure_death_popup(release_input: bool = true) -> void:
	if not _has_active_adventure_death_popup():
		return
	if is_instance_valid(adventure_death_popup_layer):
		adventure_death_popup_layer.queue_free()
	adventure_death_popup_layer = null
	adventure_death_popup_opened_at_ms = 0
	if not release_input:
		return
	if is_instance_valid(arena) and is_instance_valid(arena.player) and arena.player.has_method("set_gameplay_input_blocked"):
		if not _has_active_inventory_menu() and not _has_active_chest_item_popup():
			arena.player.call("set_gameplay_input_blocked", false)


func _show_chest_item_popup(item_name: String, item_description: String) -> void:
	_close_chest_item_popup()
	var layer := CanvasLayer.new()
	layer.name = "ChestItemPopup"
	add_child(layer)
	chest_item_popup_layer = layer
	chest_item_popup_opened_at_ms = Time.get_ticks_msec()

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.01, 0.02, 0.78)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(0.0, 220.0)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Treasure Acquired"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var item_label := Label.new()
	item_label.text = item_name
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.add_theme_font_size_override("font_size", 24)
	item_label.modulate = Color(0.98, 0.91, 0.62, 1.0)
	content.add_child(item_label)

	var description_label := Label.new()
	description_label.text = item_description
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(500.0, 92.0)
	description_label.add_theme_font_size_override("font_size", 18)
	content.add_child(description_label)

	var hint := Label.new()
	hint.text = "Press any key to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.82, 0.9, 1.0, 0.95)
	hint.add_theme_font_size_override("font_size", 16)
	content.add_child(hint)

	if is_instance_valid(arena) and is_instance_valid(arena.player) and arena.player.has_method("set_gameplay_input_blocked"):
		arena.player.call("set_gameplay_input_blocked", true)


func _close_chest_item_popup() -> void:
	if not _has_active_chest_item_popup():
		return
	if is_instance_valid(chest_item_popup_layer):
		chest_item_popup_layer.queue_free()
	chest_item_popup_layer = null
	chest_item_popup_opened_at_ms = 0
	if is_instance_valid(arena) and is_instance_valid(arena.player) and arena.player.has_method("set_gameplay_input_blocked"):
		if not _has_active_inventory_menu():
			arena.player.call("set_gameplay_input_blocked", false)


func _build_chest_item_popup_data(item_id: String) -> Dictionary:
	var normalized_item_id := item_id.strip_edges().to_lower()
	var display_name := String(CHEST_ITEM_DISPLAY_NAMES.get(normalized_item_id, _format_item_id_for_display(normalized_item_id)))

	if CHEST_BOOT_ITEM_DESCRIPTIONS.has(normalized_item_id):
		return {
			"name": display_name,
			"description": String(CHEST_BOOT_ITEM_DESCRIPTIONS[normalized_item_id])
		}

	if CHEST_PICKUP_TO_SWORD_ID.has(normalized_item_id):
		var sword_id := String(CHEST_PICKUP_TO_SWORD_ID[normalized_item_id])
		var sword_data := SWORD_DEFINITIONS.get_definition(sword_id)
		return {
			"name": String(sword_data.get("name", display_name)),
			"description": String(sword_data.get("description", "A sword empowered for your basic attacks."))
		}

	if CHEST_PICKUP_TO_SHIELD_ID.has(normalized_item_id):
		var shield_id := String(CHEST_PICKUP_TO_SHIELD_ID[normalized_item_id])
		var shield_data := SHIELD_DEFINITIONS.get_definition(shield_id)
		return {
			"name": String(shield_data.get("name", display_name)),
			"description": String(shield_data.get("description", "A shield blessed with defensive power."))
		}

	if CHEST_PICKUP_TO_RING_ID.has(normalized_item_id):
		var ring_id := String(CHEST_PICKUP_TO_RING_ID[normalized_item_id])
		var ring_data := RING_DEFINITIONS.get_definition(ring_id)
		return {
			"name": String(ring_data.get("name", display_name)),
			"description": String(ring_data.get("description", "A ring with unusual power."))
		}

	return {
		"name": display_name,
		"description": "A rare item from the treasure chest."
	}


func _format_item_id_for_display(item_id: String) -> String:
	if item_id.is_empty():
		return "Unknown Item"
	var words: Array[String] = []
	var split_words := item_id.split("_", false)
	for word_variant in split_words:
		var word := String(word_variant)
		if word.is_empty():
			continue
		var first := word.substr(0, 1).to_upper()
		var rest := word.substr(1)
		words.append("%s%s" % [first, rest])
	if words.is_empty():
		return "Unknown Item"
	return " ".join(words)


func _get_autoplay_encounter_type() -> int:
	var encounter_raw := OS.get_environment("AUTOPLAY_ENCOUNTER").strip_edges().to_lower()
	if encounter_raw == "cobra" or encounter_raw == "1":
		return Arena.EncounterType.COBRA
	if encounter_raw == "minotaur" or encounter_raw == "2":
		return Arena.EncounterType.MINOTAUR
	if encounter_raw == "cacodemon" or encounter_raw == "3":
		return Arena.EncounterType.CACODEMON
	if encounter_raw == "shardsoul" or encounter_raw == "4":
		return Arena.EncounterType.SHARDSOUL
	if encounter_raw == "two_room" or encounter_raw == "tworoom" or encounter_raw == "5":
		return Arena.EncounterType.COBRA_TWO_ROOM_TEST
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

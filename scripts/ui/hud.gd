extends CanvasLayer
class_name HUD

const ABILITY_BAR_SLOTS: Array[Dictionary] = [
	{"id": "basic", "icon": "ATK", "name": "Swing", "key": "J", "accent": Color(0.94, 0.64, 0.33, 1.0), "uses_cooldown": true},
	{"id": "ability_1", "icon": "HPN", "name": "Hook", "key": "K", "accent": Color(0.46, 0.94, 1.0, 1.0), "uses_cooldown": true},
	{"id": "counter", "icon": "CTR", "name": "Counter", "key": "O", "accent": Color(0.86, 0.98, 1.0, 1.0), "uses_cooldown": false},
	{"id": "ability_2", "icon": "DSH", "name": "Dash", "key": "L", "accent": Color(0.42, 0.88, 1.0, 1.0), "uses_cooldown": true},
	{"id": "roll", "icon": "RLL", "name": "Roll", "key": "Space", "accent": Color(0.78, 0.93, 1.0, 1.0), "uses_cooldown": true},
	{"id": "block", "icon": "BLK", "name": "Block", "key": "I", "accent": Color(0.56, 0.88, 1.0, 1.0), "uses_cooldown": false}
]

@onready var health_label: Label = $HealthLabel
@onready var xp_label: Label = $XPLabel
@onready var cooldown_label: Label = $CooldownLabel
@onready var items_label: Label = $ItemsLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var status_label: Label = $StatusLabel
@onready var victory_panel: Panel = $VictoryPanel
@onready var victory_label: Label = $VictoryPanel/Message
@onready var status_timer: Timer = $StatusTimer
var combat_debug_label: Label = null
var ability_slot_views: Dictionary = {}
var ability_slot_ready_flags: Dictionary = {}
var ready_pulse_time: float = 0.0


func _ready() -> void:
	victory_panel.visible = false
	status_timer.timeout.connect(_on_status_timeout)
	status_label.text = ""
	combat_debug_label = Label.new()
	combat_debug_label.name = "CombatDebugLabel"
	combat_debug_label.position = Vector2(990.0, 20.0)
	combat_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combat_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	combat_debug_label.size = Vector2(620.0, 230.0)
	combat_debug_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	combat_debug_label.modulate = Color(0.88, 0.97, 1.0, 0.94)
	combat_debug_label.text = ""
	add_child(combat_debug_label)
	_build_ability_bar()
	set_process(true)


func _process(delta: float) -> void:
	if ability_slot_views.is_empty():
		return
	ready_pulse_time += maxf(0.0, delta)
	var pulse := 0.68 + (0.22 * (0.5 + (0.5 * sin(ready_pulse_time * 4.2))))
	for slot_def in ABILITY_BAR_SLOTS:
		var slot_id := String(slot_def.get("id", ""))
		if slot_id.is_empty():
			continue
		var slot := ability_slot_views.get(slot_id, {}) as Dictionary
		if slot.is_empty():
			continue
		var ready_border := slot.get("ready_border") as Panel
		if ready_border == null or not is_instance_valid(ready_border):
			continue
		if not bool(ability_slot_ready_flags.get(slot_id, false)):
			continue
		var border_color := Color(0.34, 0.96, 0.5, pulse)
		if slot_id == "block" and bool(slot.get("block_active", false)):
			border_color = Color(0.48, 0.92, 1.0, pulse)
		elif slot_id == "counter":
			border_color = Color(0.52, 0.97, 1.0, pulse)
		ready_border.self_modulate = border_color


func update_health(current: float, maximum: float) -> void:
	health_label.text = "Health: %d / %d" % [int(round(current)), int(round(maximum))]


func update_xp(current: int, needed: int, level: int) -> void:
	xp_label.text = "Level %d  XP: %d / %d" % [level, current, needed]


func update_cooldowns(values: Dictionary) -> void:
	var basic_text := _format_cooldown(float(values.get("basic", 0.0)))
	var ability_1_left := float(values.get("ability_1", 0.0))
	var ability_1_text := _format_cooldown(ability_1_left)
	var harpoon_charging := bool(values.get("harpoon_charging", false))
	var harpoon_charge_ratio := clampf(float(values.get("harpoon_charge_ratio", 0.0)), 0.0, 1.0)
	var counter_unlocked := bool(values.get("counter_unlocked", false))
	var counter_ready := bool(values.get("counter_ready", false))
	var counter_window_left := maxf(0.0, float(values.get("counter_window_left", 0.0)))
	var counter_text := "Need Shield"
	if counter_unlocked:
		counter_text = "Ready %.1fs" % counter_window_left if counter_ready else "Locked"
	var ability_2_text := _format_cooldown(float(values.get("ability_2", 0.0)))
	var roll_text := _format_cooldown(float(values.get("roll", 0.0)))
	var blocking_text := " | Blocking" if bool(values.get("block_active", false)) else ""
	var sword_id := String(values.get("equipped_sword_id", ""))
	var sword_name := String(values.get("equipped_sword_name", ""))
	var sword_suffix := " | Sword: %s" % sword_name if not sword_name.is_empty() else ""
	var shield_name := String(values.get("equipped_shield_name", ""))
	var shield_suffix := " | Shield: %s" % shield_name if not shield_name.is_empty() else ""
	cooldown_label.text = "Swing %s  Hook %s  Counter %s  Dash %s  Roll %s%s%s%s" % [basic_text, ability_1_text, counter_text, ability_2_text, roll_text, blocking_text, sword_suffix, shield_suffix]
	_apply_charge_sword_indicator(sword_id)
	_update_ability_slot("basic", float(values.get("basic", 0.0)), false)
	_update_harpoon_slot(ability_1_left, harpoon_charging, harpoon_charge_ratio)
	_update_counter_slot(counter_ready, counter_window_left, counter_unlocked)
	_update_ability_slot("ability_2", float(values.get("ability_2", 0.0)), false)
	_update_ability_slot("roll", float(values.get("roll", 0.0)), false)
	_update_ability_slot("block", 0.0, bool(values.get("block_active", false)))


func update_objective(text: String) -> void:
	objective_label.text = text


func update_combat_debug(values: Dictionary) -> void:
	if combat_debug_label == null or not is_instance_valid(combat_debug_label):
		return
	var healer_state := String(values.get("healer_state", "-"))
	var healer_target := String(values.get("healer_target", "-"))
	var dps_state := String(values.get("dps_state", "-"))
	var dps_target := String(values.get("dps_target", "-"))
	var marked_ally := String(values.get("marked_ally", "-"))
	var boss_state := String(values.get("boss_state", "Idle"))
	var vulnerable_left := float(values.get("boss_vulnerable_left", 0.0))
	var tank_basic_cd_left := float(values.get("tank_basic_cd_left", 0.0))
	var boss_windup_duration := float(values.get("boss_windup_duration", 0.0))
	var boss_lunge_cycle_left := float(values.get("boss_lunge_cycle_left", 0.0))
	var minion_count := int(values.get("minion_count", 0))
	var clone_count := int(values.get("clone_count", 0))
	var breath_state := String(values.get("breath_state", "Idle"))
	var breath_time_left := float(values.get("breath_time_left", 0.0))
	var tank_blocking := bool(values.get("tank_blocking", false))
	var pocket_valid := bool(values.get("pocket_valid", false))
	var companions_safe := int(values.get("companions_safe", 0))
	combat_debug_label.text = "HealerAI: %s -> %s\nDPSAI: %s -> %s\nMarked Ally: %s\nBoss: %s  VulnerableTimer: %.2fs\nBreath: %s %.2fs | TankBlocking: %s | Pocket: %s | SafeCount: %d\nMinions: %d  Clones: %d\nPACING_DEBUG: TankSwingCD %.2fs | BossWindup %.2fs | BossLungeCD %.2fs" % [
		healer_state,
		healer_target,
		dps_state,
		dps_target,
		marked_ally,
		boss_state,
		vulnerable_left,
		breath_state,
		breath_time_left,
		"yes" if tank_blocking else "no",
		"valid" if pocket_valid else "none",
		companions_safe,
		minion_count,
		clone_count,
		tank_basic_cd_left,
		boss_windup_duration,
		boss_lunge_cycle_left
	]


func show_item_pickup(item_name: String, total_owned: int) -> void:
	items_label.text = "Inventory: %s x%d" % [item_name, total_owned]
	show_status_message("Picked up %s" % item_name, 2.2)


func show_status_message(text: String, duration: float = 1.6) -> void:
	status_label.text = text
	status_timer.start(maxf(0.1, duration))


func show_victory() -> void:
	victory_panel.visible = true
	victory_label.text = "Victory\nMiniboss defeated"


func show_defeat() -> void:
	victory_panel.visible = true
	victory_label.text = "Defeat\nYou were slain"


func _on_status_timeout() -> void:
	status_label.text = ""


func _format_cooldown(value: float) -> String:
	if value <= 0.05:
		return "Ready"
	return "%.1fs" % value


func _apply_charge_sword_indicator(sword_id: String) -> void:
	var slot := ability_slot_views.get("basic", {}) as Dictionary
	if slot.is_empty():
		return
	var icon_label := slot.get("icon_label") as Label
	var name_label := slot.get("name_label") as Label
	if icon_label == null or name_label == null:
		return
	var accent := Color(0.98, 0.74, 0.3, 1.0)
	var icon_text := "ATK"
	var name_text := "Swing"
	match sword_id:
		"extended_charge":
			accent = Color(1.0, 0.77, 0.34, 1.0)
			icon_text = "EXT"
			name_text = "Swing+"
		"slowing":
			accent = Color(0.5, 0.9, 1.0, 1.0)
			icon_text = "SLOW"
			name_text = "Swing+"
		"stacking_dot":
			accent = Color(0.96, 0.54, 1.0, 1.0)
			icon_text = "DOT"
			name_text = "Swing+"
		_:
			pass
	slot["accent"] = accent
	ability_slot_views["basic"] = slot
	icon_label.text = icon_text
	name_label.text = name_text


func _build_ability_bar() -> void:
	var bottom_strip := Control.new()
	bottom_strip.name = "AbilityBarStrip"
	bottom_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_strip.anchor_left = 0.0
	bottom_strip.anchor_right = 1.0
	bottom_strip.anchor_top = 1.0
	bottom_strip.anchor_bottom = 1.0
	bottom_strip.offset_left = 0.0
	bottom_strip.offset_right = 0.0
	bottom_strip.offset_top = -116.0
	bottom_strip.offset_bottom = -14.0
	add_child(bottom_strip)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_strip.add_child(center_container)

	var row := HBoxContainer.new()
	row.name = "AbilityBarRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	center_container.add_child(row)

	for slot_def in ABILITY_BAR_SLOTS:
		var slot_view := _create_ability_slot(slot_def)
		var slot_id := String(slot_def.get("id", ""))
		if slot_id.is_empty():
			continue
		row.add_child(slot_view.get("root") as Control)
		ability_slot_views[slot_id] = slot_view
		ability_slot_ready_flags[slot_id] = false
	for slot_def in ABILITY_BAR_SLOTS:
		var slot_id := String(slot_def.get("id", ""))
		if slot_id.is_empty():
			continue
		if slot_id == "counter":
			_update_counter_slot(false, 0.0, false)
		else:
			_update_ability_slot(slot_id, 0.0, false)


func _create_ability_slot(slot_def: Dictionary) -> Dictionary:
	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(78.0, 78.0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_stylebox_override("panel", _make_slot_stylebox(Color(0.08, 0.1, 0.14, 0.92), Color(0.3, 0.4, 0.5, 0.95), 2))

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(content)

	var icon_label := Label.new()
	icon_label.text = String(slot_def.get("icon", "?"))
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.anchor_left = 0.0
	icon_label.anchor_right = 1.0
	icon_label.anchor_top = 0.0
	icon_label.anchor_bottom = 0.0
	icon_label.offset_top = 8.0
	icon_label.offset_bottom = 32.0
	icon_label.add_theme_font_size_override("font_size", 14)
	icon_label.modulate = Color(0.95, 0.97, 1.0, 0.98)
	content.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = String(slot_def.get("name", "-"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.anchor_left = 0.0
	name_label.anchor_right = 1.0
	name_label.anchor_top = 0.0
	name_label.anchor_bottom = 0.0
	name_label.offset_top = 30.0
	name_label.offset_bottom = 50.0
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.modulate = Color(0.8, 0.88, 0.98, 0.9)
	content.add_child(name_label)

	var key_label := Label.new()
	key_label.text = String(slot_def.get("key", ""))
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.anchor_left = 0.0
	key_label.anchor_right = 1.0
	key_label.anchor_top = 1.0
	key_label.anchor_bottom = 1.0
	key_label.offset_top = -20.0
	key_label.offset_bottom = -4.0
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.modulate = Color(0.73, 0.85, 0.94, 0.96)
	content.add_child(key_label)

	var cooldown_overlay := ColorRect.new()
	cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.color = Color(0.02, 0.02, 0.03, 0.64)
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_overlay.visible = false
	content.add_child(cooldown_overlay)

	var cooldown_label := Label.new()
	cooldown_label.text = ""
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_label.add_theme_font_size_override("font_size", 15)
	cooldown_label.modulate = Color(1.0, 0.95, 0.84, 0.98)
	cooldown_label.visible = false
	content.add_child(cooldown_label)

	var ready_border := Panel.new()
	ready_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	ready_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ready_border.add_theme_stylebox_override("panel", _make_slot_stylebox(Color(0.0, 0.0, 0.0, 0.0), Color(0.34, 0.96, 0.5, 0.9), 2))
	ready_border.visible = false
	content.add_child(ready_border)

	return {
		"root": root,
		"icon_label": icon_label,
		"name_label": name_label,
		"key_label": key_label,
		"cooldown_overlay": cooldown_overlay,
		"cooldown_label": cooldown_label,
		"ready_border": ready_border,
		"block_active": false,
		"accent": slot_def.get("accent", Color(0.9, 0.9, 0.9, 1.0)),
		"uses_cooldown": bool(slot_def.get("uses_cooldown", true))
	}


func _update_ability_slot(slot_id: String, cooldown_left: float, block_active: bool) -> void:
	var slot := ability_slot_views.get(slot_id, {}) as Dictionary
	if slot.is_empty():
		return
	var uses_cooldown := bool(slot.get("uses_cooldown", true))
	var icon_label := slot.get("icon_label") as Label
	var key_label := slot.get("key_label") as Label
	var cooldown_overlay := slot.get("cooldown_overlay") as ColorRect
	var cooldown_label := slot.get("cooldown_label") as Label
	var ready_border := slot.get("ready_border") as Panel
	var root := slot.get("root") as PanelContainer
	if icon_label == null or key_label == null or cooldown_overlay == null or cooldown_label == null or ready_border == null or root == null:
		return

	var ready := true
	if uses_cooldown:
		ready = cooldown_left <= 0.05

	if uses_cooldown and not ready:
		cooldown_overlay.visible = true
		cooldown_label.visible = true
		cooldown_label.text = "%.1f" % maxf(0.0, cooldown_left)
		ready_border.visible = false
		root.self_modulate = Color(0.74, 0.74, 0.77, 1.0)
		icon_label.modulate = Color(0.9, 0.91, 0.95, 0.9)
		key_label.modulate = Color(0.62, 0.72, 0.8, 0.95)
	else:
		cooldown_overlay.visible = false
		cooldown_label.visible = false
		ready_border.visible = true
		root.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		var accent_variant: Variant = slot.get("accent", Color(0.95, 0.97, 1.0, 1.0))
		var accent: Color = Color(0.95, 0.97, 1.0, 1.0)
		if accent_variant is Color:
			accent = accent_variant
		icon_label.modulate = accent
		key_label.modulate = Color(0.8, 0.95, 0.84, 0.98)
	ability_slot_ready_flags[slot_id] = ready
	slot["block_active"] = block_active
	ability_slot_views[slot_id] = slot

	if slot_id == "block":
		var border_color := Color(0.48, 0.92, 1.0, 0.9) if block_active else Color(0.34, 0.96, 0.5, 0.9)
		ready_border.self_modulate = border_color
		icon_label.modulate = Color(0.64, 0.92, 1.0, 1.0) if block_active else Color(0.56, 0.88, 1.0, 1.0)


func _update_counter_slot(counter_ready: bool, counter_window_left: float, counter_unlocked: bool) -> void:
	var slot_id := "counter"
	var slot := ability_slot_views.get(slot_id, {}) as Dictionary
	if slot.is_empty():
		return
	var icon_label := slot.get("icon_label") as Label
	var key_label := slot.get("key_label") as Label
	var cooldown_overlay := slot.get("cooldown_overlay") as ColorRect
	var cooldown_label := slot.get("cooldown_label") as Label
	var ready_border := slot.get("ready_border") as Panel
	var root := slot.get("root") as PanelContainer
	if icon_label == null or key_label == null or cooldown_overlay == null or cooldown_label == null or ready_border == null or root == null:
		return

	var window_left := maxf(0.0, counter_window_left)
	if not counter_unlocked:
		cooldown_overlay.visible = true
		cooldown_overlay.color = Color(0.02, 0.04, 0.08, 0.74)
		cooldown_label.visible = true
		cooldown_label.text = "SHD"
		cooldown_label.modulate = Color(0.56, 0.86, 1.0, 0.94)
		ready_border.visible = false
		root.self_modulate = Color(0.7, 0.74, 0.8, 1.0)
		icon_label.modulate = Color(0.64, 0.84, 0.96, 0.9)
		key_label.modulate = Color(0.58, 0.74, 0.86, 0.96)
		ability_slot_ready_flags[slot_id] = false
		slot["block_active"] = false
		ability_slot_views[slot_id] = slot
		return

	if counter_ready:
		cooldown_overlay.visible = false
		cooldown_label.visible = true
		cooldown_label.text = "%.1f" % window_left
		cooldown_label.modulate = Color(0.84, 0.98, 1.0, 0.98)
		ready_border.visible = true
		ready_border.self_modulate = Color(0.52, 0.97, 1.0, 0.96)
		root.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		icon_label.modulate = Color(0.88, 1.0, 1.0, 1.0)
		key_label.modulate = Color(0.82, 0.98, 1.0, 0.98)
	else:
		cooldown_overlay.visible = true
		cooldown_overlay.color = Color(0.02, 0.04, 0.08, 0.72)
		cooldown_label.visible = true
		cooldown_label.text = "PB"
		cooldown_label.modulate = Color(0.68, 0.78, 0.9, 0.92)
		ready_border.visible = false
		root.self_modulate = Color(0.78, 0.78, 0.8, 1.0)
		icon_label.modulate = Color(0.76, 0.84, 0.92, 0.9)
		key_label.modulate = Color(0.64, 0.72, 0.82, 0.95)
	ability_slot_ready_flags[slot_id] = counter_ready
	slot["block_active"] = false
	ability_slot_views[slot_id] = slot


func _update_harpoon_slot(cooldown_left: float, charging: bool, charge_ratio: float) -> void:
	var slot_id := "ability_1"
	var slot := ability_slot_views.get(slot_id, {}) as Dictionary
	if slot.is_empty():
		return
	_update_ability_slot(slot_id, cooldown_left, false)
	var icon_label := slot.get("icon_label") as Label
	var cooldown_label := slot.get("cooldown_label") as Label
	var cooldown_overlay := slot.get("cooldown_overlay") as ColorRect
	var ready_border := slot.get("ready_border") as Panel
	if icon_label == null or cooldown_label == null or cooldown_overlay == null or ready_border == null:
		return
	if not charging:
		icon_label.text = "HPN"
		return
	icon_label.text = "THR"
	ready_border.visible = true
	ready_border.self_modulate = Color(0.46, 0.94, 1.0, 0.72 + (0.25 * charge_ratio))
	cooldown_overlay.visible = true
	cooldown_overlay.color = Color(0.02, 0.08, 0.12, 0.5)
	cooldown_label.visible = true
	cooldown_label.text = "%d%%" % int(round(charge_ratio * 100.0))
	cooldown_label.modulate = Color(0.72, 0.98, 1.0, 0.98)
	ability_slot_ready_flags[slot_id] = true
	ability_slot_views[slot_id] = slot


func _make_slot_stylebox(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(maxi(1, border_width))
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

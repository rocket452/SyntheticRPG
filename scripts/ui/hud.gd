extends CanvasLayer
class_name HUD

const ABILITY_LAYOUT_TANK: String = "tank"
const ABILITY_LAYOUT_HEALER: String = "healer"
const ABILITY_LAYOUT_RATFOLK: String = "ratfolk"
const ABILITY_LAYOUT_LIZARDFOLK: String = "lizardfolk"
const ABILITY_BAR_LAYOUTS: Dictionary = {
	ABILITY_LAYOUT_TANK: [
		{"id": "basic", "icon": "ATK", "name": "Swing", "key": "J", "accent": Color(0.94, 0.64, 0.33, 1.0), "uses_cooldown": true},
		{"id": "ability_1", "icon": "HPN", "name": "Hook", "key": "K", "accent": Color(0.46, 0.94, 1.0, 1.0), "uses_cooldown": true},
		{"id": "counter", "icon": "CTR", "name": "Counter", "key": "O", "accent": Color(0.86, 0.98, 1.0, 1.0), "uses_cooldown": false},
		{"id": "ability_2", "icon": "DSH", "name": "Dash", "key": "L", "accent": Color(0.42, 0.88, 1.0, 1.0), "uses_cooldown": true},
		{"id": "roll", "icon": "RLL", "name": "Roll", "key": "Space", "accent": Color(0.78, 0.93, 1.0, 1.0), "uses_cooldown": true},
		{"id": "block", "icon": "BLK", "name": "Block", "key": "I", "accent": Color(0.56, 0.88, 1.0, 1.0), "uses_cooldown": true}
	],
	ABILITY_LAYOUT_HEALER: [
		{"id": "basic", "icon": "ATK", "name": "Bolt", "key": "J", "accent": Color(0.62, 0.9, 1.0, 1.0), "uses_cooldown": true},
		{"id": "ability_1", "icon": "HPN", "name": "Hook", "key": "K", "accent": Color(0.46, 0.94, 1.0, 1.0), "uses_cooldown": true},
		{"id": "counter", "icon": "QHL", "name": "Quick", "key": "O", "accent": Color(0.84, 0.96, 1.0, 1.0), "uses_cooldown": true},
		{"id": "ability_2", "icon": "WAVE", "name": "Tidal", "key": "L", "accent": Color(0.52, 0.94, 1.0, 1.0), "uses_cooldown": true},
		{"id": "roll", "icon": "RLL", "name": "Roll", "key": "Space", "accent": Color(0.78, 0.93, 1.0, 1.0), "uses_cooldown": true},
		{"id": "block", "icon": "BHL", "name": "Big Heal", "key": "I", "accent": Color(0.66, 0.98, 0.84, 1.0), "uses_cooldown": true}
	],
	ABILITY_LAYOUT_RATFOLK: [
		{"id": "basic", "icon": "STB", "name": "Stab", "key": "J", "accent": Color(0.98, 0.78, 0.46, 1.0), "uses_cooldown": true},
		{"id": "ability_1", "icon": "FEAR", "name": "Fear", "key": "K", "accent": Color(0.74, 0.54, 1.0, 1.0), "uses_cooldown": true},
		{"id": "counter", "icon": "DASH", "name": "Shadow Dash", "key": "O", "accent": Color(0.72, 0.52, 1.0, 1.0), "uses_cooldown": true},
		{"id": "ability_2", "icon": "STRK", "name": "Strike", "key": "L", "accent": Color(0.86, 0.72, 1.0, 1.0), "uses_cooldown": true},
		{"id": "roll", "icon": "RLL", "name": "Roll", "key": "Space", "accent": Color(0.74, 0.9, 1.0, 1.0), "uses_cooldown": true},
		{"id": "block", "icon": "SURG", "name": "Surge", "key": "I", "accent": Color(0.92, 0.7, 1.0, 1.0), "uses_cooldown": true}
	],
	ABILITY_LAYOUT_LIZARDFOLK: [
		{"id": "basic", "icon": "SHOT", "name": "Shot", "key": "J", "accent": Color(0.82, 0.98, 0.62, 1.0), "uses_cooldown": true},
		{"id": "ability_1", "icon": "TRAP", "name": "Freeze Trap", "key": "K", "accent": Color(0.52, 0.82, 1.0, 1.0), "uses_cooldown": true},
		{"id": "counter", "icon": "DIST", "name": "Distracting Shot", "key": "O", "accent": Color(1.0, 0.88, 0.44, 1.0), "uses_cooldown": true},
		{"id": "ability_2", "icon": "FLRY", "name": "Flurry", "key": "L", "accent": Color(0.74, 0.98, 0.66, 1.0), "uses_cooldown": true},
		{"id": "roll", "icon": "RLL", "name": "Roll", "key": "Space", "accent": Color(0.76, 0.92, 1.0, 1.0), "uses_cooldown": true},
		{"id": "block", "icon": "PRCS", "name": "Precision", "key": "U", "accent": Color(1.0, 0.92, 0.32, 1.0), "uses_cooldown": true}
	]
}

@onready var health_label: Label = $HealthLabel
@onready var xp_label: Label = $XPLabel
@onready var cooldown_label: Label = $CooldownLabel
@onready var items_label: Label = $ItemsLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var status_label: Label = $StatusLabel
@onready var victory_panel: Panel = $VictoryPanel
@onready var victory_label: Label = $VictoryPanel/Message
@onready var status_timer: Timer = $StatusTimer
const ABILITY_GUIDE_DESCRIPTIONS: Dictionary = {
	ABILITY_LAYOUT_TANK: {
		"basic":     "Basic melee strike against the nearest enemy.",
		"ability_1": "Launch a harpoon to pull an enemy toward you.",
		"counter":   "Parry the next incoming attack and counter-strike.",
		"ability_2": "Lunge forward with a powerful rushing strike.",
		"roll":      "Dodge roll to quickly evade attacks.",
		"block":     "Hold to raise your shield and reduce incoming damage."
	},
	ABILITY_LAYOUT_HEALER: {
		"basic":     "Fire a magical bolt at the nearest enemy.",
		"ability_1": "Launch a harpoon to reposition an enemy.",
		"counter":   "Instantly restore a small amount of health to a nearby ally. Hold Shift to heal yourself instead.",
		"ability_2": "Unleash a tidal wave that heals nearby allies.",
		"roll":      "Dodge roll to quickly evade attacks.",
		"block":     "Channel a powerful surge of healing on a nearby ally. Hold Shift to target yourself instead."
	},
	ABILITY_LAYOUT_RATFOLK: {
		"basic":     "Quick melee strike against the nearest enemy.",
		"ability_1": "Cause an enemy to flee in terror.",
		"counter":   "Dash through shadows and strike from behind.",
		"ability_2": "Unleash a devastating shadow strike.",
		"roll":      "Dodge roll to quickly evade attacks.",
		"block":     "Unleash a shadow surge — a burst of shadow energy."
	},
	ABILITY_LAYOUT_LIZARDFOLK: {
		"basic":     "Fire an arrow at the nearest enemy.",
		"ability_1": "Place a trap that freezes enemies who step on it.",
		"counter":   "Fire a taunting arrow that draws all enemy aggression.",
		"ability_2": "Rapid arrow volley hitting multiple targets. Requires full special meter.",
		"roll":      "Dodge roll to quickly evade attacks.",
		"block":     "Hold to charge. Release in the green window for a perfect shot with bonus damage. Hold too long and it overcharges."
	}
}
var combat_debug_label: Label = null
var ability_slot_views: Dictionary = {}
var ability_slot_ready_flags: Dictionary = {}
var ready_pulse_time: float = 0.0
var text_debug_visible: bool = false
var current_ability_layout: String = ABILITY_LAYOUT_TANK
var _guide_panel: Control = null
var _guide_hint_label: Label = null


func _ready() -> void:
	victory_panel.visible = false
	status_timer.timeout.connect(_on_status_timeout)
	status_label.text = ""
	_apply_status_style(false)
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
	set_text_debug_visible(false)
	_guide_hint_label = Label.new()
	_guide_hint_label.text = "F1  —  Game guide"
	_guide_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_guide_hint_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_guide_hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_guide_hint_label.offset_left = -160.0
	_guide_hint_label.offset_top = -28.0
	_guide_hint_label.offset_right = -12.0
	_guide_hint_label.offset_bottom = -8.0
	_guide_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_guide_hint_label.add_theme_font_size_override("font_size", 16)
	_guide_hint_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	add_child(_guide_hint_label)
	set_process(true)


func _process(delta: float) -> void:
	if ability_slot_views.is_empty():
		return
	ready_pulse_time += maxf(0.0, delta)
	var pulse := 0.68 + (0.22 * (0.5 + (0.5 * sin(ready_pulse_time * 4.2))))
	for slot_id_variant in ability_slot_views.keys():
		var slot_id := String(slot_id_variant)
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
			border_color = Color(0.88, 0.82, 1.0, pulse) if current_ability_layout == ABILITY_LAYOUT_HEALER else Color(0.52, 0.97, 1.0, pulse)
		ready_border.self_modulate = border_color


func update_health(current: float, maximum: float) -> void:
	health_label.text = "Health: %d / %d" % [int(round(current)), int(round(maximum))]


func update_xp(current: int, needed: int, level: int) -> void:
	xp_label.text = "Level %d  XP: %d / %d" % [level, current, needed]


func update_cooldowns(values: Dictionary) -> void:
	var requested_layout := String(values.get("ability_layout", ABILITY_LAYOUT_TANK)).strip_edges().to_lower()
	_apply_ability_layout(requested_layout)
	if is_instance_valid(cooldown_label):
		cooldown_label.text = ""
	if current_ability_layout == ABILITY_LAYOUT_HEALER:
		_update_healer_control_slots(values)
		return
	if current_ability_layout == ABILITY_LAYOUT_RATFOLK:
		_update_ratfolk_control_slots(values)
		return
	if current_ability_layout == ABILITY_LAYOUT_LIZARDFOLK:
		_update_lizardfolk_control_slots(values)
		return
	_update_tank_control_slots(values)


func _update_tank_control_slots(values: Dictionary) -> void:
	var ability_1_left := float(values.get("ability_1", 0.0))
	var harpoon_charging := bool(values.get("harpoon_charging", false))
	var harpoon_charge_ratio := clampf(float(values.get("harpoon_charge_ratio", 0.0)), 0.0, 1.0)
	var counter_unlocked := bool(values.get("counter_unlocked", false))
	var counter_ready := bool(values.get("counter_ready", false))
	var counter_window_left := maxf(0.0, float(values.get("counter_window_left", 0.0)))
	var ability_2_left := float(values.get("ability_2", 0.0))
	var ability_2_unlocked := bool(values.get("ability_2_unlocked", true))
	var block_cooldown_left := maxf(0.0, float(values.get("block_cooldown_left", 0.0)))
	var sword_id := String(values.get("equipped_sword_id", ""))
	_apply_charge_sword_indicator(sword_id)
	_update_ability_slot("basic", float(values.get("basic", 0.0)), false)
	_update_harpoon_slot(ability_1_left, harpoon_charging, harpoon_charge_ratio)
	_update_counter_slot(counter_ready, counter_window_left, counter_unlocked)
	_update_ability_slot("ability_2", ability_2_left, false, ability_2_unlocked)
	_update_ability_slot("roll", float(values.get("roll", 0.0)), false)
	_update_ability_slot("block", block_cooldown_left, bool(values.get("block_active", false)))


func _update_healer_control_slots(values: Dictionary) -> void:
	var basic_left := float(values.get("basic", 0.0))
	var basic_unlocked := bool(values.get("basic_unlocked", true))
	var quick_heal_left := maxf(0.0, float(values.get("quick_heal", values.get("counter_window_left", 0.0))))
	var quick_heal_unlocked := bool(values.get("quick_heal_unlocked", values.get("counter_unlocked", true)))
	var ability_1_left := float(values.get("ability_1", 0.0))
	var ability_1_unlocked := bool(values.get("ability_1_unlocked", true))
	var harpoon_charging := bool(values.get("harpoon_charging", false))
	var harpoon_charge_ratio := clampf(float(values.get("harpoon_charge_ratio", 0.0)), 0.0, 1.0)
	var wave_left := float(values.get("ability_2", 0.0))
	var wave_unlocked := bool(values.get("ability_2_unlocked", false))
	var roll_unlocked := bool(values.get("roll_unlocked", false))
	var shield_left := maxf(0.0, float(values.get("block_cooldown_left", 0.0)))
	_update_ability_slot("basic", basic_left, false, basic_unlocked)
	if ability_1_unlocked:
		_update_harpoon_slot(ability_1_left, harpoon_charging, harpoon_charge_ratio)
	else:
		_update_ability_slot("ability_1", ability_1_left, false, false)
	_update_ability_slot("counter", quick_heal_left, false, quick_heal_unlocked)
	_update_ability_slot("ability_2", wave_left, false, wave_unlocked)
	_update_ability_slot("roll", float(values.get("roll", 0.0)), false, roll_unlocked)
	_update_ability_slot("block", shield_left, false, true)


func _update_ratfolk_control_slots(values: Dictionary) -> void:
	var basic_left := float(values.get("basic", 0.0))
	var basic_unlocked := bool(values.get("basic_unlocked", true))
	var fear_left := float(values.get("ability_1", 0.0))
	var fear_unlocked := bool(values.get("ability_1_unlocked", false))
	var mark_left := maxf(0.0, float(values.get("counter", 0.0)))
	var mark_unlocked := bool(values.get("counter_unlocked", false))
	var clone_left := float(values.get("ability_2", 0.0))
	var clone_unlocked := bool(values.get("ability_2_unlocked", false))
	var roll_left := float(values.get("roll", 0.0))
	var roll_unlocked := bool(values.get("roll_unlocked", false))
	var block_unlocked := bool(values.get("block_unlocked", false))
	_update_ability_slot("basic", basic_left, false, basic_unlocked)
	_update_ability_slot("ability_1", fear_left, false, fear_unlocked)
	_update_ability_slot("counter", mark_left, false, mark_unlocked)
	_update_ability_slot("ability_2", clone_left, false, clone_unlocked)
	_update_ability_slot("roll", roll_left, false, roll_unlocked)
	_update_ability_slot("block", maxf(0.0, float(values.get("block_cooldown_left", 0.0))), false, block_unlocked)


func _update_lizardfolk_control_slots(values: Dictionary) -> void:
	var basic_left := float(values.get("basic", 0.0))
	var basic_unlocked := bool(values.get("basic_unlocked", true))
	var trap_left := float(values.get("ability_1", 0.0))
	var trap_unlocked := bool(values.get("ability_1_unlocked", false))
	var distract_left := float(values.get("counter", 0.0))
	var distract_unlocked := bool(values.get("counter_unlocked", false))
	var flurry_left := float(values.get("ability_2", 0.0))
	var flurry_unlocked := bool(values.get("ability_2_unlocked", false))
	var roll_left := float(values.get("roll", 0.0))
	var roll_unlocked := bool(values.get("roll_unlocked", false))
	var precision_left := maxf(0.0, float(values.get("block_cooldown_left", 0.0)))
	var precision_unlocked := bool(values.get("block_unlocked", false))
	_update_ability_slot("basic", basic_left, false, basic_unlocked)
	_update_ability_slot("ability_1", trap_left, false, trap_unlocked)
	_update_ability_slot("counter", distract_left, false, distract_unlocked)
	_update_ability_slot("ability_2", flurry_left, false, flurry_unlocked)
	_update_ability_slot("roll", roll_left, false, roll_unlocked)
	_update_ability_slot("block", precision_left, false, precision_unlocked)


func update_objective(text: String) -> void:
	objective_label.text = text


func set_text_debug_visible(enabled: bool) -> void:
	text_debug_visible = bool(enabled)
	_apply_text_visibility()


func is_text_debug_visible() -> bool:
	return text_debug_visible


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
	_apply_status_style(false)
	status_label.text = text
	status_timer.start(maxf(0.1, duration))


func show_warning_status_message(text: String, duration: float = 2.0) -> void:
	_apply_status_style(true)
	status_label.text = text
	status_timer.start(maxf(0.1, duration))


func show_victory() -> void:
	victory_panel.visible = text_debug_visible
	victory_label.text = "Victory\nMiniboss defeated"


func show_defeat() -> void:
	victory_panel.visible = text_debug_visible
	victory_label.text = "Defeat\nYou were slain"


func _on_status_timeout() -> void:
	status_label.text = ""
	_apply_status_style(false)


func _apply_status_style(is_warning: bool) -> void:
	if is_warning:
		status_label.add_theme_font_size_override("font_size", 30)
		status_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.74, 1.0))
		status_label.add_theme_color_override("font_outline_color", Color(0.38, 0.04, 0.04, 0.96))
		status_label.add_theme_constant_override("outline_size", 7)
		return
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.98))
	status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	status_label.add_theme_constant_override("outline_size", 4)


func _format_cooldown(value: float) -> String:
	if value <= 0.05:
		return "Ready"
	return "%.1fs" % value


func _apply_charge_sword_indicator(sword_id: String) -> void:
	if current_ability_layout != ABILITY_LAYOUT_TANK:
		return
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

	var slot_defs := _get_layout_slot_defs(current_ability_layout)
	for slot_def in slot_defs:
		var slot_view := _create_ability_slot(slot_def)
		var slot_id := String(slot_def.get("id", ""))
		if slot_id.is_empty():
			continue
		row.add_child(slot_view.get("root") as Control)
		ability_slot_views[slot_id] = slot_view
		ability_slot_ready_flags[slot_id] = false
	for slot_def in slot_defs:
		var slot_id := String(slot_def.get("id", ""))
		if slot_id.is_empty():
			continue
		if slot_id == "counter":
			_update_counter_slot(false, 0.0, false)
		else:
			_update_ability_slot(slot_id, 0.0, false)
	_apply_ability_layout(current_ability_layout)


func _get_layout_slot_defs(layout_id: String) -> Array[Dictionary]:
	var normalized_layout := layout_id.strip_edges().to_lower()
	var layout_variant: Variant = ABILITY_BAR_LAYOUTS.get(normalized_layout, null)
	var slot_defs: Array[Dictionary] = []
	if layout_variant is Array:
		for entry_variant in (layout_variant as Array):
			if entry_variant is Dictionary:
				slot_defs.append((entry_variant as Dictionary).duplicate(true))
	if not slot_defs.is_empty():
		return slot_defs
	var fallback_variant: Variant = ABILITY_BAR_LAYOUTS.get(ABILITY_LAYOUT_TANK, [])
	if fallback_variant is Array:
		for entry_variant in (fallback_variant as Array):
			if entry_variant is Dictionary:
				slot_defs.append((entry_variant as Dictionary).duplicate(true))
	return slot_defs


func _apply_ability_layout(layout_id: String) -> void:
	var normalized_layout := layout_id.strip_edges().to_lower()
	if normalized_layout.is_empty():
		normalized_layout = ABILITY_LAYOUT_TANK
	if not ABILITY_BAR_LAYOUTS.has(normalized_layout):
		normalized_layout = ABILITY_LAYOUT_TANK
	current_ability_layout = normalized_layout
	if ability_slot_views.is_empty():
		return
	var slot_defs := _get_layout_slot_defs(normalized_layout)
	for slot_def in slot_defs:
		var slot_id := String(slot_def.get("id", ""))
		if slot_id.is_empty():
			continue
		var slot := ability_slot_views.get(slot_id, {}) as Dictionary
		if slot.is_empty():
			continue
		var icon_label := slot.get("icon_label") as Label
		var name_label := slot.get("name_label") as Label
		var key_label := slot.get("key_label") as Label
		if is_instance_valid(icon_label):
			icon_label.text = String(slot_def.get("icon", "?"))
		if is_instance_valid(name_label):
			name_label.text = String(slot_def.get("name", "-"))
		if is_instance_valid(key_label):
			key_label.text = String(slot_def.get("key", ""))
		slot["accent"] = slot_def.get("accent", Color(0.9, 0.9, 0.9, 1.0))
		slot["uses_cooldown"] = bool(slot_def.get("uses_cooldown", true))
		slot["block_active"] = false
		ability_slot_ready_flags[slot_id] = false
		ability_slot_views[slot_id] = slot


func _create_ability_slot(slot_def: Dictionary) -> Dictionary:
	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(84.0, 84.0)
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
	icon_label.add_theme_font_size_override("font_size", 17)
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
	name_label.add_theme_font_size_override("font_size", 13)
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
	key_label.add_theme_font_size_override("font_size", 12)
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
	cooldown_label.add_theme_font_size_override("font_size", 17)
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


func _update_ability_slot(slot_id: String, cooldown_left: float, block_active: bool, unlocked: bool = true) -> void:
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

	if not unlocked:
		cooldown_overlay.visible = true
		cooldown_overlay.color = Color(0.03, 0.04, 0.08, 0.76)
		cooldown_label.visible = true
		cooldown_label.text = "LOCK"
		cooldown_label.modulate = Color(0.7, 0.84, 1.0, 0.96)
		ready_border.visible = false
		root.self_modulate = Color(0.7, 0.72, 0.78, 1.0)
		icon_label.modulate = Color(0.66, 0.76, 0.88, 0.9)
		key_label.modulate = Color(0.58, 0.66, 0.78, 0.95)
		ability_slot_ready_flags[slot_id] = false
		slot["block_active"] = block_active
		ability_slot_views[slot_id] = slot
		return

	var ready := true
	if uses_cooldown:
		ready = cooldown_left <= 0.05

	if uses_cooldown and not ready:
		cooldown_overlay.visible = true
		cooldown_overlay.color = Color(0.02, 0.02, 0.03, 0.64)
		cooldown_label.visible = true
		cooldown_label.text = "%.1f" % maxf(0.0, cooldown_left)
		cooldown_label.modulate = Color(1.0, 0.95, 0.84, 0.98)
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


func _update_healer_special_meter_slot(fill_ratio: float, special_ready: bool) -> void:
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
	var ratio := clampf(fill_ratio, 0.0, 1.0)
	var meter_percent := clampi(int(round(ratio * 100.0)), 0, 100)
	if special_ready:
		cooldown_overlay.visible = false
		cooldown_label.visible = true
		cooldown_label.text = "%d%%" % meter_percent
		cooldown_label.modulate = Color(0.92, 0.88, 1.0, 0.98)
		ready_border.visible = true
		ready_border.self_modulate = Color(0.9, 0.82, 1.0, 0.96)
		root.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		icon_label.modulate = Color(0.96, 0.9, 1.0, 1.0)
		key_label.modulate = Color(0.86, 0.96, 1.0, 0.98)
	else:
		cooldown_overlay.visible = true
		cooldown_overlay.color = Color(0.03, 0.04, 0.08, 0.72)
		cooldown_label.visible = true
		cooldown_label.text = "%d%%" % meter_percent
		cooldown_label.modulate = Color(0.78, 0.84, 0.98, 0.96)
		ready_border.visible = false
		root.self_modulate = Color(0.8, 0.82, 0.9, 1.0)
		icon_label.modulate = Color(0.8, 0.86, 0.98, 0.95)
		key_label.modulate = Color(0.76, 0.82, 0.94, 0.95)
	ability_slot_ready_flags[slot_id] = special_ready
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


func _apply_text_visibility() -> void:
	var show_non_ability_text := text_debug_visible
	if is_instance_valid(health_label):
		health_label.visible = show_non_ability_text
	if is_instance_valid(xp_label):
		xp_label.visible = show_non_ability_text
	if is_instance_valid(cooldown_label):
		cooldown_label.visible = false
	if is_instance_valid(items_label):
		items_label.visible = show_non_ability_text
	if is_instance_valid(objective_label):
		objective_label.visible = show_non_ability_text
	if is_instance_valid(status_label):
		status_label.visible = show_non_ability_text
	if is_instance_valid(combat_debug_label):
		combat_debug_label.visible = show_non_ability_text
	if not show_non_ability_text:
		victory_panel.visible = false


func toggle_guide() -> void:
	if is_instance_valid(_guide_panel):
		_close_guide()
	else:
		_open_guide()


func is_guide_open() -> bool:
	return is_instance_valid(_guide_panel)


func _open_guide() -> void:
	if is_instance_valid(_guide_panel):
		return
	get_tree().paused = true
	if is_instance_valid(_guide_hint_label):
		_guide_hint_label.visible = false

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.04, 0.08, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_guide_panel = overlay

	var panel_container := PanelContainer.new()
	panel_container.set_anchors_preset(Control.PRESET_CENTER)
	panel_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel_container.custom_minimum_size = Vector2(560.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.10, 0.15, 0.98)
	panel_style.border_color = Color(0.30, 0.44, 0.60, 0.80)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 28.0
	panel_style.content_margin_right = 28.0
	panel_style.content_margin_top = 22.0
	panel_style.content_margin_bottom = 22.0
	panel_container.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel_container)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel_container.add_child(content)

	var title := Label.new()
	title.text = "How to Play"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.92, 0.96, 1.0, 1.0)
	content.add_child(title)

	_add_guide_divider(content)

	var tab_row := Label.new()
	tab_row.text = "Tab  —  Open shop & equipment screen"
	tab_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_row.add_theme_font_size_override("font_size", 13)
	tab_row.modulate = Color(0.74, 0.88, 1.0, 0.95)
	content.add_child(tab_row)

	_add_guide_divider(content)

	var char_name := _get_layout_display_name(current_ability_layout)
	var char_label := Label.new()
	char_label.text = "%s — Abilities" % char_name
	char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_label.add_theme_font_size_override("font_size", 15)
	char_label.modulate = Color(0.82, 0.96, 0.68, 1.0)
	content.add_child(char_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 2.0)
	content.add_child(spacer)

	var slot_defs := _get_layout_slot_defs(current_ability_layout)
	var descs: Dictionary = ABILITY_GUIDE_DESCRIPTIONS.get(current_ability_layout, {}) as Dictionary
	for slot_def_variant in slot_defs:
		var slot_def := slot_def_variant as Dictionary
		if slot_def == null:
			continue
		var slot_id := String(slot_def.get("id", ""))
		var slot_name := String(slot_def.get("name", slot_id))
		var slot_key := String(slot_def.get("key", "?"))
		var slot_accent: Color = slot_def.get("accent", Color(0.9, 0.9, 0.9, 1.0))
		var slot_desc := String(descs.get(slot_id, ""))

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		content.add_child(row)

		var key_bg := PanelContainer.new()
		var key_style := StyleBoxFlat.new()
		key_style.bg_color = Color(slot_accent.r * 0.18, slot_accent.g * 0.18, slot_accent.b * 0.22, 0.90)
		key_style.border_color = Color(slot_accent.r, slot_accent.g, slot_accent.b, 0.72)
		key_style.set_border_width_all(1)
		key_style.set_corner_radius_all(4)
		key_style.content_margin_left = 6.0
		key_style.content_margin_right = 6.0
		key_style.content_margin_top = 2.0
		key_style.content_margin_bottom = 2.0
		key_bg.add_theme_stylebox_override("panel", key_style)
		key_bg.custom_minimum_size = Vector2(64.0, 0.0)
		row.add_child(key_bg)

		var key_label := Label.new()
		key_label.text = slot_key
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 12)
		key_label.modulate = slot_accent
		key_bg.add_child(key_label)

		var name_label := Label.new()
		name_label.text = slot_name
		name_label.custom_minimum_size = Vector2(128.0, 0.0)
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.modulate = Color(0.94, 0.94, 0.86, 1.0)
		row.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = slot_desc
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.modulate = Color(0.68, 0.76, 0.92, 0.88)
		row.add_child(desc_label)

	_add_guide_divider(content)

	var close_hint := Label.new()
	close_hint.text = "F1 to close"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 11)
	close_hint.modulate = Color(0.50, 0.58, 0.72, 0.80)
	content.add_child(close_hint)


func _close_guide() -> void:
	if is_instance_valid(_guide_panel):
		_guide_panel.queue_free()
	_guide_panel = null
	get_tree().paused = false
	if is_instance_valid(_guide_hint_label):
		_guide_hint_label.visible = true


func _add_guide_divider(parent: Control) -> void:
	var div := Label.new()
	div.text = "─────────────────────────────────────────────"
	div.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	div.add_theme_font_size_override("font_size", 9)
	div.modulate = Color(0.28, 0.38, 0.52, 0.72)
	parent.add_child(div)


func _get_layout_display_name(layout_id: String) -> String:
	match layout_id:
		ABILITY_LAYOUT_TANK: return "Tank"
		ABILITY_LAYOUT_HEALER: return "Healer"
		ABILITY_LAYOUT_RATFOLK: return "Ratfolk"
		ABILITY_LAYOUT_LIZARDFOLK: return "Lizard Ranger"
		_: return layout_id.capitalize()

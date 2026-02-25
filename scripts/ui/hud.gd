extends CanvasLayer
class_name HUD

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


func _ready() -> void:
	victory_panel.visible = false
	status_timer.timeout.connect(_on_status_timeout)
	status_label.text = ""
	combat_debug_label = Label.new()
	combat_debug_label.name = "CombatDebugLabel"
	combat_debug_label.position = Vector2(990.0, 20.0)
	combat_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combat_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	combat_debug_label.size = Vector2(620.0, 172.0)
	combat_debug_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	combat_debug_label.modulate = Color(0.88, 0.97, 1.0, 0.94)
	combat_debug_label.text = ""
	add_child(combat_debug_label)


func update_health(current: float, maximum: float) -> void:
	health_label.text = "Health: %d / %d" % [int(round(current)), int(round(maximum))]


func update_xp(current: int, needed: int, level: int) -> void:
	xp_label.text = "Level %d  XP: %d / %d" % [level, current, needed]


func update_cooldowns(values: Dictionary) -> void:
	var gcd_text := _format_cooldown(float(values.get("gcd", 0.0)))
	var basic_text := _format_cooldown(float(values.get("basic", 0.0)))
	var ability_1_text := _format_cooldown(float(values.get("ability_1", 0.0)))
	var ability_2_text := _format_cooldown(float(values.get("ability_2", 0.0)))
	var roll_text := _format_cooldown(float(values.get("roll", 0.0)))
	var blocking_text := " | Blocking" if bool(values.get("block_active", false)) else ""
	cooldown_label.text = "GCD %s  Swing %s  Charge %s  Dash %s  Roll %s%s" % [gcd_text, basic_text, ability_1_text, ability_2_text, roll_text, blocking_text]


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
	combat_debug_label.text = "HealerAI: %s -> %s\nDPSAI: %s -> %s\nMarked Ally: %s\nBoss: %s  VulnerableTimer: %.2fs\nPACING_DEBUG: TankGCD %.2fs | BossWindup %.2fs | BossLungeCD %.2fs" % [
		healer_state,
		healer_target,
		dps_state,
		dps_target,
		marked_ally,
		boss_state,
		vulnerable_left,
		tank_basic_cd_left,
		boss_windup_duration,
		boss_lunge_cycle_left
	]


func show_item_pickup(item_name: String, total_owned: int) -> void:
	items_label.text = "Inventory: %s x%d" % [item_name, total_owned]
	status_label.text = "Picked up %s" % item_name
	status_timer.start(2.2)


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

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


func _ready() -> void:
	victory_panel.visible = false
	status_timer.timeout.connect(_on_status_timeout)
	status_label.text = ""


func update_health(current: float, maximum: float) -> void:
	health_label.text = "Health: %d / %d" % [int(round(current)), int(round(maximum))]


func update_xp(current: int, needed: int, level: int) -> void:
	xp_label.text = "Level %d  XP: %d / %d" % [level, current, needed]


func update_cooldowns(values: Dictionary) -> void:
	var basic_text := _format_cooldown(float(values.get("basic", 0.0)))
	var ability_1_text := _format_cooldown(float(values.get("ability_1", 0.0)))
	var ability_2_text := _format_cooldown(float(values.get("ability_2", 0.0)))
	var roll_text := _format_cooldown(float(values.get("roll", 0.0)))
	var blocking_text := " | Blocking" if bool(values.get("block_active", false)) else ""
	cooldown_label.text = "Basic %s  Cleave %s  Lunge %s  Roll %s%s" % [basic_text, ability_1_text, ability_2_text, roll_text, blocking_text]


func update_objective(text: String) -> void:
	objective_label.text = text


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

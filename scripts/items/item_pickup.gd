extends Area2D
class_name ItemPickup

const ITEM_DATA: Dictionary = {
	"iron_shard": {
		"name": "Iron Shard",
		"color": Color(0.88, 0.88, 0.95, 1.0)
	},
	"sturdy_hide": {
		"name": "Sturdy Hide",
		"color": Color(0.6, 0.4, 0.2, 1.0)
	},
	"swift_boots": {
		"name": "Swift Boots",
		"color": Color(0.35, 0.8, 1.0, 1.0)
	}
}

@export var item_id: String = "iron_shard"
@export var value: int = 1
@export var bob_height: float = 5.0
@export var bob_speed: float = 2.8
@export var spin_speed: float = 1.8

var base_position: Vector2 = Vector2.ZERO
var time_passed: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var label: Label = $Label


func _ready() -> void:
	add_to_group("pickups")
	base_position = position
	_apply_item_style()


func _process(delta: float) -> void:
	time_passed += delta
	position = base_position + Vector2(0.0, sin(time_passed * bob_speed) * bob_height)
	rotation += delta * spin_speed
	label.rotation = -rotation


func set_item(new_item_id: String, new_value: int = 1) -> void:
	item_id = new_item_id
	value = new_value
	if is_node_ready():
		_apply_item_style()


func try_collect(player: Node) -> void:
	if not is_instance_valid(player):
		return
	if player.has_method("collect_item"):
		player.collect_item(item_id, value)
	queue_free()


func _apply_item_style() -> void:
	var data: Dictionary = ITEM_DATA.get(item_id, ITEM_DATA["iron_shard"])
	var item_name := String(data["name"])
	var item_color: Color = data["color"]
	visual.color = item_color
	label.text = item_name.substr(0, 1)

extends CanvasLayer
class_name InventoryMenu

signal sword_selected(sword_id: String)
signal menu_closed

var sword_entries: Array[Dictionary] = []
var equipped_sword_id: String = ""

var _content_root: VBoxContainer = null
var _button_by_sword_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 30
	_build_ui()
	_rebuild_sword_list()


func configure(entries: Array[Dictionary], equipped_id: String) -> void:
	sword_entries = []
	for entry in entries:
		if entry is Dictionary:
			sword_entries.append((entry as Dictionary).duplicate(true))
	equipped_sword_id = equipped_id
	if is_inside_tree():
		_rebuild_sword_list()


func set_equipped_sword(sword_id: String) -> void:
	equipped_sword_id = sword_id
	_rebuild_sword_list()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle") or event.is_action_pressed("ui_cancel"):
		menu_closed.emit()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.04, 0.84)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 360.0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	_content_root = content

	var title := Label.new()
	title.text = "Inventory - Swords"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Click a sword to equip. Only one sword can be equipped at a time."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)

	var separator := HSeparator.new()
	content.add_child(separator)

	var sword_list := VBoxContainer.new()
	sword_list.name = "SwordList"
	sword_list.add_theme_constant_override("separation", 8)
	content.add_child(sword_list)

	var hint := Label.new()
	hint.text = "Press Tab or Esc to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.86, 0.9, 1.0, 0.92)
	content.add_child(hint)


func _rebuild_sword_list() -> void:
	if _content_root == null or not is_instance_valid(_content_root):
		return
	var sword_list := _content_root.get_node_or_null("SwordList") as VBoxContainer
	if sword_list == null:
		return
	for child in sword_list.get_children():
		child.queue_free()
	_button_by_sword_id.clear()

	for entry in sword_entries:
		var sword_id := String(entry.get("id", ""))
		if sword_id.is_empty():
			continue
		var sword_name := String(entry.get("name", sword_id))
		var sword_icon := String(entry.get("icon", "SWD"))
		var sword_description := String(entry.get("description", ""))
		var equipped := sword_id == equipped_sword_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.toggle_mode = false
		button.text = "%s  %s%s\n%s" % [
			sword_icon,
			sword_name,
			"   [EQUIPPED]" if equipped else "",
			sword_description
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_sword_button_pressed.bind(sword_id))
		if equipped:
			button.modulate = Color(0.72, 1.0, 0.78, 1.0)
		sword_list.add_child(button)
		_button_by_sword_id[sword_id] = button

	if sword_list.get_child_count() > 0:
		var first_button := sword_list.get_child(0) as Button
		if first_button != null:
			first_button.grab_focus()


func _on_sword_button_pressed(sword_id: String) -> void:
	sword_selected.emit(sword_id)
